# PODNAME: IO::SocketAlarm::Util
# This package is defined in XS loaded by IO::SocketAlarm.
# This file stub exists for documentation and to allow 'use ...Util'
require IO::SocketAlarm;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::SocketAlarm::Util

=head1 EXPORTS

=head2 socketalarm

  $alarm= socketalarm($socket);
  $alarm= socketalarm($socket, @actions);
  $alarm= socketalarm($socket, $event_mask, @actions);

This is a shortcut for L<IO::SocketAlarm-E<gt>new|IO::SocketAlarm/new>:

  $alarm= IO::SocketAlarm->new(
    socket => $socket,
    events => $event_mask,
    actions => \@actions,
  );
  $alarm->start;

=head2 is_socket

  $bool= is_socket($thing);

Returns true if and only if the parameter is a socket at the operating system level.
(for instance, the socket must not have been C<close>d, which would release that file
descriptor) It permits file handles or file descriptor numbers.

=head2 get_fd_table_str

  $str= get_fd_table();        // scans fd 0..1023
  $str= get_fd_table($max_fd); // specify your own upper limit

Return a human-readable string describing each open file descriptor.  This is just for
debugging, and relies on /proc/self/fd/ symlinks for anything other than sockets.
For sockets, it prints the bound name and peer name of the socket.

=head2 Event Constants

=over

=item EVENT_SHUT

Triggers when the TCP connection is being shutdown (the TCP "FIN" flag) or any detectable
condition that means communication on the socket is no longer possible and is the result of an
external event.

While this event is the whole point of this module, there actually isn't a good cross-platform
way to identify this condition!  Linux and FreeBSD provide a reliable POLLRDHUP flag to poll()
to get notified of the TCP 'FIN' flag, but on OpenBSD and Mac and Windows the best you can do
is check for a zero-length "peek" on the socket, which only works if the application has already
read all incoming data on the socket.  (but this works for typical HTTP worker pools where only
one request will be sent from the reverse proxy to the worker, before closing the connection)

The poll() POLLHUP flag also triggers this event, for socket types (or pipes) that emit this
flag in a useful manner.

=item EVENT_EOF

Triggers when the file handle indicates EOF by a successful zero-length read.  This is checked
by performing a C<< recv(sock, buf, len, MSG_PEEK|MSG_DONTWAIT) >> so that no actual data is
removed from the socket.  If your peer writes data to the socket before closing it, you won't
get this event until you read that data.  There is no efficient way to wait for this event when
the peer has sent additional data; this module falls back to checking at short intervals in that
case, which is inefficient and may fail to deliver the event when you need it delivered.

But again, this generally works in a HTTP worker pool where this module is intended to be used.

=item EVENT_IN

Triggers if there is any data available to be read from the socket.  This sets the POLLIN flag
on the call to poll().

=item EVENT_PRI

Triggers if there is any priority data available to be read from the socket.  This sets the
POLLPRI flag on the call to poll().

=item EVENT_CLOSE

Triggers when another thread on this application has called "close" on the socket file handle.
More specifically, it triggers when "stat()" fails or reports a different device or inode for
the file descriptor, indicating that descriptor number has been closed or recycled.

(it is a better idea to make sure you cancel the alarm before returning to any code which might
 close your end of the socket)

=back

=head1 VERSION

version 0.003

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
