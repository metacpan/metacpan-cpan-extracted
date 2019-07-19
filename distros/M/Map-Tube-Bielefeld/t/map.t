use strict;
use warnings FATAL => 'all';
use Test::More;

my $min_ver = 0.35;
eval "use Test::Map::Tube $min_ver tests => 2";
plan skip_all => "Test::Map::Tube $min_ver required." if $@;

use utf8;
use Map::Tube::Bielefeld;
my $map = Map::Tube::Bielefeld->new;
ok_map($map);
ok_map_functions($map);
