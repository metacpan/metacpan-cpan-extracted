#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 11;

use lib '../lib', 'lib';
use Math::Polygon::Transform;
use Math::Polygon::Calc       qw/polygon_string/;

###
### SAME
###

my @p = ([0,0], [0,0], [1,1], [2,2], [2.1, 2.1], [1.9, 1.85], [0,0.1], [0,0]);

is( polygon_string(polygon_simplify @p)
  , "[0,0], [1,1], [2,2], [2.1,2.1], [1.9,1.85], [0,0.1], [0,0]"
  , 'default'
  );

is( polygon_string(polygon_simplify same => 0.15, @p)
  , "[0,0.05], [1,1], [2.05,2.05], [1.9,1.85], [0,0.05]"
  , 'resolution 0.11'
  );

is( polygon_string(polygon_simplify same => 0.25, @p)
  , "[0,0.05], [1,1], [1.975,1.95], [0,0.05]"
  , 'resolution 0.11'
  );

pop @p;   # @p now not a ring anymore

is( polygon_string(polygon_simplify @p)
  , "[0,0], [1,1], [2,2], [2.1,2.1], [1.9,1.85], [0,0.1]"
  , 'default no ring'
  );

is( polygon_string(polygon_simplify same => 0.15, @p)
  , "[0,0], [1,1], [2.05,2.05], [1.9,1.85], [0,0.1]"
  , 'resolution 0.11 no ring'
  );

is( polygon_string(polygon_simplify same => 0.25, @p)
  , "[0,0], [1,1], [1.975,1.95], [0,0.1]"
  , 'resolution 0.11 no ring'
  );

###
### SLOPE
###

my @q = ( [0,1],[0,4],[4,5],[7,4],[7,1],[3,0],[0,1] );
is( polygon_string(polygon_simplify @q)
  , "[0,1], [0,4], [4,5], [7,4], [7,1], [3,0], [0,1]"
  , 'identity'
  );

is( polygon_string(polygon_simplify slope => 1, @q)
  , "[0,1], [0,4], [7,4], [7,1], [0,1]"
  , 'identity'
  );

###
### Z shape in slope
###

my @r = ( [1,1], [1,4], [1,2], [1,5] );
is( polygon_string(polygon_simplify slope => 0.001, @r)
  , "[1,1], [1,5]"
  , 'simple'
  );
  
###
### Remove blunt angles
###

my @s = ( [0,0], [1,3], [4,3], [5,0], [4,-3], [1,-3], [0,0] );
is( polygon_string(polygon_simplify max_points => 4, @s)
  , "[1,3], [4,3], [4,-3], [1,-3], [1,3]"
  , 'max 4 (ring => 5 left)'
  );
  
pop @s;
is( polygon_string(polygon_simplify max_points => 5, @s)
  , "[0,0], [1,3], [4,3], [4,-3], [1,-3]"
  , 'max 5 (no ring)'
  );

