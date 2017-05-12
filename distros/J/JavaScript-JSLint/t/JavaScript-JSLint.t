#!/usr/bin/perl -w

use strict;

use Data::Dumper;
use Test::More tests => 17;

BEGIN {
    use_ok( 'JavaScript::JSLint' );
}

eval { jslint() };
like( $@, qr/usage/, 'jslint() provokes usage message' );

my @tests = (
    {
        name   => 'empty',
        js     => '',
        opts   => {},
        errors => [],
    },
    {
        name     => 'basic',
          js     => 'var two = 1 + 1;',
          opts   => {},
          errors => [],
    },
    {
        name   => 'strict whitespace',
        js     => 'var two = 1+1;',
        opts   => {},
        errors => [
            {
                'id'        => '(error)',
                'line'      => 1,
                'character' => 12,
                'evidence'  => 'var two = 1+1;',
                'reason'    => "Missing space between '1' and '+'.",
                'raw'       => "Missing space between '{a}' and '{b}'.",
                'a'         => '1',
                'b'         => '+',
                'c'         => undef,
                'd'         => undef,
            },
            {
                'id'        => '(error)',
                'line'      => 1,
                'character' => 13,
                'evidence'  => 'var two = 1+1;',
                'reason'    => "Missing space between '+' and '1'.",
                'raw'       => "Missing space between '{a}' and '{b}'.",
                'a'         => '+',
                'b'         => '1',
                'c'         => undef,
                'd'         => undef,
            },
        ],
    },
    {
        name   => 'missing semicolon',
        js     => 'var two = 1 + 1',
        opts   => {},
        errors => [
            {
                'id'        => '(error)',
                'line'      => 1,
                'character' => 16,
                'evidence'  => 'var two = 1 + 1',
                'reason'    => "Expected ';' and instead saw '(end)'.",
                'raw'       => "Expected '{a}' and instead saw '{b}'.",
                'a'         => ';',
                'b'         => '(end)',
                'c'         => undef,
                'd'         => undef,
            }
        ],
    },
    {
        name   => 'missing semicolon and late declaration',
        js     => 'two = 1 + 1; var two',
        opts   => {},
        errors => [
            {
                'id'        => '(error)',
                'line'      => 1,
                'character' => 1,
                'evidence'  => 'two = 1 + 1; var two',
                'reason'    => "'two' was used before it was defined.",
                'raw'       => "'{a}' was used before it was defined.",
                'a'         => 'two',
                'b'         => undef,
                'c'         => undef,
                'd'         => undef,
            },
            {
                'id'        => '(error)',
                'line'      => 1,
                'character' => 21,
                'evidence'  => 'two = 1 + 1; var two',
                'reason'    => "Expected ';' and instead saw '(end)'.",
                'raw'       => "Expected '{a}' and instead saw '{b}'.",
                'a'         => ';',
                'b'         => '(end)',
                'c'         => undef,
                'd'         => undef,
            },
        ],
    },
    {
        name   => 'nested comment, like prototype.js',
        js     => "/* nested\n/* comment */",
        opts   => {},
        errors => [
            {
                'id'        => '(error)',
                'line'      => 2,
                'character' => 3,
                'evidence'  => '/* comment */',
                'reason'    => 'Nested comment.',
                'raw'       => 'Nested comment.',
                'a'         => undef,
                'b'         => undef,
                'c'         => undef,
                'd'         => undef,

            },
            {
                'line'      => 2,
                'character' => 3,
                'reason'    => 'Stopping.  (100% scanned).'
            }
        ],
    },
    {
        name   => 'disallow undefined variables by default',
        js     => 'alert(42);',
        opts   => {},
        errors => [
            {
                'id'        => '(error)',
                'line'      => 1,
                'character' => 1,
                'evidence'  => 'alert(42);',
                'reason'    => "'alert' was used before it was defined.",
                'raw'       => "'{a}' was used before it was defined.",
                'a'         => 'alert',
                'b'         => undef,
                'c'         => undef,
                'd'         => undef,
            }
        ],
    },
    {
        name   => 'allow undefined variables with undef option',
        js     => 'alert(42);',
        opts   => { 'undef' => 1 },
        errors => [],
    },
    {
        name   => 'allow predefined variables with predef array',
        js     => 'alert(42);',
        opts   => { 'predef' => ['alert'] },
        errors => [],
    },
    {
        name   => 'allow predefined variables with predef option as object',
        js     => 'alert(42);',
        opts   => { 
            'predef' => {
                'alert' => 0,
            },
        },
        errors => [],
    },
    {
        name   => 'allow overwrite of predefined variables with truthy value',
        js     => 'alert = "foo";',
        opts   => { 
            'predef' => {
                'alert' => 1,
            },
        },
        errors => [],
    },
    {
        name   => 'disallow overwrite of predefined variables with false value',
        js     => 'alert = "foo";',
        opts   => { 
            'predef' => {
                'alert' => 0,
            },
        },
        errors => [
            {
                'id'        => '(error)',
                'line'      => 1,
                'character' => 1,
                'evidence'  => 'alert = "foo";',
                'reason'    => 'Read only.',
                'raw'       => 'Read only.',
                'a'         => 'alert',
                'b'         => undef,
                'c'         => undef,
                'd'         => undef,
            },
        ],
    },
    {
        name   => 'unknown options allowed',
        js     => 'alert(42);',
        opts   => { xyzzy => 1, devel => 1 },
        errors => [],
    },
    {
        name   => 'embedded in html',
        js     => '<html><head><script type="text/javascript">alert(42);</script></head></html>',
        opts   => { devel => 1, white => 1 },
        errors => [],
    },
    {
        name   => 'DOM Level 0 event handlers not allowed',
        js     => '<html><body><a onclick="alert(42);">click here</a></body></html>',
        opts   => { devel => 1, white => 1 },
        errors => [
            {
                'id'        => '(error)',
                'line'      => 1,
                'character' => 23,
                'evidence'  => '<html><body><a onclick="alert(42);">click here</a></body></html>',
                'reason'    => 'Avoid HTML event handlers.',
                'raw'       => 'Avoid HTML event handlers.',
                'a'         => '=',
                'b'         => undef,
                'c'         => undef,
                'd'         => undef,
            }
        ],
    },
);

foreach my $t ( @tests ) {
    my @got = jslint( $t->{ js }, %{ $t->{ opts } } );
    is_deeply( \@got, $t->{ errors }, $t->{ name } )
      or diag(
        Data::Dumper->new( [ \@got ], ['*errors'] )->Indent( 1 )->Sortkeys( 1 )
          ->Dump );
}

# vim: set ai et sw=4 syntax=perl :
