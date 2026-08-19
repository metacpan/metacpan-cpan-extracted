=head1 NAME

49_rw_attrs_after_first_use.t - HAC-066: browser_id/timeout/ssl_verify are
documented as plain read-write attributes, but ua is lazy and memoized -
built once, on first use, from whatever those attributes were at the
time. Changing any of them after the first request was a silent no-op:
the underlying LWP::UserAgent's agent/timeout/ssl_opts never updated,
with no error or warning. send() now re-applies all three to the
existing ua object on every call, so a change made between calls takes
effect on the next one.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( base_url => "http://example.com" );

    $api->get( "/first", {}, {}, { test_request_object => 1 } );

    $api->timeout(999);
    $api->browser_id("changed-agent");
    $api->ssl_verify(1);

    $api->get( "/second", {}, {}, { test_request_object => 1 } );

    is $api->ua->timeout, 999, "timeout changed after first use takes effect on the next call";
    is $api->ua->agent, "changed-agent", "browser_id changed after first use takes effect on the next call";
    is $api->ua->ssl_opts("verify_hostname"), 1,
        "ssl_verify changed after first use takes effect on the next call";
}

done_testing;
