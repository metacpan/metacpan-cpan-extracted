package Linux::Event;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.010';

use Linux::Event::Loop;

sub new ($class, %args) {
  return Linux::Event::Loop->new(%args);
}

1;

__END__

=head1 NAME

Linux::Event - Front door for the Linux::Event reactor and proactor ecosystem

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;

  # The default model is the reactor.
  my $reactor = Linux::Event->new;

  $reactor->after(0.250, sub ($loop) {
    say "reactor timer fired";
    $loop->stop;
  });

  $reactor->run;

  # Choose the proactor explicitly.
  my $proactor = Linux::Event->new(
    model   => 'proactor',
    backend => 'uring',
  );

  my $op = $proactor->read(
    fh          => $fh,
    len         => 4096,
    on_complete => sub ($op, $result, $data) {
      if ($op->failed) {
        warn $op->error->message;
        return;
      }

      my $bytes = $result->{bytes};
      my $buf   = $result->{data};
    },
  );

=head1 DESCRIPTION

C<Linux::Event> is the front door for the Linux::Event distribution.
C<Linux::Event-E<gt>new> returns a L<Linux::Event::Loop>, which then selects a
reactor or proactor engine.

<<<<<<< HEAD
The distribution is intentionally split into clear layers.
=======
In this distribution, C<Linux::Event-E<gt>new> returns a L<Linux::Event::Loop>.
That keeps the common case short while allowing the loop implementation to stay
in its own module. Model selection is explicit and required: callers must pass
C<model =E<gt> 'reactor'> or C<model =E<gt> 'proactor'>.

This distribution provides the core loop and kernel-primitive adaptors:
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

=over 4

=item * L<Linux::Event::Loop>

Selector and public front door. It chooses a reactor or proactor engine and
forwards the public API.

=item * L<Linux::Event::Reactor>

Readiness-based engine built around epoll plus Linux timer, signal, wakeup, and
pid primitives.

=item * L<Linux::Event::Proactor>

Completion-based engine built for io_uring-style operations.

=item * L<Linux::Event::Watcher>

Mutable watcher handle returned by reactor C<watch()> registrations.

=item * L<Linux::Event::Operation>

In-flight operation object returned by proactor submissions.

=item * L<Linux::Event::Error>

Lightweight failure object for proactor operations.

=back

=head1 ARCHITECTURE

The distribution now has two peer engines under one front door:

  Linux::Event::Loop
      |
      +-- Linux::Event::Reactor
      |       |
      |       +-- Linux::Event::Reactor::Backend::Epoll
      |
      +-- Linux::Event::Proactor
              |
              +-- Linux::Event::Proactor::Backend::Uring
              +-- Linux::Event::Proactor::Backend::Fake

Use the reactor when you want readiness callbacks over existing filehandles.
Use the proactor when you want explicit operation objects and completion-based
I/O.

=head1 MODEL SELECTION

The default model is C<reactor>:

  my $loop = Linux::Event->new;

Select a model explicitly when you want to make the choice obvious in the
calling code:

  my $reactor = Linux::Event->new(model => 'reactor');
  my $proactor = Linux::Event->new(model => 'proactor');

Backend names are model-specific. In this release:

=over 4

=item * reactor: C<epoll>

=item * proactor: C<uring>, C<fake>

=back

=head1 ECOSYSTEM LAYERING

This distribution intentionally stays at the loop-and-primitives layer. Higher
level networking remains in companion distributions:

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

=back

=head1 EXAMPLES

See the C<examples/> directory for small, current examples covering both the
reactor and proactor models.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=cut
