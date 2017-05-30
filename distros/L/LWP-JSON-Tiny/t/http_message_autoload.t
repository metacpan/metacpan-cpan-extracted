#!/usr/bin/env perl
# Make sure that rebless_maybe works on a HTTP::Response when
# nobody has called HTTP::Message->content_type yet.
# This needs to be a separate test file to make sure we start with as
# close to a fresh HTTP::Message setup as is humanly possible.

use strict;
use warnings;
no warnings 'uninitialized';

use Test::More;

use LWP::UserAgent::JSON;

rebless_response_no_autoload();

Test::More::done_testing();

# Make sure that we rebless a response object accurately, even if
# there hasn't been any autoloading of HTTP::Message->content_type yet.
# This is https://github.com/skington/lwp-json-tiny/issues/2

sub rebless_response_no_autoload {
    # Set up a bare-bones response.
    my $response = HTTP::Response->new(
        200, 'OK',
        HTTP::Headers->new(
            Content_Type   => 'application/json',
            Content_Length => 25,
        ),
        '{"this":"json structure"}'
    );
    is($response->as_string, <<RESPONSE, 'It behaves like a proper response');
200 OK
Content-Length: 25
Content-Type: application/json

{"this":"json structure"}
RESPONSE

    # Even though there is no content_type method yet, we can still check
    # that it's JSON.
    ok(
        !exists $HTTP::Message::{content_type},
        'No content_type method exists yet'
    );
    ok(LWP::UserAgent::JSON->rebless_maybe($response), 'We can rebless it');
    is($response->content_type, 'application/json', 'We got back JSON');
    isa_ok($response, 'HTTP::Response::JSON');
    is_deeply(
        $response->json_content,
        { this => 'json structure' },
        'We can decode the JSON'
    );
}
