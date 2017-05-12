#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/le.factorial.p32.ints');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),2);
is($bin->get_si32(),6);
is($bin->get_si32(),24);
is($bin->get_si32(),120);
is($bin->get_si32(),720);
is($bin->get_si32(),5040);
is($bin->get_si32(),40320);
is($bin->get_si32(),362880);
is($bin->get_si32(),3628800);
is($bin->get_si32(),39916800);
is($bin->get_si32(),479001600);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

ok($bin->put_si32(1));
ok($bin->put_si32(2));
ok($bin->put_si32(6));
ok($bin->put_si32(24));
ok($bin->put_si32(120));
ok($bin->put_si32(720));
ok($bin->put_si32(5040));
ok($bin->put_si32(40320));
ok($bin->put_si32(362880));
ok($bin->put_si32(3628800));
ok($bin->put_si32(39916800));
ok($bin->put_si32(479001600));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),2);
is($bin->get_si32(),6);
is($bin->get_si32(),24);
is($bin->get_si32(),120);
is($bin->get_si32(),720);
is($bin->get_si32(),5040);
is($bin->get_si32(),40320);
is($bin->get_si32(),362880);
is($bin->get_si32(),3628800);
is($bin->get_si32(),39916800);
is($bin->get_si32(),479001600);


$bin->close();

open(BINDATA, 't/le.factorial.p32.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),2);
is($bin->get_si32(),6);
is($bin->get_si32(),24);
is($bin->get_si32(),120);
is($bin->get_si32(),720);
is($bin->get_si32(),5040);
is($bin->get_si32(),40320);
is($bin->get_si32(),362880);
is($bin->get_si32(),3628800);
is($bin->get_si32(),39916800);
is($bin->get_si32(),479001600);


$bin->close;


