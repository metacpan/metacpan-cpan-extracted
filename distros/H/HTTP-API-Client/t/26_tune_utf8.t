=head1 NAME

26_tune_utf8.t - HAC-028: HTTP::API::Client::_tune_utf8's actual UTF-8
encoding path (its catch block) is unreachable through the public
send/get/post API, since convert_data() always hands it already
byte-encoded content (kvp2json via JSON::XS's utf8 mode, kvp2str via
uri_escape_utf8 - HAC-029). Tested directly here as a white-box unit
test of the private function, since no realistic caller path reaches it.

=cut

use strict;
use warnings;
use utf8;
use Test::More;
use Encode;
use HTTP::API::Client;

{
    my $wide = "\x{65E5}\x{672C}\x{8A9E}";    ## genuinely wide (> 0xFF), triggers HTTP::Message's "content must be bytes"
    ok utf8::is_utf8($wide), "sanity: the input string is UTF8-flagged before encoding";

    my $out = HTTP::API::Client::_tune_utf8($wide);

    ok !utf8::is_utf8($out), "_tune_utf8 returns a byte string, not a UTF8-flagged one";
    is $out, Encode::encode( utf8 => $wide ), "the bytes are the correct UTF-8 encoding of the input";
}

{
    my $bytes = "already plain ascii bytes";
    my $out = HTTP::API::Client::_tune_utf8($bytes);
    is $out, $bytes, "content that is already byte-safe passes through unchanged";
}

done_testing;
