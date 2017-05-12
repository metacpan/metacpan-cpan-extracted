#!perl -T
use 5.006;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More;

plan tests => 34;

BEGIN {
    use_ok('Lingua::RO::Numbers') || print "Bail out!\n";

    my %opts = (thousands_separator => q{});
    my $ron = Lingua::RO::Numbers->new(%opts);

    my $num = 124_445_223;
    is(Lingua::RO::Numbers::ro_to_number($ron->number_to_ro($num), %opts), $num);

    # Some random tests
    foreach my $n (2..11) {
        my $i = int(rand(10**$n));
        is($ron->ro_to_number($ron->number_to_ro($i)), $i);
    }

    is($ron->ro_to_number('trei'),                                                                       3);
    is($ron->ro_to_number('zero virgulă zero zero unu'),                                                 0.001);
    is($ron->ro_to_number('zero virgulă o sută treizeci și nouă'),                                       0.139);
    is($ron->ro_to_number('trei virgulă paisprezece'),                                                   3.14);
    is($ron->ro_to_number('doisprezece virgulă douăzeci și șase'),                                       12.26);
    is($ron->ro_to_number('minus nouă mii nouă sute șaizeci'),                                          -9_960);
    is($ron->ro_to_number('o mie'),                                                                      1_000);
    is($ron->ro_to_number('patru mii două sute'),                                                        4_200);
    is($ron->ro_to_number('zece mii șaptesprezece'),                                                     10_017);
    is($ron->ro_to_number('șaizeci și două de mii'),                                                     62_000);
    is($ron->ro_to_number('o sută doisprezece mii'),                                                     112_000);
    is($ron->ro_to_number('o sută douăzeci de mii'),                                                     120_000);
    is($ron->ro_to_number('un milion doisprezece mii'),                                                  1_012_000);
    is($ron->ro_to_number('o sută două milioane'),                                                       102_000_000);
    is($ron->ro_to_number('un milion cinci sute de mii optzeci și trei'),                                1_500_083);
    is($ron->ro_to_number('un miliard o sută paisprezece milioane'),                                     1_114_000_000);
    is($ron->ro_to_number('patru sute unu mii două sute treizeci și patru'),                             401_234);
    is($ron->ro_to_number('o sută nouăsprezece milioane opt sute treizeci de mii'),                      119_830_000);
    is($ron->ro_to_number('un miliard o sută nouăzeci și opt de milioane trei sute de mii'),             1_198_300_000);
    is($ron->ro_to_number('unsprezece miliarde nouă sute optzeci și trei de milioane'),                  11_983_000_000);
    is($ron->ro_to_number('o sută nouăsprezece miliarde opt sute treizeci de milioane'),                 119_830_000_000);
    is($ron->ro_to_number('minus zero virgulă șase sute optzeci și opt de mii o sută douăzeci și unu'), -0.688121);
}
