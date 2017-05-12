package Linux::Inotify;
our $VERSION = '0.05';

=pod

=head1 NAME

Linux::Inotify - Classes for supporting inotify in Linux Kernel >= 2.6.13

=head1 SYNOPSIS

Linux::Inotify supports the new inotify interface of Linux which is a
replacement of dnotify. Beside the class Linux::Inotify there two helper
classes -- Linux::Inotify::Watch and Linux::Inotify::Event.

=head1 DESCRIPTION

=head2 class Linux::Inotify

The following code

   use Linux::Inotify;
   my $notifier = Linux::Inotify->new();

returns a new notifier.

   my $watch = $notifier->add_watch('filename', Linux::Inotify::MASK);

adds a watch to filename (see below), where MASK is one of ACCESS, MODIFY,
ATTRIB, CLOSE_WRITE, CLOSE_NOWRITE, OPEN, MOVED_FROM, MOVED_TO, CREATE, DELETE,
DELETE_SELF, UNMOUNT, Q_OVERFLOW, IGNORED, ISDIR, ONESHOT, CLOSE, MOVE or
ALL_EVENTS.

   my @events = $notifier->read();

reads and decodes all available data and returns an array of
Linux::Inotify::Event objects (see below).

   $notifier->close();

destroys the notifier and closes the associated file descriptor.

=head2 class Linux::Inotify::Watch

The constructor new is usually not called directly but via the add_watch method
of the notifier. An alternative contructor

   my $watch_clone = $watch->clone('filename');

creates an new watch for filename but shares the same $notifier and MASK. This
is indirectly used for recursing into subdirectories (see below). The
destructor

   $watch->remove()

destroys the watch safely. It does not matter if the kernel has already removed
the watch itself, which may happen when the watched object has been deleted.
   
=head2 class Linux::Inotify::Event

The constructor is not called directly but through the read method of
Linux::Inotify that returns an array of event objects.  An
Linux::Inotify::Event object has some interesting data members: mask, cookie
and name. The method

   $event->fullname();

returns the full name of the file or directory not only the name relative to
the watch like the name member does contain.

   $event->print();

prints the event to stdout in a human readable form.

   my $new_watch = $event->add_watch();

creates a new watch for the file/directory of the event and shares the notifier
and MASK of the original watch, that has generated the event. That is useful
for recursing into subdirectories.


=head1 AUTHOR

Copyright 2005 by Torsten Werner <twerner@debian.org>. The code is licensed
under the same license as perl: L<perlgpl> or L<perlartistic>.

=cut


use strict;
use warnings;
use Carp;
use POSIX;
use Config;

my %syscall_init = (
   alpha     => 444,
   arm       => 316,
   i386      => 291,
   ia64      => 1277,
   powerpc   => 275,
   powerpc64 => 275,
   s390      => 284,
   sh        => 290,
   sparc     => 151,
   sparc_64  => 151,
   x86_64    => 253,
);
my ($arch) = ($Config{archname} =~ m{([^-]+)-});
die "unsupported architecture: $arch\n" unless exists $syscall_init{$arch};

sub syscall_init {
   syscall $syscall_init{$arch};
}

sub syscall_add_watch {
   syscall $syscall_init{$arch} + 1, @_;
}

sub syscall_rm_watch {
   unless ($arch =~ m{sparc}) {
      syscall $syscall_init{$arch} + 2, @_;
   }
   else {
      # that's my favourite syscall:
      syscall $syscall_init{$arch} + 5, @_;
   }
}

sub new($) {
   my $class = shift;
   my $self = {
      fd => syscall_init
   };
   croak "Linux::Inotify::init() failed: $!" if $self->{fd} == -1;
   return bless $self, $class;
}

sub add_watch($$$) {
   my $self = shift;
   use Linux::Inotify::Watch;
   my $watch = Linux::Inotify::Watch->new($self, @_);
   $self->{wd}->{$watch->{wd}} = $watch;
   return $watch;
}

sub find($$) {
   my $self = shift;
   my $wd = shift;
   return $self->{wd}->{$wd};
}

sub close($) {
   my $self = shift;
   for my $watch (values %{$self->{wd}}) {
      $watch->remove;
   }
   my $ret = POSIX::close($self->{fd});
   croak "Linux::Inotify::close() failed: $!" unless defined $ret;
}

use constant {
   ACCESS        => 0x00000001,
   MODIFY        => 0x00000002,
   ATTRIB        => 0x00000004,
   CLOSE_WRITE   => 0x00000008,
   CLOSE_NOWRITE => 0x00000010,
   OPEN          => 0x00000020,
   MOVED_FROM    => 0x00000040,
   MOVED_TO      => 0x00000080,
   CREATE        => 0x00000100,
   DELETE        => 0x00000200,
   DELETE_SELF   => 0x00000400,
   UNMOUNT       => 0x00002000,
   Q_OVERFLOW    => 0x00004000,
   IGNORED       => 0x00008000,
   ISDIR         => 0x40000000,
   ONESHOT       => 0x80000000,
   CLOSE         => 0x00000018,
   MOVE          => 0x000000c0,
   ALL_EVENTS    => 0x00000fff
};

sub read($) {
   my $self = shift;
   my $bytes = POSIX::read($self->{fd}, my $raw_events, 65536);
   croak "Linux::Inotify::read: read only $bytes bytes: $!" if $bytes < 16;
   my @all_events;
   do {
      use Linux::Inotify::Event;
      my $event = Linux::Inotify::Event->new($self, $raw_events);
      push @all_events, $event;
      $raw_events = substr($raw_events, 16 + $event->{len});
   } while(length $raw_events >= 16);
   return @all_events;
}

1;

