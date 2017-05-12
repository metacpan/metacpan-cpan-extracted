#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/le.factorial.u32.ints');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_ui32(),1);
is($bin->get_ui32(),2);
is($bin->get_ui32(),6);
is($bin->get_ui32(),24);
is($bin->get_ui32(),120);
is($bin->get_ui32(),720);
is($bin->get_ui32(),5040);
is($bin->get_ui32(),40320);
is($bin->get_ui32(),362880);
is($bin->get_ui32(),3628800);
is($bin->get_ui32(),39916800);
is($bin->get_ui32(),479001600);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

ok($bin->put_ui32(1));
ok($bin->put_ui32(2));
ok($bin->put_ui32(6));
ok($bin->put_ui32(24));
ok($bin->put_ui32(120));
ok($bin->put_ui32(720));
ok($bin->put_ui32(5040));
ok($bin->put_ui32(40320));
ok($bin->put_ui32(362880));
ok($bin->put_ui32(3628800));
ok($bin->put_ui32(39916800));
ok($bin->put_ui32(479001600));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_ui32(),1);
is($bin->get_ui32(),2);
is($bin->get_ui32(),6);
is($bin->get_ui32(),24);
is($bin->get_ui32(),120);
is($bin->get_ui32(),720);
is($bin->get_ui32(),5040);
is($bin->get_ui32(),40320);
is($bin->get_ui32(),362880);
is($bin->get_ui32(),3628800);
is($bin->get_ui32(),39916800);
is($bin->get_ui32(),479001600);


$bin->close();

open(BINDATA, 't/le.factorial.u32.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::LITTLE_ENDIAN);

is($bin->get_ui32(),1);
is($bin->get_ui32(),2);
is($bin->get_ui32(),6);
is($bin->get_ui32(),24);
is($bin->get_ui32(),120);
is($bin->get_ui32(),720);
is($bin->get_ui32(),5040);
is($bin->get_ui32(),40320);
is($bin->get_ui32(),362880);
is($bin->get_ui32(),3628800);
is($bin->get_ui32(),39916800);
is($bin->get_ui32(),479001600);


$bin->close;


