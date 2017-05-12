use strict;
use warnings;
use Encode;
use Encode::JP::Mobile;
use Test::More;

my $sjis = "\x81\x60";
my @tildes = qw/FF5E 301C/;
my @sjis_encodings = qw/x-sjis-docomo x-sjis-kddi-cp932-raw x-sjis-kddi-auto x-sjis-vodafone x-sjis-vodafone-auto x-sjis-airh/;
my @utf8_encodings = qw/x-utf8-docomo x-utf8-kddi x-utf8-vodafone/;

plan tests => @sjis_encodings*@tildes + @utf8_encodings*@tildes*2;

for my $encoding (@sjis_encodings) {
    for my $char (@tildes) {
        is encode($encoding, chr hex $char), $sjis, "U+$char $encoding";
    }
}

for my $encoding (@utf8_encodings) {
    for my $char (@tildes) {
        is encode($encoding, chr hex $char), encode('utf8', chr hex $char), "U+$char $encoding";
        is decode($encoding, encode($encoding, chr hex $char)), chr hex $char, "U+$char $encoding(roundtrip safe)";
    }
}

