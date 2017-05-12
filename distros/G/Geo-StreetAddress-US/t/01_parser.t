use blib;
use Test::More;
use strict;
use warnings;
use Data::Dumper;

use_ok( "Geo::StreetAddress::US" );

my %address = (
    "1005 Gravenstein Hwy 95472" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'zip' => '95472',
          'type' => 'Hwy',
        },
    "1005 Gravenstein Hwy, 95472" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'zip' => '95472',
          'type' => 'Hwy',
        },
    "1005 Gravenstein Hwy N, 95472" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'zip' => '95472',
          'suffix' => 'N',
          'type' => 'Hwy',
        },
    "1005 Gravenstein Highway North, 95472" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'zip' => '95472',
          'suffix' => 'N',
          'type' => 'Hwy',
        },
    "1005 N Gravenstein Highway, Sebastopol, CA" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'type' => 'Hwy',
          'prefix' => 'N'
        },
    "1005 N Gravenstein Highway, Suite 500, Sebastopol, CA" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'type' => 'Hwy',
          'prefix' => 'N',
          'sec_unit_type' => 'Suite',
          'sec_unit_num' => '500',
        },
    "1005 N Gravenstein Hwy Suite 500 Sebastopol, CA" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'type' => 'Hwy',
          'prefix' => 'N',
          'sec_unit_type' => 'Suite',
          'sec_unit_num' => '500',
        },
    "1005 N Gravenstein Highway, Sebastopol, CA, 95472" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'zip' => '95472',
          'type' => 'Hwy',
          'prefix' => 'N'
        },
    "1005 N Gravenstein Highway Sebastopol CA 95472" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'zip' => '95472',
          'type' => 'Hwy',
          'prefix' => 'N'
        },
    "1005 Gravenstein Hwy N Sebastopol CA" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'suffix' => 'N',
          'type' => 'Hwy',
        },
    "1005 Gravenstein Hwy N, Sebastopol CA" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'suffix' => 'N',
          'type' => 'Hwy',
        },
    "1005 Gravenstein Hwy, N Sebastopol CA" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'North Sebastopol',
          'type' => 'Hwy',
        },
    "1005 Gravenstein Hwy, North Sebastopol CA" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'North Sebastopol',
          'type' => 'Hwy',
        },
    "1005 Gravenstein Hwy Sebastopol CA" => {
          'number' => '1005',
          'street' => 'Gravenstein',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'type' => 'Hwy',
        },
    "115 Broadway San Francisco CA" => {
          'type' => '',
          'number' => '115',
          'street' => 'Broadway',
          'state' => 'CA',
          'city' => 'San Francisco',
        },
    "7800 Mill Station Rd, Sebastopol, CA 95472" => {
          'number' => '7800',
          'street' => 'Mill Station',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'zip' => '95472',
          'type' => 'Rd',
        },
    "7800 Mill Station Rd Sebastopol CA 95472" => {
          'number' => '7800',
          'street' => 'Mill Station',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'zip' => '95472',
          'type' => 'Rd',
        },
    "1005 State Highway 116 Sebastopol CA 95472" => {
          'number' => '1005',
          'street' => 'State Highway 116',
          'state' => 'CA',
          'city' => 'Sebastopol',
          'zip' => '95472',
          'type' => 'Hwy',
        },
    "1600 Pennsylvania Ave. Washington DC" => {
          'number' => '1600',
          'street' => 'Pennsylvania',
          'state' => 'DC',
          'city' => 'Washington',
          'type' => 'Ave',
        },
    "1600 Pennsylvania Avenue Washington DC" => {
          'number' => '1600',
          'street' => 'Pennsylvania',
          'state' => 'DC',
          'city' => 'Washington',
          'type' => 'Ave',
        },
    "48S 400E, Salt Lake City UT" => {
          'type' => '',
          'number' => '48',
          'street' => '400',
          'state' => 'UT',
          'city' => 'Salt Lake City',
          'suffix' => 'E',
          'prefix' => 'S'
        },
    "550 S 400 E #3206, Salt Lake City UT 84111" => {
            'number' => '550',
            'street' => '400',
            'state' => 'UT',
            'sec_unit_num' => '3206',
            'zip' => '84111',
            'city' => 'Salt Lake City',
            'suffix' => 'E',
            'type' => '',
            'sec_unit_type' => '#',
            'prefix' => 'S'
    },
    "6641 N 2200 W Apt D304 Park City, UT 84098" => {
          'number' => '6641',
          'street' => '2200',
          'state' => 'UT',
          'sec_unit_num' => 'D304',
          'zip' => '84098',
          'city' => 'Park City',
          'suffix' => 'W',
          'type' => '',
          'sec_unit_type' => 'Apt',
          'prefix' => 'N'
    },
    "100 South St, Philadelphia, PA" => {
          'number' => '100',
          'street' => 'South',
          'state' => 'PA',
          'city' => 'Philadelphia',
          'type' => 'St',
        },
    "100 S.E. Washington Ave, Minneapolis, MN" => {
          'number' => '100',
          'street' => 'Washington',
          'state' => 'MN',
          'city' => 'Minneapolis',
          'type' => 'Ave',
          'prefix' => 'SE'
        },
    "3813 1/2 Some Road, Los Angeles, CA" => {
          'number' => '3813',
          'street' => 'Some',
          'state' => 'CA',
          'city' => 'Los Angeles',
          'type' => 'Rd',
        },
    "Mission & Valencia San Francisco CA" => {
          'type1' => '',
          'type2' => '',
          'street1' => 'Mission',
          'state' => 'CA',
          'city' => 'San Francisco',
          'street2' => 'Valencia'
        },
    "Mission & Valencia, San Francisco CA" => {
          'type1' => '',
          'type2' => '',
          'street1' => 'Mission',
          'state' => 'CA',
          'city' => 'San Francisco',
          'street2' => 'Valencia'
        },
    "Mission St and Valencia St San Francisco CA" => {
          'type1' => 'St',
          'type2' => 'St',
          'street1' => 'Mission',
          'state' => 'CA',
          'city' => 'San Francisco',
          'street2' => 'Valencia'
        },
    "Mission St & Valencia St San Francisco CA" => {
          'type1' => 'St',
          'type2' => 'St',
          'street1' => 'Mission',
          'state' => 'CA',
          'city' => 'San Francisco',
          'street2' => 'Valencia'
        },
    "Mission and Valencia Sts San Francisco CA" => {
          'type1' => 'St',
          'type2' => 'St',
          'street1' => 'Mission',
          'state' => 'CA',
          'city' => 'San Francisco',
          'street2' => 'Valencia'
        },
    "Mission & Valencia Sts. San Francisco CA" => {
          'type1' => 'St',
          'type2' => 'St',
          'street1' => 'Mission',
          'state' => 'CA',
          'city' => 'San Francisco',
          'street2' => 'Valencia'
        },
    "Mission & Valencia Streets San Francisco CA" => {
          'type1' => 'St',
          'type2' => 'St',
          'street1' => 'Mission',
          'state' => 'CA',
          'city' => 'San Francisco',
          'street2' => 'Valencia'
        },
    "Mission Avenue and Valencia Street San Francisco CA" => {
          'type1' => 'Ave',
          'type2' => 'St',
          'street1' => 'Mission',
          'state' => 'CA',
          'city' => 'San Francisco',
          'street2' => 'Valencia'
        },
    "1 First St, e San Jose CA" => { # lower case city direction
          'number' => '1',
          'street' => 'First',
          'state' => 'CA',
          'city' => 'East San Jose',
          'type' => 'St',
        },
    "123 Maple Rochester, New York" => { # space in state name
          'type' => '',
          'number' => '123',
          'street' => 'Maple',
          'state' => 'NY',
          'city' => 'Rochester',
        },
    "233 S Wacker Dr 60606-6306" => { # zip+4 with hyphen
          'number' => '233',
          'street' => 'Wacker',
          'zip' => '60606',
          'type' => 'Dr',
          'prefix' => 'S'
        },
    "233 S Wacker Dr 606066306" => { # zip+4 without hyphen
          'number' => '233',
          'street' => 'Wacker',
          'zip' => '60606',
          'type' => 'Dr',
          'prefix' => 'S'
        },
    "233 S Wacker Dr lobby 60606" => { # unnumbered secondary unit type
          'number' => '233',
          'street' => 'Wacker',
          'zip' => '60606',
          'type' => 'Dr',
          'prefix' => 'S',
          'sec_unit_type' => 'lobby',
        },
    "(233 S Wacker Dr lobby 60606)" => { # surrounding punctuation
          'number' => '233',
          'street' => 'Wacker',
          'zip' => '60606',
          'type' => 'Dr',
          'prefix' => 'S',
          'sec_unit_type' => 'lobby',
        },
    "#42 233 S Wacker Dr 60606" => { # leading numbered secondary unit type
          'sec_unit_num' => '42',
          'zip' => '60606',
          'number' => '233',
          'street' => 'Wacker',
          'sec_unit_type' => '#',
          'type' => 'Dr',
          'prefix' => 'S'
        },
    "lt42 99 Some Road, Some City LA" => { # no space before sec_unit_num
          'sec_unit_num' => '42',
          'city' => 'Some City',
          'number' => '99',
          'street' => 'Some',
          'sec_unit_type' => 'lt',
          'type' => 'Rd',
          'state' => 'LA'
        },
    "36401 County Road 43, Eaton, CO 80615" => { # numbered County Road
          'city' => 'Eaton',
          'zip' => '80615',
          'number' => '36401',
          'street' => 'County Road 43',
          'type' => 'Rd',
          'state' => 'CO'
        },
    "1234 COUNTY HWY 60E, Town, CO 12345" => {
        'city' => 'Town',
        'zip' => '12345',
        'number' => '1234',
        'street' => 'COUNTY HWY 60',
        'suffix' => 'E',
        'type' => '',  # ?
        'state' => 'CO'
        },

    "321 S. Washington" => { # RT#82146
          'type' => '',
          'prefix' => 'S',
          'street' => 'Washington',
          'number' => '321'
        },

    "'45 Quaker Ave, Ste 105'" => { # RT#73397
          'number' => '45',
          'street' => 'Quaker',
          'type' => 'Ave',
          'sec_unit_num' => '105',
          'sec_unit_type' => 'Ste'
        },

);


while (my ($addr, $expected) = each %address) {
    my $parse = Geo::StreetAddress::US->parse_location( $addr );
    is_deeply( $parse, $expected, "can parse $addr" )
        or warn "Got: ".Dumper($parse);
}


my @failures = (
    "1005 N Gravenstein Hwy Sebastopol",
    "1005 N Gravenstein Hwy Sebastopol CZ",
    "Gravenstein Hwy 95472",
    "E1005 Gravenstein Hwy 95472",
    "1005E Gravenstein Hwy 95472",
);

for my $fail (@failures) {
    my $parse = Geo::StreetAddress::US->parse_location( $fail );
    ok( !$parse || !defined($parse->{state}), "can't parse $fail" );
}

ok not Geo::StreetAddress::US->avoid_redundant_street_type;
Geo::StreetAddress::US->avoid_redundant_street_type(1);
ok Geo::StreetAddress::US->avoid_redundant_street_type;

is_deeply Geo::StreetAddress::US->parse_location("36401 County Road 43, Eaton, CO 80615"), {
    'city' => 'Eaton',
    'zip' => '80615',
    'number' => '36401',
    'street' => 'County Road 43',
    'type' => undef,  #
    'state' => 'CO'
}, 'type should be undef for Country Road 43 with avoid_redundant_street_type';

# XXX TODO: a suffix like "COUNTY HWY 60E" breaks this logic
# but not very badly, suffix='E', street='COUNTY HWY 60' and type='' (not undef)
is_deeply Geo::StreetAddress::US->parse_location("1234 COUNTY HWY 60, Town, CO 12345"), {
    'city' => 'Town',
    'zip' => '12345',
    'number' => '1234',
    'street' => 'COUNTY HWY 60',
    'type' => undef,
    'state' => 'CO'
}, 'type should be undef for COUNTY HWY 60 with avoid_redundant_street_type';

done_testing();

