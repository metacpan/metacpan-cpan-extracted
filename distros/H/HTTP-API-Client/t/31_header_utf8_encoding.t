=head1 NAME

31_header_utf8_encoding.t - HAC-034: header values got zero UTF-8
handling, unlike body values (fixed for body content by HAC-029/031/032).
A wide Unicode header value stayed UTF8-flagged all the way through, so
serializing the request (as_string, or LWP writing it to the socket)
produced "Wide character in print" warnings instead of correct bytes.

=cut

use strict;
use warnings;
use utf8;
use Test::More;
use Encode;
use HTTP::API::Client;

my $wide_chars = "\x{65E5}\x{672C}\x{8A9E}";

{
    my $api = HTTP::API::Client->new;
    my $req = $api->get( "http://example.com", {}, { "X-Name" => $wide_chars }, {
        test_request_object => 1,
    } );

    ok !utf8::is_utf8( $req->header("X-Name") ),
        "the header value is byte-encoded, not left UTF8-flagged";
    is $req->header("X-Name"), Encode::encode( utf8 => $wide_chars ),
        "the header value is the correct UTF-8 byte encoding of the original string";

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $string = $req->as_string;
    ok !( grep { /Wide character/ } @warnings ),
        "serializing the request produces no 'Wide character' warning";
}

{
    my $api = HTTP::API::Client->new;
    my $req = $api->get( "http://example.com", {}, { "X-Name" => "plain ascii" }, {
        test_request_object => 1,
    } );
    is $req->header("X-Name"), "plain ascii", "plain ASCII header values unaffected";
}

done_testing;
