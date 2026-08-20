=head1 NAME

81_form_urlencoded_content_type_with_params.t - HAC-107: convert_data()'s
content_type dispatch required an EXACT match ('eq') for form-urlencoded,
while its JSON branch matched leniently (a bare substring check, so
'application/json; charset=utf8' - this module's own default - already
worked). A form-urlencoded content_type with a trailing parameter, like
'application/x-www-form-urlencoded; charset=utf-8' (a valid Content-Type
value, and the same charset-suffix pattern the module's own JSON default
uses), died instead of being accepted. new_request()'s GET-restriction
check had the identical exact-match problem. Both now accept a
form-urlencoded content_type followed by ';' or end-of-string, matching
the JSON branch's existing leniency.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new(
        content_type => "application/x-www-form-urlencoded; charset=utf-8",
    );

    my $req = eval {
        $api->post( "http://x/", { a => 1 }, {}, { test_request_object => 1 } );
    };

    ok !$@, "POST with a charset-qualified form-urlencoded content_type doesn't die (error: " . ( $@ // '' ) . ")";
    is $req->content, "a=1", "the body is still correctly form-urlencoded";
}

{
    my $api = HTTP::API::Client->new(
        content_type => "application/x-www-form-urlencoded; charset=utf-8",
    );

    my $req = eval {
        $api->get( "http://x/", { a => 1 }, {}, { test_request_object => 1 } );
    };

    ok !$@, "GET with a charset-qualified form-urlencoded content_type doesn't die (error: " . ( $@ // '' ) . ")";
    like $req->uri, qr/\?a=1$/, "the query string is still correctly built";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );

    my $req = $api->post( "http://x/", { a => 1 }, {}, { test_request_object => 1 } );

    is $req->content, "a=1", "the bare content_type (no parameter) is unaffected by this fix";
}

done_testing;
