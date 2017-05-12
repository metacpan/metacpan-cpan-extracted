use POSIX;
use Test::More qw(no_plan);

BEGIN { 
    use_ok( 'Geo::Raster' );
}

# test zonal methods

my $grid = new Geo::Raster 10,10;
my $zones = $grid*1;
$zones->circle(5,5,2,1);

for ('zones','zonal_fct',) {
    eval "\$return = \$grid->$_(\$zones)";
    is(1, 1, "calling $_");
}

for ('fct','count','sum','min','max','mean','variance') {
    eval "\$return = \$grid->zonal_$_(\$zones)";
    is(1, 1, "calling zonal_$_");
}

$zones->grow_zones($grid);
