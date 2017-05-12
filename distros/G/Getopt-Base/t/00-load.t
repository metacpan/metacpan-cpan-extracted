
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Getopt::Base';
use_ok('Getopt::Base') or BAIL_OUT('cannot load Getopt::Base');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
