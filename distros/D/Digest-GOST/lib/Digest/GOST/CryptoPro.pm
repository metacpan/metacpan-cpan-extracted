package Digest::GOST::CryptoPro;

use strict;
use warnings;
use parent qw(Digest::GOST);

our @EXPORT_OK = qw(gost gost_hex gost_base64);


1;

__END__

=head1 NAME

Digest::GOST::CryptoPro - uses the CryptoPro parameters from RFC 4357

=head1 DESCRIPTION

The C<Digest::GOST::CryptoPro> module uses the "production ready" CryptoPro
parameters from RFC 4357.

The interface is identical to that of C<Digest::GOST>.

=head1 SEE ALSO

L<Digest::GOST>

L<https://tools.ietf.org/html/rfc4357>

=cut
