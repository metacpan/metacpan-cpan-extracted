package Linux::Event::Kernel;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

1;

__END__

=head1 NAME

Linux::Event::Kernel - Linux kernel notification and lifecycle resources

=head1 SYNOPSIS

Choose the concrete kernel resource that matches the event you need:

  use Linux::Event::Kernel::Timer;
  use Linux::Event::Kernel::Signal;
  use Linux::Event::Kernel::Event;
  use Linux::Event::Kernel::Inotify;
  use Linux::Event::Kernel::Process;

=head1 DESCRIPTION

C<Linux::Event::Kernel> is the namespace for Linux::Event resources built around
Linux kernel notification, timing, filesystem, process, and synchronization
facilities.

It is a category, not a generic kernel-event object.

Applications normally use one of the concrete classes beneath it.

=head1 TIMER

L<Linux::Event::Kernel::Timer> schedules callbacks using Linux::Event's shared
native timer scheduler.

For example:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop  => $loop,
      after => 2,

      on_timer => sub ($self) {
          say "two seconds passed";
      },
  );

Timers support:

  one-shot delays
  absolute monotonic deadlines
  recurring intervals

A Loop does not create one timerfd for every Timer object.

Linux::Event uses one scheduler timerfd and a native timer heap for the Loop.

=head1 SIGNAL

L<Linux::Event::Kernel::Signal> subscribes to Unix signals through Linux
C<signalfd>.

For example:

  my $signal = Linux::Event::Kernel::Signal->new(
      loop    => $loop,
      signals => ['INT', 'TERM'],

      on_signal => sub ($self, $number, $count) {
          ...
      },
  );

Linux::Event delivers signal notifications through the event loop rather than
ordinary asynchronous Perl signal handlers.

The Signal resource also preserves process signal-mask ownership so it does not
blindly undo masking that belonged to application code before the subscription
was created.

=head1 EVENT

L<Linux::Event::Kernel::Event> provides an explicit event-loop notification
mechanism backed by Linux C<eventfd>.

For example:

  my $event = Linux::Event::Kernel::Event->new(
      loop => $loop,

      on_event => sub ($self, $count) {
          say "notification count: $count";
      },
  );

Another execution context can signal it with:

  $event->signal;

or add several notification units at once:

  $event->signal(5);

The eventfd counter allows several notifications to accumulate without reducing
them to one boolean wakeup.

Event is a notification mechanism, not a payload queue.

A common design is:

  shared queue or other state
      +
  Event notification

The producer publishes the payload first, then signals the Event.

=head1 INOTIFY

L<Linux::Event::Kernel::Inotify> monitors filesystem changes using Linux
C<inotify>.

For example:

  my $inotify = Linux::Event::Kernel::Inotify->new(
      loop => $loop,
  );

  my $watch = $inotify->watch(
      'log.txt',

      on_modify => sub ($event) {
          say $event->path . " changed";
      },
  );

The parent Inotify object owns the kernel inotify source.

Each call to C<watch> returns a logical
L<Linux::Event::Kernel::Inotify::Watch> subscription.

Filesystem records are represented by
L<Linux::Event::Kernel::Inotify::Event> values.

Several logical subscriptions can safely share one underlying kernel watch when
appropriate.

=head1 PROCESS

L<Linux::Event::Kernel::Process> manages process lifecycle and asynchronous
subprocess I/O.

For example:

  my $process = Linux::Event::Kernel::Process->new(
      loop    => $loop,
      command => ['/usr/bin/sort'],
      stdin   => 'pipe',
      stdout  => 'pipe',

      on_stdout => sub ($self, $bytes) {
          print $bytes;
      },

      on_exit => sub ($self, $status) {
          ...
      },
  );

Process uses Linux process facilities such as C<pidfd> for identity and
lifecycle observation.

When pipes are requested, Linux::Event also manages the subprocess's standard
I/O asynchronously.

A Process can either spawn a child or observe an existing PID, depending on how
it is constructed.

=head1 IO AND KERNEL ARE DIFFERENT CATEGORIES

C<Linux::Event::Kernel> contains resources whose primary purpose is kernel
notification, timing, synchronization, filesystem observation, or process
lifecycle.

Application data I/O resources instead live below L<Linux::Event::IO>.

For example:

  Linux::Event::IO::Pipe
  Linux::Event::IO::TTY
  Linux::Event::IO::Sock::Stream
  Linux::Event::IO::Sock::Listener
  Linux::Event::IO::Sock::Dgram

The distinction is organizational.

Both categories attach to the same L<Linux::Event::Loop> and participate in the
same epoll-driven event system.

=head1 CALLBACKS AND SUBCLASSES

Kernel resources use constructor callbacks where appropriate.

For example:

  my $timer = Linux::Event::Kernel::Timer->new(
      after => 1,

      on_timer => sub ($self) {
          ...
      },
  );

Reusable behavior can instead be placed in subclasses:

  package Heartbeat;

  use parent 'Linux::Event::Kernel::Timer';

  sub on_timer ($self) {
      ...
  }

When both forms are supported, a constructor callback overrides the
corresponding subclass callback for that object.

Inotify is slightly different because filesystem event callbacks belong to each
logical Watch rather than to a subclass of the parent source.

=head1 LOOP ATTACHMENT

Kernel resources generally follow the normal Linux::Event attachment model.

They may be constructed already attached:

  loop => $loop

or constructed detached and added later:

  my $timer = Linux::Event::Kernel::Timer->new(
      after => 1,
      on_timer => sub ($self) {
          ...
      },
  );

  $loop->add($timer);

The concrete resource documentation describes any special activation or
lifecycle rules.

For example, an Inotify parent does not create its kernel inotify descriptor
until it is attached to a Loop.

=head1 CANCELLATION AND TERMINAL STATE

Many kernel resources provide explicit cancellation or closing operations.

For example:

  $timer->cancel;
  $signal->cancel;
  $event->cancel;
  $watch->cancel;
  $inotify->close;

The exact terminal states differ by resource.

Applications should use the concrete resource's documented lifecycle rather than
assuming every kernel object has the same close or cancel method.

=head1 FORK BEHAVIOR IS RESOURCE-SPECIFIC

Linux::Event's managed fork support does not treat every kernel resource the
same way.

The correct disposition depends on the underlying Linux facility.

For example:

=over 4

=item *

Timer supports C<clone> and C<move>.

=item *

Inotify supports C<clone> and C<move>.

=item *

Signal, Event, and Process are currently child-drop resources in managed fork.

=back

The Loop itself is always recreated independently in the child.

No parent and child Linux::Event::Loop objects share one epoll instance.

See L<Linux::Event::Loop> and each concrete resource for the full managed-fork
contract.

=head1 THERE IS NO GENERIC KERNEL OBJECT

This is not a public construction API:

  Linux::Event::Kernel->new(...);

Choose the resource that corresponds to the kernel facility or lifecycle you
need.

Use:

  Linux::Event::Kernel::Timer

for scheduled time.

Use:

  Linux::Event::Kernel::Signal

for Unix signal delivery.

Use:

  Linux::Event::Kernel::Event

for explicit eventfd-backed notification.

Use:

  Linux::Event::Kernel::Inotify

for filesystem observation.

Use:

  Linux::Event::Kernel::Process

for subprocess or PID lifecycle management.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO>,
L<Linux::Event::Kernel::Timer>,
L<Linux::Event::Kernel::Signal>,
L<Linux::Event::Kernel::Event>,
L<Linux::Event::Kernel::Inotify>,
L<Linux::Event::Kernel::Inotify::Watch>,
L<Linux::Event::Kernel::Inotify::Event>,
L<Linux::Event::Kernel::Process>.

=cut
