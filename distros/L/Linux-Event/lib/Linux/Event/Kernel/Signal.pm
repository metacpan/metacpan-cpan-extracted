package Linux::Event::Kernel::Signal;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Carp qw(croak);
use Hash::Util::FieldHash qw(fieldhash);
use POSIX qw(SIGKILL SIGRTMAX SIGSTOP);
use Scalar::Util qw(refaddr weaken);

require Linux::Event::Loop;
require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

my %CLASS_DESCRIPTOR;
fieldhash my %ENGINE_FOR_LOOP;

sub _descriptor_for ($class) {
    return $CLASS_DESCRIPTOR{$class} if exists $CLASS_DESCRIPTOR{$class};
    croak "$class is not a Linux::Event::Kernel::Signal subclass"
        if !$class->isa(__PACKAGE__);
    my $callback = $class->can('on_signal')
        // croak "$class must define on_signal() or receive on_signal => coderef";
    return $CLASS_DESCRIPTOR{$class}
        = Linux::Event::Kernel::Signal::_Descriptor->new($callback);
}

sub _effective_descriptor ($class, $option) {
    croak "$class is not a Linux::Event::Kernel::Signal subclass"
        if !$class->isa(__PACKAGE__);
    return _descriptor_for($class) if !exists $option->{on_signal};
    my $callback = delete $option->{on_signal};
    croak 'new(): on_signal must be a coderef' if ref($callback) ne 'CODE';
    return Linux::Event::Kernel::Signal::_Descriptor->new($callback);
}

sub _numbers ($value) {
    my @number = ref($value) eq 'ARRAY' ? @$value : ($value);
    croak 'new(): signals must contain at least one signal number' if !@number;
    my (%seen, @unique);
    for my $number (@number) {
        croak 'new(): every signal must be a positive integer'
            if !defined($number) || ref($number) || $number !~ /\A\d+\z/
            || $number == 0;
        my $digits = "$number";
        $digits =~ s/\A0+//;
        my $maximum = '' . SIGRTMAX;
        croak "signal number $number cannot be used with signalfd"
            if length($digits) > length($maximum)
            || (length($digits) == length($maximum)
                && $digits gt $maximum)
            || $number == SIGKILL || $number == SIGSTOP;
        $number = 0 + $number;
        push @unique, $number if !$seen{$number}++;
    }
    return \@unique;
}

sub new ($class, %option) {
    croak 'new(): must be called as a class method' if ref $class;
    my $descriptor = _effective_descriptor($class, \%option);
    my $loop = delete $option{loop};
    croak 'new(): loop must be an object implementing add() and watch()'
        if defined($loop) && (!ref($loop) || !$loop->can('add')
            || !$loop->can('watch'));
    my $data = delete $option{data};
    croak 'new(): signals is required' if !exists $option{signals};
    my $numbers = _numbers(delete $option{signals});
    croak 'new(): unknown options: ' . join(', ', sort keys %option) if %option;
    my $signal = $class->_new_native(
        $descriptor, $numbers, $data,
    );
    $loop->add($signal) if defined $loop;
    return $signal;
}

sub _attach_to_loop ($self, $loop) {
    my $engine = $ENGINE_FOR_LOOP{$loop}
        //= Linux::Event::Kernel::Signal::_Engine->_new($loop);
    return $self->_attach_native($loop, $engine->{native});
}

sub _fork_preflight ($self, $mode, $loop) {
    croak "fork(): Signal does not support '$mode'" if $mode ne 'drop';
    my $owner = $self->loop;
    croak 'fork(): Signal is not active in this Loop'
        if !$owner || refaddr($owner) != refaddr($loop) || !$self->is_active;
    return 1;
}

sub _fork_child_drop ($self, $loop) {
    return;
}

sub _fork_child_drop_loop ($class, $loop) {
    my $engine = delete $ENGINE_FOR_LOOP{$loop};
    return if !$engine;
    my $native = delete $engine->{native};
    $engine->{loop} = undef;
    $native->_fork_child_drop if $native;
    return;
}

sub _objects_for_loop ($class, $loop) {
    my $engine = $ENGINE_FOR_LOOP{$loop};
    return $engine ? $engine->{native}->objects : [];
}

sub CLONE ($class) {
    %CLASS_DESCRIPTOR = ();
    %ENGINE_FOR_LOOP = ();
    return;
}

sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Kernel::Signal::_Descriptor;
sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Kernel::Signal::_Service;
sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Kernel::Signal::_Engine;
use v5.36;
use strict;
use warnings;

sub CLONE_SKIP ($class) { 1 }

sub _new ($class, $loop) {
    my $self = bless {
        loop   => $loop,
        native => Linux::Event::Kernel::Signal::_Service->new,
    }, $class;
    Scalar::Util::weaken($self->{loop});
    my $ready = sub { $self->{native}->dispatch };
    my $failed = sub { die "Linux::Event Signal event source failed\n" };
    $loop->watch(
        fd      => $self->{native}->fd,
        _internal => 1,
        read    => $ready,
        error   => $failed,
        no_args => 1,
        lean    => 1,
    );
    return $self;
}

1;
__END__

=head1 NAME

Linux::Event::Kernel::Signal - Handle Unix signals through the event loop

=head1 SYNOPSIS

  use v5.36;
  use POSIX qw(SIGINT SIGTERM);
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Signal;

  my $loop = Linux::Event::Loop->new;

  my $shutdown = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => [SIGINT, SIGTERM],

      on_signal => sub ($self, $number, $count) {
          say "Received signal $number";
          $loop->stop;
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Signal> lets a Linux::Event application respond to Unix
signals as normal event-loop callbacks.

For example, a server can respond to C<SIGINT> and C<SIGTERM> without putting
application Perl code inside an asynchronous C<%SIG> handler:

  my $shutdown = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => [SIGINT, SIGTERM],

      on_signal => sub ($self, $number, $count) {
          $listener->close;
          $loop->stop;
      },
  );

Linux::Event uses Linux C<signalfd> internally.

The important application-level difference is that C<on_signal> runs as
ordinary Loop work.

It does not interrupt arbitrary Perl code in the middle of execution.

=head1 WHY USE A SIGNAL OBJECT?

Traditional Perl signal handling often looks like:

  $SIG{TERM} = sub {
      ...
  };

That callback is associated with asynchronous process-signal delivery.

With Linux::Event, the signal is instead consumed through the event loop:

  my $signal = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => SIGTERM,

      on_signal => sub ($self, $number, $count) {
          ...
      },
  );

The application callback therefore runs from normal Linux::Event dispatch.

This is generally much easier to reason about when the callback needs to:

=over 4

=item *

close a Listener

=item *

write to a Stream

=item *

cancel a Timer

=item *

modify application state

=item *

stop the Loop

=back

=head1 CHOOSING SIGNALS

=head2 signals

C<signals> is required.

It may contain one numeric signal:

  signals => SIGTERM

or an array reference:

  signals => [SIGINT, SIGTERM]

Signal constants are commonly imported from L<POSIX>:

  use POSIX qw(SIGINT SIGTERM SIGHUP);

For example:

  my $signal = Linux::Event::Kernel::Signal->new(
      signals => [SIGHUP, SIGTERM],
      on_signal => sub ($self, $number, $count) {
          ...
      },
  );

Duplicate numbers are removed automatically.

=head2 Unsupported signals

C<SIGKILL> and C<SIGSTOP> cannot be handled through C<signalfd> and are
rejected.

Signal numbers must be positive integers supported by the platform.

=head1 THE CALLBACK

=head2 on_signal

The callback receives three arguments:

  on_signal => sub ($self, $number, $count) {
      ...
  }

They are:

=over 4

=item C<$self>

The L<Linux::Event::Kernel::Signal> object.

=item C<$number>

The numeric signal that was received.

=item C<$count>

The number of C<signalfd> records observed for that signal during the current
complete drain.

=back

For example:

  my $shutdown = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => [SIGINT, SIGTERM],

      on_signal => sub ($self, $number, $count) {
          say "Signal $number arrived";
          $self->loop->stop;
      },
  );

=head1 WHAT COUNT MEANS

For most ordinary signals, C<$count> will usually be one.

However, Linux::Event drains all currently available C<signalfd> records before
performing semantic callback delivery and aggregates records for the same
signal number.

For real-time signals, several queued records may therefore produce:

  $count > 1

Ordinary Unix signals may already have been coalesced by the kernel before
C<signalfd> observes them.

Therefore C<$count> means:

  records Linux::Event actually observed

not:

  number of kill() calls attempted by other code

=head1 ONE OBJECT CAN WATCH SEVERAL SIGNALS

A single Signal object can subscribe to several numbers:

  my $signal = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => [SIGINT, SIGTERM, SIGHUP],

      on_signal => sub ($self, $number, $count) {
          if ($number == SIGHUP) {
              reload_configuration();
              return;
          }

          $loop->stop;
      },
  );

The callback's C<$number> tells you which subscribed signal was received.

=head1 SEVERAL OBJECTS CAN WATCH THE SAME SIGNAL

Several Signal objects on the B<same Loop> may subscribe to the same signal.

For example:

  my $logger = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => SIGTERM,

      on_signal => sub ($self, $number, $count) {
          log_shutdown_request();
      },
  );

  my $shutdown = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => SIGTERM,

      on_signal => sub ($self, $number, $count) {
          $loop->stop;
      },
  );

Both subscribers receive the observed signal.

Subscribers for one signal are called in attachment order.

A callback may safely cancel itself or another Signal object.

If a later subscriber is cancelled before its turn, it is skipped.

=head1 ONE LOOP OWNS A SIGNAL NUMBER

A particular signal number may be owned by only one Linux::Event Loop in a
process.

This is because reading a C<signalfd> consumes its notifications.

Therefore this is supported:

  Loop A
    Signal object 1 -> SIGTERM
    Signal object 2 -> SIGTERM

but Linux::Event does not allow:

  Loop A -> SIGTERM
  Loop B -> SIGTERM

at the same time in the same process.

Multiple subscribers should use the same owning Loop.

=head1 CONSTRUCTOR CALLBACKS OR SUBCLASS METHODS

A Signal can use a constructor callback:

  my $signal = Linux::Event::Kernel::Signal->new(
      signals => SIGTERM,

      on_signal => sub ($self, $number, $count) {
          ...
      },
  );

or a subclass:

  package ShutdownSignal;

  use parent 'Linux::Event::Kernel::Signal';

  sub on_signal ($self, $number, $count) {
      $self->data->{listener}->close;
      $self->loop->stop;
  }

  package main;

  my $signal = ShutdownSignal->new(
      loop    => $loop,
      signals => [SIGINT, SIGTERM],
      data    => {
          listener => $listener,
      },
  );

A constructor C<on_signal> callback overrides the subclass method for that
particular object.

Constructor callbacks are usually simplest when the subscription needs lexical
application state.

Subclassing is useful for reusable signal policy.

=head1 APPLICATION DATA

=head2 data

Arbitrary application state can be stored with the Signal:

  my $signal = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => SIGTERM,
      data    => {
          listener => $listener,
      },

      on_signal => sub ($self, $number, $count) {
          $self->data->{listener}->close;
      },
  );

Retrieve it with:

  my $data = $signal->data;

While the Signal is nonterminal, it may also be replaced:

  $signal->data($new_data);

Cancellation releases retained application data.

A cancelled Signal cannot retain new C<data>.

=head1 ATTACHING TO A LOOP

A Signal may be attached during construction:

  my $signal = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => SIGTERM,

      on_signal => sub ($self, $number, $count) {
          ...
      },
  );

or constructed detached:

  my $signal = Linux::Event::Kernel::Signal->new(
      signals => SIGTERM,

      on_signal => sub ($self, $number, $count) {
          ...
      },
  );

and added later:

  $loop->add($signal);

Once active, the Signal belongs to that Loop.

=head1 LOOP OWNERSHIP

An active Signal subscription is retained by its Loop.

This means an application does not need to retain an extra reference merely to
keep an active signal subscription alive.

For example:

  Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => SIGTERM,

      on_signal => sub ($self, $number, $count) {
          $loop->stop;
      },
  );

remains active because the Loop owns the subscription.

Cancellation removes it from the Loop's Signal service.

=head1 CANCELLING A SIGNAL SUBSCRIPTION

=head2 cancel

  $signal->cancel;

Stop receiving the subscribed signals for this object.

Cancellation is terminal.

Calling C<cancel> more than once is harmless.

A Signal may cancel itself:

  on_signal => sub ($self, $number, $count) {
      do_once();
      $self->cancel;
  }

or another Signal:

  on_signal => sub ($self, $number, $count) {
      $other_signal->cancel;
  }

Cancellation during dispatch is safe.

=head1 LIFECYCLE

A Signal has three public states:

  unattached
  active
  cancelled

=head2 state

  my $state = $signal->state;

Return the current lifecycle state.

=head2 is_active

  if ($signal->is_active) {
      ...
  }

Return true while the subscription is active.

=head2 is_terminal

  if ($signal->is_terminal) {
      ...
  }

Return true after cancellation.

A cancelled Signal cannot be reattached.

=head1 INSPECTING SUBSCRIBED SIGNALS

=head2 signals

  my $numbers = $signal->signals;

Return an array reference containing the numeric signals subscribed by this
object.

For example:

  for my $number (@{ $signal->signals }) {
      say "Watching signal $number";
  }

=head1 LOOP

=head2 loop

  my $loop = $signal->loop;

Return the owning L<Linux::Event::Loop> while attached.

=head1 SIGNAL MASKS

This section matters when combining Linux::Event with lower-level signal or
thread code.

Linux C<signalfd> receives signals by having those signals blocked in the
consuming thread's signal mask.

Linux::Event manages that blocking automatically for signals it owns.

When the first Linux::Event subscription for a signal is attached, Linux::Event
records whether that signal was already blocked.

When the last subscription is removed, Linux::Event restores only the mask
state that B<Linux::Event itself changed>.

For example, if your application had already blocked C<SIGTERM> before creating
the Signal object, Linux::Event does not later decide that it should become
unblocked.

This preserves application-owned signal-mask policy.

=head1 DO NOT ALSO EXPECT %SIG TO HANDLE THE SAME SIGNAL

A Signal subscription is not an additional observer layered on top of an
ordinary Perl C<%SIG> handler.

For example, do not design code around both:

  $SIG{TERM} = sub {
      ...
  };

and:

  Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => SIGTERM,
      ...
  );

receiving the same notification.

The signal is blocked for C<signalfd> consumption while Linux::Event owns it.

Use the Linux::Event Signal callback as the application's handler for that
signal.

=head1 THREADS

Signal masks are per-thread.

If an application creates its own worker threads, the easiest model is to
establish the Linux::Event Signal subscriptions B<before> creating those
threads.

New threads then inherit the blocked signal mask.

If threads already exist, the application is responsible for ensuring that
signals intended for C<signalfd> are blocked consistently in threads that could
otherwise receive them.

Linux::Event's own resolver workers arrange their signal masks so they do not
accidentally consume application Signal traffic.

Perl ithreads are not required to use C<Linux::Event::Kernel::Signal>.

=head1 LOOP-AWARE FORKING

Signal currently supports only the default parent-only behavior during
L<Linux::Event::Loop> managed fork.

It does B<not> currently support:

  share
  clone
  move

A Signal should therefore be omitted from those disposition lists.

For example:

  my $pid = $loop->fork(
      clone => [$timer],
  );

An active Signal that is not listed remains active in the parent.

The inherited child Signal service is discarded during child Loop
reconstruction.

Linux::Event also restores child-side signal-mask entries that it had blocked
for the discarded service.

The inherited Signal object is not active in the child.

An ordinary C<CORE::fork> does not make an inherited Linux::Event Signal service
safe to reuse.

Use the managed Loop fork contract when forking a process that already owns
Linux::Event resources.

=head1 SHARED SIGNALFD SERVICE

Applications normally do not need to know how many C<signalfd> descriptors are
used.

All Signal objects attached to one Loop share one private nonblocking
C<signalfd> service.

For example:

  100 Signal objects

do not imply:

  100 signalfd descriptors

The shared service keeps subscriber lists for each signal number and fans an
observed signal out to the appropriate Signal objects.

Several native records may also be drained and aggregated before entering Perl
callbacks.

=head1 DELIVERY ORDER

When one C<signalfd> drain contains several different signal numbers,
Linux::Event delivers them in numeric signal order.

For one signal number, subscribers are called in attachment order.

This gives dispatch deterministic ordering without requiring applications to
depend on the order in which separate kernel records happened to be read.

=head1 PERFORMANCE MODEL

Each Loop uses one shared native Signal service rather than one C<signalfd> per
Signal object.

A readiness event enters the native service once, drains available
C<signalfd_siginfo> records, aggregates them by signal number, and then invokes
the semantic Perl callbacks.

Constructor callbacks are retained for their objects and subclass methods are
cached rather than looked up repeatedly for every signal record.

These details normally require no application action.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::Kernel::Timer>,
L<Linux::Event::Kernel::Process>,
F<docs/SIGNAL-DESIGN.md>.

=cut
