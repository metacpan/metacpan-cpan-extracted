package Linux::Event::Loop;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.009';

use Scalar::Util qw(looks_like_number);
use Carp qw(croak);
use Linux::Event::Scheduler;
use Linux::Event::Clock;
use Linux::Event::Timer;
use Linux::Event::Backend::Epoll;
use Linux::Event::Watcher;
use Linux::Event::Signal;
use Linux::Event::Wakeup;
use Linux::Event::Pid;

use constant READABLE => 0x01;
use constant WRITABLE => 0x02;
use constant PRIO     => 0x04;
use constant RDHUP    => 0x08;
use constant ET       => 0x10;
use constant ONESHOT  => 0x20;
use constant ERR      => 0x40;
use constant HUP      => 0x80;

sub new ($class, %args) {
  my $backend = delete $args{backend};
  my $clock   = delete $args{clock};
  my $timer   = delete $args{timer};

  croak "unknown args: " . join(", ", sort keys %args) if %args;

  $clock //= Linux::Event::Clock->new(clock => 'monotonic');
  for my $m (qw(tick now_ns deadline_in_ns remaining_ns)) {
    croak "clock missing method '$m'" if !$clock->can($m);
  }

  $timer //= Linux::Event::Timer->new;
  for my $m (qw(after disarm read_ticks fh)) {
    croak "timer missing method '$m'" if !$timer->can($m);
  }

  $backend = _build_backend($backend);
  for my $m (qw(watch unwatch run_once)) {
    croak "backend missing method '$m'" if !$backend->can($m);
  }
  # modify is optional in this release; Loop can fall back to unwatch+watch.

  my $sched = Linux::Event::Scheduler->new(clock => $clock);

  my $self = bless {
    clock   => $clock,
    timer   => $timer,
    backend => $backend,
    sched   => $sched,
    running => 0,

    _watchers => {},     # fd -> Linux::Event::Watcher
    _timer_w  => undef,  # internal timerfd watcher
  }, $class;

  # Internal timerfd watcher: read -> dispatch due timers -> rearm kernel timer.
  my $t_fh = $timer->fh;
  my $t_fd = fileno($t_fh);
  croak "timer fh has no fileno" if !defined $t_fd;

  $self->{_timer_w} = $self->watch(
    $t_fh,
    read => sub ($loop, $fh, $w) {
      $loop->{timer}->read_ticks;
      $loop->{clock}->tick;
      $loop->_dispatch_due;
      $loop->_rearm_timer;
    },
    data => undef,
  );

  return $self;
}

sub _build_backend ($backend) {
  return Linux::Event::Backend::Epoll->new if !defined $backend;

  if (!ref($backend)) {
    return Linux::Event::Backend::Epoll->new if $backend eq 'epoll';
    croak "unknown backend '$backend'";
  }

  return $backend;
}

sub clock   ($self) { return $self->{clock} }
sub timer   ($self) { return $self->{timer} }
sub backend ($self) { return $self->{backend} }
sub sched   ($self) { return $self->{sched} }

# -- Signals --------------------------------------------------------------

sub signal ($self, @args) {
  return ($self->{_signal} ||= Linux::Event::Signal->new(loop => $self))->signal(@args);
}

# -- Wakeups --------------------------------------------------------------

sub waker ($self) {
  if (!$self->{_waker}) {
    my $w = Linux::Event::Wakeup->new(loop => $self);
    $self->{_waker} = $w;

    # Internal watcher: drain wakeups.
    $self->watch(
      $w->fh,
      read => sub ($loop, $fh, $watcher) {
        $w->drain;
      },
      data => undef,
    );
  }

  return $self->{_waker};
}

# -- Pidfds ---------------------------------------------------------------

sub pid ($self, @args) {
  $self->{pid_adaptor} //= Linux::Event::Pid->new(loop => $self);
  return $self->{pid_adaptor}->pid(@args);
}

# -- Timers ---------------------------------------------------------------

sub after ($self, $seconds, $cb) {
  croak "seconds is required" if !defined $seconds;
  croak "cb is required" if !$cb;
  croak "cb must be a coderef" if ref($cb) ne 'CODE';

  $self->{clock}->tick;

  my $delta_ns = int($seconds * 1_000_000_000);
  $delta_ns = 0 if $delta_ns < 0;

  my $id = $self->{sched}->after_ns($delta_ns, $cb);
  $self->_rearm_timer;
  return $id;
}

sub at ($self, $deadline_seconds, $cb) {
  croak "deadline_seconds is required" if !defined $deadline_seconds;
  croak "cb is required" if !$cb;
  croak "cb must be a coderef" if ref($cb) ne 'CODE';

  my $deadline_ns = int($deadline_seconds * 1_000_000_000);

  my $id = $self->{sched}->at_ns($deadline_ns, $cb);
  $self->_rearm_timer;
  return $id;
}

sub cancel ($self, $id) {
  my $ok = $self->{sched}->cancel($id);
  $self->_rearm_timer if $ok;
  return $ok;
}

# -- Watchers -------------------------------------------------------------

sub watch ($self, $fh, %spec) {
  croak "fh is required" if !$fh;

  my $read           = delete $spec{read};
  my $write          = delete $spec{write};
  my $error          = delete $spec{error};
  my $data           = delete $spec{data};
  my $edge_triggered = delete $spec{edge_triggered};
  my $oneshot        = delete $spec{oneshot};

  croak "unknown args: " . join(", ", sort keys %spec) if %spec;

  if (defined $read && ref($read) ne 'CODE') {
    croak "read must be a coderef or undef";
  }
  if (defined $write && ref($write) ne 'CODE') {
    croak "write must be a coderef or undef";
  }
  if (defined $error && ref($error) ne 'CODE') {
    croak "error must be a coderef or undef";
  }

  my $fd = fileno($fh);
  croak "fh has no fileno" if !defined $fd;
  $fd = int($fd);

  if (my $old = $self->{_watchers}{$fd}) {
    $self->_watcher_cancel($old);
  }

  my $w = Linux::Event::Watcher->new(
    loop           => $self,
    fh             => $fh,
    fd             => $fd,
    read           => $read,
    write          => $write,
    error          => $error,
    data           => $data,
    edge_triggered => $edge_triggered ? 1 : 0,
    oneshot        => $oneshot ? 1 : 0,
  );

  my $dispatch = sub ($loop, $fh_from_backend, $fd2, $mask, $tag) {
    my $ww = $loop->{_watchers}{$fd2} or return;

    my $fhw = $ww->{fh};
    if (!$fhw) {
      $loop->_watcher_cancel($ww);
      return;
    }
    my $fnow = fileno($fhw);
    if (!defined $fnow || int($fnow) != $fd2) {
      $loop->_watcher_cancel($ww);
      return;
    }

    # Frozen dispatch contract:
    #  - ERR: call error handler first if installed+enabled; otherwise treat as read+write.
    #  - HUP: also triggers read (EOF detection).
    my $read_trig  = ($mask & READABLE) ? 1 : 0;
    my $write_trig = ($mask & WRITABLE) ? 1 : 0;

    if ($mask & ERR) {
      if ($ww->{error_cb} && $ww->{error_enabled}) {
        $ww->{error_cb}->($loop, $fhw, $ww);
        return;
      }
      $read_trig  = 1;
      $write_trig = 1;
    }

    $read_trig = 1 if ($mask & HUP);

    if ($read_trig && $ww->{read_cb} && $ww->{read_enabled}) {
      $ww->{read_cb}->($loop, $fhw, $ww);
    }

    my $still = $loop->{_watchers}{$fd2};
    if (!$still || $still != $ww) {
      return;
    }

    if ($write_trig && $ww->{write_cb} && $ww->{write_enabled}) {
      $ww->{write_cb}->($loop, $fhw, $ww);
    }

    return;
  };

  $w->{_dispatch_cb} = $dispatch;

  $self->{_watchers}{$fd} = $w;

  my $mask = $self->_watcher_mask($w);
  $self->{backend}->watch($fh, $mask, $dispatch, _loop => $self, tag => undef);

  return $w;
}

sub _watcher_mask ($self, $w) {
  my $mask = 0;

  $mask |= READABLE if $w->{read_cb}  && $w->{read_enabled};
  $mask |= WRITABLE if $w->{write_cb} && $w->{write_enabled};

  $mask |= ET      if $w->{edge_triggered};
  $mask |= ONESHOT if $w->{oneshot};

  return $mask;
}

sub _watcher_update ($self, $w) {
  return 0 if !$w->{active};

  my $mask = $self->_watcher_mask($w);

  if ($self->{backend}->can('modify')) {
    return $self->{backend}->modify($w->{fh}, $mask);
  }

  # Fallback: unwatch+watch, preserving dispatch cb.
  $self->{backend}->unwatch($w->{fh});
  $self->{backend}->watch($w->{fh}, $mask, $w->{_dispatch_cb}, _loop => $self, tag => undef);
  return 1;
}

sub _watcher_cancel ($self, $w) {
  return if !$w || !$w->{active};

  $w->{active} = 0;
  delete $self->{_watchers}{ $w->{fd} };

  $self->{backend}->unwatch($w->{fh});
  $w->{fh} = undef;

  return;
}

sub unwatch ($self, $fh) {
  return 0 if !$fh;

  my $fd = fileno($fh);
  return 0 if !defined $fd;
  $fd = int($fd);

  my $w = delete $self->{_watchers}{$fd} or return 0;
  $self->_watcher_cancel($w);

  return 1;
}

sub run ($self) {
  # run() controls the running flag. run_once() may be called manually even
  # when the loop is not in run() mode (tests and advanced callers rely on
  # this), so run_once() must only honor running=0 when run() is active.
  local $self->{_in_run} = 1;
  $self->{running} = 1;

  while ($self->{running}) {
    $self->run_once;
  }

  return;
}

sub stop ($self) {
  $self->{running} = 0;

  # If a waker was already created (user called $loop->waker), poke it so a
  # currently-blocking backend wait can return promptly. This does not create
  # the waker implicitly (contract: no implicit watcher).
  if (my $w = $self->{_waker}) {
    eval { $w->signal; 1 };
  }

  return;
}

sub run_once ($self, $timeout_s = undef) {
  # One syscall per iteration/batch: refresh cached monotonic time.
  $self->{clock}->tick;

  # Snapshot whether we were "running" at entry. This matters because callers
  # are allowed to pump the loop manually via run_once() without calling run()
  # (so running may be false). If running *was* true and stop() flips it during
  # callback dispatch, we must not enter backend wait in the same iteration.
  my $was_running = $self->{running} ? 1 : 0;

  # Run any due timer callbacks before blocking.
  $self->_dispatch_due;

  # stop() can be called from a timer callback (or other user callback).
  # - If we're inside run(), honor running immediately.
  # - If running was true at entry, also honor it (prevents an extra backend wait)
  # - If running was false at entry, allow manual pumping.
  return 0 if (!$self->{running} && ($self->{_in_run} || $was_running));

  # If no explicit timeout was provided, derive one from the next scheduled
  # timer deadline. This is what makes $loop->run() advance timers without
  # requiring callers to manually pass a timeout.
  if (!defined $timeout_s) {
    my $next = $self->{sched}->next_deadline_ns;
    if (defined $next) {
      my $remain_ns = $self->{clock}->remaining_ns($next);
      $timeout_s = ($remain_ns <= 0) ? 0 : ($remain_ns / 1_000_000_000);
    }
  }

  # Keep timerfd state in sync for users who may be watching the timer fd
  # directly (or for future backends that integrate it). This is not relied on
  # for core scheduling.
  $self->_rearm_timer;

  # Re-check after rearm, since user callbacks can run during _rearm_timer()
  # (e.g. via a custom timer implementation).
  return 0 if (!$self->{running} && ($self->{_in_run} || $was_running));

  return $self->{backend}->run_once($self, $timeout_s);
}


sub _dispatch_due ($self) {
  my @ready = $self->{sched}->pop_expired;
  for my $item (@ready) {
    my ($id, $cb, $deadline_ns) = @$item;

    # Timer callbacks are invoked with just ($loop).
    $cb->($self);
  }
  return;
}


use Scalar::Util qw(looks_like_number);

sub _rearm_timer ($self) {
  my $next = $self->{sched}->next_deadline_ns;

  if (!defined $next) {
    $self->{timer}->disarm;
    return;
  }

  my $remain_ns = $self->{clock}->remaining_ns($next);

  return if !defined $remain_ns;
  return if !looks_like_number($remain_ns);

  if ($remain_ns <= 0) {
    # Minimal non-zero delay (fixed decimal, no exponent).
    my $min_s = sprintf('%.9f', 1 / 1_000_000_000);
    $self->{timer}->after($min_s);
    return;
  }

  my $after_s = $remain_ns / 1_000_000_000;

  return if !looks_like_number($after_s);

  # IMPORTANT: format to fixed decimal so Timer::_num accepts it.
  $self->{timer}->after(sprintf('%.9f', $after_s));

  return;
}

1;

__END__

=head1 NAME

Linux::Event::Loop - Linux-native event loop (epoll + timerfd + signalfd + eventfd + pidfd)

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event;

  my $loop = Linux::Event->new;   # epoll backend, monotonic clock

  # I/O watcher (read/write) with user data stored on the watcher:
  my $conn = My::Conn->new(...);

  my $w = $loop->watch($fh,
    read  => \&My::Conn::on_read,
    write => \&My::Conn::on_write,
    error => \&My::Conn::on_error,   # optional
    data  => $conn,                   # optional (avoid closure captures)

    edge_triggered => 0,              # optional, default false
    oneshot        => 0,              # optional, default false
  );

  $w->disable_write;

  # Timers (monotonic)
  my $id = $loop->after(0.250, sub ($loop) {
    say "250ms later";
  });

  # Signals (signalfd): strict 4-arg callback
  my $sub = $loop->signal('INT', sub ($loop, $sig, $count, $data) {
    say "SIG$sig ($count)";
    $loop->stop;
  });

  # Wakeups (eventfd): create once, then use to wake a blocking run()
  my $waker = $loop->waker;

  # In another thread/process (or any place you need to wake the loop):
  #   $waker->signal;
  #
  # After calling $loop->waker, the loop installs an internal watcher that drains
  # the wakeup fd automatically. The wakeup fd is reserved for loop wakeups.

  # Pidfds (pidfd): one-shot exit notification
  my $pid = fork() // die "fork: $!";
  if ($pid == 0) { exit 42 }

  my $psub = $loop->pid($pid, sub ($loop, $pid, $status, $data) {
    require POSIX;
    if (POSIX::WIFEXITED($status)) {
      say "child $pid exited: " . POSIX::WEXITSTATUS($status);
    }
  });

  $loop->run;

=head1 DESCRIPTION

Linux::Event::Loop is a minimal, Linux-native event loop that exposes Linux
FD primitives cleanly and predictably. It is built around:

=over 4

=item * C<epoll(7)> for I/O readiness

=item * C<timerfd(2)> for timers

=item * C<signalfd(2)> for signal delivery

=item * C<eventfd(2)> for explicit wakeups

=item * C<pidfd_open(2)> (via L<Linux::FD::Pid>) for process lifecycle notifications

=back

Linux::Event is intentionally I<not> a networking framework, protocol layer,
retry/backoff engine, process supervisor, or socket abstraction. Ownership is
explicit; there is no implicit close, and teardown operations are idempotent.

=head1 CONSTRUCTION

=head2 new(%opts) -> $loop

  my $loop = Linux::Event->new(
    backend => 'epoll',   # default
    clock   => $clock,    # optional; must provide tick/now_ns/etc.
    timer   => $timer,    # optional; must provide after/disarm/read_ticks/fh
  );

Options:

=over 4

=item * C<backend>

Either the string C<'epoll'> (default) or a backend object that implements
C<watch>, C<unwatch>, and C<run_once>.

=item * C<clock>

An object implementing the clock interface used by the scheduler. By default,
a monotonic clock is used.

=item * C<timer>

An object implementing the timerfd interface used by the loop. By default,
L<Linux::Event::Timer> is used.

=back

=head1 RUNNING THE LOOP

=head2 run() / run_once($timeout_seconds) / stop()

C<run()> enters the dispatch loop and continues until C<stop()> is called.

C<run_once($timeout_seconds)> runs at most one backend wait/dispatch cycle. The
timeout is in seconds; fractions are allowed.

If you need C<stop()> to reliably wake a blocking backend wait, call
C<< $loop->waker >> once during initialization. When present, C<stop()> signals
the waker to return promptly from a blocking wait.

=head1 WATCHERS

=head2 watch($fh, %spec) -> Linux::Event::Watcher

Create (or replace) a watcher for a filehandle.

Watchers are keyed internally by file descriptor (fd). Calling C<watch()> again
for the same fd replaces the existing watcher atomically.

Supported keys in C<%spec>:

=over 4

=item * C<read>  - coderef (optional)

=item * C<write> - coderef (optional)

=item * C<error> - coderef (optional). Called on C<EPOLLERR>.

=item * C<data>  - user data (optional). Stored on the watcher to avoid closure captures.

=item * C<edge_triggered> - boolean (optional, advanced). Defaults to false.

=item * C<oneshot> - boolean (optional, advanced). Defaults to false.

If true, the watcher uses C<EPOLLONESHOT>-style semantics: after an event is
delivered, the fd is disabled inside the kernel until it is re-armed. Re-arming
is typically done by forcing an epoll C<MOD> (for example by toggling
C<disable_read/enable_read> or C<disable_write/enable_write>).

=back

Handlers are invoked as:

  read  => sub ($loop, $fh, $watcher) { ... }
  write => sub ($loop, $fh, $watcher) { ... }
  error => sub ($loop, $fh, $watcher) { ... }

=head2 unwatch($fh) -> bool

Remove the watcher for C<$fh>. Returns true if a watcher was removed, false if
C<$fh> was not watched (or had no fd). Calling C<unwatch()> multiple times is safe.

=head2 Dispatch contract

When the backend reports events for a file descriptor, the loop dispatches
callbacks in this order (when applicable):

=over 4

=item 1. C<error>

=item 2. C<read>

=item 3. C<write>

=back

This order is frozen.

=head1 SIGNALS

=head2 signal($sig_or_list, $cb, %opt) -> Linux::Event::Signal::Subscription

Register a signal handler using Linux C<signalfd>.

C<$sig_or_list> may be a signal number (e.g. C<2>), a signal name (C<'INT'> or
C<'SIGINT'>), or an arrayref of those values.

Callback ABI (strict): the callback is always invoked with 4 arguments:

  sub ($loop, $sig, $count, $data) { ... }

Only one handler is stored per signal; calling C<signal()> again for the same
signal replaces the previous handler.

Options:

=over 4

=item * C<data> - arbitrary user value passed as the final callback argument.

=back

Returns a subscription handle with an idempotent C<cancel> method.

See L<Linux::Event::Signal>.

=head1 WAKEUPS

=head2 waker() -> Linux::Event::Wakeup

Returns the loop's singleton waker object (an C<eventfd(2)> handle) used to
wake the loop from another thread or process.

The waker is created lazily on first use and is never destroyed for the lifetime
of the loop.

B<Important:> when the waker is created via C<< $loop->waker >>, the loop also
installs an internal read watcher that drains the wakeup fd. This guarantees that
C<< $waker->signal >> (and C<< $loop->stop >> after waker creation) can reliably
wake a blocking backend wait (for example, C<epoll_wait>).

Because watchers are keyed by file descriptor and calling C<watch()> replaces the
existing watcher for that fd, user code MUST NOT call C<< $loop->watch($waker->fh, ...) >>.
The wakeup fd is reserved for loop wakeups and is managed internally.

See L<Linux::Event::Wakeup>.

=head1 PIDFDS

=head2 pid($pid, $cb, %opts) -> Linux::Event::Pid::Subscription

Registers a pidfd watcher for C<$pid>.

Callback ABI (strict): the callback is always invoked with 4 arguments:

  sub ($loop, $pid, $status, $data) { ... }

If C<reap =E<gt> 1> (default), the loop attempts a non-blocking reap of the PID
and passes a wait-status compatible value in C<$status>. If C<reap =E<gt> 0>,
no reap is attempted and C<$status> is C<undef>.

This is a one-shot subscription: after a defined status is observed and the
callback is invoked, the subscription is automatically canceled.

Replacement semantics apply per PID: calling C<pid()> again for the same C<$pid>
replaces the existing subscription.

See L<Linux::Event::Pid> for full semantics and caveats (child-only reaping).

=head1 TIMERS

Timers use a monotonic clock.

=head2 after($seconds, $cb) -> $id

Schedule C<$cb> to run after C<$seconds>. Fractions are allowed.

Timer callbacks are invoked as:

  sub ($loop) { ... }

=head2 at($deadline_seconds, $cb) -> $id

Schedule C<$cb> at an absolute monotonic deadline in seconds (same timebase as
the clock used by this loop). Fractions are allowed.

=head2 cancel($id) -> bool

Cancel a scheduled timer. Returns true if a timer was removed.

=head1 NOTES

=head2 Threading and forking helpers

Linux::Event intentionally does not provide C<< $loop->thread >> or
C<< $loop->fork >> helpers. Concurrency helpers are policy-layer constructs
and belong in separate distributions. The core provides primitives (C<waker>,
C<pid>) that make such helpers straightforward to implement in user code.

=head1 VERSION

This document describes Linux::Event::Loop version 0.007.

=head1 AUTHOR

Joshua S. Day

=head1 LICENSE

Same terms as Perl itself.

=head1 STABILITY

As of version 0.007, the public API and the following contracts are frozen:

=over 4

=item * I/O watcher callback ABI and dispatch order (error, then read, then write)

=item * Timer callback ABI (C<< ($loop) >>)

=item * Signal callback ABI (C<< ($loop, $sig, $count, $data) >>) and replacement semantics per signal

=item * Wakeup (waker) single-instance contract and reliable stop() wake guarantee

=item * Pid subscription callback ABI (C<< ($loop, $pid, $status, $data) >>) and replacement semantics per PID

=back

Future releases will be additive and will not change existing behavior.

=cut
