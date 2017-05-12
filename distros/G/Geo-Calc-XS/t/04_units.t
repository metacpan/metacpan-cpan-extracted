use strict;
use warnings;
use utf8;

use Test::More;
BEGIN {
    my $needed_modules = [ 'Scalar::Util', 'Math::Units' ];
    foreach my $module ( @{ $needed_modules } ) {
        eval "use $module";
        if ($@) {
            plan skip_all => join( ', ', @{ $needed_modules } ). " are needed";
        }
    }
}

use_ok 'Geo::Calc::XS';

my %cardiff = (
    lat => '51.483435',
    lon => '-3.213501',
);
my %london = (
    lat => '51.490277',
    lon => '-0.181274',
);

my @units = ("", "m", "k-m", "yd", "ft", "mi");

for my $original_unit (@units) {
    note "Setting default unit to \"$original_unit\"";
    my $gc = Geo::Calc::XS->new(
        lat => $cardiff{lat},
        lon => $cardiff{lon},
        ($original_unit ? (units => $original_unit) : ())
    );

    my $unit = $original_unit || "m";

    # distance_to
    is(
        round( $gc->distance_to( \%london ) ),
        round( Math::Units::convert( '209954.832717', 'm', $unit ) ),
        "distance_to 20km original_unit: \"$original_unit\""
    );

    # destination_point
    is_deeply(
        round( $gc->destination_point(0, Math::Units::convert(1, 'm', $unit)) ),
        round( { lat => '51.483444', lon => '-3.213501', final_bearing => 0 } ),
        "destination_point 1m north"
    );

    # boundary_box
    is_deeply(
        round( $gc->boundry_box( Math::Units::convert(1, 'm', $unit) ) ),
        round( { lat_min => '51.483426', lon_min => '-3.213504', lat_max => '51.483444', lon_max => '-3.213486' } ),
        "boundry_box 1m radius"
    );
    is_deeply(
        round( $gc->boundry_box( Math::Units::convert('0.5', 'm', $unit), Math::Units::convert('0.5', 'm', $unit) ) ),
        round( { lat_min => '51.483426', lon_min => '-3.213504', lat_max => '51.483444', lon_max => '-3.213486' } ),
        "boundry_box 0.5m width by 0.5m height"
    );

    # rhumb_distance_to
    is(
        round( $gc->rhumb_distance_to( \%london ) ),
        round( Math::Units::convert( '209954.082043', 'm', $unit ) ),
        "rhumb_distance_to"
    );

    # distance_at
    is_deeply(
        $gc->distance_at(),
        { m_lat => '111257.478549', m_lon => '69465.660366' },
        "distance_at"
    );

    # rhumb_destination_point
    is_deeply(
        $gc->rhumb_destination_point( 0, Math::Units::convert( 30, 'm', $unit ) ),
        { lat => '51.483705', lon => '-3.213501' },
        "rhumb_destination_point original_unit: \"$original_unit\""
    );

}

done_testing();

sub round {
    my ( $input ) = @_;

    if ( ref($input) eq 'HASH' ) {
        my $result = {};
        for my $key (keys %$input) {
            if (Scalar::Util::looks_like_number( $input->{$key} )) {
                $result->{$key} = sprintf("%.2f", $input->{$key});
            }
            else {
                $result->{$key} = $input->{$key};
            }
        }
        return $result;
    }

    return sprintf("%.2f", $input);
}
