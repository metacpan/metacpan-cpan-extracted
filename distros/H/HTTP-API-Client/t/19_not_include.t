=head1 NAME

19_not_include.t - regression test for HAC-022: the not_include event must
exclude a key in form-urlencoded mode the same way it already does in
JSON mode

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( content_type => "application/json" );
    my $req = $api->post( "http://example.com", { a => 1, secret => "hide-me" },
        {}, { test_request_object => 1, not_include => { secret => 1 } } );

    unlike $req->content, qr/secret/, "not_include already excludes the key in JSON mode";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->post( "http://example.com", { a => 1, secret => "hide-me" },
        {}, { test_request_object => 1, not_include => { secret => 1 } } );

    unlike $req->content, qr/secret/, "not_include excludes the key in form-urlencoded mode too";
    like $req->content, qr/a=1/, "the non-excluded key is still present";
}

done_testing;
