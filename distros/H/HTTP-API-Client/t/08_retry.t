=head1 NAME

08_retry.t - regression tests for HAC-006: send() must not sleep
RETRY_DELAY when no retry attempt is left (the default, RETRY_FAIL_RESPONSE=0),
but must still sleep/retry once when a real retry is configured

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use HTTP::API::Client;
use FakeUA;

{
    local $ENV{RETRY_FAIL_RESPONSE} = 0;
    local $ENV{RETRY_DELAY}         = 5;

    my $api = HTTP::API::Client->new;
    $api->ua(FakeUA->new(500));

    my $t0 = time;
    $api->get("http://x/");
    my $elapsed = time - $t0;

    ok $elapsed < 2, "no retries configured (default) - no sleep on a failed request (elapsed=$elapsed)";
}

{
    local $ENV{RETRY_FAIL_RESPONSE} = 1;
    local $ENV{RETRY_DELAY}         = 1;

    my $api = HTTP::API::Client->new;
    $api->ua(FakeUA->new(500));

    my $t0 = time;
    $api->get("http://x/");
    my $elapsed = time - $t0;

    ok $elapsed >= 1 && $elapsed < 3, "one retry configured - sleeps roughly one RETRY_DELAY, not zero and not two (elapsed=$elapsed)";
}

done_testing;
