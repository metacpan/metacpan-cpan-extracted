#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/le.power3.p32.ints');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),3);
is($bin->get_si32(),9);
is($bin->get_si32(),27);
is($bin->get_si32(),81);
is($bin->get_si32(),243);
is($bin->get_si32(),729);
is($bin->get_si32(),2187);
is($bin->get_si32(),6561);
is($bin->get_si32(),19683);
is($bin->get_si32(),59049);
is($bin->get_si32(),177147);
is($bin->get_si32(),531441);
is($bin->get_si32(),1594323);
is($bin->get_si32(),4782969);
is($bin->get_si32(),14348907);
is($bin->get_si32(),43046721);
is($bin->get_si32(),129140163);
is($bin->get_si32(),387420489);
is($bin->get_si32(),1162261467);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

ok($bin->put_si32(1));
ok($bin->put_si32(3));
ok($bin->put_si32(9));
ok($bin->put_si32(27));
ok($bin->put_si32(81));
ok($bin->put_si32(243));
ok($bin->put_si32(729));
ok($bin->put_si32(2187));
ok($bin->put_si32(6561));
ok($bin->put_si32(19683));
ok($bin->put_si32(59049));
ok($bin->put_si32(177147));
ok($bin->put_si32(531441));
ok($bin->put_si32(1594323));
ok($bin->put_si32(4782969));
ok($bin->put_si32(14348907));
ok($bin->put_si32(43046721));
ok($bin->put_si32(129140163));
ok($bin->put_si32(387420489));
ok($bin->put_si32(1162261467));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),3);
is($bin->get_si32(),9);
is($bin->get_si32(),27);
is($bin->get_si32(),81);
is($bin->get_si32(),243);
is($bin->get_si32(),729);
is($bin->get_si32(),2187);
is($bin->get_si32(),6561);
is($bin->get_si32(),19683);
is($bin->get_si32(),59049);
is($bin->get_si32(),177147);
is($bin->get_si32(),531441);
is($bin->get_si32(),1594323);
is($bin->get_si32(),4782969);
is($bin->get_si32(),14348907);
is($bin->get_si32(),43046721);
is($bin->get_si32(),129140163);
is($bin->get_si32(),387420489);
is($bin->get_si32(),1162261467);


$bin->close();

open(BINDATA, 't/le.power3.p32.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),3);
is($bin->get_si32(),9);
is($bin->get_si32(),27);
is($bin->get_si32(),81);
is($bin->get_si32(),243);
is($bin->get_si32(),729);
is($bin->get_si32(),2187);
is($bin->get_si32(),6561);
is($bin->get_si32(),19683);
is($bin->get_si32(),59049);
is($bin->get_si32(),177147);
is($bin->get_si32(),531441);
is($bin->get_si32(),1594323);
is($bin->get_si32(),4782969);
is($bin->get_si32(),14348907);
is($bin->get_si32(),43046721);
is($bin->get_si32(),129140163);
is($bin->get_si32(),387420489);
is($bin->get_si32(),1162261467);


$bin->close;


