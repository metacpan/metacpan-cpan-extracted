=head1 NAME

28_uri_escape_bytes_vs_chars.t - HAC-031: HAC-029's fix switched
kvp2str_each to uri_escape_utf8(), which unconditionally UTF-8-encodes
its input. That's correct for a genuine Unicode character string, but
double-encodes a value that is ALREADY raw UTF-8 bytes (utf8::is_utf8
false - the common shape for data read from a file/DB/API without being
explicitly Encode::decode'd), producing mojibake instead of the correct
percent-encoding.

=cut

use strict;
use warnings;
use utf8;
use Test::More;
use Encode;
use HTTP::API::Client;
use URI::Escape qw( uri_escape_utf8 );

my $wide_chars = "\x{65E5}\x{672C}";                       ## genuine Unicode string
my $utf8_bytes = Encode::encode( utf8 => $wide_chars );    ## already raw UTF-8 bytes, is_utf8 flag off
my $expected   = uri_escape_utf8($wide_chars);              ## the one correct answer for this content

ok !utf8::is_utf8($utf8_bytes), "sanity: the byte-string input is not UTF8-flagged";

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { name => $wide_chars }, {}, { test_request_object => 1 } );
    is $req->uri, "http://example.com?name=$expected",
        "a genuine Unicode character string still encodes correctly (HAC-029 unaffected)";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { name => $utf8_bytes }, {}, { test_request_object => 1 } );
    is $req->uri, "http://example.com?name=$expected",
        "a value that is already raw UTF-8 bytes is not double-encoded";
}

{
    my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
    my $req = $api->get( "http://example.com", { name => "plain ascii" }, {}, { test_request_object => 1 } );
    is $req->uri, "http://example.com?name=plain%20ascii", "plain ASCII values unaffected";
}

done_testing;
