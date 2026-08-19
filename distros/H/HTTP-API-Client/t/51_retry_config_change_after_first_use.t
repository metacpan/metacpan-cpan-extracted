=head1 NAME

51_retry_config_change_after_first_use.t - HAC-068: same bug class as
HAC-066 (ua/browser_id/timeout/ssl_verify) and HAC-067 (json/charset) -
retry is lazy and memoized from _build_retry, built once from whatever
retry_config was at the time send() first ran. Changing retry_config
after that first call was a silent no-op: send() kept using the stale
memoized retry count/delay/status on every later call. send() now
recomputes retry fresh from the current retry_config on every call.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use HTTP::API::Client;
use FakeUA;

my $api = HTTP::API::Client->new(
    base_url     => "http://example.com",
    retry_config => { fail_response => 0, fail_status => '', delay => 0 },
);

$api->ua( FakeUA->new(500) );
$api->get("/first");    # forces retry's lazy build with fail_response => 0 (1 attempt)

is $api->ua->{calls}, 1, "0 configured retries makes exactly 1 attempt";

$api->retry_config( { fail_response => 2, fail_status => '', delay => 0 } );
$api->ua( FakeUA->new(500) );
$api->get("/second");

is $api->ua->{calls}, 3,
    "retry_config changed to 2 retries after first use makes 3 attempts on the next call, not still 1";

done_testing;
