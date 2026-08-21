=head1 NAME

98_basic_auth_empty_username_set_password.t - HAC-133: prepare_request()'s
Basic-auth guard ('if (length($u) || length($p))') had HAC-118/t/86 cover
both-"0", username-only-"0", and both-empty, but never the "username
empty, password non-empty" combination. Live-verified before this test
existed: the behavior is already correct - Basic auth still triggers.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use MIME::Base64 qw(decode_base64);

{
    my $api = HTTP::API::Client->new( username => "", password => "secret" );
    my $req = $api->get( "http://x/", {}, {}, { test_request_object => 1 } );

    ok defined $req->header("Authorization"),
        "an empty username with a non-empty password still triggers Basic auth";

    my ($encoded) = $req->header("Authorization") =~ /Basic (.+)/;
    is decode_base64($encoded), ":secret", "the credentials are correctly ':secret', not dropped";
}

done_testing;
