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

if (! $ENV{IPC_SPAWN_TEST}) {
    plan skip_all => "IPC_SPAWN_TEST env var not set";
}

my $obj = SpawnTest->new;

$obj->add(27);
is $obj->{data}{add}, 27, "add() adds 27 ok";
$obj->add(27);
is $obj->{data}{add}, 54, "add() with 27 again is 54 ok";


for (0..10){
    $obj->push($_);
    is $obj->{data}{array}[$_], $_, "push() with $_ is $_ ok";
}

$obj->push(99);
is $obj->{data}{array}[11], 99, "push() pushes 99 into last elem ok";

done_testing();
