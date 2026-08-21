=head1 NAME

92_kvp_response_empty_content.t - HAC-127: kvp_response()'s
'my $content = $response->decoded_content or return {};' guard was untested
- t/09_kvp_response.t only covers the EARLIER guard (no request made yet,
last_response itself undef). The "a real response exists, but its body is
empty" case had no direct test. Live-verified before this test existed:
the behavior is already correct, this closes a coverage gap, not a defect.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

{
    my $api = HTTP::API::Client->new;
    my $response = HTTP::Response->new(200);
    $response->content('');
    $api->last_response($response);

    is_deeply $api->kvp_response, {},
        "kvp_response() returns {} for a real response with an empty body, not a crash or bogus data";
}

done_testing;
