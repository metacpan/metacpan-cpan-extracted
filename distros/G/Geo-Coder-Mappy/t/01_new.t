use strict;
use warnings;
use Test::More;
use Geo::Coder::Mappy;

new_ok('Geo::Coder::Mappy' => [ 'Your Mappy AJAX API token', ]);
new_ok('Geo::Coder::Mappy' => [ token => 'Your Mappy AJAX API token', ]);
{
    local $@;
    eval {
        my $geocoder = Geo::Coder::Mappy->new(debug => 1);
    };
    like($@, qr/^'token' is required/, 'token is required');
}

can_ok('Geo::Coder::Mappy', qw(geocode response ua));

done_testing;
