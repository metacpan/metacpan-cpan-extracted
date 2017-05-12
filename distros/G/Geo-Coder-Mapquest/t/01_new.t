use strict;
use warnings;
use Test::More tests => 7;
use Geo::Coder::Mapquest;

new_ok('Geo::Coder::Mapquest' => ['Your API key']);
new_ok('Geo::Coder::Mapquest' => ['Your API key', debug => 1]);
new_ok('Geo::Coder::Mapquest' => [apikey => 'Your API key']);
new_ok('Geo::Coder::Mapquest' => [apikey => 'Your API key', debug => 1]);

{
    local $@;
    eval {
        my $geocoder = Geo::Coder::Mapquest->new(debug => 1);
    };
    like($@, qr/^'apikey' is required/, 'apikey is required');

    my $ua = LWP::UserAgent->new(protocols_forbidden => ['https']);
    my $geocoder = eval {
        Geo::Coder::Mapquest->new(
            apikey => 'Your API key',
            https  => 1,
            ua     => $ua,
        );
    };
    like($@, qr/^'https' requires/, 'https fails w/o an SSL module');
}

can_ok('Geo::Coder::Mapquest', qw(geocode batch response ua));
