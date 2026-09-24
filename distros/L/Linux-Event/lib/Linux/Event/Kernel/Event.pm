package Linux::Event::Kernel::Event;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use Config ();
use POSIX qw(getpid);
use Scalar::Util qw(refaddr weaken);

require Linux::Event::Loop;
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

my %CLASS_DESCRIPTOR;
my %OWNER_STATE;
my %LIVE_HANDLE;
my $NEXT_ID = 1;
my $MAX_INCREMENT = $Config::Config{uvsize} >= 8
    ? '18446744073709551614' : '4294967295';

sub _decimal_greater_than ($value, $maximum) {
    $value =~ s/\A0+//;
    $value = '0' if $value eq '';
    return 1 if length($value) > length($maximum);
    return 0 if length($value) < length($maximum);
    return $value gt $maximum;
}

sub _descriptor_for ($class) {
    return $CLASS_DESCRIPTOR{$class} if exists $CLASS_DESCRIPTOR{$class};
    croak "$class is not a Linux::Event::Kernel::Event subclass"
        if !$class->isa(__PACKAGE__);
    my $callback = $class->can('on_event')
        // croak "$class must define on_event() or receive on_event => coderef";
    return $CLASS_DESCRIPTOR{$class} = { callback => $callback };
}

sub _effective_descriptor ($class, $option) {
    croak "$class is not a Linux::Event::Kernel::Event subclass"
        if !$class->isa(__PACKAGE__);
    return _descriptor_for($class) if !exists $option->{on_event};
    my $callback = delete $option->{on_event};
    croak 'new(): on_event must be a coderef' if ref($callback) ne 'CODE';
    return { callback => $callback };
}

sub new ($class, %option) {
    croak 'new(): must be called as a class method' if ref $class;
    my $descriptor = _effective_descriptor($class, \%option);
    my $loop = delete $option{loop};
    croak 'new(): loop must be an object implementing add() and watch()'
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch'));
    my $data = delete $option{data};
    croak 'new(): unknown options: ' . join(', ', sort keys %option)
        if %option;
    my $id = $NEXT_ID++;
    my $self = bless {
        id              => $id,
        fd              => _new_fd(),
        terminal        => 0,
        owner_pid       => $$,
        owner_interpreter => _interpreter_id(),
        handle_interpreter => _interpreter_id(),
        cloned_signal_handle => 0,
    }, $class;
    $LIVE_HANDLE{$id} = $self;
    weaken($LIVE_HANDLE{$id});
    $OWNER_STATE{$id} = bless {
        descriptor => $descriptor,
        loop       => undef,
        watcher    => undef,
        data       => $data,
        state      => 'unattached',
    }, 'Linux::Event::Kernel::Event::_OwnerState';
    $loop->add($self) if defined $loop;
    return $self;
}

sub _assert_owner ($self, $method) {
    croak "$method(): Event may be managed only by its creating interpreter"
        if $self->{cloned_signal_handle}
        || $self->{owner_pid} != $$
        || $self->{owner_interpreter} != _interpreter_id();
    return;
}

sub _owner_state ($self, $method) {
    $self->_assert_owner($method);
    return $OWNER_STATE{ $self->{id} }
        // croak "$method(): Event owner state is unavailable";
}

sub _attach_to_loop ($self, $loop) {
    croak 'add(): Event is not unattached' if $self->{terminal};
    my $state = $self->_owner_state('add');
    croak 'add(): Event is not unattached'
        if $state->{state} ne 'unattached' || $state->{loop};
    my $watcher = $loop->watch(
        fd      => $self->{fd},
        _internal => 1,
        read    => sub { $self->_dispatch },
        error   => sub { die "Linux::Event Event event source failed\n" },
        no_args => 1,
        lean    => 1,
    );
    $state->{loop} = $loop;
    $state->{state} = 'active';
    $state->{watcher} = $watcher;
    return $self;
}

sub _dispatch ($self) {
    my $state = $self->_owner_state('dispatch');
    return if $state->{state} ne 'active';
    my $count = _drain_fd($self->{fd});
    return if !$count;
    $state->{descriptor}{callback}->($self, $count);
    return;
}

sub signal ($self, $increment = 1) {
    croak 'signal(): Event is cancelled' if $self->{terminal};
    croak 'signal(): cloned Event handle belongs to another interpreter'
        if $self->{handle_interpreter} != _interpreter_id();
    croak 'signal(): increment must be a positive integer'
        if !defined($increment) || ref($increment)
        || $increment !~ /\A\d+\z/ || $increment == 0;
    croak 'signal(): increment exceeds the supported eventfd range'
        if _decimal_greater_than("$increment", $MAX_INCREMENT);
    _signal_fd($self->{fd}, 0 + $increment);
    return $self;
}

sub cancel ($self) {
    return $self if $self->{terminal};
    my $state = $self->_owner_state('cancel');
    $state->{watcher}->cancel if $state->{watcher};
    $state->{watcher} = undef;
    _close_fd(delete $self->{fd}) if defined $self->{fd};
    delete $LIVE_HANDLE{ $self->{id} };
    $state->{loop} = undef;
    $state->{data} = undef;
    $state->{state} = 'cancelled';
    delete $OWNER_STATE{ $self->{id} };
    $self->{terminal} = 1;
    return $self;
}

sub loop ($self) {
    return undef if $self->{terminal};
    return $self->_owner_state('loop')->{loop};
}
sub state ($self) {
    return $self->{fork_state} if $self->{terminal} && $self->{fork_state};
    return 'cancelled' if $self->{terminal};
    return $self->_owner_state('state')->{state};
}
sub is_active ($self) { $self->state eq 'active' }
sub is_terminal ($self) { !!$self->{terminal} }

sub data ($self, @argument) {
    croak 'data(): Event is cancelled' if $self->{terminal};
    my $state = $self->_owner_state('data');
    $state->{data} = $argument[0] if @argument;
    return $state->{data};
}

sub _fork_preflight ($self, $mode, $loop) {
    croak "fork(): Event does not support '$mode'" if $mode ne 'drop';
    my $state = $OWNER_STATE{ $self->{id} };
    croak 'fork(): Event is not active in this Loop'
        if $self->{terminal} || !$state || !$state->{loop}
        || refaddr($state->{loop}) != refaddr($loop)
        || $state->{state} ne 'active';
    return 1;
}

sub _fork_child_drop ($self, $loop) {
    my $state = delete $OWNER_STATE{ $self->{id} };
    $state->{watcher} = undef if $state;
    $state->{loop} = undef if $state;
    $state->{data} = undef if $state;
    _close_fd(delete $self->{fd}) if defined $self->{fd};
    delete $LIVE_HANDLE{ $self->{id} };
    $self->{owner_pid} = getpid();
    $self->{terminal} = 1;
    $self->{fork_state} = 'not_inherited';
    return;
}

sub _objects_for_loop ($class, $loop) {
    my @object;
    for my $id (keys %LIVE_HANDLE) {
        my $object = $LIVE_HANDLE{$id} // next;
        next if $object->{terminal};
        my $state = $OWNER_STATE{$id} // next;
        next if !$state->{loop}
            || refaddr($state->{loop}) != refaddr($loop);
        push @object, $object;
    }
    return \@object;
}

sub CLONE ($class) {
    for my $id (keys %LIVE_HANDLE) {
        my $self = $LIVE_HANDLE{$id};
        if (!$self) {
            delete $LIVE_HANDLE{$id};
            next;
        }
        next if $self->{terminal} || !defined $self->{fd};
        $self->{fd} = _dup_fd($self->{fd});
        $self->{handle_interpreter} = _interpreter_id();
        $self->{cloned_signal_handle} = 1;
    }
    return;
}

sub DESTROY ($self) {
    my $interpreter = eval { _interpreter_id() };
    my $is_owner = !$self->{cloned_signal_handle}
        && defined($interpreter)
        && $self->{owner_pid} == $$
        && $self->{owner_interpreter} == $interpreter;
    if ($is_owner) {
        my $state = delete $OWNER_STATE{ $self->{id} };
        eval { $state->{watcher}->cancel if $state && $state->{watcher}; 1 };
    }
    my $live = $LIVE_HANDLE{ $self->{id} };
    delete $LIVE_HANDLE{ $self->{id} }
        if !$live || refaddr($live) == refaddr($self);
    return if !defined($interpreter)
        || $self->{handle_interpreter} != $interpreter;
    eval { _close_fd(delete $self->{fd}); 1 } if defined $self->{fd};
    return;
}

package Linux::Event::Kernel::Event::_OwnerState;
use v5.36;
use strict;
use warnings;

sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Kernel::Event;

1;
__END__

=head1 NAME

Linux::Event::Kernel::Event - Wake an event loop from another execution context

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Event;

  my $loop = Linux::Event::Loop->new;

  my $event = Linux::Event::Kernel::Event->new(
      loop => $loop,

      on_event => sub ($self, $count) {
          say "Received $count notification(s)";
          $loop->stop;
      },
  );

  $event->signal;

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Event> provides an eventfd-backed notification that can
wake a L<Linux::Event::Loop>.

Its main purpose is simple:

  something outside the Loop has work ready
          |
          v
      $event->signal
          |
          v
      Loop wakes up
          |
          v
      on_event runs normally on the Loop

The producer might be:

=over 4

=item *

another thread

=item *

a native extension

=item *

an external C library

=item *

a forked child process

=item *

ordinary application code that wants to notify the Loop

=back

C<on_event> always runs as ordinary Loop dispatch.

C<signal> does not execute the callback inline.

=head1 EVENT IS A NOTIFICATION, NOT A MESSAGE QUEUE

This distinction is important.

An Event tells the Loop:

  work is available

It does not carry arbitrary Perl data between threads or processes.

Linux C<eventfd> contains a numeric counter.

It cannot safely transport:

  Perl objects
  coderefs
  hashes
  strings
  arbitrary messages

If another execution context has actual application data to deliver, place that
data in an appropriate queue or IPC mechanism first and then signal the Event.

Conceptually:

  producer:
      put result in queue
      $event->signal

  Loop:
      on_event fires
      drain queue

For example:

  my $event = Linux::Event::Kernel::Event->new(
      loop => $loop,
      data => $results,

      on_event => sub ($self, $count) {
          my $queue = $self->data;

          while (my $result = next_result($queue)) {
              process_result($result);
          }
      },
  );

The queue is the source of truth for the actual work.

The Event is merely the wakeup notification.

=head1 CREATING AN EVENT

The normal constructor form is:

  my $event = Linux::Event::Kernel::Event->new(
      loop => $loop,

      on_event => sub ($self, $count) {
          ...
      },
  );

C<on_event> is required unless the class provides an C<on_event> method.

=head1 THE CALLBACK

=head2 on_event

The callback receives:

  on_event => sub ($self, $count) {
      ...
  }

where:

=over 4

=item C<$self>

The Event object.

=item C<$count>

The eventfd counter value consumed for this delivery.

=back

For example:

  my $event = Linux::Event::Kernel::Event->new(
      loop => $loop,

      on_event => sub ($self, $count) {
          say "$count wakeup unit(s) arrived";
      },
  );

=head1 SIGNALING

=head2 signal

Add one to the Event counter:

  $event->signal;

C<signal> returns the Event object.

It does not call C<on_event> immediately.

Instead, the eventfd becomes readable and the callback runs when the owning
Loop dispatches that readiness.

=head2 signal($increment)

An explicit positive increment may also be supplied:

  $event->signal(5);

This adds five to the eventfd counter.

The increment must be a positive integer within the supported eventfd range.

=head1 MULTIPLE SIGNALS MAY COALESCE

Several calls to C<signal> can become one callback.

For example:

  $event->signal;
  $event->signal;
  $event->signal;

may later produce:

  on_event => sub ($self, $count) {
      # $count may be 3
  }

This is normal eventfd behavior.

That is another reason not to treat C<$count> as though it represented one
specific application message.

If three queue items were published and three signals were sent, the callback
might run once with a count of three.

The application should normally drain the associated queue until no work
remains.

=head1 SIGNALING BEFORE ATTACHMENT

An Event owns its eventfd as soon as it is constructed.

Therefore a detached Event can be signaled before it is added to a Loop:

  my $event = Linux::Event::Kernel::Event->new(
      on_event => sub ($self, $count) {
          ...
      },
  );

  $event->signal;

  $loop->add($event);

The pending eventfd counter remains available and can make the Event ready once
it is attached.

=head1 CONSTRUCTOR CALLBACKS OR SUBCLASS METHODS

A constructor callback is often simplest:

  my $event = Linux::Event::Kernel::Event->new(
      on_event => sub ($self, $count) {
          ...
      },
  );

A reusable Event type can instead use a subclass:

  package ResultsReady;

  use parent 'Linux::Event::Kernel::Event';

  sub on_event ($self, $count) {
      my $queue = $self->data;

      while (my $result = next_result($queue)) {
          process_result($result);
      }
  }

  package main;

  my $event = ResultsReady->new(
      loop => $loop,
      data => $results,
  );

A constructor C<on_event> callback overrides the subclass method for that
particular Event.

=head1 APPLICATION DATA

=head2 data

Application-owned state may be associated with an Event:

  my $event = Linux::Event::Kernel::Event->new(
      loop => $loop,
      data => $results,

      on_event => sub ($self, $count) {
          drain_results($self->data);
      },
  );

Retrieve it with:

  my $data = $event->data;

While the Event is nonterminal, it may be changed:

  $event->data($new_data);

Cancellation releases the owner-side application data.

=head1 ATTACHING TO A LOOP

An Event can be attached during construction:

  my $event = Linux::Event::Kernel::Event->new(
      loop => $loop,

      on_event => sub ($self, $count) {
          ...
      },
  );

or created detached:

  my $event = Linux::Event::Kernel::Event->new(
      on_event => sub ($self, $count) {
          ...
      },
  );

and added later:

  $loop->add($event);

=head1 CANCELLING AN EVENT

=head2 cancel

  $event->cancel;

Cancellation:

=over 4

=item *

removes the Event from its Loop

=item *

closes its owner-side eventfd

=item *

releases retained application data

=item *

makes the Event terminal

=back

Calling C<cancel> again is harmless.

A cancelled Event cannot be signaled or attached again.

=head1 LIFECYCLE

The normal Event states are:

  unattached
  active
  cancelled

=head2 state

  my $state = $event->state;

Return the current lifecycle state.

A managed-fork child may also observe the special terminal state:

  not_inherited

when the parent's Event was intentionally dropped during child Loop
reconstruction.

=head2 is_active

  if ($event->is_active) {
      ...
  }

Return true while attached and active.

=head2 is_terminal

  if ($event->is_terminal) {
      ...
  }

Return true once the Event can no longer be managed.

=head1 LOOP

=head2 loop

  my $loop = $event->loop;

Return the owning Loop while the Event is active.

After cancellation, no owning Loop is returned.

=head1 USING EVENT WITH THREADS

Event is useful for waking the Loop from another thread.

The important ownership rule is:

  worker signals
  owner Loop dispatches

The worker does not become another owner of the Loop or callback.

On an ithread-enabled Perl, a cloned Event handle may be used for signaling.

It does not gain access to the owner interpreter's:

=over 4

=item *

Loop

=item *

callback state

=item *

application C<data>

=item *

lifecycle management

=back

The owning interpreter remains responsible for the Event object itself.

=head1 WHY THE EVENT DOES NOT CARRY PERL VALUES

Arbitrary Perl values belong to a Perl interpreter.

Allowing something like:

  $event->signal($perl_object);

to cross thread boundaries would require Linux::Event to define ownership,
copying, serialization, cancellation, destruction, and exception behavior for
arbitrary Perl state.

C<Kernel::Event> deliberately avoids inventing such a model.

Use the Event as the wakeup primitive and choose a payload mechanism appropriate
to the producer.

=head1 USING EVENT ACROSS FORK

There are two different cases to understand.

=head2 Ordinary CORE::fork

A child created with ordinary C<CORE::fork> inherits the eventfd.

The child may use the inherited Event handle to signal the parent's eventfd
until C<exec> or until that inherited handle is closed.

For example, conceptually:

  my $pid = CORE::fork();

  if ($pid == 0) {
      publish_result_through_ipc();
      $event->signal;
      exit;
  }

The child does not gain ownership of the parent's Loop, callback, or application
C<data>.

Cross-process payloads still require real IPC or shared storage.

The Event descriptor is close-on-exec.

=head2 Linux::Event managed fork

C<Linux::Event::Kernel::Event> currently supports only the default parent-only
behavior with L<Linux::Event::Loop> managed C<fork>.

It does not support:

  share
  clone
  move

Therefore an Event should not be placed in those disposition lists.

For example:

  my $pid = $loop->fork(
      clone => [$timer],
  );

The Event remains active in the parent.

The inherited child Event is deliberately dropped as part of rebuilding the
child Loop and becomes terminal there.

This prevents an inherited Event from accidentally being treated as a
child-owned Loop resource.

=head1 CALLBACK EXCEPTIONS

If C<on_event> throws an exception, that exception propagates through ordinary
Loop dispatch.

Linux::Event does not silently convert the exception into Event cancellation.

This follows the normal Linux::Event callback model.

=head1 COUNTER SATURATION

Linux eventfd counters have a finite range.

If producers attempt to increment an already saturated counter, the
nonblocking eventfd write fails.

Linux::Event reports that failure from C<signal> rather than silently discarding
the notification.

Applications should normally use Event as a wakeup and drain their actual work
queue promptly rather than trying to use the eventfd counter as long-term
storage.

=head1 IMPLEMENTATION MODEL

Each Event owns one nonblocking, close-on-exec Linux C<eventfd>.

When the counter becomes nonzero, epoll makes the Event readable.

Linux::Event reads the counter and invokes C<on_event> on the owning Loop.

One readiness dispatch performs one counter read.

If producers signal again after that read, the eventfd remains or becomes
readable for a later Loop turn.

This prevents a continuously active producer from forcing one Event dispatch to
drain forever.

=head1 PERFORMANCE MODEL

Event is intentionally small.

The application callback is resolved at construction: a constructor callback is
retained for that Event, or a subclass method is cached for its class.

Normal delivery therefore consists primarily of:

  eventfd readiness
  counter read
  cached callback

without repeatedly performing method lookup or callback-style selection.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::Kernel::Signal>,
L<Linux::Event::Kernel::Process>,
F<docs/EVENT-DESIGN.md>.

=cut
