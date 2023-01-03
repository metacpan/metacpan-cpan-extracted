package Linux::FD::Pid;
$Linux::FD::Pid::VERSION = '0.006';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: PID file descriptors

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::FD::Pid - PID file descriptors

=head1 VERSION

version 0.006

=head1 SYNOPSIS

 use Linux::FD::Pid
 
 my $fh = Linux::FD::Pid->new($pid, @flags)

=head1 DESCRIPTION

This creates a pidfd filehandle that can be used to await the termination of a process. This provides an alternative to using C<SIGCHLD>, and has the advantage that the file descriptor may be monitored by select, poll, and epoll.

=head1 METHODS

=head2 new($pid)

This creates a new filehandle object for the designated C<$pid>. C<@flags> is an optional list of flags, currently limited to C<'non-blocking'>.

=head2 send($signal)

This sends a signal to the process. The signal may be given as either a signal number (e.g. C<POSIX::SIGUSR1>) or as a signal name (e.g. C<'USR1'>).

=head2 wait($flags = WEXITED)

This waits for the process to end and returns its return value. It's only allowed to be child of the current process. It takes a flags argument like `waitpid`, the constants for this from the L<POSIX|POSIX> module can be used for this. If either the pidfd is non-blocking or C<WNOHANG> is part of C<$flag> and the process isn't then ready C<undef> is returned instead.

=head2 get_handle($fd)

This duplicates a handle from another process. Permission to duplicate another process's file descriptor is governed by a ptrace access mode C<PTRACE_MODE_ATTACH_REALCREDS> check.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
