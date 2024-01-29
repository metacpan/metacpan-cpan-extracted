#!perl

use strict;
use warnings;
use Test::More 0.98;

use List::Util::Find qw(
                           hasnum
                           hasstr
                        );

subtest "hasnum" => sub {
    ok( hasnum 1,  4,3,undef,"foo",2,"bar","foo",3,7,1);
    ok( hasnum 3,  4,3,undef,"foo",2,"bar","foo",3,7,1);
    ok( hasnum 3.0,4,3,undef,"foo",2,"bar","foo",3,7,1);
    ok(!hasnum 8,  4,3,undef,"foo",2,"bar","foo",3,7,1);

    ok(!hasnum 0,  4,3,undef,"foo",2,"bar","foo",3,7,1);
    ok( hasnum 0,  4,3,undef,"foo",2,"bar","foo",3,7,1,0);
};

subtest "hasstr" => sub {
    ok( hasstr "foo",  4,3,undef,"foo",2,"bar","foo",3,7,1);
    ok( hasstr "bar",  4,3,undef,"foo",2,"bar","foo",3,7,1);
    ok( hasstr 3    ,  4,3,undef,"foo",2,"bar","foo",3,7,1);
    ok(!hasstr "3.0",  4,3,undef,"foo",2,"bar","foo",3,7,1);
    ok(!hasstr "baz",  4,3,undef,"foo",2,"bar","foo",3,7,1);
};

DONE_TESTING:
done_testing;
