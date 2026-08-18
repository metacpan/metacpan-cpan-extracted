=head1 NAME

11_retry_fail_status.t - regression tests for HAC-009: RETRY_FAIL_STATUS
must retry without crashing when the response status code matches, and
must not retry when it doesn't

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
    local $ENV{RETRY_FAIL_STATUS}   = 500;
    local $ENV{RETRY_DELAY}         = 0;

    my $api = HTTP::API::Client->new;
    my $ua  = FakeUA->new(500);
    $api->ua($ua);

    my $ok = eval { $api->get("http://x/"); 1 };
    ok $ok, "RETRY_FAIL_STATUS matching the response code does not crash (error: " . ($@ // '') . ")";
    is $ua->{calls}, 2, "it retried once (2 calls total) when the status code matched";
}

{
    local $ENV{RETRY_FAIL_RESPONSE} = 1;
    local $ENV{RETRY_FAIL_STATUS}   = 500;
    local $ENV{RETRY_DELAY}         = 0;

    my $api = HTTP::API::Client->new;
    my $ua  = FakeUA->new(404);
    $api->ua($ua);

    $api->get("http://x/");
    is $ua->{calls}, 1, "no retry when the response code (404) is not in RETRY_FAIL_STATUS (500)";
}

done_testing;
