#!perl -w

use strict;
use Test::More qw(no_plan);
use File::Binary;
use IO::Scalar;

my $bin = File::Binary->new('t/be.fibonacci.p32.ints');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),1);
is($bin->get_si32(),2);
is($bin->get_si32(),3);
is($bin->get_si32(),5);
is($bin->get_si32(),8);
is($bin->get_si32(),13);
is($bin->get_si32(),21);
is($bin->get_si32(),34);
is($bin->get_si32(),55);
is($bin->get_si32(),89);
is($bin->get_si32(),144);
is($bin->get_si32(),233);
is($bin->get_si32(),377);
is($bin->get_si32(),610);
is($bin->get_si32(),987);
is($bin->get_si32(),1597);
is($bin->get_si32(),2584);
is($bin->get_si32(),4181);
is($bin->get_si32(),6765);
is($bin->get_si32(),10946);
is($bin->get_si32(),17711);
is($bin->get_si32(),28657);
is($bin->get_si32(),46368);
is($bin->get_si32(),75025);
is($bin->get_si32(),121393);
is($bin->get_si32(),196418);
is($bin->get_si32(),317811);
is($bin->get_si32(),514229);
is($bin->get_si32(),832040);
is($bin->get_si32(),1346269);
is($bin->get_si32(),2178309);
is($bin->get_si32(),3524578);
is($bin->get_si32(),5702887);
is($bin->get_si32(),9227465);
is($bin->get_si32(),14930352);
is($bin->get_si32(),24157817);
is($bin->get_si32(),39088169);
is($bin->get_si32(),63245986);
is($bin->get_si32(),102334155);
is($bin->get_si32(),165580141);
is($bin->get_si32(),267914296);
is($bin->get_si32(),433494437);
is($bin->get_si32(),701408733);
is($bin->get_si32(),1134903170);
is($bin->get_si32(),1836311903);


$bin->close();



$bin = File::Binary->new('>t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

ok($bin->put_si32(1));
ok($bin->put_si32(1));
ok($bin->put_si32(2));
ok($bin->put_si32(3));
ok($bin->put_si32(5));
ok($bin->put_si32(8));
ok($bin->put_si32(13));
ok($bin->put_si32(21));
ok($bin->put_si32(34));
ok($bin->put_si32(55));
ok($bin->put_si32(89));
ok($bin->put_si32(144));
ok($bin->put_si32(233));
ok($bin->put_si32(377));
ok($bin->put_si32(610));
ok($bin->put_si32(987));
ok($bin->put_si32(1597));
ok($bin->put_si32(2584));
ok($bin->put_si32(4181));
ok($bin->put_si32(6765));
ok($bin->put_si32(10946));
ok($bin->put_si32(17711));
ok($bin->put_si32(28657));
ok($bin->put_si32(46368));
ok($bin->put_si32(75025));
ok($bin->put_si32(121393));
ok($bin->put_si32(196418));
ok($bin->put_si32(317811));
ok($bin->put_si32(514229));
ok($bin->put_si32(832040));
ok($bin->put_si32(1346269));
ok($bin->put_si32(2178309));
ok($bin->put_si32(3524578));
ok($bin->put_si32(5702887));
ok($bin->put_si32(9227465));
ok($bin->put_si32(14930352));
ok($bin->put_si32(24157817));
ok($bin->put_si32(39088169));
ok($bin->put_si32(63245986));
ok($bin->put_si32(102334155));
ok($bin->put_si32(165580141));
ok($bin->put_si32(267914296));
ok($bin->put_si32(433494437));
ok($bin->put_si32(701408733));
ok($bin->put_si32(1134903170));
ok($bin->put_si32(1836311903));


$bin->close();


$bin = File::Binary->new('t/temp');
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),1);
is($bin->get_si32(),2);
is($bin->get_si32(),3);
is($bin->get_si32(),5);
is($bin->get_si32(),8);
is($bin->get_si32(),13);
is($bin->get_si32(),21);
is($bin->get_si32(),34);
is($bin->get_si32(),55);
is($bin->get_si32(),89);
is($bin->get_si32(),144);
is($bin->get_si32(),233);
is($bin->get_si32(),377);
is($bin->get_si32(),610);
is($bin->get_si32(),987);
is($bin->get_si32(),1597);
is($bin->get_si32(),2584);
is($bin->get_si32(),4181);
is($bin->get_si32(),6765);
is($bin->get_si32(),10946);
is($bin->get_si32(),17711);
is($bin->get_si32(),28657);
is($bin->get_si32(),46368);
is($bin->get_si32(),75025);
is($bin->get_si32(),121393);
is($bin->get_si32(),196418);
is($bin->get_si32(),317811);
is($bin->get_si32(),514229);
is($bin->get_si32(),832040);
is($bin->get_si32(),1346269);
is($bin->get_si32(),2178309);
is($bin->get_si32(),3524578);
is($bin->get_si32(),5702887);
is($bin->get_si32(),9227465);
is($bin->get_si32(),14930352);
is($bin->get_si32(),24157817);
is($bin->get_si32(),39088169);
is($bin->get_si32(),63245986);
is($bin->get_si32(),102334155);
is($bin->get_si32(),165580141);
is($bin->get_si32(),267914296);
is($bin->get_si32(),433494437);
is($bin->get_si32(),701408733);
is($bin->get_si32(),1134903170);
is($bin->get_si32(),1836311903);


$bin->close();

open(BINDATA, 't/be.fibonacci.p32.ints');
my $data = do { local $/ = undef; <BINDATA> };
$bin = File::Binary->new(IO::Scalar->new(\$data));
$bin->set_endian($File::Binary::BIG_ENDIAN);

is($bin->get_si32(),1);
is($bin->get_si32(),1);
is($bin->get_si32(),2);
is($bin->get_si32(),3);
is($bin->get_si32(),5);
is($bin->get_si32(),8);
is($bin->get_si32(),13);
is($bin->get_si32(),21);
is($bin->get_si32(),34);
is($bin->get_si32(),55);
is($bin->get_si32(),89);
is($bin->get_si32(),144);
is($bin->get_si32(),233);
is($bin->get_si32(),377);
is($bin->get_si32(),610);
is($bin->get_si32(),987);
is($bin->get_si32(),1597);
is($bin->get_si32(),2584);
is($bin->get_si32(),4181);
is($bin->get_si32(),6765);
is($bin->get_si32(),10946);
is($bin->get_si32(),17711);
is($bin->get_si32(),28657);
is($bin->get_si32(),46368);
is($bin->get_si32(),75025);
is($bin->get_si32(),121393);
is($bin->get_si32(),196418);
is($bin->get_si32(),317811);
is($bin->get_si32(),514229);
is($bin->get_si32(),832040);
is($bin->get_si32(),1346269);
is($bin->get_si32(),2178309);
is($bin->get_si32(),3524578);
is($bin->get_si32(),5702887);
is($bin->get_si32(),9227465);
is($bin->get_si32(),14930352);
is($bin->get_si32(),24157817);
is($bin->get_si32(),39088169);
is($bin->get_si32(),63245986);
is($bin->get_si32(),102334155);
is($bin->get_si32(),165580141);
is($bin->get_si32(),267914296);
is($bin->get_si32(),433494437);
is($bin->get_si32(),701408733);
is($bin->get_si32(),1134903170);
is($bin->get_si32(),1836311903);


$bin->close;


