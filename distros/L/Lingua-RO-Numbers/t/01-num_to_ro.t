#!perl -T
use 5.006;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More;

plan tests => 23;

BEGIN {
    use_ok('Lingua::RO::Numbers') || print "Bail out!\n";

    my %opts = (thousands_separator => q{});
    my $ron = Lingua::RO::Numbers->new(%opts);

    my $num = 124_445_223;
    is(Lingua::RO::Numbers::number_to_ro($num, %opts), $ron->number_to_ro($num));

    is($ron->number_to_ro(3),               'trei');
    is($ron->number_to_ro(0.001),           'zero virgulă zero zero unu');
    is($ron->number_to_ro(0.139),           'zero virgulă o sută treizeci și nouă');
    is($ron->number_to_ro(3.14),            'trei virgulă paisprezece');
    is($ron->number_to_ro(12.26),           'doisprezece virgulă douăzeci și șase');
    is($ron->number_to_ro(-9_960),          'minus nouă mii nouă sute șaizeci');
    is($ron->number_to_ro(1_000),           'o mie');
    is($ron->number_to_ro(4_200),           'patru mii două sute');
    is($ron->number_to_ro(10_017),          'zece mii șaptesprezece');
    is($ron->number_to_ro(62_000),          'șaizeci și două de mii');
    is($ron->number_to_ro(112_000),         'o sută doisprezece mii');
    is($ron->number_to_ro(120_000),         'o sută douăzeci de mii');
    is($ron->number_to_ro(1_012_000),       'un milion doisprezece mii');
    is($ron->number_to_ro(102_000_000),     'o sută două milioane');
    is($ron->number_to_ro(1_500_083),       'un milion cinci sute de mii optzeci și trei');
    is($ron->number_to_ro(1_114_000_000),   'un miliard o sută paisprezece milioane');
    is($ron->number_to_ro(119_830_000),     'o sută nouăsprezece milioane opt sute treizeci de mii');
    is($ron->number_to_ro(1_198_300_000),   'un miliard o sută nouăzeci și opt de milioane trei sute de mii');
    is($ron->number_to_ro(11_983_000_000),  'unsprezece miliarde nouă sute optzeci și trei de milioane');
    is($ron->number_to_ro(119_830_000_000), 'o sută nouăsprezece miliarde opt sute treizeci de milioane');
    is($ron->number_to_ro(-0.688121),       'minus zero virgulă șase sute optzeci și opt de mii o sută douăzeci și unu');
}
