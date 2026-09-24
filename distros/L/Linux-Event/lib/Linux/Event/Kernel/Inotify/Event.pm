package Linux::Event::Kernel::Inotify::Event;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use File::Spec ();

use constant IN_ISDIR => 0x40000000;

sub _new ($class, $watch, $name, $mask, $cookie) {
    my $path = defined($name) && length($name)
        ? File::Spec->catfile($watch->path, $name)
        : $watch->path;
    return bless {
        watch  => $watch,
        name   => $name,
        path   => $path,
        mask   => $mask,
        cookie => $cookie,
    }, $class;
}

sub watch ($self) { $self->{watch} }
sub name ($self) { $self->{name} }
sub path ($self) { $self->{path} }
sub mask ($self) { $self->{mask} }
sub cookie ($self) { $self->{cookie} }
sub is_directory ($self) { !!($self->{mask} & IN_ISDIR) }

1;

__END__

=head1 NAME

Linux::Event::Kernel::Inotify::Event - Describe one filesystem notification

=head1 SYNOPSIS

  on_create => sub ($event) {
      say "created: " . $event->path;

      if ($event->is_directory) {
          say "it is a directory";
      }
  }

=head1 DESCRIPTION

C<Linux::Event::Kernel::Inotify::Event> is the value object passed to Inotify
watch callbacks.

Applications do not construct Event objects directly.

Linux::Event creates one when the kernel reports a filesystem notification.

For example:

  my $watch = $inotify->watch(
      '/srv/uploads',

      on_create => sub ($event) {
          say $event->path;
      },
  );

The Event tells the callback:

=over 4

=item *

which logical Watch received the notification

=item *

which child name Linux reported, when applicable

=item *

the useful full path

=item *

the raw Linux event mask

=item *

the rename or move cookie

=item *

whether the event refers to a directory

=back

=head1 THE SAME EVENT MAY REACH SEVERAL CALLBACKS

One Linux inotify record may contain several matching event bits.

For one logical Watch, Linux::Event creates one Event object for that record and
passes the same object to each matching specific callback.

For example:

  my $watch = $inotify->watch(
      '/srv/data',

      on_modify => sub ($event) {
          ...
      },

      on_event => sub ($event) {
          ...
      },
  );

If one record matches C<on_modify>, the same Event object is first passed to
C<on_modify> and then to C<on_event>.

=head1 WATCH

=head2 watch

  my $watch = $event->watch;

Return the L<Linux::Event::Kernel::Inotify::Watch> that received this event.

This is useful when one callback is shared by several Watches:

  my $callback = sub ($event) {
      say "watching: " . $event->watch->path;
      say "event:    " . $event->path;
  };

=head1 CHILD NAME

=head2 name

  my $name = $event->name;

Return the optional child name supplied by Linux.

For events on entries inside a watched directory, this is typically the
directory entry name.

For example, if the Watch is:

  /srv/uploads

and Linux reports activity for:

  photo.jpg

then:

  $event->name

returns:

  photo.jpg

For events concerning the watched object itself, there may be no child name.

=head1 PATH

=head2 path

  my $path = $event->path;

Return the useful composed path for the event.

When Linux supplies a child name, C<path> combines the Watch path and that name.

For example:

  watch path:  /srv/uploads
  event name:  photo.jpg
  event path:  /srv/uploads/photo.jpg

When Linux supplies no child name, C<path> is simply the original Watch path.

This is usually the most convenient Event method for application code.

=head1 MASK

=head2 mask

  my $mask = $event->mask;

Return the raw Linux inotify mask for this kernel record.

Most applications should prefer the named callbacks such as:

  on_create
  on_modify
  on_delete
  on_moved_from
  on_moved_to

instead of decoding the raw mask themselves.

C<mask> is available for applications that need lower-level Linux event
information or diagnostic output.

For example:

  on_event => sub ($event) {
      say "mask=" . $event->mask;
  }

=head1 MOVE AND RENAME COOKIE

=head2 cookie

  my $cookie = $event->cookie;

Return the Linux inotify cookie associated with this record.

The cookie is primarily useful for pairing related move or rename events.

For example:

  on_moved_from => sub ($event) {
      remember_old_name(
          $event->cookie,
          $event->path,
      );
  }

  on_moved_to => sub ($event) {
      complete_rename(
          $event->cookie,
          $event->path,
      );
  }

Linux commonly gives the related C<IN_MOVED_FROM> and C<IN_MOVED_TO> records the
same nonzero cookie.

Applications that do not need to correlate renames can usually ignore this
field.

=head1 DIRECTORY FLAG

=head2 is_directory

  if ($event->is_directory) {
      ...
  }

Return true when the Linux event mask contains C<IN_ISDIR>.

For example:

  on_create => sub ($event) {
      if ($event->is_directory) {
          say "directory created: " . $event->path;
      }
      else {
          say "file created: " . $event->path;
      }
  }

This reports what Linux marked on the event.

It does not perform a new filesystem C<stat> call.

=head1 EVENT VALUES ARE SNAPSHOTS

An Event describes the notification that Linux delivered at that moment.

The filesystem may change again immediately afterward.

For example, by the time this callback runs:

  on_create => sub ($event) {
      ...
  }

the path could already have been renamed or deleted by another process.

Therefore the Event should be treated as a record of what Linux reported, not
as a guarantee that the path still has the same current filesystem state.

Applications that need current metadata should query the filesystem separately.

=head1 EVENT OBJECTS DO NOT CONTROL THE WATCH

An Event is descriptive.

Lifecycle operations belong to the Watch or parent Inotify object.

To cancel the logical subscription from a callback:

  on_modify => sub ($event) {
      $event->watch->cancel;
  }

To close the whole inotify service:

  on_modify => sub ($event) {
      $event->watch->inotify->close;
  }

=head1 IMMUTABILITY

The public Event API provides only readers:

  watch
  name
  path
  mask
  cookie
  is_directory

There are no public setters.

An Event represents one already-observed kernel notification and is intended to
be treated as an immutable value.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::Kernel::Inotify>,
L<Linux::Event::Kernel::Inotify::Watch>.

=cut
