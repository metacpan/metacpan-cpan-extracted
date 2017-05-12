use strict;
use warnings;
use Test::More;

use Encode;
use Encode::JP::Mobile ':props';

eval { require YAML };
plan skip_all => $@ if $@;

my $dat = YAML::LoadFile("dat/softbank-table.yaml");

plan tests => 6 * @$dat;

for my $r (@$dat) {
    my $sjis = pack "H*", $r->{sjis};
    my $unicode = chr hex $r->{unicode};
    is decode("x-sjis-softbank", $sjis), $unicode, $r->{unicode};
    is encode("x-sjis-softbank", $unicode), $sjis, $r->{unicode};

    # not testing the actual bytes, but just check if it can be
    # encoded and different from cp932
SKIP: {
        if ($r->{unicode} =~ /E25[5-7]/) {
            skip "these characters are removed in PDF, hence not in .ucm" => 1;
        }
        my $sjis_auto = encode("x-sjis-softbank-auto", $unicode);
        isnt $sjis_auto, encode("cp932", $unicode);
    }

    ok $unicode =~ /^\p{InSoftBankPictograms}+$/;
    ok $unicode =~ /^\p{InMobileJPPictograms}+$/;
    ok $unicode !~ /^\p{InDoCoMoPictograms}+$/;
}
