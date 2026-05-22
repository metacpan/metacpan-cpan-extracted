use strict;
use warnings;
use Test::More;

use_ok('HTML::Gumbo');

# Tests for GUMBO_NODE_TEMPLATE handling.
# Before the fix, walk_tree() treated template nodes as text nodes and
# accessed uninitialized memory via node->v.text.text, which produced
# garbage output in string mode and croaked "Unknown node type" in
# callback mode.
# See: https://github.com/ruz/HTML-Gumbo/issues/6

my $parser = HTML::Gumbo->new;

{
    my $input    = qq{<template><p>hi</p></template>};
    my $expected = qq{<html><head><template><p>hi</p></template></head><body></body></html>\n};
    my $res = $parser->parse($input);
    is $res, $expected, 'template element is walked and serialized correctly';
}

{
    my $input    = qq{<template></template>};
    my $expected = qq{<html><head><template></template></head><body></body></html>\n};
    my $res = $parser->parse($input);
    is $res, $expected, 'empty template element is serialized correctly';
}

{
    my $input    = qq{<template id="t1"><span>x</span></template>};
    my $expected = qq{<html><head><template id="t1"><span>x</span></template></head><body></body></html>\n};
    my $res = $parser->parse($input);
    is $res, $expected, 'template element preserves attributes';
}

{
    my $input    = qq{<template><template><b>nested</b></template></template>};
    my $expected = qq{<html><head><template><template><b>nested</b></template></template></head><body></body></html>\n};
    my $res = $parser->parse($input);
    is $res, $expected, 'nested template elements are walked';
}

{
    my $input = qq{<template><p>hi</p></template>};
    my @expected = (
        ['document start', undef],
        ['start', 'html', []],
        ['start', 'head', []],
        ['start', 'template', []],
        ['start', 'p', []],
        ['text', 'hi'],
        ['end', 'p'],
        ['end', 'template'],
        ['end', 'head'],
        ['start', 'body', []],
        ['end', 'body'],
        ['end', 'html'],
        ['document end'],
    );
    my @got;
    $parser->parse($input, format => 'callback', callback => sub {
        push @got, [@_];
    });
    is_deeply \@got, \@expected, 'callback mode emits template start/end with children';
}

done_testing();
