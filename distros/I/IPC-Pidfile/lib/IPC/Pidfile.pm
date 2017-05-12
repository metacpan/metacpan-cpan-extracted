use strict;
use warnings;
package IPC::Pidfile;
$IPC::Pidfile::VERSION = '0.02';
# ABSTRACT: run only one instance of a program at a time
our $DEBUG = $ENV{IPC_PIDFILE_DEBUG};
our $PID = pid();

# signal handler
$SIG{TERM} = $SIG{INT} = sub { exit(0) };

pidfile_lock();

END { pidfile_clear() }


sub pidfile_name  { "$0.pid" }

sub pidfile_lock
{
  print "$PID pidfile_lock\n" if $DEBUG;
  die "$0 is already running\n" if (-e pidfile_name()) && pidfile_is_fresh();
  open my $pidfile, '>', pidfile_name() or die 'Unable to open pidfile ' . pidfile_name();
  select((select($pidfile), $| = 1)[0]);
  print $pidfile pid();
  close $pidfile;
  return 1;
}

sub pidfile_is_fresh
{
  print "$PID pidfile_is_stale\n" if $DEBUG;
  # kill isnt portable
  if ($^O ne 'MSWin32')
  {
    my $pid = pidfile_read();
    return kill 0, $pid;
  }
  return 0;
}

sub pid
{
  my $pid = $$;
  # Win32 pids have a trailing newline?!
  chomp $pid;
  return $pid;
}

sub pidfile_read
{
  print "$PID pidfile_read\n" if $DEBUG;
  open my $pidfile, '<', pidfile_name() or die 'Unable to open pidfile ' . pidfile_name();
  my $pid = do { local($/);<$pidfile> };
  close $pidfile;
  chomp $pid;

  # avoid negative pid numbers and garbage
  die "pidfile appears corrupted: $pid\n" unless $pid =~ /^[0-9]+$/;
  return $pid;
}

sub pidfile_clear
{
  print "$PID pidfile_clear\n" if $DEBUG;
  if (pid() eq pidfile_read())
  {
    unlink pidfile_name() or die "Unable to delete pidfile " . pidfile_name();
  }
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Pidfile - run only one instance of a program at a time

=head1 VERSION

version 0.02

=head1 SYNOPSIS

Just import the module:

  #!/usr/bin/env perl
  use IPC::Pidfile;

  ... # program code here

This will create a pidfile for the program and clear it up when the program is
finished.

=head1 DESCRIPTION

C<IPC::Pidfile> is a module for use with Perl programs when you only want one
instance of the script to run at a time. It should work for you if:

=over 4

=item *

You are OK with the pidfile being created in the same directory as the
script

=item *

You are not using an obscure OS. (Linux, BSD, OSX and Windows should be OK,
see CPANTESTERS).

=item *

Your program is not using signal handlers for C<SIGINT> and C<SIGTERM>.
C<IPC::Pidfile> uses these to clear up the pidfile at the end of the process

=back

=head1 WARNING

This module has a race condition as it attempts to remove the pidfile. It
might be better to use C<IPC::Lockfile>.

=head1 BUGS/ISSUES

Race condition (see L<#WARNING>).

This is an early release and may contain bugs. To run C<IPC::Pidfile> in
debug mode, create the environment variable C<IPC_PIDFILE_DEBUG>:

  IPC_PIDFILE_DEBUG=1 ./path/to/program

=head1 AUTHOR

David Farrell <dfarrell@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Farrell.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
