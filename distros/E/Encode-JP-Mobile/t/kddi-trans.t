use strict;
use warnings;
use Encode;
use Encode::JP::Mobile;
use Test::More tests => 4;

my $sjis     = "\xf6\x59";
my $kddi_unicode = "\x{E481}";
my $auto_unicode = "\x{EF59}";

roundtrip($sjis);

sub roundtrip {
    my $bytes = shift;
    is decode("x-sjis-kddi-cp932-raw", $bytes), $kddi_unicode;
    is encode("x-sjis-kddi-cp932-raw", $kddi_unicode), $sjis;
    is decode("x-sjis-kddi-auto-raw", $bytes), $auto_unicode;
    is encode("x-sjis-kddi-auto-raw", $auto_unicode), $sjis;
}

