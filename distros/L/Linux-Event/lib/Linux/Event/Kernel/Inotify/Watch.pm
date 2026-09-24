package Linux::Event::Kernel::Inotify::Watch;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Scalar::Util qw(weaken);

sub _new ($class, $parent, $id, $path, $event_mask, $callback, $flag) {
    my $self = bless {
        parent     => $parent,
        id         => $id,
        path       => $path,
        event_mask => $event_mask,
        callbacks  => $callback,
        flags      => $flag,
        wd         => undef,
        state      => 'pending',
    }, $class;
    weaken($self->{parent});
    return $self;
}

sub cancel ($self) {
    return $self if $self->is_terminal;
    my $parent = $self->{parent};
    return $parent->_cancel_watch($self) if $parent;
    $self->_terminate('cancelled');
    return $self;
}

sub path ($self) { $self->{path} }
sub inotify ($self) { $self->{parent} }
sub state ($self) { $self->{state} }
sub is_active ($self) { $self->{state} eq 'active' }
sub is_terminal ($self) {
    return $self->{state} ne 'pending' && $self->{state} ne 'active';
}

sub _id ($self) { $self->{id} }
sub _wd ($self) { $self->{wd} }
sub _event_mask ($self) { $self->{event_mask} }
sub _callback ($self, $name) { $self->{callbacks}{$name} }
sub _flag ($self, $name) { $self->{flags}{$name} ? 1 : 0 }

sub _activate ($self, $wd) {
    $self->{wd} = $wd;
    $self->{state} = 'active';
    return $self;
}

sub _reset_pending ($self) {
    $self->{wd} = undef;
    $self->{state} = 'pending';
    return $self;
}

sub _terminate ($self, $state) {
    $self->{wd} = undef;
    $self->{state} = $state;
    $self->{callbacks} = {};
    return $self;
}

1;

__END__

=head1 NAME

Linux::Event::Kernel::Inotify::Watch - One filesystem watch owned by an Inotify object

=head1 SYNOPSIS

  use Linux::Event::Loop;
  use Linux::Event::Kernel::Inotify;

  my $loop = Linux::Event::Loop->new;
  my $inotify = Linux::Event::Kernel::Inotify->new;

  my $watch = $inotify->watch(
      '/srv/data',

      on_modify => sub ($event) {
          say $event->path . ' changed';
      },
  );

  $loop->add($inotify);
  $loop->run_for(10);

  $watch->cancel;

=head1 DESCRIPTION

C<Linux::Event::Kernel::Inotify::Watch> represents one logical filesystem
subscription created by:

  $inotify->watch(...)

Applications do not normally construct Watch objects directly.

The parent L<Linux::Event::Kernel::Inotify> object owns the Linux inotify
instance.

Each Watch represents one application-level subscription within that parent.

For example:

  my $first = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          log_change($event->path);
      },
  );

  my $second = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          $changes++;
      },
  );

C<$first> and C<$second> are separate logical Watches even if Linux can
represent both through one underlying kernel watch descriptor.

Each can be cancelled independently.

=head1 WATCH CREATION

Watch objects are returned by the parent:

  my $watch = $inotify->watch(
      $path,
      on_modify => sub ($event) {
          ...
      },
  );

See L<Linux::Event::Kernel::Inotify> for the supported filesystem callbacks and
watch options.

=head1 PENDING AND ACTIVE WATCHES

If the parent Inotify object is detached when C<watch> is called:

  my $inotify = Linux::Event::Kernel::Inotify->new;

  my $watch = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          ...
      },
  );

the Watch begins in the C<pending> state.

The logical subscription has been recorded, but the kernel watch does not yet
exist.

When the parent is attached:

  $loop->add($inotify);

the Watch becomes active.

If the parent is already active when C<watch> is called, the new Watch is
activated before C<watch> returns successfully.

=head1 CANCELLING A WATCH

=head2 cancel

  $watch->cancel;

Cancel this logical filesystem subscription.

Cancellation is immediate and terminal.

After C<cancel> returns, no later callback is delivered to that Watch.

This includes an C<IN_IGNORED> notification caused by Linux removing the
underlying kernel watch.

C<cancel> returns the Watch object.

Calling it again is harmless.

=head1 CANCELLING ONE OF SEVERAL WATCHES

Several logical Watches may refer to the same underlying filesystem object.

For example:

  my $logger = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          log_change($event->path);
      },
  );

  my $counter = $inotify->watch(
      '/srv/data',
      on_modify => sub ($event) {
          $modified++;
      },
  );

Cancelling:

  $logger->cancel;

does not cancel C<$counter>.

Linux::Event updates the shared kernel subscription as necessary to preserve
the events still required by surviving Watches.

=head1 PATH

=head2 path

  my $path = $watch->path;

Return the absolute path captured when the Watch was created.

Relative input paths are converted to absolute paths by the parent
C<watch> method.

Therefore:

  my $watch = $inotify->watch(
      'log.txt',
      on_modify => sub ($event) {
          ...
      },
  );

  chdir '/tmp';

does not change what C<< $watch->path >> refers to.

=head1 PARENT INOTIFY OBJECT

=head2 inotify

  my $inotify = $watch->inotify;

Return the parent L<Linux::Event::Kernel::Inotify> object while that object
still exists.

This can also be reached from an event callback:

  on_modify => sub ($event) {
      my $watch   = $event->watch;
      my $inotify = $watch->inotify;
  }

The parent relationship is weak internally, so a Watch does not keep an
otherwise unused parent Inotify object alive by itself.

=head1 STATE

=head2 state

  my $state = $watch->state;

A Watch can pass through several states.

=head2 pending

C<pending> means the Watch has been configured on a detached Inotify parent but
has not yet been installed in the kernel.

=head2 active

C<active> means the Watch is currently able to receive filesystem events.

=head2 cancelled

C<cancelled> means the application explicitly called C<cancel>.

=head2 ignored

C<ignored> means Linux invalidated the underlying kernel watch.

=head2 closed

C<closed> means the parent Inotify object was closed.

=head2 failed

C<failed> means activation of a Watch on an already-active parent failed.

Managed-fork handling can also produce terminal states such as
C<not_inherited> and C<moved>.

=head1 IS THE WATCH ACTIVE?

=head2 is_active

  if ($watch->is_active) {
      ...
  }

Return true only while the Watch state is C<active>.

A C<pending> Watch is not yet active.

=head1 IS THE WATCH TERMINAL?

=head2 is_terminal

  if ($watch->is_terminal) {
      ...
  }

Return false for C<pending> and C<active>.

Return true for terminal states such as:

  cancelled
  ignored
  closed
  failed
  not_inherited
  moved

A terminal Watch cannot later be reactivated.

=head1 WATCH EVENTS

Filesystem callbacks receive a
L<Linux::Event::Kernel::Inotify::Event> rather than the Watch directly:

  my $watch = $inotify->watch(
      '/srv/data',

      on_modify => sub ($event) {
          say $event->path;
      },
  );

The Event identifies the Watch that received it:

  my $watch = $event->watch;

This is particularly useful when the same callback is shared by several
Watches.

=head1 PARENT CLOSE

Closing the parent:

  $inotify->close;

makes all of its remaining Watch objects terminal.

No callbacks are delivered to them afterward.

The Watch state becomes C<closed> unless another terminal lifecycle state was
already established.

=head1 LOOP-AWARE FORKING

Watch lifecycle follows the disposition of its parent
L<Linux::Event::Kernel::Inotify> object.

If the parent is cloned:

  my $pid = $loop->fork(
      clone => [$inotify],
  );

the child recreates an independent Inotify instance and corresponding active
Watch subscriptions.

If the parent is moved:

  my $pid = $loop->fork(
      move => [$inotify],
  );

the parent-side Watch becomes terminal with state C<moved> after the move
commits.

If the parent is omitted from the managed-fork disposition lists, the child
copy becomes terminal with state C<not_inherited>.

Watch objects are not listed separately in C<Loop-E<gt>fork> disposition
arrays; their lifecycle belongs to the parent Inotify resource.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::Kernel::Inotify>,
L<Linux::Event::Kernel::Inotify::Event>.

=cut
