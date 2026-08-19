=head1 NAME

73_auth_token_does_not_clobber_explicit_header.t - HAC-094:
prepare_request() unconditionally wrote $headers->{authorization} = $at
whenever auth_token was set and username/password weren't, even if the
caller had already explicitly passed their own Authorization header
(any casing) for this specific call - a real, plausible per-call
override (e.g. a freshly refreshed token) was silently discarded with
no error or warning. prepare_request() now only applies auth_token's
default when the caller hasn't already provided an authorization header
of any casing.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( auth_token => "token-from-attr" );
    my $req = $api->get( "http://example.com", {},
        { Authorization => "Bearer per-call-override" }, { test_request_object => 1 } );

    is $req->header('Authorization'), "Bearer per-call-override",
        "an explicit per-call Authorization header is respected, not clobbered by auth_token";
}

{
    my $api = HTTP::API::Client->new( auth_token => "token-from-attr" );
    my $req = $api->get( "http://example.com", {},
        { authorization => "Bearer lowercase-override" }, { test_request_object => 1 } );

    is $req->header('Authorization'), "Bearer lowercase-override",
        "the override is respected case-insensitively";
}

{
    my $api = HTTP::API::Client->new( auth_token => "token-from-attr" );
    my $req = $api->get( "http://example.com", {}, {}, { test_request_object => 1 } );

    is $req->header('Authorization'), "token-from-attr",
        "auth_token still applies as the default when the caller sets no Authorization header at all";
}

done_testing;
