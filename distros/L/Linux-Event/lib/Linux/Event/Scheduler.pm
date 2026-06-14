package Linux::Event::Scheduler;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.012';

use Carp qw(croak);
use Linux::Event::XS ();

sub new ($class, %args) {
  my $clock = delete $args{clock};
  croak "clock is required" if !$clock;
  croak "unknown args: " . join(", ", sort keys %args) if %args;

  for my $m (qw(now_ns deadline_in_ns)) {
    croak "clock missing method '$m'" if !$clock->can($m);
  }

  return bless {
    clock => $clock,
    heap  => Linux::Event::XS::timer_heap_new(),
  }, $class;
}

sub at_ns ($self, $deadline_ns, $cb) {
  croak "deadline_ns is required" if !defined $deadline_ns;
  croak "callback is required"    if !defined $cb;
  croak "callback must be a coderef" if ref($cb) ne 'CODE';

  return Linux::Event::XS::timer_heap_at_ns(
    $self->{heap},
    int($deadline_ns),
    $cb,
  );
}

sub after_ns ($self, $delta_ns, $cb) {
  croak "delta_ns is required" if !defined $delta_ns;
  $delta_ns = int($delta_ns);
  my $deadline = $self->{clock}->deadline_in_ns($delta_ns);
  return $self->at_ns($deadline, $cb);
}

sub cancel ($self, $id) {
  return 0 if !defined $id;
  return Linux::Event::XS::timer_heap_cancel($self->{heap}, int($id));
}

sub next_deadline_ns ($self) {
  return Linux::Event::XS::timer_heap_next_deadline_ns($self->{heap});
}

sub pop_expired ($self) {
  my $now = $self->{clock}->now_ns;
  return Linux::Event::XS::timer_heap_pop_expired($self->{heap}, int($now));
}

1;

__END__

=head1 NAME

Linux::Event::Scheduler - Internal monotonic timer queue for Linux::Event::Loop

=head1 DESCRIPTION

C<Linux::Event::Scheduler> is the internal deadline queue used by the loop.
It stores callbacks keyed by monotonic nanosecond deadlines and returns expired
items in deadline order. The heap is stored in XS while preserving this
Perl wrapper and the existing loop-facing API.

This module is internal. Its API is documented only to explain the structure of
this distribution, not as a stable user-facing contract.

=head1 METHODS

=head2 new(clock => $clock)

Create a scheduler bound to a clock object that provides C<now_ns> and
C<deadline_in_ns>.

=head2 after_ns($delta_ns, $cb)

Schedule a callback relative to the current time.

=head2 at_ns($deadline_ns, $cb)

Schedule a callback for an absolute monotonic deadline.

=head2 cancel($id)

Cancel an existing timer by id.

=head2 next_deadline_ns

Return the next live deadline, if any.

=head2 pop_expired

Return all expired entries as C<[ $id, $cb, $deadline_ns ]> tuples.

=cut
