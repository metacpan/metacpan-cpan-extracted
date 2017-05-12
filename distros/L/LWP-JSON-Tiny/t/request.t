#!/usr/bin/env perl
# Tests for HTTP::Request::JSON

use strict;
use warnings;
no warnings 'uninitialized';

use Test::Fatal;
use Test::More;

use HTTP::Request::JSON;

my $tested_class = 'HTTP::Request::JSON';

isa();
accept_header();
encode_invalid();
encode_valid();
encode_unicode();
getter_vs_setter();

Test::More::done_testing();

sub isa {
    my $request = $tested_class->new;
    isa_ok($request, 'HTTP::Request', 'This is a subclass of HTTP::Request');
    can_ok($request, 'json_content');
}

sub accept_header {
    my $request = $tested_class->new;
    is($request->headers->header('Accept'),
        'application/json', 'The Accept header is automatically set');
}

sub encode_invalid {
    my $request = $tested_class->new;
    my $scalar = 42;
    ok(
        exception { $request->json_content(\$scalar) },
        'Cannot add arbitrary scalar references as JSON'
    );
    ok(
        exception {
            $request->json_content(bless 'foo' => 'Package::Thing')
        },
        'Cannot add blessed objects as JSON'
    );
}

sub encode_valid {
    my $request = $tested_class->new;
    is($request->content_type, '', 'No content type at first');
    $request->json_content({foo => ['foo', 'bar', { baz => 'bletch'}]});
    is(
        $request->decoded_content,
        '{"foo":["foo","bar",{"baz":"bletch"}]}',
        'Simple JSON encoding worked'
    );
    is($request->content_type, 'application/json',
        'We have a content-type now');
}

sub encode_unicode {
    return if $^V lt v5.13.8;
    use if $^V ge v5.13.8, feature => 'unicode_strings';

    # OK, time to try the most famous Unicode character of all,
    # PILE OF POO.
    # Unicode: U+1F4A9 (U+D83D U+DCA9), UTF-8: F0 9F 92 A9
    my $pile_of_poo = "\x{1f4a9}";
    my $request     = $tested_class->new;
    $request->json_content($pile_of_poo);
    is(length($request->content),
        6, '6 bytes in the raw content: 4 bytes of poo plus quotes');
    is_deeply(
        [map { ord($_) } split(//, $request->content)],
        [ord('"'), 0xF0, 0x9F, 0x92, 0xA9, ord('"')],
        'Bytes look fine'
    );
    is(length($request->decoded_content),
        3, '3 code points in the decoded content: 1 pile of poo plus quotes');
    is_deeply(
        [map { ord($_) } split(//, $request->decoded_content)],
        [ord('"'), 0x1f4a9, ord('"')],
        'Code points look fine'
    );
    is($request->json_content, $pile_of_poo, 'That decodes to JSON fine');
}

sub getter_vs_setter {

    my $perl_structure = { foo => 'bar' };
    my $json = '{"foo":"bar"}';

    my $request = $tested_class->new;
    is($request->decoded_content, '', 'No contents yet');
    is($request->json_content($perl_structure), $json,
       'The setter returns JSON');
    is($request->decoded_content, $json, 'That set the content');
    is_deeply(
        $request->json_content,
        $perl_structure,
        'The getter returns a decoded Perl structure'
    );
    is($request->decoded_content, $json, 'The content is still JSON');
}
