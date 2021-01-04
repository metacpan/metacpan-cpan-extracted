=head1 NAME

IO::FDPass - pass a file descriptor over a socket

=head1 SYNOPSIS

   use IO::FDPass;

   IO::FDPass::send fileno $socket, fileno $fh_to_pass
      or die "send failed: $!";

   my $fd = IO::FDPass::recv fileno $socket;
   $fd >= 0 or die "recv failed: $!";

=head1 DESCRIPTION

This small low-level module only has one purpose: pass a file descriptor
to another process, using a (streaming) unix domain socket (on POSIX
systems) or any (streaming) socket (on WIN32 systems). The ability to pass
file descriptors on windows is currently the unique selling point of this
module. Have I mentioned that it is really small, too?

=head1 FUNCTIONS

=over 4

=cut

package IO::FDPass;

BEGIN {
   $VERSION = 1.3;

   require XSLoader;
   XSLoader::load (__PACKAGE__, $VERSION);
}

=item $bool = IO::FDPass::send $socket_fd, $fd_to_pass

Sends the file descriptor given by C<$fd_to_pass> over the socket
C<$socket_fd>. Return true if it worked, false otherwise.

Note that I<both> parameters must be file descriptors, not handles.

When used on non-blocking sockets, this function might fail with C<$!>
set to C<EAGAIN> or equivalent, in which case you are free to try. It
should succeed if called on a socket that indicates writability (e.g. via
C<select>).

Example: pass a file handle over an open socket.

   IO::FDPass::send fileno $socket, fileno $fh
      or die "unable to pass file handle: $!";

=item $fd = IO::FDPass::recv $socket_fd

Receive a file descriptor from the socket and return it if successful. On
errors, return C<-1>.

Note that I<both> C<$socket_fd> and the returned file descriptor are, in
fact, file descriptors, not handles.

When used on non-blocking sockets, this function might fail with C<$!> set
to C<EAGAIN> or equivalent, in which case you are free to try again. It
should succeed if called on a socket that indicates readability (e.g. via
C<select>).

Example: receive a file descriptor from a blocking socket and convert it
to a file handle.

  my $fd = IO::FDPass::recv fileno $socket;
  $fd >= 0 or die "unable to receive file handle: $!";
  open my $fh, "+<&=$fd"
     or die "unable to convert file descriptor to handle: $!";

=back

=head1 PORTABILITY NOTES

This module has been tested on GNU/Linux x86 and amd64, NetBSD 6, OS X
10.5, Windows 2000 ActivePerl 5.10, Solaris 10, OpenBSD 4.4, 4.5, 4.8 and
5.0, DragonFly BSD, FreeBSD 7, 8 and 9, Windows 7 + ActivePerl 5.16.3 32
and 64 bit and Strawberry Perl 5.16.3 32 and 64 bit, and found to work,
although ActivePerl 32 bit needed a newer MinGW version (that supports XP
and higher).

However, windows doesn't support asynchronous file descriptor passing, so
the source process must still be around when the destination process wants
to receive the file handle. Also, if the target process fails to fetch the
handle for any reason (crashes, fails to call C<recv> etc.), the handle
will leak, so never do that.

Also, on windows, the receiving process must have the PROCESS_DUP_HANDLE
access right on the sender process for this module to work.

Cygwin is not supported at the moment, as file descriptor passing in
cygwin is not supported, and cannot be rolled on your own as cygwin has no
(working) method of opening a handle as fd. That is, it has one, but that
one isn't exposed to programs, and only used for stdin/out/err. Sigh.

=head1 OTHER MODULES

At the time of this writing, the author of this module was aware of two
other file descriptor passing modules on CPAN: L<File::FDPasser> and
L<AnyEvent::FDPasser>.

The former hasn't seen any release for over a decade, isn't 64 bit clean
and it's author didn't respond to my mail with the fix, so doesn't work on
many 64 bit machines. It does, however, support a number of pre-standard
unices, basically everything of relevance at the time it was written.

The latter seems to have similar support for antique unices, and doesn't
seem to suffer from 64 bit bugs, but inexplicably has a large perl
part, doesn't support mixing data and file descriptors, and requires
AnyEvent. Presumably that makes it much more user friendly than this
module (skimming the manpage shows that a lot of thought has gone into
it, and you are well advised to read it and maybe use it before trying a
low-level module such as this one). In fact, the manpage discusses even
more file descriptor passing modules on CPAN.

Neither seems to support native win32 perls.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

