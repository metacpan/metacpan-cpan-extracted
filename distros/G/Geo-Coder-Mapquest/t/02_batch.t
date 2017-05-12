use strict;
use warnings;
use Test::More tests => 1;
use Geo::Coder::Mapquest;

my $geocoder = Geo::Coder::Mapquest->new('You API key');
{
    local $@;
    eval {
        my @locations = $geocoder->batch([ (0..101) ]);
    };
    like($@, qr/^too many locations- limit is 100/, 'too many locations');
}
