#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

use lib '../lib';
use Math::Polygon::Transform;
use Math::Polygon::Calc       qw/polygon_string/;

my @p = ([0,0], [1,1], [-2,1], [-2,-2], [0,0]);

is( polygon_string(polygon_resize @p)
  , "[0,0], [1,1], [-2,1], [-2,-2], [0,0]"
  , 'identity'
  );

is( polygon_string(polygon_resize xscale => 3, @p)
  , "[0,0], [3,1], [-6,1], [-6,-2], [0,0]"
  , 'xscale 3'
  );

is( polygon_string(polygon_resize yscale => 4, @p)
  , "[0,0], [1,4], [-2,4], [-2,-8], [0,0]"
  , 'yscale 4'
  );

is( polygon_string(polygon_resize xscale=>3, yscale=>4, @p)
  , "[0,0], [3,4], [-6,4], [-6,-8], [0,0]"
  , 'x-yscale 3-4'
  );

is( polygon_string(polygon_resize scale => 5, @p)
  , "[0,0], [5,5], [-10,5], [-10,-10], [0,0]"
  , 'scale 5'
  );

is( polygon_string(polygon_resize center => [100,100], @p)
  , "[0,0], [1,1], [-2,1], [-2,-2], [0,0]"
  , 'identity with center'
  );

is( polygon_string(polygon_resize center => [1,1], scale => 2, @p)
  , "[-1,-1], [1,1], [-5,1], [-5,-5], [-1,-1]"
  , 'scale 2 with center'
  );


