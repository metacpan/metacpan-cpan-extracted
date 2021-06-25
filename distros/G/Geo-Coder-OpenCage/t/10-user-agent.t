use strict;
use warnings;
use utf8;
use Net::Ping;
use Test::More;
use Test::Warn;
use LWP::UserAgent;
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

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

    my $user_agent = LWP::UserAgent->new();

    # use special key OpenCage makes available for testing
    # https://opencagedata.com/api#testingkeys
    my $api_key = '6d0e711d72d74daeb2b0bfd2a5cdfdba';

    my $geocoder = Geo::Coder::OpenCage->new(api_key => $api_key, ua => $user_agent);
    my $result = $geocoder->reverse_geocode('lat' => 1, 'lng' => 2);
    is($result->{status}->{code}, 200, 'got http 200 status');
}

done_testing();

