#!/usr/bin/perl
use strict;
use warnings;
BEGIN {eval 'use Test::More skip_all => "no profile"' if %Devel::Cover::}
use Test::More tests => 7;
use lib qw(../lib lib t/lib);
use List::Gen::Testing;
BEGIN {$List::Gen::Lazy::Builtins::WARN = 0}
use List::Gen::Lazy::Builtins;


    my $int = Int(my $float);
    my $int2 = Int($float);

    $float = 3.4;

    t 'int 1', is => $int, 3;

    $float *= 2;

    t 'int 2', is => $int, 3;
    t 'int 3', is => $int2, 6;

    t 'names',
        is => \&Int, \&List::Gen::Lazy::Builtins::_int,
        is => \&Int, \&List::Gen::Lazy::Builtins::Int,
        is => \&Int, \&List::Gen::Lazy::Builtins::lazy_int;

package test;

use List::Gen::Lazy::Builtins ':_';

my $_x = _int my $_y;

$_y = 1.234;

::t '_name',
    is => $_x, 1;
