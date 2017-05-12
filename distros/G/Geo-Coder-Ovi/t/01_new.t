use strict;
use warnings;
use Test::More;
use Geo::Coder::Ovi;

new_ok('Geo::Coder::Ovi' => []);
new_ok('Geo::Coder::Ovi' => [debug => 1]);

can_ok('Geo::Coder::Ovi', qw(geocode response ua));

done_testing;
