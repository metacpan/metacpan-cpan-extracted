use strict;
use Test::More qw(no_plan);

BEGIN{ use_ok( 'GIS::Distance::Lite' ); }

my %tests = (
    'Bandhagen'                    => [ 59.26978,     18.03948,  59.27200,    18.05375,   847.628337357761],
    'Canoga Park to San Francisco' => [ 34.202361, -118.601875,  37.752258, -122.441254,   524347.542197146],
    'Egypt to Anchorage'           => [ 26.185018,   30.047607,  61.147543, -149.81575,  10324656.666156],
    'London to Sydney'             => [ 51.497736,   -0.115356, -33.81966,   151.169472, 16982540.2359324],
    'Santiago to Rio de Janeiro'   => [-33.446339,  -70.63591,  -22.902981,  -43.213177,  2923667.33201558],
    'Beirut to Dimashq'            => [ 33.863146,   35.52824,   33.516496,   36.287842, 80241.1054436632],
);

my $lossy = 0.00189;
while (my ($name, $vals) = each %tests) {
	my $meters = eval { GIS::Distance::Lite::distance(@{$vals}[0..3]); };
	ok( (not($@) and $meters>$vals->[4]*(1-$lossy) and $meters<$vals->[4]*(1+$lossy)), "$name distance" );	
}
