=head1 NAME

59_json_response_charset_change.t - HAC-076: json_response() never
re-applied charset before decoding, unlike kvp2json() (HAC-067) which
does on the encode side. json is lazy and memoized - built once, on
first use, in whatever charset mode was set at the time. Changing
charset afterward and calling json_response() again on the same
response body still decoded through the stale mode, silently producing
mojibake for a UTF-8-encoded body if json had first been built in a
non-utf8 mode. json_response() now re-applies charset to the existing
json object at the start of every call, matching kvp2json()'s existing
behavior.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

my $api = HTTP::API::Client->new( charset => "latin1" );

my $r = HTTP::Response->new(200);
$r->content( qq({"name":"caf\xc3\xa9"}) );    # UTF-8-encoded bytes for "café"
$api->last_response($r);

# Forces json's lazy build in latin1 mode - the wrong mode for this body.
my $mojibake = $api->json_response;
isnt $mojibake->{name}, "caf\x{e9}", "sanity: latin1-mode decode of UTF-8 bytes is mojibake, not the real value";

$api->charset("utf8");
my $correct = $api->json_response;
is $correct->{name}, "caf\x{e9}",
    "charset changed to utf8 after json was already built takes effect on the next json_response() call";

done_testing;
