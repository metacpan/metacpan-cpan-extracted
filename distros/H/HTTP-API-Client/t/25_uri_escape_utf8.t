=head1 NAME

25_uri_escape_utf8.t - HAC-029: a form-urlencoded request with a genuinely
wide Unicode character (codepoint > 0xFF - CJK, Cyrillic, emoji) in a key
or value must not crash. kvp2str_each used URI::Escape::uri_escape(),
which dies outright above 0xFF ("Can't escape \x{...}, try
uri_escape_utf8() instead") instead of encoding.

=cut

use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::API::Client;
use URI::Escape qw( uri_escape_utf8 );

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );

    my $req = eval {
        $api->get( "http://example.com", { name => "\x{65E5}\x{672C}\x{8A9E}" }, {}, {
            test_request_object => 1,
        } );
    };

    ok !$@, "a wide Unicode character in a value does not crash (error: " . ($@ // '') . ")";
    is $req->uri, "http://example.com?name=" . uri_escape_utf8("\x{65E5}\x{672C}\x{8A9E}"),
        "the value is correctly percent-encoded as UTF-8 bytes";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );

    my $req = eval {
        $api->get( "http://example.com", { "\x{65E5}\x{672C}" => "1" }, {}, {
            test_request_object => 1,
        } );
    };

    ok !$@, "a wide Unicode character in a key does not crash (error: " . ($@ // '') . ")";
    is $req->uri, "http://example.com?" . uri_escape_utf8("\x{65E5}\x{672C}") . "=1",
        "the key is correctly percent-encoded as UTF-8 bytes";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { b => 1, a => 2 }, {}, { test_request_object => 1 } );
    is $req->uri, "http://example.com?a=2&b=1", "plain-ASCII form-urlencoded behavior unchanged";
}

done_testing;
