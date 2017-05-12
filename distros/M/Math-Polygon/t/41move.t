#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use lib '../lib';
use Math::Polygon::Transform;
use Math::Polygon::Calc       qw/polygon_string/;

my @p = ([0,0], [1,1], [-2,1], [-2,-2], [0,0]);

is( polygon_string(polygon_move @p)
  , "[0,0], [1,1], [-2,1], [-2,-2], [0,0]"
  , 'identity'
  );

is( polygon_string(polygon_move dx => 0, dy => 0, @p)
  , "[0,0], [1,1], [-2,1], [-2,-2], [0,0]"
  , 'identity'
  );

is( polygon_string(polygon_move dx => 1, dy => -1, @p)
  , "[1,-1], [2,0], [-1,0], [-1,-3], [1,-1]"
  , 'move 1,-1'
  );

