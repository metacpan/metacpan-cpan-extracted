=head1 NAME

27_undef_value_guard.t - HAC-030: _execute_callbacks' undef-value guard
(next if !defined $callback) had zero test coverage - no test ever passed
an explicit undef value for a data or header key, so this defensive
branch (and the downstream skip-on-undef in kvp2json/kvp2str) was
entirely unverified.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new;

    my $req = eval {
        $api->post( "http://example.com", { name => "kept", secret => undef }, {}, {
            test_request_object => 1,
        } );
    };

    ok !$@, "an explicit undef data value does not crash (error: " . ($@ // '') . ")";
    is $req->content, '{"name":"kept"}', "the undef-valued key is silently omitted from the JSON body";
}

{
    my $api = HTTP::API::Client->new;

    my $req = eval {
        $api->get( "http://example.com", {}, { A => "1", B => undef }, {
            test_request_object => 1,
        } );
    };

    ok !$@, "an explicit undef header value does not crash (error: " . ($@ // '') . ")";
    is $req->header("A"), "1", "the defined header key is still set";
    ok !defined $req->header("B"), "the undef-valued header key is silently omitted";
}

done_testing;
