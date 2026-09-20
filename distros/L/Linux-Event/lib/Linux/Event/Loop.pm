package Linux::Event::Loop;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use Carp qw(croak);
use Scalar::Util qw(blessed);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

require Linux::Event::Loop::Introspection;
our @ISA = ('Linux::Event::Loop::Introspection');

sub add ($self, $object) {
    croak 'add(): object must support loop attachment'
        if !blessed($object) || !$object->can('_attach_to_loop');
    $object->_attach_to_loop($self);
    return $object;
}

sub CLONE_SKIP ($class) { 1 }

package Linux::Event::_Registration;
sub CLONE_SKIP ($class) { 1 }

package Linux::Event::Loop;

1;

__END__

=head1 NAME

Linux::Event::Loop - Linux-native epoll event loop

=head1 SYNOPSIS

  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Stream;

  package Client;
  use parent 'Linux::Event::IO::Sock::Stream';

  sub on_data ($self, $bytes) {
      print $bytes;
  }

  package main;
  my $loop = Linux::Event::Loop->new;
  my $connection = $loop->add(Client->connect(
      host => '127.0.0.1',
      port => 9999,
  ));
  $loop->run;

=head1 DESCRIPTION

Linux::Event::Loop owns the native epoll instance, descriptor registry, event
buffer, shared timer source, and readiness dispatch. It is the only public loop
class.

Public resource objects may be attached during construction with
C<loop =E<gt> $loop>, or constructed detached and passed to C<add>. C<add>
invokes the object's attachment implementation and returns that same object.

Ordered-byte resources may receive their application callbacks as subclass
methods or constructor coderefs. This does not change Loop attachment or
ownership; see F<docs/FIRST-CLASS-STREAM-CALLBACKS.md>.

The public resource leaves are L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>, L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Sock::Listener>, L<Linux::Event::IO::Sock::Dgram>,
L<Linux::Event::Kernel::Timer>, L<Linux::Event::Kernel::Signal>,
L<Linux::Event::Kernel::Event>, and L<Linux::Event::Kernel::Process>.
A resource rejects attachment to a second Loop or attachment after reaching a
terminal state.

C<watch> is the low-level descriptor API. It registers immediately and returns
an opaque native registration handle. The handle is not a public class or a
subclassing API.

=head1 HIGH-LEVEL OBJECTS

=head2 add($object)

Attach a detached public I/O or Kernel resource and return that exact object.
The object becomes owned by this Loop until its normal terminal lifecycle
releases it.

The following styles are equivalent:

  my $a = Client->connect(
      loop => $loop,
      host => '127.0.0.1',
      port => 9999,
  );

  my $b = $loop->add(Client->connect(
      host => '127.0.0.1',
      port => 9999,
  ));

A timer uses the same attachment contract:

  package Delay;
  use parent 'Linux::Event::Kernel::Timer';
  sub on_timer ($self) { ... }

  my $timer = $loop->add(Delay->new(after => 0.25));

The C<loop> constructor option and C<add> are both primary public APIs. Loop has
no resource-specific factory hierarchy.

=head1 RAW DESCRIPTOR API

=head2 watch(fh => $fh, read => $callback) / watch(fd => $fd, read => $callback)

Register exactly one filehandle or integer descriptor. Supported options are:

=over 4

=item * C<read>, C<write>, C<error>

Coderefs for readable, writable, and terminal/error readiness. Only C<read>
and C<write> control ordinary interest; terminal flags are always observed.
For one returned event, callback order is error, read, then write. Cancellation
after any callback suppresses the remaining callbacks for that event.

=item * C<data>

An arbitrary retained value available through C<< $registration->data >>.

=item * C<no_args =E<gt> 1>

Call readiness coderefs without an argument. By default each receives the
opaque registration handle.

=item * C<lean =E<gt> 1>

With C<no_args>, avoid retaining references used only by handle accessors.
This is an expert registration-throughput optimization.

=item * C<edge_triggered =E<gt> 1>

Use C<EPOLLET>. The callback must drain the descriptor until C<EAGAIN>.

=item * C<oneshot =E<gt> 1>

Use C<EPOLLONESHOT>. The application is responsible for its rearm policy.

=back

Registering an fd that is already registered replaces its native registration
with C<EPOLL_CTL_MOD>. Cancelling the obsolete handle cannot remove the new
registration.

=head2 watch_fd($fd, read => $callback)

Low-level positional form used by Linux::Event internals and specialized code.
It creates the same native registration and has the same dispatch path as
C<watch>. Normal application code should prefer C<watch>.

=head2 unwatch_fd($fd)

Cancel the current registration for C<$fd>, if any. Prefer the registration's
C<cancel> method when the handle is available.

=head1 REGISTRATION METHODS

The opaque result of C<watch> supports C<fd>, C<fh>, C<data>, C<loop>, C<lean>,
C<cancel>, C<enable_read>, C<disable_read>, C<enable_write>, and
C<disable_write>. C<cancel> is idempotent and makes an obsolete handle inert,
including after native watcher storage is reused. Cancellation releases the
registration's retained Perl state. An fd-only registration returns undef from
C<fh>.

=head1 DRIVING THE LOOP

=head2 poll_fd

Return the Loop-owned epoll descriptor used to integrate Linux::Event beneath
another event system. The descriptor becomes readable whenever Linux::Event has
kernel readiness pending, including its timerfd, signalfd, pidfds, eventfds,
and ordinary I/O registrations.

The returned descriptor is borrowed. Linux::Event owns it and closes it when
the Loop is destroyed; foreign adapters must not close it. An adapter that
requires a Perl filehandle may duplicate the descriptor and watch the duplicate.

Foreign loops should normally watch C<poll_fd> for level-triggered read
readiness and call C<poll> once from that readiness callback.

=head2 poll

Perform exactly one nonblocking C<epoll_wait> and dispatch the returned batch.
Returns the number of events returned by epoll. This is the supported
foreign-loop drive primitive; adapters should not depend on C<resources()> or
use C<run_once(0)> as an integration convention.

If more than C<event_capacity> events are pending, the epoll descriptor remains
readable so a level-triggered foreign loop can schedule another turn. C<poll>
does not run or stop the foreign event system. A prior C<stop> request does not
suppress C<poll>.

Like the other driver methods, C<poll> cannot recursively drive the same Loop
from one of its callbacks. An interrupted C<epoll_wait> returns zero events;
other C<epoll_wait> failures throw. Callback exceptions propagate after native
driver state is restored.

=head2 run

Wait and dispatch until C<stop> is called.

=head2 run_once($timeout_ms = -1)

Run one C<epoll_wait>. A negative timeout blocks indefinitely, zero polls, and
a positive value is a maximum wait in milliseconds. Returns the number of
events returned by epoll. A prior C<stop> request does not suppress a later
C<run_once> call.

=head2 run_for($seconds)

Run against a monotonic deadline for the supplied non-negative number of
seconds.

Only one driver method may be active for a given Loop. Calling C<poll>,
C<run>, C<run_once>, or C<run_for> recursively on that same Loop throws an
exception;
a callback may drive a different Loop. C<set_event_capacity> is likewise
rejected while its Loop is running or dispatching.

=head2 stop

Request that the active C<run> or C<run_for> return after the current dispatch
work completes.

=head1 INTROSPECTION

=head2 running

True while this Loop is inside C<poll>, C<run>, C<run_once>, or C<run_for>,
including from a callback. This is an O(1) query of native driver state.

=head2 count

Return the number of current managed public resource objects. Opaque raw
registrations and private helper objects are excluded.

=head2 has($object)

Return true only when the exact object is current in this Loop. An object owned
by another Loop, detached, or terminal returns false.

=head2 objects

Return a new array reference containing the actual current managed resource
objects. Order is unspecified. The query reads authoritative native and service
registries without maintaining a duplicate public-object registry.

=head2 inspect($object)

Return a new type-specific snapshot. Every result contains C<type>, C<class>,
and C<registered>. A supported object which is not current in this Loop returns
only those common fields with C<registered =E<gt> 0>. Current objects also
include C<state> and resource-specific fields. See F<docs/INTROSPECTION.md> for
the complete field table and the stable introspection type labels.

=head2 census

Return a new hash reference containing the documented introspection counts for
ordered-byte resources, listeners, datagrams, timers, signals, eventfd
notifications, and processes. See F<docs/INTROSPECTION.md> for exact keys.

=head2 resources

Return a native resource snapshot: epoll and timer fds, total/public/internal
registration counts, public registration fds, active timers, and current
registry, timer-heap, and event-buffer capacities. C<timer_fd> is undef until
the first L<Linux::Event::Kernel::Timer> creates the Loop's shared timer source.
This scans native state and does not create resources.

=head2 why_alive

Return an array reference of actionable user-visible liveness reasons. Managed
resource entries contain the same snapshot as C<inspect> plus the exact
C<object>. Direct raw C<watch> registrations appear as C<registration> entries
with their fd. Private backing registrations are not repeated as reasons.

=head2 pressure

Return conservative C<registrations>, C<timers>, and C<event_batch> capacity
and utilization snapshots. Event-batch maximum and utilization are undef until
an epoll wait has completed. This is implementation pressure, not a synthesized
health or latency score.

=head1 DIAGNOSTICS AND TUNING

C<stats> returns counters for epoll waits, event classes, callbacks,
registrations, timer scheduling and delivery, dispatch batching, and lifecycle
activity. C<reset_stats> resets them without changing profiling state.
C<profile($boolean)> returns the Loop and changes future nanosecond timing
collection without resetting existing statistics. Statistics remain readable
while profiling is disabled. Profiling changes the measured workload, so it
should be disabled for normal benchmarks.

C<event_capacity> returns the reusable epoll event-array capacity, default
8,192. C<set_event_capacity($capacity)> accepts an integer from 1 through
1,048,576 while the Loop is neither running nor dispatching. A larger value can
return more ready registrations from one C<epoll_wait>; it also allocates a
larger reusable array.

C<callback_scope_limit> returns the maximum callbacks sharing one bounded Perl
temporary scope, default 128. C<set_callback_scope_limit($limit)> accepts an
integer from 0 through 1,048,576. Zero uses one scope for the whole dispatch
batch; a positive value rotates the scope after that many callbacks.

C<enable_watcher_reclaim($boolean = 1)> toggles immediate watcher-structure
recycling after dispatch. It defaults off and exposes an experimental native
memory/throughput tradeoff. The measured defaults should normally remain
unchanged unless application-specific benchmarks justify tuning them.

Loop tuning uses instance methods rather than subclass policy:

  my $loop = Linux::Event::Loop->new;
  $loop->set_event_capacity(16_384);
  $loop->set_callback_scope_limit(256);
  $loop->enable_watcher_reclaim(1); # experimental

=head1 INTERPRETER OWNERSHIP

A Loop and every native object it owns belong to the Perl interpreter that
created them. They are not cloned into a new ithread. A cloned
L<Linux::Event::Kernel::Event> handle is deliberately restricted to signaling
its owner through eventfd; it cannot manage the Loop, invoke callbacks, or
access owner-interpreter data.

=head1 PLATFORM

Linux only. The implementation uses epoll directly.

=cut
