package GPLVote::SignDoc::Client;

# Copyright (c) 2014, Andrey Velikoredchanin.
# This library is free software released under the GNU Lesser General
# Public License, Version 3.  Please read the important licensing and
# disclaimer information included below.

# $Id: Client.pm,v 0.7 2015/02/06 17:23:00 Andrey Velikoredchanin $

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::AES;
use Crypt::CBC;
use Bytes::Random::Secure qw(random_bytes);
use MIME::Base64;
use Digest::SHA qw(sha256_base64 sha256);
use JSON;
use utf8;
use Encode;


use strict;
use Exporter;
use vars qw($VERSION);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = qw(user_sign_is_valid calc_pub_key_id encrypt split_base64);
@EXPORT_OK   = qw(user_sign_is_valid calc_pub_key_id encrypt split_base64);
%EXPORT_TAGS = (DEFAULT => [qw(&user_sign_is_valid &calc_pub_key_id &encrypt &split_base64)]);

BEGIN {
  $VERSION = '0.9';
}

=head1 NAME

GPLVote::SignDoc::Client -  module for helping create GPLVote SignDoc client software.

=head1 SYNOPSIS

 use GPLVote::SignDoc::Client;

 if (user_sign_is_valid($public_key, $sign, $data)) {
    print "Sign of document is CORRECT\n";
 } else {
    print "BAD SIGN!!!\n";
 };

 my $pub_key_id = calc_pub_key_id($public_key);

 my $enc_data = encrypt($public_key, $data);
 
=head1 Methods

=head2 user_sign_is_valid(base64_plain public_key, base64_plain sign, raw data, boolean sha256sign)

Check signature of data.

public_key - RSA public key for check signature. Encoded in Base64 in one string without special
begin/finish strings and without line breaks.

sign - RSA signature. Some format like public_key.

data - signing data for verify signature.

sha256sign - boolean flag for check signature as "SHA256withRSA", else checking as "SHA1withRSA".

Returning true if signature is valid.

=head2 split_base64(base_64 string)

Helping method for separate one long line Base64 on different lines with length 72 chars.

=head2 calc_pub_key_id(base64_plain public_key)

Calculate ID of public key.

=head2 encrypt(base64_plain public_key, raw data)

Encrypt data over public key.

Returning plain Base64 string with encrypted data.

=head1 BUGS

No known bugs, but this does not mean no bugs exist.

=head1 SEE ALSO

http://gplvote.org/

=head1 MAINTAINER

Andrey Velikoredchanin <andy@andyhost.ru>

=head1 AUTHOR

Andrey Velikoredchanin

=head1 COPYRIGHT

GPLVote::SignDoc::Client - module for helping create GPLVote SignDoc client software
Copyright (c) 2014, Andrey Velikoredchanin.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

BECAUSE THIS LIBRARY IS LICENSED FREE OF CHARGE, THIS LIBRARY IS
BEING PROVIDED "AS IS WITH ALL FAULTS," WITHOUT ANY WARRANTIES
OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING, WITHOUT
LIMITATION, ANY IMPLIED WARRANTIES OF TITLE, NONINFRINGEMENT,
MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, AND THE
ENTIRE RISK AS TO SATISFACTORY QUALITY, PERFORMANCE, ACCURACY,
AND EFFORT IS WITH THE YOU.  See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA

=cut


sub user_sign_is_valid {
  my ($b64_pub_key, $b64_sign, $data, $use_sha256_hash) = @_;

  my $b64_open_key = "-----BEGIN PUBLIC KEY-----\n".split_base64($b64_pub_key)."\n-----END PUBLIC KEY-----";
  my $dec_sign = decode_base64($b64_sign);
    
  my $rsa = Crypt::OpenSSL::RSA->new_public_key($b64_open_key);
  $rsa->use_sha256_hash if $use_sha256_hash;
  return($rsa->verify($data, $dec_sign));
}

sub split_base64 {
  my $text = $_[0];
      
  my $res = '';
  while ($text ne '') {
    if (length($text) > 72) {
      $res .= substr($text, 0, 72)."\n";
      $text = substr($text, 72, length($text) - 72);
    } else {
      $res .= $text;
      $text = '';
    };
  };

  return($res);
};

sub calc_pub_key_id {
  my $b64_pub_key = $_[0];

  my $pub_key = decode_base64($b64_pub_key);

  return(sha256_base64($pub_key));
};

sub encrypt {
  my ($b64_pub_key, $data) = @_;

  my $b64_open_key = "-----BEGIN PUBLIC KEY-----\n".split_base64($b64_pub_key)."\n-----END PUBLIC KEY-----";

  my $rsa = Crypt::OpenSSL::RSA->new_public_key($b64_open_key);
  $rsa->use_pkcs1_padding();
  if (length($data) <= 256) {
    return(encode_base64($rsa->encrypt($data), ''));
  } else {
    # First 256 bytes - RSA-encrypted header:
    #   32 bytes - 256-bits AES key
    #   16 bytes - IV for AES
    #   32 bytes - sha256 crc for data
    my $enc_data = '';

    # Random AES (256 bit)
    my $aes_key = random_bytes(32);
    # Random IV (
    my $aes_iv = random_bytes(16);
    # CRC for data
    my $crc = sha256($data);
    
    $enc_data .= $rsa->encrypt($aes_key.$aes_iv.$crc);

    my $aes_cbc = Crypt::CBC->new( -key => $aes_key,
                                    -literal_key => 1,
                                    -keysize => 32,
                                    -cipher => "Crypt::OpenSSL::AES",
                                    -iv => $aes_iv,
                                    -header => 'none' );
    
    $enc_data .= $aes_cbc->encrypt($data);

    return(encode_base64($enc_data, ''));
  };
};

sub to_hash {
  my ($json) = @_;
  my $h;
  my $js = JSON->new();
  # for invalid json
  $js->relaxed(1);
  # convert to utf-8
  $js->utf8;
  eval {
    # eval required for no exception if bad json
    $h = $js->decode($json);
  };
  undef($js);
  return($h);
};

sub from_hash {
  my ($h, $pretty) = @_;

  my $s = '';
  my $js = JSON->new();
  # for invalid json
  $js->relaxed(1);
  $js->pretty(1) if ($pretty);
  eval {
    # eval required for no exception if bad json
    $s = $js->encode($h);
  };
  undef($js);

  return($s);
};

1;