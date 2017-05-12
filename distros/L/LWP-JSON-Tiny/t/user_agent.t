#!/usr/bin/env perl
# Tests for LWP::UserAgent::JSON

use utf8;
use strict;
use warnings;
no warnings 'uninitialized';

use FindBin;
use Test::More;

use LWP::UserAgent::JSON;

use lib "$FindBin::Bin/lib";
use LWP::Protocol::record;

my $tested_class = 'LWP::UserAgent::JSON';

isa();
guess_content_type();
post_simple();
post_encoding();
put();
patch();

Test::More::done_testing();

sub isa {
    my $user_agent = $tested_class->new;
    isa_ok($user_agent, 'LWP::UserAgent',
        'This is a subclass of LWP::UserAgent');
}

sub guess_content_type {
    my $user_agent = $tested_class->new;
    my $dir_fixtures = $FindBin::Bin . '/fixtures';

    # Text file: not messed with.
    my $request_text
        = HTTP::Request->new(GET => "file://$dir_fixtures/test.txt");
    my $response_text = $user_agent->request($request_text);
    is($response_text->content_type,
        'text/plain', 'Text file recognised as text');
    like(
        $response_text->decoded_content,
        qr/The quick brown fox/,
        'Text file contains what we expect'
    );
    is(ref($response_text), 'HTTP::Response',
        'Normal HTTP::Response for text file');
    ok(
        !$tested_class->rebless_maybe($response_text),
        'Will not rebless a non-JSON response'
    );
    is(ref($response_text), 'HTTP::Response',
        'Still have a normal HTTP::Response for text file');

    # JSON: reblessed and decoded.
    my $request_json
        = HTTP::Request->new(GET => "file://$dir_fixtures/test.json");
    my $response_json = $user_agent->request($request_json);
    is($response_json->content_type,
        'application/json', 'JSON file recognised as JSON');
    like($response_json->decoded_content,
        qr/Shave yaks/, 'JSON file contains what we expect');
    is(ref($response_json), 'HTTP::Response::JSON',
        'Got a HTTP::Response::JSON object for JSON response');
    bless $response_json => 'HTTP::Response';
    ok($tested_class->rebless_maybe($response_json),
        'Will rebless this JSON response');
    is(ref($response_json), 'HTTP::Response::JSON',
        'Got a HTTP::Response::JSON objectagain for JSON response');
}

sub post_simple {
    my $user_agent = $tested_class->new(agent => 'TestStuff');

    # Baseline test: POST works as normal with no arguments.
    response_matches(
        'A simple POST with no arguments looks fine',
        sub { $user_agent->post('record::example.com/foo') },
        <<VANILLA_RESPONSE);
POST record::example.com/foo
User-Agent: TestStuff
Content-Length: 0
Content-Type: application/x-www-form-urlencoded

VANILLA_RESPONSE

    # Baseline post with arguments is URL-encoded,
    response_matches(
        'A simple POST with arguments is URL-encoded',
        sub {
            $user_agent->post('record::nic.meh/', { foo => 'bar' });
        },
        <<FORM_RESPONSE
POST record::nic.meh/
User-Agent: TestStuff
Content-Length: 7
Content-Type: application/x-www-form-urlencoded

foo=bar
FORM_RESPONSE
    );

    # post_json with no arguments does nothing fancy.
    response_matches(
        'A simple post_json with no arguments looks fine',
        sub { $user_agent->post_json('record::example.com/foo') },
        <<VANILLA_RESPONSE);
POST record::example.com/foo
User-Agent: TestStuff
Content-Length: 0
Content-Type: application/x-www-form-urlencoded

VANILLA_RESPONSE

    # post_json with simple arguments is JSON.
    response_matches(
        'post_json with simple arguments is JSON-encoded',
        sub {
            $user_agent->post_json('record::nic.meh/', { foo => 'bar' });
        },
        <<FORM_RESPONSE
POST record::nic.meh/
Accept: application/json
User-Agent: TestStuff
Content-Length: 13
Content-Type: application/json

{"foo":"bar"}
FORM_RESPONSE
    );

    # post_json with complex arguments is JSON and canonicalised.
    response_matches(
        'post_json with simple arguments is JSON-encoded',
        sub {
            $user_agent->post_json(
                'record::many.many.subdomains.enterprisey.wtf/'
                    . 'redundant/subdomains.servlet?guid=not-even-a-guid',
                [
                    'Hello there',
                    'Would you like me to tell you a story?',
                    'Oh go on',
                    'This next stuff will be sorted' => {
                        title => 'Shaggy dog story',
                        setup =>
                            'A guy walks into a bar, but very quickly...',
                        intermediate => [
                            'this one thing happens',
                            'then the other',
                            'then even more things',
                        ],
                        punchline => '...it was cheese',
                        comment   => 'Sorting spoils the joke',
                    }
                ]
                )
        },
        <<FORM_RESPONSE
POST record::many.many.subdomains.enterprisey.wtf/redundant/subdomains.servlet?guid=not-even-a-guid
Accept: application/json
User-Agent: TestStuff
Content-Length: 333
Content-Type: application/json

FORM_RESPONSE
            . '['
            . '"Hello there","Would you like me to tell you a story?",'
            . '"Oh go on","This next stuff will be sorted",'
            . '{"comment":"Sorting spoils the joke",'
            . '"intermediate":['
            . '"this one thing happens","then the other",'
            . '"then even more things"'
            . '],'
            . '"punchline":"...it was cheese",'
            . '"setup":"A guy walks into a bar, but very quickly...",'
            . '"title":"Shaggy dog story"}'
            . ']'
            . "\n"
    );

    # If Content and Content-Type are specified normally, they happen.
    response_matches(
        'You could always specify content and content-type',
        sub {
            $user_agent->post(
                'record::rickroll.wtf',
                'Content-Type' => 'music/midi',
                Content        => 'Will give you up at some point after all'
                )
        },
        <<FORM_RESPONSE
POST record::rickroll.wtf
User-Agent: TestStuff
Content-Length: 40
Content-Type: music/midi

Will give you up at some point after all
FORM_RESPONSE
    );

    # The same is true for post_json
    response_matches(
        'You can also override the JSON we generate',
        sub {
            $user_agent->post(
                'record::new-and-shiny',
                { stuff => 'awesome' },
                'Content-Type' => 'text/xml',
                Content        => '<brackets type="angle">lolnope</brackets>',
            );
        },
        <<FORM_RESPONSE
POST record::new-and-shiny
User-Agent: TestStuff
Content-Length: 41
Content-Type: text/xml

<brackets type="angle">lolnope</brackets>
FORM_RESPONSE
    );
}

sub post_encoding {
    return if $^V lt v5.13.8;
    use if $^V ge v5.13.8, feature => 'unicode_strings';

    # I wanted to put Unicode into the user-agent, but that apparently
    # breaks LWP::UserAgent.
    my $user_agent = $tested_class->new(agent => "Snowman");

    # OK, some standard difficult Unicode characters.

    # â˜ƒ
    # Snowman
    # Unicode: U+2603, UTF-8: E2 98 83
    my $snowman = "\x{2603}";

    # í ½í²©
    # Pile of poo
    # Unicode: U+1F4A9, UTF-8: F0 9F 92 A9
    my $pile_of_poo = "\x{1f4a9}";

    # Post with URL-encoding deals with Unicode OKish.
    decoded_content_matches(
        'Vanilla LWP copes with hard Unicode',
        sub {
            $user_agent->post('record::stuff', { php => $pile_of_poo });
        },
        'php=%F0%9F%92%A9'
    );

    # Post with JSON encoding is fine.
    decoded_content_matches(
        'post_json also copes with Unicode',
        sub {
            $user_agent->post_json('record::more-stuff',
                [{ php => $pile_of_poo }, { perl => $snowman }]);
        },
        qq{[{"php":"$pile_of_poo"},{"perl":"$snowman"}]},
    );
    
}

sub put {
    my $user_agent = $tested_class->new(agent => 'TestStuff');

    response_matches(
        'put_json with simple arguments is JSON-encoded',
        sub {
            $user_agent->put_json('record::updatethis.wtf/', ['things']);
        },
        <<FORM_RESPONSE
PUT record::updatethis.wtf/
Accept: application/json
User-Agent: TestStuff
Content-Length: 10
Content-Type: application/json

["things"]
FORM_RESPONSE
    );
}

sub patch {
    my $user_agent = $tested_class->new(agent => 'TestStuff');

    response_matches(
        'patch_json with simple arguments is JSON-encoded',
        sub {
            $user_agent->patch_json('record::fancy.ooo/', {better => 'yes'});
        },
        <<FORM_RESPONSE
PATCH record::fancy.ooo/
Accept: application/json
User-Agent: TestStuff
Content-Length: 16
Content-Type: application/json

{"better":"yes"}
FORM_RESPONSE
    );
}

sub response_matches {
    my ($title, $do_request, $expected) = @_;

    my $request = _do_request($do_request);

    is($request->as_string, $expected, $title);
}

sub decoded_content_matches {
    my ($title, $do_request, $expected) = @_;

    my $request = _do_request($do_request);

    is($request->decoded_content, $expected, $title);
}

sub _do_request {
    my ($do_request) = @_;
    LWP::Protocol::record->clear_requests;
    $do_request->();
    my @requests = LWP::Protocol::record->requests;
    return $requests[0];
}

