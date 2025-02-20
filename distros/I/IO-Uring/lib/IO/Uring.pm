package IO::Uring;
$IO::Uring::VERSION = '0.002';
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use Exporter 'import';
# @EXPORT_OK is filled from XS

1;

# ABSTRACT: io_uring for Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Uring - io_uring for Perl

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 my $ring = IO::Uring->new(32);
 my $buffer = "\0" x 4096;
 $ring->recv($fh, $buffer, MSG_WAITALL, 0, sub($res, $flags) { ... });
 $ring->send($fh, $buffer, 0, 0, sub($res, $flags) { ... });
 $ring->run_once while 1;

=head1 DESCRIPTION

This module is a low-level interface to C<io_uring>, Linux's new asynchronous I/O interface drastically reducing the number of system calls needed to perform I/O. Unlike previous models such as epoll, it's based on a proactor model instead of a reactor model, meaning that you schedule asynchronous actions and then get notified by a callback when the action has completed.

Generally speaking, the methods of this class match a system call 1-to-1 (e.g. L<recv(2)>), except that they have two additional arguments:

=over 1

=item 1.

The submission flags. In particular this allows you to chain actions.

=item 2.

A callback. This callback receives two integer arguments: a result (on error typically a negative errno value), and the completion flags. This callback will be kept alive by this module; any other resources that need to be kept alive should be captured by it.

=back

All event methods return an identifier that can be used with C<cancel>.

B<Note>: This is an early release and this module should still be regarded as experimental. Backwards compatibility is not yet guaranteed.

=head1 METHODS

=head2 new($queue_size)

Create a new uring object, with the given submission queue size.

=head2 run_once($min_events = 1)

Submit all pending requests, and process at least C<$min_events> completed (but up to C<$queue_size>) events.

=head2 probe()

This probes for which features are supported on this system. It returns a hash of feature-name to true/false. Generally speaking feature names map directly to method names but note that for filesystem operations you should check for the C<*at> version (e.g. C<'openat'> not C<'open'>).

=head2 accept($sock, $flags, $s_flags, $callback)

Accept a new socket from listening socket C<$sock>.

=head2 bind($sock, $sockaddr, $s_flags, $callback)

Bind the socket C<$sock> to C<$sockaddr>.

=head2 cancel($identifier, $flags, $s_flags, $callback = undef)

Cancel a pending request. C<$identifier> should usually be the value returned by a previous event method. C<$flags> is usually C<0>, but may be C<IORING_ASYNC_CANCEL_ALL>, C<IORING_ASYNC_CANCEL_FD> or C<IORING_ASYNC_CANCEL_ANY>. Note that unlike most event methods the C<$callback> is allowed to be empty.

=head2 close($fh, $s_flags, $callback)

Close the filehandle C<$fh>.

=head2 connect($sock, $sockaddr, $s_flags, $callback)

Connect socket C<$sock> to address C<$sockaddr>.

=head2 fallocate($fh, $offset, $length, $s_flags, $callback)

Allocate disk space in C<$fh> for C<$offset> and C<$length>.

=head2 fsync($fh, $flags, $s_flags, $callback)

Synchronize a file's in-core state with its storage device. C<flags> may be C<0> or C<IORING_FSYNC_DATASYNC>.

=head2 ftruncate($fh, $length, $s_flags, $callback)

Truncate C<$fh> to length C<$length>.

=head2 listen($fh, $count)

Mark the socket referred to by C<$fh> as a passive socket, that is, as a socket that will be used to C<accept> incoming connection requests using accept(2). C<$count> is the maximum backlog site for pending connections.

=head2 link($old_path, $new_path, $flags, $s_flags, $callback)

Link the file at C<$new_path> to C<$old_path>.

=head2 linkat($old_dir, $old_path, $new_dir, $new_path, $flags, $s_flags, $callback)

Link the file at C<$new_path> in C<$new_dir> (a directory handle) to C<$old_path> in C<$old_dir>.

=head2 link_timeout($time_spec, $flags, $s_flags, $callback = undef)

Prepare a timeout request for linked submissions (using the C<IOSQE_IO_LINK>/C<IOSQE_IO_HARDLINK> submission flags). C<$timespec> must refer to a L<Time::Spec|Time::Spec> object that must be kept alive until submission (usually through the callback). C<$flags> is a bit set that may contain any of the following values: C<IORING_TIMEOUT_ABS>, C<IORING_TIMEOUT_BOOTTIME>, C<IORING_TIMEOUT_REALTIME>, C<IORING_TIMEOUT_ETIME_SUCCESS>, C<IORING_TIMEOUT_MULTISHOT>.

Like C<cancel> and C<timeout_remove>, the C<$callback> is optional.

=head2 mkdir($path, $mode, $s_flags, $callback)

Make a new directory at C<$path> with mode C<$mode>.

=head2 mkdirat($dirhandle, $path, $mode, $s_flags, $callback)

Make a new directory at C<$path> under C<$dirhandle> with mode C<$mode>.

=head2 nop($s_flags, $callback)

This executes a no-op.

=head2 open($path, $flags, $mode, $s_flags, $callback)

Open a file at C<$path> with C<$flags> and C<mode>.

=head2 openat($dirhandle, $path, $flags, $mode, $s_flags, $callback)

Open a file at C<$path> under C<$dirhandle> with C<$flags> and C<mode>.

=head2 poll($fh, $mask, $s_flags, $callback)

Poll the file handle C<$fh> once. C<$mask> can have the same values as synchronous poll (e.g. C<POLLIN>, C<POLLOUT>).

=head2 poll_multishot($fh, $mask, $s_flags, $callback)

Poll the file handle C<$fh> and repeatedly call C<$callback> whenever new data is available. C<$mask> can have the same values as synchronous poll (e.g. C<POLLIN>, C<POLLOUT>).

=head2 shutdown($fh, $how, $s_flags, $callback)

Shut down a part of a connection, the same way the core builtin C<shutdown($fh, $how)> does.

=head2 splice($fh_in, $off_in, $fh_out, $off_out, $nbytes, $flags, $s_flags, $callback)

Move data between two file handle without copying
between kernel address space and user address space. It transfers
up to size bytes of data from the file handle C<$fh_in> to the
file handle C<fh_out>, where one of the file handles must
refer to a pipe.

For a pipe file handles the associated offset must be -1. If set
it will be used as the offset in the file or block device to start the read.

C<flags> must currently be C<0>.

=head2 sync_file_range($fh, $length, $offset, $flags, $s_flags, $callback)

Synchronize the given range to disk. C<$flags> must currently be C<0>.

=head2 read($fh, $buffer, $offset, $s_flags, $callback)

Equivalent to C<pread($fh, $buffer, $offset)>. The buffer must be preallocated to the desired size, the callback received the number of bytes in it that are actually written to. The buffer must be kept alive, typically by enclosing over it in the callback.

=head2 recv($sock, $buffer, $flags, $s_flags, $callback)

Equivalent to C<recv($fh, $buffer, $flags)>. The buffer must be preallocated to the desired size, the callback received the number of bytes in it that are actually written to. The buffer must be kept alive, typically by enclosing over it in the callback.

=head2 rename($old_path, $new_path, $flags, $s_flags, $callback)

Rename the file at C<$old_path> to C<$new_path>.

=head2 renameat($old_dir, $old_path, $new_dir, $new_path, $flags, $s_flags, $callback)

Rename the file at C<$old_path> in C<$old_dir> (a directory handle) to C<$new_path> in C<$new_dir>.

=head2 send($sock, $buffer, $flags, $s_flags, $callback)

Equivalent to C<send($fh, $buffer, $flags)>. The buffer must be kept alive, typically by enclosing over it in the callback.

=head2 sendto($sock, $buffer, $flags, $sockaddr, $s_flags, $callback)

Send a buffer to a specific address. The buffer and address must be kept alive, typically by enclosing over it in the callback.

=head2 socket($domain, $type, $protocol, $flags, $s_flags, $callback)

Create a new socket of the given C<$domain>, C<$type> and C<$protocol>.

=head2 tee($fh_in, $fh_out, $nbytes, $flags, $callback)

Prepare a tee request. This will use as input the file
handle C<$fh_in> and as output the file handle C<$fh_out>
duplicating C<$nbytes> bytes worth of data. C<$flags> are modifier
flags for the operation and must currently be C<0>.

=head2 timeout($timespec, $count, $flags, $s_flags, $callback)

Create a timeout. C<$timespec> must refer to a L<Time::Spec|Time::Spec> object that must be kept alive through the callback. C<$count> is the number of events that should be waited on, typically it would be C<0>. C<$flags> is a bit set that may contain any of the following values: C<IORING_TIMEOUT_ABS>, C<IORING_TIMEOUT_BOOTTIME>, C<IORING_TIMEOUT_REALTIME>, C<IORING_TIMEOUT_ETIME_SUCCESS>, C<IORING_TIMEOUT_MULTISHOT>.

=head2 timeout_remove($id, $flags, $s_flags, $callback = undef)

Remove a timeout identified by C<$id>. C<$flags> is currently unused and must be C<0>. Like C<cancel> and C<link_timeout>, the callback is optional.

=head2 timeout_update($id, $timespec, $flags, $s_flags, $callback)

Update the timer identifiers by C<$id>. C<timespec> and C<flags> have the same meaning as in C<timeout>.

=head2 unlink($path, $mode, $s_flags, $callback)

Remove a file or directory at C<$path> with flags C<$flags>.

=head2 unlinkat($dirhandle, $path, $mode, $s_flags, $callback)

Remove a file or directory at C<$path> under C<$dirhandle> with flags C<$flags>.

=head2 waitid($id_type, $id, $info, $options, $flags, $s_flags, $callback)

Wait for another process. C<$id_type> specifies the type of ID used and must be one of C<P_PID> (C<$id> is a PID), C<P_PGID> (C<$id> is a process group), C<P_PIDFD> (C<$id> is a PID fd) or C<P_ALL> (C<$id> is ignored, wait for any child). C<$info> must be a L<Signal::Info|Signal::Info> object that must be kept alive through the callback, it will contain the result of the event. C<$options> is a bitset of C<WEXITED>, C<WSTOPPED> C<WCONTINUED>, C<WNOWAIT>; typically it would be C<WEXITED>. C<$flags> is currently unused and must be C<0>. When the callback is triggered the following entries of C<$info> will be set: C<pid>, C<uid>, C<signo> (will always be C<SIGCHLD>), C<status> and C<code> (C<CLD_EXITED>, C<CLD_KILLED>)

=head2 write($fh, $buffer, $offset, $s_flags, $callback)

Equivalent to C<send($fh, $buffer, $flags)>. The buffer must be kept alive, typically by enclosing over it in the callback.

=head1 FLAGS

The following flags are all optionally exported:

=head2 Submission flags

These flags are passed to all event methods, and affect how the submission is processed.

=over 4

=item * C<IOSQE_ASYNC>

Normal operation for io_uring is to try and issue an SQE as
non-blocking first, and if that fails, execute it in an
async manner. To support more efficient overlapped
operation of requests that the application knows/assumes
will always (or most of the time) block, the application
can ask for an SQE to be issued async from the start. Note
that this flag immediately causes the SQE to be offloaded
to an async helper thread with no initial non-blocking
attempt. This may be less efficient and should not be used
liberally or without understanding the performance and
efficiency tradeoffs.

=item * C<IOSQE_IO_LINK>

When this flag is specified, the SQE forms a link with the
next SQE in the submission ring. That next SQE will not be
started before the previous request completes. This, in
effect, forms a chain of SQEs, which can be arbitrarily
long. The tail of the chain is denoted by the first SQE
that does not have this flag set. Chains are not supported
across submission boundaries. Even if the last SQE in a
submission has this flag set, it will still terminate the
current chain. This flag has no effect on previous SQE
submissions, nor does it impact SQEs that are outside of
the chain tail. This means that multiple chains can be
executing in parallel, or chains and individual SQEs. Only
members inside the chain are serialized. A chain of SQEs
will be broken if any request in that chain ends in error.

=item * C<IOSQE_IO_HARDLINK>

Like IOSQE_IO_LINK , except the links aren't severed if an
error or unexpected result occurs.

=item * C<IOSQE_IO_DRAIN>

When this flag is specified, the SQE will not be started
before previously submitted SQEs have completed, and new
SQEs will not be started before this one completes.

=back

=head2 Completion flags

These are values set in the C<$flags> arguments of the event callbacks. They include:

=over 4

=item * C<IORING_CQE_F_MORE>

If set, the application should expect more completions from
the request. This is used for requests that can generate
multiple completions, such as multi-shot requests, receive,
or accept.

=item * C<IORING_CQE_F_SOCK_NONEMPTY>

If set, upon receiving the data from the socket in the
current request, the socket still had data left on
completion of this request.

=back

=head2 Event specific flags

=head3 cancel

=over 4

=item * C<IORING_ASYNC_CANCEL_ALL>

Cancel all requests that match the given criteria, rather
than just canceling the first one found. Available since
5.19.

=item * C<IORING_ASYNC_CANCEL_FD>

Match based on the file handle used in the original
request rather than the user_data. Available since 5.19.

=item * C<IORING_ASYNC_CANCEL_ANY>

Match any request in the ring, regardless of user_data or
file handle.  Can be used to cancel any pending request
in the ring. Available since 5.19.

=back

=head3 fsync

The only allowed flag value for C<fsync>:

=over 4

=item * C<IORING_FSYNC_DATASYNC>

If set C<fsync> will do an C<fdatasync> instead: not sync if only metadata has changed.

=back

=head3 link / linkat

=over 4

=item * C<AT_SYMLINK_FOLLOW>

=back

=head3 recv / send / sendto

=over 4

=item * C<IORING_RECVSEND_POLL_FIRST>

If set, C<io_uring> will assume the socket is currently empty and attempting to receive data will be unsuccessful. For this case, io_uring will arm internal poll and trigger a receive of the data when the socket has data to be read. This initial receive attempt can be wasteful for the case where the socket is expected to be empty, setting this flag will bypass the initial receive attempt and go straight to arming poll. If poll does indicate that data is ready to be received, the operation will proceed.

=back

=head3 remove / removeat

=over 4

=item * C<RENAME_EXCHANGE>

Atomically exchange oldpath and newpath.  Both pathnames
must exist but may be of different types (e.g., one could
be a non-empty directory and the other a symbolic link).

=item * C<RENAME_NOREPLACE>

Don't overwrite newpath of the rename.  Return an error if
newpath already exists.

C<RENAME_NOREPLACE> can't be employed together with
C<RENAME_EXCHANGE>. C<RENAME_NOREPLACE> requires support
from the underlying filesystem.

=back

=head3 timeout

=over 4

=item * C<IORING_TIMEOUT_ABS>

The value specified in ts is an absolute value rather than
a relative one.

=item * C<IORING_TIMEOUT_BOOTTIME>

The boottime clock source should be used.

=item * C<IORING_TIMEOUT_REALTIME>

The realtime clock source should be used.

=item * C<IORING_TIMEOUT_ETIME_SUCCESS>

Consider an expired timeout a success in terms of the
posted completion. This means it will not sever dependent
links, as a failed request normally would. The posted CQE
result code will still contain -ETIME in the res value.

=item * C<IORING_TIMEOUT_MULTISHOT>

The request will return multiple timeout completions. The
completion flag IORING_CQE_F_MORE is set if more timeouts
are expected. The value specified in count is the number of
repeats. A value of 0 means the timeout is indefinite and
can only be stopped by a removal request. Available since
the 6.4 kernel.

=back

=head3 unlink / unlinkat

=over 4

=item * C<AT_REMOVEDIR>

If the C<AT_REMOVEDIR> flag is specified, C<unlink> / C<unlinkat>
performs the equivalent of L<rmdir(2)> on pathname.

=back

=head3 waitid

C<waitid> has various constants defined for it. The following values are defined for the C<$idtype>:

=over 4

=item * C<P_PID>

This indicates the identifier is a process identifier.

=item * C<P_PGID>

This indicates the identifier is a process group identifier.

=item * C<P_PIDFD>

This indicates the identifier is a pidfd.

=item * C<P_ALL>

This indicates the identifier will be ignored and any child is waited upon.

=back

The following constants are defined for the C<$options> argument:

=over 4

=item * C<WEXITED>

Wait for children that have terminated.

=item * C<WSTOPPED>

Wait for children that have been stopped by delivery of a signal.

=item * C<WCONTINUED>

Wait for (previously stopped) children that have been
resumed by delivery of SIGCONT.

=item * C<WNOWAIT>

Leave the child in a waitable state; a later wait call can
be used to again retrieve the child status information.

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
