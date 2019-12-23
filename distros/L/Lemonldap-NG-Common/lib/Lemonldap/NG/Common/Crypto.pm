##@file
# Extend Crypt::Rijndael to get several keys from a single secret key,
# add base64 encoding of binary data, and cipher hexadecimal data.

##@class
# Extend Crypt::Rijndael to get several keys from a single secret key,
# add base64 encoding of binary data, and cipher hexadecimal data.
# $Lemonldap::NG::Common::Crypto::msg contains Crypt::Rijndael errors.
package Lemonldap::NG::Common::Crypto;

use strict;
use Crypt::Rijndael;
use MIME::Base64;
use Digest::SHA;
use bytes;

our $VERSION = '2.0.0';
my ( $newIv, $randG, $hash );
$hash = \&Digest::SHA::sha256;

use constant HMAC_LENGTH => 32;
use constant IV_LENGTH   => 16;

# Build initialization vector subroutine
BEGIN {
    eval { require Crypt::URandom; Crypt::URandom::urandom(IV_LENGTH) };
    if ($@) {
        $newIv = sub {
            return bytes::substr( Digest::SHA::sha1( rand() . time . {} ),
                0, IV_LENGTH );
        };
        $randG = sub { return int( rand( $_[0] ) ) };
    }
    else {
        $newIv = sub { return Crypt::URandom::urandom(IV_LENGTH) };
        $randG = sub {
            return
              int( unpack( "C", Crypt::URandom::urandom(1) ) * $_[0] / 256 );
        };
    }
}

our $msg;

## @cmethod Lemonldap::NG::Common::Crypto new(string key, string mode)
# Constructor
# @param key key defined in LL::NG conf
# @param mode Crypt::Rijndael constant
# @return Lemonldap::NG::Common::Crypto object
sub new {
    my ( $class, $key, $mode ) = @_;
    $mode ||= Crypt::Rijndael::MODE_CBC();
    my $self = {
        key     => $key,
        mode    => $mode,
        ciphers => {}
    };
    return bless $self, $class;
}

## @method private Crypt::Rijndael _getCipher(string key)
# Returns a Crypt::Rijndael object whose key is mainKey ^ secondKey,
# where mainKey is defined in LL::NG conf,
# and secondKey is set in code so as to get different keys
# @param key that secondary key
# @return Crypt::Rijndael object
sub _getCipher {
    my ( $self, $key ) = @_;
    $key ||= "";
    $self->{ciphers}->{$key} ||=
      Crypt::Rijndael->new( $hash->( $self->{key}, $key ), $self->{mode} );
    return $self->{ciphers}->{$key};
}

## @method string encrypt(string data)
# Encrypt $data and return it in Base64 format
# @param data data to encrypt
# @return encrypted data in Base64 format
sub encrypt {
    my ( $self, $data, $low ) = @_;

    # pad $data so that its length be multiple of 16 bytes
    $data //= '';
    my $l = bytes::length($data) % 16;
    $data .= "\0" x ( 16 - $l ) unless ( $l == 0 );

    my $iv =
      $low
      ? bytes::substr( Digest::SHA::sha1( rand() . time . {} ), 0, IV_LENGTH )
      : $newIv->();
    my $hmac = $hash->($data);
    eval {
        $data =
          encode_base64(
            $iv . $self->_getCipher->set_iv($iv)->encrypt( $hmac . $data ),
            '' );
    };

    if ($@) {
        $msg = "Crypt::Rijndael error : $@";
        return undef;
    }
    else {
        $msg = '';
        chomp $data;
        return $data;
    }
}

## @method string decrypt(string data)
# Decrypt $data and return it
# @param data data to decrypt in Base64 format
# @return decrypted data
sub decrypt {
    my ( $self, $data ) = @_;
    $data =~ s/%2B/\+/ig;
    $data =~ s/%2F/\//ig;
    $data =~ s/%3D/=/ig;
    $data =~ s/%0A/\n/ig;
    $data = decode_base64($data);
    my $iv;
    $iv   = bytes::substr( $data, 0, IV_LENGTH );
    $data = bytes::substr( $data, IV_LENGTH );
    eval { $data = $self->_getCipher->set_iv($iv)->decrypt($data); };

    if ($@) {
        $msg = "Crypt::Rijndael error : $@";
        return undef;
    }
    my $hmac = bytes::substr( $data, 0, HMAC_LENGTH );
    $data = bytes::substr( $data, HMAC_LENGTH );
    if ( $hash->($data) ne $hmac ) {
        $msg = "Bad MAC";
        return undef;
    }
    else {
        $msg = '';

        # Obscure Perl re bug...
        $data .= "\0";
        $data =~ s/\0*$//;
        return $data;
    }
}

## @method string encryptHex(string data, string key)
# Encrypt $data and return it in hexadecimal format
# Data must be hexadecimal and its length must be a multiple of 32
# the encrypted data have same length as the original data
# @param data data to encrypt
# @param key optional secondary key
# @return encrypted data in hexadecimal data
sub encryptHex {
    my ( $self, $data, $key ) = @_;
    return _cryptHex( $self, $data, $key, "encrypt" );
}

## @method string decryptHex(string data, string key)
# Decrypt $data and return it in hexadecimal format
# Data must be hexadecimal and its length must be a multiple of 32
# the decrypted data have same length as the encrypted data
# @param data data to decrypt
# @param key optional secondary key
# @return decrypted data in hexadecimal data
sub decryptHex {
    my ( $self, $data, $key ) = @_;
    return _cryptHex( $self, $data, $key, "decrypt" );
}

## @method private string _cryptHex (string data, string key, string sub)
# Auxiliary method to share code between encrypt and decrypt
# @param data data to decrypt
# @param key secondary key
# @param sub may be "encrypt" or "decrypt"
# @return decrypted data in hexadecimal data
sub _cryptHex {
    my ( $self, $data, $key, $sub ) = @_;
    unless ( $data =~ /^([0-9a-fA-F]{2})*$/ ) {
        $msg =
"Lemonldap::NG::Common::Crypto::${sub}Hex error : data is not hexadecimal";
        return undef;
    }

    # $data's length must be multiple of 32,
    # since Rijndael requires data length multiple of 16
    unless ( bytes::length($data) % 32 == 0 ) {
        $msg =
"Lemonldap::NG::Common::Crypto::${sub}Hex error : data length must be multiple of 32";
        return undef;
    }
    my $iv;
    if ( $sub eq 'encrypt' ) {
        $iv = $newIv->();
    }
    $data = pack "H*", $data;
    if ( $sub eq 'decrypt' ) {
        $iv   = bytes::substr( $data, 0, IV_LENGTH );
        $data = bytes::substr( $data, IV_LENGTH );
    }
    eval { $data = $self->_getCipher($key)->set_iv($iv)->$sub($data); };
    if ($@) {
        $msg = "Crypt::Rijndael error : $@";
        return undef;
    }
    if ( $sub eq 'encrypt' ) {
        $data = $iv . $data;
    }
    $msg  = "";
    $data = unpack "H*", $data;
    return $data;
}

sub srandom {
    eval { require String::Random };
    if ($@) {
        die 'Missing recommended dependency to String::Random';
    }
    return String::Random->new( rand_gen => $randG );
}

1;
