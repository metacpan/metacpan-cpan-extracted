=head1 NAME

90_debug_response_header_only.t - HAC-124: DEBUG_RESPONSE_HEADER_ONLY
(documented in the ENVIRONMENT VARIABLES POD section, used by send()'s
RESPONSE debug dump to choose $response->headers->as_string instead of
$response->as_string) had zero test coverage anywhere in the suite -
Devel::Cover's branch report confirmed the ternary at ~line 987 had an
untested arm. Live-verified before this test existed: the behavior is
already correct, this closes a coverage gap, not a defect.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use HTTP::API::Client;
use HTTP::Response;
use HTTP::Request;
use CaptureStderr;

package FakeUA;
sub new { bless {}, shift }
sub agent {}
sub timeout {}
sub request {
    my $r = HTTP::Response->new(200);
    $r->request( HTTP::Request->new( GET => "http://x/" ) );
    $r->header( "X-Test" => "yes" );
    $r->content("the response body");
    return $r;
}

package main;

{
    local $ENV{DEBUG_RESPONSE}             = 1;
    local $ENV{DEBUG_RESPONSE_HEADER_ONLY} = 1;
    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    like $out, qr/X-Test: yes/, "DEBUG_RESPONSE_HEADER_ONLY still prints the response headers";
    unlike $out, qr/the response body/,
        "DEBUG_RESPONSE_HEADER_ONLY omits the response body from the dump";
}

{
    local $ENV{DEBUG_RESPONSE} = 1;
    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    like $out, qr/the response body/,
        "without DEBUG_RESPONSE_HEADER_ONLY, the body is included in the dump";
}

done_testing;
