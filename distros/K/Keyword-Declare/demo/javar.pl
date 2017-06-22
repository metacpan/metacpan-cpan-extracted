#! /usr/bin/env perl

use 5.024; use warnings;
use lib qw< ../dlib  dlib >;
use Var::Javan;

{
    var Int foo = 1;
    var Num BAR = 2.2;
    let baz = 1;

    say foo;
    say BAR;

    foo = 2;
    BAR *= 3.1415926;

    say foo;
    say BAR;

    BAR = 'fred';
    say BAR;
}

eval 'say foo' or warn $@;
eval 'say BAR' or warn $@;

