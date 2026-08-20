=head1 NAME

16_debug_flags.t - coverage for the DEBUG_* env vars, which had never been
exercised by any test (confirmed via Devel::Cover: the print STDERR lines
showed a statement count of zero)

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
sub new { bless { code => $_[1] // 200 }, $_[0] }
sub agent {}
sub timeout {}
sub request {
    my ($self) = @_;
    my $r = HTTP::Response->new($self->{code});
    $r->request(HTTP::Request->new(GET => "http://x/"));
    $r->content($self->{code} == 200 ? "OK" : "FAIL");
    return $r;
}

package main;

{
    local $ENV{DEBUG_IN_OUT} = 1;
    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new(200) );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    like $out, qr/-- REQUEST --/,  "DEBUG_IN_OUT prints the request dump";
    like $out, qr/-- RESPONSE/,    "DEBUG_IN_OUT prints the response dump";
    like $out, qr/OK/,             "the response body appears in the dump";
}

{
    local $ENV{DEBUG_RESPONSE_IF_FAIL} = 1;
    my $api = HTTP::API::Client->new(
        retry => { count => 0, delay => 0, status => {} },
    );
    $api->ua( FakeUA->new(200) );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    is $out, "", "DEBUG_RESPONSE_IF_FAIL prints nothing on a successful response";
}

{
    # DEBUG_RESPONSE_IF_FAIL only modifies DEBUG_IN_OUT/DEBUG_RESPONSE - it
    # is not a standalone flag. Needs one of those also set to print anything.
    local $ENV{DEBUG_RESPONSE}         = 1;
    local $ENV{DEBUG_RESPONSE_IF_FAIL} = 1;
    local $ENV{RETRY_FAIL_RESPONSE}    = 0;
    local $ENV{RETRY_DELAY}            = 0;
    my $api = HTTP::API::Client->new;
    $api->ua( FakeUA->new(500) );

    my $out = capture_stderr( sub { $api->get("http://x/") } );

    like $out, qr/-- RESPONSE/, "DEBUG_RESPONSE + DEBUG_RESPONSE_IF_FAIL prints on a failed response";
}

done_testing;
