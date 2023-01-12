use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib './lib'; # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

lives_ok {
    my $geocoder = Geo::Coder::OpenCage->new(api_key => "abcde");
    ok $geocoder, 'created geocoder object with dummy api key';
}
'new() lived with api key';

dies_ok {
    my $geocoder = Geo::Coder::OpenCage->new();
}
'exception thrown when no api key passed to new()';


# make sure we didn't forget to update version
{
    my $geocoder = Geo::Coder::OpenCage->new(api_key => "abcde");
    my $v        = $geocoder->{ua}->agent;
    $v =~ s/Geo::Coder::OpenCage //;
    is($v > 0.33, 1, 'version number greater than 0.33');
}

done_testing();
