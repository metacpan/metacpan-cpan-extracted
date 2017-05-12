#!perl -T

use strict;
use warnings;
use Test::More tests => 13;

use GSM::Nbit;
use Encode qw/encode decode/;

my $gsm = GSM::Nbit->new();

my $warn = undef;
local $SIG{__WARN__} = sub {
    my $received = shift;
    $warn = $received;
};

## 1
ok( defined($gsm) && ref $gsm eq 'GSM::Nbit', 'GSM::Nbit->new() works');

## 2
my $text = "hellohello";
my $text_7bit = $gsm->encode_7bit($text);
ok($text_7bit eq 'E8329BFD4697D9EC37', 'GSM::Nbit->encode_7bit() works');

## 3
my $text_orig = $gsm->decode_7bit($text_7bit);
ok($text_orig eq $text, 'GSM::Nbit->decode_7bit() works');

## 4
my $text_7bit_wlen = $gsm->encode_7bit_wlen($text);
ok($text_7bit_wlen eq '0AE8329BFD4697D9EC37', 'GSM::Nbit->encode_7bit_wlen() works');

## 5
$text_orig = $gsm->decode_7bit_wlen($text_7bit_wlen);
ok($text_orig eq $text, 'GSM::Nbit->decode_7bit_wlen() works');

## 6
my $text_8bit = $gsm->encode_8bit($text);
ok($text_8bit eq '68656C6C6F68656C6C6F', 'GSM::Nbit->encode_8bit() works');


## 7
$text_orig = $gsm->decode_8bit($text_8bit);
ok($text_orig eq $text, "GSM::Nbit->decode_8bit() works : $text_orig");


## 8
my $edge1 = 'hellohe';
my $edge11 = 'hellohe@';

my $text_7bit_e1    = $gsm->encode_7bit(encode("gsm0338", $edge1));
my $text_7bit_e11   = $gsm->encode_7bit(encode("gsm0338", $edge11));

ok($text_7bit_e1 eq $text_7bit_e11, "'hellohe' and 'hellohe\@' are the same once encoded with encode_7bit()");

## 9
my $text_7bit_e1_wlen   = $gsm->encode_7bit_wlen(encode("gsm0338", $edge1));
my $text_7bit_e11_wlen  = $gsm->encode_7bit_wlen(encode("gsm0338", $edge11));

ok($text_7bit_e1_wlen ne $text_7bit_e11_wlen, "'hellohe' and 'hellohe\@' should not be the same when encoded with encode_7bit_wlen()");

## 10
my $orig_7bit_e1_wlen   = decode("gsm0338", $gsm->decode_7bit_wlen( $text_7bit_e1_wlen)  );
my $orig_7bit_e11_wlen  = decode("gsm0338", $gsm->decode_7bit_wlen( $text_7bit_e11_wlen) );

ok($orig_7bit_e1_wlen ne $orig_7bit_e11_wlen, "'hellohe' and 'hellohe\@' shouldn't be the same when decoded back - update Encode.pm if this fails!");

## 11
$warn = undef;
my $foo;
my $check = eval{
    $foo = $gsm->decode_7bit_wlen(5);
};
ok((not $check) && (not $@) && (defined $warn) && (not defined $foo), "decode_7bit_wlen warns about crappy data when provided length is too long");

## 12
$warn = undef;
$foo = $gsm->decode_7bit_wlen('00');

ok((not $@) && (not defined $warn) && ($foo eq ''), "giving just '00' to decode_7bit_wlen should pass and return empty string");

## 13
$warn = undef;
$check = eval {
    $foo = $gsm->decode_7bit_wlen('03E8329BFD4697D9EC37');
};

ok((not $check) && (defined $warn) && (not defined $foo), "decode_7bit_wlen warns about too short data for the provided length");

## 14