#!/usr/bin/perl

use strict;
use warnings;

use Lingua::DE::ASCII;
use Test::More tests => 1;

my $chars = join "", map chr, (0 ..127);

is to_ascii($chars), $chars, "No changings in ASCII code";
