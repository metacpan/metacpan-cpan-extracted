use strict;
use warnings;
use utf8;
use Test::More;
use Test::Warn;
use LWP::UserAgent;

binmode Test::More->builder->output,         ":encoding(utf8)";
binmode Test::More->builder->failure_output, ":encoding(utf8)";
binmode Test::More->builder->todo_output,    ":encoding(utf8)";

use lib './lib';   # actually use the module, not other versions installed
use lib './t/lib'; # shared test helpers
use Geo::Coder::OpenCage;
use TestConnectivity;

# Verify the UA string format documented in the pod: "Geo::Coder::OpenCage/$VERSION"
{
    my $geocoder = Geo::Coder::OpenCage->new(api_key => 'dummy');
    like(
        $geocoder->ua->agent,
        qr{^Geo::Coder::OpenCage/\S+$},
        'default HTTP::Tiny UA has agent "Geo::Coder::OpenCage/<version>"',
    );

    my $lwp = LWP::UserAgent->new;
    $geocoder->ua($lwp);
    like(
        $lwp->agent,
        qr{^Geo::Coder::OpenCage/\S+$},
        'caller-supplied UA gets agent "Geo::Coder::OpenCage/<version>" via ua() setter',
    );

    my $lwp_via_new = LWP::UserAgent->new;
    my $geocoder2 = Geo::Coder::OpenCage->new(api_key => 'dummy', ua => $lwp_via_new);
    like(
        $lwp_via_new->agent,
        qr{^Geo::Coder::OpenCage/\S+$},
        'caller-supplied UA gets agent "Geo::Coder::OpenCage/<version>" when passed via new()',
    );
}

SKIP: {
    skip 'skipping test that requires connectivity', 2
        unless TestConnectivity::have_connection();

    my $user_agent = LWP::UserAgent->new();

    # use special key OpenCage makes available for testing
    # https://opencagedata.com/api#testingkeys
    my $api_key = '6d0e711d72d74daeb2b0bfd2a5cdfdba';

    my $geocoder = Geo::Coder::OpenCage->new(api_key => $api_key, ua => $user_agent);
    my $result = $geocoder->reverse_geocode('lat' => 1, 'lng' => 2);
    is($result->{status}->{code}, 200, 'got http 200 status');
}

done_testing();

