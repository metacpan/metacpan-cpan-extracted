#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 1;

my $str = Math::Matrix -> version();
like($str, qr/^Math::Matrix \d+(\.\d*)?\z/, 'output from version() is valid');
