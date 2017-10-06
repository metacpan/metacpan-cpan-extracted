use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib './lib';  # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

lives_ok {
    my $Geocoder = Geo::Coder::OpenCage->new(
        api_key => "abcde"
    );
    ok $Geocoder, 'created geocoder object with dummy api key';
} 'new() lived with api key';

dies_ok {
    my $Geocoder = Geo::Coder::OpenCage->new();
} 'exception thrown when no api key passed to new()';

done_testing();
