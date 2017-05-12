#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/le.power3.n16.ints');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si16(),-1);
is($bin->get_si16(),-3);
is($bin->get_si16(),-9);
is($bin->get_si16(),-27);
is($bin->get_si16(),-81);
is($bin->get_si16(),-243);
is($bin->get_si16(),-729);
is($bin->get_si16(),-2187);
is($bin->get_si16(),-6561);
is($bin->get_si16(),-19683);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

ok($bin->put_si16(-1));
ok($bin->put_si16(-3));
ok($bin->put_si16(-9));
ok($bin->put_si16(-27));
ok($bin->put_si16(-81));
ok($bin->put_si16(-243));
ok($bin->put_si16(-729));
ok($bin->put_si16(-2187));
ok($bin->put_si16(-6561));
ok($bin->put_si16(-19683));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si16(),-1);
is($bin->get_si16(),-3);
is($bin->get_si16(),-9);
is($bin->get_si16(),-27);
is($bin->get_si16(),-81);
is($bin->get_si16(),-243);
is($bin->get_si16(),-729);
is($bin->get_si16(),-2187);
is($bin->get_si16(),-6561);
is($bin->get_si16(),-19683);


$bin->close();

open(BINDATA, 't/le.power3.n16.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si16(),-1);
is($bin->get_si16(),-3);
is($bin->get_si16(),-9);
is($bin->get_si16(),-27);
is($bin->get_si16(),-81);
is($bin->get_si16(),-243);
is($bin->get_si16(),-729);
is($bin->get_si16(),-2187);
is($bin->get_si16(),-6561);
is($bin->get_si16(),-19683);


$bin->close;


