=head1 NAME

95_headers_keys_duplicate_dedup.t - HAC-130: new_request()'s headers_keys
callback (a full override of which header keys to consider, similar to
kvp2json's/kvp2str's events->{keys}) had no deduplication of its return
value - unlike the sibling add_headers_keys path, which explicitly dedupes
(HAC-022/t/22). A duplicate key returned by headers_keys silently
double-fired before_header/after_header for that key. Same bug class as
HAC-129 (kvp2json/kvp2str's events->{keys}), just in new_request's
header-key handling instead. Live-verified before this fix: a
before_header callback that increments a counter fired twice for a
headers_keys-supplied duplicate key.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $count = 0;
    my $api   = HTTP::API::Client->new;

    my $req = $api->send(
        GET => "http://x/", {}, { "X-Test" => "1" },
        {
            headers_keys  => sub { return ( "X-Test", "X-Test" ) },
            before_header => { "X-Test" => sub { $count++; return "value-$count" } },
            test_request_object => 1,
        },
    );

    is $count, 1, "before_header fires exactly once despite a duplicate key from headers_keys";
    is $req->header("X-Test"), "value-1", "the header reflects a single invocation";
}

{
    # order-preservation must survive the dedup - headers_keys controls
    # order, and the fix must not silently start sorting it. Tracked via
    # after_header invocation order, not HTTP::Headers::scan (which has
    # its own internal ordering, unrelated to insertion order).
    my @order;
    my $api = HTTP::API::Client->new;

    $api->send(
        GET => "http://x/", {},
        { "X-C" => "3", "X-A" => "1", "X-B" => "2" },
        {
            headers_keys => sub { return ( "X-C", "X-A", "X-C", "X-B" ) },
            after_header => { map { my $k = $_; $k => sub { push @order, $k } } qw( X-A X-B X-C ) },
            test_request_object => 1,
        },
    );

    is_deeply \@order, [ "X-C", "X-A", "X-B" ],
        "deduplication preserves first-occurrence order from headers_keys, not sorted order";
}

done_testing;
