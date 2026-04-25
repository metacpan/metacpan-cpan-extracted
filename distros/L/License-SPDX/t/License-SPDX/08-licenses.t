use strict;
use warnings;

use License::SPDX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = License::SPDX->new;
my @ret = $obj->licenses;
is(@ret, 727, 'Get all licenses - count number (727).');
