#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;
use Test::Mock::LWP::Dispatch;
use Cache::FastMmap;
use Digest::SHA qw/sha256_hex/;

BEGIN {
    use_ok( 'Google::Directions::Client' ) || print "Bail out!\n";
}

my %params = (
    origin      => "Theresienstr. 100, Munich, Germany",
    destination => "Nymphenburger Straße 31, Munich, Germany",
    waypoints	=> [ 'Schellingstr. 130, Munich, Germany', 'Winzererstr. 42, Munich, Germany' ],
    );


# Get the sample response
open( my $fh, '<', 'samples/response.json' ) or die( $! );
my $response_content;
while( my $line = readline( $fh ) ){
    $response_content .= $line;
}
close( $fh );

# Set the mock useragent to always respond with the response
$mock_ua->map(qr{.*}, sub {
    my $request = shift;
    my $response = HTTP::Response->new(200, 'OK');
    $response->add_content( $response_content );
    return $response;
});

# This will generate a temporary cache which will be removed on destroy
my $cache = Cache::FastMmap->new(
    num_pages	=> 3,	    # We are only storing one result...
    page_size	=> 32768,   # This is just big enough for the result
    );

# Test client with cache
my $client_with_cache = Google::Directions::Client->new(
    cache   => $cache,
    );

my $response = $client_with_cache->directions( %params );
ok( ! $response->cached, 'first response not cached' );
$response = $client_with_cache->directions( %params );
ok( $response->cached, 'second response to same query cached' );

# Test client without a cache
my $client_no_cache = Google::Directions::Client->new();
$response = $client_no_cache->directions( %params );
$response = $client_no_cache->directions( %params );
ok( ! $response->cached, 'not cached if cache not used' );

# Make sure we have found a route
my $first_route = $response->routes->[0];
ok( $first_route, 'has first route' );

# See if the sum of duration, distance and number of legs is right
my $duration = 0;
my $distance = 0;
my $leg_count = 0;
my $first_leg = undef;
foreach my $leg( @{ $first_route->legs } ){
    $first_leg ||= $leg;
    $leg_count++;
    $duration += $leg->duration;
    $distance += $leg->distance;
}
ok( $leg_count == 3, 'has expected number of legs' );
ok( $duration == 420, 'duration matches expected' );
ok( $distance == 2946, 'distance matches expected' );

# See if the addresses have been correctly transformed
ok( $first_leg->start_address eq 'Theresienstraße 100, 80333 Munich, Germany', 
    'start address transformed correctly' );
ok( $first_leg->end_address eq 'Schellingstraße 130, 80797 Munich, Germany',
    'end address transformed correctly' );

# Get the polyline and see if it's good
my $polyline = '';
foreach my $step ( @{ $first_leg->steps } ){
    foreach my $point( @{ $step->polyline->points  } ){
        $polyline .= sprintf "%f,%f\n", $point->lng, $point->lat; 
    }
}
# printf "SHA: %s\n", sha256_hex( $polyline );
ok( sha256_hex( $polyline ) eq 'de64d27aa7902b4c3b4b91a65a21b27188fb5779434c19a8ed6326ede281055b',
    'polyline ok' );
