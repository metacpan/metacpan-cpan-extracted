#!/usr/bin/perl -w
use strict;
use Scalar::Util qw{reftype};
use File::Path;
use Getopt::Long;
use GRID::Machine qw{slurp_file};
use Fcntl qw(:DEFAULT :flock);

# Package Variables. The user can modify it inside the machine.preamble.pl
# configuration file
#
our $makebuilder = '';
our $build = '';
our $makebuilder_arg = '';
our $build_test_arg = '';
our $build_arg = '';
our $localpreamble = "local.preamble.pl";
my  $report;
my $parallel;
our %preamble;

  my $m; # current machine
  my $tmpdir; # temporary directory in the remote machine

  our $clean_files = sub {
    # Clean files
    return unless UNIVERSAL::isa($m, 'GRID::Machine');
    my $r = $m->eval( q{
      our $tmpdir;
      CORE::chdir "$tmpdir/.." || die "Can't chage to $tmpdir ...";
      rmtree($tmpdir);
    });
    warn "Can't remove files in temporary directory <$tmpdir>: $r\n" unless $r->ok;
  };


  local $SIG{INT} = $SIG{PIPE} = sub { 
    $clean_files->(); 
    warn "Tests were interrupted!";
  };

sub usage {
  return <<'EOS'
Usage:\n$0 [--report reportfile ] [--parallel] distribution.tar.gz machine1 machine2 ... 

  The null string machine '' will fork (via open2) a process executing perl in the local machine 
EOS
}

GetOptions ("localpreamble=s" => \$localpreamble, 'report=s' => \$report, parallel => \$parallel);

my $dist = shift or die usage();

die "No distribution $dist found\n" unless -r $dist;

die "Distribution does not follow standard name convention\n" unless $dist =~ m{([\w.-]+)\.tar\.gz$};
my $dir = $1;

die usage() unless @ARGV;

if (-r $localpreamble) {
  local $/ = undef;

  my $code = slurp_file($localpreamble);
  eval $code;
  warn("Error in $localpreamble $@. Local preamble skipped") if  $@;
}


for my $host (@ARGV) {

  if ($parallel) {
    my $pid = fork();
    next if $pid;
  }

  my $LOG = '';
  my $prefix = sub {
    my $str = shift;

    $str =~ s/^/$host:/mg;
    $LOG .= $str;
    $str;
  };

  $m = eval { 
    GRID::Machine->new(host => $host) 
  };

  warn "Cant' create GRID::Machine connection with $host\n", next unless UNIVERSAL::isa($m, 'GRID::Machine');

  my $r = $m->eval(q{ 
      our $tmpdir = File::Temp::tempdir;
      chdir($tmpdir) or die "Can't change to dir <$tmpdir>\n"; 
      $tmpdir;
    }
  );

  warn($r),next unless $r->ok;
  $tmpdir = $r->result;

  my $c = $preamble{$host};
  if ($c) {
    $r = $m->eval($c);
    warn("Error in $localpreamble preamble for host $host: $r"),next unless $r->ok;
  }

  my $preamble = $host.".preamble.pl";
  if (-r $preamble) {
    local $/ = undef;

    my $code = slurp_file($preamble);
    $r = $m->eval($code);
    warn("Error in $host preamble: $r"),next unless $r->ok;
  }

  $m->put([$dist]) or die "Can't copy distribution in $host\n";

  $r = $m->eval(q{
      my $dist = shift;

      eval('use Archive::Tar');
      if (Archive::Tar->can('new')) {
        # Archive::Tar is installed, use it
        my $tar = Archive::Tar->new;
        $tar->read($dist,1) or die "Archive::Tar error: Can't read distribution $dist\n";
        $tar->extract() or die "Archive::Tar error: Can't extract distribution $dist\n";
      }
      else {
        CORE::system("gunzip $dist") and die "Can't gunzip $dist\n";
        my $tar = $dist;
        $tar =~ s/\.gz$//;
        CORE::system('tar', '-xf', $tar) and die "Can't untar $tar\n";
      }
    },
    $dist # arg for eval
  );

  warn($r), next unless $r->ok;

  $m->chdir($dir)->ok or do {
    warn "$host: Can't change to directory $dir\n";
    next;
  };


  unless ($makebuilder && $build) {
    ($makebuilder, $build) = $m->eval(q{
      return ('Makefile.PL', 'make') if -e 'Makefile.PL';
      return ('Build.PL', './Build') if -e 'Build.PL';
      return '';
    })->Results;
  }

  $r = $m->system("perl $makebuilder $makebuilder_arg");
  print $prefix->("$r");
  next if !$r->ok && $r->stderr;

  $r = $m->system("$build $build_arg");
  print $prefix->("$r");
  next if !$r->ok && $r->stderr;

  $r = $m->system("$build test $build_test_arg");
  print $prefix->("$r");
  warn "Errors while running tests in $host: $r\n" unless $r->ok;

  # Clean files
  $clean_files->();

  if ($report) { 
    open my $rf, '>', "$report.$host" or die "Can't open file log_$report.$host";
      print $rf $LOG;
      print $rf "\n";
    close($rf);
  }

  exit(0) if $parallel;
}

if ($parallel) {
  wait for @ARGV;
}

__END__

=head1 NAME

remotetest.pl - make tests on a remote machine


=head1 SYNOPSYS

  remotetest.pl MyInteresting-Dist-1.107.tar.gz machine1.domain machine2.domain
  remotetest.pl  -l some.preamble.pl MyInteresting-Dist-1.107.tar.gz machine1.domain ...
  remotetest.pl  -rep reportfile MyInteresting-Dist-1.107.tar.gz machine1.domain ...

=head1 MOTIVATION

Check your Perl distribution on diferent platforms avoiding the familiar excuse
I<It works on my machine>.

=head1 REQUIREMENTS

The script assumes that 
automatic authentification via SSH has been set up with each of the remote 
UNIX machines.


=head1 DESCRIPTION

The script C<remotetest.pl> copies  the specified Perl distribution 

                MyInteresting-Dist-1.107.tar.gz

(see L<ExtUtils::MakeMaker> and L<Module::Build>) to each of the listed machines 
C<machine1.domain>, C<machine2.domain>, etc. 
and proceeeds to  test the distribution (C<make test>) on these machines.
Namely, it does the following steps:

=over 2

=item * Evals a preamble Perl file named by default C<local.preamble.pl>. Use that file
to init any configuration variables and set up things in both the local and
remote machines 

=item *  For each of the machines C<machine1.domain>, C<machine2.domain>, etc.

=over 2

=item - A C<ssh> connection is open. If a file with name C<preamble.$machine.pl> exists
(being C<$machine> the name of the machine) it will be evaluated in the remote machine C<$machine>.
A temporary directory is created and the distribution is transferred
(using C<scp>) to that directory

=item - The distribution is unpacked using C<tar> and C<gunzip>. The program then changes directory
to the distribution directory

=item - If a file C<Makefile.PL> exists, the classical sequence

                      perl Makefile.PL
                      make
                      make test

takes place. Otherwise, if a file C<Build.PL> exists, the default sequence is

                      perl Build.Pl
                      ./Build
                      ./Build test

Options can be passed in each of these steps setting some variables in
C<local.preamble.pl> (See section L<SPECIAL VARIABLES>)

=item - In case of error the program will proceed with the next machine in the list
of arguments

=item - After reporting the test results, the temporary directories
and files are removed

=back

=back

=head1 THE LOCAL PREAMBLE FILE  

The local preamble file (by default C<local.premable.pl>) can be used
to initialize the state both in the local and remote machines.
If the command option C<--localpreamble filename> is 
specified C<filename> will be used instead of C<local.premable.pl>

If exists the preamble file is used to set the variables that govern the 
execution and the environment in which the tests will be performed.
The public variables are:

=head2 SPECIAL VARIABLES

The following variables have a special meaning:

=over 2

=item *  C<$makebuilder> 

the name of the Perl program that builds the builder. Defaults
to C<Makefile.PL> if the distribution has one. Otherwise it defaults to C<Build.PL>  
if the distribution has one.
If you set a value for C<$makebuilder> and C<$build> these will be used instead.

=item * C<$build> 

defaults to C<make> or C<./Build>

=item * C<$makebuilder_arg>  

arguments for C<perl Makefile.PL> or C<perl Build.PL>

=item * C<$build_arg> 

arguments for C<make> or C<./Build>

=item * C<$build_test_arg> 

arguments for C<make test> or C<./Build test>

=item * C<%preamble> 

hash indexed in the machine IPs/names. Values are
strings containing the preamble code that will be evaluated in
the corresponding machine when the SSH connection is set

=back

=head1 THE REMOTE PREAMBLE FILES 

When conecting to C<machine1.domain> the program checks if a file
with name C<machine1.domain.premable.pl> exists. If so it will be 
loaded and evaluated in such machine before running the tests.
Settings in this file take precedence over the ones in the hash C<%preamble>

=head1 LIMITATIONS

=over 2

=item *
No input from C<STDIN> is allowed either in your C<Makefile.PL> (or C<Build.PL>)
or during any of the testing phases, i.e. your programs must run in batch mode

=item * The current version does not allow to change the arguments for C<perl Makefile.PL>,
etc. on a machine basis. The sequence of commands is the the same in each machine

=back


=head1 EXAMPLE

I have a file named C<local.preamble.pl> in the distribution directory
of C<GRID::Machine>:

  pp2@nereida:~/LGRID_Machine$ cat -n local.preamble.pl
     1  # This code is executed in the local machine
     2
     3  # Redefine them if needed
     4  #our $makebuilder = 'Makefile:PL';
     5  #our $build = 'make';
     6  #our $makebuilder_arg = ''; # s.t. like INSTALL_BASE=~/personalmodules
     7  #our $build_arg = '';       # arguments for "make"/"Build"
     8
     9  our $build_test_arg = 'TEST_VERBOSE=1';
    10
    11  # This code will be executed in the remote servers
    12  our %preamble = (
    13    beowulf => q{ $ENV{GRID_REMOTE_MACHINE} = "orion"; },
    14    orion   => q{ $ENV{GRID_REMOTE_MACHINE} = "beowulf"; },
    15  );


Now when I run C<remotetest.pl> for a distribution in machine C<beowulf>
the environment variable C<GRID_REMOTE_MACHINE> will be set in C<beowulf> prior
to the execution of the tests and the tests will run with C<TEST_VERBOSE=1>:

  pp2@nereida:~/LGRID_Machine$ remotetest.pl GRID-Machine-0.091.tar.gz beowulf
  ************beowulf************
  Checking if your kit is complete...
  Looks good
  Writing Makefile for GRID::Machine
  cp lib/GRID/Machine.pm blib/lib/GRID/Machine.pm
  ...............................................................
  /usr/bin/perl "-MExtUtils::MY" -e "MY->fixin(shift)" blib/script/remotetest.pl
  Manifying blib/man1/remotetest.pl.1p
  ...............................................................
  PERL_DL_NONLAZY=1 /usr/bin/perl "-MExtUtils::Command::MM" \
    "-e" "test_harness(1, 'blib/lib', 'blib/arch')" t/*.t
  t/01synopsis..............1..10
  ok 1 - use GRID::Machine;
  ok 2 - No fatals creating a GRID::Machine object
  ok 3 - installed sub on remote machine
  ok 4 - RPC didn't died
  ok 5 - nested structures
  ok 6 - Remote died gracefully
  ok 7 - Syntax error correctly catched
  ok 8 - Undefined subroutine error correctly catched
  ok 9 - Equal local references look equal on the remote side
  ok 10 - Equal remote references look equal on the local side
  ok
  t/02pod...................1..138
  ............................................................
  All tests successful.
  Files=12, Tests=213, 19 wallclock secs ( 3.12 cusr +  0.32 csys =  3.44 CPU)


To make things more comfortable, I usually set in function C<MY::postamble>
inside the C<Makefile.PL> a target C<remotetest> (see L<ExtUtils::MakeMaker>)

  sub MY::postamble {
          my @machines = qw{orion beowulf};

  remotetest:
          remotetest.pl \${DISTVNAME}.tar.gz @machines
  EOT
  }

this way I can simply run the remote test by writing :

  pp2@nereida:~/LGRID_Machine$ make remotetest
  scripts/remotetest.pl GRID-Machine-0.091.tar.gz orion beowulf
  ************orion************
  Checking if your kit is complete...
  Looks good
  ...................................


=head1 AUTHOR

Casiano Rodriguez Leon E<lt>casiano@ull.esE<gt>

=head1 COPYRIGHT

(c) Copyright 2008 Casiano Rodriguez-Leon

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

