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
use Digest::MD5 qw(md5);
use bytes;

our $VERSION = '2.0.0';

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
      Crypt::Rijndael->new( md5( $self->{key}, $key ), $self->{mode} );
    return $self->{ciphers}->{$key};
}

## @method string encrypt(string data)
# Encrypt $data and return it in Base64 format
# @param data data to encrypt
# @return encrypted data in Base64 format
sub encrypt {
    my ( $self, $data ) = @_;

    # pad $data so that its length be multiple of 16 bytes
    my $l = bytes::length($data) % 16;
    $data .= "\0" x ( 16 - $l ) unless ( $l == 0 );

    eval { $data = encode_base64( $self->_getCipher->encrypt($data), '' ); };
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
    eval { $data = $self->_getCipher->decrypt( decode_base64($data) ); };
    if ($@) {
        $msg = "Crypt::Rijndael error : $@";
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
    $data = pack "H*", $data;
    eval { $data = $self->_getCipher($key)->$sub($data); };
    if ($@) {
        $msg = "Crypt::Rijndael error : $@";
        return undef;
    }
    $msg = "";
    $data = unpack "H*", $data;
    return $data;
}

1;
