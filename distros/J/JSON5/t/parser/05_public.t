use strict;
use warnings;
use utf8;

use Test::More 0.98;
use Test::Base::Less;

use JSON::PP;
use JSON5;
use JSON5::Parser;

my $json = JSON::PP->new->allow_nonref->utf8;
Test::Base::Less::register_filter(json => sub { $json->decode($_[0]) });

filters {
    expected => [qw/json/],
};

my $parser = JSON5::Parser->new
    ->inflate_nan(sub { "<<<SPECIAL VALUE:NaN>>>" })
    ->inflate_infinity(sub { "<<<SPECIAL VALUE:$_[0]Infinity>>>" })
    ->allow_nonref
    ->utf8;
for my $block (blocks) {
    my $parsed = eval { $parser->parse($block->input) };
    is_deeply $parsed, $block->expected, $block->get_section('name')
        or diag $block->input;
    diag $@ if $@;
}

done_testing;

__DATA__
===
--- name: arrays - trailing-comma-array
--- input
[
    null,
]
--- expected
[null]
===
--- name: comments - block-comment-following-top-level-value
--- input
null
/*
    Some non-comment top-level value is needed;
    we use null above.
*/
--- expected
null
===
--- name: comments - block-comment-preceding-top-level-value
--- input
/*
    Some non-comment top-level value is needed;
    we use null below.
*/
null
--- expected
null
===
--- name: comments - inline-comment-preceding-top-level-value
--- input
// Some non-comment top-level value is needed; we use null below.
null
--- expected
null
===
--- name: comments - block-comment-following-array-element
--- input
[
    false
    /*
        true
    */
]
--- expected
[false]
===
--- name: comments - inline-comment-following-array-element
--- input
[
    false   // true
]
--- expected
[false]
===
--- name: comments - block-comment-with-asterisks
--- input
/**
 * This is a JavaDoc-like block comment.
 * It contains asterisks inside of it.
 * It might also be closed with multiple asterisks.
 * Like this:
 **/
true
--- expected
true
===
--- name: comments - inline-comment-following-top-level-value
--- input
null // Some non-comment top-level value is needed; we use null here.
--- expected
null
===
--- name: misc - readme-example
--- input
{
    foo: 'bar',
    while: true,

    this: 'is a \
multi-line string',

    // this is an inline comment
    here: 'is another', // inline comment

    /* this is a block comment
       that continues on another line */

    hex: 0xDEADbeef,
    half: .5,
    delta: +10,
    to: Infinity,   // and beyond!

    finally: 'a trailing comma',
    oh: [
        "we shouldn't forget",
        'arrays can have',
        'trailing commas too',
    ],
}

--- expected
{"foo":"bar","while":true,"this":"is a multi-line string","here":"is another","hex":3735928559,"half":0.5,"delta":10,"to":"<<<SPECIAL VALUE:+Infinity>>>","finally":"a trailing comma","oh":["we shouldn't forget","arrays can have","trailing commas too"]}
===
--- name: misc - valid-whitespace
--- input
{
    // An invalid form feed character (\x0c) has been entered before this comment.
    // Be careful not to delete it.
  "a": true
}

--- expected
{"a":true}
===
--- name: new-lines - escaped-cr
--- input
{    // the following string contains an escaped `\r`    a: 'line 1 \line 2'}
--- expected
{"a":"line 1 line 2"}
===
--- name: new-lines - comment-lf
--- input
{
    // This comment is terminated with `\n`.
}

--- expected
{}
===
--- name: new-lines - escaped-crlf
--- input
{
    // the following string contains an escaped `\r\n`
    a: 'line 1 \
line 2'
}

--- expected
{"a":"line 1 line 2"}
===
--- name: new-lines - comment-cr
--- input
{    // This comment is terminated with `\r`.}
--- expected
{}
===
--- name: new-lines - escaped-lf
--- input
{
    // the following string contains an escaped `\n`
    a: 'line 1 \
line 2'
}

--- expected
{"a":"line 1 line 2"}
===
--- name: new-lines - comment-crlf
--- input
{
    // This comment is terminated with `\r\n`.
}

--- expected
{}
===
--- name: numbers - negative-zero-hexadecimal
--- input
-0x0

--- expected
0
===
--- name: numbers - positive-integer
--- input
+15

--- expected
15
===
--- name: numbers - zero-float-leading-decimal-point
--- input
.0

--- expected
0
===
--- name: numbers - hexadecimal-with-integer-exponent
--- input
0xc8e4

--- expected
51428
===
--- name: numbers - negative-hexadecimal
--- input
-0xC8

--- expected
-200
===
--- name: numbers - positive-float-leading-decimal-point
--- input
+.5

--- expected
0.5
===
--- name: numbers - zero-hexadecimal
--- input
0x0

--- expected
0
===
--- name: numbers - infinity
--- input
Infinity

--- expected
"<<<SPECIAL VALUE:+Infinity>>>"
===
--- name: numbers - hexadecimal-uppercase-x
--- input
0XC8

--- expected
200
===
--- name: numbers - float-trailing-decimal-point
--- input
5.

--- expected
5
===
--- name: numbers - positive-zero-integer
--- input
+0

--- expected
0
===
--- name: numbers - float-trailing-decimal-point-with-integer-exponent
--- input
5.e4

--- expected
50000
===
--- name: numbers - nan
--- input
NaN

--- expected
"<<<SPECIAL VALUE:NaN>>>"
===
--- name: numbers - negative-float-trailing-decimal-point
--- input
-5.

--- expected
-5
===
--- name: numbers - hexadecimal
--- input
0xC8

--- expected
200
===
--- name: numbers - positive-zero-hexadecimal
--- input
+0x0

--- expected
0
===
--- name: numbers - positive-zero-float
--- input
+0.0

--- expected
0
===
--- name: numbers - negative-zero-float-trailing-decimal-point
--- input
-0.

--- expected
0
===
--- name: numbers - negative-infinity
--- input
-Infinity

--- expected
"<<<SPECIAL VALUE:-Infinity>>>"
===
--- name: numbers - positive-hexadecimal
--- input
+0xC8

--- expected
200
===
--- name: numbers - float-leading-decimal-point
--- input
.5

--- expected
0.5
===
--- name: numbers - positive-zero-float-trailing-decimal-point
--- input
+0.

--- expected
0
===
--- name: numbers - negative-float-leading-decimal-point
--- input
-.5

--- expected
-0.5
===
--- name: numbers - negative-zero-float-leading-decimal-point
--- input
-.0

--- expected
0
===
--- name: numbers - positive-float-trailing-decimal-point
--- input
+5.

--- expected
5
===
--- name: numbers - hexadecimal-lowercase-letter
--- input
0xc8

--- expected
200
===
--- name: numbers - positive-zero-float-leading-decimal-point
--- input
+.0

--- expected
0
===
--- name: numbers - positive-float-leading-zero
--- input
+0.5

--- expected
0.5
===
--- name: numbers - zero-float-trailing-decimal-point
--- input
0.

--- expected
0
===
--- name: numbers - positive-infinity
--- input
+Infinity

--- expected
"<<<SPECIAL VALUE:+Infinity>>>"
===
--- name: numbers - positive-float
--- input
+1.2

--- expected
1.2
===
--- name: objects - single-quoted-key
--- input
{
    'hello': "world"
}
--- expected
{"hello":"world"}
===
--- name: objects - trailing-comma-object
--- input
{
    "foo": "bar",
}
--- expected
{"foo":"bar"}
===
--- name: objects - reserved-unquoted-key
--- input
{
    while: true
}
--- expected
{"while":true}
===
--- name: objects - unquoted-keys
--- input
{
    hello: "world",
    _: "underscore",
    $: "dollar sign",
    one1: "numerals",
    _$_: "multiple symbols",
    $_$hello123world_$_: "mixed"
}
--- expected
{"hello":"world","_":"underscore","$":"dollar sign","one1":"numerals","_$_":"multiple symbols","$_$hello123world_$_":"mixed"}
===
--- name: strings - single-quoted-string
--- input
'hello world'
--- expected
"hello world"
===
--- name: strings - multi-line-string
--- input
'hello\
 world'
--- expected
"hello world"
===
--- name: strings - escaped-single-quoted-string
--- input
'I can\'t wait'
--- expected
"I can't wait"
