use strict;
use warnings;
use Test::More tests => 5;
use Geo::Coder::Navteq;

new_ok('Geo::Coder::Navteq' => ['placeholder appkey']);
new_ok('Geo::Coder::Navteq' => [ 'placeholder appkey', debug => 1 ]);
new_ok('Geo::Coder::Navteq' => [ appkey => 'placeholder appkey' ]);
new_ok('Geo::Coder::Navteq' => [
    appkey => 'placeholder appkey',
    debug  => 1
]);

can_ok('Geo::Coder::Navteq', qw(geocode response ua));
