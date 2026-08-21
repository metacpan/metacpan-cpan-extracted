=head1 NAME

94_events_keys_duplicate_dedup.t - HAC-129: kvp2json's and kvp2str's
events->{keys} callback (which replaces @keys outright, controlling which
keys are included and in what order per the POD) had no deduplication of
its return value - unlike new_request()'s add_headers_keys path, which
explicitly dedupes (HAC-022/t/22). A duplicate key returned by
events->{keys} caused a CODE-ref value at that key to be invoked once per
occurrence instead of once, with side effects firing multiple times and
(for kvp2str specifically) a genuinely malformed doubled-key output
string ("a=computed-1&a=computed-2") rather than an intentional
multi-value array. Live-verified before this fix: both encoders exhibited
this.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $count = 0;
    my $api   = HTTP::API::Client->new;
    my $data  = { a => sub { $count++; return "computed-$count" } };

    my $json = $api->kvp2json(
        data   => $data,
        events => { keys => sub { return ( "a", "a" ) } },
    );

    is $count, 1, "kvp2json invokes the per-key callback exactly once despite a duplicate key from events->{keys}";
    is $json, '{"a":"computed-1"}', "kvp2json's output reflects a single invocation";
}

{
    my $count = 0;
    my $api   = HTTP::API::Client->new;
    my $data  = { a => sub { $count++; return "computed-$count" } };

    my $str = $api->kvp2str(
        data   => $data,
        events => { keys => sub { return ( "a", "a" ) } },
    );

    is $count, 1, "kvp2str invokes the per-key callback exactly once despite a duplicate key from events->{keys}";
    is $str, "a=computed-1", "kvp2str's output is not a malformed doubled-key string";
}

{
    # order-preservation must survive the dedup - events->{keys} controls
    # order, and the fix must not silently start sorting it.
    my $api  = HTTP::API::Client->new;
    my $data = { a => 1, b => 2, c => 3 };

    my $str = $api->kvp2str(
        data   => $data,
        events => { keys => sub { return ( "c", "a", "c", "b" ) } },
    );

    is $str, "c=3&a=1&b=2",
        "deduplication preserves first-occurrence order from events->{keys}, not sorted order";
}

done_testing;
