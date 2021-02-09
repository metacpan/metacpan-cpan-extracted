#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 10;
use Crypt::PRNG qw(random_bytes);
use Crypt::PK::ECC 'ecc_shared_secret';
use MIME::Base64 qw( encode_base64url decode_base64url);
use Digest::SHA 'hmac_sha256';
use Crypt::AuthEnc::GCM 'gcm_decrypt_verify';


#================================================================
# hkdf()
#
# Calculates a key derivation using HMAC
# This is a simplified version based on Mat Scales jscript code
# see https://developers.google.com/web/updates/2016/03/web-push-encryption
#
# Notes: all args are expected to be binary strings, as the result
#================================================================
sub hkdf($$$$) {
   my $salt=shift();
   my $ikm=shift();
   my $info=shift();
   my $len=shift();

   my $key=hmac_sha256($ikm,$salt);
   my $infoHmac= hmac_sha256($info,chr(1),$key);  

   return substr($infoHmac,0,$len);
}


#Basic stuff
BEGIN { use_ok('HTTP::Request::Webpush') };
my $send=new_ok( 'HTTP::Request::Webpush' );

#Now setup a dummy subscription endpoint
my $ua_publicKey= "BMj40clWPSKfZTdyaQQjFoEozKUXI3aEZDBFC_2dr0I5ZWX7bvahx3iDRJjbXf6t9FuSuuAq57cEb_R48lmVzPA";
my $ua_privateKey= "ibx1ebRZyWiWNB_fHXHmiLROYXDXD_II8EZ1nqef4VA";
my $auth=random_bytes(16);

my $app_publicKey= "BDIlKk-A0gBOnZ9DWHoEzSFe_HZbDEAY6yYgN6ILmdVC3mS8laszyLPI6FJhVXZpsJPSYlBkAyYrKRVBdD9fydY";
my $app_privateKey= "cLERT3eZx0JfS0pIX6orz_uGBzf1JV0I7PWGCaGfkbg";

my $service={"endpoint"=>"https://foo",
   "expirationTime" => 0,
   "keys"=> {
      "p256dh"=>$ua_publicKey,
      "auth"=> encode_base64url($auth)}};

ok($send->subscription($service) );
ok($send->authbase64($ua_publicKey,$ua_privateKey));


my $payload= <<'EOP';
Podría escribir los versos más tristes esta noche.

Escribir, por ejemplo: "La noche está estrellada,
y tiritan, azules, los astros, a lo lejos".
EOP

$send->content($payload);
ok($send->encode );

my $body=$send->content;
ok (length($body) >= 104);

my $salt=substr($body,0,16);
my $keylength=substr($body,20,1);
ok ($keylength eq "\x41");

my $mess_key=substr($body,21,65);
my $tag=substr($body,-16,16);
my $encoded=substr($body, 86,-16);

my $mk= Crypt::PK::ECC->new(); #This will be the message key
my $sk= Crypt::PK::ECC->new(); #Tis will be the channel key

$sk->import_key_raw(decode_base64url($ua_privateKey), 'secp256r1');

ok ($mk->import_key_raw($mess_key, 'secp256r1'));

my $shared=$sk->shared_secret($mk);

my $key_info='WebPush: info'.chr(0).decode_base64url($ua_publicKey).$mess_key;
my $prk=hkdf($auth, $shared, $key_info,32);

my $cek_info='Content-Encoding: aes128gcm'.chr(0);
my $nonce_info='Content-Encoding: nonce'.chr(0);

my $cek=hkdf($salt,$prk,$cek_info,16);
my $nonce= hkdf($salt, $prk,$nonce_info,12);

my $decrypt=gcm_decrypt_verify('AES', $cek, $nonce, '', $encoded, $tag);

ok ($decrypt);

#Remove the trailing
$decrypt = substr($decrypt,0,-2);
ok ($decrypt eq $payload);



