=head1 NAME

67_retry_fail_status_empty_entry.t - HAC-086: RETRY_FAIL_STATUS (and the
equivalent retry_config->{fail_status}) with an empty or
whitespace-only entry (a doubled comma, a lone whitespace segment)
created a bogus '' key in the retry-status match set - split /,/ yields
an empty segment for it, and trimming whitespace from a whitespace-only
segment also leaves ''. Harmless in practice (a real HTTP status code is
never empty), but inconsistent with how this module now skips empty
segments elsewhere (kvp_response's HAC-075). Empty entries are now
skipped entirely rather than becoming a bogus key.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( retry_config => { fail_status => "500,,404" } );
    my $retry = $api->_build_retry;

    is_deeply $retry->{status}, { 500 => 1, 404 => 1 },
        "a doubled comma in fail_status doesn't create a bogus '' key";
}

{
    my $api = HTTP::API::Client->new( retry_config => { fail_status => "500, ,404" } );
    my $retry = $api->_build_retry;

    is_deeply $retry->{status}, { 500 => 1, 404 => 1 },
        "a whitespace-only entry in fail_status doesn't create a bogus '' key";
}

{
    my $api = HTTP::API::Client->new( retry_config => { fail_status => "500,404" } );
    my $retry = $api->_build_retry;

    is_deeply $retry->{status}, { 500 => 1, 404 => 1 },
        "normal comma-separated status codes are unaffected";
}

done_testing;
