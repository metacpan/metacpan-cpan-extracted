=head1 NAME

Linux::AIO - linux-specific aio implemented using clone

=head1 SYNOPSIS

 use Linux::AIO;

 # This module has been mostly superseded by IO::AIO.

=head1 DESCRIPTION

I<This module has been mostly superseded by IO::AIO, which is API 
compatible.>

This module implements asynchronous I/O using the means available to Linux
- clone. It does not hook into the POSIX aio_* functions because Linux
does not yet support these in the kernel (even as of 2.6.12, only O_DIRECT
files are supported) and even if, it would only allow aio_read and write,
not open, stat and so on.

Instead, in this module a number of (non-posix) threads are started that
execute your read/writes and signal their completion. You don't need
thread support in your libc or perl, and the threads created by this
module will not be visible to the pthreads library.

NOTICE: the threads created by this module will automatically be killed
when the thread calling min_parallel exits. Make sure you only ever call
min_parallel from the same thread that loaded this module.

Although the module will work with in the presence of other threads, it is
not reentrant, so use appropriate locking yourself.

=head2 API NOTES

All the C<aio_*> calls are more or less thin wrappers around the syscall
with the same name (sans C<aio_>). The arguments are similar or identical,
and they all accept an additional C<$callback> argument which must be
a code reference. This code reference will get called with the syscall
return code (e.g. most syscalls return C<-1> on error, unlike perl, which
usually delivers "false") as it's sole argument when the given syscall has
been executed asynchronously.

All functions that expect a filehandle will also accept a file descriptor.

The filenames you pass to these routines I<must> be absolute. The reason
is that at the time the request is being executed, the current working
directory could have changed. Alternatively, you can make sure that you
never change the current working directory.

=over 4

=cut

package Linux::AIO;

use base 'Exporter';

BEGIN {
   $VERSION = 1.9;

   @EXPORT = qw(aio_read aio_write aio_open aio_close aio_stat aio_lstat aio_unlink
                aio_fsync aio_fdatasync aio_readahead);
   @EXPORT_OK = qw(poll_fileno poll_cb min_parallel max_parallel nreqs);

   require XSLoader;
   XSLoader::load Linux::AIO, $VERSION;
}

=item Linux::AIO::min_parallel $nthreads

Set the minimum number of AIO threads to C<$nthreads>. The default is
C<1>, which means a single asynchronous operation can be done at one time
(the number of outstanding operations, however, is unlimited).

It is recommended to keep the number of threads low, as some linux
kernel versions will scale negatively with the number of threads (higher
parallelity => MUCH higher latency).

Under normal circumstances you don't need to call this function, as this
module automatically starts a single async thread.

=item Linux::AIO::max_parallel $nthreads

Sets the maximum number of AIO threads to C<$nthreads>. If more than
the specified number of threads are currently running, kill them. This
function blocks until the limit is reached.

This module automatically runs C<max_parallel 0> at program end, to ensure
that all threads are killed and that there are no outstanding requests.

Under normal circumstances you don't need to call this function.

=item $fileno = Linux::AIO::poll_fileno

Return the I<request result pipe filehandle>. This filehandle must be
polled for reading by some mechanism outside this module (e.g. Event
or select, see below). If the pipe becomes readable you have to call
C<poll_cb> to check the results.

See C<poll_cb> for an example.

=item Linux::AIO::poll_cb

Process all outstanding events on the result pipe. You have to call this
regularly. Returns the number of events processed. Returns immediately
when no events are outstanding.

You can use Event to multiplex, e.g.:

   Event->io (fd => Linux::AIO::poll_fileno,
              poll => 'r', async => 1,
              cb => \&Linux::AIO::poll_cb);

=item Linux::AIO::poll_wait

Wait till the result filehandle becomes ready for reading (simply does a
select on the filehandle. This is useful if you want to synchronously wait
for some requests to finish).

See C<nreqs> for an example.

=item Linux::AIO::nreqs

Returns the number of requests currently outstanding.

Example: wait till there are no outstanding requests anymore:

   Linux::AIO::poll_wait, Linux::AIO::poll_cb
      while Linux::AIO::nreqs;

=item aio_open $pathname, $flags, $mode, $callback

Asynchronously open or create a file and call the callback with the
filedescriptor (NOT a perl filehandle, sorry for that, but watch out, this
might change in the future).

The pathname passed to C<aio_open> must be absolute. See API NOTES, above,
for an explanation.

The C<$mode> argument is a bitmask. See the C<Fcntl> module for a
list. They are the same as used in C<sysopen>.

Example:

   aio_open "/etc/passwd", O_RDONLY, 0, sub {
      if ($_[0] >= 0) {
         open my $fh, "<&=$_[0]";
         print "open successful, fh is $fh\n";
         ...
      } else {
         die "open failed: $!\n";
      }
   };

=item aio_close $fh, $callback

Asynchronously close a file and call the callback with the result code.

=item aio_read  $fh,$offset,$length, $data,$dataoffset,$callback

=item aio_write $fh,$offset,$length, $data,$dataoffset,$callback

Reads or writes C<length> bytes from the specified C<fh> and C<offset>
into the scalar given by C<data> and offset C<dataoffset> and calls the
callback without the actual number of bytes read (or -1 on error, just
like the syscall).

Example: Read 15 bytes at offset 7 into scalar C<$buffer>, strating at
offset C<0> within the scalar:

   aio_read $fh, 7, 15, $buffer, 0, sub {
      $_[0] >= 0 or die "read error: $!";
      print "read <$buffer>\n";
   };

=item aio_readahead $fh,$offset,$length, $callback

Asynchronously reads the specified byte range into the page cache, using
the C<readahead> syscall.

readahead() populates the page cache with data from a file so that
subsequent reads from that file will not block on disk I/O. The C<$offset>
argument specifies the starting point from which data is to be read and
C<$length> specifies the number of bytes to be read. I/O is performed in
whole pages, so that offset is effectively rounded down to a page boundary
and bytes are read up to the next page boundary greater than or equal to
(off-set+length). aio_readahead() does not read beyond the end of the
file. The current file offset of the file is left unchanged.

=item aio_stat  $fh_or_path, $callback

=item aio_lstat $fh, $callback

Works like perl's C<stat> or C<lstat> in void context. The callback will
be called after the stat and the results will be available using C<stat _>
or C<-s _> etc...

The pathname passed to C<aio_stat> must be absolute. See API NOTES, above,
for an explanation.

Currently, the stats are always 64-bit-stats, i.e. instead of returning an
error when stat'ing a large file, the results will be silently truncated
unless perl itself is compiled with large file support.

Example: Print the length of F</etc/passwd>:

   aio_stat "/etc/passwd", sub {
      $_[0] and die "stat failed: $!";
      print "size is ", -s _, "\n";
   };

=item aio_unlink $pathname, $callback

Asynchronously unlink (delete) a file and call the callback with the
result code.

=item aio_fsync $fh, $callback

Asynchronously call fsync on the given filehandle and call the callback
with the fsync result code.

=item aio_fdatasync $fh, $callback

Asynchronously call fdatasync on the given filehandle and call the
callback with the fdatasync result code.

=cut

min_parallel 1;

END {
   max_parallel 0;
}

1;

=back

=head1 BUGS

This module has been extensively tested in a large and very busy webserver
for many years now.

   - aio_open gives a fd, but all other functions expect a perl filehandle.

=head1 SEE ALSO

L<Coro>, L<IO::AIO>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

