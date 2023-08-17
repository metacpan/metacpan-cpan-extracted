use strict;
use warnings;

use License::SPDX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = License::SPDX->new;
my $ret = $obj->spdx_release_date;
is($ret, '2023-06-18', 'SPDX release date (2023-06-18).');
