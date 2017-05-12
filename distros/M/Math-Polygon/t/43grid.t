#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use lib '../lib';
use Math::Polygon::Transform;
use Math::Polygon::Calc       qw/polygon_string/;

my @p = ( [1,1], [2.45,2.55], [-1.45, -1.55] );

is( polygon_string(polygon_grid raster => 0, @p)
  , "[1,1], [2.45,2.55], [-1.45,-1.55]"
  , "identity"
  );

is( polygon_string(polygon_grid @p)
  , "[1,1], [2,3], [-1,-2]"
  , "grid 1"
  );

is( polygon_string(polygon_grid raster => 2.5, @p)
  , "[0,0], [2.5,2.5], [-2.5,-2.5]"
  , "grid 2.5"
  );

is( polygon_string(polygon_grid raster => 0.25, @p)
  , "[1,1], [2.5,2.5], [-1.5,-1.5]"
  , "grid 0.5"
  );

