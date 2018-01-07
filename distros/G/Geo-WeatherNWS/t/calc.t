#!perl -T

use strict;
use warnings;
use Test::More tests => 45;
use Geo::WeatherNWS;

# Test the supporting calculations

# Rounding

is( Geo::WeatherNWS::round(1.49),  1,  'round 1.49' );
is( Geo::WeatherNWS::round(1.5),   2,  'round 1.5 does round half to even' );
is( Geo::WeatherNWS::round(1.51),  2,  'round 1.51' );
is( Geo::WeatherNWS::round(2.49),  2,  'round 2.49' );
is( Geo::WeatherNWS::round(2.5),   2,  'round 2.5 does round half to even' );
is( Geo::WeatherNWS::round(2.51),  3,  'round 2.51' );
is( Geo::WeatherNWS::round(-3.49), -3, 'round 1.49' );
is( Geo::WeatherNWS::round(-3.5),  -4, 'round -3.5 does round half to even' );
is( Geo::WeatherNWS::round(-3.51), -4, 'round -3.51' );
is( Geo::WeatherNWS::round(undef), undef, 'round undef' );

# Fahrenheit to Celsius

is( Geo::WeatherNWS::convert_f_to_c(212),   100,   '212f -> c' );
is( Geo::WeatherNWS::convert_f_to_c(32),    0,     '32f -> c' );
is( Geo::WeatherNWS::convert_f_to_c(-40),   -40,   '-40f -> c' );
is( Geo::WeatherNWS::convert_f_to_c(undef), undef, 'undef f -> c' );

# Celsius to Fahrenheit

is( Geo::WeatherNWS::convert_c_to_f(100),   212,   '100c -> f' );
is( Geo::WeatherNWS::convert_c_to_f(0),     32,    '0c -> f' );
is( Geo::WeatherNWS::convert_c_to_f(-40),   -40,   '-40c -> f' );
is( Geo::WeatherNWS::convert_c_to_f(undef), undef, 'undef c -> f' );

# Windchill

is( Geo::WeatherNWS::windchill( 20, undef ), undef, 'undefined wind' );
is( Geo::WeatherNWS::windchill( 20, 0 ),
    undef, 'wind chill for 32 f, wind calm' );
is( Geo::WeatherNWS::round( Geo::WeatherNWS::windchill( 32, 10 ) ),
    24, 'wind chill for 32 f, wind 10 mph' );
is( Geo::WeatherNWS::round( Geo::WeatherNWS::windchill( 40, 20 ) ),
    30, 'wind chill for 40 f, wind 20 mph' );
is( Geo::WeatherNWS::round( Geo::WeatherNWS::windchill( 0, 30 ) ),
    -26, 'wind chill for 0 f, wind 30 mph' );

# Heat Index

is( Geo::WeatherNWS::round( Geo::WeatherNWS::heat_index( 80, 50 ) ),
    81, 'heat index 80F 50% rh' );
is( Geo::WeatherNWS::round( Geo::WeatherNWS::heat_index( 100, 60 ) ),
    129, 'heat index 100F 60% rh' );

# Wind Speed

is( Geo::WeatherNWS::convert_kts_to_mph(0), 0, 'mph for calm wind' );
is( Geo::WeatherNWS::round( Geo::WeatherNWS::convert_kts_to_mph(50) ),
    58, 'mph for 50 kts' );
is( Geo::WeatherNWS::round( Geo::WeatherNWS::convert_kts_to_kmh(50) ),
    93, 'kmh for 50 kts' );

# Distance

is( Geo::WeatherNWS::round( Geo::WeatherNWS::convert_miles_to_km(10) ),
    16, '10 miles to km' );

# Translate Present Weather into readable Conditions Text

my ($conditionstextA, $conditions1A, $conditions2A, $intensityA) = Geo::WeatherNWS::translate_weather("-TSRA");
is ($conditionstextA, 'Light Thunderstorm Rain', 'conditions text for -TSRA');
is ($conditions1A, 'Thunderstorm', 'condition1 for -TSRA');
is ($conditions2A, 'Rain', 'condition2 for -TSRA');
is ($intensityA, 'Light', 'intensity text for -TSRA');

my ($conditionstextB, $conditions1B, $conditions2B, $intensityB) = Geo::WeatherNWS::translate_weather("+FZFG");
is ($conditionstextB, 'Heavy Freezing Fog', 'conditions text for +FZFG');
is ($conditions1B, 'Freezing', 'condition1 for +FZFG');
is ($conditions2B, 'Fog', 'condition2 for +FZFG');
is ($intensityB, 'Heavy', 'intensity text for +FZFG');

my ($conditionstextC, $conditions1C, $conditions2C, $intensityC) = Geo::WeatherNWS::translate_weather("DRSN");
is ($conditionstextC, 'Low Drifting Snow', 'conditions text for DRSN');
is ($conditions1C, 'Low Drifting', 'condition1 for DRSN');
is ($conditions2C, 'Snow', 'condition2 for DRSN');
is ($intensityC, undef, 'intensity text for DRSN'); # moderate is undefined

my ($conditionstextD, $conditions1D, $conditions2D, $intensityD) = Geo::WeatherNWS::translate_weather("SHGR");
is ($conditionstextD, 'Shower Hail', 'conditions text for SHGR');
is ($conditions1D, 'Shower', 'condition1 for SHGR');
is ($conditions2D, 'Hail', 'condition2 for SHGR');
is ($intensityD, undef, 'intensity text for SHGR'); # moderate is undefined


