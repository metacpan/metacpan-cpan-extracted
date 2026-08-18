=head1 NAME

18_auth_token.t - coverage for auth_token, including the documented
username/password-wins precedence rule (neither had a test before)

=cut

use strict;
use warnings;
use Test::More;
use MIME::Base64 qw(encode_base64);
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( auth_token => "Bearer abc123" );
    my $req = $api->get( "http://example.com", {}, {}, { test_request_object => 1 } );

    is $req->header("Authorization"), "Bearer abc123",
        "auth_token alone sets the Authorization header verbatim";
}

{
    my $api = HTTP::API::Client->new(
        username   => "bob",
        password   => "secret",
        auth_token => "Bearer abc123",
    );
    my $req = $api->get( "http://example.com", {}, {}, { test_request_object => 1 } );

    my $expected_basic = "Basic " . encode_base64( "bob:secret", "" );
    is $req->header("Authorization"), $expected_basic,
        "username/password set alongside auth_token still uses Basic auth (precedence)";
}

done_testing;
