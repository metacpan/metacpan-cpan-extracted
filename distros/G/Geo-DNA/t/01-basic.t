use Test::More tests => 14;

use common::sense;

BEGIN { use_ok( 'Geo::DNA' ) }

sub value_is_near {
    my ( $value, $comparator, $error ) = @_;
    $error ||= 0.005;
    return ( abs($comparator - $value) < $error );
}

use Geo::DNA qw(
    encode_geo_dna
    decode_geo_dna
    neighbours_geo_dna
    bounding_box_geo_dna
);

my $wellington = encode_geo_dna( -41.288889, 174.777222, precision => 22 );
ok( $wellington eq 'etctttagatagtgacagtcta', "Wellington's DNA is correct" );

my ($lat, $lon) = decode_geo_dna( $wellington );

ok( value_is_near( $lat, -41.288889 ), "Latitude converted back correctly." );
ok( value_is_near( $lon, 174.777222 ), "Longitude converted back correctly." );

my $nelson = encode_geo_dna( -41.283333, 173.283333, precision => 16 );
ok( $nelson eq 'etcttgctagcttagt', "Nelson's DNA is correct" );

($lat, $lon) = decode_geo_dna( $nelson );
ok( value_is_near( $lat, -41.283333, 0.5 ), "Latitude converted back correctly." );
ok( value_is_near( $lon, 173.283333, 0.5 ), "Longitude converted back correctly." );

my $geo = encode_geo_dna( 7.0625, -95.677068 );
ok( $geo eq 'watttatcttttgctacgaagt', "Encoded successfully" );

my ( $new_lat, $new_lon ) = Geo::DNA::add_vector( $wellington, 10.0, 10.0 );
ok( value_is_near( $new_lat, -31.288889 ), "New latitude is good" );
ok( value_is_near( $new_lon, -175.222777 ), "New longitude is good" );

my $neighbours = neighbours_geo_dna( 'etctttagatag' );
ok( $neighbours && scalar @$neighbours == 8, "Got back correct neighbours" );

my ( $lati, $loni ) = bounding_box_geo_dna( 'etctttagatag' );

is_deeply( [ $lati, $loni ],
           [ [ '-41.30859375', '-41.220703125' ],
             [ '174.7265625', '174.814453125' ]
           ], "Bounding box" );

my $distance = Geo::DNA::distance_in_km( $wellington, $nelson );
ok( $distance > 120.0 && $distance < 140.0, "Nelson is about 130km from Wellington" );

$neighbours = Geo::DNA::reduce( Geo::DNA::neighbours_within_radius( $nelson, 140.0, precision => 11 ) );

my $found = 0;
foreach my $n (@$neighbours) {
   if ( $wellington =~ /^$n/ ) {
       $found = 1;
   }
}
ok( $found, "Found Wellington in proximity to Nelson." );

