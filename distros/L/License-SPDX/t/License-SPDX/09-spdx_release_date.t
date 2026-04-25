use strict;
use warnings;

use License::SPDX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = License::SPDX->new;
my $ret = $obj->spdx_release_date;
is($ret, '2026-02-20T00:00:00Z', 'SPDX release date (2026-02-20T00:00:00Z).');
