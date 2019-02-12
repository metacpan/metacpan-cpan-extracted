use strict;
use warnings;
use utf8;
use Test::More;
use Test::Warn;

binmode Test::More->builder->output,         ":encoding(utf8)";
binmode Test::More->builder->failure_output, ":encoding(utf8)";
binmode Test::More->builder->todo_output,    ":encoding(utf8)";

use lib './lib';  # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

# use special key OpenCage makes available for testing
my $api_key = '2e10e5e828262eb243ec0b54681d699a';

my $geocoder = Geo::Coder::OpenCage->new(
    api_key => $api_key,
);

{
    my $result;
    warning_like
        { $result = $geocoder->reverse_geocode('lat'=> 41.40139, 'lng'=> 2.12870); }
        [ qr/403, suspended/ ],
        " got suspended warning ";
    is($result, undef, 'correctly returned undef for 403 response');
}

done_testing();

