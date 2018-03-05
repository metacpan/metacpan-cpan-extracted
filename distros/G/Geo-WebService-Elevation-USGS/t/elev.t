package main;

use strict;
use warnings;

use HTTP::Response;
use HTTP::Status;
use JSON;
use Test::More 0.88;

no warnings qw{ deprecated };

use constant BAD_EXTENT_SOURCE => 'NED.AK_NED';
use constant NO_DATA_FOUND_RE => qr{ \A \QNo data found in query result}smx;

_skip_it(eval { require Geo::WebService::Elevation::USGS; 1; },
    'Unable to load Geo::WebService::Elevation::USGS');

_skip_it(eval { require LWP::UserAgent; 1; },
    'Unable to load LWP::UserAgent (should not happen)');

_skip_it(eval { require HTTP::Response; 1; },
    'Unable to load HTTP::Response (should not happen)');

my $ele = _skip_it(eval {Geo::WebService::Elevation::USGS->new(
	    places => 2 )},
    'Unable to instantiate Geo::WebService::Elevation::USGS');

{
    my $ua = _skip_it(eval {LWP::UserAgent->new()},
	'Unable to instantiate LWP::UserAgent (should not happen)');

    my $pxy = _skip_it(eval { $ele->USGS_URL() },
	'Unable to retrieve USGS URL');

    my $rslt = _skip_it(eval {$ua->get($pxy)},
	'Unable to execute GET (should not happen)');

    _skip_it($rslt->is_success(),
	"Unable to access $pxy");
}

#x# my $ele_dataset = 'Elev_DC_Washington';	# Expected data set
#y# my $ele_dataset = 'NED 1/3 arc-second';	# Expected data set
my $ele_dataset = '3DEP 1/3 arc-second';	# Expected data set
my $ele_re = qr{ \A Elev_DC }smx;	# Regexp for data set
#x# my $ele_ft = '57.03';	# expected elevation in feet.
#x# my $ele_ft = '56.95';	# expected elevation in feet.
my $ele_ft = '56.53';	# expected elevation in feet.
my @ele_loc = ( 38.898748, -77.037684 );	# Lat/Lon to get elevation for
#x# my $ele_mt = '17.38';	# Expected elevation in meters.
#x# my $ele_mt = '17.36';	# Expected elevation in meters.
my $ele_mt = '17.23';	# Expected elevation in meters.

my $rslt;

SKIP: {
    $rslt = eval {$ele->getElevation( @ele_loc )};
    _skip_on_server_error($ele, 6);
    ok(!$@, 'getElevation succeeded')
	or _skip_tests( 6 );
    ok($rslt, 'getElevation returned a result');
    is(ref $rslt, 'HASH', 'getElevation returned a hash');
    is( $rslt->{Data_Source}, $ele_dataset,
	"Data came from $ele_dataset" );
    is($rslt->{Units}, 'Feet', 'Elevation is in feet');
    is($rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft");
}

SKIP: {
    $rslt = eval {$ele->getElevation( @ele_loc , undef, 1)};
    _skip_on_server_error($ele, 2);
    ok(!$@, 'getElevation (only) succeeded')
	or _skip_tests( 2 );
    is($rslt, $ele_ft, "getElevation (only) returned $ele_ft");
}

SKIP: {
    $rslt = eval {$ele->elevation( @ele_loc )};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation() succeeded')
	or _skip_tests( 4 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH', 'elevation() returned a hash' );
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset,
	"Data came from $ele_dataset" );
    is($rslt->{Units}, 'Feet', 'Elevation is in feet');
    is($rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft");
}

$ele->set(source => []);
is(ref ($ele->get('source')), 'ARRAY', 'Source can be set to an array ref');

SKIP: {
    $rslt = eval {$ele->elevation( @ele_loc )};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation() still succeeds')
	or _skip_tests( 4 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH', 'elevation() still returns a hash');
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset,
	"We have results from $ele_dataset" );
    is( $rslt->{Units}, 'Feet', 'Elevation is in feet' );
    is( $rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft" );
}

$ele->set(source => {});
is(ref ($ele->get('source')), 'HASH', 'Source can be set to a hash ref');

SKIP: {
    $rslt = eval {$ele->elevation( @ele_loc )};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation() with hash source still succeeds')
	or _skip_tests( 7 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH',
	'elevation() with hash source still returns a hash');
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset,
	"We have results from $ele_dataset" );
    is( $rslt->{Units}, 'Feet', 'Elevation is in feet' );
    is( $rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft" );
}

SKIP: {
    $ele->set(
	source => [ $ele_dataset, 'NED.CONUS_NED_13E', 'NED.CONUS_NED'],
	use_all_limit => 5,
    );
    $rslt = eval {$ele->elevation( @ele_loc )};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation() still succeeds')
	or _skip_tests( 7 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH', 'elevation() still returns a hash' );
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset,
	"We have results from $ele_dataset" );
    is( $rslt->{Units}, 'Feet', 'Elevation is in feet' );
    is( $rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft" );
}

$ele->set(
##  source => ['NED.CONUS_NED_13E', 'NED.CONUS_NED', 'SRTM.C_SA_3'],
##  source => ['NED.CONUS_NED_13E', 'NED.CONUS_NED', 'NED.AK_NED'],
##  source => ['NED.CONUS_NED_13E', 'NED.CONUS_NED', BAD_EXTENT_SOURCE],
    source => [ $ele_dataset, 'NED.CONUS_NED_13E', 'NED.CONUS_NED',
	BAD_EXTENT_SOURCE ],
    use_all_limit => 0,
);

SKIP: {
    $rslt = eval {$ele->elevation( @ele_loc )};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation() done by iteration succeeds')
	or _skip_tests( 4 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH', 'elevation() still returns a hash' );
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset,
	"We have results from $ele_dataset" );
    is( $rslt->{Units}, 'Feet', 'Elevation is in feet' );
    is( $rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft" );
}

SKIP: {
    $rslt = eval {$ele->elevation( @ele_loc , 1)};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation(valid) succeeds')
	or _skip_tests( 4 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH', 'elevation(valid) still returns a hash' );
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset,
	"We have results from $ele_dataset" );
    is( $rslt->{Units}, 'Feet', 'Elevation is in feet' );
    is( $rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft" );
}

{
    my $msg;
    local $SIG{__WARN__} = sub {$msg = $_[0]};
    my $bogus = $ele->new();
    ok($bogus, 'Call new() as normal method');
    isnt($bogus, $ele, 'They are different objects');

    # CAVEAT:
    # Direct manipulation of the attribute hash is UNSUPPORTED! I can't
    # think why anyone would want a public interface for {_hack_result}
    # anyway. If you do, contact me, and if I can't talk you out of it
    # we will come up with something.
    $bogus->{_hack_result} = _make_resp(
	{
	    USGS_Elevation_Point_Query_Service	=> {
		Elevation_Query	=> {
		    Elevation	=> 58.6035683399111,
		},
	    },
	}
    );
    $rslt = eval {$bogus->getElevation( @ele_loc , undef, 1)};
    ok(!$@, 'getElevation (only) succeeded') or diag($@);
    is($rslt, '58.6035683399111',
	'getElevation (only) returned 58.6035683399111');

=begin comment

    SKIP: {
	$rslt = eval {$bogus->getElevation(40, 90, 'NED.CONUS_NED_13E')};
	ok(!$@, 'getElevation without returned value succeeded')
	    or _skip_tests( 3 );
	ok( ref $rslt eq 'HASH', 'getElevation result is a hash ref' );
    }

=end comment

=cut

    $bogus->{_hack_result} = $ele->_get_bad_som();
    $rslt = eval {$bogus->getElevation( @ele_loc , undef, 1)};
    ok($bogus->get('error'),
	'getElevation() SOAP failures other than BAD_EXTENT conversion are errors.');

    $bogus->set(
	source => sub {$_[1]{Data_Source} eq $ele_dataset },
	use_all_limit => 0,
    );
    is(ref $bogus->get('source'), 'CODE', 'Can set source to code ref');
    SKIP: {
	$rslt = eval {$bogus->elevation( @ele_loc )};
	_skip_on_server_error($bogus, 5);
	ok(!$@, 'elevation succeeded using code ref as source')
	    or _skip_tests( 2 );
	ok($rslt, 'Got a result when using code ref as source');
	# Note that prior to version 0.106_01 the default
	# for the 'compatibility' attribute was true, which caused an
	# array to be returned.
	is( ref $rslt, 'HASH', 'Got hash ref when using code ref as source' );
	$rslt ||= {};	# To keep following from blowing up.
	is( $rslt->{Data_Source}, $ele_dataset,
	    'Got correct Data_Source when using code ref as source');
    }

    $bogus->set(source => []);
    $bogus->{_hack_result} = _make_resp( undef );
    $rslt = eval {$bogus->elevation( @ele_loc )};
    like($@, NO_DATA_FOUND_RE,
	'No data error when going through getAllElevations');

    $bogus->set(croak => 0, carp => 1);
    $bogus->{_hack_result} = _make_resp( undef );
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok(!$@, 'Should not throw an error on bad result if croak is false')
	or diag($@);
    like( $msg, qr{ \A No \s data \s found \b }smx,
	'Should warn if croak is false but carp is true' );
    ok(!$rslt, 'Should return undef on bad result if croak is false');
    like($bogus->get('error'), NO_DATA_FOUND_RE,
	'No data error when going through getAllElevations');

    $msg = undef;
    $bogus->set(carp => 0);
    $bogus->{_hack_result} = _make_resp( undef );
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok(!$@, 'Should not throw an error on bad result if croak is false')
	or diag($@);
    ok( ! defined $msg, 'Should not warn if carp is false' );
    ok(!$rslt, 'Should return undef on bad result if croak is undef');
    like($bogus->get('error'), NO_DATA_FOUND_RE,
	'No data error when going through getAllElevations');

    $msg = undef;
    $bogus->set(carp => 0);
    $bogus->{_hack_result} = sub { die 'Artificial failure' };
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok(!$@, 'Should not throw an error on exception if croak is false')
	or diag($@);
    ok( ! defined $msg, 'Should not warn on exception if carp is false' );
    ok(!$rslt, 'Should return undef on exception if croak is undef');
    like($bogus->get('error'), qr{ \A \QArtificial failure\E \b}smx,
	'No data error when going through getAllElevations');

    SKIP: {
	$bogus->set(
	    source => {&BAD_EXTENT_SOURCE => 1},
	    use_all_limit => 5,
	);
	$rslt = eval {$bogus->elevation( @ele_loc )};
	_skip_on_server_error($bogus, 2);
	my $err = $bogus->get('error');
	$err =~ m/Input Source Layer was invalid/i
	    and skip($err, 2);
	ok(!$err,
	    "Query of @{[ BAD_EXTENT_SOURCE ]} still is not an error" )
	    or diag($bogus->get('error'));
    }

    $bogus->{_hack_result} = $ele->_get_bad_som();
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok($bogus->get('error'),
	'SOAP failures other than conversion of BAD_EXTENT are still errors.');

    $bogus->set(croak => 1);
    $bogus->{_hack_result} = $ele->_get_bad_som();
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok($@,
	'SOAP failures other than conversion are fatal with croak => 1');
    ok($bogus->get('error'),
	'SOAP failures should set {error} even if fatal');

    $bogus->set(
	source => ['FUBAR'],
	use_all_limit => 0,
	croak => 0,
    );

    $bogus->set(source => undef, croak => 1);
    $bogus->{_hack_result} = _make_resp( undef );
    $rslt = eval {$bogus->elevation( @ele_loc )};
    like($@, NO_DATA_FOUND_RE,
	'No data error when going through getElevations');

    $bogus->set(croak => 0);
    $bogus->{_hack_result} = _make_resp( undef );
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok(!$@, 'Should not throw an error on bad result if croak is false')
	or diag($@);
    ok(!$rslt, 'Should return undef on bad result if croak is false');
    like($bogus->get('error'), NO_DATA_FOUND_RE,
	'No data error when going through getElevation');

    $bogus->{_hack_result} = _make_resp( {} );
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok(!$@, 'Should not throw an error on bad result if croak is false')
	or diag($@);
    like($bogus->get('error'), qr{^Elevation result is missing element},
	'Missing element error when going through getElevation');

    $bogus->{_hack_result} = _make_resp(
	{
	    USGS_Elevation_Point_Query_Service => [],
	},
    );
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok(!$@, 'Should not throw an error on bad result if croak is false')
	or diag($@);
    like($bogus->get('error'), qr{^Elevation result is missing element},
	'Missing element error when going through getElevation');

    $bogus->{_hack_result} = _make_resp(
	{
	    USGS_Elevation_Point_Query_Service => {
		Elevation_Query => 'Something bad happened',
	    },
	},
    );
    $rslt = eval {$bogus->elevation( @ele_loc )};
    ok(!$@, 'Should not throw an error on bad result if croak is false')
	or diag($@);
    like($bogus->get('error'), qr{^Something bad happened},
	'Missing data error when going through getElevation');

    $bogus->{_hack_result} = _make_resp(
	{
	    USGS_Elevation_Point_Query_Service => {
		Elevation_Query => {
		    Data_Source => $ele_dataset,
		    Data_ID	=> $ele_dataset,
		    Elevation => 58.6035683399111,
		    Units => 'FEET',
		},
	    },
	},
    );
    $rslt = eval {$bogus->getAllElevations( @ele_loc )};
    ok(!$bogus->get('error'),
	'Should not declare an error processing an individual point')
	or diag 'Error: ' . $bogus->get( 'error' );
    is(ref $rslt, 'ARRAY', 'Result should still be an array ref')
	or $rslt = [];
    cmp_ok(scalar @$rslt, '==', 1, 'getAllelevations() returned one result');
    ok(!(grep {ref $_ ne 'HASH'} @$rslt),
	'elevation\'s results are all hashes');
    $rslt = {map {$_->{Data_ID} => $_} @$rslt};
    ok($rslt->{$ele_dataset}, "We have results from $ele_dataset" );
    is($rslt->{$ele_dataset}{Units}, 'FEET', 'Elevation is in feet');
    is($rslt->{$ele_dataset}{Elevation}, '58.6035683399111',
	'Elevation is 58.6035683399111');

}

{
    my $retries;
    my $bogus = $ele->new(
	places => 2,
	retry => 1,	# Do a single retry
	retry_hook => sub { $retries++ },	# Just count them
    );

    SKIP: {
	$retries = 0;
	$bogus->{_hack_result} = $ele->_get_bad_som();
	$rslt = eval {$bogus->getElevation( @ele_loc )};
	ok( $retries, 'A retry was performed' );
	_skip_on_server_error($bogus, 6);
	ok(!$@, 'getElevation succeeded on retry')
	    or _skip_tests( 6 );
	ok($rslt, 'getElevation returned a result on retry');
	is(ref $rslt, 'HASH', 'getElevation returned a hash on retry');
	is( $rslt->{Data_Source}, $ele_dataset,
	    "Data came from $ele_dataset on retry" );
	is($rslt->{Units}, 'Feet', 'Elevation is in feet on retry');
	is($rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft on retry");
    }

    SKIP: {
	$retries = 0;
	$bogus->{_hack_result} = $ele->_get_bad_som();
	$rslt = eval {$bogus->getAllElevations( @ele_loc )};
	ok( $retries, 'A retry was performed' );
	_skip_on_server_error($bogus, 6);
	ok(!$@, 'getAllElevations succeeded on retry')
	    or _skip_tests( 6 );
	ok($rslt, 'getAllElevations returned a result on retry');
	is(ref $rslt, 'ARRAY', 'getAllElevations returned an array on retry');
	my %hash = map { $_->{Data_Source} => $_ } @{ $rslt };
	ok( $hash{$ele_dataset},
	    "Results contain $ele_dataset on retry" );
	is($hash{$ele_dataset}{Units}, 'Feet',
	    'Elevation is in feet on retry');
	is($hash{$ele_dataset}{Elevation}, $ele_ft,
	    "Elevation is $ele_ft on retry");
    }

    SKIP: {
	eval {
	    require Time::HiRes;
	    Time::HiRes->can( 'time' ) && Time::HiRes->can( 'sleep' );
	} or skip( "Unable to load Time::HiRes", 2 );
	$retries = 0;
	Geo::WebService::Elevation::USGS->set( throttle => 5 );
	$bogus->{_hack_result} = $ele->_get_bad_som();
	my $start = Time::HiRes::time();
	$rslt = eval {$bogus->getElevation( @ele_loc )};
	my $finish = Time::HiRes::time();
	ok( $retries, 'A retry was performed after throttling' );
	cmp_ok( $finish - $start, '>', 4,
	    'Throttling in fact probably took place' );
	Geo::WebService::Elevation::USGS->set( throttle => undef );
    }

}

$ele->set(
    croak => 1,
    source => undef,
    units => 'METERS'
);

SKIP: {
    $rslt = eval {$ele->getElevation( @ele_loc )};
    _skip_on_server_error($ele, 6);
    ok(!$@, 'getElevation again succeeded')
	or _skip_tests( 6 );
    ok($rslt, 'getElevation again returned a result');
    is(ref $rslt, 'HASH', 'getElevation again returned a hash');
    is( $rslt->{Data_Source}, $ele_dataset, "Data again came from $ele_dataset" );
    is($rslt->{Units}, 'Meters', 'Elevation is in meters');
    is($rslt->{Elevation}, $ele_mt, "Elevation is $ele_mt");
}

SKIP: {
    $rslt = eval {$ele->getElevation( @ele_loc , undef, 1)};
    _skip_on_server_error($ele, 2);
    ok(!$@, 'getElevation(only) succeeded')
	or _skip_tests( 2 );
    is($rslt, $ele_mt, "getElevation (only) returned $ele_mt");
}

SKIP: {
    $rslt = eval {[$ele->elevation( @ele_loc )]};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation() succeeded in list context')
	or _skip_tests( 7 );
    is(ref $rslt, 'ARRAY', 'elevation() returns an array in list context');
    ref $rslt eq 'ARRAY' or $rslt = [];	# To keep following from blowing up.
    cmp_ok(scalar @$rslt, '==', 1, 'elevation() returned a single result');
    is(ref ($rslt->[0]), 'HASH', 'elevation\'s only result was a hash');
    is( $rslt->[0]{Data_Source}, $ele_dataset, "Data came from $ele_dataset" );
    is($rslt->[0]{Units}, 'Meters', 'Elevation is in meters');
    is($rslt->[0]{Elevation}, $ele_mt, "Elevation is $ele_mt");
}

eval {$ele->set(source => \*STDOUT)};
like($@, qr{^Attribute source may not be a GLOB ref},
    'Can not set source as a glob ref');
$ele->set( source => $ele_re );
is(ref $ele->get('source'), 'Regexp', 'Can set source as a regexp ref');

SKIP: {
    $rslt = eval {[$ele->elevation( @ele_loc )]};
    _skip_on_server_error($ele, 6);
    ok(!$@, 'elevation() succeeded with regexp source')
	or _skip_tests( 6 );
    is(ref $rslt, 'ARRAY', 'Get an array back from regexp source');
    ref $rslt eq 'ARRAY' or $rslt = [];	# To keep following from blowing up.
    cmp_ok(scalar @$rslt, '>=', 1, 'Should have at least one result');
    $rslt = {map {$_->{Data_Source} => $_} @$rslt};
    ok($rslt->{$ele_dataset}, "We have results from $ele_dataset");
    is($rslt->{$ele_dataset}{Units}, 'Meters', 'Elevation is in meters');
    is($rslt->{$ele_dataset}{Elevation}, $ele_mt, "Elevation is $ele_mt");
}

my $gp = bless [ @ele_loc ], 'Geo::Point';
$ele->set(source => {$ele_dataset => 1});
is(ref $ele->get('source'), 'HASH', 'Can set source as a hash');

SKIP: {
    $rslt = eval {$ele->elevation($gp)};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation(Geo::Point) succeeded')
	or _skip_tests( 4 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH',
	'elevation(Geo::Point) returns a hash' );
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset, "Data came from $ele_dataset" );
    is( $rslt->{Units}, 'Meters', 'Elevation is in meters' );
    is( $rslt->{Elevation}, $ele_mt, "Elevation is $ele_mt" );
}

SKIP: {
    $ele->set(use_all_limit => -1);	# Force iteration.
    $rslt = eval {$ele->elevation($gp)};
    _skip_on_server_error($ele, 2);
    ok(!$@, 'elevation(Geo::Point) via getElevation succeeded')
	or _skip_tests( 2 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH',
	'elevation(Geo::Point) returns a hash');
}

SKIP: {
    my $kind;
    if ( eval { require GPS::Point; 1 } ) {
	$gp = GPS::Point->new();
	$gp->lat( $ele_loc[0] );
	$gp->lon( $ele_loc[1] );
	$gp->alt(undef);
	$kind = 'real GPS::Point';
    } else {
	$gp = bless [ @ele_loc ], 'GPS::Point';
	no warnings qw{once};
	*GPS::Point::latlon = \&Geo::Point::latlong;
	$kind = 'dummy GPS::Point';
    }
    $ele->set(use_all_limit => 0);	# Force getAllElevations
    $rslt = eval {$ele->elevation($gp)};
    _skip_on_server_error($ele, 7);
    ok(!$@, "elevation($kind) via getAllElevations succeeded")
	or _skip_tests( 7 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, 'HASH', "elevation($kind) returns a hash");
    $rslt ||= {};	# To keep following from blowing up.
    is($rslt->{Data_Source}, $ele_dataset,
	"$kind data came from $ele_dataset");
    is($rslt->{Units}, 'Meters', "$kind elevation is in meters");
    is($rslt->{Elevation}, $ele_mt, "$kind elevation is $ele_mt");
}

$ele->set( compatible => 1 );

SKIP: {
    $rslt = eval {
	$ele->elevation( @ele_loc );
    };
    _skip_on_server_error( $ele, 1 );
    is_deeply $rslt, [
	{
	    x		=> $ele_loc[1],
	    y		=> $ele_loc[0],
	    Data_ID	=> $ele_dataset,
	    Data_Source	=> $ele_dataset,
	    Elevation	=> $ele_mt,
	    Units	=> 'METERS',
	},
    ],	q{elevation() with 'compatible' set true};
}

_skip_on_server_summary();

done_testing();

{
    my $json;
    sub _make_resp {
	my ( $content, $code ) = @_;
	$json ||= JSON->new()->utf8()->allow_nonref();
	defined $code
	    or $code = HTTP::Status->HTTP_OK;
	my $resp = HTTP::Response->new( $code );
	$resp->content( $json->encode( $content ) );
	return $resp;
    }
}

sub _skip_tests {
    my ( $count ) = @_;
    diag $@;
    skip 'Query failed', $count - 1;
    return;	# Never executed.
}

# I need to mung the argument list before use because the idea is to
# call this with an indication of whether to skip the whole test and
# a reason for skipping. The first argument may be computed inside an
# eval{}, which returns () in list context on failure.
#
sub _skip_it {
    my @args = @_;
    @args > 1
	or unshift @args, undef;  # Because eval{} returns () in list context.
    my ($check, $reason) = @args;
    unless ($check) {
	plan (skip_all => $reason);
	exit;
    }
    return $check;
}

{
    my $skips;

    sub _skip_on_server_error {
	my ($ele, $how_many) = @_;
	local $_ = $ele->get( 'error' ) or return;
	s/ \s+ \z //smx;
	(m/^5\d\d\b/ ||
	    m/^ERROR: No Elevation values were returned/i ||
	    m/^ERROR: No Elevation value was returned/i ||
	    m/System\.Web\.Services\.Protocols\.SoapException/i
	) or return;
	$skips += $how_many;
	my (undef, $file, $line) = caller(0);
	diag("Skipping $how_many tests: $_ at $file line $line");
	return skip ($_, $how_many);
    }

    sub _skip_on_server_summary {
	$skips and diag(<<eod);

Skipped $skips tests due to apparent server errors.

eod
	return;
    }

}

sub Geo::Point::latlong {
    return ( @{ $_[0] } )
}

my $VAR1;
sub Geo::WebService::Elevation::USGS::_get_bad_som {
##  my ( $self ) = @_;
    return ( $VAR1 ||= HTTP::Response->new(
	    HTTP::Status->HTTP_INTERNAL_SERVER_ERROR,
	    'Internal Server Error' ) );
}

1;
