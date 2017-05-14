use Test::More tests => 6;

use Forecast::IO;
use Term::ReadKey;
use strict;
use warnings;

my $lat  = 43.6667;
my $long = -79.4167;
my $time = 1373241600;
diag("Please enter your Forecast.io API key: ");
my $key = ReadLine(0);
chomp $key;
my $forecast = Forecast::IO->new(
    key       => $key,
    longitude => $long,
    latitude  => $lat,
    'time'    => $time
);

is( sprintf( "%.4f", $forecast->{latitude} ),  $lat );
is( sprintf( "%.4f", $forecast->{longitude} ), $long );
is( $forecast->{currently}->{'time'}, $time );
ok( exists( $forecast->{daily}->{data} ) );
ok( exists( $forecast->{hourly}->{data} ) );
ok( exists( $forecast->{currently}->{summary} ) );
