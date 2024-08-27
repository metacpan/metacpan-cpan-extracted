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

=item EVENT_EOF

=item EVENT_IN

=item EVENT_PRI

=item EVENT_CLOSE

=back

=head1 VERSION

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
