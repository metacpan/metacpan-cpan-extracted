use strict;
use Test::More qw(no_plan);

BEGIN{ use_ok( 'Geo::SweGrid' ); }

my $grid = eval{ Geo::SweGrid->new("rt90_2.5_gon_v") };
ok(!$@ and $grid,'create a Geo::SweGrid object');

my ($lat, $lon) = eval { $grid->grid_to_geodetic(7011002, 1299996); };
ok( (not($@) and $lat>63.1530261140461 and $lat<63.1530261140463 and $lon>11.8353976399344 and $lon<11.8353976399346), 'grid_to_geodetic' );

my ($x, $y) = eval { $grid->geodetic_to_grid(63.1530261140462, 11.8353976399345) };
ok( (not($@) and $x==7011002 and $y==1299996), 'geodetic_to_grid' );
