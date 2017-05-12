
use warnings;
use strict;

use Test::More tests => 1;

my $package = 'Getopt::Abridged';
use_ok('Getopt::Abridged') or BAIL_OUT('cannot load Getopt::Abridged');

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
