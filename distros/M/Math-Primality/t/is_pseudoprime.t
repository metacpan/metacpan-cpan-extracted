#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 72;

use Math::Primality qw/ is_pseudoprime /;
use Math::GMPz;

my $z = Math::GMPz->new(7);

ok( is_pseudoprime($z,2) , 'is_pseudoprime should handle Math::GMPz objects, 7 is a psp(2)');

ok( is_pseudoprime(7,2) , '7 is a psp(2)');
ok( is_pseudoprime(7) , 'is_pseudoprime defaults to base 2');
ok(!is_pseudoprime(0), '0 is not a psp(2)');
ok(!is_pseudoprime(1), '1 is not a psp(2)');
ok(!is_pseudoprime(2), '2 is not a psp(2)' );
ok( is_pseudoprime(3), '3 is a psp(2)' );
ok(!is_pseudoprime(4), '4 is not a psp(2)' );

# These are the 10 largest Carmichael numbers <= 1e15
# from http://oldweb.cecm.sfu.ca/pseudoprime/
my @carmichael = qw/
                    999838193331601
                    999840927672001
                    999851057445241
                    999878556600001
                    999885684921481
                    999895175363161
                    999902676805201
                    999907821232321
                    999919121100481
                    999922265173441
                    /;
# none of the above numbers have these as factors
my @bases = (2, 3, 5, 23);
for my $base (@bases) {
    map {
        ok( is_pseudoprime($_,$base), "$_ is a Carmicheal number and hence a psp($base)");
    } @carmichael;
};

ok(!is_pseudoprime( 999895175363161, 7 ), ' 7 is a factor of 999895175363161 and hence it is not a psp(7)');

map {
    ok(!is_pseudoprime( $_ , 13 ), "13 is a factor of $_ and hence it is not a psp(13)") } (999838193331601,999878556600001,999902676805201) ;

# First 20 psp(2)'s
map {
    ok( is_pseudoprime($_), "$_ is a psp(2)" );
} qw/
 341 561 645 1105 1387 1729 1905 2047
 2465 2701 2821 3277 4033 4369 4371
 4681 5461 6601 7957 8321
/;
