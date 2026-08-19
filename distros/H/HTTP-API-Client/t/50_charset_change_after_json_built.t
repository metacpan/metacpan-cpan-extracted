=head1 NAME

50_charset_change_after_json_built.t - HAC-067: like HAC-066's ua/browser_id/
timeout/ssl_verify, the json attribute is lazy and memoized - built once,
on first use, from whatever charset was set at the time. Changing charset
after that point was a silent no-op: kvp2json() kept using the JSON::XS
object's original charset mode, so an invalid charset set after the first
JSON encode never triggered HAC-046's documented "dies immediately and
clearly" behavior, and switching between two valid charsets after the
first encode had no effect on the actual output bytes.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new;

    $api->kvp2json( data => { a => 1 }, events => {} );    # force json to build with the default charset
    $api->charset("bogus_invalid_charset_xyz");

    eval { $api->kvp2json( data => { a => 1 }, events => {} ) };
    my $error = $@;

    ok $error, "an invalid charset set after json is already built still dies on the next encode";
    like $error, qr/bogus_invalid_charset_xyz/, "the error names the offending charset";
}

{
    my $api = HTTP::API::Client->new( charset => "utf8" );
    my $wide = "caf\x{e9}";
    utf8::upgrade($wide);    # a genuine Unicode string, not ambiguous raw bytes (see HAC-055)

    my $utf8_json = $api->kvp2json( data => { a => $wide }, events => {} );

    $api->charset("latin1");

    my $latin1_json = $api->kvp2json( data => { a => $wide }, events => {} );

    isnt $utf8_json, $latin1_json,
        "switching charset after json is already built changes the actual encoded output on the next call";
}

done_testing;
