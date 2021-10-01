# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

plan tests => 89;

# testing of Math::BigInt::Named::English, primarily for the $x->name() and
# $x->from_name() functionality, and not for the math functionality

use Math::BigInt::Named::English;
use Math::BigInt;

my $c = 'Math::BigInt::Named::English';

###############################################################################
# triple names
my $x = Math::BigInt -> bzero();
my $y = Math::BigInt -> new(2);

is($c -> _triple_name(0, $x), '');              # null
is($c -> _triple_name(2, $x), '');              # null millionen
$x++;
is($c -> _triple_name(1, $x), 'thousand');
my $i = 2;
for (qw/ m b tr quadr pent hex sept oct / ) {
    is($c -> _triple_name($i,   $x), $_ . 'i' . 'llion');
    is($c -> _triple_name($i+1, $x), $_ . 'i' . 'lliard');
    is($c -> _triple_name($i,   $y), $_ . 'i' . 'llions');
    is($c -> _triple_name($i+1, $y), $_ . 'i' . 'lliards');
    $i += 2;
}

###############################################################################
# assorted names

while (<DATA>) {
    chomp;
    next if !/\S/;              # empty lines
    next if /^#/;               # comments
    my @args = split /:/;

    my $got      = $c -> new($args[0]) -> name();
    my $expected = $args[1];
    my $test     = $args[0] . " -> " . $args[1];
    is($got, $expected, $test);
    # is($c -> from_name($args[1]), $args[0]);
}


###############################################################################

# nothing valid at all
$x = $c -> new('foo');
is($x, 'NaN', "foo -> NaN");

# done

1;

__END__
0:zero
1:one
-1:minus one
2:two
3:three
4:four
5:five
6:six
7:seven
8:eight
9:nine
10:ten
11:eleven
12:twelve
13:thirteen
14:fourteen
15:fifteen
16:sixteen
17:seventeen
18:eighteen
19:nineteen
20:twenty
21:twenty-one
22:twenty-two
33:thirty-three
44:fourty-four
55:fifty-five
66:sixty-six
77:seventy-seven
88:eighty-eight
99:ninety-nine

100:one hundred
200:two hundred
300:three hundred
400:four hundred
500:five hundred
600:six hundred
700:seven hundred
800:eight hundred
900:nine hundred

101:one hundred and one
202:two hundred and two

1000:one thousand
1001:one thousand and one
1002:one thousand and two
1098:one thousand and ninety-eight
1099:one thousand and ninety-nine
1100:one thousand one hundred
1102:one thousand one hundred and two
1122:one thousand one hundred and twenty-two

1000000:one million
1000001:one million and one
1000100:one million one hundred
