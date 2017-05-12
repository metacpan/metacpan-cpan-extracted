use strict;
use warnings;
use utf8;

use Test::More;
BEGIN {
    my $needed_modules = [ 'Test::Warn', 'Test::FailWarnings' ];
    foreach my $module ( @{ $needed_modules } ) {
        eval "use $module";
        if ($@) {
            plan skip_all => join( ', ', @{ $needed_modules } ). " are needed";
        }
    }
}

use_ok 'Geo::Calc::XS';

my @units = ("m", "k-m", "mi", "yd", "ft", "");

for my $unit (@units) {

    my $gc = Geo::Calc::XS->new(
        lat => '1.5423',
        lon => '-2.234',
        units => $unit,
    );

    my $actual_unit = $unit || "m";

    is($gc->get_lat, '1.5423', "get_lat (units \"$unit\")");
    is($gc->get_lon, '-2.234', "get_lon (units \"$unit\")");
    is($gc->get_radius, 6371, "get_radius (units \"$unit\")");
    is($gc->get_units, $actual_unit, "get_units (units \"$unit\")");
}


{
    my $gc = Geo::Calc::XS->new( lat => 1, lon => 2 );
    is($gc->get_lat, 1, "get_lat (units not specified)");
    is($gc->get_lon, 2, "get_lat (units not specified)");
    is($gc->get_radius, 6371, "get_radius (units not specified)");
    is($gc->get_units, 'm', "get_units (units not specified)");
}

my $gc;

warning_is
    {
        $gc = Geo::Calc::XS->new(
            lat => 1,
            lon => 2,
            units => 'unknown'
        );
    }
    "Unrecognised unit (defaulting to m)",
    "Caught warning when specifying bad distance unit";

is($gc->get_units, "m", "default to meters");

done_testing();
