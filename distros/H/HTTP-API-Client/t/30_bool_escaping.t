=head1 NAME

30_bool_escaping.t - HAC-033: kvp2str_each's BOOL branch interpolated
its value directly with no percent-escaping, unlike every other branch
(plain scalar, ARRAY, CSV) - a BOOL value containing '&' or '=' corrupted
the query string by introducing extra params.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use URI;

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { flag => xBOOLEAN("a&b=c") }, {}, {
        test_request_object => 1,
    } );

    my $uri = URI->new( $req->uri );
    my %params = $uri->query_form;

    is_deeply \%params, { flag => "a&b=c" },
        "a BOOL value containing '&' and '=' is correctly escaped, not treated as extra params";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { flag => xTRUE }, {}, { test_request_object => 1 } );
    is $req->uri, "http://example.com?flag=1", "xTRUE output unchanged";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { flag => xTrue }, {}, { test_request_object => 1 } );
    is $req->uri, "http://example.com?flag=True", "xTrue output unchanged";
}

done_testing;
