use strict;
use warnings;
use Encode;
use Encode::JP::Mobile ':props';

use Test::More;

eval { require YAML };
plan skip_all => $@ if $@;

my $dat = YAML::LoadFile("dat/kddi-table.yaml");
plan tests => 20 * @$dat;

for my $r (@$dat) {
    my $sjis = pack "H*", $r->{sjis};
    my $jis  = "\e\$B" . pack("H*", $r->{email_jis}) . "\e(B";

    my $unicode = chr hex $r->{unicode};
    my $auto = chr hex $r->{unicode_auto};
    is decode("x-sjis-kddi-cp932-raw", $sjis), $unicode, $r->{unicode};
    is encode("x-sjis-kddi-cp932-raw", $unicode), $sjis, $r->{unicode};
    is encode("x-sjis-kddi-auto-raw", $auto), $sjis, $r->{unicode};
    is decode("x-sjis-kddi-auto-raw", $sjis), $auto, $r->{unicode};
    is decode("x-iso-2022-jp-kddi", $jis), $unicode, $r->{unicode};
    is encode("x-iso-2022-jp-kddi", $unicode), $jis, $r->{unicode};
    is decode("x-iso-2022-jp-kddi-auto", $jis), $auto, $r->{unicode};
    is encode("x-iso-2022-jp-kddi-auto", $auto), $jis, $r->{unicode};

    # is decode("x-utf8-kddi", encode("x-utf8-kddi", $auto)), $auto, $r->{unicode};
    my $x = encode("x-utf8-kddi", $auto);
    Encode::_utf8_on($x);
    is $x, $auto, $r->{unicode};

    if ($unicode =~ /\p{InKDDISoftBankConflicts}/) {
        isnt decode('x-utf8-kddi', encode('x-utf8-kddi', $unicode)), $unicode, $r->{unicode};
    } else {
        eval { encode("x-utf8-kddi", $unicode, Encode::FB_CROAK) };
        like $@, qr{does not map to x-utf8-kddi}, "$r->{unicode} does not map to x-utf8-kddi";
    }

    ok $unicode =~ /^\p{InKDDIPictograms}+$/;
    ok $unicode =~ /^\p{InKDDICP932Pictograms}+$/;
    ok $unicode !~ /^\p{InKDDIAutoPictograms}+$/;
    ok $unicode =~ /^\p{InMobileJPPictograms}+$/;
    ok $unicode !~ /^\p{InDoCoMoPictograms}+$/;

    ok $auto =~ /^\p{InKDDIPictograms}+$/;
    ok $auto =~ /^\p{InKDDIAutoPictograms}+$/;
    ok $auto !~ /^\p{InKDDICP932Pictograms}+$/;
    ok $auto =~ /^\p{InMobileJPPictograms}+$/;
    ok $auto !~ /^\p{InDoCoMoPictograms}+$/;
}
