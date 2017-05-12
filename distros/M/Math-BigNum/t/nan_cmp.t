#!perl -T

# test that overloaded comparison works when NaN is involved

use strict;
use warnings;

use Test::More tests => 13;

use Math::BigNum;

my $nan = Math::BigNum->nan();
my $one = Math::BigNum->new(1);

is($one, $one, "one() == one()");

ok($one != $nan, "one() != nan()");
ok($nan != $one, "nan() != one()");
ok($nan != $nan, "nan() != nan()");

ok(!($nan == $one), "nan() == one()");
ok(!($one == $nan), "one() == nan()");
ok(!($nan == $nan), "nan() == nan()");

ok(!($nan <= $one), "nan() <= one()");
ok(!($one <= $nan), "one() <= nan()");
ok(!($nan <= $nan), "nan() <= nan()");

ok(!($nan >= $one), "nan() >= one()");
ok(!($one >= $nan), "one() >= nan()");
ok(!($nan >= $nan), "nan() >= nan()");
