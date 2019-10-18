package main;

use strict;
use warnings;

use HTTP::Response;
use HTTP::Status;
use JSON;
use Test::More 0.88;

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};
use constant REGEXP_REF	=> ref qr{};

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

diag "Accessing @{[ $ele->get( 'usgs_url' ) ]}";

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
    $rslt = eval {$ele->elevation( @ele_loc )};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation() succeeded')
	or _skip_tests( 4 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, HASH_REF, 'elevation() returned a hash' );
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset,
	"Data came from $ele_dataset" );
    is($rslt->{Units}, 'Feet', 'Elevation is in feet');
    is($rslt->{Elevation}, $ele_ft, "Elevation is $ele_ft");
}

$ele->set(
    croak => 1,
    units => 'METERS'
);

SKIP: {
    $rslt = eval {[$ele->elevation( @ele_loc )]};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation() succeeded in list context')
	or _skip_tests( 7 );
    is(ref $rslt, ARRAY_REF, 'elevation() returns an array in list context');
    ref $rslt eq ARRAY_REF or $rslt = [];	# To keep following from blowing up.
    cmp_ok(scalar @$rslt, '==', 1, 'elevation() returned a single result');
    is(ref ($rslt->[0]), HASH_REF, 'elevation\'s only result was a hash');
    is( $rslt->[0]{Data_Source}, $ele_dataset, "Data came from $ele_dataset" );
    is($rslt->[0]{Units}, 'Meters', 'Elevation is in meters');
    is($rslt->[0]{Elevation}, $ele_mt, "Elevation is $ele_mt");
}

SKIP: {
    $rslt = eval {[$ele->elevation( @ele_loc )]};
    _skip_on_server_error($ele, 6);
    ok(!$@, 'elevation() succeeded with regexp source')
	or _skip_tests( 6 );
    is(ref $rslt, ARRAY_REF, 'Get an array back from regexp source');
    ref $rslt eq ARRAY_REF or $rslt = [];	# To keep following from blowing up.
    cmp_ok(scalar @$rslt, '>=', 1, 'Should have at least one result');
    $rslt = {map {$_->{Data_Source} => $_} @$rslt};
    ok($rslt->{$ele_dataset}, "We have results from $ele_dataset");
    is($rslt->{$ele_dataset}{Units}, 'Meters', 'Elevation is in meters');
    is($rslt->{$ele_dataset}{Elevation}, $ele_mt, "Elevation is $ele_mt");
}

my $gp = bless [ @ele_loc ], 'Geo::Point';

SKIP: {
    $rslt = eval {$ele->elevation($gp)};
    _skip_on_server_error($ele, 7);
    ok(!$@, 'elevation(Geo::Point) succeeded')
	or _skip_tests( 4 );
    # Note that prior to version 0.106_01 the default for
    # the 'compatibility' attribute was true, which caused an array to
    # be returned.
    is( ref $rslt, HASH_REF,
	'elevation(Geo::Point) returns a hash' );
    $rslt ||= {};	# To keep following from blowing up.
    is( $rslt->{Data_Source}, $ele_dataset, "Data came from $ele_dataset" );
    is( $rslt->{Units}, 'Meters', 'Elevation is in meters' );
    is( $rslt->{Elevation}, $ele_mt, "Elevation is $ele_mt" );
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

    $rslt = eval {$ele->elevation($gp)};
    _skip_on_server_error($ele, 7);
    ok(!$@, "elevation($kind) succeeded")
	or _skip_tests( 7 );
    is( ref $rslt, HASH_REF, "elevation($kind) returns a hash");
    $rslt ||= {};	# To keep following from blowing up.
    is($rslt->{Data_Source}, $ele_dataset,
	"$kind data came from $ele_dataset");
    is($rslt->{Units}, 'Meters', "$kind elevation is in meters");
    is($rslt->{Elevation}, $ele_mt, "$kind elevation is $ele_mt");
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
