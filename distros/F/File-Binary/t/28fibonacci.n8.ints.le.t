#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/le.fibonacci.n8.ints');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si8(),-1);
is($bin->get_si8(),-1);
is($bin->get_si8(),-2);
is($bin->get_si8(),-3);
is($bin->get_si8(),-5);
is($bin->get_si8(),-8);
is($bin->get_si8(),-13);
is($bin->get_si8(),-21);
is($bin->get_si8(),-34);
is($bin->get_si8(),-55);
is($bin->get_si8(),-89);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

ok($bin->put_si8(-1));
ok($bin->put_si8(-1));
ok($bin->put_si8(-2));
ok($bin->put_si8(-3));
ok($bin->put_si8(-5));
ok($bin->put_si8(-8));
ok($bin->put_si8(-13));
ok($bin->put_si8(-21));
ok($bin->put_si8(-34));
ok($bin->put_si8(-55));
ok($bin->put_si8(-89));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si8(),-1);
is($bin->get_si8(),-1);
is($bin->get_si8(),-2);
is($bin->get_si8(),-3);
is($bin->get_si8(),-5);
is($bin->get_si8(),-8);
is($bin->get_si8(),-13);
is($bin->get_si8(),-21);
is($bin->get_si8(),-34);
is($bin->get_si8(),-55);
is($bin->get_si8(),-89);


$bin->close();

open(BINDATA, 't/le.fibonacci.n8.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si8(),-1);
is($bin->get_si8(),-1);
is($bin->get_si8(),-2);
is($bin->get_si8(),-3);
is($bin->get_si8(),-5);
is($bin->get_si8(),-8);
is($bin->get_si8(),-13);
is($bin->get_si8(),-21);
is($bin->get_si8(),-34);
is($bin->get_si8(),-55);
is($bin->get_si8(),-89);


$bin->close;


