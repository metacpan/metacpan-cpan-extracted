#!/usr/bin/env perl
# Tests for HTTP::Response::JSON

use strict;
use warnings;
no warnings 'uninitialized';

use Test::Fatal;
use Test::More;

use HTTP::Response::JSON;

my $tested_class = 'HTTP::Response::JSON';

isa();
pass_through();
decode_invalid();
decode_ascii();
charset_guessed();
decode_unicode();
ignore_binary();

Test::More::done_testing();

sub isa {
    my $request = $tested_class->new;
    isa_ok($request, 'HTTP::Response',
        'This is a subclass of HTTP::Response');
    can_ok($request, 'json_content');
}

sub pass_through {
    my $response = $tested_class->new;
    $response->content_type('text/html');
    my $html
        = '<html><head><title>Meh</title></head>'
        . '<body><p>Meh</p></body></html>';
    $response->content($html);
    is($response->decoded_content, $html,
       'Decoded content via standard LWP is what we expect');
    is($response->json_content, undef, q{Don't even try to decode it});
}

sub decode_invalid {
    my $response = $tested_class->new;
    $response->content_type('application/json');
    $response->content('["foo", "bar", "baz');
    ok(
        exception { $response->json_content },
        'Invalid JSON throws an exception'
    );
}

sub decode_ascii {
    my $response = $tested_class->new;
    $response->content_type('application/json');
    $response->content('{"foo":["toto","tata","titi"]}');
    is_deeply(
        $response->json_content,
        { foo => [qw(toto tata titi)] },
        'ASCII JSON decodes happily'
    );
}

sub charset_guessed {
    my $response = $tested_class->new;
    $response->content_type('application/json');
    is($response->content_charset, 'UTF-8', 'JSON is recognised as UTF8');
}

sub decode_unicode {
    my $response = $tested_class->new;
    $response->content_type('application/json');
    # POUND SIGN Unicode: U+00A3, UTF-8: C2 A3
    # SNOWMAN Unicode: U+2603, UTF-8: E2 98 83
    $response->content(
        sprintf(
            '{"price":"%s9.99","label":"%s"}',
            chr(0xC2) . chr(0xA3),
            chr(0xE2) . chr(0x98) . chr(0x83)
        )
    );
    isnt($response->decoded_content,
        $response->content,
        "Some Unicode encoding has happened in the response");
    is_deeply(
        $response->json_content,
        {
            price => "\x{00A3}9.99",
            label => "\x{2603}"
        },
        'Unicode decodes accurately'
    );
}

sub ignore_binary {
    my $response = $tested_class->new;
    $response->content_type('application/not-json-at-all');
    # GREEK SMALL LETTER PI Unicode: U+03C0, UTF-8: CF 80
    $response->content(chr(0xCF) . chr(0x80));
    is($response->decoded_content,
        $response->content, 'No Unicode decoding done on non-JSON');
    is(length($response->decoded_content),
        2, 'Decoded content is 2 bytes, not one Unicode character');
}