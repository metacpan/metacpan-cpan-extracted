use strict;
use warnings;
use utf8;
use Net::Ping;
use Test::More;
use Test::Warn;

binmode Test::More->builder->output,         ":encoding(utf8)";
binmode Test::More->builder->failure_output, ":encoding(utf8)";
binmode Test::More->builder->todo_output,    ":encoding(utf8)";

use lib './lib'; # actually use the module, not other versions installed
use Geo::Coder::OpenCage;

# TODO should move this into module to share with other tests
my $api_ip_num      = '95.216.176.62';
my $p               = Net::Ping->new;
my $have_connection = 0;
if ($p->ping($api_ip_num, 1)) {
    $have_connection = 1;
}

SKIP: {
    skip 'skipping test that requires connectivity', 2 unless ($have_connection);

    # use special key OpenCage makes available for testing
    my $api_key = '4372eff77b8343cebfc843eb4da4ddc4';


    my $geocoder = Geo::Coder::OpenCage->new(api_key => $api_key,);

    {
        my $result;
        warning_like { $result = $geocoder->reverse_geocode('lat' => 41.40139, 'lng' => 2.12870); }
        [qr/402, quota exceeded/], "got quota exceeded warning";

        is($result, undef, 'correctly returned undef for 402 response');

    }
}

done_testing();
