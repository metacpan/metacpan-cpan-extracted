#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/be.power10.n32.ints');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si32(),-1);
is($bin->get_si32(),-10);
is($bin->get_si32(),-100);
is($bin->get_si32(),-1000);
is($bin->get_si32(),-10000);
is($bin->get_si32(),-100000);
is($bin->get_si32(),-1000000);
is($bin->get_si32(),-10000000);
is($bin->get_si32(),-100000000);
is($bin->get_si32(),-1000000000);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

ok($bin->put_si32(-1));
ok($bin->put_si32(-10));
ok($bin->put_si32(-100));
ok($bin->put_si32(-1000));
ok($bin->put_si32(-10000));
ok($bin->put_si32(-100000));
ok($bin->put_si32(-1000000));
ok($bin->put_si32(-10000000));
ok($bin->put_si32(-100000000));
ok($bin->put_si32(-1000000000));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si32(),-1);
is($bin->get_si32(),-10);
is($bin->get_si32(),-100);
is($bin->get_si32(),-1000);
is($bin->get_si32(),-10000);
is($bin->get_si32(),-100000);
is($bin->get_si32(),-1000000);
is($bin->get_si32(),-10000000);
is($bin->get_si32(),-100000000);
is($bin->get_si32(),-1000000000);


$bin->close();

open(BINDATA, 't/be.power10.n32.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si32(),-1);
is($bin->get_si32(),-10);
is($bin->get_si32(),-100);
is($bin->get_si32(),-1000);
is($bin->get_si32(),-10000);
is($bin->get_si32(),-100000);
is($bin->get_si32(),-1000000);
is($bin->get_si32(),-10000000);
is($bin->get_si32(),-100000000);
is($bin->get_si32(),-1000000000);


$bin->close;


