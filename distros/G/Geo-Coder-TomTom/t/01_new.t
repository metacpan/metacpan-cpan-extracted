use strict;
use warnings;
use Test::More;
use Geo::Coder::TomTom;

new_ok('Geo::Coder::TomTom' => ['Your API key']);
new_ok('Geo::Coder::TomTom' => ['Your API key', debug => 1]);
new_ok('Geo::Coder::TomTom' => [apikey => 'Your API key']);
new_ok('Geo::Coder::TomTom' => [apikey => 'Your API key', debug => 1]);

{
    local $@;
    eval {
        my $geocoder = Geo::Coder::TomTom->new(debug => 1);
    };
    like($@, qr/^'apikey' is required/, 'apikey is required');
}

can_ok('Geo::Coder::TomTom', qw(geocode response ua));

done_testing;
