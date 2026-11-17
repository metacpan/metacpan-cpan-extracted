#!/usr/bin/env perl
# Langertha::Holmgang::Expectation, with the expectation part of cai-platform
# t/eval_world.t ported onto invented data (ADR 0003). Claims: every matcher
# holds and fails where it should, all named matchers must hold, and the reason
# says why; paths take dotted text, segment lists, list indices and {arg};
# argument filters split, int and lc; same_scalar compares numbers numerically,
# text exactly and booleans against 1/0 and true/false.
use strict;
use warnings;
use utf8;
use Test::More;
use Test::Fatal qw( exception );
use JSON::MaybeXS ();

use Langertha::Holmgang::Expectation qw( condition check_value element_match path get flat same_scalar interp_text filter_value );

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

my $s = {
  l => [qw( red green blue )],
  h => [ { chain => 'forward', rule => 'accept' }, { chain => 'input', rule => 'drop' } ],
  n => 1420, t => 'eth0', e => [], u => undef,
  f => { 'a.b' => { x => 1 } },
};
my $ok  = sub { ( condition( $s, $_[0], $_[1] ) )[0] };
my $why = sub { ( condition( $s, $_[0], $_[1] ) )[1] };

ok( $ok->( { path => 'n', equals => '1420' } ), 'equals numerically' );
ok( $ok->( { path => 'n', equals => '1420.0' } ), '... 1420.0 too' );
ok( !$ok->( { path => 't', equals => 'ETH0' } ), 'equals: text exactly' );
ok( $ok->( { path => 't', in => [qw( eth1 eth0 )] } ), 'in' );
ok( !$ok->( { path => 't', in => [qw( eth1 eth2 )] } ), 'in: missing' );
ok( $ok->( { path => 't', regex => '^eth\d$' } ), 'regex' );
ok( $ok->( { path => 't', regex => '(?i)^ETH0$' } ), 'regex with (?i)' );
ok( !$ok->( { path => 'l', regex => 'red' } ), 'regex on a list fails' );
ok( $ok->( { path => 'l', contains => [qw( blue red )] } ), 'contains' );
ok( !$ok->( { path => 'l', contains => ['pink'] } ), 'contains: missing' );
like( $why->( { path => 'l', contains => ['pink'] } ), qr/\Apink missing in \["red","green","blue"\]\z/, '... reason' );
ok( $ok->( { path => 'l', excludes => ['pink'] } ), 'excludes' );
ok( !$ok->( { path => 'l', excludes => ['green'] } ), 'excludes: present' );
ok( !$ok->( { path => 't', contains => ['e'] } ), 'contains on text fails' );
like( $why->( { path => 't', contains => ['e'] } ), qr/\Anot a list/, '... not a list' );
ok( $ok->( { path => 'l', length => 3 } ), 'length of a list' );
ok( $ok->( { path => 'f', length => 1 } ), 'length of a hash' );
ok( !$ok->( { path => 't', length => 4 } ), 'length of text is no length' );
like( $why->( { path => 'l', length => 2 } ), qr/\A3 entries\z/, '... reason' );
ok( $ok->( { path => 'h', any => { chain => '^input$', rule => 'drop' } } ), 'any with fields' );
ok( !$ok->( { path => 'h', any => { chain => '^input$', rule => 'accept' } } ), 'any: all fields of one entry' );
ok( $ok->( { path => 'l', any => '^gr' } ), 'any with a text pattern' );
ok( !$ok->( { path => 'h', none => { rule => 'accept' } } ), 'none hits' );
like( $why->( { path => 'h', none => { rule => 'accept' } } ), qr/\Aunwanted entry: \{"chain":"forward"/, '... reason names the entry' );
ok( $ok->( { path => 'h', none => { rule => 'reject' } } ), 'none' );
ok( $ok->( { path => 'h', before => [ { rule => 'accept' }, { rule => 'drop' } ] } ), 'before' );
ok( !$ok->( { path => 'h', before => [ { rule => 'drop' }, { rule => 'accept' } ] } ), 'before reversed' );
like( $why->( { path => 'h', before => [ { rule => 'drop' }, { rule => 'accept' } ] } ), qr/\Aorder: 1 after 0\z/, '... reason' );
like( $why->( { path => 'h', before => [ { rule => 'x' }, { rule => 'drop' } ] } ), qr/\Afirst entry missing\z/, 'before: first missing' );
like( $why->( { path => 'h', before => [ { rule => 'drop' }, { rule => 'x' } ] } ), qr/\Asecond entry missing\z/, 'before: second missing' );
ok( $ok->( { path => 'x', absent => 1 } ), 'absent' );
ok( $ok->( { path => 'u', absent => 1 } ), 'absent includes null' );
ok( !$ok->( { path => 'u', exists => 0 } ), 'exists: false fails on a null that is there' );
ok( $ok->( { path => 'u', exists => 1 } ), 'exists: a null is there' );
ok( !$ok->( { path => 't', absent => 1 } ), 'absent: present' );
like( $why->( { path => 't', absent => 1 } ), qr/\Apresent: "eth0"\z/, '... reason' );
ok( !$ok->( { path => 'x', equals => 1 } ), 'expectation on a missing path' );
is( $why->( { path => 'x', equals => 1 } ), 'missing', '... reason' );
ok( $ok->( { path => 'x' } ), 'no matcher: holds' );
is( $why->( { path => 'x' } ), 'not present', '... and says so' );
ok( $ok->( { path => 'l.1', equals => 'green' } ), 'list index in the path' );
ok( !$ok->( { path => 'l.7', exists => 1 } ), 'index out of range' );
ok( $ok->( { path => [ 'f', 'a.b', 'x' ], equals => 1 } ), 'segments with a dot as a list' );
ok( $ok->( { path => 'h', any => { rule => { in => [qw( drop reject )] } } } ), 'a field with expectations' );
ok( $ok->( { path => '{k}', equals => 'eth0' }, { k => 't' } ), '{arg} in the path' );
ok( $ok->( { path => 't', regex => '^{v}$' }, { v => 'eth0' } ), '{arg} in a regex' );
ok( !$ok->( { path => 't', regex => '^{v}$' }, { v => 'eth.' } ), '... put in literally' );
ok( $ok->( { path => 'n', equals => 1420, regex => '^14' } ), 'all named must hold' );
ok( !$ok->( { path => 'n', equals => 1420, regex => '^15' } ), '... one failing is enough' );
ok( $ok->( { path => 'e', length => 0, excludes => ['x'] } ), 'empty list' );

# file entries: the content counts against a text
{
  my $st = { h => { files => { '/a' => { content => "x\n", mode => '0600' }, '/b' => "y\n" } } };
  ok( ( condition( $st, { path => [ 'h', 'files', '/a' ], regex => '^x' } ) )[0], 'regex against an entry with attributes' );
  ok( ( condition( $st, { path => [ 'h', 'files', '/b', 'content' ], equals => "y\n" } ) )[0], '.content fits a bare-text file' );
  ok( ( condition( $st, { path => [ 'h', 'files', '/a', 'mode' ], equals => '0600' } ) )[0], 'an attribute of the entry' );
}

# booleans
{
  my $T = JSON::MaybeXS::true();
  my $F = JSON::MaybeXS::false();
  ok( same_scalar( $T, 1 ), 'true is 1' );
  ok( same_scalar( $T, 'true' ), 'true is "true"' );
  ok( same_scalar( $F, 0 ), 'false is 0' );
  ok( !same_scalar( $F, 'true' ), 'false is not "true"' );
  ok( !same_scalar( 'true', 1 ), 'without a boolean, "true" is only text' );
  ok( !same_scalar( undef, undef ), 'undef matches nothing' );
  ok( !same_scalar( [], [] ), 'references match nothing' );
  ok( same_scalar( '007', 7 ), 'numbers numerically' );
  ok( !same_scalar( '1.0.0', '1.0' ), 'versions as text' );
}

# paths, args, filters
is_deeply( [ path( 'a.b.c', {} ) ], [qw( a b c )], 'path: dotted' );
is_deeply( [ path( [ 'a', '{k}.x' ], { k => 'y' } ) ], [ 'a', 'y.x' ], 'path: list with {arg}' );
like( exception { path( [], {} ) }, qr/empty path/, 'path: empty dies' );
is_deeply( [ get( $s, qw( h 1 rule ) ) ], [ 1, 'drop' ], 'get' );
is_deeply( [ get( $s, qw( t x ) ) ], [0], 'get: through a scalar' );
is( flat( [ 1, undef, 'b' ] ), '1,,b', 'flat: list' );
is( flat( JSON::MaybeXS::true() ), 'true', 'flat: boolean' );
is( flat( { b => 1, a => 2 } ), '{"a":2,"b":1}', 'flat: hash as canonical JSON' );
is( interp_text( 'x={v|lc} n={n|int} {missing}.', { v => 'AbC', n => 'about 12 items' } ), 'x=abc n=12 .', 'interp_text with filters' );
is_deeply( filter_value( ' 10.0.0.1/32,10.0.0.2/32  fe80::1 ', 'split' ), [qw( 10.0.0.1/32 10.0.0.2/32 fe80::1 )], 'split' );
is( filter_value( 'none', 'int' ), 0, 'int without a number: 0' );
is( exception { filter_value( 'x', 'upper' ) }, "dieser Aufruf ist in diesem Szenario nicht vorgesehen.\n",
  'unknown filter dies with the generic refusal, without its name, file or line (k35)' );
ok( element_match( 'abc', '^a' ), 'element_match: text' );
ok( !element_match( { a => 'x' }, '^x' ), 'element_match: a text pattern needs a text element' );
ok( !element_match( 'x', { a => 'x' } ), 'element_match: a field pattern needs a hash element' );
ok( element_match( { tags => [ 'a', 'b' ] }, { tags => '^a,b$' } ), 'element_match: a list field flattened' );
my ( $cv ) = check_value( 1, [ 1, 2 ], { length => 2, title => 'ignored', path => 'ignored' } );
ok( $cv, 'check_value ignores keys that are no matchers' );

done_testing;
