package Linux::Event::IO::Sock;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

1;

__END__

=head1 NAME

Linux::Event::IO::Sock - Linux socket I/O namespace

=head1 DESCRIPTION

C<Linux::Event::IO::Sock> groups public socket leaves by Linux socket type.
Use L<Linux::Event::IO::Sock::Stream> for C<SOCK_STREAM> sockets,
L<Linux::Event::IO::Sock::Dgram> for C<SOCK_DGRAM> sockets, and
L<Linux::Event::IO::Sock::Listener> for listening stream sockets.

=cut
