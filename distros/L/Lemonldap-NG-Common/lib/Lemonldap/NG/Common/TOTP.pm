package Lemonldap::NG::Common::TOTP;

# This module is inspired by Auth::GoogleAuth written by Gryphon Shafer
# <gryphon@cpan.org>

use strict;
use Mouse;
use Convert::Base32 qw(decode_base32 encode_base32);
use Crypt::URandom;
use Digest::SHA;
use Lemonldap::NG::Common::Crypto;

my $hash_func = {
    "sha1"   => \&Digest::SHA::hmac_sha1_hex,
    "sha256" => \&Digest::SHA::hmac_sha256_hex,
    "sha512" => \&Digest::SHA::hmac_sha512_hex,
};

our $VERSION = '2.23.0';

has key => (
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

has crypto => (
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

# DEPRECATED: legacy API
sub verifyCode {
    my ( $self, $interval, $range, $digits, $stored_secret, $code ) = @_;
    my $result = $self->verify_totp(
        interval        => $interval,
        range_tolerance => $range,
        digits          => $digits,
        stored_secret   => $stored_secret,
        code            => $code,
    );
    if ( $result->{result} == 1 ) {
        return ( wantarray() ? ( 1, $result->{offset} ) : 1 );
    }
    else {
        $self->logger->error( $result->{error} );
        return $result->{result};
    }
}

# Verify that TOTP $code matches with $secret
sub verify_totp {
    my ( $self, %args ) = @_;

    my $interval      = $args{interval} || 30;
    my $digits        = $args{digits}   || 6;
    my $range         = $args{range_tolerance} // 0;
    my $stored_secret = $args{stored_secret};
    my $code          = $args{code};
    my $hash          = $args{hash} || "sha1";

    if ( !$stored_secret ) {
        return {
            result => -1,
            error  => "No secret provided",
        };
    }

    if ( !$code ) {
        return {
            result => -1,
            error  => "No code provided",
        };
    }

    my $secret = $self->get_cleartext_secret($stored_secret);
    if ( !$secret ) {
        return {
            result => -1,
            error  => "Unable to decrypt TOTP secret",
        };
    }

    my $s = eval { decode_base32($secret) };
    if ($@) {
        return {
            result => -1,
            error  => "Bad characters in TOTP secret",
        };
    }
    for ( -$range .. $range ) {
        if ( $code eq $self->_code( $s, $_, $interval, $digits, $hash ) ) {
            return {
                result => 1,
                offset => $_,
            };
        }
    }
    return {
        result => 0,
        error  => "Code did not match",
    };
}

# Internal subroutine that calculates TOTP code using $secret and $interval
sub _code {
    my ( $self, $secret, $offset, $interval, $digits, $hash, $time ) = @_;

    $time ||= time();

    my $hash_func = $hash_func->{$hash};
    die "Unknown hash $hash" unless $hash_func;

    my $hmac = $hash_func->(
        pack( 'H*', sprintf( '%016x', int( $time / $interval ) - $offset ) ),
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
