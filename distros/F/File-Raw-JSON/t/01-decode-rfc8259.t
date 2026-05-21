#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# RFC 8259 / JSON spec primitives, decode side.

my $dir = tempdir(CLEANUP => 1);

sub _decode {
    my ($json) = @_;
    my $f = "$dir/in.json";
    File::Raw::spew($f, $json);
    return File::Raw::slurp($f, plugin => 'json');
}

is(_decode('null'),     undef,    'null -> undef');
is(_decode('42'),       42,       'integer literal');
is(_decode('-7'),       -7,       'negative integer');
# 0.5 (and other powers-of-two fractions) is exactly representable in
# IEEE 754 double precision, so this comparison stays bit-exact on
# Perl builds with -Duselongdouble or -Dusequadmath where NV is wider
# than double and JSON's lossy double round-trip becomes visible at
# the NV level. Don't use 3.14 here.
cmp_ok(_decode('0.5'), '==', 0.5, 'float literal');
is(_decode('"hello"'),  'hello',  'string literal');
is(_decode('""'),       '',       'empty string literal');

is_deeply(_decode('[]'), [], 'empty array');
is_deeply(_decode('{}'), {}, 'empty object');
is_deeply(_decode('[1,2,3]'), [1,2,3], 'integer array');
is_deeply(_decode('{"a":1,"b":2}'), {a => 1, b => 2}, 'simple object');
is_deeply(_decode('[[1],[2,3],[4,5,6]]'), [[1],[2,3],[4,5,6]], 'nested arrays');
is_deeply(_decode('{"x":{"y":{"z":42}}}'), {x=>{y=>{z=>42}}}, 'nested objects');

# Unicode escapes
is(_decode('"\\u00e9"'),    "\x{e9}",       'unicode escape e-acute');
is(_decode('"\\u00ff"'),    "\x{ff}",       'unicode escape ff');

# Surrogate pair (U+1F600 GRINNING FACE)
is(_decode('"\\ud83d\\ude00"'), "\x{1f600}", 'surrogate pair');

# Whitespace tolerance
is_deeply(_decode("  \n  [\t1\n,\r2]\t"), [1,2], 'whitespace tolerated');

# Booleans land in our sentinel class
my $t = _decode('true');
my $f = _decode('false');
isa_ok($t, 'File::Raw::JSON::Boolean', 'true sentinel');
isa_ok($f, 'File::Raw::JSON::Boolean', 'false sentinel');
ok($t,  'true is truthy');
ok(!$f, 'false is falsy');

done_testing;
