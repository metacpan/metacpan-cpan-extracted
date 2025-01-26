package main;

use strict;
use warnings;

use HTTP::Response;
use HTTP::Status qw{ HTTP_BAD_REQUEST HTTP_OK };
use JSON;
use Test::More 0.88;

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};
use constant REGEXP_REF	=> ref qr{};

no warnings qw{ deprecated };

use constant BAD_EXTENT_SOURCE => 'NED.AK_NED';
use constant NO_DATA_FOUND_RE => qr{ \A \QNo data found in query result}smx;

use constant FEET_TO_METERS	=> 12 * 2.54 / 100;
use constant TOLERANCE_FEET	=> 0.5;
use constant TOLERANCE_METERS	=> 0 + sprintf '%.2f', TOLERANCE_FEET * FEET_TO_METERS;

_skip_it(eval { require Geo::WebService::Elevation::USGS; 1; },
    'Able to load Geo::WebService::Elevation::USGS');

_skip_it(eval { require LWP::UserAgent; 1; },
    'Able to load LWP::UserAgent');

_skip_it(eval { require HTTP::Response; 1; },
    'Able to load HTTP::Response');

my $ele = _skip_it(eval {Geo::WebService::Elevation::USGS->new(
	    places => 2 )},
    'Unable to instantiate Geo::WebService::Elevation::USGS');

diag "Accessing @{[ $ele->get( 'usgs_url' ) ]}";

{
    my $ua = _skip_it(eval {LWP::UserAgent->new()},
	'Able to instantiate LWP::UserAgent');

    my $pxy = _skip_it(eval { $ele->USGS_URL() },
	'Able to retrieve USGS URL');

    my $rslt = _skip_it(eval {$ua->get($pxy)},
	'Able to execute GET');

    _skip_it( $rslt->is_success() || $rslt->code() == HTTP_BAD_REQUEST,
	"Able to access $pxy", $rslt->status_line() );
}

#x# my $ele_dataset = 'Elev_DC_Washington';	# Expected data set
#y# my $ele_dataset = 'NED 1/3 arc-second';	# Expected data set
# my $ele_dataset = '3DEP 1/3 arc-second';	# Expected data set
my $ele_re = qr{ \A Elev_DC }smx;	# Regexp for data set
#x# my $ele_ft = '57.03';	# expected elevation in feet.
#x# my $ele_ft = '56.95';	# expected elevation in feet.
# my $ele_ft = '56.53';	# expected elevation in feet.
my $ele_ft = '56.59';	# expected elevation in feet.
my @ele_loc = ( 38.898748, -77.037684 );	# Lat/Lon to get elevation for
#x# my $ele_mt = '17.38';	# Expected elevation in meters.
#x# my $ele_mt = '17.36';	# Expected elevation in meters.
# my $ele_mt = '17.23';	# Expected elevation in meters.
# my $ele_mt = '17.25';	# Expected elevation in meters.
my $ele_mt = 0 + sprintf '%.2f', $ele_ft * FEET_TO_METERS;

my $rslt;

SKIP: {
    $rslt = eval {$ele->elevation( @ele_loc )};
    _skip_on_server_error( $ele, 4 );
    ok(!$@, 'elevation() succeeded')
	or _skip_tests( 4 );
    is( ref $rslt, HASH_REF, 'elevation() returned a hash' )
	or skip 'elevation() did not return a hash', 2;
    tolerance( $rslt->{Elevation}, $ele_ft, TOLERANCE_FEET, 'Elevation' );
}

$ele->set(
    croak => 1,
    units => 'METERS'
);

SKIP: {
    $rslt = eval { [ $ele->elevation( @ele_loc ) ] };
    _skip_on_server_error( $ele, 6 );
    ok(!$@, 'elevation() succeeded in list context')
	or _skip_tests( 5 );
    is(ref $rslt, ARRAY_REF, 'elevation() returns an array in list context')
	or skip 'elevation() did not return an array reference', 4;
    cmp_ok(scalar @$rslt, '==', 1, 'elevation() returned a single result')
	or skip 'elevation() did not return a single-element array', 3;
    is(ref ($rslt->[0]), HASH_REF, 'elevation\'s only result was a hash')
	or skip 'elevation() did not return an array of hashes', 2;
    tolerance( $rslt->[0]{Elevation}, $ele_mt, TOLERANCE_METERS, 'Elevation' );
}

my $gp = bless [ @ele_loc ], 'Geo::Point';

SKIP: {
    $rslt = eval { $ele->elevation( @ele_loc ) };
    _skip_on_server_error( $ele, 4 );
    ok(!$@, 'elevation() succeeded')
	or _skip_tests( 3 );
    is( ref $rslt, HASH_REF, 'elevation() returned a hash' )
	or skip 'elevation() did not return a hash', 2;
    tolerance( $rslt->{Elevation}, $ele_mt, TOLERANCE_METERS, 'Elevation' );
}

SKIP: {
    my $kind;
    if ( eval { require GPS::Point; 1 } ) {
	$gp = GPS::Point->new();
	$gp->lat( $ele_loc[0] );
	$gp->lon( $ele_loc[1] );
	$gp->alt(undef);
	$kind = 'Real GPS::Point';
    } else {
	$gp = bless [ @ele_loc ], 'GPS::Point';
	no warnings qw{once};
	*GPS::Point::latlon = \&Geo::Point::latlong;
	$kind = 'Dummy GPS::Point';
    }

    $rslt = eval {$ele->elevation($gp)};
    _skip_on_server_error( $ele, 4 );
    ok(!$@, "elevation($kind) succeeded")
	or _skip_tests( 3 );
    is( ref $rslt, HASH_REF, "elevation($kind) returns a hash")
	or skip 'elevation() did not return a hash', 2;
    tolerance( $rslt->{Elevation}, $ele_mt, TOLERANCE_METERS, "$kind elevation" );
}

_skip_on_server_summary();

done_testing();

{
    my $json;
    sub _make_resp {
	my ( $content, $code ) = @_;
	$json ||= JSON->new()->utf8()->allow_nonref();
	defined $code
	    or $code = HTTP_OK;
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
    my ( $check, $reason, @diag ) = @args;
    if ( $ENV{AUTHOR_TESTING} ) {
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	unless ( ok $check, $reason ) {
	    diag @diag;
	    done_testing;
	    exit;
	}
    } elsif ( ! $check ) {
	plan skip_all => @diag ? "$reason: @diag" : $reason;
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

# NOTE that on January 18 2025 I experienced sporadic test failures.
# Direct queries of the web interface showed that I could indeed get
# different results for the same query. I found the documentation
# unhelpful, so I just installed a 6-inch tolerance.
sub tolerance {
    my ( $got, $want, $tolerance, $name ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $limit = $want + $tolerance;
    my $ok = cmp_ok( $got, '<=', $limit, "$name <= $limit" );
    $limit = $want - $tolerance;
    cmp_ok( $got, '>=', $limit, "$name >= $limit" )
	or $ok = 0;
    return $ok;
}

sub Geo::Point::latlong {
    return ( @{ $_[0] } )
}

1;
