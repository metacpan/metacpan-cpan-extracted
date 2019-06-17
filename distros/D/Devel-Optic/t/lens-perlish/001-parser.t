#!/usr/bin/perl
use strict;
use warnings;
use Test2::V0;

use Devel::Optic::Lens::Perlish::Constants qw(:all);
use Devel::Optic::Lens::Perlish::Parser qw(parse lex);

# note: not all valid lexes are valid parses (tokens might be invalid for a range of reasons)
subtest 'valid lexes' => sub {
    for my $test (qw($foo @foo %foo)) {
        is([ lex($test) ], [$test], "Symbol '$test'");
    }

    my $test = '%foo->{bar}';
    is([ lex($test) ], [qw( %foo -> { bar } )], "Simple hash access: $test");

    $test = '%foo->{b-ar}';
    is([ lex($test) ], [qw( %foo -> { b-ar } )], "Key with dash: $test");

    $test = '%foo->{b\->ar}';
    is([ lex($test) ], [qw( %foo -> { b->ar } )], "Key with escaped arrow: $test");

    $test = q|%foo->{'bar'}|;
    is([ lex($test) ], [qw( %foo -> { 'bar' } )], "Quoted string key: $test");

    $test = q|%foo->{'b->ar'}|;
    is([ lex($test) ], [qw( %foo -> { 'b->ar' } )], "Quoted arrow: $test");

    $test = q|%foo->{'b}ar'}|;
    is([ lex($test) ], [qw( %foo -> { 'b}ar' } )], "Brace in string: $test");

    $test = q|%foo->{b\}ar}|;
    is([ lex($test) ], [qw( %foo -> { b}ar } )], "Escaped brace: $test");

    $test = q|%foo->{'b\}ar'}|;
    is([ lex($test) ], [qw( %foo -> { 'b}ar' } )], "Escaped brace in string: $test");

    $test = q|%foo->{}|;
    is([ lex($test) ], [qw( %foo -> { } )], "Empty key: $test");

    $test = q|%foo->{ba\'r}|;
    is([ lex($test) ], [qw( %foo -> { ba'r } )], "Escaped quote: $test");

    $test = q|%foo->{bar}->[-2]->{foo}->{blorg}->[22]|;
    is([ lex($test) ], [qw( %foo -> { bar } -> [ -2 ] -> { foo } -> { blorg } -> [ 22 ])], "Deep access: $test");

    $test = q|%foo->{$bar}|;
    is([ lex($test) ], [qw( %foo -> { $bar } )], "Nested vars: $test");

    $test = q|%foo->{$bar->[-1]}|;
    is([ lex($test) ], [qw( %foo -> { $bar -> [ -1 ] } )], "Nested vars with nested access: $test");
};

subtest invalid_lexes => sub {
    like(
        dies { lex("") },
        qr/invalid syntax: empty query/,
        "empty query exception"
    );

    like(
        dies { lex("foobar") },
        qr/invalid syntax: query must start with a Perl symbol/,
        "missing sigil at start"
    );

    like(
        dies { lex(q|$foobar->{'foo}|) },
        qr/invalid syntax: unclosed string/,
        "unclosed string"
    );
};

subtest valid_parses => sub {
    for my $test (qw($foo @foo %foo)) {
        is(parse($test), [SYMBOL, $test], "Symbol '$test'");
    }

    my $test = q|%foo->{'bar'}|;
    is(parse($test),
        [OP_ACCESS, [
            [SYMBOL, '%foo'],
            [OP_HASHKEY,
                [STRING, 'bar']]]],
        "$test"
    );

    $test = q|@foo->[3]|;
    is(parse($test),
        [OP_ACCESS, [
            [SYMBOL, '@foo'],
            [OP_ARRAYINDEX,
                [NUMBER, 3]]]],
        "$test"
    );

    $test = q|$foo->[0]|;
    is(parse($test),
        [OP_ACCESS, [
            [SYMBOL, '$foo'],
            [OP_ARRAYINDEX,
                [NUMBER, 0]]]],
        "$test"
    );

    $test = q|$foo->{0}|;
    is(parse($test),
        [OP_ACCESS, [
            [SYMBOL, '$foo'],
            [OP_HASHKEY,
                [NUMBER, 0]]]],
        "$test"
    );

    $test = q|%foo->{$bar}|;
    is(parse($test),
        [OP_ACCESS, [
            [SYMBOL, '%foo'],
            [OP_HASHKEY,
                [SYMBOL, '$bar']]]],
        "$test"
    );

    $test = q|%foo->{'bar'}->[-2]->{'baz'}|;
    is(parse($test),
        [OP_ACCESS, [
            [OP_ACCESS, [
                [OP_ACCESS, [
                    [SYMBOL, '%foo'],
                    [OP_HASHKEY,
                        [ STRING, 'bar']]]],
                [OP_ARRAYINDEX,
                    [ NUMBER, -2]]]],
            [OP_HASHKEY,
                [STRING, 'baz']]]],
        "$test"
    );

    $test = q|%foo->{$bar->[0]}|;
    is(parse($test),
        [OP_ACCESS, [
            [SYMBOL, '%foo'],
            [OP_HASHKEY,
                [OP_ACCESS, [
                    [SYMBOL, '$bar'],
                    [OP_ARRAYINDEX,
                        [NUMBER, 0]]]]]]],
        "$test"
    );
};

subtest invalid_parses => sub {
    like(
        dies { parse(q|$fo#obar|) },
        qr/invalid symbol: "\$fo#obar". symbols must start with a Perl sigil \(.+\) and contain only word characters/,
        "invalid symbol"
    );

    like(
        dies { parse(q|$foobar->|) },
        qr/invalid syntax: '->' needs something on the right hand side/,
        "dangling access"
    );

    like(
        dies { parse(q|$foobar->#|) },
        qr/invalid syntax: -> expects either hash key "\{'foo'\}" or array index "\[0\]" on the right hand side/,
        "access weird right hand side"
    );

    like(
        dies { parse(q|$foobar->{bar}|) },
        qr/unrecognized token 'bar'\. hash key strings must be quoted with single quotes/,
        "unquoted hash key"
    );

    like(
        dies { parse(q|$foobar->{'baz'|) },
        qr/invalid syntax: unclosed hash key/,
        "dangling brace"
    );

    like(
        dies { parse(q|$foobar->[0|) },
        qr/invalid syntax: unclosed array index/,
        "dangling bracket"
    );
};

done_testing;
