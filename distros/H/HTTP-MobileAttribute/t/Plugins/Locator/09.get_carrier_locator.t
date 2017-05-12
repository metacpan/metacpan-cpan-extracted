use strict;
use warnings;
use Test::More;
plan skip_all => "this module requires Geo::Coordinates::Converter && Geo::Coordinates::Converter::iArea" unless eval "use Geo::Coordinates::Converter; use Geo::Coordinates::Converter::iArea; 1;";
plan 'no_plan';
use CGI;
use HTTP::MobileAttribute plugins => [qw/Locator/];
use HTTP::MobileAttribute::Plugin::Locator ':constants';

sub get_carrier_locator_test {
    my ( $params, $option_ref, $expect ) = @_;
    my $agent = HTTP::MobileAttribute->new;
    ok HTTP::MobileAttribute::Plugin::Locator::_get_carrier_locator(
        $agent, $params, $option_ref,
    ) eq $expect;
}

{ # DoCoMo GPS device
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 SH904i(c100;TB;W24H16)';

    get_carrier_locator_test(
        +{}, undef, 'DoCoMo::GPS',
    );
    get_carrier_locator_test(
        +{}, +{}, 'DoCoMo::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO_FROM_COMPLIANT }, 'DoCoMo::GPS',
    );
    get_carrier_locator_test(
        +{ AREACODE => 'dummy' }, +{ locator => LOCATOR_AUTO }, 'DoCoMo::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO }, 'DoCoMo::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_GPS }, 'DoCoMo::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_BASIC }, 'DoCoMo::BasicLocation',
    );
}

{ # DoCoMo Basic device
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/1.0/P503i/c10';

    get_carrier_locator_test(
        +{}, undef, 'DoCoMo::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{}, 'DoCoMo::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO_FROM_COMPLIANT }, 'DoCoMo::BasicLocation',
    );
    get_carrier_locator_test(
        +{ AREACODE => 'dummy' }, +{ locator => LOCATOR_AUTO }, 'DoCoMo::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO }, 'DoCoMo::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_GPS }, 'DoCoMo::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_BASIC }, 'DoCoMo::BasicLocation',
    );
}

{ # au GPS device
    local $ENV{HTTP_USER_AGENT} = 'KDDI-CA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0';
    local $ENV{HTTP_X_UP_DEVCAP_MULTIMEDIA} = '0200000000000000';

    get_carrier_locator_test(
        +{}, undef, 'EZweb::GPS',
    );
    get_carrier_locator_test(
        +{}, +{}, 'EZweb::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO_FROM_COMPLIANT }, 'EZweb::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO }, 'EZweb::BasicLocation',
    );
    get_carrier_locator_test(
        +{ datum => '000' }, +{ locator => LOCATOR_AUTO }, 'EZweb::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_GPS }, 'EZweb::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_BASIC }, 'EZweb::BasicLocation',
    );
}

{ # au Basic device
    local $ENV{HTTP_USER_AGENT} = 'KDDI-CA31 UP.Browser/6.2.0.7.3.129 (GUI) MMP/2.0';

    get_carrier_locator_test(
        +{}, undef, 'EZweb::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{}, 'EZweb::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO_FROM_COMPLIANT }, 'EZweb::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO }, 'EZweb::BasicLocation',
    );
    get_carrier_locator_test(
        +{ datum => '000' }, +{ locator => LOCATOR_AUTO }, 'EZweb::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_GPS }, 'EZweb::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_BASIC }, 'EZweb::BasicLocation',
    );
}

{ # ThirdForce GPS device
    local $ENV{HTTP_USER_AGENT} = 'SoftBank/1.0/911T/TJ001 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1';

    get_carrier_locator_test(
        +{}, undef, 'ThirdForce::GPS',
    );
    get_carrier_locator_test(
        +{}, +{}, 'ThirdForce::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO_FROM_COMPLIANT }, 'ThirdForce::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO }, 'ThirdForce::BasicLocation',
    );
    get_carrier_locator_test(
        +{ pos => 'dummy' }, +{ locator => LOCATOR_AUTO }, 'ThirdForce::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_GPS }, 'ThirdForce::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_BASIC }, 'ThirdForce::BasicLocation',
    );
}

{ # ThirdForce Basic device
    local $ENV{HTTP_USER_AGENT} = 'J-PHONE/2.0/J-DN02';

    get_carrier_locator_test(
        +{}, undef, 'ThirdForce::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{}, 'ThirdForce::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO_FROM_COMPLIANT }, 'ThirdForce::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO }, 'ThirdForce::BasicLocation',
    );
    get_carrier_locator_test(
        +{ pos => 'dummy' }, +{ locator => LOCATOR_AUTO }, 'ThirdForce::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_GPS }, 'ThirdForce::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_BASIC }, 'ThirdForce::BasicLocation',
    );
}

{ # AirHPhone
    local $ENV{HTTP_USER_AGENT} = 'Mozilla/3.0(DDIPOCKET;JRC/AH-J3001V,AH-J3002V/1.0/0100/c50)CNF/2.0';

    get_carrier_locator_test(
        +{}, undef, 'AirHPhone::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{}, 'AirHPhone::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO_FROM_COMPLIANT }, 'AirHPhone::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_AUTO }, 'AirHPhone::BasicLocation',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_GPS }, 'AirHPhone::GPS',
    );
    get_carrier_locator_test(
        +{}, +{ locator => LOCATOR_BASIC }, 'AirHPhone::BasicLocation',
    );
}

