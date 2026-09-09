#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More tests => 45;
use JSON::PP ();
use Data::Dumper;

use JQ::XS qw(JQ_DEBUG_TRACE JQ_DEBUG_TRACE_DETAIL JQ_DEBUG_TRACE_ALL);
BEGIN { use_ok('JQ::XS'); }

# Test constants
is(JQ_DEBUG_TRACE, 1, 'JQ_DEBUG_TRACE constant');
is(JQ_DEBUG_TRACE_DETAIL, 2, 'JQ_DEBUG_TRACE_DETAIL constant');
is(JQ_DEBUG_TRACE_ALL, 3, 'JQ_DEBUG_TRACE_ALL constant');

# Test simple identity filter
my $jq = JQ::XS->new('.');
isa_ok($jq, 'JQ::XS', 'new() returns JQ::XS object');

# Test program accessor
is($jq->program, '.', 'program() returns the source');

# Test identity roundtrip with scalar
my @result = $jq->process(42);
is_deeply(\@result, [42], 'scalar identity roundtrip');

# Test identity roundtrip with string
@result = $jq->process('hello');
is_deeply(\@result, ['hello'], 'string identity roundtrip');

# Test identity roundtrip with undef/null
@result = $jq->process(undef);
is_deeply(\@result, [undef], 'null identity roundtrip');

# Test identity roundtrip with nested hash
my $data = { foo => [1, 2, 3], bar => 'baz' };
@result = $jq->process($data);
is_deeply(\@result, [$data], 'nested hash identity roundtrip');

# Test identity roundtrip with float
@result = $jq->process(3.14);
is_deeply(\@result, [3.14], 'float identity roundtrip');

# Test array iteration
$jq = JQ::XS->new('.[]');
@result = $jq->process([1, 2, 3]);
is_deeply(\@result, [1, 2, 3], 'array iteration with .[]');

# Test filter on array
$jq = JQ::XS->new('.[] | select(. > 2)');
@result = $jq->process([1, 3, 5]);
is_deeply(\@result, [3, 5], 'array filter with select');

# Test nested object access
$jq = JQ::XS->new('.users[].name');
@result = $jq->process({ users => [{name => 'Alice'}, {name => 'Bob'}] });
is_deeply(\@result, ['Alice', 'Bob'], 'nested object access');

# Test process_json with JSON input
$jq = JQ::XS->new('.foo');
@result = $jq->process_json('{"foo": 42}');
is_deeply(\@result, ['42'], 'process_json with JSON object');

# Test process_json with array
$jq = JQ::XS->new('.');
@result = $jq->process_json('[1, 2, 3]');
is_deeply(\@result, ['[1,2,3]'], 'process_json returns JSON string');

# Test UTF-8 string roundtrip
$jq = JQ::XS->new('.');
@result = $jq->process('héllo ☃');
is_deeply(\@result, ['héllo ☃'], 'UTF-8 string roundtrip');

# Test UTF-8 hash keys roundtrip
$jq = JQ::XS->new('.');
my $utf8_hash = { 'café' => 'naïve' };
@result = $jq->process($utf8_hash);
is_deeply(\@result, [$utf8_hash], 'UTF-8 hash keys roundtrip');

# Test compile error croaks
eval { JQ::XS->new('.[') };
like($@, qr/jq compile error/, 'compile error croaks');

# Test invalid JSON croaks
$jq = JQ::XS->new('.');
eval { $jq->process_json('not json') };
like($@, qr/Invalid JSON|parse error/i, 'invalid JSON croaks');

# Test runtime error croaks
$jq = JQ::XS->new('error("boom")');
eval { $jq->process(42) };
like($@, qr/jq runtime error/, 'runtime error croaks');

# Test two independent objects
my $jq1 = JQ::XS->new('.x');
my $jq2 = JQ::XS->new('.y');
my @r1 = $jq1->process({ x => 1 });
my @r2 = $jq2->process({ y => 2 });
is_deeply(\@r1, [1], 'first independent object');
is_deeply(\@r2, [2], 'second independent object');

# Test object destruction doesn't crash
{
  my $temp = JQ::XS->new('.');
  # temp is destroyed here
}
pass('object destruction completes');

# Test scalar context returns arrayref
$jq = JQ::XS->new('.');
my $ref = scalar($jq->process(42));
is(ref($ref), 'ARRAY', 'scalar context returns arrayref');
is_deeply($ref, [42], 'arrayref content is correct');

# Test complex nested data
$jq = JQ::XS->new('.');
my $complex = {
  array => [1, 2.5, 'three'],
  nested => { deep => { value => 42 } },
  null => undef,
  bool_true => 1,
  bool_false => 0,
};
@result = $jq->process($complex);
is_deeply(\@result, [$complex], 'complex nested data roundtrip');

# --- Boolean support ---

# jq results that are booleans come back as JSON::PP::Boolean objects
$jq = JQ::XS->new('. > 2');
@result = $jq->process(5);
isa_ok($result[0], 'JSON::PP::Boolean', 'true result');
ok($result[0], 'true result is true in boolean context');
is_deeply(\@result, [JSON::PP::true], 'true result equals JSON::PP::true');

@result = $jq->process(1);
isa_ok($result[0], 'JSON::PP::Boolean', 'false result');
ok(!$result[0], 'false result is false in boolean context');
is_deeply(\@result, [JSON::PP::false], 'false result equals JSON::PP::false');

# JSON::PP::Boolean input is seen as a JSON boolean by jq
$jq = JQ::XS->new('type');
@result = $jq->process(JSON::PP::true);
is_deeply(\@result, ['boolean'], 'JSON::PP::true input has jq type boolean');
@result = $jq->process(JSON::PP::false);
is_deeply(\@result, ['boolean'], 'JSON::PP::false input has jq type boolean');

# \1 and \0 scalar references are booleans
@result = $jq->process(\1);
is_deeply(\@result, ['boolean'], '\\1 input has jq type boolean');
@result = $jq->process(\0);
is_deeply(\@result, ['boolean'], '\\0 input has jq type boolean');

$jq = JQ::XS->new('.');
is_deeply([$jq->process(\1)], [JSON::PP::true], '\\1 roundtrips as true');
is_deeply([$jq->process(\0)], [JSON::PP::false], '\\0 roundtrips as false');

# Perl native booleans (PL_sv_yes / PL_sv_no) are booleans
$jq = JQ::XS->new('type');
@result = $jq->process(1 == 1);
is_deeply(\@result, ['boolean'], 'PL_sv_yes (1 == 1) has jq type boolean');
@result = $jq->process(1 == 0);
is_deeply(\@result, ['boolean'], 'PL_sv_no (1 == 0) has jq type boolean');
@result = $jq->process(!!1);
is_deeply(\@result, ['boolean'], '!!1 has jq type boolean');

$jq = JQ::XS->new('.');
is_deeply([$jq->process(2 > 1)], [JSON::PP::true], 'native true roundtrips as true');
is_deeply([$jq->process(2 < 1)], [JSON::PP::false], 'native false roundtrips as false');

# booleans nested inside structures roundtrip
my $bool_data = { yes => JSON::PP::true, no => \0, list => [\1, JSON::PP::false] };
@result = $jq->process($bool_data);
is_deeply(
  \@result,
  [{ yes => JSON::PP::true, no => JSON::PP::false, list => [JSON::PP::true, JSON::PP::false] }],
  'nested booleans roundtrip as JSON::PP::Boolean'
);

