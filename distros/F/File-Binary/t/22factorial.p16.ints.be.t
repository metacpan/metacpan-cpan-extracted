#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/be.factorial.p16.ints');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si16(),1);
is($bin->get_si16(),2);
is($bin->get_si16(),6);
is($bin->get_si16(),24);
is($bin->get_si16(),120);
is($bin->get_si16(),720);
is($bin->get_si16(),5040);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

ok($bin->put_si16(1));
ok($bin->put_si16(2));
ok($bin->put_si16(6));
ok($bin->put_si16(24));
ok($bin->put_si16(120));
ok($bin->put_si16(720));
ok($bin->put_si16(5040));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si16(),1);
is($bin->get_si16(),2);
is($bin->get_si16(),6);
is($bin->get_si16(),24);
is($bin->get_si16(),120);
is($bin->get_si16(),720);
is($bin->get_si16(),5040);


$bin->close();

open(BINDATA, 't/be.factorial.p16.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si16(),1);
is($bin->get_si16(),2);
is($bin->get_si16(),6);
is($bin->get_si16(),24);
is($bin->get_si16(),120);
is($bin->get_si16(),720);
is($bin->get_si16(),5040);


$bin->close;


