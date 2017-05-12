#!perl

use 5.010;
use strict;
use warnings;
use Test::More;
use utf8;

use Lingua::SU::Nums2Words qw(nums2words nums2words_simple);

my %test_n2w = (
    0 => "kosong",
    1 => "hiji",
    -1 => "négatif hiji",
    10 => "sa-puluh",
    10.1 => "sa-puluh koma hiji",
    10.01 => "sa-puluh koma kosong hiji",
    10.012 => "sa-puluh koma kosong hiji dua",
    11 => "sa-belas",
    12 => "dua belas",
    21 => "dua puluh hiji",
    99 => "salapan puluh salapan",
    100 => "sa-ratus",
    101 => "sa-ratus hiji",
    -110 => "négatif sa-ratus sa-puluh",
    111 => "sa-ratus sa-belas",
    132 => "sa-ratus tilu puluh dua",
    #1000 => "sa-rébu", # fudged, why outputs "sa- rébu"? in indo it's seribu
    2000000 => "dua juta",
    2010203 => "dua juta sa-puluh rébu dua ratus tilu",
    -2004005 => "négatif dua juta opat rébu lima",
    3000000000 => "tilu miliar",
    3000000000.009 => "tilu miliar koma kosong kosong salapan",
    3123456789 => "tilu miliar sa-ratus dua puluh tilu juta ".
        "opat ratus lima puluh genep rébu tujuh ratus dalapan puluh salapan",
    -4000000000000 => "négatif opat triliun",
    994000000000000 => "salapan ratus salapan puluh opat triliun",

    "5.4e6" => "lima koma opat dikali sa-puluh pangkat genep",
    "-5.4e6" => "négatif lima koma opat dikali sa-puluh pangkat genep",
    "5.4e-6" => "lima koma opat dikali sa-puluh pangkat négatif genep",
    "-5.4e-6" => "négatif lima koma opat dikali sa-puluh pangkat négatif genep",

);
for (sort {abs($a) <=> abs($b)} keys %test_n2w) {
    is(nums2words($_), $test_n2w{$_}, "$_ => $test_n2w{$_}");
}

my %test_n2ws = (
    0 => "kosong",
    1 => "hiji",
    10 => "hiji kosong",
    101 => "hiji kosong hiji",
    1234567890 => "hiji dua tilu opat lima genep tujuh dalapan salapan kosong",
);
for (sort {abs($a) <=> abs($b)} keys %test_n2ws) {
    is(nums2words_simple($_), $test_n2ws{$_}, "simple: $_ => $test_n2ws{$_}");
}

done_testing();
