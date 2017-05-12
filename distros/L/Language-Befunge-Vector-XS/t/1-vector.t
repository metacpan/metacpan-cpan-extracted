#!perl
#
# This file is part of Language::Befunge::Vector::XS.
# Copyright (c) 2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

#
# Language::Befunge::Vector::XS tests
# taken from Language::Befunge::Vector
#

use strict;
use warnings;
use Config;

use Test::More tests => 151;

use Language::Befunge::Vector::XS;


# check prereq for test
eval "use Test::Exception";
my $has_test_exception = defined($Test::Exception::VERSION);


my ($v1, $v2, $v3, $v4, @coords);
my $v2d = Language::Befunge::Vector::XS->new(3,4);
my $v3d = Language::Befunge::Vector::XS->new(5,6,7);


# -- CONSTRUCTORS

# new()
$v1 = Language::Befunge::Vector::XS->new(7,8,9);
isa_ok($v1,                          "Language::Befunge::Vector::XS");
is($v1->get_dims,                 3, "three dimensions");
is($v1->get_component(0),         7, "X is correct");
is($v1->get_component(1),         8, "Y is correct");
is($v1->get_component(2),         9, "Z is correct");
is($v1->as_string,        '(7,8,9)', "stringifies back to (7,8,9)");
is("$v1",                 '(7,8,9)', "overloaded stringify back to (7,8,9)");
SKIP: {
    skip "need Test::Exception", 1 unless $has_test_exception;
	throws_ok(sub { Language::Befunge::Vector::XS->new() },
		qr/Usage/, "LBV::XS->new needs a defined 'dimensions' argument");
}


# new_zeroes()
$v1 = Language::Befunge::Vector::XS->new_zeroes(4);
isa_ok($v1,                            "Language::Befunge::Vector::XS");
is($v1->get_dims,                   4, "four dimensions");
is($v1->get_component(0),           0, "X is correct");
is($v1->get_component(1),           0, "Y is correct");
is($v1->get_component(2),           0, "Z is correct");
is($v1->get_component(3),           0, "T is correct");
is("$v1",                 '(0,0,0,0)', "all values are 0");
SKIP: {
    skip "need Test::Exception", 2 unless $has_test_exception;
	throws_ok(sub { Language::Befunge::Vector::XS->new_zeroes() },
		qr/Usage/, "LBV::XS->new_zeroes needs a defined 'dimensions' argument");
	throws_ok(sub { Language::Befunge::Vector::XS->new_zeroes(0) },
		qr/Usage/, "LBV::XS->new_zeroes needs a non-zero 'dimensions' argument");
}


# copy()
$v1 = Language::Befunge::Vector::XS->new(2,3,4,5);
$v4 = Language::Befunge::Vector::XS->new(6,7,8,9);
$v2 = $v1->copy;
$v3 = $v1;
is("$v1", "$v2", "v1 has been copied");
$v1 += $v4;
is("$v1", "(8,10,12,14)", "v1 has had v4 added");
is("$v2",    "(2,3,4,5)", "v2 hasn't changed");
is("$v3",    "(2,3,4,5)", "v3 hasn't changed");



# -- PUBLIC METHODS

#- accessors

# get_dims() has already been tested above...


# get_component()
# regular behaviour is tested all over this script.
$v1 = Language::Befunge::Vector::XS->new(2,3);
SKIP: {
    skip "need Test::Exception", 2 unless $has_test_exception;
	throws_ok(sub { $v2d->get_component(-1) },
		qr/No such dimension/, "get_component() checks min dimension");
	throws_ok(sub { $v1->get_component(2) },
		qr/No such dimension/, "get_component() checks max dimension");
}


# get_all_components()
$v1 = Language::Befunge::Vector::XS->new(2,3,4,5);
my @list = $v1->get_all_components;
is(scalar @list, 4, "get_all_components() returned 4 elements");
is($list[0], 2, "X is 2");
is($list[1], 3, "Y is 3");
is($list[2], 4, "Z is 4");
is($list[3], 5, "T is 5");


# as_string() is already tested above.


#- mutators

# clear()
$v1 = Language::Befunge::Vector::XS->new(2,3,4,5);
$v1->clear;
is("$v1",                 '(0,0,0,0)', "clear() sets all values are 0");
is($v1->get_component(0),           0, "X is now 0");
is($v1->get_component(1),           0, "Y is now 0");
is($v1->get_component(2),           0, "Z is now 0");
is($v1->get_component(3),           0, "T is now 0");


# set_component()
$v1 = Language::Befunge::Vector::XS->new(2,3,4,5);
$v1->set_component(0,9);
$v1->set_component(1,6);
is($v1->as_string,        "(9,6,4,5)", "set_component() works");
is($v1->get_component(0),           9, "X is now 9");
is($v1->get_component(1),           6, "Y is now 6");
is($v1->get_component(2),           4, "Z is still 4");
is($v1->get_component(3),           5, "T is still 5");
SKIP: {
    skip "need Test::Exception", 2 unless $has_test_exception;
	throws_ok(sub { $v1->set_component(-1, 0) },
		qr/No such dimension/, "set_component() checks min dimension");
	throws_ok(sub { $v1->set_component(4, 0) },
		qr/No such dimension/, "set_component() checks max dimension");
}


#- other methods

# bounds_check()
$v1 = Language::Befunge::Vector::XS->new(-1, -1);
$v2 = Language::Befunge::Vector::XS->new( 2,  2);
@coords = ( [1,1], [-1,1], [1,-1], [-1,-1], [2,1], [1,2], [2,2] );
foreach my $coords ( @coords ) {
    $v3 = Language::Befunge::Vector::XS->new(@$coords);
    ok($v3->bounds_check($v1, $v2), "$v3 is within bounds");
}
@coords = ( [3,3], [3,1], [1,3], [-2,1], [1,-2], [-2,-2] );
foreach my $coords ( @coords ) {
    $v3 = Language::Befunge::Vector::XS->new(@$coords);
    ok(!$v3->bounds_check($v1, $v2), "$v3 is within bounds");
}
SKIP: {
    skip "need Test::Exception", 3 unless $has_test_exception;
	throws_ok(sub { $v3d->bounds_check($v1, $v2) },
		qr/uneven dimensions/, "bounds_check() catches wrong dimension in first arg");
	throws_ok(sub { $v1->bounds_check($v3d, $v2) },
		qr/uneven dimensions/, "bounds_check() catches wrong dimension in second arg");
	throws_ok(sub { $v1->bounds_check($v2, $v3d) },
		qr/uneven dimensions/, "bounds_check() catches wrong dimension in third arg");
}


# rasterize
$v1 = Language::Befunge::Vector::XS->new(-1, -1, -1);
$v2 = Language::Befunge::Vector::XS->new(1, 1, 1);
my @expectations = (
    [-1, -1, -1], [ 0, -1, -1], [ 1, -1, -1],
    [-1,  0, -1], [ 0,  0, -1], [ 1,  0, -1],
    [-1,  1, -1], [ 0,  1, -1], [ 1,  1, -1],
    [-1, -1,  0], [ 0, -1,  0], [ 1, -1,  0],
    [-1,  0,  0], [ 0,  0,  0], [ 1,  0,  0],
    [-1,  1,  0], [ 0,  1,  0], [ 1,  1,  0],
    [-1, -1,  1], [ 0, -1,  1], [ 1, -1,  1],
    [-1,  0,  1], [ 0,  0,  1], [ 1,  0,  1],
    [-1,  1,  1], [ 0,  1,  1], [ 1,  1,  1]);
for($v3 = $v1->copy; scalar @expectations; $v3 = $v3->rasterize($v1, $v2)) {
    my $expect = shift @expectations;
    $expect = Language::Befunge::Vector::XS->new(@$expect);
    is($v3, $expect, "next one is $expect");
    is(ref($v3), "Language::Befunge::Vector::XS", "retval is also a LBVXS");
}
is($v3, undef, "rasterize returns undef at end of loop");


# _xs_rasterize_ptr
my $ptr = Language::Befunge::Vector::XS::_xs_rasterize_ptr();
ok(defined($ptr), "rasterize pointer is defined");
is(length($ptr), $Config{ptrsize}, "rasterize pointer is the right size");



#- math ops

# addition
$v1 = Language::Befunge::Vector::XS->new(4,5,6);
$v2 = Language::Befunge::Vector::XS->new(1,2,3);
$v3 = $v1 + $v2;
is("$v1",   '(4,5,6)', "addition doesn't change v1");
is("$v2",   '(1,2,3)', "addition doesn't change v2");
isa_ok($v3,            "Language::Befunge::Vector::XS");
is("$v3",   '(5,7,9)', "v3 is v1 plus v2");
SKIP: {
    skip "need Test::Exception", 1 unless $has_test_exception;
	throws_ok(sub { my $blah = $v2d + $v3d },
		qr/uneven dimensions/, "misaligned vector arithmetic (+)");
}


# substraction
$v1 = Language::Befunge::Vector::XS->new(4,5,6);
$v2 = Language::Befunge::Vector::XS->new(3,2,1);
$v3 = $v1 - $v2;
is("$v1",   '(4,5,6)', "substraction doesn't change v1");
is("$v2",   '(3,2,1)', "substraction doesn't change v2");
isa_ok($v3,            "Language::Befunge::Vector::XS");
is("$v3",   '(1,3,5)', "v3 is v1 minus v2");
SKIP: {
    skip "need Test::Exception", 1 unless $has_test_exception;
	throws_ok(sub { my $blah = $v2d - $v3d },
		qr/uneven dimensions/, "misaligned vector arithmetic (-)");
}


# inversion
$v1 = Language::Befunge::Vector::XS->new(4,5,6);
$v2 = -$v1;
is("$v1",      '(4,5,6)', "inversion doesn't change v1");
is("$v2",   '(-4,-5,-6)', "inversion doesn't change v2");


#- inplace math ops

# inplace addition
$v1 = Language::Befunge::Vector::XS->new(4,5,6);
$v2 = Language::Befunge::Vector::XS->new(1,2,3);
$v1 += $v2;
is("$v1", "(5,7,9)", "inplace addition changes v1");
is("$v2", "(1,2,3)", "inplace addition doesn't change v2");
SKIP: {
    skip "need Test::Exception", 1 unless $has_test_exception;
	throws_ok(sub { $v2d += $v3d },
		qr/uneven dimensions/, "misaligned vector arithmetic (+=)");
}


# inplace substraction
$v1 = Language::Befunge::Vector::XS->new(4,5,6);
$v2 = Language::Befunge::Vector::XS->new(3,2,1);
$v1 -= $v2;
is("$v1", "(1,3,5)", "inplace substraction changes v1");
is("$v2", "(3,2,1)", "inplace substraction doesn't change v2");
SKIP: {
    skip "need Test::Exception", 1 unless $has_test_exception;
	throws_ok(sub { $v2d -= $v3d },
		qr/uneven dimensions/, "misaligned vector arithmetic (-=)");
}


#- comparison

# equality
$v1 = Language::Befunge::Vector::XS->new(1,2,3);
$v2 = Language::Befunge::Vector::XS->new(1,2,3);
ok($v1 == $v1, "v1 == v1");
ok($v1 == $v2, "v1 == v2");
ok($v2 == $v1, "v2 == v1");
@coords = ( [0,2,3], [1,0,3], [1,2,0] );
foreach my $coords ( @coords ) {
    $v3 = Language::Befunge::Vector::XS->new(@$coords);
    ok(!($v1 == $v3), "!(v1 == $v3)");
    ok(!($v2 == $v3), "!(v2 == $v3)");
}
SKIP: {
    skip "need Test::Exception", 1 unless $has_test_exception;
	throws_ok(sub { $v2d == $v3d },
		qr/uneven dimensions/, "misaligned vector arithmetic (==)");
}


# inequality
$v1 = Language::Befunge::Vector::XS->new(1,2,3);
$v2 = Language::Befunge::Vector::XS->new(1,2,3);
ok(!($v1 != $v1), "!(v1 != v1)");
ok(!($v1 != $v2), "!(v1 != v2)");
ok(!($v2 != $v1), "!(v2 != v1)");
@coords = ( [0,2,3], [1,0,3], [1,2,0] );
foreach my $coords ( @coords ) {
    $v3 = Language::Befunge::Vector::XS->new(@$coords);
    ok($v1 != $v3, "v1 != $v3)");
    ok($v2 != $v3, "v2 != $v3)");
}
SKIP: {
    skip "need Test::Exception", 1 unless $has_test_exception;
	throws_ok(sub { $v2d != $v3d },
		qr/uneven dimensions/, "misaligned vector arithmetic (!=)");
}



