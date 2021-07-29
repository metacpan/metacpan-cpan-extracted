use warnings;
use strict;

use lib 't/';

use Test::More;

BEGIN {
    if (!$ENV{IPC_SPAWN_TEST}) {
        plan skip_all => "IPC_SPAWN_TEST env var not set";
    }
}

use SpawnTest;
use IPC::Shareable;

my $obj = SpawnTest->new;

is $obj->{data}{add}, 54, "data retained 54 in add()";
$obj->add(27);
is $obj->{data}{add}, 81, "add() with 27 again works ok (81)";


for (0..10){
    is $obj->{data}{array}[$_], $_, "push() with $_ is $_ ok";
}

$obj->push(100);
is $obj->{data}{array}[12], 100, "push() pushes 100 into new last elem ok";

$obj->clean;

done_testing();
