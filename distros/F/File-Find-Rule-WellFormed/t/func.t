#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use File::Find::Rule qw(:WellFormed);

my @f;

plan tests => 2;

@f = rule(file => 'wellformed');
is(scalar @f, 1, "wellformed");

@f = rule(file => '!wellformed');
is(scalar @f, 1, "!wellformed");
