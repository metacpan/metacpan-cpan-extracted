package Linux::Event;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.009';

use Linux::Event::Loop;

sub new ($class, %args) {
  return Linux::Event::Loop->new(%args);
}

1;

__END__

=head1 NAME

Linux::Event - Front door for the Linux::Event ecosystem

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;

  my $loop = Linux::Event->new( backend => 'epoll' );

  # Timers use seconds (float allowed)
  $loop->after(0.100, sub ($loop) {
    say "tick";
    $loop->stop;
  });

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event> is a Linux-focused event loop ecosystem. This distribution
currently provides:

=over 4

=item * L<Linux::Event::Loop> - main event loop (epoll + timerfd + signalfd + eventfd + pidfd)

=item * L<Linux::Event::Watcher> - mutable watcher handles returned by the loop

=item * L<Linux::Event::Signal> - signalfd adaptor (signal subscriptions)

=item * L<Linux::Event::Wakeup> - eventfd-backed wakeups (loop waker)

=item * L<Linux::Event::Pid> - pidfd-backed process exit notifications

=item * L<Linux::Event::Scheduler> - internal deadline scheduler (nanoseconds)

=item * L<Linux::Event::Backend> - backend contract boundary

=item * L<Linux::Event::Backend::Epoll> - epoll backend implementation

=back


=head1 STATUS

As of version 0.006, the public API of this distribution is considered stable.

Linux::Event intentionally exposes Linux primitives with explicit semantics and minimal policy:

  * epoll for I/O readiness
  * timerfd for timers
  * signalfd for signals
  * eventfd for explicit wakeups
  * pidfd (via L<Linux::FD::Pid>) for process exit notifications

Future releases will be additive and will not change existing callback ABIs or dispatch order.

=head1 REPOSITORY

The project repository is hosted on GitHub:

L<https://github.com/haxmeister/perl-linux-event>

=head1 SEE ALSO

L<Linux::Event::Loop>, L<Linux::Event::Watcher>, L<Linux::Event::Backend>,
L<Linux::Event::Scheduler>

=head1 VERSION

This document describes Linux::Event version 0.006.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=cut
