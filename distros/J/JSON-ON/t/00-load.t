
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'JSON::ON';
use_ok('JSON::ON') or BAIL_OUT('cannot load JSON::ON');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
