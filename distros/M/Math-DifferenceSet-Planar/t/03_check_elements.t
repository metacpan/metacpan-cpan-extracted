# Copyright (c) 2020-2021 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 03_check_elements.t'

#########################

use strict;
use warnings;
use File::Spec;
use Math::DifferenceSet::Planar;
use constant MDP => Math::DifferenceSet::Planar::;

use Test::More tests => 22;

#########################

my @set_1 = (0, 7, 16, 21, 22, 24, 34, 53);
my @set_2a = (7, 16, 21, 22, 24, 34, 53, 57);
my @set_2b = (-4, 0, 7, 16, 21, 22, 24, 34);
my @set_2c = (0, 7.5, 16, 21, 22, 24, 34, 53);
my @set_2d = (0);
my @set_3 = (7, 16, 21, 22, 24, 34, 53, 7);
my @set_4 = (0, 1, 5, 7, 17, 28, 31, 49);
my @set_5 = (0, 1, 3, 7, 21, 33, 38, 49);
my @set_6 = (0, 4, 12, 28, 43, 45, 63, 66, 72);

my $r = MDP->check_elements(\@set_1);
is($r, 2);

$r = MDP->check_elements(\@set_1, 28);
is($r, 2);

$r = MDP->check_elements(\@set_2a);
is($r, undef);

$r = MDP->check_elements(\@set_2b);
is($r, undef);

$r = MDP->check_elements(\@set_2c);
is($r, undef);

$r = MDP->check_elements(\@set_2d);
is($r, undef);

$r = MDP->check_elements(\@set_3);
is($r, q[]);

$r = MDP->check_elements(\@set_4, 18, 1);
is($r, 1);

$r = MDP->check_elements(\@set_4, 19, 1);
is($r, q[]);

$r = MDP->check_elements(\@set_4, 1);
is($r, 0);

$r = MDP->check_elements(\@set_5, 9);
is($r, 1);

CHECK_DEFAULT:
{
    local $Math::DifferenceSet::Planar::_DEFAULT_DEPTH = 9;
    $r = MDP->check_elements(\@set_5);
    is($r, 1);
}

$r = MDP->check_elements(\@set_5, 10);
is($r, q[]);

$r = MDP->check_elements(\@set_6, 1);
is($r, 0);

$r = MDP->verify_elements(@set_1);
is($r, 1);

$r = MDP->verify_elements(@set_2a);
is($r, undef);

$r = MDP->verify_elements(@set_2b);
is($r, undef);

$r = MDP->verify_elements(@set_2c);
is($r, undef);

$r = MDP->verify_elements(@set_3);
is($r, q[]);

$r = MDP->verify_elements(@set_4);
is($r, q[]);

$r = MDP->verify_elements(@set_5);
is($r, q[]);

$r = MDP->verify_elements(@set_6);
is($r, q[]);
