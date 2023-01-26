use strict;
use warnings;

use License::SPDX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = License::SPDX->new;
my $ret = $obj->spdx_release_date;
is($ret, '2022-11-30', 'SPDX release date (2022-11-30).');
