=head1 NAME

66_debug_response_if_fail_narrows_request_dump.t - HAC-085:
DEBUG_RESPONSE_IF_FAIL's own POD says it narrows DEBUG_IN_OUT to only
print on a failed response, but only the RESPONSE half of DEBUG_IN_OUT's
output was actually narrowed - the REQUEST dump printed unconditionally
whenever DEBUG_IN_OUT was set, regardless of response_if_fail or whether
the response succeeded. DEBUG_SEND_OUT (a separate, request-only flag
not mentioned in DEBUG_RESPONSE_IF_FAIL's POD) is deliberately left
unnarrowed - it always prints the request dump regardless.

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use HTTP::API::Client;
use FakeUA;

sub capture_stderr {
    my ($code) = @_;
    my $captured = "";
    open my $fh, ">", \$captured or die $!;
    {
        local *STDERR = $fh;
        $code->();
    }
    close $fh;
    return $captured;
}

{
    local $ENV{DEBUG_IN_OUT}          = 1;
    local $ENV{DEBUG_RESPONSE_IF_FAIL} = 1;

    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new(200) );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    is $out, "",
        "DEBUG_IN_OUT + DEBUG_RESPONSE_IF_FAIL prints nothing (request or response) on a successful response";
}

{
    local $ENV{DEBUG_IN_OUT}           = 1;
    local $ENV{DEBUG_RESPONSE_IF_FAIL} = 1;
    local $ENV{RETRY_FAIL_RESPONSE}    = 0;
    local $ENV{RETRY_DELAY}            = 0;

    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new(500) );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    like $out, qr/-- REQUEST --/, "DEBUG_IN_OUT still prints the request dump on a failed response";
    like $out, qr/-- RESPONSE/,   "DEBUG_IN_OUT still prints the response dump on a failed response";
}

{
    local $ENV{DEBUG_SEND_OUT}         = 1;
    local $ENV{DEBUG_RESPONSE_IF_FAIL} = 1;

    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new(200) );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    like $out, qr/-- REQUEST --/,
        "DEBUG_SEND_OUT is unaffected by DEBUG_RESPONSE_IF_FAIL - it always prints the request dump";
}

done_testing;
