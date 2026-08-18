=head1 NAME

32_basic_auth_utf8.t - HAC-035: Basic Auth crashed on a wide-character
username or password. Unlike auth_token (fixed by HAC-034, since it
flows through the header-setting loop) and body values (HAC-029/031/032),
username/password went straight into authorization_basic() with no
UTF-8 handling - authorization_basic()'s internal base64 encoding dies
on a UTF8-flagged wide-character string.

=cut

use strict;
use warnings;
use utf8;
use Test::More;
use Encode;
use MIME::Base64 qw( decode_base64 );
use HTTP::API::Client;

my $wide_user = "\x{65E5}\x{672C}\x{8A9E}";

{
    my $api = HTTP::API::Client->new( username => $wide_user, password => "secret" );

    my $req = eval {
        $api->get( "http://example.com", {}, {}, { test_request_object => 1 } );
    };

    ok !$@, "a wide-character username does not crash (error: " . ($@ // '') . ")";

    my $auth = $req->header("Authorization");
    $auth =~ s/^Basic //;
    my $decoded = decode_base64($auth);

    is $decoded, Encode::encode( utf8 => $wide_user ) . ":secret",
        "the Authorization header decodes to the correct UTF-8 credentials";
}

{
    my $api = HTTP::API::Client->new( username => "user", password => $wide_user );
    my $req = eval {
        $api->get( "http://example.com", {}, {}, { test_request_object => 1 } );
    };
    ok !$@, "a wide-character password does not crash (error: " . ($@ // '') . ")";
}

{
    my $api = HTTP::API::Client->new( username => "user", password => "pass" );
    my $req = $api->get( "http://example.com", {}, {}, { test_request_object => 1 } );
    my $auth = $req->header("Authorization");
    $auth =~ s/^Basic //;
    is decode_base64($auth), "user:pass", "plain ASCII username/password unaffected";
}

done_testing;
