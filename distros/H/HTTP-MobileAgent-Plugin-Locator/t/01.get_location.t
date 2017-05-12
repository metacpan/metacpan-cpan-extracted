use Test::More 'no_plan';

use HTTP::MobileAgent;
use HTTP::MobileAgent::Plugin::Locator qw/:locator/;

my $for_gps_option_refs = [
    undef,
    { locator => $LOCATOR_AUTO_FROM_COMPLIANT },
    { locator => $LOCATOR_AUTO },
    { locator => $LOCATOR_GPS },
];
my $for_basic_option_refs = [
    undef,
    { locator => $LOCATOR_AUTO_FROM_COMPLIANT },
    { locator => $LOCATOR_AUTO },
    { locator => $LOCATOR_BASIC },
];
my $for_basic_on_gps_option_refs = [
    { locator => $LOCATOR_AUTO },
    { locator => $LOCATOR_BASIC },
];

sub locator_test {
    my ( $option_refs, $params, $expect ) = @_;

    my $agent = HTTP::MobileAgent->new;

    for my $option_ref (@{$option_refs}) {
        my $location = $agent->get_location( $params, $option_ref );
        is ref $location, 'Geo::Coordinates::Converter::Point';
        is_deeply( { lat => $location->lat, lng => $location->lng  } => $expect );
   }
}


{ # DoCoMo GPS device
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 SH904i(c100;TB;W24H16)';

    locator_test(
        $for_gps_option_refs,
        { lat => '35.21.03.342', lon => '138.34.45.725', geo => 'wgs84' },
        { lat => '35.21.03.342', lng => '138.34.45.725'}
    );
    locator_test(
        $for_basic_on_gps_option_refs,
        { AREACODE => '05902', LAT => '+35.39.43.538', LON => '+139.44.06.232', GEO => 'wgs84', XACC => 1 },
        { lat => '35.39.43.538', lng => '139.44.06.232' }
    );
    locator_test(
        $for_basic_on_gps_option_refs,
        { AREACODE => '05902' },
        { lat => '35.39.52.909', lng => '139.43.52.172' }
    );
}

{ # DoCoMo Basic device
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/1.0/P503i/c10';

    locator_test(
        $for_basic_option_refs,
        { AREACODE => '05902', LAT => '+35.39.43.538', LON => '+139.44.06.232', GEO => 'wgs84', XACC => 1 },
        { lat => '35.39.43.538', lng => '139.44.06.232' }
    );
    locator_test(
        $for_basic_option_refs,
        { AREACODE => '05902' },
        { lat => '35.39.52.909', lng => '139.43.52.172' }
    );
}


{ # au GPS device
    local $ENV{HTTP_USER_AGENT} = 'KDDI-CA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0';
    local $ENV{HTTP_X_UP_DEVCAP_MULTIMEDIA} = '0200000000000000';

    locator_test(
        $for_gps_option_refs,
        { lat => '+35.21.03.342', lon => '+138.34.45.725', datum => '0' },
        { lat => '35.21.03.342', lng => '138.34.45.725' }
    );
    locator_test(
        $for_basic_on_gps_option_refs,
        { lat => '35.21.03.342', lon => '138.34.45.725', datum => 'wgs84' },
        { lat => '35.21.03.342', lng => '138.34.45.725' }
    );
}

{ # au Basic device
    local $ENV{HTTP_USER_AGENT} = 'KDDI-CA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0';

    locator_test(
        $for_basic_option_refs,
        { lat => '35.21.03.342', lon => '138.34.45.725', datum => 'wgs84' },
        { lat => '35.21.03.342', lng => '138.34.45.725' }
    );
}

{ # SoftBank GPS device
    local $ENV{HTTP_USER_AGENT} = 'SoftBank/1.0/911T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1';

    locator_test(
        $for_gps_option_refs,
        { pos => 'N35.21.03.342E138.34.45.725' },
        { lat => '35.21.03.342', lng => '138.34.45.725' }
    );

    local $ENV{ HTTP_X_JPHONE_GEOCODE } = '352051%1a1383456%1afoo';
    locator_test(
        $for_basic_on_gps_option_refs,
        undef,
        { lat => '35.21.02.678', lng => '138.34.44.820' }
    );
}

{ # SoftBank Basic device
    local $ENV{HTTP_USER_AGENT} = 'J-PHONE/2.0/J-DN02';
    local $ENV{ HTTP_X_JPHONE_GEOCODE } = '352051%1a1383456%1afoo';

    locator_test(
        $for_basic_option_refs,
        undef,
        { lat => '35.21.02.678', lng => '138.34.44.820' }
    );
}

{ # Willcom
    local $ENV{HTTP_USER_AGENT} = 'Mozilla/3.0(DDIPOCKET;JRC/AH-J3001V,AH-J3002V/1.0/0100/c50)CNF/2.0';

    locator_test(
        $for_basic_option_refs,
        { pos => 'N35.20.51.664E138.34.56.905' },
        { lat => '35.21.03.342', lng => '138.34.45.725' }
    );
}


