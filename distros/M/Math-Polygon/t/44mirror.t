#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use lib '../lib';
use Math::Polygon::Transform;
use Math::Polygon::Calc       qw/polygon_string/;

my @p = ([0,0], [1,1], [-2,1], [-2,-2], [0,0]);

is( polygon_string(polygon_mirror x => 1, @p)
  , "[2,0], [1,1], [4,1], [4,-2], [2,0]"
  , 'x=1'
  );

is( polygon_string(polygon_mirror y => 1, @p)
  , "[0,2], [1,1], [-2,1], [-2,4], [0,2]"
  , 'y=1'
  );

is( polygon_string(polygon_mirror rc => 1, @p)
  , "[0,0], [1,1], [1,-2], [-2,-2], [0,0]"
  , 'y=x'
  );

is( polygon_string(polygon_mirror rc => undef, b => 1, @p)
  , "[2,0], [1,1], [4,1], [4,-2], [2,0]"
  , 'x=1'
  );

is( polygon_string(polygon_mirror rc => -1, b => -1, @p)
  , "[-1,-1], [-2,-2], [-2,1], [1,1], [-1,-1]"
  , 'y=-x-1'
  );


is( polygon_string(polygon_mirror line => [[0,0],[1,1]], @p)
  , "[0,0], [1,1], [1,-2], [-2,-2], [0,0]"
  , 'y=x'
  );

is( polygon_string(polygon_mirror line => [[0,-1],[-3,2]], @p)
  , "[-1,-1], [-2,-2], [-2,1], [1,1], [-1,-1]"
  , 'y=-x-1'
  );

is( polygon_string(polygon_mirror line => [[1,-3],[1,10]], @p)
  , "[2,0], [1,1], [4,1], [4,-2], [2,0]"
  , 'x=1'
  );


