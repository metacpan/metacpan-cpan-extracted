=head1 NAME

21_before_events.t - coverage for before_headers and
before_sorting_keys/after_sorting_keys, none of which had a test before
(t/04_callbacks.t's own NAME section claimed to cover before_headers but
never actually called it)

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new;
    my $fired = 0;
    my $req = $api->get( "http://example.com", {}, { A => "1" }, {
        test_request_object => 1,
        before_headers      => sub { $fired = 1 },
    } );

    ok $fired, "before_headers fires";
    is $req->header("A"), "1", "header processing still completes normally";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my @order;
    my $req = $api->get( "http://example.com", { b => 1, a => 2 }, {}, {
        test_request_object => 1,
        before_sorting_keys => sub { push @order, "before" },
        after_sorting_keys  => sub { push @order, "after" },
    } );

    is_deeply \@order, [ "before", "after" ],
        "before_sorting_keys fires, then after_sorting_keys fires";
    is $req->uri, "http://example.com?a=2&b=1", "key sorting still happens normally";
}

done_testing;
