#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 114;

use Math::AnyNum;

{
    my $f1 = Math::AnyNum->new_f('43.12');
    my $f2 = Math::AnyNum->new_f('13.9');

    is($f1 ^ $f2, 38);
    is($f2 ^ $f1, 38);
    is($f1 | $f2, 47);
    is($f2 | $f1, 47);
    is($f1 & $f2, 9);
    is($f2 & $f1, 9);

    is((-$f1) ^ (-$f2), 38);
    is($f1 ^ (-$f2),    -40);
    is((-$f1) ^ $f2,    -40);
    is((-$f1) | (-$f2), -9);
    is($f1 | (-$f2),    -5);
    is((-$f1) | $f2,    -35);
    is((-$f1) & $f2,    5);
    is($f1 & (-$f2),    35);
    is((-$f1) & (-$f2), -47);

    is($f1 << $f2,                          '352256');
    is('81263819264821648127491284' << $f2, '665713207417418941460408598528');
    is('81263819264821648127491284' >> $f1, '9238626633398');
    is($f2 >> '2',                          '3');
    is($f1 >> '2.9',                        '10');
}

{
    my $q1 = Math::AnyNum->new_q('1078', '25');
    my $q2 = Math::AnyNum->new_q('139',  '10');

    is($q1 ^ $q2, 38);
    is($q2 ^ $q1, 38);
    is($q1 | $q2, 47);
    is($q2 | $q1, 47);
    is($q1 & $q2, 9);
    is($q2 & $q1, 9);

    is((-$q1) ^ (-$q2), 38);
    is($q1 ^ (-$q2),    -40);
    is((-$q1) ^ $q2,    -40);
    is((-$q1) | (-$q2), -9);
    is($q1 | (-$q2),    -5);
    is((-$q1) | $q2,    -35);
    is((-$q1) & $q2,    5);
    is($q1 & (-$q2),    35);
    is((-$q1) & (-$q2), -47);
}

{
    my $z1 = Math::AnyNum->new_z('43');
    my $z2 = Math::AnyNum->new_z('13');

    is($z1 ^ $z2, 38);
    is($z2 ^ $z1, 38);
    is($z1 | $z2, 47);
    is($z2 | $z1, 47);
    is($z1 & $z2, 9);
    is($z2 & $z1, 9);

    is((-$z1) ^ (-$z2), 38);
    is($z1 ^ (-$z2),    -40);
    is((-$z1) ^ $z2,    -40);
    is((-$z1) | (-$z2), -9);
    is($z1 | (-$z2),    -5);
    is((-$z1) | $z2,    -35);
    is((-$z1) & $z2,    5);
    is($z1 & (-$z2),    35);
    is((-$z1) & (-$z2), -47);
}

{
    # Test mutability

    {
        my $z1 = Math::AnyNum->new_z('43');
        my $z2 = Math::AnyNum->new_z('13');

        $z1 = $z1->xor($z2);
        is($z1, 38);
        is($z2, 13);
    }

    {
        my $z1 = Math::AnyNum->new_z('43');
        my $z2 = Math::AnyNum->new_z('13');

        $z1 = $z1->or($z2);
        is($z1, 47);
        is($z2, 13);
    }

    {
        my $z1 = Math::AnyNum->new_z('43');
        my $z2 = Math::AnyNum->new_z('13');

        $z1 = $z1->and($z2);
        is($z1, 9);
        is($z2, 13);
    }

}

{
    # Test with scalar arguments

    my $z = Math::AnyNum->new_z('43');
    my $f = Math::AnyNum->new_f('43.92');
    my $q = Math::AnyNum->new_q('1078', '25');

    is($z ^ 13, 38);
    is(13 ^ $z, 38);
    is($z | 13, 47);
    is(13 | $z, 47);
    is($z & 13, 9);
    is(13 & $z, 9);

    is($z ^ '13.98',    38);
    is('13.87' ^ $z,    38);
    is($z | '13.23',    47);
    is('13.412' | $z,   47);
    is($z & '13.1234',  9);
    is('13.92312' & $z, 9);

    is($f ^ 13, 38);
    is(13 ^ $f, 38);
    is($f | 13, 47);
    is(13 | $f, 47);
    is($f & 13, 9);
    is(13 & $f, 9);

    is($q ^ 13, 38);
    is(13 ^ $q, 38);
    is($q | 13, 47);
    is(13 | $q, 47);
    is($q & 13, 9);
    is(13 & $q, 9);

}

{
    # Complementary tests
    my $z = Math::AnyNum->new_z('89012389126812846121237');
    is(~$z,    '-89012389126812846121238');
    is(~(~$z), $z);
}

# General tests

{

    my $x = Math::AnyNum->new(1234);
    my $y = Math::AnyNum->new(99);
    my $k = Math::AnyNum->new(3);

    my $z = $x;
    $z = $z->or($y);
    is($z, "1267");

    $z = $x;
    $z = $z->or("99");
    is($z, "1267");

    is($x | $y,     "1267");
    is($y | $x,     "1267");
    is($x | "99",   "1267");
    is("1234" | $y, "1267");

    $z = $x;
    $z = $z->and($y);
    is($z, "66");

    $z = $x;
    $z = $z->and("99");
    is($z, "66");

    is($x & $y,     "66");
    is($y & $x,     "66");
    is($x & "99",   "66");
    is("1234" & $y, "66");

    $z = $x;
    $z = $z->xor($y);
    is($z, "1201");

    $z = $x;
    $z = $z->xor("99");
    is($z, "1201");

    is($x ^ $y,     "1201");
    is($y ^ $x,     "1201");
    is($x ^ "99",   "1201");
    is("1234" ^ $y, "1201");

    $z = $x;
    $z = $z->lsft("3");
    is($z, "9872");

    $z = $x;
    $z = $z->lsft($k);
    is($z, "9872");

    $z = $x;
    $z = $z <<= "3";
    is($z, "9872");

    $z = $x;
    $z = $z <<= $k;
    is($z, "9872");

    is($x << ("3"),  "9872");
    is($x << $k,     "9872");
    is("1234" << $k, "9872");

    $z = $x;
    $z = $z->rsft("3");
    is($z, "154");

    $z = $x;
    $z = $z->rsft($k);
    is($z, "154");

    $z = $x;
    $z = $z >>= "3";
    is($z, "154");

    $z = $x;
    $z = $z >>= $k;
    is($z, "154");

    is($x >> "3",    "154");
    is($x >> $k,     "154");
    is("1234" >> $k, "154");
}
