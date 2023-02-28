use strict;
use warnings;

use License::SPDX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = License::SPDX->new;
my @ret = $obj->exceptions;
is(@ret, 49, 'Get all license exceptions - count number (49).');
