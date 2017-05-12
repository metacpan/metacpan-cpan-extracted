package Test::Zone;

use Test::Most;
use Test::Roo::Role;

use DateTime;
use Scalar::Util qw(blessed);

test 'zone tests' => sub {

    my $self = shift;

    my ( $rset, %countries, %states, %zones, $data, $result );

    my $dt = DateTime->now;

    # stuff countries and states into hashes to save lots of lookups later

    $rset = $self->countries->search( {} );
    while ( my $res = $rset->next ) {
        $countries{ $res->country_iso_code } = $res;
    }

    $rset = $self->states->search( {} );
    while ( my $res = $rset->next ) {
        $states{ $res->country_iso_code . "_" . $res->state_iso_code } = $res;
    }

    # test populate zone

    $rset = $self->zones->search( { zone => 'US lower 48' } );
    cmp_ok( $rset->count, '==', 1, "Found zone: US lower 48" );

    $result = $rset->next;
    cmp_ok( $result->state_count, '==', 49, "has 49 states :-)" );
    ok( $result->has_state('NY'), "includes NY state" );
    ok( $result->has_state('DC'), "includes DC" );
    is( $result->has_state('AK'),             0, "does not include Alaska" );
    is( $result->has_state('HI'),             0, "or Hawaii" );
    is( $result->has_state('FooBar'),         0, "or FooBar" );
    is( $result->has_state( $countries{GB} ), 0, "or country GB (as state)" );

    $rset = $self->zones->search( { zone => 'EU member states' } );
    cmp_ok( $rset->count, '==', 1, "Found zone: EU member states" );

    $result = $rset->next;
    cmp_ok( $result->country_count, '==', 28, "has 28 countries" );
    cmp_ok( $result->state_count,   '==', 0,  "has 0 states" );
    ok( $result->has_country( $countries{MT} ),
        "includes Malta (country obj)" );
    ok( $result->has_country('MT'),    "includes Malta (MT)" );
    ok( $result->has_country('Malta'), "includes Malta" );
    is( $result->has_country('IM'), 0, "does not include Isle of Man (IM)" );
    is( $result->has_country('Isle of Man'), 0,
        "does not include Isle of Man" );
    is( $result->has_country( $states{'US_CA'} ),
        0, "countries does not include Caliornia (state obj)" );

    $rset = $self->zones->search( { zone => 'EU VAT countries' } );
    cmp_ok( $rset->count, '==', 1, "Found zone: EU VAT countries" );

    $result = $rset->next;
    cmp_ok( $result->country_count, '==', 29, "has 29 countries" );
    cmp_ok( $result->state_count,   '==', 0,  "has 0 states" );
    ok( $result->has_country('MT'), "includes Malta" );
    ok( $result->has_country('IM'), "includes Isle of Man" );
    is( $result->has_country('CH'), 0, "does not include Switzerland" );

    # other zone tests

    # Canada

    throws_ok(
        sub { $result = $self->zones->create( { zone => 'Canada' } ); },
        qr/unique|duplicate/i,
        "Fail to create zone Canada which already exists (populate)"
    );

    lives_ok(
        sub { $result = $self->zones->create( { zone => 'Canada test' } ); },
        "Create zone: Canada test" );

    lives_ok(
        sub { $result->add_countries( $countries{CA} ) },
        "Create relationship to Country for Canada in zone Canada"
    );

    cmp_ok( $result->country_count, '==', 1, "1 country in zone" );

    throws_ok(
        sub { $result->remove_countries( $countries{US} ) },
        qr/Country does not exist in zone: United States/,
        "Fail to remove country US from zone Canada"
    );

    lives_ok( sub { $result->remove_countries( $countries{CA} ) },
        "Remove country CA from zone Canada" );

    cmp_ok( $result->country_count, '==', 0, "0 country in zone" );

    $rset = $self->ic6s_schema->resultset('ZoneCountry')
      ->search( { zones_id => $result->zones_id } );
    cmp_ok( $rset->count, '==', 0, "check cascade delete in ZoneCountry" );

    $rset = $self->countries->search( { country_iso_code => 'CA' } );
    cmp_ok( $rset->count, '==', 1, "check cascade delete in Country" );

    lives_ok(
        sub { $result->add_countries( $countries{CA} ) },
        "Create relationship to Country for Canada in zone Canada"
    );

    throws_ok(
        sub { $result->remove_countries('FooBar') },
        qr/Bad country: FooBar/,
        "Fail remove country FooBar from zone Canada"
    );

    throws_ok(
        sub { $result->remove_countries( ['FooBar'] ) },
        qr/Bad country: FooBar/,
        "Fail remove country FooBar (arrayref) from zone Canada"
    );

    throws_ok(
        sub { $result->remove_countries( [ $states{'US_CA'} ] ) },
        qr/Country cannot be a Interchange6::Schema::Result::State/,
        "Fail remove_countries(state_obj)"
    );

    lives_ok(
        sub { $result->remove_countries( [ $countries{CA} ] ) },
        "Remove country CA (arrayref) from zone Canada"
    );

    lives_ok(
        sub { $result->add_countries( $countries{CA} ) },
        "Create relationship to Country for Canada in zone Canada"
    );
    lives_ok( sub { $result->add_countries( $countries{US} ) },
        "Create relationship to Country for United States in zone Canada" );

    throws_ok(
        sub { $result->add_states( $states{'CA_BC'} ) },
        qr /Cannot add state to zone with multiple countries/,
        "Cannot add state to zone with multiple countries"
    );

    lives_ok( sub { $result->remove_countries( $countries{US} ) },
        "Remove United States from zone Canada" );

    throws_ok(
        sub { $result->add_states( $countries{CA} ) },
        qr /State cannot be a Interchange6::Schema::Result::Country/,
        "Cannot add country with add_states"
    );

    lives_ok( sub { $result->add_states( $states{'CA_BC'} ) }, "Add BC to CA" );

    throws_ok(
        sub { $result->add_states( [ $states{'CA_NT'}, 'FooBar' ] ) },
        qr/Bad state: FooBar/,
        "Fail add FooBar state to CA in arrayref"
    );

    throws_ok(
        sub { $result->add_states( [ $states{'CA_NT'}, $countries{US} ] ) },
        qr /State cannot be a Interchange6::Schema::Result::Country/,
        "Fail add_state country obj to CA in arrayref"
    );

    lives_ok( sub { $result->remove_states( $states{'CA_BC'} ) },
        "Add BC to CA" );
    lives_ok(
        sub { $result->remove_countries( [ $countries{CA} ] ) },
        "Remove country CA (arrayref) from zone Canada"
    );

    lives_ok(
        sub { $result->add_states( $states{'CA_NT'} ) },
        "Add state NT to CA zone without country"
    );

    is( $result->has_country('CA'), 1, "Zone has country Canada" );

    throws_ok(
        sub { $result->add_states( $states{'CA_NT'} ) },
        qr/Zone already includes state: Northwest Te/,
        "Fail add state NT to CA zone second time"
    );

    throws_ok(
        sub { $result->add_states( $states{'US_CA'} ) },
        qr/State California is not in country Canada/,
        "Fail add state California to Canada zone"
    );

    lives_ok( sub { $result->add_states( $states{'CA_BC'} ) }, "Add BC to CA" );

    throws_ok(
        sub { $result->remove_states( ['FooBar'] ) },
        qr/Bad state: FooBar/,
        "Fail remove_states arrayref of scalar"
    );

    throws_ok(
        sub { $result->remove_states( $countries{US} ) },
        qr /State cannot be a Interchange6::Schema::Result::Country/,
        "Fail remove_states arg is Country obj"
    );

    # CA GST only

    lives_ok(
        sub { $result = $self->zones->create( { zone => 'CA GST only' } ) },
        "Create zone: CA GST only" );

    ok( blessed($result), "Result is blessed" );
    ok( $result->isa('Interchange6::Schema::Result::Zone'),
        "Result is a Zone" );

    lives_ok( sub { $result->add_countries( $countries{CA} ) },
        "Create relationship to Country for Canada in zone CA GST only" );

    throws_ok(
        sub { $result->add_countries( $countries{CA} ) },
        qr/Zone already includes country: Canada/,
        "Exception when adding Canada a second time"
    );

    throws_ok(
        sub { $result->add_countries(undef) },
        qr/Country must be defined/,
        "Fail add_countries with undef arg"
    );

    throws_ok(
        sub { $result->add_countries( [undef] ) },
        qr/Country must be defined/,
        "Fail add_countries with arrayref of undef"
    );

    throws_ok(
        sub { $result->add_countries('FooBar') },
        qr/Bad country: FooBar/,
        "Fail add_countries with scalar arg"
    );

    throws_ok(
        sub { $result->add_countries( ['FooBar'] ) },
        qr/Bad country: FooBar/,
        "Fail add_countries with arrayref of scalar"
    );

    throws_ok(
        sub { $result->add_countries( [ $states{US_CA} ] ) },
        qr/Country cannot be a Interchange6::Schema::Result::State/,
        'Exception add_countries([$state])'
    );

    throws_ok(
        sub { $result->add_countries( 'XX' ) },
        qr/No country found for code: XX/,
        "Exception add_countries('XX')"
    );

    throws_ok(
        sub { $result->add_countries( ['XX'] ) },
        qr/No country found for code: XX/,
        "Exception add_countries(['XX'])"
    );

    lives_ok(
        sub { $result->add_countries( 'US' ) },
        "add 'US' to zone"
    );

    lives_ok(
        sub { $result->add_countries( 'MT' ) },
        "add ['MT'] to zone"
    );

    cmp_ok( $result->country_count, '==', 3, "3 countries in zone" );

    # remove last 2 countries

    lives_ok(
        sub { $result->remove_countries( [qw/MT US/] ) },
        "remove MT and US"
    );

    $data = [
        $states{CA_AB}, $states{CA_NT}, $states{CA_NU},
        $states{CA_YT}, $states{US_CA}
    ];

    throws_ok(
        sub { $result->add_states($data) },
        qr/State California is not in country Canada/,
        "Exception: create relationship to 4 states in zone CA GST plus US_CA"
    );

    cmp_ok( $result->country_count, '==', 1, "1 country in zone" );
    cmp_ok( $result->state_count,   '==', 0, "0 states in zone" );

    $data = [ $states{CA_AB}, $states{CA_NT}, $states{CA_NU}, $states{CA_YT} ];

    lives_ok( sub { $result->add_states($data) },
        "Create relationship to 4 states in zone CA GST" );

    cmp_ok( $result->country_count, '==', 1, "1 country in zone" );
    cmp_ok( $result->state_count,   '==', 4, "4 states in zone" );

    throws_ok(
        sub { $result->add_countries( $countries{US} ) },
        qr/Cannot add countries to zone containing states/,
        "Exception Cannot add countries to zone containing states"
    );

    # USA

    lives_ok( sub { $result = $self->zones->create( { zone => 'US' } ) },
        "Create zone: US" );

    ok( blessed($result), "Result is blessed" );
    ok( $result->isa('Interchange6::Schema::Result::Zone'),
        "Result is a Zone" );

    lives_ok(
        sub { $result->add_countries( $countries{US} ) },
        "Create relationship to Country for US"
    );

    lives_ok( sub { $result->add_to_states( $states{US_CA} ) },
        "add CA to zone US" );

    throws_ok(
        sub { $result->remove_countries( $countries{US} ) },
        qr/States must be removed before countries/,
        "Exception on remove country"
    );

    cmp_ok( $result->country_count, '==', 1, "Country till there" );
    cmp_ok( $result->state_count,   '==', 1, "State still there" );

    lives_ok( sub { $result->remove_states( $states{US_CA} ) },
        "Try to remove state" );

    cmp_ok( $result->country_count, '==', 1, "Country till there" );
    cmp_ok( $result->state_count,   '==', 0, "State removed" );

    lives_ok( sub { $result->remove_countries( $countries{US} ) },
        "Try to remove country" );

    cmp_ok( $result->country_count, '==', 0, "Country removed" );

    # California

    lives_ok(
        sub {
            $result = $self->zones->create(
                {
                    zone => "California",
                }
            );
        },
        "Create California zone"
    );

    lives_ok( sub { $result->add_to_states( $states{US_CA} ) },
        "add CA to zone California" );

    cmp_ok( $result->state_count, '==', 1, "zone has one state" );

    lives_ok( sub { $rset = $self->zones->search( { zone => 'CA GST only' } ) },
        "Search for CA GST only" );
    cmp_ok( $rset->count, '==', 1, "Should have one result" );

    $result = $rset->next;
    cmp_ok( $result->country_count,   '==', 1, "Should have 1 country" );
    cmp_ok( $result->state_count,     '==', 4, "and 4 states" );
    cmp_ok( $result->has_state('AB'), '==', 1, "Check has_state('AB')" );
    cmp_ok( $result->has_state('Alberta'),
        '==', 1, "Check has_state('Alberta')" );
    cmp_ok( $result->has_state( $states{CA_AB} ),
        '==', 1, 'Check has_state($obj)' );

    lives_ok(
        sub {
            $result = $self->zones->create(
                {
                    zone => "a zone",
                    countries => 'US',
                    states => [ 'CA', 'WA' ],
                }
            );
        },
        "Create a zone with one country (scalar) and two states"
    );

    cmp_ok( $result->country_count, '==', 1, "1 country in zone" );
    cmp_ok( $result->state_count,   '==', 2, "2 states in zone" );

    throws_ok {
        $self->zones->create(
            { zone => "state without country", states => 'CA' } );
    }
    qr/Cannot create Zone with states but without countries/,
      "Create zone with states but without countries fails";

    lives_ok {
        $self->zones->create(
            { zone => "multiple countries", countries => [ 'US', 'DE', 'MT' ] }
        );
    }
    "Create zone containg multiple countries";

    lives_ok {
        $self->zones->create(
            {
                zone      => "single country with one non-arrayref state",
                countries => 'US',
                states    => 'CA'
            }
        );
    }
    "Create zone containg single country with one non-arrayref state";

    lives_ok { $result = $self->zones->create( { zone => "empty zone" } ) }
    "Create a zone with no countries and no states";

    throws_ok { $result->add_states('CA') }
    qr/Cannot resolve state_iso_code for zone with no country/,
      "Fail to add a state to an empty zone";

    throws_ok {
        $self->zones->create(
            {
                zone      => "single country with bad state",
                countries => 'US',
                states    => 'XX'
            }
        );
    }
    qr/No state found for code/,
      "Fail create zone containg single country with bad state";

    # cleanup
    lives_ok( sub { $self->clear_zones }, "clear_zones" );
};

1;
