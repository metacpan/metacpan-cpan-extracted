
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Devel::NoGlobalSig';
use_ok('Devel::NoGlobalSig') or BAIL_OUT('cannot load Devel::NoGlobalSig');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
