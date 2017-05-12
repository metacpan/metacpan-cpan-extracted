#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/le.factorial.u16.ints');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_ui16(),1);
is($bin->get_ui16(),2);
is($bin->get_ui16(),6);
is($bin->get_ui16(),24);
is($bin->get_ui16(),120);
is($bin->get_ui16(),720);
is($bin->get_ui16(),5040);
is($bin->get_ui16(),40320);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

ok($bin->put_ui16(1));
ok($bin->put_ui16(2));
ok($bin->put_ui16(6));
ok($bin->put_ui16(24));
ok($bin->put_ui16(120));
ok($bin->put_ui16(720));
ok($bin->put_ui16(5040));
ok($bin->put_ui16(40320));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_ui16(),1);
is($bin->get_ui16(),2);
is($bin->get_ui16(),6);
is($bin->get_ui16(),24);
is($bin->get_ui16(),120);
is($bin->get_ui16(),720);
is($bin->get_ui16(),5040);
is($bin->get_ui16(),40320);


$bin->close();

open(BINDATA, 't/le.factorial.u16.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_ui16(),1);
is($bin->get_ui16(),2);
is($bin->get_ui16(),6);
is($bin->get_ui16(),24);
is($bin->get_ui16(),120);
is($bin->get_ui16(),720);
is($bin->get_ui16(),5040);
is($bin->get_ui16(),40320);


$bin->close;


