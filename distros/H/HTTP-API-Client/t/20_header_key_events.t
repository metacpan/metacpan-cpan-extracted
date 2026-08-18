=head1 NAME

20_header_key_events.t - coverage for headers_keys, add_headers_keys, and
the per-key before_header/after_header events, none of which had a test
before (t/04_callbacks.t covers before_headers, after_header_keys, and
CODE values inside the raw %headers hash - a different mechanism)

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new;
    my $req = $api->get( "http://example.com", {}, { A => "1", B => "2", C => "3" }, {
        test_request_object => 1,
        headers_keys        => sub { qw(A C) },
    } );

    is $req->header("A"), "1", "headers_keys: an included key is set";
    ok !defined $req->header("B"), "headers_keys: an excluded key is not set";
    is $req->header("C"), "3", "headers_keys: another included key is set";
}

{
    my $api = HTTP::API::Client->new;
    my $req = $api->get( "http://example.com", {}, { A => "1" }, {
        test_request_object => 1,
        add_headers_keys    => sub {
            my ( $self, %o ) = @_;
            $o{headers}{B} = "extra";
            return "B";
        },
    } );

    is $req->header("A"), "1", "add_headers_keys: the original key is still set";
    is $req->header("B"), "extra", "add_headers_keys: the added key is set too";
}

{
    my $api = HTTP::API::Client->new;
    my @order;
    my $req = $api->get( "http://example.com", {}, { A => "orig" }, {
        test_request_object => 1,
        before_header => { A => sub { push @order, "before"; return "computed" } },
        after_header   => { A => sub { push @order, "after" } },
    } );

    is $req->header("A"), "computed", "before_header can override the header value";
    is_deeply \@order, [ "before", "after" ],
        "before_header fires, then the header is set, then after_header fires";
}

done_testing;
