package Linux::Event::Kernel::Timer;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use POSIX qw(isfinite);
use Scalar::Util qw(looks_like_number refaddr);

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

sub _fork_preflight ($self, $mode, $loop) {
    my $owner = $self->loop;
    croak 'fork(): Timer is not active in this Loop'
        if !$owner || refaddr($owner) != refaddr($loop) || !$self->is_active;
    croak "fork(): Timer does not support '$mode'"
        if $mode ne 'drop' && $mode ne 'clone' && $mode ne 'move';
    return 1;
}

sub _fork_child_clone ($self, $loop) { $loop->add($self); return }
sub _fork_child_move  ($self, $loop) { $loop->add($self); return }
sub _fork_child_drop  ($self, $loop) { $self->cancel; return }
sub _fork_parent_move ($self, $child_pid) { $self->cancel; return }

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

Linux::Event::Kernel::Timer - Schedule one-time or recurring work

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Timer;

  my $loop = Linux::Event::Loop->new;

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 1,

      on_timer => sub ($self) {
          say "One second has passed";
          $loop->stop;
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Timer> schedules work to happen later on a
L<Linux::Event::Loop>.

A Timer can:

=over 4

=item *

fire once after a delay

=item *

fire once at a particular monotonic-clock time

=item *

repeat at a fixed interval

=item *

start repeating after a different first delay

=item *

be rescheduled while active

=item *

be cancelled

=back

For example, a recurring heartbeat can be written as:

  my $heartbeat = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      every => 15,

      on_timer => sub ($self) {
          $connection->write("ping\n");
      },
  );

All public time values are expressed in B<seconds> and may be fractional.

=head1 ONE-SHOT TIMERS

=head2 after

Use C<after> for a timer relative to now:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 2.5,

      on_timer => sub ($self) {
          say "2.5 seconds later";
      },
  );

C<after> is measured from the time the Timer becomes active on its Loop.

A value of zero is allowed:

  after => 0

but the callback is not invoked immediately from the constructor.

It runs on a later Loop turn.

This avoids surprising reentrant callbacks during object construction.

=head1 RECURRING TIMERS

=head2 every

Use C<every> for a repeating Timer:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      every => 5,

      on_timer => sub ($self) {
          say "Five-second heartbeat";
      },
  );

C<every> must be greater than zero.

With C<every> alone, the first callback occurs after one interval.

For example:

  every => 5

means approximately:

  5 seconds
  10 seconds
  15 seconds
  ...

until the Timer is cancelled or rescheduled.

=head1 A DIFFERENT FIRST DELAY

C<after> may be combined with C<every>:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 1,
      every => 10,

      on_timer => sub ($self) {
          ...
      },
  );

The first callback is scheduled after one second.

Later callbacks occur on the ten-second recurring schedule.

This is useful when the first action should happen quickly but normal repetition
should happen less often.

=head1 ABSOLUTE MONOTONIC DEADLINES

=head2 at

Use C<at> when you already have an absolute monotonic-clock time:

  my $when = Linux::Event::Kernel::Timer->now + 10;

  my $timer = Linux::Event::Kernel::Timer->new(
      loop => $loop,
      at   => $when,

      on_timer => sub ($self) {
          say "deadline reached";
      },
  );

C<at> uses the same monotonic clock returned by:

  Linux::Event::Kernel::Timer->now

It is not wall-clock time.

Do not pass values from C<time()> or calendar timestamps to C<at>.

Monotonic time is intentionally unaffected by wall-clock corrections such as
NTP adjustments or a user changing the system clock.

=head2 at with every

An absolute first deadline may also begin a recurring schedule:

  my $start = Linux::Event::Kernel::Timer->now + 2;

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      at    => $start,
      every => 30,
      ...
  );

The first callback occurs at C<$start> and subsequent callbacks continue at the
configured interval.

=head1 SCHEDULE RULES

The valid schedule forms are:

  after => $seconds

  at => $monotonic_seconds

  every => $seconds

  after => $first_delay,
  every => $interval

  at    => $first_deadline,
  every => $interval

C<after> and C<at> cannot be used together.

C<after> and C<at> are non-negative.

C<every> must be positive.

=head1 THE TIMER CALLBACK

=head2 on_timer

The constructor form is:

  on_timer => sub ($self) {
      ...
  }

The callback receives the Timer object itself.

For example:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      every => 1,

      on_timer => sub ($self) {
          say "tick";
      },
  );

The callback runs as normal Loop work.

It may interact with other Linux::Event resources:

  on_timer => sub ($self) {
      $connection->write("heartbeat\n");
      $listener->pause;
  }

or stop the Loop:

  on_timer => sub ($self) {
      $self->loop->stop;
  }

=head1 CONSTRUCTOR CALLBACKS OR SUBCLASS METHODS

Timer behavior may be supplied directly with C<on_timer>:

  my $timer = Linux::Event::Kernel::Timer->new(
      every => 5,

      on_timer => sub ($self) {
          ...
      },
  );

or implemented by a subclass:

  package Heartbeat;

  use parent 'Linux::Event::Kernel::Timer';

  sub on_timer ($self) {
      $self->data->write("ping\n");
  }

  package main;

  my $timer = Heartbeat->new(
      loop  => $loop,
      every => 5,
      data  => $connection,
  );

A constructor C<on_timer> callback overrides the subclass method for that
particular Timer.

Constructor callbacks are usually simplest when the Timer needs lexical
application state.

Subclassing is useful when the timer behavior itself is reusable.

=head1 APPLICATION DATA

=head2 data

A Timer may carry arbitrary application data:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      every => 5,
      data  => $connection,

      on_timer => sub ($self) {
          $self->data->write("ping\n");
      },
  );

Retrieve it with:

  my $value = $timer->data;

While the Timer is nonterminal, it may also be replaced:

  $timer->data($new_value);

Terminal Timers no longer accept a new C<data> value.

A final one-shot expiration and explicit cancellation release the Timer's
stored application data according to the Timer lifecycle.

=head1 RESCHEDULING

=head2 reschedule

An active Timer can be given a new schedule:

  $timer->reschedule(
      after => 10,
  );

or:

  $timer->reschedule(
      every => 2,
  );

or:

  $timer->reschedule(
      after => 1,
      every => 30,
  );

C<reschedule> accepts the same scheduling forms as C<new>.

It returns the same Timer object.

=head2 Rescheduling from the callback

A Timer may reschedule itself:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 1,

      on_timer => sub ($self) {
          do_some_work();

          $self->reschedule(
              after => 5,
          );
      },
  );

This can be useful for work whose next delay depends on the result of the
current callback.

A one-shot Timer is still active while its callback is running, so it may be
rescheduled from inside that callback.

If it is not rescheduled, its completed one-shot expiration becomes terminal
after the callback.

=head1 CANCELLING A TIMER

=head2 cancel

  $timer->cancel;

Cancel future delivery.

Cancellation is terminal.

A cancelled Timer cannot later be rescheduled or added to another Loop.

Calling C<cancel> again is harmless.

A Timer may also cancel itself from inside its callback:

  on_timer => sub ($self) {
      ...
      $self->cancel;
  }

=head1 TIMER LIFECYCLE

A newly constructed detached Timer begins unattached.

After it is added to a Loop, it becomes active.

A one-shot Timer becomes expired after its final callback unless it was
rescheduled.

An explicitly cancelled Timer becomes cancelled.

=head2 state

  my $state = $timer->state;

The public lifecycle states are:

  unattached
  active
  expired
  cancelled

=head2 is_active

  if ($timer->is_active) {
      ...
  }

Return true while the Timer is scheduled or its callback is currently firing.

=head2 is_terminal

  if ($timer->is_terminal) {
      ...
  }

Return true after final expiration or cancellation.

Terminal Timers cannot be revived.

=head1 ATTACHING TO A LOOP

The usual form attaches during construction:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 1,
      on_timer => sub ($self) {
          ...
      },
  );

A Timer may also be constructed detached:

  my $timer = Linux::Event::Kernel::Timer->new(
      after => 1,
      on_timer => sub ($self) {
          ...
      },
  );

and attached later:

  $loop->add($timer);

C<add> returns the same Timer object, so this is also valid:

  my $timer = $loop->add(
      Linux::Event::Kernel::Timer->new(
          after => 1,
          on_timer => sub ($self) {
              ...
          },
      )
  );

Once attached, a Timer belongs to that Loop for its lifetime.

=head1 LOOP OWNERSHIP

An active Timer is retained by its Loop.

This means this is safe:

  Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 1,
      on_timer => sub ($self) {
          say "still fires";
      },
  );

The application does not need to keep another reference merely to prevent the
active Timer from disappearing.

The Loop releases its ownership when the Timer becomes terminal.

=head1 FIXED-RATE RECURRENCE

Recurring timers use a fixed-rate schedule.

The next deadline is calculated from the previous scheduled deadline, not from
the time the callback finishes.

For example, with:

  every => 1

a callback that takes 0.1 seconds does not intentionally turn the schedule into:

  callback finished + 1 second

for every repetition.

This avoids accumulating ordinary callback execution time as timer drift.

=head1 MISSED TICKS

A Loop can occasionally be too busy to run a recurring Timer exactly when one
or more intervals expire.

Linux::Event does not call the callback repeatedly in a burst merely to replay
every missed interval.

Instead, missed recurring intervals are coalesced into one callback.

=head2 expirations

Inside the callback:

  on_timer => sub ($self) {
      my $ticks = $self->expirations;

      say "$ticks timer interval(s) elapsed";
  }

C<expirations> reports how many periodic ticks the current delivery represents.

Normally this is:

  1

If the Loop was delayed long enough to cross several recurring deadlines, it
may be greater than one.

The recurring schedule is advanced beyond the current monotonic time and
continues from its fixed-rate timeline.

=head1 CURRENT DEADLINE AND INTERVAL

=head2 deadline

  my $deadline = $timer->deadline;

For an active Timer, return its current absolute monotonic deadline in seconds.

For a detached Timer created with an absolute C<at> value, that absolute
deadline is also available before attachment.

A relative detached Timer does not yet have an absolute Loop deadline.

=head2 interval

  my $seconds = $timer->interval;

Return the recurring interval in seconds.

A one-shot Timer has an interval of zero.

=head1 MONOTONIC TIME

=head2 now

  my $now = Linux::Event::Kernel::Timer->now;

Return the current monotonic clock value in seconds.

This is the clock used by C<at> and C<deadline>.

For example:

  my $deadline =
      Linux::Event::Kernel::Timer->now + 0.250;

  my $timer = Linux::Event::Kernel::Timer->new(
      at => $deadline,
      ...
  );

=head1 IMMEDIATE AND PAST DEADLINES

A Timer scheduled with:

  after => 0

or with an C<at> value that has already passed does not invoke C<on_timer>
inline from C<new> or C<reschedule>.

It becomes normal pending Loop work and fires on a later dispatch turn.

The same rule applies when an immediate Timer is scheduled from another Timer
callback.

This prevents recursive timer-callback chains.

=head1 LOOP-AWARE FORKING

L<Linux::Event::Loop> supports explicit Timer dispositions during managed
C<fork>.

A Timer may be:

=over 4

=item C<clone>

Remain active in the parent and create an independent active Timer in the
child.

The child Timer preserves the same absolute monotonic deadline.

=item C<move>

Move the active Timer to the child.

After a successful move, the parent Timer is terminal.

=back

Timer C<share> is not supported.

A Timer omitted from the disposition lists remains parent-only and its inherited
child copy is dropped.

For example:

  my $pid = $loop->fork(
      clone => [$heartbeat],
      move  => [$child_only_timer],
  );

See L<Linux::Event::Loop> for the full managed-fork contract and its
quiescence requirements.

=head1 IMPLEMENTATION MODEL

Applications do not need to create or manage Linux C<timerfd> descriptors.

All active Timers on one Loop share one private timerfd-backed scheduler.

Linux::Event keeps scheduled Timers in an indexed native minimum heap and arms
the shared timerfd for the next deadline.

Therefore:

  1 Timer

does not mean:

  1 timerfd

and:

  10,000 Timers

do not require 10,000 timerfds.

This shared scheduler is an implementation detail, but it explains why Timer
is a logical scheduled resource rather than a thin wrapper around one kernel
timer descriptor.

Timers with identical deadlines are delivered in stable scheduling order, and
timer dispatch is bounded so a large timer cohort does not permanently exclude
other ready Loop resources.

=head1 PERFORMANCE MODEL

Timer callback policy is resolved when the Timer is constructed.

A subclass method is cached per Timer class, while a constructor C<on_timer>
callback is retained for that object.

Recurring delivery therefore does not need to repeatedly perform method lookup
or decide between callback styles.

The shared native scheduler also provides indexed cancellation and rescheduling
rather than searching all active Timers linearly.

These details normally require no application action.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::Kernel::Signal>,
L<Linux::Event::Kernel::Event>,
F<docs/TIMER-DESIGN.md>,
F<docs/ORDERED-BYTE-DEADLINES.md>.

=cut
