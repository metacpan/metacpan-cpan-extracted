package DigiByte::DigiID;
$DigiByte::DigiID::VERSION = '0.003';
use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(
  extract_nonce
  get_qrcode
  verify_signature
);

use Crypto::ECC;
use Crypt::OpenPGP::Digest;    ## RIPEMD160
use Crypt::OpenSSL::Random;
use Digest::SHA qw(sha256);
use Math::BigInt lib => 'GMP';
use MIME::Base64 qw(decode_base64);
use String::Pad qw(pad);
use URI::Escape qw(uri_escape);

my $STR_PAD_LEFT = 'l';
my %SECP256K1    = (
    a => 00,
    b => 07,
    prime =>
      '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F',
    x => '0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798',
    y => '0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8',
    order =>
      '0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
);

sub get_qrcode {
    my ( $server_domain, %options ) = @_;

    my $nonce = $options{nonce} // unpack( "H*",
        pack( "B*", Crypt::OpenSSL::Random::random_pseudo_bytes(16) ) );

    my $path = $options{path} // '/callback';

    my $url = "digiid://$server_domain$path?x=$nonce";

    if ( $options{nossl} ) {
        $url .= '&u=1';
    }

    my $str = uri_escape($url);

    return (
        nonce    => $nonce,
        callback => $url,
        image =>
          "https://chart.googleapis.com/chart?chs=200x200&cht=qr&chl=$str",
    );
}

sub extract_nonce {
    my ($uri)   = @_;
    my ($nonce) = ( $uri =~ m/[\?\&]x=([^\&]+)/ );
    return $nonce;
}

sub verify_signature {
    my ( $address, $signature, $message, $testnet ) = @_;

    my $decoded_address = _base58check_decode( $address, $testnet );
    my @decoded_address = split //, $decoded_address;

    if (   length($decoded_address) != 21
        || ( $decoded_address[0] ne "\x1E" && !$testnet )
        || ( $decoded_address[0] ne "\x6F" && $testnet ) )
    {
        die "invalid DigiByte address";
    }

    my $decoded_signature = decode_base64($signature);
    my @decoded_signature = split //, $decoded_signature;

    if ( length($decoded_signature) != 65 ) {
        die "invalid signature";
    }

    my $recovery_flags = ord( $decoded_signature[0] ) - 27;

    if ( $recovery_flags < 0 || $recovery_flags > 7 ) {
        die "invalid signature type";
    }

    my $is_compressed = ( $recovery_flags & 4 ) != 0;

    my $message_hash = sha256(
        sha256(
                "\x19DigiByte Signed Message:\n"
              . _num_to_var_int_string( length($message) )
              . $message
        )
    );

    my $pubkey = do {
        my $r = _bin2gmp( substr( $decoded_signature, 1,  32 ) );
        my $s = _bin2gmp( substr( $decoded_signature, 33, 32 ) );
        my $e = _bin2gmp($message_hash);
        my $g = $Point->new(%SECP256K1);

        _recover_pubkey( $r, $s, $e, $recovery_flags, $g );
    };

    if ( !$pubkey ) {
        die 'unable to recover key';
    }

    my $point = $pubkey->point;

    my $pub_bin_str;

    ## see that the key we recovered is for the address given
    if ($is_compressed) {
        $pub_bin_str = ( _is_bignum_even( $point->y ) ? "\x02" : "\x03" )
          . pad( _gmp2bin( $point->x ), 32, $STR_PAD_LEFT, "\x00" );
    }
    else {
        $pub_bin_str = "\x04"
          . pad( _gmp2bin( $point->x ), 32, $STR_PAD_LEFT, "\x00" )
          . pad( _gmp2bin( $point->y ), 32, $STR_PAD_LEFT, "\x00" );
    }

    my $ripemd160 = Crypt::OpenPGP::Digest->new('RIPEMD160');

    my $derived_address;

    if ($testnet) {
        $derived_address = "\x6F" . $ripemd160->hash( sha256($pub_bin_str) );
    }
    else {
        $derived_address = "\x1E" . $ripemd160->hash( sha256($pub_bin_str) );
    }

    return $decoded_address eq $derived_address;
}

sub _base58check_decode {
    my ( $address, $testnet ) = @_;

    my $decoded_address = $address;

    $decoded_address =~
      tr{123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz}
                          {0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuv};

    $decoded_address =~ s/^0+//;

    my $v = Math::BigInt->from_base( $decoded_address, 58 );

    $v = _gmp2bin($v);

    foreach my $chr ( split //, $address ) {
        if ( $chr ne '1' ) {
            last;
        }
        if ($testnet) {
            $v = "\x6F$v";
        }
        else {
            $v = "\x00$v";
        }
    }

    my $checksum = substr $v, -4;

    $v = substr $v, 0, -4;

    my $exp_check_sum = substr sha256( sha256($v) ), 0, 4;

    if ( $exp_check_sum ne $checksum ) {
        die "Invalid checksum";
    }

    return $v;
}

sub _num_to_var_int_string {
    my ($i) = @_;

    if ( $i < 0xfd ) {
        return chr($i);
    }
    elsif ( $i <= 0xffff ) {
        return pack( 'Cv', 0xfd, $i );
    }
    elsif ( $i <= 0xffffffff ) {
        return pack( 'CV', 0xfe, $i );
    }
    else {
        die 'int too large';
    }
}

sub _bin2gmp {
    my ($bin_str) = @_;

    my $v = Math::BigInt->new(0);

    foreach my $ch ( split //, $bin_str ) {
        $v *= 256;
        $v += ord $ch;
    }

    return $v;
}

sub _gmp2bin {
    my ($v) = @_;

    my $bin_str = '';

    while ( ( $v <=> 0 ) > 0 ) {
        my $r;
        ( $v, $r ) = ( $v / 256, $v % 256 );
        $bin_str = chr($r) . $bin_str;
    }

    return $bin_str;
}

sub _recover_pubkey {
    my ( $r, $s, $e, $recovery_flags, $_g ) = @_;

    my $is_y_even     = ( $recovery_flags & 1 ) != 0;
    my $is_second_key = ( $recovery_flags & 2 ) != 0;

    my $signature = $Signature->new( r => $r->copy, s => $s->copy );

    my $p_over_four = ( $_g->prime + 1 ) / 4;

    my $x;

    if ($is_second_key) {
        $x = $r + $_g->order;
    }
    else {
        $x = $r->copy;
    }

    my $alpha = ( ( ( $x**3 ) + ( $_g->a * $x ) ) + $_g->b ) % $_g->prime;
    my $beta = _modular_exp( $alpha, $p_over_four, $_g->prime );

    my $y;

    my $is_bignum_even = _is_bignum_even($beta);

    if ( $is_bignum_even == $is_y_even ) {
        $y = $_g->prime - $beta;
    }
    else {
        $y = $beta;
    }

    my $_r = $_g->copy(
        x => $x,
        y => $y,
    );

    my $r_inv = $r->bmodinv( $_g->order );

    my $mul_p = $Point->mul( $e, $_g );

    my $e_g_neg = $mul_p->negative;

    my $_q =
      $Point->mul( $r_inv, $Point->add( $Point->mul( $s, $_r ), $e_g_neg ) );

    my $q_k = $PublicKey->new( generator => $_g, point => $_q );

    return $q_k->verifies( $e, $signature ) ? $q_k : 0;
}

sub _modular_exp {
    my ( $base, $exponent, $modulus ) = @_;

    if ( $exponent < 0 ) {
        die "Negative exponents (" . $exponent . ") not allowed";
    }

    return $base->copy->bmodpow( $exponent, $modulus );
}

sub _is_bignum_even {
    my ($bn_str) = @_;

    my @bn_str = split //, $bn_str;

    my $test = int( $bn_str[ length($bn_str) - 1 ] ) & 1;

    return $test == 0;
}

1;

=head1 NAME

Digi-ID implementation in Perl5

=head1 DESCRIPTION

Perl5 implementation of [Digi-ID](https://www.digi-id.io/).

=head2 Digi-ID Open Authentication Protocol

Pure DigiByte sites and applications shouldn't have to rely on artificial identification methods such as usernames and passwords. Digi-ID is an open authentication protocol allowing simple and secure authentication using public-key cryptography.

Classical password authentication is an insecure process that could be solved with public key cryptography. The problem however is that it theoretically offloads a lot of complexity and responsibility on the user. Managing private keys securely is complex. However this complexity is already addressed in the DigiByte ecosystem. So doing public key authentication is practically a free lunch to DigiByte users.

=head2 The protocol is based on the following BIP draft

https://github.com/bitid/bitid/blob/master/BIP_draft.md

=head1 USAGE IN WEB APPLICATION

 use Dancer2;
 use DigiByte::DigiID qw(get_qrcode extract_nonce verify_signature);

 get '/login' => sub {
     template 'login' => {
         qrcode => {get_qrcode(request->host)},
     };
 };

 get '/callback' => sub {
    my $credential = from_json do { 
        my $input = request->env->{'psgi.input'};
        local $/; <$input>;
    } or halt "credential not found";

    my $nonce = extract_nonce($credential->{uri})
        or do { 
            status 403; 
            return "Nonce is missing";
        };

    eval { verify_signature(@$credential{qw(address signature uri)}) }
        or do { 
            status(403);
            return "Invalid credential, $@";
        };

    my $db = DB->schema; ## using dbix-lite for example

    my $user = $db->table('digiid_users')
        ->find({digiid => $credential->{address}})
        or do {
            status(403);
            return "digiid is not found: $credential->{address}";
        };

    $db->transaction(sub {
        $db->table('digiid_sessions')->insert({
            nonce      => $nonce,
            digiid     => $user->id,
            created_at => \'NOW()',
        });
    });

    return 'OK';
 };

 get '/ajax' => sub {
    content_type 'application/json';

    my $nonce = params->{nonce}
        or return to_json {ok => 0, error => 'missing nonce'};

    my $db = DB->schema; ## using dbix-lite for example

    my $session = $db->table('digiid_sessions')
        ->find({nonce => $nonce})
            or return to_json {ok => 0};

    my $user = $session->get_digiid_users->get_user
        or return to_json {ok => 0, next => 'scan to login in digibyte wallet'};

    $session->delete;

	return to_json {ok => 1};
 };

 dance;

=head1 Demo

https://digibyteforums.io/ (Has a custom interface on top)

=head1 Notes

* Pure Perl5 implementation, no need to run a DigiByte node

=head1 Credit

Direct Translation from PHP to Perl5 - https://github.com/DigiByte-Core/digiid-php/blob/master/DigiID.php

=cut
