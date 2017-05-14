#!/usr/bin/perl -w
# vim: set ft=perl:

use strict;

use Test::More;
use File::Find::Rule qw(:WellFormed);

plan tests => 3;
my @f;

@f = File::Find::Rule->new->file->wellformed;
is(scalar @f, 1, "wellformed");

@f = File::Find::Rule->new->file->not_wellformed;
is(scalar @f, 1, "!wellformed");

@f = File::Find::Rule->new(File::Find::Rule->new,
                           File::Find::Rule->file,
                           File::Find::Rule->wellformed);
is(scalar @f, 1, "wellformed");
