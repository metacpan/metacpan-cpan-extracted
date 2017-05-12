#!/usr/bin/perl -w

use strict;
use Test::More tests => 30;

use lib 't/lib';
use a;

use Data::Dumper;

is_deeply([a::a_caller()], [qw(main t/00_alltests.t 11)], "un-magic caller() works") &&
    is_deeply([(a::a_caller(0))[0..3]], [qw(main t/00_alltests.t 11 a::a_caller)], "un-magic caller(0) works") &&
    is_deeply([a::a_caller_caller()], [qw(a t/lib/a.pm 8)], "un-magic foo(caller()) works") &&
    is_deeply([(a::a_caller_caller(0))[0..3]], [qw(a t/lib/a.pm 8 a::a_caller)], "un-magic foo(caller(0)) works") &&
    is_deeply([(a::a_caller_caller(1))[0..3]], [qw(main t/00_alltests.t 11 a::a_caller_caller)], "un-magic foo(caller(1)) works") &&
    is_deeply([a::a_caller_caller(2)], [], "un-magic foo(caller(2)) works (empty list)");

eval 'use b';

print "# loaded a module that has a magic caller\n";
is_deeply([a::a_caller()], [qw(main t/00_alltests.t 21)], "un-magic caller() works") &&
    is_deeply([(a::a_caller(0))[0..3]], [qw(main t/00_alltests.t 21 a::a_caller)], "un-magic caller(0) works") &&
    is_deeply([a::a_caller_caller()], [qw(a t/lib/a.pm 8)], "un-magic foo(caller()) works") &&
    is_deeply([(a::a_caller_caller(0))[0..3]], [qw(a t/lib/a.pm 8 a::a_caller)], "un-magic foo(caller(0)) works") &&
    is_deeply([(a::a_caller_caller(1))[0..3]], [qw(main t/00_alltests.t 21 a::a_caller_caller)], "un-magic foo(caller(1)) works") &&
    is_deeply([a::a_caller_caller(2)], [], "un-magic foo(caller(2)) works (empty list)");

is_deeply([b::b_caller_caller()], [qw(main t/00_alltests.t 28)], "magic caller() works (skips a level)") &&
    is_deeply([b::b_caller()], [qw(main t/00_alltests.t 28)], "... when necessary") &&
    is_deeply([(b::b_caller_caller(0))[0..3]], [qw(main t/00_alltests.t 28 b::b_caller)], "magic foo(caller(0)) works (skips a level)") &&
    is_deeply([(b::b_caller_caller(1))[0..3]], [], "magic foo(caller(1)) works (skips a level)");

eval 'use c';

print "# loaded a second module that has a magic caller\n";
is_deeply([a::a_caller()], [qw(main t/00_alltests.t 36)], "un-magic caller() works") &&
    is_deeply([(a::a_caller(0))[0..3]], [qw(main t/00_alltests.t 36 a::a_caller)], "un-magic caller(0) works") &&
    is_deeply([a::a_caller_caller()], [qw(a t/lib/a.pm 8)], "un-magic foo(caller()) works") &&
    is_deeply([(a::a_caller_caller(0))[0..3]], [qw(a t/lib/a.pm 8 a::a_caller)], "un-magic foo(caller(0)) works") &&
    is_deeply([(a::a_caller_caller(1))[0..3]], [qw(main t/00_alltests.t 36 a::a_caller_caller)], "un-magic foo(caller(1)) works") &&
    is_deeply([a::a_caller_caller(2)], [], "un-magic foo(caller(2)) works (empty list)");

is_deeply([b::b_caller_caller()], [qw(main t/00_alltests.t 43)], "magic caller() works (in first magic module)") &&
    is_deeply([b::b_caller()], [qw(main t/00_alltests.t 43)], "... when necessary") &&
    is_deeply([(b::b_caller_caller(0))[0..3]], [qw(main t/00_alltests.t 43 b::b_caller)], "magic foo(caller(0)) works (in first magic module)") &&
    is_deeply([(b::b_caller_caller(1))[0..3]], [], "magic foo(caller(1)) works (in first magic module)");
is_deeply([c::c_caller_caller()], [qw(main t/00_alltests.t 47)], "magic caller() works (in second magic module)") &&
    is_deeply([c::c_caller()], [qw(main t/00_alltests.t 47)], "... when necessary") &&
    is_deeply([(c::c_caller_caller(0))[0..3]], [qw(main t/00_alltests.t 47 c::c_caller)], "magic foo(caller(0)) works (in second magic module)") &&
    is_deeply([(c::c_caller_caller(1))[0..3]], [], "magic foo(caller(1)) works (in second magic module)");

eval q{
    no warnings 'redefine';
    sub is_deeply {
        print Dumper(@_[0,1]);
       goto &Test::More::is_deeply;
    }
};
1;
