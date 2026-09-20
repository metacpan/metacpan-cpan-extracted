package Linux::Event::Kernel::Timer;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use Carp qw(croak);
use POSIX qw(isfinite);
use Scalar::Util qw(looks_like_number);

require Linux::Event::Loop;

my %CLASS_DESCRIPTOR;

sub _descriptor_for ($class) {
    return $CLASS_DESCRIPTOR{$class} if exists $CLASS_DESCRIPTOR{$class};
    croak "$class is not a Linux::Event::Kernel::Timer subclass"
        if !$class->isa(__PACKAGE__);
    my $callback = $class->can('on_timer')
        // croak "$class must define on_timer() or receive on_timer => coderef";
    return $CLASS_DESCRIPTOR{$class}
        = Linux::Event::Kernel::Timer::_Descriptor->new($callback);
}

sub _effective_descriptor ($class, $option) {
    croak "$class is not a Linux::Event::Kernel::Timer subclass"
        if !$class->isa(__PACKAGE__);
    return _descriptor_for($class) if !exists $option->{on_timer};
    my $callback = delete $option->{on_timer};
    croak 'new(): on_timer must be a coderef' if ref($callback) ne 'CODE';
    return Linux::Event::Kernel::Timer::_Descriptor->new($callback);
}

sub _seconds ($method, $name, $value, $positive) {
    my $seconds = !defined($value) || ref($value)
        || !looks_like_number($value) ? undef : 0 + $value;
    croak "$method(): $name must be a "
        . ($positive ? 'positive' : 'non-negative')
        . ' number of seconds'
        if !defined($seconds) || !isfinite($seconds)
        || $seconds < 0 || ($positive && $seconds == 0);
    return $seconds;
}

sub _schedule ($method, $option) {
    my @unknown = sort grep {
        $_ ne 'after' && $_ ne 'at' && $_ ne 'every'
    } keys %$option;
    croak "$method(): unknown options: " . join(', ', @unknown) if @unknown;

    my $has_after = exists $option->{after};
    my $has_at = exists $option->{at};
    my $has_every = exists $option->{every};
    croak "$method(): after and at are mutually exclusive"
        if $has_after && $has_at;
    croak "$method(): one of after, at, or every is required"
        if !$has_after && !$has_at && !$has_every;

    my $every = $has_every
        ? _seconds($method, 'every', $option->{every}, 1) : 0;
    my ($absolute, $first);
    if ($has_at) {
        $absolute = 1;
        $first = _seconds($method, 'at', $option->{at}, 0);
    }
    elsif ($has_after) {
        $absolute = 0;
        $first = _seconds($method, 'after', $option->{after}, 0);
    }
    else {
        $absolute = 0;
        $first = $every;
    }
    return ($absolute, $first, $every);
}

sub new ($class, %option) {
    croak 'new(): must be called as a class method' if ref $class;
    my $descriptor = _effective_descriptor($class, \%option);
    my $loop = delete $option{loop};
    croak 'new(): loop must be an object implementing add()'
        if defined($loop) && (!ref($loop) || !$loop->can('add'));
    my $data = delete $option{data};
    my ($absolute, $first, $every) = _schedule('new', \%option);
    my $timer = $class->_new_native(
        $descriptor, $absolute, $first, $every, $data,
    );
    $loop->add($timer) if defined $loop;
    return $timer;
}

sub reschedule ($self, %option) {
    my ($absolute, $first, $every) = _schedule('reschedule', \%option);
    return $self->_reschedule_native($absolute, $first, $every);
}

sub CLONE ($class) {
    %CLASS_DESCRIPTOR = ();
    return;
}

sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Kernel::Timer::_Descriptor;
sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Kernel::Timer;

1;
__END__

=head1 NAME

Linux::Event::Kernel::Timer - monotonic one-shot and recurring Loop timers

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Timer;

  my $loop = Linux::Event::Loop->new;
  my $timer = Linux::Event::Kernel::Timer->new(
      loop     => $loop,
      after    => 1,
      on_timer => sub ($timer) {
          say 'timer fired';
          $timer->loop->stop;
      },
  );
  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Timer> is the public timer leaf. All active timers on a
Loop share the Loop's timerfd-backed native scheduler and indexed minimum heap;
one Timer object does not mean one kernel timer descriptor.

=head1 CALLBACKS AND SUBCLASS POLICY

Pass C<on_timer =E<gt> sub ($timer) { ... }> to C<new> when a timer should
capture lexical application state. Subclassing remains useful for a reusable
timer type with named, testable behavior:

  package Heartbeat;
  use parent 'Linux::Event::Kernel::Timer';

  sub on_timer ($timer) {
      $timer->data->write("ping\n");
  }

A constructor callback overrides the subclass method for that object. The
effective CV is resolved once at construction; recurring delivery does not
repeat method lookup or branch between callback styles.

=head1 SCHEDULES

Construction accepts one schedule:

=over 4

=item C<after =E<gt> $seconds>

Relative one-shot deadline.

=item C<at =E<gt> $monotonic_seconds>

Absolute one-shot deadline using the same monotonic clock returned by
C<< Linux::Event::Kernel::Timer->now >>.

=item C<every =E<gt> $seconds>

Fixed-rate recurrence. C<after> or C<at> may be combined with C<every> to set a
different first deadline.

=back

C<after> and C<at> are mutually exclusive. Public durations are seconds and may
be fractional. Zero-delay work is delivered on a later Loop turn rather than
reentrantly from construction.

=head1 CALLBACK AND RECURRENCE

  sub on_timer ($timer) { ... } # subclass form

or:

  on_timer => sub ($timer) { ... } # constructor form

Recurring timers advance from the previous scheduled deadline rather than from
callback completion. If the Loop is late, missed intervals are coalesced into
one callback; C<expirations> reports how many ticks that callback represents.

Method callbacks are cached per subclass and constructor callbacks per object.
C<data> holds arbitrary application state and C<loop> returns the owning Loop
while attached.

=head1 RESCHEDULING AND CANCELLATION

C<reschedule> accepts the same schedule grammar as construction and returns the
same object. It may be called while active or from C<on_timer>.

C<cancel> is idempotent and terminal. A completed one-shot timer is also
terminal. Active timers are retained by the Loop even if the application drops
its own reference; cancellation, final expiration, or Loop destruction releases
that ownership safely.

=head1 ATTACHMENT

C<loop =E<gt> $loop> attaches during construction. Otherwise construct
detached and use C<< $loop->add($timer) >>. Timer callbacks are ordinary Loop
callbacks and may close I/O objects, schedule other timers, or stop the Loop.

=head1 SEE ALSO

L<Linux::Event::Loop>, F<docs/TIMER-DESIGN.md>,
F<docs/ORDERED-BYTE-DEADLINES.md>.

=cut
