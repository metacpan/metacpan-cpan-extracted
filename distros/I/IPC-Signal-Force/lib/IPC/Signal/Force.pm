=head1 NAME

IPC::Signal::Force - force default handling of a signal

=head1 SYNOPSIS

	use IPC::Signal::Force qw(force_raise);

	force_raise "TERM";

=head1 DESCRIPTION

This module exports one function, C<force_raise>, which invokes a default
signal handler regardless of the signal's current handling.

=cut

package IPC::Signal::Force;

{ use 5.006; }
use warnings;
use strict;

use IPC::Signal 1.00 qw(sig_num);
use POSIX qw(SIG_SETMASK SIG_UNBLOCK sigprocmask);

our $VERSION = "0.003";

use parent "Exporter";
our @EXPORT_OK = qw(force_raise);

=head1 FUNCTIONS

=over

=item force_raise(SIGNAL)

SIGNAL must be the name of a signal (e.g., "TERM").  The specified signal
is delivered to the current process, with the handler for the signal
temporarily reset to the default.  The signal is also temporarily
unblocked if it was initially blocked.  The overall effect is to
synchronously invoke the default handler for the signal, regardless of
how the signal would be handled the rest of the time.

This is mainly useful in a handler for the same signal, if the handler
wants to do something itself and also call the default handler.
For example, a handler for SIGTERM might shut down the program neatly
and then C<force_raise("TERM")>, which achieves a graceful shutdown
while also letting the parent process see that the process terminated
due to a signal rather than by C<exit()>.

A similar, but slightly more complex, case is a handler for SIGTSTP
(tty-initiated stop), which in a curses-style program might need to
restore sane tty settings, C<force_raise("TSTP")>, and then (after
the process has been restarted) reassert control of the tty and redraw
the screen.

=cut

sub force_raise($) {
	my($signame) = @_;
	my $signum = sig_num($signame);
	my $sigset = new POSIX::SigSet $signum;
	my $mask = new POSIX::SigSet;
	local $SIG{$signame};
	kill $signame, 0;
	sigprocmask(SIG_UNBLOCK, $sigset, $mask);
	if($mask->ismember($signum)) {
		sigprocmask(SIG_SETMASK, $mask, $mask);
	}
}

=back

=head1 BUGS

If the signal in question is delivered from somewhere else while
C<force_raise> is executing, there is a race condition that makes it
is possible for the default signal handler to be called more than once.
There appears to be no way to avoid this in POSIX.

=head1 SEE ALSO

L<IPC::Signal>,
L<perlfunc/kill>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2004, 2007, 2010 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
