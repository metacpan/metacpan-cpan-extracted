#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/be.fibonacci.n16.ints');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si16(),-1);
is($bin->get_si16(),-1);
is($bin->get_si16(),-2);
is($bin->get_si16(),-3);
is($bin->get_si16(),-5);
is($bin->get_si16(),-8);
is($bin->get_si16(),-13);
is($bin->get_si16(),-21);
is($bin->get_si16(),-34);
is($bin->get_si16(),-55);
is($bin->get_si16(),-89);
is($bin->get_si16(),-144);
is($bin->get_si16(),-233);
is($bin->get_si16(),-377);
is($bin->get_si16(),-610);
is($bin->get_si16(),-987);
is($bin->get_si16(),-1597);
is($bin->get_si16(),-2584);
is($bin->get_si16(),-4181);
is($bin->get_si16(),-6765);
is($bin->get_si16(),-10946);
is($bin->get_si16(),-17711);
is($bin->get_si16(),-28657);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

ok($bin->put_si16(-1));
ok($bin->put_si16(-1));
ok($bin->put_si16(-2));
ok($bin->put_si16(-3));
ok($bin->put_si16(-5));
ok($bin->put_si16(-8));
ok($bin->put_si16(-13));
ok($bin->put_si16(-21));
ok($bin->put_si16(-34));
ok($bin->put_si16(-55));
ok($bin->put_si16(-89));
ok($bin->put_si16(-144));
ok($bin->put_si16(-233));
ok($bin->put_si16(-377));
ok($bin->put_si16(-610));
ok($bin->put_si16(-987));
ok($bin->put_si16(-1597));
ok($bin->put_si16(-2584));
ok($bin->put_si16(-4181));
ok($bin->put_si16(-6765));
ok($bin->put_si16(-10946));
ok($bin->put_si16(-17711));
ok($bin->put_si16(-28657));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si16(),-1);
is($bin->get_si16(),-1);
is($bin->get_si16(),-2);
is($bin->get_si16(),-3);
is($bin->get_si16(),-5);
is($bin->get_si16(),-8);
is($bin->get_si16(),-13);
is($bin->get_si16(),-21);
is($bin->get_si16(),-34);
is($bin->get_si16(),-55);
is($bin->get_si16(),-89);
is($bin->get_si16(),-144);
is($bin->get_si16(),-233);
is($bin->get_si16(),-377);
is($bin->get_si16(),-610);
is($bin->get_si16(),-987);
is($bin->get_si16(),-1597);
is($bin->get_si16(),-2584);
is($bin->get_si16(),-4181);
is($bin->get_si16(),-6765);
is($bin->get_si16(),-10946);
is($bin->get_si16(),-17711);
is($bin->get_si16(),-28657);


$bin->close();

open(BINDATA, 't/be.fibonacci.n16.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si16(),-1);
is($bin->get_si16(),-1);
is($bin->get_si16(),-2);
is($bin->get_si16(),-3);
is($bin->get_si16(),-5);
is($bin->get_si16(),-8);
is($bin->get_si16(),-13);
is($bin->get_si16(),-21);
is($bin->get_si16(),-34);
is($bin->get_si16(),-55);
is($bin->get_si16(),-89);
is($bin->get_si16(),-144);
is($bin->get_si16(),-233);
is($bin->get_si16(),-377);
is($bin->get_si16(),-610);
is($bin->get_si16(),-987);
is($bin->get_si16(),-1597);
is($bin->get_si16(),-2584);
is($bin->get_si16(),-4181);
is($bin->get_si16(),-6765);
is($bin->get_si16(),-10946);
is($bin->get_si16(),-17711);
is($bin->get_si16(),-28657);


$bin->close;


