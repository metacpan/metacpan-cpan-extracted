=head1 NAME

22_add_headers_keys_dedup.t - HAC-025: add_headers_keys, per its own
documented usage (mutate %headers as a side effect, then return the key),
must not cause that key to be processed twice in new_request()'s @keys

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new;
    my $before_count = 0;
    my $after_count  = 0;

    my $req = $api->get( "http://example.com", {}, { A => "1" }, {
        test_request_object => 1,
        add_headers_keys    => sub {
            my ( $self, %o ) = @_;
            $o{headers}{B} = "extra";
            return "B";
        },
        before_header => { B => sub { $before_count++; return "extra" } },
        after_header  => { B => sub { $after_count++ } },
    } );

    is $req->header("B"), "extra", "the added key is still set correctly";
    is $before_count, 1, "before_header for the added key fires exactly once";
    is $after_count, 1, "after_header for the added key fires exactly once";
}

done_testing;
