#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/be.fibonacci.u8.ints');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_ui8(),1);
is($bin->get_ui8(),1);
is($bin->get_ui8(),2);
is($bin->get_ui8(),3);
is($bin->get_ui8(),5);
is($bin->get_ui8(),8);
is($bin->get_ui8(),13);
is($bin->get_ui8(),21);
is($bin->get_ui8(),34);
is($bin->get_ui8(),55);
is($bin->get_ui8(),89);
is($bin->get_ui8(),144);
is($bin->get_ui8(),233);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

ok($bin->put_ui8(1));
ok($bin->put_ui8(1));
ok($bin->put_ui8(2));
ok($bin->put_ui8(3));
ok($bin->put_ui8(5));
ok($bin->put_ui8(8));
ok($bin->put_ui8(13));
ok($bin->put_ui8(21));
ok($bin->put_ui8(34));
ok($bin->put_ui8(55));
ok($bin->put_ui8(89));
ok($bin->put_ui8(144));
ok($bin->put_ui8(233));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_ui8(),1);
is($bin->get_ui8(),1);
is($bin->get_ui8(),2);
is($bin->get_ui8(),3);
is($bin->get_ui8(),5);
is($bin->get_ui8(),8);
is($bin->get_ui8(),13);
is($bin->get_ui8(),21);
is($bin->get_ui8(),34);
is($bin->get_ui8(),55);
is($bin->get_ui8(),89);
is($bin->get_ui8(),144);
is($bin->get_ui8(),233);


$bin->close();

open(BINDATA, 't/be.fibonacci.u8.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_ui8(),1);
is($bin->get_ui8(),1);
is($bin->get_ui8(),2);
is($bin->get_ui8(),3);
is($bin->get_ui8(),5);
is($bin->get_ui8(),8);
is($bin->get_ui8(),13);
is($bin->get_ui8(),21);
is($bin->get_ui8(),34);
is($bin->get_ui8(),55);
is($bin->get_ui8(),89);
is($bin->get_ui8(),144);
is($bin->get_ui8(),233);


$bin->close;


