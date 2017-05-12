use strict;
use warnings;
use Encode;
use Encode::JP::Mobile ':props';
use Test::More 'no_plan';

my @tests = qw(
    InDoCoMoPictograms    docomo
    InSoftBankPictograms  softbank
    InAirEdgePictograms   airh
    InKDDIAutoPictograms  kddi-auto
    InKDDICP932Pictograms kddi
);

while (my($prop, $enc) = splice @tests, 0, 2) {
    no strict 'refs';
    my $range = &$prop;
    my @chars = map {
        my($from, $to) = split /\t/;
        $to ? (hex($from)..hex($to)) : (hex($from));
    } split /\n/, $range;

    for my $code (@chars) {
        my $char = chr $code;
        my $encoding = "x-sjis-$enc-raw";
        $encoding =~ s/x-sjis-kddi-raw/x-sjis-kddi-cp932-raw/;

        my $byte = eval { encode($encoding, $char, Encode::FB_CROAK) };
        ok $byte, sprintf("U+%X is in %s range", $code, $enc);

        if ($byte) {
            my $bytes = unpack "H*", $byte;
            $bytes =~ s/(..)/\\x$1/g;
            is decode($encoding, $byte), chr($code), "$code <-> $bytes roundtrip";
        }
    }
}

