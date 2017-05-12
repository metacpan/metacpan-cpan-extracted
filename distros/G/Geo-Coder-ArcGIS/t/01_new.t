use strict;
use warnings;
use Test::More;
use Geo::Coder::ArcGIS;

new_ok('Geo::Coder::ArcGIS' => []);
new_ok('Geo::Coder::ArcGIS' => [debug => 1]);

can_ok('Geo::Coder::ArcGIS', qw(geocode response ua));

done_testing;
