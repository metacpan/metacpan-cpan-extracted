=head1 NAME

24_retry_fail_status_whitespace.t - HAC-027: RETRY_FAIL_STATUS with a
comma-space separator (e.g. "500, 404") must retry on every listed status,
not just the first - _build_retry's split didn't trim whitespace, so a
status after a space-separated comma never matched $response->code

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use HTTP::API::Client;
use FakeUA;

{
    local $ENV{RETRY_FAIL_RESPONSE} = 1;
    local $ENV{RETRY_FAIL_STATUS}   = "500, 404";
    local $ENV{RETRY_DELAY}         = 0;

    my $api = HTTP::API::Client->new;
    my $ua  = FakeUA->new(404);
    $api->ua($ua);

    $api->get("http://x/");
    is $ua->{calls}, 2,
        "RETRY_FAIL_STATUS='500, 404' (comma-space) retries on 404 too, not just 500";
}

done_testing;
