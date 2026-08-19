=head1 NAME

76_get_query_string_already_has_question_mark.t - HAC-097: new_request()'s
GET branch takes a different code path to append encoded data depending on
whether the URL already contains a '?' ("$url&$content" vs "$url?$content").
Both were already correct - confirmed live before this test existed - but
Devel::Cover showed the '$url already has a ?' branch had a raw execution
count of 0 across the entire test suite: a coverage gap for existing,
already-correct behavior, not a defect (the same category HAC-039 closed for
json_response()'s no-prior-request case). This test closes that gap.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    my $req = $api->get(
        "http://example.com/search?existing=1",
        { q => "widgets" },
        {},
        { test_request_object => 1 },
    );

    is $req->uri, "http://example.com/search?existing=1&q=widgets",
        "a URL that already has a '?' gets new query data appended with '&', not a second '?'";
}

{
    my $req = $api->get(
        "http://example.com/search",
        { q => "widgets" },
        {},
        { test_request_object => 1 },
    );

    is $req->uri, "http://example.com/search?q=widgets",
        "a URL with no '?' yet still gets one added, unaffected by this fix";
}

done_testing;
