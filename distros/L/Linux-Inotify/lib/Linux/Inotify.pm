package Linux::Inotify;

use strict;
use warnings;
use Carp;
use POSIX;
use Config;

# ABSTRACT: Classes for supporting inotify in Linux Kernel >= 2.6.13
our $VERSION = '0.06'; # VERSION


use constant ACCESS        => 0x00000001;
use constant MODIFY        => 0x00000002;
use constant ATTRIB        => 0x00000004;
use constant CLOSE_WRITE   => 0x00000008;
use constant CLOSE_NOWRITE => 0x00000010;
use constant OPEN          => 0x00000020;
use constant MOVED_FROM    => 0x00000040;
use constant MOVED_TO      => 0x00000080;
use constant CREATE        => 0x00000100;
use constant DELETE        => 0x00000200;
use constant DELETE_SELF   => 0x00000400;
use constant UNMOUNT       => 0x00002000;
use constant Q_OVERFLOW    => 0x00004000;
use constant IGNORED       => 0x00008000;
use constant ISDIR         => 0x40000000;
use constant ONESHOT       => 0x80000000;
use constant CLOSE         => 0x00000018;
use constant MOVE          => 0x000000c0;
use constant ALL_EVENTS    => 0x00000fff;

sub _arch_config {
   my ($arch) = ($Config{archname} =~ m{([^-]+)-});
   return (253,254,255)      if $arch eq 'x86_64';
   return (26, 27, 28, 0)    if $arch eq 'aarch64';
   return (151, 152, 156)    if $arch =~ /^sparc(_64|)\z/;
   return (444, 445, 446)    if $arch eq 'alpha';
   return (291, 292, 293)    if $arch =~ /^i[3456]86\z/;
   return (1277, 1278, 1279) if $arch eq 'ia64';
   return (275, 276, 277)    if $arch =~ /^powerpc(|64)\z/;
   return (284, 285, 296)    if $arch eq 's390';
   die "do not know syscalls for inotify on $arch";
}

sub syscall_init;
sub syscall_add_watch;
sub syscall_rm_watch;

if(my($init, $add, $remove, @init_args) = _arch_config()) {
   if(@init_args) {
       *syscall_init = sub { syscall $init, 0 };
   } else {
       *syscall_init = sub { syscall $init };
   }
   *syscall_add_watch = sub { syscall $add,    @_ };
   *syscall_rm_watch  = sub { syscall $remove, @_ };
}

sub new {
   my $class = shift;
   my $fd = syscall_init();
   croak "Linux::Inotify::init() failed: $!" if $fd == -1;
   return bless { fd => $fd }, $class;
}

sub add_watch {
   my $self = shift;
   require Linux::Inotify::Watch;
   my $watch = Linux::Inotify::Watch->new($self, @_);
   $self->{wd}->{$watch->{wd}} = $watch;
   return $watch;
}

sub find {
   my $self = shift;
   my $wd = shift;
   return $self->{wd}->{$wd};
}

sub close {
   my $self = shift;
   for my $watch (values %{$self->{wd}}) {
      $watch->remove;
   }
   my $ret = POSIX::close($self->{fd});
   croak "Linux::Inotify::close() failed: $!" unless defined $ret;
}

sub read {
   my $self = shift;
   my $bytes = POSIX::read($self->{fd}, my $raw_events, 65536);
   croak "Linux::Inotify::read: read only $bytes bytes: $!" if $bytes < 16;
   my @all_events;
   do {
      require Linux::Inotify::Event;
      my $event = Linux::Inotify::Event->new($self, $raw_events);
      push @all_events, $event;
      $raw_events = substr($raw_events, 16 + $event->{len});
   } while(length $raw_events >= 16);
   return @all_events;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Inotify - Classes for supporting inotify in Linux Kernel >= 2.6.13

=head1 VERSION

version 0.06

=head1 DESCRIPTION

Linux::Inotify supports the new inotify interface of Linux which is a
replacement of dnotify. Beside the class Linux::Inotify there two helper
classes -- Linux::Inotify::Watch and Linux::Inotify::Event.

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
of the notifier. An alternative constructor.

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

Original author: Torsten Werner

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Torsten Werner <twerner@debian.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
