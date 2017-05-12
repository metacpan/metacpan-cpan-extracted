#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use Math::Int64 qw(uint64_rand);

my $n = shift || 1;

say uint64_rand for 1..$n;
