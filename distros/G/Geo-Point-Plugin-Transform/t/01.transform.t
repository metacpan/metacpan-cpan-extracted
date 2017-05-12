use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Point::Plugin::Transform;
use Geo::Proj;

my $clrk = Geo::Proj->new( 
    nick  => 'clark66', 
    proj4 => [proj => "merc", ellps => "clrk66", lon_0 => -96],
);


run {
    my $block = shift;
    my ($fproj,$fx,$fy)         = split(/\n/,$block->input);
    my ($tproj,$tx,$ty)         = split(/\n/,$block->expected);

    my $pf = Geo::Point->longlat($fx, $fy, $fproj);
    my $pt = $pf->transform($clrk);

    is sprintf("%.6f",$pt->x), $tx;
    is sprintf("%.6f",$pt->y), $ty;
};

__END__
===
--- input
wgs84
4.400000
56.120000
--- expected
clark66
11176598.485998
7546921.066300

