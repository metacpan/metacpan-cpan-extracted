use strict;
use warnings;
use utf8;

use Test::More;
BEGIN {
    my $needed_modules = [ 'Test::LeakTrace' ];
    foreach my $module ( @{ $needed_modules } ) {
        eval "use $module";
        if ($@) {
            plan skip_all => join( ', ', @{ $needed_modules } ). " is needed";
        }
    }
}

use_ok 'Geo::Calc::XS';

no_leaks_ok {
    my $gc = Geo::Calc::XS->new(lat => 2, lon => 4.5);
} "new";

my $gc = Geo::Calc::XS->new(lat => 2.4, lon => -4.5);

no_leaks_ok { $gc->get_lat } "get_lat";
no_leaks_ok { $gc->get_lon } "get_lon";
no_leaks_ok { $gc->get_units } "get_units";
no_leaks_ok { $gc->get_radius } "get_radius";
no_leaks_ok { $gc->boundry_box(1000, 1000, -6) } "boundry_box";
no_leaks_ok { $gc->destination_point(44.3, 1000, -6) } "destination_point";
no_leaks_ok { $gc->distance_to({lat => 30.2, lon => 24.2}) } "distance_to";
no_leaks_ok { $gc->distance_to(Geo::Calc::XS->new(lat => 30.2, lon => 24.2)) } "distance_to 2";
no_leaks_ok { $gc->midpoint_to({lat => 23.2, lon => -45.2}) } "distance_to 2";
no_leaks_ok { $gc->intersection(90, {lat => 52.4, lon => -53.2}, 180, -6) } "intersection";
no_leaks_ok { $gc->distance_at() } "distance_at";
no_leaks_ok { $gc->bearing_to({lat => 52.23, lon => 54.1}) } "bearing_to";
no_leaks_ok { $gc->final_bearing_to({lat => 52.23, lon => 54.1}) } "final_bearing_to";
no_leaks_ok { $gc->rhumb_distance_to({lat => 30.2, lon => 24.2}) } "rhumb_distance_to";
no_leaks_ok { $gc->rhumb_bearing_to({lat => 52.23, lon => 54.1}) } "rhumb_bearing_to";
no_leaks_ok { $gc->rhumb_destination_point(44.3, 1000, -6) } "rhumb_destination_point";


done_testing();
