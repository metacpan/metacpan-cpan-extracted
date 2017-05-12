package IO::Vectored;

use strict;

use Carp;

our $VERSION = '0.110';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(sysreadv syswritev);

require XSLoader;
XSLoader::load('IO::Vectored', $VERSION);


sub sysreadv(*@) {
  my $fh = shift;

  my $fileno = fileno($fh);
  croak("closed or invalid file-handle passed to sysreadv") if !defined $fileno || $fileno < 0;

  return _backend($fileno, 0, @_);
}

sub syswritev(*@) {
  my $fh = shift;

  my $fileno = fileno($fh);
  croak("closed or invalid file-handle passed to syswritev") if !defined $fileno || $fileno < 0;

  return _backend($fileno, 1, @_);
}

sub IOV_MAX() {
  return _get_iov_max();
}

1;



__END__


=encoding utf-8

=head1 NAME

IO::Vectored - Read from or write to multiple buffers at once

=head1 WRITE SYNOPSIS

    use IO::Vectored;

    syswritev($file_handle, "hello", "world") || die "syswritev: $!";


=head1 READ SYNOPSIS

    use IO::Vectored;

    my $buf1 = " " x 5;
    my $buf2 = " " x 5;

    sysreadv($file_handle, $buf1, $buf2) || die "sysreadv: $!";

    ## if input is "abcdefg" then:
    ##  $buf1 eq "abcde"
    ##  $buf2 eq "fg   "



=head1 DESCRIPTION

Vectored-IO is sometimes called "scatter-gather" IO. The idea is that instead of doing multiple C<read(2)> or C<write(2)> system calls for each string, your program creates a vector of pointers to all the strings you wish to read/write and then does a single system call referencing this vector.

Although some people consider these interfaces contrary to the minimalist design principles of unix, vectored-IO has certain advantages which are described below.

This module is an interface to your system's L<readv(2)|http://pubs.opengroup.org/onlinepubs/009695399/functions/readv.html> and L<writev(2)|http://pubs.opengroup.org/onlinepubs/009695399/functions/writev.html> vectored-IO system calls specified by POSIX.1. It exports the functions C<syswritev> and C<sysreadv> which are almost the same as the C<syswrite> and C<sysread> perl functions except that they accept multiple strings and always have default length and offset parameters.



=head1 ADVANTAGES

The first advantage of vectored-IO is that it reduces the number of system calls required. This provides an atomicity guarantee in that your reads/writes won't be intermingled with the reads/writes of other processes when you aren't expecting it and also eliminates a constant overhead particular to your system.

Another advantage of vectored-IO is that doing multiple system calls can result in excess network packets being sent. The classic example of this is a web-server sending a static file. If the server C<write()>s the HTTP headers and then C<write()>s the file data, the kernel might send the headers and file in separate network packets. Ensuring a single packet is better for latency and bandwidth consumption. L<TCP_CORK|http://baus.net/on-tcp_cork/> is a solution to this issue but it is Linux-specific and requires more system calls.

Of course an alternative to vectored-IO is to copy the buffers together into a contiguous buffer before calling C<write(2)>. The performance trade-off of this is that a potentially large buffer needs to be allocated and then all the smaller buffers copied into it. Also, if your buffers are backed by memory-mapped files (created with L<File::Map> for instance) then this approach results in an unnecessary copy of the data to userspace. If you use vectored-IO then files can be copied directly from the file-system cache into the socket's L<mbuf|http://www.openbsd.org/cgi-bin/man.cgi?query=mbuf>.

Note that as with anything the performance benefits of vectored-IO will vary from application to application and you shouldn't retro-fit it onto an application unless benchmarking has shown measurable benefits. However, vectored-IO can sometimes be more programmer-convenient than regular IO and may be worth using for that reason alone.




=head1 RETURN VALUES AND ERROR CONDITIONS

As mentioned above, this module's interface tries to match C<syswrite> and C<sysread> so the same caveats that apply to those functions apply to the vectored interfaces. In particular, you should not mix these calls with userspace-buffered interfaces such as C<print> or C<seek>. Mixing the vectored interfaces with C<syswrite> and C<sysread> is fine though.

C<syswritev> returns the number of bytes written (usually the sum of the lengths of all arguments). If it returns less, either there was an error which is indicated in C<$!> or you are using non-blocking IO in which case it is up to you to adjust it so that the next C<syswritev> points to the remaining data.

C<sysreadv> returns the number of bytes read up to the sum of the lengths of all arguments. Note that unlike C<sysread>, C<sysreadv> will not truncate any buffers (see the L<READ SYNOPSIS> above and the L<TODO> below).

Both of these functions can also return C<undef> if the underlying C<readv(2)> or C<writev(2)> system calls fail for any reason other than C<EINTR>. When undef is returned, C<$!> will be set with the error.

Like C<sysread>/C<syswrite>, the vectored versions also croak for various reasons such as passing in too many arguments (more than C<IO::Vectored::IOV_MAX>), trying to use a closed file-handle, or trying to write to a read-only/constant string. See the C<t/exceptions.t> test for a full list.

Although not specific to vectored-IO, when accessing C<mmap()>ed memory, a SIGBUS signal can kill your process if another process truncates the backing file while you are accessing it.




=head1 SENDFILE

The non-standard C<sendfile(2)> system call can do one less copy than vectored-IO because the file data can be copied directly from the filesystem cache into the final network packet if the hardware and network driver support scatter-gather IO.

Another advantage of C<sendfile()> is that the file pages are never actually mapped into virtual address space. Because the network hardware can gather the data from the OS file-system cache with Direct Memory Access (DMA), there is less pressure on the Translation Lookaside Buffer (TLB). The consequence is less CPU usage per page transferred.

With C<sendfile()>, the number of bytes to send with each system call is specified by C<size_t> so you still have to call it multiple times in order to send files too large to map into virtual memory on 32-bit systems. However, C<sendfile()> doesn't require re-mmaping large files throughout the send like vectored-IO does on 32 bit systems so it can send files in the fewest number of system calls.

A good rule of thumb is that C<sendfile()> is best for large files and vectored-IO is best for small files.

Unfortunately, where operating systems have implemented it at all, the C<sendfile()> interfaces are different. The rest of this section will briefly describe the pros and cons of some implementations.

Linux has the most limited C<sendfile()> implementation. On Linux, a system call is required for each file to be sent, unlike with vectored-IO. Also, a solution such as C<TCP_CORK> is needed to avoid excess network packets. If you are using 32 bit C<off_t> then you will need the C<sendfile64(2)> transitional interface. Note that while this function lets you send large files, you still need to call C<sendfile()> multiple times since the amount you wish to send at once is stored in a C<size_t>.

FreeBSD's C<sendfile()> allows you to specify leading or trailing vectored-IO in addition to the file. This mostly gets rid of the need for C<TCP_CORK>-like solutions. Sending multiple files in one system call is possible but only by taking advantage of one of the vectored-IO parameters in which case you must choose one and only one of the files to get the advantages of C<sendfile()>. FreeBSD's C<off_t> is always 64 bits so there is no need for a C<sendfile64()>.

As well as a Linux-like C<sendfile()>, Solaris has a fully vectorised interface called C<sendfilev()> which allows the arbitrary mixing of files and in-process memory buffers. Although in many ways this is the best of both worlds, it still doesn't guarantee atomicity like standard vectored-IO does. Note that Solaris also provides C<sendfile64()> and C<sendfilev64()> interfaces because C<off_t> can be 32 or 64 bits so an explicitly 64-bit transitional interface is required.

As if all the above caveats weren't enough, many C<sendfile()> implementations will only work when sending from a file (obviously) and to a network socket (less obviously). So in order for your code to be fully general and portable you may have to implement one code path that uses C<sendfile()> and one that doesn't.

How are those minimalist design principles of unix sounding now? :) 





=head1 TODO

Consider truncating input strings like C<sysread> does. Please don't depend on the non-truncating behaviour of C<sysreadv> until version 1.000.

Implement some helper utilities to make using non-blocking IO easier such as a utility to shift off N bytes from the beginning of a vector.

To the extent possible, make it do the right thing for file-handles with non-raw encodings and unicode strings. Any test-cases are appreciated.

Investigate if there is a performance benefit in eliminating the perl subs and re-implementing their logic in XS.

Think about whether this module should support vectors larger than C<IOV_MAX> by calling C<writev>/C<readv> multiple times. This should be opt-in because it breaks the atomicity guarantee.

Support windows with C<ReadFileScatter>, C<WriteFileGather>, C<WSASend>, and C<WSARecv>.



=head1 SEE ALSO

L<IO-Vectored github repo|https://github.com/hoytech/IO-Vectored>

Useful modules to combine with vectored-IO:

L<File::Map> / L<Sys::Mmap>

L<overload::substr>

L<String::Slice>

Even though C<sendfile()> is a solution to a somewhat different problem (see the L<SENDFILE> section above), here are some perl interfaces:

L<Sys::Sendfile> / L<Sys::Syscall> / L<Sys::Sendfile::FreeBSD>


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>


=head1 COPYRIGHT & LICENSE

Copyright 2013-2014 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut
