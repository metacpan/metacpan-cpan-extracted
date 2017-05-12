#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/be.power3.u8.ints');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_ui8(),1);
is($bin->get_ui8(),3);
is($bin->get_ui8(),9);
is($bin->get_ui8(),27);
is($bin->get_ui8(),81);
is($bin->get_ui8(),243);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

ok($bin->put_ui8(1));
ok($bin->put_ui8(3));
ok($bin->put_ui8(9));
ok($bin->put_ui8(27));
ok($bin->put_ui8(81));
ok($bin->put_ui8(243));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_ui8(),1);
is($bin->get_ui8(),3);
is($bin->get_ui8(),9);
is($bin->get_ui8(),27);
is($bin->get_ui8(),81);
is($bin->get_ui8(),243);


$bin->close();

open(BINDATA, 't/be.power3.u8.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_ui8(),1);
is($bin->get_ui8(),3);
is($bin->get_ui8(),9);
is($bin->get_ui8(),27);
is($bin->get_ui8(),81);
is($bin->get_ui8(),243);


$bin->close;


