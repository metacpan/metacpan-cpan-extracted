use strict;
use warnings;
package IPC::OpenAny;
{
  $IPC::OpenAny::VERSION = '0.005';
}

# ABSTRACT: Run a process with control over any FDs it may use.

use English qw(-no_match_vars);
use Carp;
use autodie;
use Data::Dumper;
use Params::Util qw(_STRING _ARRAYLIKE _CODELIKE);

use parent 'Exporter';
our @EXPORT_OK = qw(openany);

our $DEBUG = 0;

# TODO: Figure out how to send IO to/from scalar vals.
#       It should probably be done in another module wrapping this one.
# TODO: validate all fds to make sure they are either a filehandle or undef.
# TODO: validate cmd spec as well... etc, etc.

sub run {
  my (undef, %opt) = @_;
  my $cmd_spec = delete $opt{cmd_spec} or die "cmd_spec parameter is required!\n";
  my $fds      = delete $opt{fds};
  my $env      = delete $opt{env};
  my $pwd      = delete $opt{pwd};
  my $pid      = __fork_cmd($cmd_spec, $fds, $env, $pwd);
  waitpid $pid, 0 if $opt{wait};
  return $pid;
}

sub openany { __PACKAGE__->run(@_) }

# fork a child process in which to run the command/sub
sub __fork_cmd {
  my ($cmd_spec, $fds, $env, $pwd) = @_;

  my $pid = fork();
  return $pid if $pid;

  ### now in child process...

  # set up working directory
  chdir $pwd if $pwd;

  # set up environment
  $ENV{$_} = $env->{$_} for keys %$env;

  # go!
  __setup_child_fds($fds);
  __exec_cmd($cmd_spec);

  die "pid $PID should never have gotten here.";
}

# do all the file-descriptor magic that the user asked for...
sub __setup_child_fds {
  my ($fds) = @_;

  # close all fds that are explicitly mapped to undef...
  for my $fd ( grep { ! defined $fds->{$_} } keys %$fds) {
    defined POSIX::close($fd) or die "Couldn't close descriptor [$fd] in pid [$PID]: $!\n";
    next;
  }

  # figure out what gets mapped to what (parent => client)
  my %p_map =
    map { fileno($fds->{$_}) => $_ }
    grep { defined $fds->{$_} }
    keys %$fds;

  my %c_map = reverse %p_map;

  # setup file descriptors in child, closing and duping etc.
  my %redir_fds;
  while ( my ($c_fd, $p_fd) = each %c_map ) {

    delete $p_map{$p_fd};
    next if $c_fd == $p_fd;

    $redir_fds{$c_fd} = POSIX::dup($c_fd) if $p_map{$c_fd};
    $p_fd = $redir_fds{$p_fd} if $redir_fds{$p_fd};

    defined POSIX::close($c_fd) or die "Couldn't close descriptor [$c_fd] in pid [$PID]: $!\n";
    defined POSIX::dup2($p_fd, $c_fd) or die "Couldn't dup2 [$p_fd],[$c_fd] in pid [$PID]: $!\n";
    print STDOUT "Dup2 [$p_fd], [$c_fd]\n" if $DEBUG;
  }

#my $tmp = POSIX::dup(1);
#POSIX::dup2(2,1);
#POSIX::dup2($tmp,2);
#print "TMP: [$tmp]\n";

}

# finally, exec the command or sub.
sub __exec_cmd {
  my ($cmd_spec) = @_;

  print Dumper $cmd_spec if $DEBUG;

  if (_STRING($cmd_spec)) {
    exec $cmd_spec or die "Cannot exec [$cmd_spec]: $!\n";
  }

  if (_CODELIKE($cmd_spec)) {
    exit $cmd_spec->();
  }

  if (_ARRAYLIKE($cmd_spec)) {

    if (_CODELIKE($cmd_spec->[0])) {
      my $code = shift @$cmd_spec;
     exit $code->(@$cmd_spec);
    }

    exec(@$cmd_spec) or die "Cannot exec [$cmd_spec->[0]]: $!\n";
 }

 croak "Invalid cmd_spec!\n";
}

1 && q{this statement is true};


=pod

=head1 NAME

IPC::OpenAny - Run a process with control over any FDs it may use.

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use IPC::OpenAny qw(openany);

  open my $fh, '>', 'fd3_out.txt';

  my $cmd_sub = sub {
    print STDOUT  "foo1\n";
    print STDERR  "foo2\n";
    my $fd3_fh = IO::Handle->new_from_fd(3, '>');
    print $fd3_fh "foo3\n";
  };

  # call the class method
  my $pid = IPC::OpenAny->run(
    cmd_spec => $cmd_sub,
    fds => {
      0 => undef,    # close this
      1 => \*STDERR, # foo1
      2 => \*STDOUT, # foo2
      3 => $fh,      # foo3
    },
    wait => 1,
  );


  # OR use the exported sub
  open my $fd1_fh, '<', $0;
  my $pid2 = openany(
    cmd_spec => [qw(tr a-zA-Z n-za-mN-ZA-M)],
    fds => {
      0 => $fd1_fh,
    },
  );

=head1 DESCRIPTION

B<THIS SOFTWARE IS STILL UNDER DEVELOPMENT PLEASE REPORT ANY BUGS, COMMENTS,
OR FEATURE REQUESTS>

In the spirit of L<IPC::Open2> and L<IPC::Open3>, which give you 2 and 3 handles
to a child process, IPC::OpenAny makes it easy to start a process with any
file descriptors you want connected to whatever handles you want.

=head1 METHODS

=head2 run

Runs the given command or code-ref in a separate process, with its
file descriptors mapped to handles or closed (or just left alone)
however the user may choose.

Accepts the following parameters:

=over 4

=item cmd_spec

This specifies the command or code to be executed.
If it is a string, it will be passed to L<exec>() which
will invoke it via the shell. If it is a coderef, that
coderef will be executed in a sepearate process just
like a system command. If it is an arrayref, the first
element will be used as the system command to execute,
and the remaining elements will be the arguments passed
to it. (I<string> | I<coderef> | I<arrayref>)

=item fds

Set this to a hashref where the keys are file descriptor
numbers in the child process and the values are either
perl file handles or undef. (I<hashref>)

=item env

Set this to a hashref where the keys are the names of environment
variables and the values are the values you want set for those env
vars when the process is executed. (I<hashref>)

=item pwd

Set this to the path you want to be the working directory of the
process that will be executed. (I<string>)

=back

=head1 FUNCTIONS

=head2 openany

This exportable sub is just a thin wrapper around the L</run>
method above. It takes the exact same parameters.

=head1 SEE ALSO

=over 4

=item *

L<IPC::Open2>

=item *

L<IPC::Open3>

=item *

L<IPC::Run>

=item *

L<IPC::Cmd>

=back

=head1 CAVEATS

May not work on Win32, and I don't have a windows box with which to
develop and test it. Patches welcome!

As usual, please report any other issues you may encounter!

=head1 AUTHOR

Stephen R. Scaffidi <sscaffidi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Stephen R. Scaffidi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

