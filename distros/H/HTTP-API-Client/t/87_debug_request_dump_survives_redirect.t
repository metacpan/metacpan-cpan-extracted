=head1 NAME

87_debug_request_dump_survives_redirect.t - HAC-121: send()'s DEBUG_IN_OUT/
DEBUG_SEND_OUT '-- REQUEST --' dump printed $response->request->as_string
instead of the $req object it actually built and passed to $ua->request($req).
LWP::UserAgent follows redirects automatically for GET/HEAD by default, and on
a redirect $response->request is the LAST request in the chain (a new object,
built by LWP for the redirected-to URL) - not the original outgoing request.
So the debug dump silently showed the wrong request (wrong URL, and for a
303-redirected POST, even the wrong method) whenever a GET/HEAD hit a
redirect. This fakes that scenario without a real socket: the fake UA's
request() returns a response whose ->request is a different object/URI than
the $req it was handed, exactly like LWP does after following a redirect.

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

package RedirectingFakeUA;
sub new { bless {}, $_[0] }
sub agent {}
sub timeout {}

sub request {
    my ($self, $req) = @_;
    $self->{last_req} = $req;
    my $r = HTTP::Response->new(200);
    ## simulate LWP's own post-redirect behavior: $response->request is a
    ## DIFFERENT object, pointing at the redirected-to URL, not $req.
    $r->request( HTTP::Request->new( GET => "http://redirected-to/final" ) );
    $r->content("OK");
    return $r;
}

package main;

{
    local $ENV{DEBUG_IN_OUT} = 1;
    my $api = HTTP::API::Client->new;
    $api->ua( RedirectingFakeUA->new );

    my $out = capture_stderr( sub { $api->get("http://original-host/start") } );

    like $out, qr{http://original-host/start},
        "the REQUEST dump shows the request actually sent, not the redirected-to one";
    unlike $out, qr{redirected-to},
        "the REQUEST dump does not show \$response->request's post-redirect URL";
}

{
    local $ENV{DEBUG_SEND_OUT} = 1;
    my $api = HTTP::API::Client->new;
    $api->ua( RedirectingFakeUA->new );

    my $out = capture_stderr( sub { $api->get("http://original-host/start") } );

    like $out, qr{http://original-host/start},
        "DEBUG_SEND_OUT's dump also shows the actual outgoing request, not the redirected-to one";
}

done_testing;
