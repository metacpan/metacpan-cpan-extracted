package IO::Sockatmark;

require 5.005;
use strict;

require Exporter;
require DynaLoader;
use vars qw(@ISA @EXPORT $VERSION);

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw( sockatmark );

$VERSION = '1.00';

bootstrap IO::Sockatmark $VERSION;

sub IO::Socket::atmark { return sockatmark($_[0]) }

1;
__END__

=head1 NAME

IO::Sockatmark - Perl extension for TCP urgent data

=head1 SYNOPSIS

  use IO::Sockatmark;
  use IO::Socket;

  my $sock = IO::Socket::INET->new('some_server');
  $sock->read(1024,$data) until $sock->atmark;

=head1 DESCRIPTION

This module adds the atmark() method to the standard IO::Socket class.
This can be used to detect the "mark" created by the receipt of TCP
urgent data.

=head2 Methods

=over 4

=item $flag = $socket->atmark()

The atmark() method true if the socket is currently positioned at the
urgent data mark, false otherwise.

=back

=head2 Exported functions

=over 4

=item $flag = sockatmark($socket)

The atmark() function returns true if the socket is currently positioned
at the urgent data mark, false otherwise.  This will work with an IO::Socket
object, as well as with a conventional filehandle socket.

=back

=head1 CAVEATS

This module is critically dependent on the system ioctl() constant
SIOCATMARK, which is located in different places on different systems.
The module compiles and works correctly on Linux, Solaris and Tru64
Unix systems, but probably needs tweaking to compile on others.
Please send patches.

=head1 AUTHOR

Copyright 2001, Lincoln Stein <lstein@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=head1 SEE ALSO

perl(1), IO::Socket(3)

=cut
