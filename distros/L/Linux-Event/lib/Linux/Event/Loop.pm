package Linux::Event::Loop;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.118';

use Carp qw(croak);
use Errno ();
use Hash::Util::FieldHash qw(fieldhash);
use Scalar::Util qw(blessed refaddr weaken);
use utf8 ();

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

require Linux::Event::Loop::Introspection;
our @ISA = ('Linux::Event::Loop::Introspection');

fieldhash my %DEFER_STATE;
fieldhash my %DEFER_FORK_STATE;
our $FORK_DRIVER_FRAME;
my $DEFER_CALLBACK_BATCH = 1024;

# Native drivers are private XS entry points. The public Perl boundary does
# not retain XS coderefs across interpreter clones.

sub _fork_write_all ($fh, $bytes) {
    my $offset = 0;
    while ($offset < length($bytes)) {
        my $written = syswrite($fh, $bytes, length($bytes) - $offset, $offset);
        next if !defined($written) && $! == Errno::EINTR();
        die "fork(): handshake write failed: $!\n" if !defined $written;
        die "fork(): handshake write returned zero bytes\n" if !$written;
        $offset += $written;
    }
    return;
}

sub _fork_read_exact ($fh, $length) {
    my $bytes = '';
    while (length($bytes) < $length) {
        my $chunk = '';
        my $read = sysread($fh, $chunk, $length - length($bytes));
        next if !defined($read) && $! == Errno::EINTR();
        die "fork(): handshake read failed: $!\n" if !defined $read;
        return undef if !$read;
        $bytes .= $chunk;
    }
    return $bytes;
}

sub _fork_child_failure ($fh, $error) {
    $error = "$error";
    $error = "child reconstruction failed\n" if $error eq '';
    utf8::encode($error) if utf8::is_utf8($error);
    $error = substr($error, 0, 1_048_576);
    eval { _fork_write_all($fh, 'E' . pack('N', length($error)) . $error); 1 };
    require POSIX;
    POSIX::_exit(255);
}

sub _fork_child_reset_deferred ($self) {
    my $state = delete $DEFER_STATE{$self};
    $state->_fork_child_drop if $state;
    return;
}

sub fork ($self, %option) {
    $self->_assert_owner_native('fork');
    croak 'fork(): Loop must be quiescent and cannot fork during dispatch'
        if $self->running;

    my %known = map { $_ => 1 } qw(share clone move);
    my @unknown = sort grep { !$known{$_} } keys %option;
    croak 'fork(): unknown options: ' . join(', ', @unknown) if @unknown;

    my %disposition;
    my %selected;
    for my $mode (qw(share clone move)) {
        my $list = exists($option{$mode}) ? $option{$mode} : [];
        croak "fork(): $mode must be an array reference" if ref($list) ne 'ARRAY';
        for my $object (@$list) {
            croak "fork(): $mode entries must be resource objects"
                if !blessed($object);
            my $id = refaddr($object);
            croak 'fork(): a resource may appear in only one disposition list'
                if $selected{$id}++;
            croak "fork(): $mode resource is not current in this Loop"
                if !$self->has($object);
            $disposition{$id} = $mode;
        }
    }

    my $objects = $self->objects;
    for my $object (@$objects) {
        my $mode = $disposition{ refaddr($object) } // 'drop';
        croak 'fork(): resource does not implement fork disposition hooks'
            if !$object->can('_fork_preflight') || !$object->can('_fork_child_drop');
        $object->_fork_preflight($mode, $self);
        croak "fork(): resource does not implement child '$mode' disposition"
            if $mode ne 'drop' && !$object->can("_fork_child_$mode");
        croak 'fork(): moved resource does not implement parent disposition'
            if $mode eq 'move' && !$object->can('_fork_parent_move');
    }

    require Linux::Event::_Resolver;
    Linux::Event::_Resolver->_fork_prepare_loop($self);

    require Socket;
    socketpair(my $parent_channel, my $child_channel,
        Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
        or croak "fork(): socketpair failed: $!";

    my $pid = CORE::fork();
    if (!defined $pid) {
        my $errno = 0 + $!;
        close $parent_channel;
        close $child_channel;
        $! = $errno;
        return undef;
    }

    if ($pid == 0) {
        close $parent_channel;
        my $ok = eval {
            $self->_fork_child_reset;
            $self->reset_stats;
            $self->_fork_child_reset_deferred;
            $self->_fork_child_reset_deferred_forks;
            require Linux::Event::Kernel::Signal;
            Linux::Event::Kernel::Signal->_fork_child_drop_loop($self);

            for my $object (@$objects) {
                my $mode = $disposition{ refaddr($object) } // 'drop';
                my $method = $mode eq 'drop'
                    ? '_fork_child_drop' : "_fork_child_$mode";
                $object->$method($self);
            }
            1;
        };
        _fork_child_failure($child_channel, $@) if !$ok;

        my $ready = eval { _fork_write_all($child_channel, 'R'); 1 };
        _fork_child_failure($child_channel, $@) if !$ready;
        my $commit = eval { _fork_read_exact($child_channel, 1) };
        if ($@ || !defined($commit) || $commit ne 'C') {
            require POSIX;
            POSIX::_exit(255);
        }
        close $child_channel;
        return 0;
    }

    close $child_channel;
    my $status = eval { _fork_read_exact($parent_channel, 1) };
    if ($@ || !defined $status) {
        my $error = $@ || "fork(): child reconstruction channel closed\n";
        waitpid($pid, 0);
        close $parent_channel;
        die $error;
    }
    if ($status eq 'E') {
        my $length_bytes = _fork_read_exact($parent_channel, 4);
        my $length = defined($length_bytes) ? unpack('N', $length_bytes) : 0;
        my $message = $length ? _fork_read_exact($parent_channel, $length) : undef;
        waitpid($pid, 0);
        close $parent_channel;
        $message //= 'child reconstruction failed';
        croak "fork(): $message";
    }
    if ($status ne 'R') {
        waitpid($pid, 0);
        close $parent_channel;
        croak 'fork(): invalid child reconstruction handshake';
    }

    my $moved = eval {
        for my $object (@$objects) {
            next if ($disposition{ refaddr($object) } // '') ne 'move';
            $object->_fork_parent_move($pid);
        }
        1;
    };
    if (!$moved) {
        my $error = $@ || "fork(): parent move disposition failed\n";
        eval { _fork_write_all($parent_channel, 'A'); 1 };
        waitpid($pid, 0);
        close $parent_channel;
        die $error;
    }

    _fork_write_all($parent_channel, 'C');
    close $parent_channel;
    return $pid;
}

sub add ($self, $object) {
    croak 'add(): object must support loop attachment'
        if !blessed($object) || !$object->can('_attach_to_loop');
    $object->_attach_to_loop($self);
    return $object;
}
sub _defer_state ($self) {
    return $DEFER_STATE{$self} if $DEFER_STATE{$self};

    require Linux::Event::Kernel::Event;
    my $fd = Linux::Event::Kernel::Event::_new_fd();
    my $state = bless {
        fd       => $fd,
        queue    => [],
        pending  => 0,
        signaled => 0,
    }, 'Linux::Event::Loop::_DeferService';

    my $ok = eval {
        $self->watch(
            fd        => $fd,
            _internal => 1,
            read      => sub { $state->_dispatch },
            error     => sub { die "Linux::Event defer event source failed\n" },
            no_args   => 1,
            lean      => 1,
        );
        1;
    };
    if (!$ok) {
        my $error = $@;
        my $close_fd = delete $state->{fd};
        eval { Linux::Event::Kernel::Event::_close_fd($close_fd); 1 }
            if defined $close_fd;
        die $error;
    }

    $DEFER_STATE{$self} = $state;
    return $state;
}

sub defer ($self, $callback) {
    $self->_assert_owner_native('defer');
    croak 'defer(): callback must be a coderef' if ref($callback) ne 'CODE';
    my $state = $self->_defer_state;
    my $deferred = bless {
        state    => $state,
        callback => $callback,
        active   => 1,
    }, 'Linux::Event::_Deferred';
    weaken($deferred->{state});
    $state->_enqueue($deferred);
    return $deferred;
}

sub _deferred_count ($self) {
    my $state = $DEFER_STATE{$self};
    return $state ? $state->{pending} : 0;
}

sub _deferred_fd ($self) {
    my $state = $DEFER_STATE{$self};
    return $state ? $state->{fd} : undef;
}


# A deferred fork cannot execute in a normal defer() callback: that callback
# still runs inside the native driver. The defer eventfd only asks the driver
# to exit. We perform the managed fork after its XS frame has unwound.
sub defer_fork ($self, %option) {
    $self->_assert_owner_native('defer_fork');

    my %known = map { $_ => 1 }
        qw(share clone move on_parent on_child on_error);
    my @unknown = sort grep { !$known{$_} } keys %option;
    croak 'defer_fork(): unknown options: ' . join(', ', @unknown)
        if @unknown;

    for my $mode (qw(share clone move)) {
        next if !exists $option{$mode};
        croak "defer_fork(): $mode must be an array reference"
            if ref($option{$mode}) ne 'ARRAY';
    }
    for my $callback (qw(on_parent on_child on_error)) {
        next if !exists $option{$callback};
        croak "defer_fork(): $callback must be a coderef"
            if ref($option{$callback}) ne 'CODE';
    }

    my $state = $DEFER_FORK_STATE{$self} //= { queue => [], pending => 0 };
    my $request = bless {
        state   => $state,
        options => { map { $_ => $option{$_} }
            grep { exists $option{$_} } qw(share clone move) },
        on_parent => delete $option{on_parent},
        on_child  => delete $option{on_child},
        on_error  => delete $option{on_error},
        active    => 1,
    }, 'Linux::Event::_DeferredFork';
    weaken($request->{state});
    push @{ $state->{queue} }, $request;
    $state->{pending}++;

    # A wakeup also handles requests scheduled while no driver is running,
    # and makes requests queued by on_parent wait for another Loop turn.
    my $weak_loop = $self;
    my $weak_request = $request;
    weaken($weak_loop);
    weaken($weak_request);
    my $ok = eval {
        $self->defer(sub {
            my $loop = $weak_loop // return;
            my $pending = $weak_request // return;
            $loop->_stop_native
                if $pending->{active} && $loop->running;
        });
        1;
    };
    if (!$ok) {
        my $error = $@;
        pop @{ $state->{queue} };
        $state->{pending}--;
        $request->{active} = 0;
        delete @$request{qw(options on_parent on_child on_error)};
        die $error;
    }
    return $request;
}

sub _fork_child_reset_deferred_forks ($self) {
    my $state = delete $DEFER_FORK_STATE{$self};
    return if !$state;
    for my $request (@{ $state->{queue} }) {
        next if !$request;
        $request->{active} = 0;
        delete @$request{qw(options on_parent on_child on_error)};
    }
    $state->{queue} = [];
    $state->{pending} = 0;
    return;
}

# Driver frames are dynamically scoped, never stored on a Loop. In particular,
# this avoids retaining Loop-owned objects across Perl ithread cloning.
sub _current_fork_driver ($self) {
    my $frame = $FORK_DRIVER_FRAME;
    while ($frame) {
        return $frame if refaddr($frame->{loop}) == refaddr($self);
        $frame = $frame->{parent};
    }
    return undef;
}

sub _drain_deferred_forks ($self) {
    my $state = $DEFER_FORK_STATE{$self};
    return 0 if !$state || !$state->{pending};

    # Freeze the eligible set: requests added from completion callbacks wait
    # for the next driver turn, rather than recursively forking here.
    my $eligible = scalar @{ $state->{queue} };
    my $processed = 0;
    for (1 .. $eligible) {
        my $driver = $self->_current_fork_driver;
        last if $driver && $driver->{user_stop};
        my $request = shift @{ $state->{queue} };
        next if !$request || !$request->{active};
        $request->{active} = 0;
        $state->{pending}--;
        $processed++;
        my $options = delete $request->{options};
        my $on_parent = delete $request->{on_parent};
        my $on_child = delete $request->{on_child};
        my $on_error = delete $request->{on_error};

        my $pid;
        my $ok = eval { $pid = $self->fork(%$options); 1 };
        if (!$ok || !defined $pid) {
            my $error = !$ok ? $@ : "defer_fork(): fork failed: $!\n";
            if ($on_error) {
                $on_error->($error);
                next;
            }
            die $error;
        }

        if ($pid == 0) {
            # fork() has discarded the inherited queue in this child.
            $on_child->() if $on_child;
            return $processed;
        }
        $on_parent->($pid) if $on_parent;
    }

    $state->{queue} = [] if !$state->{pending};
    return $processed;
}

sub stop ($self) {
    # A user stop must not be mistaken for defer_fork's internal wakeup.
    my $driver = $self->_current_fork_driver;
    $driver->{user_stop} = 1 if $driver;
    $self->_stop_native();
    return;
}

sub run ($self) {
    my $driver = {
        loop => $self,
        parent => $FORK_DRIVER_FRAME,
        user_stop => 0,
    };
    local $FORK_DRIVER_FRAME = $driver;
    $self->_drain_deferred_forks;
    while (!$driver->{user_stop}) {
        $self->_run_native();
        last if $driver->{user_stop};
        last if !$self->_drain_deferred_forks;
    }
    return;
}

sub run_for ($self, $seconds) {
    require Time::HiRes;
    my $started = Time::HiRes::clock_gettime(Time::HiRes::CLOCK_MONOTONIC());
    my $driver = {
        loop => $self,
        parent => $FORK_DRIVER_FRAME,
        user_stop => 0,
    };
    local $FORK_DRIVER_FRAME = $driver;
    $self->_drain_deferred_forks;
    my $first = 1;
    while (!$driver->{user_stop}) {
        my $elapsed = Time::HiRes::clock_gettime(
            Time::HiRes::CLOCK_MONOTONIC()) - $started;
        my $remaining = $seconds - $elapsed;
        last if !$first && $remaining <= 0;
        # The first native entry still validates all run_for arguments.
        $self->_run_for_native(
            $remaining > 0 ? $remaining : $seconds);
        $first = 0;
        last if $driver->{user_stop};
        last if !$self->_drain_deferred_forks;
    }
    return;
}

sub run_once ($self, @args) {
    my $driver = {
        loop => $self,
        parent => $FORK_DRIVER_FRAME,
        user_stop => 0,
    };
    local $FORK_DRIVER_FRAME = $driver;
    $self->_drain_deferred_forks;
    return 0 if $driver->{user_stop};
    my $n = $self->_run_once_native(@args);
    $self->_drain_deferred_forks if !$driver->{user_stop};
    return $n;
}

sub poll ($self) {
    my $driver = {
        loop => $self,
        parent => $FORK_DRIVER_FRAME,
        user_stop => 0,
    };
    local $FORK_DRIVER_FRAME = $driver;
    $self->_drain_deferred_forks;
    return 0 if $driver->{user_stop};
    my $n = $self->_poll_native();
    $self->_drain_deferred_forks if !$driver->{user_stop};
    return $n;
}

sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Loop::_DeferService;

sub _signal ($self) {
    return if $self->{signaled};
    Linux::Event::Kernel::Event::_signal_fd($self->{fd}, 1);
    $self->{signaled} = 1;
    return;
}

sub _enqueue ($self, $deferred) {
    push @{ $self->{queue} }, $deferred;
    $self->{pending}++;
    my $ok = eval { $self->_signal; 1 };
    return if $ok;

    my $error = $@;
    pop @{ $self->{queue} };
    $self->{pending}--;
    $deferred->{active} = 0;
    delete $deferred->{callback};
    die $error;
}

sub _cancel ($self, $deferred) {
    return if !$deferred->{active};
    $deferred->{active} = 0;
    delete $deferred->{callback};
    $self->{pending}-- if $self->{pending};
    $self->{queue} = [] if !$self->{pending};
    return;
}

sub _fork_child_drop ($self) {
    for my $deferred (@{ $self->{queue} // [] }) {
        next if !$deferred;
        $deferred->{active} = 0;
        delete $deferred->{callback};
    }
    $self->{queue} = [];
    $self->{pending} = 0;
    $self->{signaled} = 0;
    my $fd = delete $self->{fd};
    eval { Linux::Event::Kernel::Event::_close_fd($fd); 1 } if defined $fd;
    return;
}

sub _dispatch ($self) {
    return if !defined $self->{fd};
    Linux::Event::Kernel::Event::_drain_fd($self->{fd});
    $self->{signaled} = 0;

    my $eligible = scalar @{ $self->{queue} };
    $eligible = $DEFER_CALLBACK_BATCH
        if $eligible > $DEFER_CALLBACK_BATCH;

    my $error;
    for (1 .. $eligible) {
        my $deferred = shift @{ $self->{queue} };
        next if !$deferred || !$deferred->{active};

        $deferred->{active} = 0;
        $self->{pending}-- if $self->{pending};
        my $callback = delete $deferred->{callback};

        local $@;
        my $ok = eval { $callback->(); 1 };
        if (!$ok) {
            $error = $@ || "deferred callback failed\n";
            last;
        }
    }

    if (!$self->{pending}) {
        $self->{queue} = [];
    }
    else {
        local $@;
        my $ok = eval { $self->_signal; 1 };
        $error = $@ || "defer event source signal failed\n"
            if !$ok && !defined $error;
    }

    die $error if defined $error;
    return;
}

sub CLONE_SKIP ($class) { 1 }

sub DESTROY ($self) {
    for my $deferred (@{ $self->{queue} // [] }) {
        next if !$deferred;
        $deferred->{active} = 0;
        delete $deferred->{callback};
    }
    $self->{queue} = [];
    $self->{pending} = 0;
    my $fd = delete $self->{fd};
    eval { Linux::Event::Kernel::Event::_close_fd($fd); 1 } if defined $fd;
    return;
}

package Linux::Event::_Deferred;

sub cancel ($self) {
    return $self if !$self->{active};
    my $state = $self->{state};
    if ($state) {
        $state->_cancel($self);
    }
    else {
        $self->{active} = 0;
        delete $self->{callback};
    }
    return $self;
}

sub is_active ($self) { !!$self->{active} }
sub CLONE_SKIP ($class) { 1 }

package Linux::Event::_DeferredFork;

sub cancel ($self) {
    return $self if !$self->{active};
    $self->{active} = 0;
    delete @$self{qw(options on_parent on_child on_error)};
    my $state = $self->{state};
    if ($state && $state->{pending}) {
        $state->{pending}--;
        $state->{queue} = [] if !$state->{pending};
    }
    return $self;
}

sub is_active ($self) { !!$self->{active} }
sub CLONE_SKIP ($class) { 1 }

package Linux::Event::_Registration;
sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Loop;

1;

__END__

=head1 NAME

Linux::Event::Loop - Run and coordinate Linux::Event resources

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::Kernel::Timer;

  my $loop = Linux::Event::Loop->new;

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 1,

      on_timer => sub ($timer) {
          say "One second has passed";
          $loop->stop;
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::Loop> is the heart of a Linux::Event application.

You create resources such as sockets, timers, processes, signals, or filesystem
watches and attach them to a Loop.

The Loop then waits until something happens and calls the appropriate Perl
callback.

A simple program usually follows this pattern:

  my $loop = Linux::Event::Loop->new;

  # Create resources and attach them to $loop.

  $loop->run;

The Loop uses Linux epoll internally, but normal applications do not need to
work with epoll directly.

=head1 CREATING A LOOP

Create a Loop with:

  my $loop = Linux::Event::Loop->new;

A program may have more than one Loop, although most applications need only one.

Resources belong to the Loop they are attached to. A resource cannot normally
be moved to another Loop after it has been attached.

=head1 ADDING RESOURCES

Most Linux::Event resources can be attached to a Loop in either of two ways.

The first is to supply the Loop when constructing the resource:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop     => $loop,
      after    => 1,
      on_timer => sub ($timer) {
          say "timer fired";
      },
  );

The second is to construct the resource first and add it afterward:

  my $timer = Linux::Event::Kernel::Timer->new(
      after    => 1,
      on_timer => sub ($timer) {
          say "timer fired";
      },
  );

  $loop->add($timer);

Both styles are normal Linux::Event APIs.

=head2 add($object)

  $loop->add($object);

Attach a Linux::Event resource to this Loop.

C<add> returns the same object, so this is also convenient:

  my $timer = $loop->add(
      Linux::Event::Kernel::Timer->new(
          after    => 1,
          on_timer => sub ($timer) {
              say "timer fired";
          },
      )
  );

Once attached, the Loop keeps the resource alive until that resource reaches
the end of its normal lifecycle.

For example, a Timer remains owned by the Loop until it is cancelled or
finishes.

=head1 RUNNING THE LOOP

=head2 run

  $loop->run;

Run the event loop until C<stop> is requested.

While C<run> is active, the Loop waits for events and dispatches callbacks as
they become ready.

For many applications this is the only Loop-driving method that is needed.

=head2 stop

  $loop->stop;

Ask an active C<run> or C<run_for> to finish after the current dispatch work is
complete.

For example:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 5,

      on_timer => sub ($timer) {
          say "Finished";
          $loop->stop;
      },
  );

  $loop->run;

C<stop> does not destroy the Loop. It may be driven again later.

=head2 run_for($seconds)

  $loop->run_for(10);

Run the Loop for at most the supplied number of seconds.

The time is measured with a monotonic clock, so changes to the system wall
clock do not change the deadline.

Fractional seconds may be used.

=head2 run_once($timeout_ms)

  $loop->run_once(100);

Wait for and dispatch one batch of events.

The timeout is expressed in milliseconds:

=over 4

=item *

A negative value waits indefinitely.

=item *

Zero does not wait.

=item *

A positive value is the maximum amount of time to wait.

=back

If the argument is omitted, C<run_once> waits indefinitely.

This method is useful when an application wants explicit control over each Loop
turn.

=head1 DEFERRED WORK

=head2 defer($callback)

  $loop->defer(sub {
      say "Run this shortly";
  });

C<defer> schedules a callback to run on a later Loop turn.

It does B<not> call the callback immediately.

This is useful when work needs to happen soon, but should not happen
recursively inside the callback that is currently running.

For example:

  sub on_message ($stream, $message) {
      update_state($message);

      $loop->defer(sub {
          process_updated_state();
      });
  }

The deferred callback takes no arguments.

Callbacks are normally delivered in the order they were queued.

If a deferred callback queues another deferred callback, the new callback waits
for a later deferred turn rather than running recursively during the current
one.

=head2 Cancelling deferred work

C<defer> returns a small one-shot handle:

  my $pending = $loop->defer(sub {
      expensive_work();
  });

It supports:

  $pending->cancel;

and:

  $pending->is_active;

C<cancel> is safe to call more than once.

Dropping your own reference to the handle does not cancel the callback. The
Loop keeps pending deferred work alive until it runs, is cancelled, or the Loop
is destroyed.

=head2 Errors in deferred callbacks

If a deferred callback dies, the exception propagates through the Loop driver.

Later deferred callbacks are left pending so they can still run if the
application catches the exception and drives the Loop again.

=head2 Fairness

One deferred dispatch processes at most 1,024 queued entries.

If more work remains, the Loop schedules another turn.

This prevents a self-sustaining chain of deferred callbacks from indefinitely
preventing sockets, timers, and other kernel events from running.

=head2 Threads and processes

C<defer> schedules Perl callbacks only within the interpreter that owns the
Loop.

It is not a cross-thread or cross-process callback queue.

To wake a Loop from another thread or process, pass the actual data through an
appropriate shared queue or IPC mechanism and use
L<Linux::Event::Kernel::Event> to wake the Loop.

=head1 CHECKING LOOP STATE

=head2 running

  if ($loop->running) {
      ...
  }

Returns true while this Loop is currently inside C<run>, C<run_for>,
C<run_once>, or C<poll>.

It is also true when called from a callback dispatched by one of those methods.

A Loop cannot recursively drive itself. Calling another driving method on the
same Loop while it is already dispatching throws an exception.

A callback may, however, drive a different Loop.

=head1 LOOP-AWARE FORKING

=head2 fork(%disposition)

Linux::Event provides a managed form of C<fork> for applications that need to
fork after Loop resources already exist.

For example:

  my $pid = $loop->fork(
      share => [ $listener ],
      clone => [ $timer ],
      move  => [ $connection ],
  );

The return value follows Perl's normal C<fork> convention:

=over 4

=item *

The parent receives the child's positive PID.

=item *

The child receives zero.

=item *

A system C<fork> failure returns undef and leaves C<$!> set.

=back

The important difference from calling C<CORE::fork> directly is that
Linux::Event rebuilds the child's event-loop infrastructure and applies an
explicit plan for existing resources.

=head2 The three dispositions

Resources listed under C<share>, C<clone>, or C<move> receive different
treatment.

=head3 share

The resource remains active in both processes using intentionally shared
underlying operating-system state.

For example, a listening socket can be shared so either process may accept new
connections.

=head3 clone

The child gets its own independent equivalent resource.

The parent keeps its original resource.

For example, cloning a Timer gives the child its own timer scheduled for the
same absolute monotonic deadline.

=head3 move

The resource becomes child-only.

The child first reconstructs the resource successfully. The parent then gives
up its side of the resource before the child is released to continue.

=head2 Unlisted resources

Resources that are not listed are parent-only.

Their inherited copies in the child are made inactive without calling normal
application lifecycle callbacks.

This makes the safe default explicit: a resource does not accidentally become
active in both processes merely because C<fork> duplicated the process.

=head2 Currently supported dispositions

The initial managed-fork support is intentionally conservative.

=over 4

=item Listener

Supports C<share> and C<move>.

=item Timer

Supports C<clone> and C<move>.

=item Inotify

Supports C<clone> and C<move>.

=item Established plain Stream sockets

Support C<move>.

C<share> is not supported for Stream connections.

=back

Other public resource types currently use the default parent-only behavior in
the child.

Pending connections, active resolver requests, and Stream transports that
cannot be safely reconstructed cause managed fork to reject the operation.

=head2 When fork may be called

C<< $loop->fork(...) >> may only be called while the Loop is quiescent.

It cannot be called while C<run>, C<run_once>, C<run_for>, C<poll>, or one of
their callbacks is actively dispatching.

In particular, do not call it directly from an event callback.

=head2 defer_fork(%options)

C<defer_fork> is the safe way to request a managed fork from a Stream, Timer,
or other event callback. It accepts the same C<share>, C<clone>, and C<move>
resource lists as C<fork>, plus three optional callbacks:

  on_parent => sub ($pid) { ... }
  on_child  => sub { ... }
  on_error  => sub ($message) { ... }

For example, to give a connected client its own child process
when it sends one complete framed message:

  # Inside a Stream configured with a message framer:
  on_message => sub ($stream, $message) {
      return unless $message eq 'FORK';

      $loop->defer_fork(
          move => [$stream],
          on_parent => sub ($pid) {
              say "Client moved to child $pid";
          },
          on_child => sub {
              say "Child now owns the client connection";
          },
          on_error => sub ($message) {
              warn $message;
          },
      );
  },

C<defer_fork> only queues the request. It does not fork immediately. After
the active native dispatch has finished, the Loop uses its existing managed
C<fork> implementation to rebuild child resources. The appropriate callback
then runs outside dispatch: C<on_parent> receives the new PID in the parent;
C<on_child> runs in the child with no arguments. Once these callbacks return,
the original Loop-driving method continues in the appropriate process; do
not call C<run> recursively from C<on_child>. The application still needs
to reap child processes and decide when a child should stop its Loop.

Unlike C<fork>, this method returns a one-shot request handle rather than a
PID. It supports C<cancel> and C<is_active>. Cancelling a request before it
is processed prevents the fork. Dropping the handle does not cancel it.

Requests waiting in the parent are discarded from a newly forked child's
queue, avoiding accidental additional children. Requests added from a
completion callback wait for another Loop turn.

When the actual fork fails, C<on_error> receives an error message, and neither
the parent nor child success callback runs. If there is no C<on_error>, the
error propagates from the Loop driver. Bad option names and callback types
are rejected when the request is queued.

This works with C<run>, C<run_for>, C<run_once>, and C<poll>. A normal
C<< $loop->stop >> call still stops the active driver. If both a stop and a
deferred fork are requested during that driver call, the explicit stop wins;
the pending fork remains queued for a later drive.

The current managed-fork resource restrictions and thread-safety rules apply
equally to C<defer_fork>. It does not add support for TLS Stream moves or
other unsupported dispositions.

=head2 Threads and fork

Managed fork assumes the application does not have unrelated live native
threads at the time of the fork.

Linux::Event can prepare its own resolver service, but it cannot make arbitrary
third-party native libraries or application-created thread state safe after a
process fork.

=head2 Why ordinary CORE::fork is different

The Loop belongs to the process that created it.

After an ordinary C<CORE::fork>, the child must not continue using the inherited
Loop as though nothing happened.

Linux::Event detects attempts to drive, modify, introspect, or tune such an
inherited parent Loop and throws instead of silently operating on unsafe copied
reactor state.

Use C<< $loop->fork(...) >> when existing Linux::Event resources must survive
into the child.

=head1 LOW-LEVEL FILE DESCRIPTOR WATCHING

Most applications should use Linux::Event resource classes such as Stream,
Listener, Timer, Signal, Process, and Inotify.

For specialized code, the Loop can also watch a file descriptor directly.

=head2 watch

A filehandle may be watched:

  my $watch = $loop->watch(
      fh   => $fh,

      read => sub ($watch) {
          ...
      },
  );

or an integer file descriptor may be used:

  my $watch = $loop->watch(
      fd   => $fd,

      read => sub ($watch) {
          ...
      },
  );

The returned value is an opaque registration handle.

=head2 Read, write, and error callbacks

C<watch> accepts:

=over 4

=item C<read>

Called when the descriptor is ready for reading.

=item C<write>

Called when the descriptor is ready for writing.

=item C<error>

Called for terminal or error readiness.

=back

If one kernel event contains several kinds of readiness, callbacks run in this
order:

  error
  read
  write

If one callback cancels the registration, callbacks later in that sequence are
not called for the same event.

=head2 data

An arbitrary value may be stored with the registration:

  my $watch = $loop->watch(
      fd   => $fd,
      data => $state,
      read => sub ($watch) {
          my $state = $watch->data;
          ...
      },
  );

=head2 no_args

Normally each readiness callback receives the registration handle.

Use:

  no_args => 1

to call the callbacks without arguments.

=head2 edge_triggered

  edge_triggered => 1

uses epoll edge-triggered readiness.

This is an advanced option. Code using it must completely drain the descriptor
until it reaches C<EAGAIN>.

=head2 oneshot

  oneshot => 1

uses C<EPOLLONESHOT>.

The application is responsible for deciding when and how to re-enable
readiness.

=head2 lean

  no_args => 1,
  lean    => 1,

avoids retaining some state that exists only to support registration-handle
accessors.

This is an advanced optimization for code where registration throughput has
been measured to matter.

=head2 One registration per descriptor

A Loop has one current low-level registration for a file descriptor.

Watching the same descriptor again replaces the current registration.

An older handle becomes obsolete and cannot accidentally remove the newer
registration if it is later cancelled.

=head1 REGISTRATION HANDLE

The value returned by C<watch> supports:

  fd
  fh
  data
  loop
  lean
  cancel
  enable_read
  disable_read
  enable_write
  disable_write

=head2 cancel

  $watch->cancel;

Cancel the registration.

Cancellation is idempotent.

=head2 enable_read / disable_read

Enable or disable ordinary read interest.

=head2 enable_write / disable_write

Enable or disable ordinary write interest.

=head2 fd

Return the integer file descriptor.

=head2 fh

Return the retained Perl filehandle when the registration was created with
C<fh>.

An fd-only registration returns undef.

=head2 data

Return the value supplied with C<data>.

=head2 loop

Return the owning Loop.

=head1 OTHER LOW-LEVEL METHODS

=head2 watch_fd

  $loop->watch_fd($fd, read => sub { ... });

This is a lower-level positional form used primarily by Linux::Event internals
and specialized code.

Normal application code should prefer C<watch>.

=head2 unwatch_fd

  $loop->unwatch_fd($fd);

Cancel the current registration for that descriptor, if one exists.

When a registration handle is already available, its C<cancel> method is
usually clearer.

=head1 USING LINUX::EVENT INSIDE ANOTHER EVENT LOOP

Linux::Event can be driven underneath another event system.

The two important methods are C<poll_fd> and C<poll>.

=head2 poll_fd

  my $fd = $loop->poll_fd;

Return the epoll descriptor owned by this Linux::Event Loop.

That descriptor becomes readable when Linux::Event has kernel events waiting.

A foreign event loop can therefore watch it just like another readable file
descriptor.

The returned fd is borrowed.

Do not close it.

Linux::Event owns it and will close it when the Loop is destroyed.

If another API requires a Perl filehandle, duplicate the descriptor rather than
taking ownership of the original.

=head2 poll

  my $events = $loop->poll;

Perform one nonblocking Linux::Event dispatch turn.

C<poll> does not wait for events.

A typical foreign-loop adapter therefore does this:

  1. Watch $loop->poll_fd for readability.
  2. When it becomes readable, call $loop->poll once.

C<poll> returns the number of events returned by epoll for that turn.

This is the supported foreign-loop integration boundary.

=head1 INTROSPECTION

Linux::Event provides several methods for asking what a Loop currently owns and
why it is still alive.

These methods are primarily diagnostic tools.

=head2 count

  my $count = $loop->count;

Return the number of current public Linux::Event resource objects.

Private helper registrations and raw C<watch> registrations are not included.

=head2 has($object)

  if ($loop->has($timer)) {
      ...
  }

Return true when that exact resource is currently owned by this Loop.

=head2 objects

  my $objects = $loop->objects;

Return a new array reference containing the current public resource objects.

The order is unspecified.

=head2 inspect($object)

  my $info = $loop->inspect($object);

Return a snapshot describing a Linux::Event resource.

Every result contains basic fields such as its type, class, and whether it is
currently registered with this Loop.

Active resources also include resource-specific information.

See F<docs/INTROSPECTION.md> for the complete field definitions.

=head2 census

  my $counts = $loop->census;

Return counts grouped by Linux::Event resource type.

See F<docs/INTROSPECTION.md> for the exact keys.

=head2 resources

  my $resources = $loop->resources;

Return a lower-level snapshot of Loop resources such as registrations, timer
state, capacities, and backing descriptors.

This is useful when investigating what the reactor itself currently owns.

=head2 why_alive

  my $reasons = $loop->why_alive;

Return an array reference explaining which user-visible resources are keeping
the Loop active.

This is particularly useful when a program appears to have finished its work
but still has live resources.

=head2 pressure

  my $pressure = $loop->pressure;

Return capacity and utilization information for native registration, timer, and
event-batch storage.

This describes implementation pressure. It is not a general performance,
latency, or health score.

=head1 STATISTICS

=head2 stats

  my $stats = $loop->stats;

Return Loop counters such as epoll waits, callbacks, registrations, timer
activity, and dispatch activity.

=head2 reset_stats

  $loop->reset_stats;

Reset diagnostic counters without changing the Loop's profiling setting.

=head2 profile($boolean)

  $loop->profile(1);

Enable or disable nanosecond timing collection used by Loop statistics.

Profiling adds measurement overhead and should normally be disabled when running
performance benchmarks.

=head1 ADVANCED TUNING

The default Loop settings are intended to work well for normal applications.

Change them only when application-specific measurements show a reason to do so.

=head2 event_capacity

  my $capacity = $loop->event_capacity;

Return the reusable epoll event-array capacity.

The default is 8,192 events.

=head2 set_event_capacity($capacity)

  $loop->set_event_capacity(16_384);

Change the event-array capacity.

The value must be between 1 and 1,048,576.

A larger value allows one epoll wait to return more ready registrations at once
but also uses a larger reusable event array.

This setting cannot be changed while the Loop is running or dispatching.

=head2 callback_scope_limit

  my $limit = $loop->callback_scope_limit;

Return the number of callbacks allowed to share one bounded Perl temporary
scope.

The default is 128.

=head2 set_callback_scope_limit($limit)

  $loop->set_callback_scope_limit(256);

Set the callback scope limit.

A value of zero allows the entire dispatch batch to use one scope.

Positive values rotate the scope after that many callbacks.

This is a performance and memory-lifetime tuning control and should normally be
left at its measured default.

=head2 enable_watcher_reclaim

  $loop->enable_watcher_reclaim(1);

Enable immediate recycling of native watcher structures after dispatch.

This is experimental and defaults to disabled.

It exposes a memory-versus-throughput tradeoff and should be changed only when
application benchmarks justify it.

=head1 INTERPRETER OWNERSHIP

A Loop belongs to the Perl interpreter that created it.

The Loop itself and the native objects it owns are not cloned into another Perl
ithread.

L<Linux::Event::Kernel::Event> has limited support for being signaled from
another thread, but that does not give the other thread access to the owning
Loop or its Perl callbacks.

=head1 PUBLIC RESOURCE CLASSES

The main resource types that can be attached to a Loop are:

=over 4

=item *

L<Linux::Event::IO::Sock::Stream>

=item *

L<Linux::Event::IO::Sock::Listener>

=item *

L<Linux::Event::IO::Sock::Dgram>

=item *

L<Linux::Event::IO::Pipe>

=item *

L<Linux::Event::IO::TTY>

=item *

L<Linux::Event::Kernel::Timer>

=item *

L<Linux::Event::Kernel::Signal>

=item *

L<Linux::Event::Kernel::Event>

=item *

L<Linux::Event::Kernel::Inotify>

=item *

L<Linux::Event::Kernel::Process>

=back

=head1 PLATFORM

C<Linux::Event::Loop> runs only on Linux.

It uses Linux epoll directly.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Kernel::Timer>,
L<Linux::Event::IO::Sock::Stream>,
F<docs/INTROSPECTION.md>.

=cut
