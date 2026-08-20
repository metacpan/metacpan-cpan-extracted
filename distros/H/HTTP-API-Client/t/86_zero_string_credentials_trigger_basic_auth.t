=head1 NAME

86_zero_string_credentials_trigger_basic_auth.t - HAC-118:
prepare_request()'s 'if ($u || $p)' check used plain Perl truthiness,
which treats the valid, non-empty string "0" as false - inconsistent
with this module's own established convention (_defor, _build_username/
_build_password) of checking emptiness via length(), not truthiness.
Verified live before this fix: HTTP::API::Client->new(username=>"0",
password=>"0")->get($url) sent no Authorization header at all, silently
dropping valid, explicitly-set credentials. username="0" or password="0"
alone (with the other genuinely truthy) already worked correctly - only
the combination of both being "0" (or one "0" and the other empty)
silently dropped authentication entirely.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use MIME::Base64 qw(decode_base64);

{
    my $api = HTTP::API::Client->new( username => "0", password => "0" );
    my $req = $api->get( "http://x/", {}, {}, { test_request_object => 1 } );

    ok defined $req->header("Authorization"),
        "username='0'/password='0' both trigger Basic auth instead of being silently dropped";

    my ($encoded) = $req->header("Authorization") =~ /Basic (.+)/;
    is decode_base64($encoded), "0:0", "the credentials are correctly '0:0', not empty";
}

{
    my $api = HTTP::API::Client->new( username => "0", password => "" );
    my $req = $api->get( "http://x/", {}, {}, { test_request_object => 1 } );

    ok defined $req->header("Authorization"),
        "username='0' alone (password genuinely empty) still triggers Basic auth";
}

{
    # Both genuinely empty (the documented "no credentials" case) is unaffected.
    my $api = HTTP::API::Client->new( username => "", password => "" );
    my $req = $api->get( "http://x/", {}, {}, { test_request_object => 1 } );

    ok !defined $req->header("Authorization"),
        "genuinely empty username and password still correctly skip Basic auth";
}

{
    # The identical bug existed for auth_token's own check.
    my $api = HTTP::API::Client->new( auth_token => "0" );
    my $req = $api->get( "http://x/", {}, {}, { test_request_object => 1 } );

    is $req->header("Authorization"), "0",
        "auth_token='0' is correctly sent instead of being silently dropped";
}

done_testing;
