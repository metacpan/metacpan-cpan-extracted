package Lemonldap::NG::Common::TOTP;

# This module is inspired by Auth::GoogleAuth written by Gryphon Shafer
# <gryphon@cpan.org>

use strict;
use Mouse;
use Convert::Base32 qw(decode_base32 encode_base32);
use Crypt::URandom;
use Digest::HMAC_SHA1 'hmac_sha1_hex';

our $VERSION = '2.0.10';

# Verify that TOTP $code matches with $secret
sub verifyCode {
    my ( $self, $interval, $range, $digits, $secret, $code ) = @_;
    my $s = eval { decode_base32($secret) };
    if ($@) {
        $self->logger->error('Bad characters in TOTP secret');
        return -1;
    }
    for ( -$range .. $range ) {
        if ( $code eq $self->_code( $s, $_, $interval, $digits ) ) {
            $self->userLogger->info("Codes match at range $_");
            return 1;
        }
    }
    return 0;
}

# Internal subroutine that calculates TOTP code using $secret and $interval
sub _code {
    my ( $self, $secret, $r, $interval, $digits ) = @_;
    my $hmac = hmac_sha1_hex(
        pack( 'H*',
            sprintf( '%016x', int( ( time - $r * $interval ) / $interval ) ) ),
        $secret,
    );

    return sprintf(
        '%0' . $digits . 'd',
        (
            hex( substr( $hmac, hex( substr( $hmac, -1 ) ) * 2, 8 ) ) &
              0x7fffffff
        ) % 10**$digits
    );
}

# Simply generate new base32 secret
sub newSecret {
    my ($self) = @_;
    return encode_base32( Crypt::URandom::urandom(20) );
}

1;
