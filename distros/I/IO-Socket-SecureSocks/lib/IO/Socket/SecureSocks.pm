package IO::Socket::SecureSocks;

use strict;
use warnings;

use vars qw(@ISA $VERSION);

require Exporter;
require IO::Socket::Socks;
require IO::Socket::SSL;

@IO::Socket::Socks::ISA = qw(Exporter IO::Socket::SSL);
@ISA = qw(Exporter IO::Socket::Socks);
$VERSION = '0.2';

1;

__END__

=head1 NAME

IO::Socket::SecureSocks - Doing socks over a secure wire (sockss)

=head1 SYNOPSIS

  use strict;
  use IO::Socket::SecureSocks;

  my $sock = IO::Socket::SecureSocks->new(
    ProxyAddr   => 'some.ssl.socks.server',
    ProxyPort   => 1081, # default sockss port
    Username    => 'socksuser',
    Password    => 'sockspassword',
    ConnectAddr => 'server.to.connect.to',
    ConnectPort => 80,
    Timeout     => 60
  ) or die;

=head1 DESCRIPTION

IO::Socket::SecureSocks connects to a SOCKS v5 proxy over a secure line (SSL), tells it to open a connection to a remote host/port
when the object is created. The object you receive can be used directly as a socket for sending and receiving data from the remote host.

=head1 SEE ALSO

L<IO::Socket::Socks|IO::Socket::Socks>, L<IO::Socket::SSL|IO::Socket::SSL>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
