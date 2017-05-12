# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Guitar-scale.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Guitar::Scale') };

#########################

my $gu = Guitar::Scale::pv('B', 'MelodicMinor', 1);

ok( substr($gu, 0, 25) eq '1010101201101010101201101', 'B_MelodicMinor');

