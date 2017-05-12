package Linux::FD::Timer;
{
  $Linux::FD::Timer::VERSION = '0.011';
}

use 5.006;

use strict;
use warnings;
use Linux::FD ();

1;    # End of Linux::FD::Timer

#ABSTRACT: Timer filehandles for Linux

__END__

=pod

=head1 NAME

Linux::FD::Timer - Timer filehandles for Linux

=head1 VERSION

version 0.011

=head1 SYNOPSIS

 use Linux::FD::Timer;

 my $fh = Linux::FD::Timer->new('monotonic');
 $fh->set_timeout(10, 10);
 while (1) {
     #do something..
     $fh->wait; #until the 10 seconds have passed.
 }

=head1 DESCRIPTION

This module creates and operates on a timer that delivers timer expiration notifications via a file descriptor. It provides an alternative to the use of Time::HiRes' setitimer or POSIX::RT::Timer, with the advantage that the file descriptor may easily be monitored by mechanisms such as select, poll, and epoll.

=head1 METHODS

=head2 new($clockid)

This creates a new timer object, and returns a file handle that refers to that timer. The clockid argument specifies the clock that is used to mark the progress of the timer, and must be either C<'realtime'> or C<'monotonic'>. C<realtime> is a settable system-wide clock. C<monotonic> is a non-settable clock that is not affected by discontinuous changes in the system clock (e.g., manual changes to system time). The current value of each of these clocks can be retrieved using L<POSIX::RT::Clock>.

=head2 get_timeout()

Get the timeout value. In list context, it also returns the interval value. Note that this value is always relative to the current time.

=head2 set_timeout(value, $interval = 0, $abs_time = 0)

Set the timer and interval values. If C<$abstime> is true, they are absolute values, otherwise they are relative to the current time. Returns the old value like C<get_time> does.

=head2 receive

If the timer has already expired one or more times since its settings were last modified using settime(), or since the last successful wait, then receive returns an unsigned 64-bit integer containing the number of expirations that have occurred. If not it either returns undef or it blocks (if the handle is blocking).

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
