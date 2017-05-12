#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'lib';

use_ok 'Math::HexGrid::Hex', 'import module';
ok my $hex = Math::HexGrid::Hex->new(-2,2,0), 'constructor';
ok my $hex2 = Math::HexGrid::Hex->new(-2,2), 'constructor';
ok $hex->hex_equal($hex2), 'hexes are equal';
done_testing;
