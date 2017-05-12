package main;

use 5.006002;

use strict;
use warnings;

use Geo::Coder::Geocoder::US;
use LWP::UserAgent;
use Test::More 0.88;

{
    my $ua = LWP::UserAgent->new();
    my $resp = $ua->get( Geo::Coder::Geocoder::US->BASE_URL );
    $resp
	and $resp->is_success()
	or do {
	    plan skip_all => join ' ',
		Geo::Coder::Geocoder::US->BASE_URL, 'not reachable:',
		$resp->status_line();
	    exit;
	};
}

my $wh_lat = 38.898748;
my $wh_lon = -77.037684;

my $gc = Geo::Coder::Geocoder::US->new();

=begin comment

diag 'This test should take about 30 seconds';

is $gc->interface(), 'namedcsv', q{Default interface is 'namedcsv'};

ok $gc->interface( 'csv' ), q{Set the interface to 'csv'};

is $gc->interface(), 'csv', q{Confirm interface set to 'csv'};

is_deeply [
    $gc->geocode(
	location => '1600 Pennsylvania Ave, Washington DC',
    ), 
], [
    {
	address	=> '1600 Pennsylvania Ave NW',
	city	=> 'Washington',
	lat	=> $wh_lat,
	long	=> $wh_lon,
	state	=> 'DC',
	zip	=> 20502,
    }
], q{Geocode the White House using the 'csv' interface};

ok $gc->interface( 'namedcsv' ), q{Set the interface to 'namedcsv'};

is $gc->interface(), 'namedcsv', q{Confirm interface set to 'namedcsv'};

=end comment

=cut

is_deeply [ $gc->geocode(
	location => '1600 Pennsylvania Ave, Washington DC',
    ),
], [
    {
	city	=> 'Washington',
	lat	=> $wh_lat,
	long	=> $wh_lon,
	number	=> '1600',
	prefix	=> '',
	state	=> 'DC',
	street	=> 'Pennsylvania',
	suffix	=> 'NW',
	type	=> 'Ave',
	zip	=> 20502,
    }
], q{Geocode the White House using the 'namedcsv' interface};

=begin comment

SKIP: {

    eval { require XML::Parser; 1; }
	or skip 'Unable to load XML::Parser', 3;

    ok $gc->interface( 'rest' ), q{Set the interface to 'rest'};

    is $gc->interface(), 'rest', q{Confirm interface set to 'rest'};

    is_deeply [ $gc->geocode(
	    location => '1600 Pennsylvania Ave, Washington DC',
	),
    ], [
	{
	    description	=> '1600 Pennsylvania Ave NW, Washington DC 20502',
	    lat	=> 	$wh_lat,
	    long	=> $wh_lon,
	}
    ], q{Geocode the White House using the 'rest' interface};

}

=end comment

=cut

done_testing;

1;

# ex: set textwidth=72 :
