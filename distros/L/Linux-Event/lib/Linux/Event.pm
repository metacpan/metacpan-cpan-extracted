package Linux::Event;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.011';

use Linux::Event::Loop;

sub new ($class, %args) {
  return Linux::Event::Loop->new(%args);
}

1;

__END__

=head1 NAME

Linux::Event - Linux-native readiness event loop for Perl

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;

  my $loop = Linux::Event->new;

  $loop->after(0.250, sub ($loop) {
    say "timer fired";
    $loop->stop;
  });

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event> is the front door for a Linux-native readiness event loop. It
currently ships with an epoll backend and uses Linux kernel primitives: timerfd,
signalfd, eventfd, and pidfd.

This distribution intentionally stays at the loop-and-primitives layer. Higher
level socket, stream, and process helpers live in companion distributions.
Additional readiness backends may be added in future releases.

=head1 CONSTRUCTOR

=head2 new(%args)

Create a new loop. With no arguments, the default epoll backend is used:

  my $loop = Linux::Event->new;

You may pass C<backend =E<gt> 'epoll'> explicitly or provide a custom readiness
backend object:

  my $loop = Linux::Event->new(backend => 'epoll');

The old model selector has been removed. Passing C<model> is an error.

=head1 CORE MODULES

=over 4

=item * L<Linux::Event::Loop>

Public readiness loop.

=item * L<Linux::Event::Backend>

Readiness backend contract.

=item * L<Linux::Event::Backend::Epoll>

Built-in epoll backend.

=item * L<Linux::Event::Watcher>

Mutable watcher handle returned by C<watch()> registrations.

=item * L<Linux::Event::Signal>

signalfd adaptor.

=item * L<Linux::Event::Wakeup>

eventfd-backed wakeup primitive.

=item * L<Linux::Event::Pid>

pidfd-backed process-exit notifications.

=item * L<Linux::Event::Scheduler>

Internal monotonic deadline queue.

=back

=head1 ECOSYSTEM LAYERING

Companion distributions provide higher-level building blocks:

=over 4

=item * L<Linux::Event::Listen>

Server-side socket acquisition.

=item * L<Linux::Event::Connect>

Client-side nonblocking outbound connect.

=item * L<Linux::Event::Stream>

Buffered I/O and backpressure management for an established filehandle.

=item * L<Linux::Event::Fork>

Asynchronous child-process helpers built on the loop.

=item * L<Linux::Event::Clock>

Monotonic clock helpers used by the core loop and related modules.

=item * L<Linux::Event::Timer>

timerfd wrapper used by the core loop.

=back

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=cut
