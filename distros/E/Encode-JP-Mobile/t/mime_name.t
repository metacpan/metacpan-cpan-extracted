use strict;
use warnings;
use Encode;
use Encode::JP::Mobile;
use Test::More;

my @utf8_encodings = qw(
    x-utf8-docomo
    x-utf8-softbank
    x-utf8-kddi
    MIME-Header-JP-Mobile-SoftBank-UTF8
);
my @sjis_encodings = qw(
    x-sjis-imode
    x-sjis-softbank
    x-sjis-softbank-auto
    x-sjis-kddi-cp932-raw
    x-sjis-kddi-auto
    x-sjis-airedge
    x-sjis-docomo-raw
    x-sjis-softbank-raw
    x-sjis-softbank-auto-raw
    x-sjis-kddi-cp932-raw
    x-sjis-kddi-auto-raw
    x-sjis-airh-raw
    MIME-Header-JP-Mobile-DoCoMo-SJIS
    MIME-Header-JP-Mobile-KDDI-SJIS
    MIME-Header-JP-Mobile-SoftBank-SJIS
    MIME-Header-JP-Mobile-Airedge-SJIS
);
my @jis_encodings = qw(
    x-iso-2022-jp-kddi
    x-iso-2022-jp-kddi-auto
);

plan tests => @sjis_encodings + @jis_encodings + @utf8_encodings;

for (@utf8_encodings) {
    is Encode::find_encoding($_)->mime_name, 'UTF-8', $_;
}
for (@sjis_encodings) {
    is Encode::find_encoding($_)->mime_name, 'Shift_JIS', $_;
}
for (@jis_encodings) {
    is Encode::find_encoding($_)->mime_name, 'ISO-2022-JP', $_;
}
