use strict;
use warnings;

use Test::More tests => 14;
use Math::BigInt;
use Math::BigInt::Random;
 
ok( random_bigint( max => '10000000000000000000000000') =~ /^\d+$/, "Big base 10 number");
my $min = new Math::BigInt('70000000');
my $max = new Math::BigInt('100000000');
my $n = random_bigint( min => $min, max => $max);
ok( $n <= $max, "Ranged random integer small enough");
ok( $n >= $min, "Ranged random integer big enough");
$n = random_bigint( min => 250, max => 300 );
ok( $n <= 300, "Ranged small random integer small enough");
ok( $n >= 250, "Ranged small random integer big enough");
$n = random_bigint( length => 20 );
ok( length $n == 20, "Base 10 set length of $n");
ok( $n =~ /^[1234567890]+$/, "Base 10 look");
my $hex_digits = 44;
$n = random_bigint( length_hex => 1, length => $hex_digits);
my $hex_len = length $n->as_hex();
ok( $hex_len == $hex_digits + 2, "Base 16 set length");
ok( $n->as_hex =~ /^[abcdefABCDEF1234567890x]+$/, "Base 16 look");
my $bin_digits = 3;
$n = random_bigint( length_bin => 1, length => $bin_digits);
my $bin_len = length $n->as_bin();
ok( $bin_len == $bin_digits + 2, "Base 2 set length");
ok( $n->as_bin =~ /^[01b]+$/, "Base 2 look");

SKIP: {
    my $page = '';
    eval { 
        require LWP::Simple; 
        $page = 
          LWP::Simple::get( "http://www.random.org/cgi-bin/randnum?num=2&min=0&max=10&col=1" );
    };
    skip( "Cannot get numbers from random.org", 3 ) if $@ or $page !~ /^\d+\s/;
    my $rn = random_bigint( min => $min, max => $max, use_internet => 1);
    ok( $rn <= $max, "Ranged random integer small enough");
    ok( $rn >= $min, "Ranged random integer big enough");
    ok( $rn =~ /^[1234567890]+$/, "Base 10 look");
}

