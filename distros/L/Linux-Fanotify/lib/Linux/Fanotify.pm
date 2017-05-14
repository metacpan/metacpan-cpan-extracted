# Copyright (c) 2014 Collax GmbH
package Linux::Fanotify;

use 5.006001;
use strict;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = (
        consts  => [qw(
		FAN_ACCESS
		FAN_MODIFY
		FAN_CLOSE_WRITE
		FAN_CLOSE_NOWRITE
		FAN_OPEN

		FAN_Q_OVERFLOW

		FAN_OPEN_PERM
		FAN_ACCESS_PERM

		FAN_ONDIR

		FAN_EVENT_ON_CHILD

		FAN_CLOSE

		FAN_CLOEXEC
		FAN_NONBLOCK

		FAN_CLASS_NOTIF
		FAN_CLASS_CONTENT
		FAN_CLASS_PRE_CONTENT
		FAN_ALL_CLASS_BITS

		FAN_UNLIMITED_QUEUE
		FAN_UNLIMITED_MARKS

		FAN_ALL_INIT_FLAGS

		FAN_MARK_ADD
		FAN_MARK_REMOVE
		FAN_MARK_DONT_FOLLOW
		FAN_MARK_ONLYDIR
		FAN_MARK_MOUNT
		FAN_MARK_IGNORED_MASK
		FAN_MARK_IGNORED_SURV_MODIFY
		FAN_MARK_FLUSH

		FAN_ALL_MARK_FLAGS

		FAN_ALL_EVENTS

		FAN_ALL_PERM_EVENTS

		FAN_ALL_OUTGOING_EVENTS

		FANOTIFY_METADATA_VERSION

		FAN_ALLOW
		FAN_DENY
		FAN_NOFD
	)],
	funcs => [qw(
		fanotify_init
		fanotify_mark
		fanotify_read
		fanotify_write
	)],
);

our @EXPORT_OK = map {@{$_}} values %EXPORT_TAGS;

bootstrap Linux::Fanotify;

################################################################################

our $default_response = -1;

sub init {
	my $class = shift;
	return fanotify_init(@_);
}

package Linux::Fanotify::FanotifyGroup;

our $autoclose = 1;

sub new {
	my $class = shift;
	return Linux::Fanotify::fanotify_init(@_);
}

sub mark {
	return Linux::Fanotify::fanotify_mark(@_);
}

sub read {
	return Linux::Fanotify::fanotify_read(@_);
}

package Linux::Fanotify::Event;

our $autoclose = 1;

use overload '""' => sub { my $self = shift; return $self->_stringify(); };

1;

__END__

=head1 NAME

Linux::Fanotify - Perl interface to the Linux fanotify API

=head1 VERSION

Version 1.1.1

=cut

our $VERSION = '1.1.1';

=head1 SYNOPSIS

    use Linux::Fanotify qw(:consts);
    use Fcntl;	# Provides O_* constants required for fanotify_init

    my $fanogrp = new Linux::Fanotify::FanotifyGroup(
	FAN_CLOEXEC | FAN_CLASS_CONTENT,
	O_RDONLY | O_LARGEFILE
    ) || die("Could not initialize fanotify: $!");

    $fanogrp->mark(
	FAN_MARK_ADD | FAN_MARK_MOUNT, FAN_OPEN_PERM | FAN_CLOSE_WRITE, -1, $path
    ) || die("Could not mark $path: $!\n");

    while (1) {
	my @events = $fanogrp->read();
	foreach my $e (@events) {
	    if ($e->needsResponse()) {
	        print("Allowing a request:\n$e\n");
	    	$e->allow();
	    }
	}
    }

=head1 DESCRIPTION

The fanotify API is a filesystem monitoring interface in the Linux kernel. It
is intended to be used by file scanners such as virus and malware scanners
or file indexers.

fanotify has been part of the Linux kernel since 2.6.37 (but needs to be
enabled in the kernel configuration).

This perl module provides a Perl binding for that API. The low level
functions fanotify_init and fanotify_mark are available similarly to the
original C functions, but provide a more abstract interface for easier usage
in perl programs.

Linux::Fanotify provides a functional as well as an object oriented interface.
The latter is the recommended way of interacting with the module.

=head1 fanotify basics

The fanotify kernel API provides two basic functions, plus a file (descriptor)
based interface from which events can be read, and which is used to respond
to such events.

The C<fanotify_init()> call is used to "connect" the kernel, which responds
with creating a notification group (also: fanotify event group, ...).
Notification groups can then be used to C<fanotify_mark()> file system
objects, most prominently mount points, directories, or files. During
marking, the type of requested events can be determined. This can be
either a simple notification about operations, or a request for permission.

After marking such objects, a program can read from the notification group
file descriptor to receive events; in case of permission requests, a
response needs to be written to the notification group.

As of today (mid 2014), the fanotify man pages have not yet made their
way into the distributions, so please consult the
L<Linux man pages project|https://www.kernel.org/doc/man-pages/>
instead. The relevant pages are fanotify(7), fanotify_init(2), and
fanotify_mark(2). Please note that man pages prior to version 3.68,
released 2014-05-28, are incorrect.

=head1 About this module

This module's interface closely resembles the low level functionality. The
fanotify functions can directly be accessed (although the OO interface
is recommended).

The return values of the offered functions and methods are perl
style (in case of error, 0 or undef is returned) rather than C style
(where 0 is returned in case of success).

Calling fanotify_init requires the CAP_SYS_ADMIN capability ("you need root",
except that you don't).

=head1 Object oriented interface

=head2 Package C<Linux::Fanotify>

=head3 Package-global variable C<$Linux::Fanotify::default_response>

This package-global variable triggers a default response for permission
events in case no explicit response has been issued.

The variable can contain a value of C<FAN_ALLOW>, C<FAN_DENY>, C<-1>,
C<0>, or any other integer. Its default is C<-1>.

Due to its system related nature, the fanotify API is good for all kinds of
mess. When events are "lost" without properly responding to them, consecutive
events can no longer properly answered (responses will allow/deny older
events, rather than the ones they were intended to). I cannot imagine any
case where one would want to trigger such a behavior intentionally, so its
best to leave this variable untouched, and C<Linux::Fanotify> will take care
of not leaking any file descriptors, and answering them with a sensible
default just in case.

However, if you intend to shoot yourself in the foot, you can set this
variable to 0. This will result in not automatically responding to events
being manually closed or going out of scope.

The default C<-1> results in C<Linux::Fanotify> choosing its own default,
currently C<FAN_DENY>.

=head3 Class method C<init($flags, $event_f_flags)>

Identical to the
L<Linux::Fanotify::FanotifyGroup|/"Package C<Linux::Fanotify::FanotifyGroup>">
constructor. See the documentation below.

=head2 Package C<Linux::Fanotify::FanotifyGroup>

=head3 Package-global variable C<$Linux::Fanotify::FanotifyGroup::autoclose>

This variable defaults to 1 and results in the fanotify group being closed when
objects of this type are destroyed (e.g. by going out of scope).

This almost definitely is what you want. However, if you use multithreading
or similar wizardry, passing around objects may result in destruction of
copies of this object and subsequent, wrongly closing of the notification
group.

Take care when setting this to 0 (or undef).

=head3 Constructor C<new($flags, $event_f_flags)>

Constructs and returns a new C<Linux::Fanotify::FanotifyGroup> object.

Please consult the
L<aforementioned man pages|http://man7.org/linux/man-pages/man2/fanotify_init.2.html>
for information on C<$flags> and C<$event_f_flags>.

Returns C<undef> in case of error; consult L<perlvar/"$!"> in this case.

=head3 Object method C<mark($flags, $mask, $dirfd, $pathname)>

Marks the given entity ($dirfd, $pathname) in the current notification
group with the given properties.

Again, see
L<the man pages|http://man7.org/linux/man-pages/man2/fanotify_mark.2.html>
for detailed information about the arguments.

C<$flags> can be one of C<FAN_MARK_ADD>, C<FAN_MARK_REMOVE>, and
C<FAN_MARK_FLUSH> to describe the respective operation

C<$mask> describes the operations for which the program listens.

C<$dirfd> and C<$pathname> describe the file system object to watch.
Please note that C<$dirfd> needs to be a numeric file descriptor (such
as returned by L<sysopen> and friends), in contrast to a perl file handle.
The L<perlfunc/fileno> function can be used to get a file descriptor for a perl
file handle.

Returns true in case of success, undef otherwise (see L<perlvar/"$!"> in that
case).

=head3 Object method C<read([$count])>

This function returns a list of L</"Package C<Linux::Fanotify::Event>> objects.
The optional C<$count> argument may limit the number of returned events.
As the kernel uses an event queue, programs may read a list of events
instead of sequentally reading single events for performance reasons.

See the L</"Package C<Linux::Fanotify::Event>> description below for more
information about the returned objects.

The C<$count> argument is optional, and defaults to a value that results
in an average-sized internal buffer. Using a value of 1 is supported.
This perl module limits the maximum value of C<$count> to 4096.

Unless the C<FAN_NONBLOCK> flag has been set while initializing the fanotify
group, the read call blocks and never returns an empty list.

For non blocking reads, the empty list is returned, and errno is EAGAIN. Other
cases are directly passed on from the low level calls.

=head3 Object method C<getfd()>

Returns the file descriptor of the notification group.

Allows for all kinds of messing around; be careful. May be useful for poll() or
select() calls on the returned file descriptor.

After a manual closing of a notification group, this will be -1.

=head3 Object method C<close()>

Closes the notification group.

This method does not have to be called manually (unless
L</"Package-global variable C<$Linux::Fanotify::FanotifyGroup::autoclose>">
has been set to 0); the object's destruction will
automatically close the file descriptor.

Any events present in the event queue will be flushed (that includes an
implicit "allow" of queued permission events).

Returns true in case of success, undef in case of error.

=head2 Package C<Linux::Fanotify::Event>

C<Linux::Fanotify::Event> objects reflect event queue entries as returned
by the system. Please note that event objects use an internal representation
of the event meta data and can only be accessed via the described methods.

Use the getter methods listed below to get information about the event
properties.

=head3 Package-global variable C<$Linux::Fanotify::Event::autoclose>

This variable defaults to 1 and results in the event's file descriptor being
closed when objects of this type are destroyed (e.g. by going out of scope).

This almost definitely is what you want. However, if you use multithreading
or similar witchcraft, passing around objects may result in destruction of
copies of this object and subsequent, wrongly closing of the files.

Take care when setting this to 0 (or undef) and manually close every event's
file descriptor.

=head3 Object method C<close()>

Closes the event's file descriptor. For non-permission events, this results
in releasing the respective kernel data structures (only a limited amount of
files can be kept open per process).

For permission events (C<FAN_OPEN_PERM>, C<FAN_ACCESS_PERM>), a default
response is created in case no explicit response was issued. See
L<above|/"Property C<$Linux::Fanotify::default_response>"> for more
information about default responses.

Manually closing the file descriptor is normally not required (unless the
L</"Package-global variable C<$Linux::Fanotify::Event::autoclose>"> has
been set to a false value); as soon as
the event object is going out of scope, it will automatically be closed
to prevent leaking file descriptors. If you intentionally want to keep
a file descriptor open, store the event object in a variable of your
choice.

Returns true in case of success, undef in case of error.

=head3 Object method C<needsResponse>

Returns whether the event object (still) requires a response, i.e., it
was (a) a FAN_OPEN_PERM or FAN_ACCESS_PERM in the first place, and (b)
was not already responed.

=head3 Object method C<allow()>

Respond to the event with a "FAN_ALLOW", allowing the operation.

=head3 Object method C<deny()>

Respond to the event with a "FAN_DENY", denying the operation.

=head3 Getter methods

The following getter methods provide read only access to the properties
of an event:

=over

=item * event_len

=item * vers

=item * metadata_len

=item * mask

=item * fd

=item * pid

=back

All getters directly return the original data structure's property
unaltered. At the time of writing, C<event_len> and C<metadata_len> contain
the length of an event meta data structure, 24 bytes.

To get the file name for the requested file descriptor, one can
use a C<readlink()> call on the process' proc entry:

        readlink("/proc/self/fd/" . $event->fd);

=head1 Functional interface

Using the object oriented interface described above is recommended in all
cases. Not all object methods (especially the event object getters) have
functional counterparts. However, the low level functions can be
accessed with normal function calls.

=head2 Function C<fanotify_init($flags, $event_f_flags)>

Initializes and returns a fanotify group.

In case of an error, returns undef.

=head2 Function C<fanotify_mark($notgrp, $flags, $mask, $dirfd, $pathname)>

Marks a file system object to be monitored via the given notgrp.

See the respective
L<object method|/"Object method C<mark($flags, $mask, $dirfd, $pathname)>">
for information on the arguments.

=head2 Function C<fanotify_read($notgrp [, $max)>

Read events from the queue described by C<$notgrp>. Limited to C<$max> if
given, limited to a module default otherwise.

=head2 Function C<fanotify_write($event, $response>

Respond to an event with FAN_ALLOW or FAN_DENY. No other responses are
currently accepted.

Returns the number of bytes written to the fanotify group file descriptor
on success (you can expect this to be true), undef otherwise.

=head1 EXPORTED SYMBOLS

Per default, no symbols are exported by this module. However, the constants
as well as the functions of the L</"Functional interface"> are exportable.

By using the export tags C<:consts> and C<:funcs>, all of the respective
symbols are importable. Use

	use Linux::Fanotify qw(:consts);

to import all constants.

The fanotify_init calls (C<new> constructor, C<init> class method,
C<fanotify_init> function) use O_* constants that are exported
by the L<Fcntl> module. In most cases, you want to C<use> that
module as well.

=head1 AUTHOR

Bastian Friedrich <bastian@cpan.org> or <bastian@friedrich.link>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2014 Bastian Friedrich. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

