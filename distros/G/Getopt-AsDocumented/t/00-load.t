
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Getopt::AsDocumented';
use_ok('Getopt::AsDocumented') or BAIL_OUT('cannot load Getopt::AsDocumented');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
