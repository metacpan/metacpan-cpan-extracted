=head1 NAME

IO::AIO - Asynchronous/Advanced Input/Output

=head1 SYNOPSIS

 use IO::AIO;

 aio_open "/etc/passwd", IO::AIO::O_RDONLY, 0, sub {
    my $fh = shift
       or die "/etc/passwd: $!";
    ...
 };

 aio_unlink "/tmp/file", sub { };

 aio_read $fh, 30000, 1024, $buffer, 0, sub {
    $_[0] > 0 or die "read error: $!";
 };

 # version 2+ has request and group objects
 use IO::AIO 2;

 aioreq_pri 4; # give next request a very high priority
 my $req = aio_unlink "/tmp/file", sub { };
 $req->cancel; # cancel request if still in queue

 my $grp = aio_group sub { print "all stats done\n" };
 add $grp aio_stat "..." for ...;

=head1 DESCRIPTION

This module implements asynchronous I/O using whatever means your
operating system supports. It is implemented as an interface to C<libeio>
(L<http://software.schmorp.de/pkg/libeio.html>).

Asynchronous means that operations that can normally block your program
(e.g. reading from disk) will be done asynchronously: the operation
will still block, but you can do something else in the meantime. This
is extremely useful for programs that need to stay interactive even
when doing heavy I/O (GUI programs, high performance network servers
etc.), but can also be used to easily do operations in parallel that are
normally done sequentially, e.g. stat'ing many files, which is much faster
on a RAID volume or over NFS when you do a number of stat operations
concurrently.

While most of this works on all types of file descriptors (for
example sockets), using these functions on file descriptors that
support nonblocking operation (again, sockets, pipes etc.) is
very inefficient. Use an event loop for that (such as the L<EV>
module): IO::AIO will naturally fit into such an event loop itself.

In this version, a number of threads are started that execute your
requests and signal their completion. You don't need thread support
in perl, and the threads created by this module will not be visible
to perl. In the future, this module might make use of the native aio
functions available on many operating systems. However, they are often
not well-supported or restricted (GNU/Linux doesn't allow them on normal
files currently, for example), and they would only support aio_read and
aio_write, so the remaining functionality would have to be implemented
using threads anyway.

In addition to asynchronous I/O, this module also exports some rather
arcane interfaces, such as C<madvise> or linux's C<splice> system call,
which is why the C<A> in C<AIO> can also mean I<advanced>.

Although the module will work in the presence of other (Perl-) threads,
it is currently not reentrant in any way, so use appropriate locking
yourself, always call C<poll_cb> from within the same thread, or never
call C<poll_cb> (or other C<aio_> functions) recursively.

=head2 EXAMPLE

This is a simple example that uses the EV module and loads
F</etc/passwd> asynchronously:

   use EV;
   use IO::AIO;

   # register the IO::AIO callback with EV
   my $aio_w = EV::io IO::AIO::poll_fileno, EV::READ, \&IO::AIO::poll_cb;

   # queue the request to open /etc/passwd
   aio_open "/etc/passwd", IO::AIO::O_RDONLY, 0, sub {
      my $fh = shift
         or die "error while opening: $!";

      # stat'ing filehandles is generally non-blocking
      my $size = -s $fh;

      # queue a request to read the file
      my $contents;
      aio_read $fh, 0, $size, $contents, 0, sub {
         $_[0] == $size
            or die "short read: $!";

         close $fh;

         # file contents now in $contents
         print $contents;

         # exit event loop and program
         EV::break;
      };
   };

   # possibly queue up other requests, or open GUI windows,
   # check for sockets etc. etc.

   # process events as long as there are some:
   EV::run;

=head1 REQUEST ANATOMY AND LIFETIME

Every C<aio_*> function creates a request. which is a C data structure not
directly visible to Perl.

If called in non-void context, every request function returns a Perl
object representing the request. In void context, nothing is returned,
which saves a bit of memory.

The perl object is a fairly standard ref-to-hash object. The hash contents
are not used by IO::AIO so you are free to store anything you like in it.

During their existance, aio requests travel through the following states,
in order:

=over 4

=item ready

Immediately after a request is created it is put into the ready state,
waiting for a thread to execute it.

=item execute

A thread has accepted the request for processing and is currently
executing it (e.g. blocking in read).

=item pending

The request has been executed and is waiting for result processing.

While request submission and execution is fully asynchronous, result
processing is not and relies on the perl interpreter calling C<poll_cb>
(or another function with the same effect).

=item result

The request results are processed synchronously by C<poll_cb>.

The C<poll_cb> function will process all outstanding aio requests by
calling their callbacks, freeing memory associated with them and managing
any groups they are contained in.

=item done

Request has reached the end of its lifetime and holds no resources anymore
(except possibly for the Perl object, but its connection to the actual
aio request is severed and calling its methods will either do nothing or
result in a runtime error).

=back

=cut

package IO::AIO;

use Carp ();

use common::sense;

use base 'Exporter';

BEGIN {
   our $VERSION = 4.75;

   our @AIO_REQ = qw(aio_sendfile aio_seek aio_read aio_write aio_open aio_close
                     aio_stat aio_lstat aio_unlink aio_rmdir aio_readdir aio_readdirx
                     aio_scandir aio_symlink aio_readlink aio_realpath aio_fcntl aio_ioctl
                     aio_sync aio_fsync aio_syncfs aio_fdatasync aio_sync_file_range
                     aio_pathsync aio_readahead aio_fiemap aio_allocate
                     aio_rename aio_rename2 aio_link aio_move aio_copy aio_group
                     aio_nop aio_mknod aio_load aio_rmtree aio_mkdir aio_chown
                     aio_chmod aio_utime aio_truncate
                     aio_msync aio_mtouch aio_mlock aio_mlockall
                     aio_statvfs
                     aio_slurp
                     aio_wd);

   our @EXPORT = (@AIO_REQ, qw(aioreq_pri aioreq_nice));
   our @EXPORT_OK = qw(poll_fileno poll_cb poll_wait flush
                       min_parallel max_parallel max_idle idle_timeout
                       nreqs nready npending nthreads
                       max_poll_time max_poll_reqs
                       sendfile fadvise madvise
                       mmap munmap mremap munlock munlockall);

   push @AIO_REQ, qw(aio_busy); # not exported

   @IO::AIO::GRP::ISA = 'IO::AIO::REQ';

   require XSLoader;
   XSLoader::load ("IO::AIO", $VERSION);
}

=head1 FUNCTIONS

=head2 QUICK OVERVIEW

This section simply lists the prototypes most of the functions for
quick reference. See the following sections for function-by-function
documentation.

   aio_wd $pathname, $callback->($wd)
   aio_open $pathname, $flags, $mode, $callback->($fh)
   aio_close $fh, $callback->($status)
   aio_seek  $fh,$offset,$whence, $callback->($offs)
   aio_read  $fh,$offset,$length, $data,$dataoffset, $callback->($retval)
   aio_write $fh,$offset,$length, $data,$dataoffset, $callback->($retval)
   aio_sendfile $out_fh, $in_fh, $in_offset, $length, $callback->($retval)
   aio_readahead $fh,$offset,$length, $callback->($retval)
   aio_stat  $fh_or_path, $callback->($status)
   aio_lstat $fh, $callback->($status)
   aio_statvfs $fh_or_path, $callback->($statvfs)
   aio_utime $fh_or_path, $atime, $mtime, $callback->($status)
   aio_chown $fh_or_path, $uid, $gid, $callback->($status)
   aio_chmod $fh_or_path, $mode, $callback->($status)
   aio_truncate $fh_or_path, $offset, $callback->($status)
   aio_allocate $fh, $mode, $offset, $len, $callback->($status)
   aio_fiemap $fh, $start, $length, $flags, $count, $cb->(\@extents)
   aio_unlink $pathname, $callback->($status)
   aio_mknod $pathname, $mode, $dev, $callback->($status)
   aio_link $srcpath, $dstpath, $callback->($status)
   aio_symlink $srcpath, $dstpath, $callback->($status)
   aio_readlink $pathname, $callback->($link)
   aio_realpath $pathname, $callback->($path)
   aio_rename $srcpath, $dstpath, $callback->($status)
   aio_rename2 $srcpath, $dstpath, $flags, $callback->($status)
   aio_mkdir $pathname, $mode, $callback->($status)
   aio_rmdir $pathname, $callback->($status)
   aio_readdir $pathname, $callback->($entries)
   aio_readdirx $pathname, $flags, $callback->($entries, $flags)
      IO::AIO::READDIR_DENTS IO::AIO::READDIR_DIRS_FIRST
      IO::AIO::READDIR_STAT_ORDER IO::AIO::READDIR_FOUND_UNKNOWN
   aio_scandir $pathname, $maxreq, $callback->($dirs, $nondirs)
   aio_load $pathname, $data, $callback->($status)
   aio_copy $srcpath, $dstpath, $callback->($status)
   aio_move $srcpath, $dstpath, $callback->($status)
   aio_rmtree $pathname, $callback->($status)
   aio_fcntl $fh, $cmd, $arg, $callback->($status)
   aio_ioctl $fh, $request, $buf, $callback->($status)
   aio_sync $callback->($status)
   aio_syncfs $fh, $callback->($status)
   aio_fsync $fh, $callback->($status)
   aio_fdatasync $fh, $callback->($status)
   aio_sync_file_range $fh, $offset, $nbytes, $flags, $callback->($status)
   aio_pathsync $pathname, $callback->($status)
   aio_msync $scalar, $offset = 0, $length = undef, flags = MS_SYNC, $callback->($status)
   aio_mtouch $scalar, $offset = 0, $length = undef, flags = 0, $callback->($status)
   aio_mlock $scalar, $offset = 0, $length = undef, $callback->($status)
   aio_mlockall $flags, $callback->($status)
   aio_group $callback->(...)
   aio_nop $callback->()

   $prev_pri = aioreq_pri [$pri]
   aioreq_nice $pri_adjust

   IO::AIO::poll_wait
   IO::AIO::poll_cb
   IO::AIO::poll
   IO::AIO::flush
   IO::AIO::max_poll_reqs $nreqs
   IO::AIO::max_poll_time $seconds
   IO::AIO::min_parallel $nthreads
   IO::AIO::max_parallel $nthreads
   IO::AIO::max_idle $nthreads
   IO::AIO::idle_timeout $seconds
   IO::AIO::max_outstanding $maxreqs
   IO::AIO::nreqs
   IO::AIO::nready
   IO::AIO::npending
   IO::AIO::reinit

   $nfd = IO::AIO::get_fdlimit
   IO::AIO::min_fdlimit $nfd

   IO::AIO::sendfile $ofh, $ifh, $offset, $count
   IO::AIO::fadvise $fh, $offset, $len, $advice

   IO::AIO::mmap $scalar, $length, $prot, $flags[, $fh[, $offset]]
   IO::AIO::munmap $scalar
   IO::AIO::mremap $scalar, $new_length, $flags[, $new_address]
   IO::AIO::madvise $scalar, $offset, $length, $advice
   IO::AIO::mprotect $scalar, $offset, $length, $protect
   IO::AIO::munlock $scalar, $offset = 0, $length = undef
   IO::AIO::munlockall

   # stat extensions
   $counter = IO::AIO::st_gen
   $seconds = IO::AIO::st_atime, IO::AIO::st_mtime, IO::AIO::st_ctime, IO::AIO::st_btime
   ($atime, $mtime, $ctime, $btime, ...) = IO::AIO::st_xtime
   $nanoseconds = IO::AIO::st_atimensec, IO::AIO::st_mtimensec, IO::AIO::st_ctimensec, IO::AIO::st_btimensec
   $seconds = IO::AIO::st_btimesec
   ($atime, $mtime, $ctime, $btime, ...) = IO::AIO::st_xtimensec

   # very much unportable syscalls
   IO::AIO::accept4 $r_fh, $sockaddr, $sockaddr_len, $flags
   IO::AIO::splice $r_fh, $r_off, $w_fh, $w_off, $length, $flags
   IO::AIO::tee $r_fh, $w_fh, $length, $flags
   $actual_size = IO::AIO::pipesize $r_fh[, $new_size]
   ($rfh, $wfh) = IO::AIO::pipe2 [$flags]
   $fh = IO::AIO::memfd_create $pathname[, $flags]
   $fh = IO::AIO::eventfd [$initval, [$flags]]
   $fh = IO::AIO::timerfd_create $clockid[, $flags]
   ($cur_interval, $cur_value) = IO::AIO::timerfd_settime $fh, $flags, $new_interval, $nbw_value
   ($cur_interval, $cur_value) = IO::AIO::timerfd_gettime $fh

=head2 API NOTES

All the C<aio_*> calls are more or less thin wrappers around the syscall
with the same name (sans C<aio_>). The arguments are similar or identical,
and they all accept an additional (and optional) C<$callback> argument
which must be a code reference. This code reference will be called after
the syscall has been executed in an asynchronous fashion. The results
of the request will be passed as arguments to the callback (and, if an
error occured, in C<$!>) - for most requests the syscall return code (e.g.
most syscalls return C<-1> on error, unlike perl, which usually delivers
"false").

Some requests (such as C<aio_readdir>) pass the actual results and
communicate failures by passing C<undef>.

All functions expecting a filehandle keep a copy of the filehandle
internally until the request has finished.

All functions return request objects of type L<IO::AIO::REQ> that allow
further manipulation of those requests while they are in-flight.

The pathnames you pass to these routines I<should> be absolute. The
reason for this is that at the time the request is being executed, the
current working directory could have changed. Alternatively, you can
make sure that you never change the current working directory anywhere
in the program and then use relative paths. You can also take advantage
of IO::AIOs working directory abstraction, that lets you specify paths
relative to some previously-opened "working directory object" - see the
description of the C<IO::AIO::WD> class later in this document.

To encode pathnames as octets, either make sure you either: a) always pass
in filenames you got from outside (command line, readdir etc.) without
tinkering, b) are in your native filesystem encoding, c) use the Encode
module and encode your pathnames to the locale (or other) encoding in
effect in the user environment, d) use Glib::filename_from_unicode on
unicode filenames or e) use something else to ensure your scalar has the
correct contents.

This works, btw. independent of the internal UTF-8 bit, which IO::AIO
handles correctly whether it is set or not.

=head2 AIO REQUEST FUNCTIONS

=over 4

=item $prev_pri = aioreq_pri [$pri]

Returns the priority value that would be used for the next request and, if
C<$pri> is given, sets the priority for the next aio request.

The default priority is C<0>, the minimum and maximum priorities are C<-4>
and C<4>, respectively. Requests with higher priority will be serviced
first.

The priority will be reset to C<0> after each call to one of the C<aio_*>
functions.

Example: open a file with low priority, then read something from it with
higher priority so the read request is serviced before other low priority
open requests (potentially spamming the cache):

   aioreq_pri -3;
   aio_open ..., sub {
      return unless $_[0];

      aioreq_pri -2;
      aio_read $_[0], ..., sub {
         ...
      };
   };


=item aioreq_nice $pri_adjust

Similar to C<aioreq_pri>, but subtracts the given value from the current
priority, so the effect is cumulative.


=item aio_open $pathname, $flags, $mode, $callback->($fh)

Asynchronously open or create a file and call the callback with a newly
created filehandle for the file (or C<undef> in case of an error).

The pathname passed to C<aio_open> must be absolute. See API NOTES, above,
for an explanation.

The C<$flags> argument is a bitmask. See the C<Fcntl> module for a
list. They are the same as used by C<sysopen>.

Likewise, C<$mode> specifies the mode of the newly created file, if it
didn't exist and C<O_CREAT> has been given, just like perl's C<sysopen>,
except that it is mandatory (i.e. use C<0> if you don't create new files,
and C<0666> or C<0777> if you do). Note that the C<$mode> will be modified
by the umask in effect then the request is being executed, so better never
change the umask.

Example:

   aio_open "/etc/passwd", IO::AIO::O_RDONLY, 0, sub {
      if ($_[0]) {
         print "open successful, fh is $_[0]\n";
         ...
      } else {
         die "open failed: $!\n";
      }
   };

In addition to all the common open modes/flags (C<O_RDONLY>, C<O_WRONLY>,
C<O_RDWR>, C<O_CREAT>, C<O_TRUNC>, C<O_EXCL> and C<O_APPEND>), the
following POSIX and non-POSIX constants are available (missing ones on
your system are, as usual, C<0>):

C<O_ASYNC>, C<O_DIRECT>, C<O_NOATIME>, C<O_CLOEXEC>, C<O_NOCTTY>, C<O_NOFOLLOW>,
C<O_NONBLOCK>, C<O_EXEC>, C<O_SEARCH>, C<O_DIRECTORY>, C<O_DSYNC>,
C<O_RSYNC>, C<O_SYNC>, C<O_PATH>, C<O_TMPFILE>, C<O_TTY_INIT> and C<O_ACCMODE>.


=item aio_close $fh, $callback->($status)

Asynchronously close a file and call the callback with the result
code.

Unfortunately, you can't do this to perl. Perl I<insists> very strongly on
closing the file descriptor associated with the filehandle itself.

Therefore, C<aio_close> will not close the filehandle - instead it will
use dup2 to overwrite the file descriptor with the write-end of a pipe
(the pipe fd will be created on demand and will be cached).

Or in other words: the file descriptor will be closed, but it will not be
free for reuse until the perl filehandle is closed.

=cut

=item aio_seek $fh, $offset, $whence, $callback->($offs)

Seeks the filehandle to the new C<$offset>, similarly to perl's
C<sysseek>. The C<$whence> can use the traditional values (C<0> for
C<IO::AIO::SEEK_SET>, C<1> for C<IO::AIO::SEEK_CUR> or C<2> for
C<IO::AIO::SEEK_END>).

The resulting absolute offset will be passed to the callback, or C<-1> in
case of an error.

In theory, the C<$whence> constants could be different than the
corresponding values from L<Fcntl>, but perl guarantees they are the same,
so don't panic.

As a GNU/Linux (and maybe Solaris) extension, also the constants
C<IO::AIO::SEEK_DATA> and C<IO::AIO::SEEK_HOLE> are available, if they
could be found. No guarantees about suitability for use in C<aio_seek> or
Perl's C<sysseek> can be made though, although I would naively assume they
"just work".

=item aio_read  $fh,$offset,$length, $data,$dataoffset, $callback->($retval)

=item aio_write $fh,$offset,$length, $data,$dataoffset, $callback->($retval)

Reads or writes C<$length> bytes from or to the specified C<$fh> and
C<$offset> into the scalar given by C<$data> and offset C<$dataoffset> and
calls the callback with the actual number of bytes transferred (or -1 on
error, just like the syscall).

C<aio_read> will, like C<sysread>, shrink or grow the C<$data> scalar to
offset plus the actual number of bytes read.

If C<$offset> is undefined, then the current file descriptor offset will
be used (and updated), otherwise the file descriptor offset will not be
changed by these calls.

If C<$length> is undefined in C<aio_write>, use the remaining length of
C<$data>.

If C<$dataoffset> is less than zero, it will be counted from the end of
C<$data>.

The C<$data> scalar I<MUST NOT> be modified in any way while the request
is outstanding. Modifying it can result in segfaults or World War III (if
the necessary/optional hardware is installed).

Example: Read 15 bytes at offset 7 into scalar C<$buffer>, starting at
offset C<0> within the scalar:

   aio_read $fh, 7, 15, $buffer, 0, sub {
      $_[0] > 0 or die "read error: $!";
      print "read $_[0] bytes: <$buffer>\n";
   };


=item aio_sendfile $out_fh, $in_fh, $in_offset, $length, $callback->($retval)

Tries to copy C<$length> bytes from C<$in_fh> to C<$out_fh>. It starts
reading at byte offset C<$in_offset>, and starts writing at the current
file offset of C<$out_fh>. Because of that, it is not safe to issue more
than one C<aio_sendfile> per C<$out_fh>, as they will interfere with each
other. The same C<$in_fh> works fine though, as this function does not
move or use the file offset of C<$in_fh>.

Please note that C<aio_sendfile> can read more bytes from C<$in_fh> than
are written, and there is no way to find out how many more bytes have been
read from C<aio_sendfile> alone, as C<aio_sendfile> only provides the
number of bytes written to C<$out_fh>. Only if the result value equals
C<$length> one can assume that C<$length> bytes have been read.

Unlike with other C<aio_> functions, it makes a lot of sense to use
C<aio_sendfile> on non-blocking sockets, as long as one end (typically
the C<$in_fh>) is a file - the file I/O will then be asynchronous, while
the socket I/O will be non-blocking. Note, however, that you can run
into a trap where C<aio_sendfile> reads some data with readahead, then
fails to write all data, and when the socket is ready the next time, the
data in the cache is already lost, forcing C<aio_sendfile> to again hit
the disk. Explicit C<aio_read> + C<aio_write> let's you better control
resource usage.

This call tries to make use of a native C<sendfile>-like syscall to
provide zero-copy operation. For this to work, C<$out_fh> should refer to
a socket, and C<$in_fh> should refer to an mmap'able file.

If a native sendfile cannot be found or it fails with C<ENOSYS>,
C<EINVAL>, C<ENOTSUP>, C<EOPNOTSUPP>, C<EAFNOSUPPORT>, C<EPROTOTYPE> or
C<ENOTSOCK>, it will be emulated, so you can call C<aio_sendfile> on any
type of filehandle regardless of the limitations of the operating system.

As native sendfile syscalls (as practically any non-POSIX interface hacked
together in a hurry to improve benchmark numbers) tend to be rather buggy
on many systems, this implementation tries to work around some known bugs
in Linux and FreeBSD kernels (probably others, too), but that might fail,
so you really really should check the return value of C<aio_sendfile> -
fewer bytes than expected might have been transferred.


=item aio_readahead $fh,$offset,$length, $callback->($retval)

C<aio_readahead> populates the page cache with data from a file so that
subsequent reads from that file will not block on disk I/O. The C<$offset>
argument specifies the starting point from which data is to be read and
C<$length> specifies the number of bytes to be read. I/O is performed in
whole pages, so that offset is effectively rounded down to a page boundary
and bytes are read up to the next page boundary greater than or equal to
(off-set+length). C<aio_readahead> does not read beyond the end of the
file. The current file offset of the file is left unchanged.

If that syscall doesn't exist (likely if your kernel isn't Linux) it will
be emulated by simply reading the data, which would have a similar effect.


=item aio_stat  $fh_or_path, $callback->($status)

=item aio_lstat $fh, $callback->($status)

Works almost exactly like perl's C<stat> or C<lstat> in void context. The
callback will be called after the stat and the results will be available
using C<stat _> or C<-s _> and other tests (with the exception of C<-B>
and C<-T>).

The pathname passed to C<aio_stat> must be absolute. See API NOTES, above,
for an explanation.

Currently, the stats are always 64-bit-stats, i.e. instead of returning an
error when stat'ing a large file, the results will be silently truncated
unless perl itself is compiled with large file support.

To help interpret the mode and dev/rdev stat values, IO::AIO offers the
following constants and functions (if not implemented, the constants will
be C<0> and the functions will either C<croak> or fall back on traditional
behaviour).

C<S_IFMT>, C<S_IFIFO>, C<S_IFCHR>, C<S_IFBLK>, C<S_IFLNK>, C<S_IFREG>,
C<S_IFDIR>, C<S_IFWHT>, C<S_IFSOCK>, C<IO::AIO::major $dev_t>,
C<IO::AIO::minor $dev_t>, C<IO::AIO::makedev $major, $minor>.

To access higher resolution stat timestamps, see L<SUBSECOND STAT TIME
ACCESS>.

Example: Print the length of F</etc/passwd>:

   aio_stat "/etc/passwd", sub {
      $_[0] and die "stat failed: $!";
      print "size is ", -s _, "\n";
   };


=item aio_statvfs $fh_or_path, $callback->($statvfs)

Works like the POSIX C<statvfs> or C<fstatvfs> syscalls, depending on
whether a file handle or path was passed.

On success, the callback is passed a hash reference with the following
members: C<bsize>, C<frsize>, C<blocks>, C<bfree>, C<bavail>, C<files>,
C<ffree>, C<favail>, C<fsid>, C<flag> and C<namemax>. On failure, C<undef>
is passed.

The following POSIX IO::AIO::ST_* constants are defined: C<ST_RDONLY> and
C<ST_NOSUID>.

The following non-POSIX IO::AIO::ST_* flag masks are defined to
their correct value when available, or to C<0> on systems that do
not support them:  C<ST_NODEV>, C<ST_NOEXEC>, C<ST_SYNCHRONOUS>,
C<ST_MANDLOCK>, C<ST_WRITE>, C<ST_APPEND>, C<ST_IMMUTABLE>, C<ST_NOATIME>,
C<ST_NODIRATIME> and C<ST_RELATIME>.

Example: stat C</wd> and dump out the data if successful.

   aio_statvfs "/wd", sub {
      my $f = $_[0]
         or die "statvfs: $!";

      use Data::Dumper;
      say Dumper $f;
   };

   # result:
   {
      bsize   => 1024,
      bfree   => 4333064312,
      blocks  => 10253828096,
      files   => 2050765568,
      flag    => 4096,
      favail  => 2042092649,
      bavail  => 4333064312,
      ffree   => 2042092649,
      namemax => 255,
      frsize  => 1024,
      fsid    => 1810
   }

=item aio_utime $fh_or_path, $atime, $mtime, $callback->($status)

Works like perl's C<utime> function (including the special case of $atime
and $mtime being undef). Fractional times are supported if the underlying
syscalls support them.

When called with a pathname, uses utimensat(2) or utimes(2) if available,
otherwise utime(2). If called on a file descriptor, uses futimens(2)
or futimes(2) if available, otherwise returns ENOSYS, so this is not
portable.

Examples:

   # set atime and mtime to current time (basically touch(1)):
   aio_utime "path", undef, undef;
   # set atime to current time and mtime to beginning of the epoch:
   aio_utime "path", time, undef; # undef==0


=item aio_chown $fh_or_path, $uid, $gid, $callback->($status)

Works like perl's C<chown> function, except that C<undef> for either $uid
or $gid is being interpreted as "do not change" (but -1 can also be used).

Examples:

   # same as "chown root path" in the shell:
   aio_chown "path", 0, -1;
   # same as above:
   aio_chown "path", 0, undef;


=item aio_truncate $fh_or_path, $offset, $callback->($status)

Works like truncate(2) or ftruncate(2).


=item aio_allocate $fh, $mode, $offset, $len, $callback->($status)

Allocates or frees disk space according to the C<$mode> argument. See the
linux C<fallocate> documentation for details.

C<$mode> is usually C<0> or C<IO::AIO::FALLOC_FL_KEEP_SIZE> to allocate
space, or C<IO::AIO::FALLOC_FL_PUNCH_HOLE | IO::AIO::FALLOC_FL_KEEP_SIZE>,
to deallocate a file range.

IO::AIO also supports C<FALLOC_FL_COLLAPSE_RANGE>, to remove a range
(without leaving a hole), C<FALLOC_FL_ZERO_RANGE>, to zero a range,
C<FALLOC_FL_INSERT_RANGE> to insert a range and C<FALLOC_FL_UNSHARE_RANGE>
to unshare shared blocks (see your L<fallocate(2)> manpage).

The file system block size used by C<fallocate> is presumably the
C<f_bsize> returned by C<statvfs>, but different filesystems and filetypes
can dictate other limitations.

If C<fallocate> isn't available or cannot be emulated (currently no
emulation will be attempted), passes C<-1> and sets C<$!> to C<ENOSYS>.


=item aio_chmod $fh_or_path, $mode, $callback->($status)

Works like perl's C<chmod> function.


=item aio_unlink $pathname, $callback->($status)

Asynchronously unlink (delete) a file and call the callback with the
result code.


=item aio_mknod $pathname, $mode, $dev, $callback->($status)

[EXPERIMENTAL]

Asynchronously create a device node (or fifo). See mknod(2).

The only (POSIX-) portable way of calling this function is:

   aio_mknod $pathname, IO::AIO::S_IFIFO | $mode, 0, sub { ...

See C<aio_stat> for info about some potentially helpful extra constants
and functions.

=item aio_link $srcpath, $dstpath, $callback->($status)

Asynchronously create a new link to the existing object at C<$srcpath> at
the path C<$dstpath> and call the callback with the result code.


=item aio_symlink $srcpath, $dstpath, $callback->($status)

Asynchronously create a new symbolic link to the existing object at C<$srcpath> at
the path C<$dstpath> and call the callback with the result code.


=item aio_readlink $pathname, $callback->($link)

Asynchronously read the symlink specified by C<$path> and pass it to
the callback. If an error occurs, nothing or undef gets passed to the
callback.


=item aio_realpath $pathname, $callback->($path)

Asynchronously make the path absolute and resolve any symlinks in
C<$path>. The resulting path only consists of directories (same as
L<Cwd::realpath>).

This request can be used to get the absolute path of the current working
directory by passing it a path of F<.> (a single dot).


=item aio_rename $srcpath, $dstpath, $callback->($status)

Asynchronously rename the object at C<$srcpath> to C<$dstpath>, just as
rename(2) and call the callback with the result code.

On systems that support the AIO::WD working directory abstraction
natively, the case C<[$wd, "."]> as C<$srcpath> is specialcased - instead
of failing, C<rename> is called on the absolute path of C<$wd>.


=item aio_rename2 $srcpath, $dstpath, $flags, $callback->($status)

Basically a version of C<aio_rename> with an additional C<$flags>
argument. Calling this with C<$flags=0> is the same as calling
C<aio_rename>.

Non-zero flags are currently only supported on GNU/Linux systems that
support renameat2. Other systems fail with C<ENOSYS> in this case.

The following constants are available (missing ones are, as usual C<0>),
see renameat2(2) for details:

C<IO::AIO::RENAME_NOREPLACE>, C<IO::AIO::RENAME_EXCHANGE>
and C<IO::AIO::RENAME_WHITEOUT>.


=item aio_mkdir $pathname, $mode, $callback->($status)

Asynchronously mkdir (create) a directory and call the callback with
the result code. C<$mode> will be modified by the umask at the time the
request is executed, so do not change your umask.


=item aio_rmdir $pathname, $callback->($status)

Asynchronously rmdir (delete) a directory and call the callback with the
result code.

On systems that support the AIO::WD working directory abstraction
natively, the case C<[$wd, "."]> is specialcased - instead of failing,
C<rmdir> is called on the absolute path of C<$wd>.


=item aio_readdir $pathname, $callback->($entries)

Unlike the POSIX call of the same name, C<aio_readdir> reads an entire
directory (i.e. opendir + readdir + closedir). The entries will not be
sorted, and will B<NOT> include the C<.> and C<..> entries.

The callback is passed a single argument which is either C<undef> or an
array-ref with the filenames.


=item aio_readdirx $pathname, $flags, $callback->($entries, $flags)

Quite similar to C<aio_readdir>, but the C<$flags> argument allows one to
tune behaviour and output format. In case of an error, C<$entries> will be
C<undef>.

The flags are a combination of the following constants, ORed together (the
flags will also be passed to the callback, possibly modified):

=over 4

=item IO::AIO::READDIR_DENTS

Normally the callback gets an arrayref consisting of names only (as
with C<aio_readdir>). If this flag is set, then the callback gets an
arrayref with C<[$name, $type, $inode]> arrayrefs, each describing a
single directory entry in more detail:

C<$name> is the name of the entry.

C<$type> is one of the C<IO::AIO::DT_xxx> constants:

C<IO::AIO::DT_UNKNOWN>, C<IO::AIO::DT_FIFO>, C<IO::AIO::DT_CHR>, C<IO::AIO::DT_DIR>,
C<IO::AIO::DT_BLK>, C<IO::AIO::DT_REG>, C<IO::AIO::DT_LNK>, C<IO::AIO::DT_SOCK>,
C<IO::AIO::DT_WHT>.

C<IO::AIO::DT_UNKNOWN> means just that: readdir does not know. If you need
to know, you have to run stat yourself. Also, for speed/memory reasons,
the C<$type> scalars are read-only: you must not modify them.

C<$inode> is the inode number (which might not be exact on systems with 64
bit inode numbers and 32 bit perls). This field has unspecified content on
systems that do not deliver the inode information.

=item IO::AIO::READDIR_DIRS_FIRST

When this flag is set, then the names will be returned in an order where
likely directories come first, in optimal stat order. This is useful when
you need to quickly find directories, or you want to find all directories
while avoiding to stat() each entry.

If the system returns type information in readdir, then this is used
to find directories directly. Otherwise, likely directories are names
beginning with ".", or otherwise names with no dots, of which names with
short names are tried first.

=item IO::AIO::READDIR_STAT_ORDER

When this flag is set, then the names will be returned in an order
suitable for stat()'ing each one. That is, when you plan to stat() most or
all files in the given directory, then the returned order will likely be
faster.

If both this flag and C<IO::AIO::READDIR_DIRS_FIRST> are specified,
then the likely dirs come first, resulting in a less optimal stat order
for stat'ing all entries, but likely a more optimal order for finding
subdirectories.

=item IO::AIO::READDIR_FOUND_UNKNOWN

This flag should not be set when calling C<aio_readdirx>. Instead, it
is being set by C<aio_readdirx>, when any of the C<$type>'s found were
C<IO::AIO::DT_UNKNOWN>. The absence of this flag therefore indicates that all
C<$type>'s are known, which can be used to speed up some algorithms.

=back


=item aio_slurp $pathname, $offset, $length, $data, $callback->($status)

Opens, reads and closes the given file. The data is put into C<$data>,
which is resized as required.

If C<$offset> is negative, then it is counted from the end of the file.

If C<$length> is zero, then the remaining length of the file is
used. Also, in this case, the same limitations to modifying C<$data> apply
as when IO::AIO::mmap is used, i.e. it must only be modified in-place
with C<substr>. If the size of the file is known, specifying a non-zero
C<$length> results in a performance advantage.

This request is similar to the older C<aio_load> request, but since it is
a single request, it might be more efficient to use.

Example: load F</etc/passwd> into C<$passwd>.

   my $passwd;
   aio_slurp "/etc/passwd", 0, 0, $passwd, sub {
      $_[0] >= 0
         or die "/etc/passwd: $!\n";

      printf "/etc/passwd is %d bytes long, and contains:\n", length $passwd;
      print $passwd;
   };
   IO::AIO::flush;


=item aio_load $pathname, $data, $callback->($status)

This is a composite request that tries to fully load the given file into
memory. Status is the same as with aio_read.

Using C<aio_slurp> might be more efficient, as it is a single request.

=cut

sub aio_load($$;$) {
   my ($path, undef, $cb) = @_;
   my $data = \$_[1];

   my $pri = aioreq_pri;
   my $grp = aio_group $cb;

   aioreq_pri $pri;
   add $grp aio_open $path, O_RDONLY, 0, sub {
      my $fh = shift
         or return $grp->result (-1);

      aioreq_pri $pri;
      add $grp aio_read $fh, 0, (-s $fh), $$data, 0, sub {
         $grp->result ($_[0]);
      };
   };

   $grp
}

=item aio_copy $srcpath, $dstpath, $callback->($status)

Try to copy the I<file> (directories not supported as either source or
destination) from C<$srcpath> to C<$dstpath> and call the callback with
a status of C<0> (ok) or C<-1> (error, see C<$!>).

Existing destination files will be truncated.

This is a composite request that creates the destination file with
mode 0200 and copies the contents of the source file into it using
C<aio_sendfile>, followed by restoring atime, mtime, access mode and
uid/gid, in that order.

If an error occurs, the partial destination file will be unlinked, if
possible, except when setting atime, mtime, access mode and uid/gid, where
errors are being ignored.

=cut

sub aio_copy($$;$) {
   my ($src, $dst, $cb) = @_;

   my $pri = aioreq_pri;
   my $grp = aio_group $cb;

   aioreq_pri $pri;
   add $grp aio_open $src, O_RDONLY, 0, sub {
      if (my $src_fh = $_[0]) {
         my @stat = stat $src_fh; # hmm, might block over nfs?

         aioreq_pri $pri;
         add $grp aio_open $dst, O_CREAT | O_WRONLY | O_TRUNC, 0200, sub {
            if (my $dst_fh = $_[0]) {
               aioreq_pri $pri;
               add $grp aio_sendfile $dst_fh, $src_fh, 0, $stat[7], sub {
                  if ($_[0] == $stat[7]) {
                     $grp->result (0);
                     close $src_fh;

                     my $ch = sub {
                        aioreq_pri $pri;
                        add $grp aio_chmod $dst_fh, $stat[2] & 07777, sub {
                           aioreq_pri $pri;
                           add $grp aio_chown $dst_fh, $stat[4], $stat[5], sub {
                              aioreq_pri $pri;
                              add $grp aio_close $dst_fh;
                           }
                        };
                     };

                     aioreq_pri $pri;
                     add $grp aio_utime $dst_fh, $stat[8], $stat[9], sub {
                        if ($_[0] < 0 && $! == ENOSYS) {
                           aioreq_pri $pri;
                           add $grp aio_utime $dst, $stat[8], $stat[9], $ch;
                        } else {
                           $ch->();
                        }
                     };
                  } else {
                     $grp->result (-1);
                     close $src_fh;
                     close $dst_fh;

                     aioreq $pri;
                     add $grp aio_unlink $dst;
                  }
               };
            } else {
               $grp->result (-1);
            }
         },

      } else {
         $grp->result (-1);
      }
   };

   $grp
}

=item aio_move $srcpath, $dstpath, $callback->($status)

Try to move the I<file> (directories not supported as either source or
destination) from C<$srcpath> to C<$dstpath> and call the callback with
a status of C<0> (ok) or C<-1> (error, see C<$!>).

This is a composite request that tries to rename(2) the file first; if
rename fails with C<EXDEV>, it copies the file with C<aio_copy> and, if
that is successful, unlinks the C<$srcpath>.

=cut

sub aio_move($$;$) {
   my ($src, $dst, $cb) = @_;

   my $pri = aioreq_pri;
   my $grp = aio_group $cb;

   aioreq_pri $pri;
   add $grp aio_rename $src, $dst, sub {
      if ($_[0] && $! == EXDEV) {
         aioreq_pri $pri;
         add $grp aio_copy $src, $dst, sub {
            $grp->result ($_[0]);

            unless ($_[0]) {
               aioreq_pri $pri;
               add $grp aio_unlink $src;
            }
         };
      } else {
         $grp->result ($_[0]);
      }
   };

   $grp
}

=item aio_scandir $pathname, $maxreq, $callback->($dirs, $nondirs)

Scans a directory (similar to C<aio_readdir>) but additionally tries to
efficiently separate the entries of directory C<$path> into two sets of
names, directories you can recurse into (directories), and ones you cannot
recurse into (everything else, including symlinks to directories).

C<aio_scandir> is a composite request that generates many sub requests.
C<$maxreq> specifies the maximum number of outstanding aio requests that
this function generates. If it is C<< <= 0 >>, then a suitable default
will be chosen (currently 4).

On error, the callback is called without arguments, otherwise it receives
two array-refs with path-relative entry names.

Example:

   aio_scandir $dir, 0, sub {
      my ($dirs, $nondirs) = @_;
      print "real directories: @$dirs\n";
      print "everything else: @$nondirs\n";
   };

Implementation notes.

The C<aio_readdir> cannot be avoided, but C<stat()>'ing every entry can.

If readdir returns file type information, then this is used directly to
find directories.

Otherwise, after reading the directory, the modification time, size etc.
of the directory before and after the readdir is checked, and if they
match (and isn't the current time), the link count will be used to decide
how many entries are directories (if >= 2). Otherwise, no knowledge of the
number of subdirectories will be assumed.

Then entries will be sorted into likely directories a non-initial dot
currently) and likely non-directories (see C<aio_readdirx>). Then every
entry plus an appended C</.> will be C<stat>'ed, likely directories first,
in order of their inode numbers. If that succeeds, it assumes that the
entry is a directory or a symlink to directory (which will be checked
separately). This is often faster than stat'ing the entry itself because
filesystems might detect the type of the entry without reading the inode
data (e.g. ext2fs filetype feature), even on systems that cannot return
the filetype information on readdir.

If the known number of directories (link count - 2) has been reached, the
rest of the entries is assumed to be non-directories.

This only works with certainty on POSIX (= UNIX) filesystems, which
fortunately are the vast majority of filesystems around.

It will also likely work on non-POSIX filesystems with reduced efficiency
as those tend to return 0 or 1 as link counts, which disables the
directory counting heuristic.

=cut

sub aio_scandir($$;$) {
   my ($path, $maxreq, $cb) = @_;

   my $pri = aioreq_pri;

   my $grp = aio_group $cb;

   $maxreq = 4 if $maxreq <= 0;

   # get a wd object
   aioreq_pri $pri;
   add $grp aio_wd $path, sub {
      $_[0]
         or return $grp->result ();

      my $wd = [shift, "."];

      # stat once
      aioreq_pri $pri;
      add $grp aio_stat $wd, sub {
         return $grp->result () if $_[0];
         my $now = time;
         my $hash1 = join ":", (stat _)[0,1,3,7,9];
         my $rdxflags = READDIR_DIRS_FIRST;

         if ((stat _)[3] < 2) {
            # at least one non-POSIX filesystem exists
            # that returns useful DT_type values: btrfs,
            # so optimise for this here by requesting dents
            $rdxflags |= READDIR_DENTS;
         }

         # read the directory entries
         aioreq_pri $pri;
         add $grp aio_readdirx $wd, $rdxflags, sub {
            my ($entries, $flags) = @_
               or return $grp->result ();

            if ($rdxflags & READDIR_DENTS) {
               # if we requested type values, see if we can use them directly.

               # if there were any DT_UNKNOWN entries then we assume we
               # don't know. alternatively, we could assume that if we get
               # one DT_DIR, then all directories are indeed marked with
               # DT_DIR, but this seems not required for btrfs, and this
               # is basically the "btrfs can't get it's act together" code
               # branch.
               unless ($flags & READDIR_FOUND_UNKNOWN) {
                  # now we have valid DT_ information for all entries,
                  # so use it as an optimisation without further stat's.
                  # they must also all be at the beginning of @$entries
                  # by now.

                  my $dirs;

                  if (@$entries) {
                     for (0 .. $#$entries) {
                        if ($entries->[$_][1] != DT_DIR) {
                           # splice out directories
                           $dirs = [splice @$entries, 0, $_];
                           last;
                        }
                     }

                     # if we didn't find any non-dir, then all entries are dirs
                     unless ($dirs) {
                        ($dirs, $entries) = ($entries, []);
                     }
                  } else {
                     # directory is empty, so there are no sbdirs
                     $dirs = [];
                  }

                  # either splice'd the directories out or the dir was empty.
                  # convert dents to filenames
                  $_ = $_->[0] for @$dirs;
                  $_ = $_->[0] for @$entries;

                  return $grp->result ($dirs, $entries);
               }

               # cannot use, so return to our old ways
               # by pretending we only scanned for names.
               $_ = $_->[0] for @$entries;
            }

            # stat the dir another time
            aioreq_pri $pri;
            add $grp aio_stat $wd, sub {
               my $hash2 = join ":", (stat _)[0,1,3,7,9];

               my $ndirs;

               # take the slow route if anything looks fishy
               if ($hash1 ne $hash2 or (stat _)[9] == $now) {
                  $ndirs = -1;
               } else {
                  # if nlink == 2, we are finished
                  # for non-posix-fs's, we rely on nlink < 2
                  $ndirs = (stat _)[3] - 2
                     or return $grp->result ([], $entries);
               }

               my (@dirs, @nondirs);

               my $statgrp = add $grp aio_group sub {
                  $grp->result (\@dirs, \@nondirs);
               };

               limit $statgrp $maxreq;
               feed $statgrp sub {
                  return unless @$entries;
                  my $entry = shift @$entries;

                  aioreq_pri $pri;
                  $wd->[1] = "$entry/.";
                  add $statgrp aio_stat $wd, sub {
                     if ($_[0] < 0) {
                        push @nondirs, $entry;
                     } else {
                        # need to check for real directory
                        aioreq_pri $pri;
                        $wd->[1] = $entry;
                        add $statgrp aio_lstat $wd, sub {
                           if (-d _) {
                              push @dirs, $entry;

                              unless (--$ndirs) {
                                 push @nondirs, @$entries;
                                 feed $statgrp;
                              }
                           } else {
                              push @nondirs, $entry;
                           }
                        }
                     }
                  };
               };
            };
         };
      };
   };

   $grp
}

=item aio_rmtree $pathname, $callback->($status)

Delete a directory tree starting (and including) C<$path>, return the
status of the final C<rmdir> only. This is a composite request that
uses C<aio_scandir> to recurse into and rmdir directories, and unlink
everything else.

=cut

sub aio_rmtree;
sub aio_rmtree($;$) {
   my ($path, $cb) = @_;

   my $pri = aioreq_pri;
   my $grp = aio_group $cb;

   aioreq_pri $pri;
   add $grp aio_scandir $path, 0, sub {
      my ($dirs, $nondirs) = @_;

      my $dirgrp = aio_group sub {
         add $grp aio_rmdir $path, sub {
            $grp->result ($_[0]);
         };
      };

      (aioreq_pri $pri), add $dirgrp aio_rmtree "$path/$_" for @$dirs;
      (aioreq_pri $pri), add $dirgrp aio_unlink "$path/$_" for @$nondirs;

      add $grp $dirgrp;
   };

   $grp
}

=item aio_fcntl $fh, $cmd, $arg, $callback->($status)

=item aio_ioctl $fh, $request, $buf, $callback->($status)

These work just like the C<fcntl> and C<ioctl> built-in functions, except
they execute asynchronously and pass the return value to the callback.

Both calls can be used for a lot of things, some of which make more sense
to run asynchronously in their own thread, while some others make less
sense. For example, calls that block waiting for external events, such
as locking, will also lock down an I/O thread while it is waiting, which
can deadlock the whole I/O system. At the same time, there might be no
alternative to using a thread to wait.

So in general, you should only use these calls for things that do
(filesystem) I/O, not for things that wait for other events (network,
other processes), although if you are careful and know what you are doing,
you still can.

The following constants are available and can be used for normal C<ioctl>
and C<fcntl> as well (missing ones are, as usual C<0>):

C<F_DUPFD_CLOEXEC>,

C<F_OFD_GETLK>, C<F_OFD_SETLK>, C<F_OFD_GETLKW>,

C<FIFREEZE>, C<FITHAW>, C<FITRIM>, C<FICLONE>, C<FICLONERANGE>, C<FIDEDUPERANGE>.

C<F_ADD_SEALS>, C<F_GET_SEALS>, C<F_SEAL_SEAL>, C<F_SEAL_SHRINK>, C<F_SEAL_GROW> and
C<F_SEAL_WRITE>.

C<FS_IOC_GETFLAGS>, C<FS_IOC_SETFLAGS>, C<FS_IOC_GETVERSION>, C<FS_IOC_SETVERSION>,
C<FS_IOC_FIEMAP>.

C<FS_IOC_FSGETXATTR>, C<FS_IOC_FSSETXATTR>, C<FS_IOC_SET_ENCRYPTION_POLICY>,
C<FS_IOC_GET_ENCRYPTION_PWSALT>, C<FS_IOC_GET_ENCRYPTION_POLICY>, C<FS_KEY_DESCRIPTOR_SIZE>.

C<FS_SECRM_FL>, C<FS_UNRM_FL>, C<FS_COMPR_FL>, C<FS_SYNC_FL>, C<FS_IMMUTABLE_FL>,
C<FS_APPEND_FL>, C<FS_NODUMP_FL>, C<FS_NOATIME_FL>, C<FS_DIRTY_FL>,
C<FS_COMPRBLK_FL>, C<FS_NOCOMP_FL>, C<FS_ENCRYPT_FL>, C<FS_BTREE_FL>,
C<FS_INDEX_FL>, C<FS_JOURNAL_DATA_FL>, C<FS_NOTAIL_FL>, C<FS_DIRSYNC_FL>, C<FS_TOPDIR_FL>,
C<FS_FL_USER_MODIFIABLE>.

C<FS_XFLAG_REALTIME>, C<FS_XFLAG_PREALLOC>, C<FS_XFLAG_IMMUTABLE>, C<FS_XFLAG_APPEND>,
C<FS_XFLAG_SYNC>, C<FS_XFLAG_NOATIME>, C<FS_XFLAG_NODUMP>, C<FS_XFLAG_RTINHERIT>,
C<FS_XFLAG_PROJINHERIT>, C<FS_XFLAG_NOSYMLINKS>, C<FS_XFLAG_EXTSIZE>, C<FS_XFLAG_EXTSZINHERIT>,
C<FS_XFLAG_NODEFRAG>, C<FS_XFLAG_FILESTREAM>, C<FS_XFLAG_DAX>, C<FS_XFLAG_HASATTR>,

=item aio_sync $callback->($status)

Asynchronously call sync and call the callback when finished.

=item aio_fsync $fh, $callback->($status)

Asynchronously call fsync on the given filehandle and call the callback
with the fsync result code.

=item aio_fdatasync $fh, $callback->($status)

Asynchronously call fdatasync on the given filehandle and call the
callback with the fdatasync result code.

If this call isn't available because your OS lacks it or it couldn't be
detected, it will be emulated by calling C<fsync> instead.

=item aio_syncfs $fh, $callback->($status)

Asynchronously call the syncfs syscall to sync the filesystem associated
to the given filehandle and call the callback with the syncfs result
code. If syncfs is not available, calls sync(), but returns C<-1> and sets
errno to C<ENOSYS> nevertheless.

=item aio_sync_file_range $fh, $offset, $nbytes, $flags, $callback->($status)

Sync the data portion of the file specified by C<$offset> and C<$length>
to disk (but NOT the metadata), by calling the Linux-specific
sync_file_range call. If sync_file_range is not available or it returns
ENOSYS, then fdatasync or fsync is being substituted.

C<$flags> can be a combination of C<IO::AIO::SYNC_FILE_RANGE_WAIT_BEFORE>,
C<IO::AIO::SYNC_FILE_RANGE_WRITE> and
C<IO::AIO::SYNC_FILE_RANGE_WAIT_AFTER>: refer to the sync_file_range
manpage for details.

=item aio_pathsync $pathname, $callback->($status)

This request tries to open, fsync and close the given path. This is a
composite request intended to sync directories after directory operations
(E.g. rename). This might not work on all operating systems or have any
specific effect, but usually it makes sure that directory changes get
written to disc. It works for anything that can be opened for read-only,
not just directories.

Future versions of this function might fall back to other methods when
C<fsync> on the directory fails (such as calling C<sync>).

Passes C<0> when everything went ok, and C<-1> on error.

=cut

sub aio_pathsync($;$) {
   my ($path, $cb) = @_;

   my $pri = aioreq_pri;
   my $grp = aio_group $cb;

   aioreq_pri $pri;
   add $grp aio_open $path, O_RDONLY, 0, sub {
      my ($fh) = @_;
      if ($fh) {
         aioreq_pri $pri;
         add $grp aio_fsync $fh, sub {
            $grp->result ($_[0]);

            aioreq_pri $pri;
            add $grp aio_close $fh;
         };
      } else {
         $grp->result (-1);
      }
   };

   $grp
}

=item aio_msync $scalar, $offset = 0, $length = undef, flags = MS_SYNC, $callback->($status)

This is a rather advanced IO::AIO call, which only works on mmap(2)ed
scalars (see the C<IO::AIO::mmap> function, although it also works on data
scalars managed by the L<Sys::Mmap> or L<Mmap> modules, note that the
scalar must only be modified in-place while an aio operation is pending on
it).

It calls the C<msync> function of your OS, if available, with the memory
area starting at C<$offset> in the string and ending C<$length> bytes
later. If C<$length> is negative, counts from the end, and if C<$length>
is C<undef>, then it goes till the end of the string. The flags can be
either C<IO::AIO::MS_ASYNC> or C<IO::AIO::MS_SYNC>, plus an optional
C<IO::AIO::MS_INVALIDATE>.

=item aio_mtouch $scalar, $offset = 0, $length = undef, flags = 0, $callback->($status)

This is a rather advanced IO::AIO call, which works best on mmap(2)ed
scalars.

It touches (reads or writes) all memory pages in the specified
range inside the scalar. All caveats and parameters are the same
as for C<aio_msync>, above, except for flags, which must be either
C<0> (which reads all pages and ensures they are instantiated) or
C<IO::AIO::MT_MODIFY>, which modifies the memory pages (by reading and
writing an octet from it, which dirties the page).

=item aio_mlock $scalar, $offset = 0, $length = undef, $callback->($status)

This is a rather advanced IO::AIO call, which works best on mmap(2)ed
scalars.

It reads in all the pages of the underlying storage into memory (if any)
and locks them, so they are not getting swapped/paged out or removed.

If C<$length> is undefined, then the scalar will be locked till the end.

On systems that do not implement C<mlock>, this function returns C<-1>
and sets errno to C<ENOSYS>.

Note that the corresponding C<munlock> is synchronous and is
documented under L<MISCELLANEOUS FUNCTIONS>.

Example: open a file, mmap and mlock it - both will be undone when
C<$data> gets destroyed.

   open my $fh, "<", $path or die "$path: $!";
   my $data;
   IO::AIO::mmap $data, -s $fh, IO::AIO::PROT_READ, IO::AIO::MAP_SHARED, $fh;
   aio_mlock $data; # mlock in background

=item aio_mlockall $flags, $callback->($status)

Calls the C<mlockall> function with the given C<$flags> (a
combination of C<IO::AIO::MCL_CURRENT>, C<IO::AIO::MCL_FUTURE> and
C<IO::AIO::MCL_ONFAULT>).

On systems that do not implement C<mlockall>, this function returns C<-1>
and sets errno to C<ENOSYS>. Similarly, flag combinations not supported
by the system result in a return value of C<-1> with errno being set to
C<EINVAL>.

Note that the corresponding C<munlockall> is synchronous and is
documented under L<MISCELLANEOUS FUNCTIONS>.

Example: asynchronously lock all current and future pages into memory.

   aio_mlockall IO::AIO::MCL_FUTURE;

=item aio_fiemap $fh, $start, $length, $flags, $count, $cb->(\@extents)

Queries the extents of the given file (by calling the Linux C<FIEMAP>
ioctl, see L<http://cvs.schmorp.de/IO-AIO/doc/fiemap.txt> for details). If
the ioctl is not available on your OS, then this request will fail with
C<ENOSYS>.

C<$start> is the starting offset to query extents for, C<$length> is the
size of the range to query - if it is C<undef>, then the whole file will
be queried.

C<$flags> is a combination of flags (C<IO::AIO::FIEMAP_FLAG_SYNC> or
C<IO::AIO::FIEMAP_FLAG_XATTR> - C<IO::AIO::FIEMAP_FLAGS_COMPAT> is also
exported), and is normally C<0> or C<IO::AIO::FIEMAP_FLAG_SYNC> to query
the data portion.

C<$count> is the maximum number of extent records to return. If it is
C<undef>, then IO::AIO queries all extents of the range. As a very special
case, if it is C<0>, then the callback receives the number of extents
instead of the extents themselves (which is unreliable, see below).

If an error occurs, the callback receives no arguments. The special
C<errno> value C<IO::AIO::EBADR> is available to test for flag errors.

Otherwise, the callback receives an array reference with extent
structures. Each extent structure is an array reference itself, with the
following members:

   [$logical, $physical, $length, $flags]

Flags is any combination of the following flag values (typically either C<0>
or C<IO::AIO::FIEMAP_EXTENT_LAST> (1)):

C<IO::AIO::FIEMAP_EXTENT_LAST>, C<IO::AIO::FIEMAP_EXTENT_UNKNOWN>,
C<IO::AIO::FIEMAP_EXTENT_DELALLOC>, C<IO::AIO::FIEMAP_EXTENT_ENCODED>,
C<IO::AIO::FIEMAP_EXTENT_DATA_ENCRYPTED>, C<IO::AIO::FIEMAP_EXTENT_NOT_ALIGNED>,
C<IO::AIO::FIEMAP_EXTENT_DATA_INLINE>, C<IO::AIO::FIEMAP_EXTENT_DATA_TAIL>,
C<IO::AIO::FIEMAP_EXTENT_UNWRITTEN>, C<IO::AIO::FIEMAP_EXTENT_MERGED> or
C<IO::AIO::FIEMAP_EXTENT_SHARED>.

At the time of this writing (Linux 3.2), this request is unreliable unless
C<$count> is C<undef>, as the kernel has all sorts of bugs preventing
it to return all extents of a range for files with a large number of
extents. The code (only) works around all these issues if C<$count> is
C<undef>.

=item aio_group $callback->(...)

This is a very special aio request: Instead of doing something, it is a
container for other aio requests, which is useful if you want to bundle
many requests into a single, composite, request with a definite callback
and the ability to cancel the whole request with its subrequests.

Returns an object of class L<IO::AIO::GRP>. See its documentation below
for more info.

Example:

   my $grp = aio_group sub {
      print "all stats done\n";
   };

   add $grp
      (aio_stat ...),
      (aio_stat ...),
      ...;

=item aio_nop $callback->()

This is a special request - it does nothing in itself and is only used for
side effects, such as when you want to add a dummy request to a group so
that finishing the requests in the group depends on executing the given
code.

While this request does nothing, it still goes through the execution
phase and still requires a worker thread. Thus, the callback will not
be executed immediately but only after other requests in the queue have
entered their execution phase. This can be used to measure request
latency.

=item IO::AIO::aio_busy $fractional_seconds, $callback->()  *NOT EXPORTED*

Mainly used for debugging and benchmarking, this aio request puts one of
the request workers to sleep for the given time.

While it is theoretically handy to have simple I/O scheduling requests
like sleep and file handle readable/writable, the overhead this creates is
immense (it blocks a thread for a long time) so do not use this function
except to put your application under artificial I/O pressure.

=back


=head2 IO::AIO::WD - multiple working directories

Your process only has one current working directory, which is used by all
threads. This makes it hard to use relative paths (some other component
could call C<chdir> at any time, and it is hard to control when the path
will be used by IO::AIO).

One solution for this is to always use absolute paths. This usually works,
but can be quite slow (the kernel has to walk the whole path on every
access), and can also be a hassle to implement.

Newer POSIX systems have a number of functions (openat, fdopendir,
futimensat and so on) that make it possible to specify working directories
per operation.

For portability, and because the clowns who "designed", or shall I write,
perpetrated this new interface were obviously half-drunk, this abstraction
cannot be perfect, though.

IO::AIO allows you to convert directory paths into a so-called IO::AIO::WD
object. This object stores the canonicalised, absolute version of the
path, and on systems that allow it, also a directory file descriptor.

Everywhere where a pathname is accepted by IO::AIO (e.g. in C<aio_stat>
or C<aio_unlink>), one can specify an array reference with an IO::AIO::WD
object and a pathname instead (or the IO::AIO::WD object alone, which
gets interpreted as C<[$wd, "."]>). If the pathname is absolute, the
IO::AIO::WD object is ignored, otherwise the pathname is resolved relative
to that IO::AIO::WD object.

For example, to get a wd object for F</etc> and then stat F<passwd>
inside, you would write:

   aio_wd "/etc", sub {
      my $etcdir = shift;

      # although $etcdir can be undef on error, there is generally no reason
      # to check for errors here, as aio_stat will fail with ENOENT
      # when $etcdir is undef.

      aio_stat [$etcdir, "passwd"], sub {
         # yay
      };
   };

The fact that C<aio_wd> is a request and not a normal function shows that
creating an IO::AIO::WD object is itself a potentially blocking operation,
which is why it is done asynchronously.

To stat the directory obtained with C<aio_wd> above, one could write
either of the following three request calls:

   aio_lstat "/etc"    , sub { ...  # pathname as normal string
   aio_lstat [$wd, "."], sub { ...  # "." relative to $wd (i.e. $wd itself)
   aio_lstat $wd       , sub { ...  # shorthand for the previous

As with normal pathnames, IO::AIO keeps a copy of the working directory
object and the pathname string, so you could write the following without
causing any issues due to C<$path> getting reused:

   my $path = [$wd, undef];

   for my $name (qw(abc def ghi)) {
      $path->[1] = $name;
      aio_stat $path, sub {
         # ...
      };
   }

There are some caveats: when directories get renamed (or deleted), the
pathname string doesn't change, so will point to the new directory (or
nowhere at all), while the directory fd, if available on the system,
will still point to the original directory. Most functions accepting a
pathname will use the directory fd on newer systems, and the string on
older systems. Some functions (such as C<aio_realpath>) will always rely on
the string form of the pathname.

So this functionality is mainly useful to get some protection against
C<chdir>, to easily get an absolute path out of a relative path for future
reference, and to speed up doing many operations in the same directory
(e.g. when stat'ing all files in a directory).

The following functions implement this working directory abstraction:

=over 4

=item aio_wd $pathname, $callback->($wd)

Asynchonously canonicalise the given pathname and convert it to an
IO::AIO::WD object representing it. If possible and supported on the
system, also open a directory fd to speed up pathname resolution relative
to this working directory.

If something goes wrong, then C<undef> is passwd to the callback instead
of a working directory object and C<$!> is set appropriately. Since
passing C<undef> as working directory component of a pathname fails the
request with C<ENOENT>, there is often no need for error checking in the
C<aio_wd> callback, as future requests using the value will fail in the
expected way.

=item IO::AIO::CWD

This is a compile time constant (object) that represents the process
current working directory.

Specifying this object as working directory object for a pathname is as if
the pathname would be specified directly, without a directory object. For
example, these calls are functionally identical:

   aio_stat "somefile", sub { ... };
   aio_stat [IO::AIO::CWD, "somefile"], sub { ... };

=back

To recover the path associated with an IO::AIO::WD object, you can use
C<aio_realpath>:

   aio_realpath $wd, sub {
      warn "path is $_[0]\n";
   };

Currently, C<aio_statvfs> always, and C<aio_rename> and C<aio_rmdir>
sometimes, fall back to using an absolue path.

=head2 IO::AIO::REQ CLASS

All non-aggregate C<aio_*> functions return an object of this class when
called in non-void context.

=over 4

=item cancel $req

Cancels the request, if possible. Has the effect of skipping execution
when entering the B<execute> state and skipping calling the callback when
entering the the B<result> state, but will leave the request otherwise
untouched (with the exception of readdir). That means that requests that
currently execute will not be stopped and resources held by the request
will not be freed prematurely.

=item cb $req $callback->(...)

Replace (or simply set) the callback registered to the request.

=back

=head2 IO::AIO::GRP CLASS

This class is a subclass of L<IO::AIO::REQ>, so all its methods apply to
objects of this class, too.

A IO::AIO::GRP object is a special request that can contain multiple other
aio requests.

You create one by calling the C<aio_group> constructing function with a
callback that will be called when all contained requests have entered the
C<done> state:

   my $grp = aio_group sub {
      print "all requests are done\n";
   };

You add requests by calling the C<add> method with one or more
C<IO::AIO::REQ> objects:

   $grp->add (aio_unlink "...");

   add $grp aio_stat "...", sub {
      $_[0] or return $grp->result ("error");

      # add another request dynamically, if first succeeded
      add $grp aio_open "...", sub {
         $grp->result ("ok");
      };
   };

This makes it very easy to create composite requests (see the source of
C<aio_move> for an application) that work and feel like simple requests.

=over 4

=item * The IO::AIO::GRP objects will be cleaned up during calls to
C<IO::AIO::poll_cb>, just like any other request.

=item * They can be canceled like any other request. Canceling will cancel not
only the request itself, but also all requests it contains.

=item * They can also can also be added to other IO::AIO::GRP objects.

=item * You must not add requests to a group from within the group callback (or
any later time).

=back

Their lifetime, simplified, looks like this: when they are empty, they
will finish very quickly. If they contain only requests that are in the
C<done> state, they will also finish. Otherwise they will continue to
exist.

That means after creating a group you have some time to add requests
(precisely before the callback has been invoked, which is only done within
the C<poll_cb>). And in the callbacks of those requests, you can add
further requests to the group. And only when all those requests have
finished will the the group itself finish.

=over 4

=item add $grp ...

=item $grp->add (...)

Add one or more requests to the group. Any type of L<IO::AIO::REQ> can
be added, including other groups, as long as you do not create circular
dependencies.

Returns all its arguments.

=item $grp->cancel_subs

Cancel all subrequests and clears any feeder, but not the group request
itself. Useful when you queued a lot of events but got a result early.

The group request will finish normally (you cannot add requests to the
group).

=item $grp->result (...)

Set the result value(s) that will be passed to the group callback when all
subrequests have finished and set the groups errno to the current value
of errno (just like calling C<errno> without an error number). By default,
no argument will be passed and errno is zero.

=item $grp->errno ([$errno])

Sets the group errno value to C<$errno>, or the current value of errno
when the argument is missing.

Every aio request has an associated errno value that is restored when
the callback is invoked. This method lets you change this value from its
default (0).

Calling C<result> will also set errno, so make sure you either set C<$!>
before the call to C<result>, or call c<errno> after it.

=item feed $grp $callback->($grp)

Sets a feeder/generator on this group: every group can have an attached
generator that generates requests if idle. The idea behind this is that,
although you could just queue as many requests as you want in a group,
this might starve other requests for a potentially long time. For example,
C<aio_scandir> might generate hundreds of thousands of C<aio_stat>
requests, delaying any later requests for a long time.

To avoid this, and allow incremental generation of requests, you can
instead a group and set a feeder on it that generates those requests. The
feed callback will be called whenever there are few enough (see C<limit>,
below) requests active in the group itself and is expected to queue more
requests.

The feed callback can queue as many requests as it likes (i.e. C<add> does
not impose any limits).

If the feed does not queue more requests when called, it will be
automatically removed from the group.

If the feed limit is C<0> when this method is called, it will be set to
C<2> automatically.

Example:

   # stat all files in @files, but only ever use four aio requests concurrently:

   my $grp = aio_group sub { print "finished\n" };
   limit $grp 4;
   feed $grp sub {
      my $file = pop @files
         or return;

      add $grp aio_stat $file, sub { ... };
   };

=item limit $grp $num

Sets the feeder limit for the group: The feeder will be called whenever
the group contains less than this many requests.

Setting the limit to C<0> will pause the feeding process.

The default value for the limit is C<0>, but note that setting a feeder
automatically bumps it up to C<2>.

=back


=head2 SUPPORT FUNCTIONS

=head3 EVENT PROCESSING AND EVENT LOOP INTEGRATION

=over 4

=item $fileno = IO::AIO::poll_fileno

Return the I<request result pipe file descriptor>. This filehandle must be
polled for reading by some mechanism outside this module (e.g. EV, Glib,
select and so on, see below or the SYNOPSIS). If the pipe becomes readable
you have to call C<poll_cb> to check the results.

See C<poll_cb> for an example.

=item IO::AIO::poll_cb

Process some requests that have reached the result phase (i.e. they have
been executed but the results are not yet reported). You have to call
this "regularly" to finish outstanding requests.

Returns C<0> if all events could be processed (or there were no
events to process), or C<-1> if it returned earlier for whatever
reason. Returns immediately when no events are outstanding. The amount
of events processed depends on the settings of C<IO::AIO::max_poll_req>,
C<IO::AIO::max_poll_time> and C<IO::AIO::max_outstanding>.

If not all requests were processed for whatever reason, the poll file
descriptor will still be ready when C<poll_cb> returns, so normally you
don't have to do anything special to have it called later.

Apart from calling C<IO::AIO::poll_cb> when the event filehandle becomes
ready, it can be beneficial to call this function from loops which submit
a lot of requests, to make sure the results get processed when they become
available and not just when the loop is finished and the event loop takes
over again. This function returns very fast when there are no outstanding
requests.

Example: Install an Event watcher that automatically calls
IO::AIO::poll_cb with high priority (more examples can be found in the
SYNOPSIS section, at the top of this document):

   Event->io (fd => IO::AIO::poll_fileno,
              poll => 'r', async => 1,
              cb => \&IO::AIO::poll_cb);

=item IO::AIO::poll_wait

Wait until either at least one request is in the result phase or no
requests are outstanding anymore.

This is useful if you want to synchronously wait for some requests to
become ready, without actually handling them.

See C<nreqs> for an example.

=item IO::AIO::poll

Waits until some requests have been handled.

Returns the number of requests processed, but is otherwise strictly
equivalent to:

   IO::AIO::poll_wait, IO::AIO::poll_cb

=item IO::AIO::flush

Wait till all outstanding AIO requests have been handled.

Strictly equivalent to:

   IO::AIO::poll_wait, IO::AIO::poll_cb
      while IO::AIO::nreqs;

This function can be useful at program aborts, to make sure outstanding
I/O has been done (C<IO::AIO> uses an C<END> block which already calls
this function on normal exits), or when you are merely using C<IO::AIO>
for its more advanced functions, rather than for async I/O, e.g.:

   my ($dirs, $nondirs);
   IO::AIO::aio_scandir "/tmp", 0, sub { ($dirs, $nondirs) = @_ };
   IO::AIO::flush;
   # $dirs, $nondirs are now set

=item IO::AIO::max_poll_reqs $nreqs

=item IO::AIO::max_poll_time $seconds

These set the maximum number of requests (default C<0>, meaning infinity)
that are being processed by C<IO::AIO::poll_cb> in one call, respectively
the maximum amount of time (default C<0>, meaning infinity) spent in
C<IO::AIO::poll_cb> to process requests (more correctly the mininum amount
of time C<poll_cb> is allowed to use).

Setting C<max_poll_time> to a non-zero value creates an overhead of one
syscall per request processed, which is not normally a problem unless your
callbacks are really really fast or your OS is really really slow (I am
not mentioning Solaris here). Using C<max_poll_reqs> incurs no overhead.

Setting these is useful if you want to ensure some level of
interactiveness when perl is not fast enough to process all requests in
time.

For interactive programs, values such as C<0.01> to C<0.1> should be fine.

Example: Install an Event watcher that automatically calls
IO::AIO::poll_cb with low priority, to ensure that other parts of the
program get the CPU sometimes even under high AIO load.

   # try not to spend much more than 0.1s in poll_cb
   IO::AIO::max_poll_time 0.1;

   # use a low priority so other tasks have priority
   Event->io (fd => IO::AIO::poll_fileno,
              poll => 'r', nice => 1,
              cb => &IO::AIO::poll_cb);

=back


=head3 CONTROLLING THE NUMBER OF THREADS

=over

=item IO::AIO::min_parallel $nthreads

Set the minimum number of AIO threads to C<$nthreads>. The current
default is C<8>, which means eight asynchronous operations can execute
concurrently at any one time (the number of outstanding requests,
however, is unlimited).

IO::AIO starts threads only on demand, when an AIO request is queued and
no free thread exists. Please note that queueing up a hundred requests can
create demand for a hundred threads, even if it turns out that everything
is in the cache and could have been processed faster by a single thread.

It is recommended to keep the number of threads relatively low, as some
Linux kernel versions will scale negatively with the number of threads
(higher parallelity => MUCH higher latency). With current Linux 2.6
versions, 4-32 threads should be fine.

Under most circumstances you don't need to call this function, as the
module selects a default that is suitable for low to moderate load.

=item IO::AIO::max_parallel $nthreads

Sets the maximum number of AIO threads to C<$nthreads>. If more than the
specified number of threads are currently running, this function kills
them. This function blocks until the limit is reached.

While C<$nthreads> are zero, aio requests get queued but not executed
until the number of threads has been increased again.

This module automatically runs C<max_parallel 0> at program end, to ensure
that all threads are killed and that there are no outstanding requests.

Under normal circumstances you don't need to call this function.

=item IO::AIO::max_idle $nthreads

Limit the number of threads (default: 4) that are allowed to idle
(i.e., threads that did not get a request to process within the idle
timeout (default: 10 seconds). That means if a thread becomes idle while
C<$nthreads> other threads are also idle, it will free its resources and
exit.

This is useful when you allow a large number of threads (e.g. 100 or 1000)
to allow for extremely high load situations, but want to free resources
under normal circumstances (1000 threads can easily consume 30MB of RAM).

The default is probably ok in most situations, especially if thread
creation is fast. If thread creation is very slow on your system you might
want to use larger values.

=item IO::AIO::idle_timeout $seconds

Sets the minimum idle timeout (default 10) after which worker threads are
allowed to exit. SEe C<IO::AIO::max_idle>.

=item IO::AIO::max_outstanding $maxreqs

Sets the maximum number of outstanding requests to C<$nreqs>. If
you do queue up more than this number of requests, the next call to
C<IO::AIO::poll_cb> (and other functions calling C<poll_cb>, such as
C<IO::AIO::flush> or C<IO::AIO::poll>) will block until the limit is no
longer exceeded.

In other words, this setting does not enforce a queue limit, but can be
used to make poll functions block if the limit is exceeded.

This is a very bad function to use in interactive programs because it
blocks, and a bad way to reduce concurrency because it is inexact: Better
use an C<aio_group> together with a feed callback.

Its main use is in scripts without an event loop - when you want to stat
a lot of files, you can write something like this:

   IO::AIO::max_outstanding 32;

   for my $path (...) {
      aio_stat $path , ...;
      IO::AIO::poll_cb;
   }

   IO::AIO::flush;

The call to C<poll_cb> inside the loop will normally return instantly, but
as soon as more thna C<32> reqeusts are in-flight, it will block until
some requests have been handled. This keeps the loop from pushing a large
number of C<aio_stat> requests onto the queue.

The default value for C<max_outstanding> is very large, so there is no
practical limit on the number of outstanding requests.

=back


=head3 STATISTICAL INFORMATION

=over

=item IO::AIO::nreqs

Returns the number of requests currently in the ready, execute or pending
states (i.e. for which their callback has not been invoked yet).

Example: wait till there are no outstanding requests anymore:

   IO::AIO::poll_wait, IO::AIO::poll_cb
      while IO::AIO::nreqs;

=item IO::AIO::nready

Returns the number of requests currently in the ready state (not yet
executed).

=item IO::AIO::npending

Returns the number of requests currently in the pending state (executed,
but not yet processed by poll_cb).

=back


=head3 SUBSECOND STAT TIME ACCESS

Both C<aio_stat>/C<aio_lstat> and perl's C<stat>/C<lstat> functions can
generally find access/modification and change times with subsecond time
accuracy of the system supports it, but perl's built-in functions only
return the integer part.

The following functions return the timestamps of the most recent
stat with subsecond precision on most systems and work both after
C<aio_stat>/C<aio_lstat> and perl's C<stat>/C<lstat> calls. Their return
value is only meaningful after a successful C<stat>/C<lstat> call, or
during/after a successful C<aio_stat>/C<aio_lstat> callback.

This is similar to the L<Time::HiRes> C<stat> functions, but can return
full resolution without rounding and work with standard perl C<stat>,
alleviating the need to call the special C<Time::HiRes> functions, which
do not act like their perl counterparts.

On operating systems or file systems where subsecond time resolution is
not supported or could not be detected, a fractional part of C<0> is
returned, so it is always safe to call these functions.

=over 4

=item $seconds = IO::AIO::st_atime, IO::AIO::st_mtime, IO::AIO::st_ctime, IO::AIO::st_btime

Return the access, modication, change or birth time, respectively,
including fractional part. Due to the limited precision of floating point,
the accuracy on most platforms is only a bit better than milliseconds
for times around now - see the I<nsec> function family, below, for full
accuracy.

File birth time is only available when the OS and perl support it (on
FreeBSD and NetBSD at the time of this writing, although support is
adaptive, so if your OS/perl gains support, IO::AIO can take advantage of
it). On systems where it isn't available, C<0> is currently returned, but
this might change to C<undef> in a future version.

=item ($atime, $mtime, $ctime, $btime, ...) = IO::AIO::st_xtime

Returns access, modification, change and birth time all in one go, and
maybe more times in the future version.

=item $nanoseconds = IO::AIO::st_atimensec, IO::AIO::st_mtimensec, IO::AIO::st_ctimensec, IO::AIO::st_btimensec

Return the fractional access, modifcation, change or birth time, in nanoseconds,
as an integer in the range C<0> to C<999999999>.

Note that no accessors are provided for access, modification and
change times - you need to get those from C<stat _> if required (C<int
IO::AIO::st_atime> and so on will I<not> generally give you the correct
value).

=item $seconds = IO::AIO::st_btimesec

The (integral) seconds part of the file birth time, if available.

=item ($atime, $mtime, $ctime, $btime, ...) = IO::AIO::st_xtimensec

Like the functions above, but returns all four times in one go (and maybe
more in future versions).

=item $counter = IO::AIO::st_gen

Returns the generation counter (in practice this is just a random number)
of the file. This is only available on platforms which have this member in
their C<struct stat> (most BSDs at the time of this writing) and generally
only to the root usert. If unsupported, C<0> is returned, but this might
change to C<undef> in a future version.

=back

Example: print the high resolution modification time of F</etc>, using
C<stat>, and C<IO::AIO::aio_stat>.

   if (stat "/etc") {
      printf "stat(/etc) mtime: %f\n", IO::AIO::st_mtime;
   }

   IO::AIO::aio_stat "/etc", sub {
      $_[0]
         and return;

      printf "aio_stat(/etc) mtime: %d.%09d\n", (stat _)[9], IO::AIO::st_mtimensec;
   };

   IO::AIO::flush;

Output of the awbove on my system, showing reduced and full accuracy:

   stat(/etc) mtime: 1534043702.020808
   aio_stat(/etc) mtime: 1534043702.020807792


=head3 MISCELLANEOUS FUNCTIONS

IO::AIO implements some functions that are useful when you want to use
some "Advanced I/O" function not available to in Perl, without going the
"Asynchronous I/O" route. Many of these have an asynchronous C<aio_*>
counterpart.

=over 4

=item $numfd = IO::AIO::get_fdlimit

Tries to find the current file descriptor limit and returns it, or
C<undef> and sets C<$!> in case of an error. The limit is one larger than
the highest valid file descriptor number.

=item IO::AIO::min_fdlimit [$numfd]

Try to increase the current file descriptor limit(s) to at least C<$numfd>
by changing the soft or hard file descriptor resource limit. If C<$numfd>
is missing, it will try to set a very high limit, although this is not
recommended when you know the actual minimum that you require.

If the limit cannot be raised enough, the function makes a best-effort
attempt to increase the limit as much as possible, using various
tricks, while still failing. You can query the resulting limit using
C<IO::AIO::get_fdlimit>.

If an error occurs, returns C<undef> and sets C<$!>, otherwise returns
true.

=item IO::AIO::sendfile $ofh, $ifh, $offset, $count

Calls the C<eio_sendfile_sync> function, which is like C<aio_sendfile>,
but is blocking (this makes most sense if you know the input data is
likely cached already and the output filehandle is set to non-blocking
operations).

Returns the number of bytes copied, or C<-1> on error.

=item IO::AIO::fadvise $fh, $offset, $len, $advice

Simply calls the C<posix_fadvise> function (see its
manpage for details). The following advice constants are
available: C<IO::AIO::FADV_NORMAL>, C<IO::AIO::FADV_SEQUENTIAL>,
C<IO::AIO::FADV_RANDOM>, C<IO::AIO::FADV_NOREUSE>,
C<IO::AIO::FADV_WILLNEED>, C<IO::AIO::FADV_DONTNEED>.

On systems that do not implement C<posix_fadvise>, this function returns
ENOSYS, otherwise the return value of C<posix_fadvise>.

=item IO::AIO::madvise $scalar, $offset, $len, $advice

Simply calls the C<posix_madvise> function (see its
manpage for details). The following advice constants are
available: C<IO::AIO::MADV_NORMAL>, C<IO::AIO::MADV_SEQUENTIAL>,
C<IO::AIO::MADV_RANDOM>, C<IO::AIO::MADV_WILLNEED>,
C<IO::AIO::MADV_DONTNEED>.

If C<$offset> is negative, counts from the end. If C<$length> is negative,
the remaining length of the C<$scalar> is used. If possible, C<$length>
will be reduced to fit into the C<$scalar>.

On systems that do not implement C<posix_madvise>, this function returns
ENOSYS, otherwise the return value of C<posix_madvise>.

=item IO::AIO::mprotect $scalar, $offset, $len, $protect

Simply calls the C<mprotect> function on the preferably AIO::mmap'ed
$scalar (see its manpage for details). The following protect
constants are available: C<IO::AIO::PROT_NONE>, C<IO::AIO::PROT_READ>,
C<IO::AIO::PROT_WRITE>, C<IO::AIO::PROT_EXEC>.

If C<$offset> is negative, counts from the end. If C<$length> is negative,
the remaining length of the C<$scalar> is used. If possible, C<$length>
will be reduced to fit into the C<$scalar>.

On systems that do not implement C<mprotect>, this function returns
ENOSYS, otherwise the return value of C<mprotect>.

=item IO::AIO::mmap $scalar, $length, $prot, $flags, $fh[, $offset]

Memory-maps a file (or anonymous memory range) and attaches it to the
given C<$scalar>, which will act like a string scalar. Returns true on
success, and false otherwise.

The scalar must exist, but its contents do not matter - this means you
cannot use a nonexistant array or hash element. When in doubt, C<undef>
the scalar first.

The only operations allowed on the mmapped scalar are C<substr>/C<vec>,
which don't change the string length, and most read-only operations such
as copying it or searching it with regexes and so on.

Anything else is unsafe and will, at best, result in memory leaks.

The memory map associated with the C<$scalar> is automatically removed
when the C<$scalar> is undef'd or destroyed, or when the C<IO::AIO::mmap>
or C<IO::AIO::munmap> functions are called on it.

This calls the C<mmap>(2) function internally. See your system's manual
page for details on the C<$length>, C<$prot> and C<$flags> parameters.

The C<$length> must be larger than zero and smaller than the actual
filesize.

C<$prot> is a combination of C<IO::AIO::PROT_NONE>, C<IO::AIO::PROT_EXEC>,
C<IO::AIO::PROT_READ> and/or C<IO::AIO::PROT_WRITE>,

C<$flags> can be a combination of
C<IO::AIO::MAP_SHARED> or
C<IO::AIO::MAP_PRIVATE>,
or a number of system-specific flags (when not available, the are C<0>):
C<IO::AIO::MAP_ANONYMOUS> (which is set to C<MAP_ANON> if your system only provides this constant),
C<IO::AIO::MAP_LOCKED>,
C<IO::AIO::MAP_NORESERVE>,
C<IO::AIO::MAP_POPULATE>,
C<IO::AIO::MAP_NONBLOCK>,
C<IO::AIO::MAP_FIXED>,
C<IO::AIO::MAP_GROWSDOWN>,
C<IO::AIO::MAP_32BIT>,
C<IO::AIO::MAP_HUGETLB> or
C<IO::AIO::MAP_STACK>.

If C<$fh> is C<undef>, then a file descriptor of C<-1> is passed.

C<$offset> is the offset from the start of the file - it generally must be
a multiple of C<IO::AIO::PAGESIZE> and defaults to C<0>.

Example:

   use Digest::MD5;
   use IO::AIO;

   open my $fh, "<verybigfile"
      or die "$!";

   IO::AIO::mmap my $data, -s $fh, IO::AIO::PROT_READ, IO::AIO::MAP_SHARED, $fh
      or die "verybigfile: $!";

   my $fast_md5 = md5 $data;

=item IO::AIO::munmap $scalar

Removes a previous mmap and undefines the C<$scalar>.

=item IO::AIO::mremap $scalar, $new_length, $flags = MREMAP_MAYMOVE[, $new_address = 0]

Calls the Linux-specific mremap(2) system call. The C<$scalar> must have
been mapped by C<IO::AIO::mmap>, and C<$flags> must currently either be
C<0> or C<IO::AIO::MREMAP_MAYMOVE>.

Returns true if successful, and false otherwise. If the underlying mmapped
region has changed address, then the true value has the numerical value
C<1>, otherwise it has the numerical value C<0>:

   my $success = IO::AIO::mremap $mmapped, 8192, IO::AIO::MREMAP_MAYMOVE
      or die "mremap: $!";

   if ($success*1) {
      warn "scalar has chanegd address in memory\n";
   }

C<IO::AIO::MREMAP_FIXED> and the C<$new_address> argument are currently
implemented, but not supported and might go away in a future version.

On systems where this call is not supported or is not emulated, this call
returns falls and sets C<$!> to C<ENOSYS>.

=item IO::AIO::mlockall $flags

Calls the C<eio_mlockall_sync> function, which is like C<aio_mlockall>,
but is blocking.

=item IO::AIO::munlock $scalar, $offset = 0, $length = undef

Calls the C<munlock> function, undoing the effects of a previous
C<aio_mlock> call (see its description for details).

=item IO::AIO::munlockall

Calls the C<munlockall> function.

On systems that do not implement C<munlockall>, this function returns
ENOSYS, otherwise the return value of C<munlockall>.

=item $fh = IO::AIO::accept4 $r_fh, $sockaddr, $sockaddr_maxlen, $flags

Uses the GNU/Linux C<accept4(2)> syscall, if available, to accept a socket
and return the new file handle on success, or sets C<$!> and returns
C<undef> on error.

The remote name of the new socket will be stored in C<$sockaddr>, which
will be extended to allow for at least C<$sockaddr_maxlen> octets. If the
socket name does not fit into C<$sockaddr_maxlen> octets, this is signaled
by returning a longer string in C<$sockaddr>, which might or might not be
truncated.

To accept name-less sockets, use C<undef> for C<$sockaddr> and C<0> for
C<$sockaddr_maxlen>.

The main reasons to use this syscall rather than portable C<accept(2)>
are that you can specify C<SOCK_NONBLOCK> and/or C<SOCK_CLOEXEC>
flags and you can accept name-less sockets by specifying C<0> for
C<$sockaddr_maxlen>, which is sadly not possible with perl's interface to
C<accept>.

=item IO::AIO::splice $r_fh, $r_off, $w_fh, $w_off, $length, $flags

Calls the GNU/Linux C<splice(2)> syscall, if available. If C<$r_off> or
C<$w_off> are C<undef>, then C<NULL> is passed for these, otherwise they
should be the file offset.

C<$r_fh> and C<$w_fh> should not refer to the same file, as splice might
silently corrupt the data in this case.

The following symbol flag values are available: C<IO::AIO::SPLICE_F_MOVE>,
C<IO::AIO::SPLICE_F_NONBLOCK>, C<IO::AIO::SPLICE_F_MORE> and
C<IO::AIO::SPLICE_F_GIFT>.

See the C<splice(2)> manpage for details.

=item IO::AIO::tee $r_fh, $w_fh, $length, $flags

Calls the GNU/Linux C<tee(2)> syscall, see its manpage and the
description for C<IO::AIO::splice> above for details.

=item $actual_size = IO::AIO::pipesize $r_fh[, $new_size]

Attempts to query or change the pipe buffer size. Obviously works only
on pipes, and currently works only on GNU/Linux systems, and fails with
C<-1>/C<ENOSYS> everywhere else. If anybody knows how to influence pipe buffer
size on other systems, drop me a note.

=item ($rfh, $wfh) = IO::AIO::pipe2 [$flags]

This is a direct interface to the Linux L<pipe2(2)> system call. If
C<$flags> is missing or C<0>, then this should be the same as a call to
perl's built-in C<pipe> function and create a new pipe, and works on
systems that lack the pipe2 syscall. On win32, this case invokes C<_pipe
(..., 4096, O_BINARY)>.

If C<$flags> is non-zero, it tries to invoke the pipe2 system call with
the given flags (Linux 2.6.27, glibc 2.9).

On success, the read and write file handles are returned.

On error, nothing will be returned. If the pipe2 syscall is missing and
C<$flags> is non-zero, fails with C<ENOSYS>.

Please refer to L<pipe2(2)> for more info on the C<$flags>, but at the
time of this writing, C<IO::AIO::O_CLOEXEC>, C<IO::AIO::O_NONBLOCK> and
C<IO::AIO::O_DIRECT> (Linux 3.4, for packet-based pipes) were supported.

Example: create a pipe race-free w.r.t. threads and fork:

   my ($rfh, $wfh) = IO::AIO::pipe2 IO::AIO::O_CLOEXEC
      or die "pipe2: $!\n";

=item $fh = IO::AIO::memfd_create $pathname[, $flags]

This is a direct interface to the Linux L<memfd_create(2)> system
call. The (unhelpful) default for C<$flags> is C<0>, but your default
should be C<IO::AIO::MFD_CLOEXEC>.

On success, the new memfd filehandle is returned, otherwise returns
C<undef>. If the memfd_create syscall is missing, fails with C<ENOSYS>.

Please refer to L<memfd_create(2)> for more info on this call.

The following C<$flags> values are available: C<IO::AIO::MFD_CLOEXEC>,
C<IO::AIO::MFD_ALLOW_SEALING> and C<IO::AIO::MFD_HUGETLB>.

Example: create a new memfd.

   my $fh = IO::AIO::memfd_create "somenameforprocfd", IO::AIO::MFD_CLOEXEC
      or die "memfd_create: $!\n";

=item $fh = IO::AIO::pidfd_open $pid[, $flags]

This is an interface to the Linux L<pidfd_open(2)> system call. The
default for C<$flags> is C<0>.

On success, a new pidfd filehandle is returned (that is already set to
close-on-exec), otherwise returns C<undef>. If the syscall is missing,
fails with C<ENOSYS>.

Example: open pid 6341 as pidfd.

   my $fh = IO::AIO::pidfd_open 6341
      or die "pidfd_open: $!\n";

=item $status = IO::AIO::pidfd_send_signal $pidfh, $signal[, $siginfo[, $flags]]

This is an interface to the Linux L<pidfd_send_signal> system call. The
default for C<$siginfo> is C<undef> and the default for C<$flags> is C<0>.

Returns the system call status.  If the syscall is missing, fails with
C<ENOSYS>.

When specified, C<$siginfo> must be a reference to a hash with one or more
of the following members:

=over

=item code - the C<si_code> member

=item pid - the C<si_pid> member

=item uid - the C<si_uid> member

=item value_int - the C<si_value.sival_int> member

=item value_ptr - the C<si_value.sival_ptr> member, specified as an integer

=back

Example: send a SIGKILL to the specified process.

   my $status = IO::AIO::pidfd_send_signal $pidfh, 9, undef
      and die "pidfd_send_signal: $!\n";

Example: send a SIGKILL to the specified process with extra data.

   my $status = IO::AIO::pidfd_send_signal $pidfh, 9,  { code => -1, value_int => 7 }
      and die "pidfd_send_signal: $!\n";

=item $fh = IO::AIO::pidfd_getfd $pidfh, $targetfd[, $flags]

This is an interface to the Linux L<pidfd_getfd> system call. The default
for C<$flags> is C<0>.

On success, returns a dup'ed copy of the target file descriptor (specified
as an integer) returned (that is already set to close-on-exec), otherwise
returns C<undef>. If the syscall is missing, fails with C<ENOSYS>.

Example: get a copy of standard error of another process and print soemthing to it.

   my $errfh = IO::AIO::pidfd_getfd $pidfh, 2
      or die "pidfd_getfd: $!\n";
   print $errfh "stderr\n";

=item $fh = IO::AIO::eventfd [$initval, [$flags]]

This is a direct interface to the Linux L<eventfd(2)> system call. The
(unhelpful) defaults for C<$initval> and C<$flags> are C<0> for both.

On success, the new eventfd filehandle is returned, otherwise returns
C<undef>. If the eventfd syscall is missing, fails with C<ENOSYS>.

Please refer to L<eventfd(2)> for more info on this call.

The following symbol flag values are available: C<IO::AIO::EFD_CLOEXEC>,
C<IO::AIO::EFD_NONBLOCK> and C<IO::AIO::EFD_SEMAPHORE> (Linux 2.6.30).

Example: create a new eventfd filehandle:

   $fh = IO::AIO::eventfd 0, IO::AIO::EFD_CLOEXEC
      or die "eventfd: $!\n";

=item $fh = IO::AIO::timerfd_create $clockid[, $flags]

This is a direct interface to the Linux L<timerfd_create(2)> system
call. The (unhelpful) default for C<$flags> is C<0>, but your default
should be C<IO::AIO::TFD_CLOEXEC>.

On success, the new timerfd filehandle is returned, otherwise returns
C<undef>. If the timerfd_create syscall is missing, fails with C<ENOSYS>.

Please refer to L<timerfd_create(2)> for more info on this call.

The following C<$clockid> values are
available: C<IO::AIO::CLOCK_REALTIME>, C<IO::AIO::CLOCK_MONOTONIC>
C<IO::AIO::CLOCK_CLOCK_BOOTTIME> (Linux 3.15)
C<IO::AIO::CLOCK_CLOCK_REALTIME_ALARM> (Linux 3.11) and
C<IO::AIO::CLOCK_CLOCK_BOOTTIME_ALARM> (Linux 3.11).

The following C<$flags> values are available (Linux
2.6.27): C<IO::AIO::TFD_NONBLOCK> and C<IO::AIO::TFD_CLOEXEC>.

Example: create a new timerfd and set it to one-second repeated alarms,
then wait for two alarms:

   my $fh = IO::AIO::timerfd_create IO::AIO::CLOCK_BOOTTIME, IO::AIO::TFD_CLOEXEC
      or die "timerfd_create: $!\n";

   defined IO::AIO::timerfd_settime $fh, 0, 1, 1
      or die "timerfd_settime: $!\n";

   for (1..2) {
      8 == sysread $fh, my $buf, 8
         or die "timerfd read failure\n";

      printf "number of expirations (likely 1): %d\n",
         unpack "Q", $buf;
   }

=item ($cur_interval, $cur_value) = IO::AIO::timerfd_settime $fh, $flags, $new_interval, $nbw_value

This is a direct interface to the Linux L<timerfd_settime(2)> system
call. Please refer to its manpage for more info on this call.

The new itimerspec is specified using two (possibly fractional) second
values, C<$new_interval> and C<$new_value>).

On success, the current interval and value are returned (as per
C<timerfd_gettime>). On failure, the empty list is returned.

The following C<$flags> values are
available: C<IO::AIO::TFD_TIMER_ABSTIME> and
C<IO::AIO::TFD_TIMER_CANCEL_ON_SET>.

See C<IO::AIO::timerfd_create> for a full example.

=item ($cur_interval, $cur_value) = IO::AIO::timerfd_gettime $fh

This is a direct interface to the Linux L<timerfd_gettime(2)> system
call. Please refer to its manpage for more info on this call.

On success, returns the current values of interval and value for the given
timerfd (as potentially fractional second values). On failure, the empty
list is returned.

=back

=cut

min_parallel 8;

END { flush }

1;

=head1 EVENT LOOP INTEGRATION

It is recommended to use L<AnyEvent::AIO> to integrate IO::AIO
automatically into many event loops:

 # AnyEvent integration (EV, Event, Glib, Tk, POE, urxvt, pureperl...)
 use AnyEvent::AIO;

You can also integrate IO::AIO manually into many event loops, here are
some examples of how to do this:

 # EV integration
 my $aio_w = EV::io IO::AIO::poll_fileno, EV::READ, \&IO::AIO::poll_cb;

 # Event integration
 Event->io (fd => IO::AIO::poll_fileno,
            poll => 'r',
            cb => \&IO::AIO::poll_cb);

 # Glib/Gtk2 integration
 add_watch Glib::IO IO::AIO::poll_fileno,
           in => sub { IO::AIO::poll_cb; 1 };

 # Tk integration
 Tk::Event::IO->fileevent (IO::AIO::poll_fileno, "",
                           readable => \&IO::AIO::poll_cb);

 # Danga::Socket integration
 Danga::Socket->AddOtherFds (IO::AIO::poll_fileno =>
                             \&IO::AIO::poll_cb);

=head2 FORK BEHAVIOUR

Usage of pthreads in a program changes the semantics of fork
considerably. Specifically, only async-safe functions can be called after
fork. Perl doesn't know about this, so in general, you cannot call fork
with defined behaviour in perl if pthreads are involved. IO::AIO uses
pthreads, so this applies, but many other extensions and (for inexplicable
reasons) perl itself often is linked against pthreads, so this limitation
applies to quite a lot of perls.

This module no longer tries to fight your OS, or POSIX. That means IO::AIO
only works in the process that loaded it. Forking is fully supported, but
using IO::AIO in the child is not.

You might get around by not I<using> IO::AIO before (or after)
forking. You could also try to call the L<IO::AIO::reinit> function in the
child:

=over 4

=item IO::AIO::reinit

Abandons all current requests and I/O threads and simply reinitialises all
data structures. This is not an operation supported by any standards, but
happens to work on GNU/Linux and some newer BSD systems.

The only reasonable use for this function is to call it after forking, if
C<IO::AIO> was used in the parent. Calling it while IO::AIO is active in
the process will result in undefined behaviour. Calling it at any time
will also result in any undefined (by POSIX) behaviour.

=back

=head2 LINUX-SPECIFIC CALLS

When a call is documented as "linux-specific" then this means it
originated on GNU/Linux. C<IO::AIO> will usually try to autodetect the
availability and compatibility of such calls regardless of the platform
it is compiled on, so platforms such as FreeBSD which often implement
these calls will work. When in doubt, call them and see if they fail wth
C<ENOSYS>.

=head2 MEMORY USAGE

Per-request usage:

Each aio request uses - depending on your architecture - around 100-200
bytes of memory. In addition, stat requests need a stat buffer (possibly
a few hundred bytes), readdir requires a result buffer and so on. Perl
scalars and other data passed into aio requests will also be locked and
will consume memory till the request has entered the done state.

This is not awfully much, so queuing lots of requests is not usually a
problem.

Per-thread usage:

In the execution phase, some aio requests require more memory for
temporary buffers, and each thread requires a stack and other data
structures (usually around 16k-128k, depending on the OS).

=head1 KNOWN BUGS

Known bugs will be fixed in the next release :)

=head1 KNOWN ISSUES

Calls that try to "import" foreign memory areas (such as C<IO::AIO::mmap>
or C<IO::AIO::aio_slurp>) do not work with generic lvalues, such as
non-created hash slots or other scalars I didn't think of. It's best to
avoid such and either use scalar variables or making sure that the scalar
exists (e.g. by storing C<undef>) and isn't "funny" (e.g. tied).

I am not sure anything can be done about this, so this is considered a
known issue, rather than a bug.

=head1 SEE ALSO

L<AnyEvent::AIO> for easy integration into event loops, L<Coro::AIO> for a
more natural syntax and L<IO::FDPass> for file descriptor passing.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

