
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'List::oo';
use_ok('List::oo') or BAIL_OUT('cannot load List::oo');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
