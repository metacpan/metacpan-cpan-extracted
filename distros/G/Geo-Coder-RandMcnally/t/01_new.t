use strict;
use warnings;
use Test::More tests => 3;
use Geo::Coder::RandMcnally;

new_ok('Geo::Coder::RandMcnally' => []);
new_ok('Geo::Coder::RandMcnally' => [debug => 1]);

can_ok('Geo::Coder::RandMcnally', qw(geocode response ua));
