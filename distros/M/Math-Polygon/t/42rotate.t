#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;

use lib '../lib';
use Math::Polygon::Transform;
use Math::Polygon::Calc       qw/polygon_string/;

my @p = ([0,0], [1,1], [-2,1], [-2,-2], [0,0]);

is( polygon_string(polygon_rotate degrees => 0, @p)
  , "[0,0], [1,1], [-2,1], [-2,-2], [0,0]"
  , 'identity'
  );

is( polygon_string(polygon_rotate radians => 0, @p)
  , "[0,0], [1,1], [-2,1], [-2,-2], [0,0]"
  , 'identity'
  );

is( polygon_string(polygon_rotate degrees => 0, center => [0,0], @p)
  , "[0,0], [1,1], [-2,1], [-2,-2], [0,0]"
  , 'identity'
  );

is( polygon_string(polygon_rotate degrees => +90, @p)
  , "[0,0], [1,-1], [1,2], [-2,2], [0,0]"
  , 'rotate +90'
  );

is( polygon_string(polygon_rotate degrees => -90, @p)
  , "[0,0], [-1,1], [-1,-2], [2,-2], [0,0]"
  , 'rotate -90'
  );

is( polygon_string(polygon_rotate degrees => -90, center => [3,4], @p)
  , "[7,1], [6,2], [6,-1], [9,-1], [7,1]"
  , 'rotate 90 around [3,4]'
  );
