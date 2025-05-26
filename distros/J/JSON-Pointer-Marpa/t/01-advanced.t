use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is is_deeply use_ok ) ], tests => 20;

my $class;

BEGIN {
  $class = 'JSON::Pointer::Marpa';
  use_ok $class or BAIL_OUT "Cannot load class '$class'!";
}

# "get" (hash)
is_deeply $class->get( { foo => 'bar' }, '' ), { foo => 'bar' }, "'' is '{ foo => 'bar' }'";
is $class->get( { foo => 'bar' }, '/foo' ), 'bar', "'/foo' is 'bar'";
is $class->get( { foo => { bar => 42 } }, '/foo/bar' ), 42, "'/foo/bar' is '42'";
is_deeply $class->get( { foo => { 23 => { baz => 0 } } }, '/foo/23' ), { baz => 0 }, "'/foo/23' is '{ baz => 0 }'";
is_deeply $class->get(
  { operator => { '-' => { name => 'minus', type => 'number' }, '.' => { name => 'concat', type => 'string' } } },
  '/operator/-' ),
  { name => 'minus', 'type' => 'number' }, "'/operator/-' is '{ name => 'minus', type => 'number' }'";

# "get" (mixed)
is_deeply $class->get( { foo => { bar => [ 1, 2, 3 ] } }, '/foo/bar' ), [ 1, 2, 3 ], "'/foo/bar' is '[ 1, 2, 3 ]'";
is $class->get( { foo => { bar => [ 0, undef, 3 ] } }, '/foo/bar/0' ), 0,     "'/foo/bar/0' is '0'";
is $class->get( { foo => { bar => [ 0, undef, 3 ] } }, '/foo/bar/1' ), undef, "'/foo/bar/1' is 'undef'";
is $class->get( { foo => { bar => [ 0, undef, 3 ] } }, '/foo/bar/2' ), 3,     "'/foo/bar/2' is '3'";
is $class->get( { foo => { bar => [ 0, undef, 3 ] } }, '/foo/bar/6' ), undef, "'/foo/bar/6' is 'undef'";

# "get" (encoded)
is $class->get( { '♥' => [ 0, 1 ] }, '#/%E2%99%A5/0' ), 0, "'#/%E2%99%A5/0' is '0' (Black Heart Suit)";
is $class->get( [ { '^foob ar'    => 'foo' } ],  '/0/^foob ar' ),            'foo',  "'/0/^foob ar' is 'foo'";
is $class->get( [ { 'foob ar'     => 'foo' } ],  '#/0/foob%20ar' ),          'foo',  "'#/0/foob%20ar' is 'foo'";
is $class->get( [ { 'foo/bar'     => 'bar' } ],  '#/0/foo%2Fbar' ),          undef,  "'/0/foo%2Fbar' is 'undef'";
is $class->get( [ { 'foo/bar'     => 'bar' } ],  '/0/foo~1bar' ),            'bar',  "'/0/foo~1bar' is 'bar'";
is $class->get( [ { 'foo/bar/baz' => 'yada' } ], '/0/foo~1bar~1baz' ),       'yada', "'/0/foo~1bar~1baz' is 'yada'";
is $class->get( [ { 'foo~/bar'    => 'bar' } ],  '/0/foo~0~1bar' ),          'bar',  "'/0/foo~0~1bar' is 'bar'";
is $class->get( [ { 'foo~/bar'    => 'bar' } ],  '#/0/foo%7E%30%7E%31bar' ), 'bar', "'#/0/foo%7E%30%7E%31bar' is 'bar'";
is $class->get( [ { 'f~o~o~/b~'   => { 'a~' => { 'r' => 'baz' } } } ] => '/0/f~0o~0o~0~1b~0/a~0/r' ),
  'baz', "'/0/f~0o~0o~0~1b~0/a~0/r' is 'baz'";
