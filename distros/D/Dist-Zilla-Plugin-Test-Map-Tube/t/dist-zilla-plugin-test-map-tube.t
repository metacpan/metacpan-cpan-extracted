#!perl

use strict;
use warnings;
use Test::More;
use Test::DZil;

my $tzil = Builder->from_config({ dist_root => 't/dist' });
$tzil->build;

my $got = $tzil->slurp_file('build/xt/release/map.t');
open(IN, "t/exp-map-test.txt") or die "Can't open routes file: $!\n"; my @exp = <IN>; close(IN);
is($got, "\n".join("",@exp)."\n");

done_testing();
