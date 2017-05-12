
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Graph::ChainBuilder';
use_ok('Graph::ChainBuilder') or BAIL_OUT('cannot load Graph::ChainBuilder');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
