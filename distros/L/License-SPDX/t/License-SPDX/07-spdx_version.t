use strict;
use warnings;

use License::SPDX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = License::SPDX->new;
my $ret = $obj->spdx_version;
is($ret, 3.19, 'SPDX license version (3.19).');
