# (X)Emacs mode: -*- cperl -*-

package test;

=head1 NAME

test - tools for helping in test suites

=head1 SYNOPSIS

  use FindBin               1.42 qw( $Bin );
  use Test                  1.13 qw( ok plan );

  BEGIN { unshift @INC, $Bin };

  use test                  qw( DATA_DIR
                                evcheck runcheck );

  BEGIN {
    plan tests  => 3,
         todo   => [],
         ;
  }

  {
    my $outcount = 1;
    my ($out, $err) = '';
    my $teststring = "\n__FOO__\n\n";
    ok runcheck
        ( [[':psreplace',
            -v => 'TEST=Cholet', -D => 'TEST', ],
           '<', \$teststring,
           '>', \$out, '2>', \$err],
          "psreplace -D",
          \$err,
        ), 1, 'runcheck -D';
    ok $out, "\nCholet\n\n", 'outputcheck -D';
  }

  ok evcheck(sub {
               open my $fh, '>', 'foo';
               print $fh "$_\n"
                 for 'Bulgaria', 'Cholet';
               close $fh;
             }, 'write foo'), 1, 'write foo';

  save_output('stderr', *STDERR{IO});
  warn 'Hello, Mum!';
  print restore_output('stderr');

=head1 DESCRIPTION

This package provides some variables, and sets up an environment, for test
scripts, such as those used in F<t/>.

Setting up the environment includes:

=over 4

=item Pushing the module F<lib/> dir onto the @PERL5LIB var

For executed scripts.

=item Pushing the module F<lib/> dir onto the @INC var

For internal C<use> calls.

=item Changing directory to a temporary directory

To avoid cluttering the local dir, and/or allowing the local directory
structure to affect matters.

=item Cleaning up the temporary directory afterwards

Unless TEST_DEBUG is set in the environment.

=back

=cut

# ----------------------------------------------------------------------------

# Pragmas -----------------------------

use v5.6.1;
use strict;
use warnings;

# Inheritance -------------------------

use base qw( Exporter );

=head2 EXPORTS

The following symbols are exported upon request:

=over 4

=item BIN_DIR

=item DATA_DIR

=item REF_DIR

=item LIB_DIR

=item only_files

=item runcheck

=item simple_run_test

=item evcheck

=item tmpnam

=back

=cut

our @EXPORT_OK = qw( BIN_DIR DATA_DIR REF_DIR LIB_DIR
                     only_files runcheck simple_run_test evcheck
                     save_output restore_output tmpnam );

# Utility -----------------------------

use Carp                          qw( carp croak );
use Env                           qw( @PERL5LIB );
use Fatal                    1.02 qw( :void close open seek sysopen unlink );
use Fcntl                    1.03 qw( :DEFAULT :seek );
use File::Basename            2.6 qw( basename );
use File::Compare          1.1002 qw( compare );
use File::Path             1.0403 qw( mkpath rmtree );
use File::Spec::Functions         qw( catdir catfile updir );
use File::Temp               0.12 qw( tempfile tempdir );
use FindBin                  1.42 qw( $Bin );
use IPC::Run                 0.44 qw( harness run );
use Test                     1.13 qw( ok );

# ----------------------------------------------------------------------------

# -------------------------------------
# PACKAGE CONSTANTS
# -------------------------------------

use constant BIN_DIR  => catdir $Bin, updir, 'bin';
use constant DATA_DIR => catdir $Bin, updir, 'data';
use constant REF_DIR  => catdir $Bin, updir, 'testref';
use constant LIB_DIR  => catdir $Bin, updir, 'lib';

# -------------------------------------
# PACKAGE ACTIONS
# -------------------------------------

unshift @PERL5LIB, LIB_DIR;
unshift @INC,      LIB_DIR;

my $tmpdn = tempdir(CLEANUP => ( ! defined $ENV{TEST_DEBUG}     or
                                 $ENV{TEST_DEBUG} !~ /\bSAVE\b/ ));
mkpath $tmpdn;
die "Couldn't create temp dir: $tmpdn: $!\n"
  unless -r $tmpdn and -w $tmpdn and -x $tmpdn and -o $tmpdn and -d $tmpdn;
CHECK {
  chdir $tmpdn;
}

END {
  print STDERR "Used tmp dir: $tmpdn\n"
    if defined $ENV{TEST_DEBUG} and $ENV{TEST_DEBUG} =~ /\bSAVE\b/;
}

# -------------------------------------
# PACKAGE FUNCTIONS
# -------------------------------------

=head2 runcheck

Run an external command, check the results.

=over 4

=item ARGUMENTS

=over 4

=item runargs

An arrayref of arguments as for L<IPC::Run/run>, excepting that array ref
arguments with an initial C<:> character on the first member will be
considered as perl scripts in the module built to run.

For example, an invocation of

  runcheck([':reverse'], '<', '/etc/passwd');

will convert the initial reverse to treat it as a perl script called
F<reverse> to find in the module, and execute that with the current running
perl.  The remaining arguments are left as is.

=item name

The name of the program to refer to in error messages

=item errref

Reference to a scalar to read in case of error.  Normally, this is bound to a
scalar where is deposited the stderr out of the command, using arguments

  '2>', $err

in L</runargs>.

=back

=item RETURNS

=over 4

=item success

1 if the command executed without failure; false otherwise.

=back

=back

=cut

sub runcheck {
  my ($runargs, $name, $errref) = @_;

  my @args = map({ ( ref $_ eq 'ARRAY' and substr($_->[0],0,1) eq ':') ?
                     [ $^X, catfile(BIN_DIR, substr($_->[0],1)),
                       @{$_}[1..$#$_] ]                                :
                     $_ }
                 @$runargs);
  my $harness = harness(@args);
  run $harness;
  my $rv = $harness->full_result;
  if ( $rv ) {
    if ( $ENV{TEST_DEBUG} ) {
      warn sprintf("$name failed: exit/sig/core %d/%d/%d\n",
                   $rv >> 8, $rv & 127, ( $rv & 128 ) >> 7);
      warn "  $$errref\n"
        if defined $errref and defined $$errref and $$errref !~ /^\s*$/;
    }
    return;
  } else {
    return 1;
  }
}

# -------------------------------------

=head2 simple_run_test

This is designed to simplify the job of running a program, and testing the
output.  It performs 2+n tests; that the command executed without error, that
the n files named in the C<checkfiles> argument are each as expected, and that
no other files exist.

All files in the current directory are wiped after the test in preparation for
the next test.

=over 4

=item ARGUMENTS

The arguments are considered as name/value pairs.

=over 4

=item runargs

B<Mandatory>.  This is an arrayref; as for the runargs argument to
L<runcheck|/runcheck>.

=item name

B<Mandatory>.  The name to use in error messages.

=item checkfiles

This is an arrayref of files to check.  The named files are considered
relative to the working directory, and are checked against files taken
relative to the F<testref> directory of the build.  Therefore, absolute file
names are non-sensical, and will raise an exception.

=item errref

A ref to a scalar potentially containing any error output.  Typically, the
stderr of the command run is redirected to this by the runargs argument.

=item testref_subdir

A subdirectory of the testref directory in which to find the files to check
against.

=back

=item RETURNS

I<None>

However, 2+n tests are performed, with ok/not ok sent to stdout.

=back

=cut

sub simple_run_test {
  my (%arg) = @_;

  die sprintf("%s: missing mandatory argument: %s\n", (caller(0))[3], $_)
    for grep ! exists $arg{$_}, qw( runargs name );

  ${$arg{errref}} = ''
    if exists $arg{errref};
  my $runok = runcheck(@arg{qw(runargs name errref)});

  ok $runok, 1, $arg{name};

  my $ref_dir = (exists $arg{testref_subdir}           ?
                 catdir(REF_DIR, $arg{testref_subdir}) :
                 REF_DIR);

  if ( exists $arg{checkfiles} ) {
    for (@{$arg{checkfiles}}) {
      my $target = catfile($ref_dir, basename $_);
      if ( -e $target ) {
        ok(compare($_, $target), 0, "$arg{name}: check file $_");
      } else {
        ok 0, 1, "$arg{name}: missing reference file $target";
      }
    }
  }

  ok(only_files($arg{checkfiles}), 1, "$arg{name}: no extra files");
  # Clean up files for next test.
  opendir my $dir, '.';
  unlink $_
    for grep !/^\.\.?$/, readdir $dir;
  closedir $dir;
}

# -------------------------------------

=head2 only_files

=over 4

=item ARGUMENTS

=over 4

=item expect

Arrayref of names of files to expect to exist.

=back

=item RETURNS

=over 4

=item ok

1 if exactly expected files exist, false otherwise.

=back

=back

=cut

sub only_files {
  my ($expect) = @_;

  opendir my $dir, '.';
  my %files = map { $_ => 1 } readdir $dir;
  closedir $dir;

  my $ok = 1;

  for (@$expect, '.', '..') {
    if ( exists $files{$_} ) {
      delete $files{$_};
    } elsif ( ! -e $_ ) { # $_ might be absolute
      carp "File not found: $_\n"
        if $ENV{TEST_DEBUG};
      $ok = 0;
    }
  }

  for (keys %files) {
    carp "Extra file found: $_\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  if ( $ok ) {
    return 1;
  } else {
    return;
  }
}

# -------------------------------------

=head2 evcheck

Eval code, return status

=over 4

=item ARGUMENTS

=over 4

=item code

Coderef to eval

=item name

Name to use in error messages

=back

=item RETURNS

=over 4

=item okay

1 if eval was okay, 0 if not.

=back

=back

=cut

sub evcheck {
  my ($code, $name) = @_;

  my $ok = 0;

  eval {
    &$code;
    $ok = 1;
  }; if ( $@ ) {
    carp "Code $name failed: $@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  return $ok;
}

# -------------------------------------

=head2 save_output

Redirect a filehandle to temporary storage for later examination.

=over 4

=item ARGUMENTS

=over 4

=item name

Name to store as (used in L<restore_output>)

=item filehandle

The filehandle to save

=back

=cut

# Map from names to saved filehandles.

# Values are arrayrefs, being filehandle that was saved (to restore), the
# filehandle being printed to in the meantime, and the original filehandle.
# This may be treated as a stack; to allow multiple saves... push & pop this
# stack.

my %grabs;

sub save_output {
  croak sprintf("%s takes 2 arguments\n", (caller 0)[3])
    unless @_ == 2;
  my ($name, $filehandle) = @_;

  my $tmpfh = tempfile;
  select((select($tmpfh), $| = 1)[0]);

  open my $savefh, '>&' . fileno $filehandle
    or die "can't dup $name: $!";
  open $filehandle, '>&' . fileno $tmpfh
    or die "can't open $name to tempfile: $!";

  push @{$grabs{$name}}, $savefh, $tmpfh, $filehandle;
}

# -------------------------------------

=head2 restore_output

Restore a saved filehandle to its original state, return the saved output.

=over 4

=item ARGUMENTS

=over 4

=item name

Name of the filehandle to restore (as passed to L<save_output>).

=back

=item RETURNS

=over 4

=item saved_string

A single string being the output saved.

=back

=cut

sub restore_output {
  my ($name) = @_;

  croak "$name has not been saved\n"
    unless exists $grabs{$name};
  croak "All saved instances of $name have been restored\n"
    unless @{$grabs{$name}};
  my ($savefh, $tmpfh, $origfh) = splice @{$grabs{$name}}, -3;

  close $origfh
    or die "cannot close $name opened to tempfile: $!";
  open  $origfh, '>&' . fileno $savefh
    or die "cannot dup $name back again: $!";

  seek $tmpfh, 0, SEEK_SET;
  local $/ = undef;
  my $string = <$tmpfh>;
  close $tmpfh;

  return $string;
}

sub _test_save_restore_output {
  warn "to stderr 1\n";
  save_output("stderr", *STDERR{IO});
  warn "Hello, Mum!";
  print 'SAVED:->:', restore_output("stderr"), ":<-\n";
  warn "to stderr 2\n";
}

# -------------------------------------

=head2 tmpnam

Very much like the one in L<POSIX> or L<File::Temp>, but does not get deleted
if TEST_DEBUG has SAVE in the value.

=over 4

=item ARGUMENTS

I<None>

=item RETURNS

=over 4

=item name

Name of temporary file name.

=item fh

Open filehandle to temp file, in r/w mode.  Only created & returned in list
context.

=back

=back

=cut

my @tmpfns;
sub tmpnam {
  my $tmpnam = File::Temp::tmpnam;

  if (@_) {
    push @tmpfns, [ $tmpnam, $_[0] ];
  } else {
    push @tmpfns, $tmpnam;
  }

  if (wantarray) {
    sysopen my $tmpfh, $tmpnam, O_RDWR | O_CREAT | O_EXCL;
    return $tmpnam, $tmpfh;
  } else {
    return $tmpnam;
  }
}

END {
  if ( defined $ENV{TEST_DEBUG} and $ENV{TEST_DEBUG} =~ /\bSAVE\b/ ) {
    for (@tmpfns) {
      if ( ref $_ ) {
        printf "Used temp file: %s (%s)\n", @$_;
      } else {
        print "Used temp file: $_\n";
      }
    }
  } else {
    unlink map((ref $_ ? $_->[0] : $_), @tmpfns);
  }
}

# ----------------------------------------------------------------------------

=head1 EXAMPLES

Z<>

=head1 BUGS

Z<>

=head1 REPORTING BUGS

Email the author.

=head1 AUTHOR

Martyn J. Pearce C<fluffy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2001, 2002 Martyn J. Pearce.  This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Z<>

=cut

1; # keep require happy.

__END__
