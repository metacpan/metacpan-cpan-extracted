use strict;
use warnings;

# update with test count
use Test::More qw( no_plan );
use Test::Exception;

# distance and duration values shift widely
use Test::Number::Delta within => 1000;
use Data::Dumper qw( Dumper );

use Geo::Distance::Google;

{
    my $geo = Geo::Distance::Google->new;
    my $distance = $geo->distance( 
        # sears tower... wacker tower whatever
        origins      => '233 S. Wacker Drive Chicago, Illinois 60606',
        destinations => '1600 Amphitheatre Parkway, Mountain View, CA'
    );

    is $distance->[0]->{destinations}->[0]->{distance}->{text},  '3,482 km', 'distance text';
    delta_ok $distance->[0]->{destinations}->[0]->{distance}->{value}, 3482426, 
        'distance value';

    is $distance->[0]->{destinations}->[0]->{duration}->{text},  '1 day 10 hours', 'duration text';
    delta_ok $distance->[0]->{destinations}->[0]->{duration}->{value}, 122354, 
        'duration value';
}

# test complex look ups
{
    my $geo = Geo::Distance::Google->new;

    my $d = $geo->distance( 
        # sears tower... wacker tower whatever
        origins      => [ 
            'One MetLife Stadium Drive, East Rutherford, New Jersey 07073, United States',
            '602 Jamestown Avenue, San Francisco, California 94124'
        ],
        destinations => '1265 Lombardi Avenue, Green Bay, Wisconsin 54304'
    );

    print Dumper( $d ), "\n";

    # from giants to packers
    is $d->[0]->{destinations}->[0]->{distance}->{text}, '1,587 km', 'distance complex origins';
    # from 49ers to packers
    is $d->[1]->{destinations}->[0]->{distance}->{text}, '3,616 km', 'distance complex origins';

}

TODO: {
    local $TODO = "imperial tests";
}

# except error conditions
{
    my $distance;
    my $geo;

    $geo = Geo::Distance::Google->new;

    throws_ok { $distance = $geo->distance; } qr/Mandatory parameters/, 'parameter check';

    $geo = Geo::Distance::Google->new( host => 'example.com' );

    throws_ok { 
        $distance = $geo->distance( 
            origins      => '123 Main St., Waukesha, WI',
            destinations => '1 Brewers Way  Milwaukee, Wisconsin 53214'
        );
    } qr/Invalid content-type/, 'Invalid content-type';
}

# URL signing
SKIP: {
    skip "Update to support google business keys", 2; 

    # sample clientID from http://code.google.com/apis/maps/documentation/webservices/index.html#URLSigning
    my $client = $ENV{GMAP_CLIENT};
    my $key    = $ENV{GMAP_KEY};
    my $geocoder = Geo::Distance::Google->new( client => $client, key => $key );
    my $location = $geocoder->distance(origins => 'New York', destinations => 'Chicago, IL');
    delta_ok($location->{geometry}{location}{lat}, 40.7143528, 'Latitude for NYC');
    delta_ok($location->{geometry}{location}{lng}, -74.0059731, 'Longitude for NYC');
}
