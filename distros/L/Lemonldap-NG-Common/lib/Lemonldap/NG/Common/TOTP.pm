package Lemonldap::NG::Common::TOTP;

# This module is inspired by Auth::GoogleAuth written by Gryphon Shafer
# <gryphon@cpan.org>

use strict;
use Mouse;
use Convert::Base32 qw(decode_base32 encode_base32);
use Crypt::URandom;
use Digest::HMAC_SHA1 'hmac_sha1_hex';
use Lemonldap::NG::Common::Crypto;

our $VERSION = '2.0.14';

has 'key' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return $self->conf->{totp2fKey} || $self->conf->{key};
    }
);

has encryptSecret => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        return $self->conf->{totp2fEncryptSecret};
    }
);

has 'crypto' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        Lemonldap::NG::Common::Crypto->new( $self->key );
    }
);

use constant PREFIX => "{llngcrypt}";

sub is_encrypted {
    my ( $self, $secret ) = @_;
    return ( substr( $secret, 0, length(PREFIX) ) eq PREFIX );
}

sub get_ciphertext {
    my ( $self, $secret ) = @_;
    return substr( $secret, length(PREFIX) );
}

# This returns the TOTP secret from its stored form
sub get_cleartext_secret {
    my ( $self, $secret ) = @_;
    my $cleartext_secret = $secret;
    if ( $self->is_encrypted($secret) ) {
        $cleartext_secret =
          $self->crypto->decrypt( $self->get_ciphertext($secret) );
    }
    return $cleartext_secret;
}

# This returns the cleartext or encrypted code for storage
sub get_storable_secret {
    my ( $self, $secret ) = @_;
    my $storable_secret = $secret;
    if ( $self->encryptSecret ) {
        $storable_secret = PREFIX . $self->crypto->encrypt($secret);
    }
    return $storable_secret;
}

# Verify that TOTP $code matches with $secret
sub verifyCode {
    my ( $self, $interval, $range, $digits, $stored_secret, $code ) = @_;

    my $secret = $self->get_cleartext_secret($stored_secret);
    if ( !$secret ) {
        $self->logger->error('Unable to decrypt TOTP secret');
        return -1;
    }

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
