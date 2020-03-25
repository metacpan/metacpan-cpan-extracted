#!/usr/bin/perl
use 5.012;
use Benchmark qw/timethis timethese cmpthese/;
use Encode::Base2N qw/encode_base64 encode_base64url encode_base32 encode_base16 decode_base64 decode_base32 decode_base16/;
use MIME::Base64();
use MIME::Base32(); 
use MIME::Base32::XS();

my $short = 'hello world hello world';
my $long = 'hello ' x 1000;




say "=========== BASE64 url ==============";
my $SHORT = encode_base64url($short);
my $LONG  = encode_base64url($long);

say "==== encode short ===";
cmpthese(-1, {
    "Encode::Base2N" => sub { encode_base64url($short) },
    "MIME::Base64"   => sub { MIME::Base64::encode_base64url($short) },
});

say "==== encode long ===";
cmpthese(-1, {
    "Encode::Base2N" => sub { encode_base64url($long) },
    "MIME::Base64"   => sub { MIME::Base64::encode_base64url($long) },
});

say "==== decode short ===";
cmpthese(-1, {
    "Encode::Base2N" => sub { decode_base64($SHORT) },
    "MIME::Base64"   => sub { MIME::Base64::decode_base64url($SHORT) },
});

say "==== decode long ===";
cmpthese(-1, {
    "Encode::Base2N" => sub { decode_base64($LONG) },
    "MIME::Base64"   => sub { MIME::Base64::decode_base64url($LONG) },
});




say "=========== BASE64 classic ==============";
$SHORT = encode_base64($short);
$LONG  = encode_base64($long);

say "==== encode short ===";
cmpthese(-1, {
    "Encode::Base2N" => sub { encode_base64($short) },
    "MIME::Base64"   => sub { MIME::Base64::encode_base64($short) },
});

say "==== encode long ===";
cmpthese(-1, {
    "Encode::Base2N" => sub { encode_base64($long) },
    "MIME::Base64"   => sub { MIME::Base64::encode_base64($long) },
});

say "==== decode short ===";
cmpthese(-1, {
    "Encode::Base2N" => sub { decode_base64($SHORT) },
    "MIME::Base64"   => sub { MIME::Base64::decode_base64($SHORT) },
});

say "==== decode long ===";
cmpthese(-1, {
    "Encode::Base2N" => sub { decode_base64($LONG) },
    "MIME::Base64"   => sub { MIME::Base64::decode_base64($LONG) },
});




say "=========== BASE32 ==============";
$SHORT = encode_base32($short);
$LONG  = encode_base32($long);

say "==== encode short ===";
cmpthese(-1, {
    "Encode::Base2N"   => sub { encode_base32($short) },
    "MIME::Base32"     => sub { MIME::Base32::encode($short) },
    "MIME::Base32::XS" => sub { MIME::Base32::XS::encode_base32($short) },
});

say "==== encode long ===";
cmpthese(-1, {
    "Encode::Base2N"   => sub { encode_base32($long) },
    "MIME::Base32"     => sub { MIME::Base32::encode($long) },
    "MIME::Base32::XS" => sub { MIME::Base32::XS::encode_base32($long) },
});

say "==== decode short ===";
cmpthese(-1, {
    "Encode::Base2N"   => sub { decode_base32($SHORT) },
    "MIME::Base32"     => sub { MIME::Base32::decode($SHORT) },
    "MIME::Base32::XS" => sub { MIME::Base32::XS::decode_base32($SHORT) },
});

say "==== decode long ===";
cmpthese(-1, {
    "Encode::Base2N"   => sub { decode_base32($LONG) },
    "MIME::Base32"     => sub { MIME::Base32::decode($LONG) },
    "MIME::Base32::XS" => sub { MIME::Base32::XS::decode_base32($LONG) },
});




say "=========== BASE16 ==============";
$SHORT = encode_base16($short);
$LONG  = encode_base16($long);
timethese(-1, {
    encode_short  => sub { encode_base16($short) },
    encode_long   => sub { encode_base16($long) },
    decode_short  => sub { decode_base16($SHORT) },
    decode_long   => sub { decode_base16($LONG) },
});

