use Test::More;

use JSON::Lines;

my $jsonl = JSON::Lines->new(
	canonical => 1,
);

# Test: Multiple JSON objects on a single line (no newlines between them)
# This is the case when streaming output concatenates multiple JSON objects
subtest 'multiple objects on single line' => sub {
	my $string = q|{"type":"init","id":1}{"type":"message","id":2}{"type":"result","id":3}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 3, 'decoded 3 objects from single line');
	is_deeply($data[0], { type => 'init', id => 1 }, 'first object correct');
	is_deeply($data[1], { type => 'message', id => 2 }, 'second object correct');
	is_deeply($data[2], { type => 'result', id => 3 }, 'third object correct');
};

# Test: Mixed - some on same line, some on separate lines
subtest 'mixed single and multi-line' => sub {
	my $string = qq|{"a":1}{"b":2}\n{"c":3}\n{"d":4}{"e":5}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 5, 'decoded 5 objects from mixed input');
	is_deeply(\@data, [
		{ a => 1 },
		{ b => 2 },
		{ c => 3 },
		{ d => 4 },
		{ e => 5 },
	], 'all objects decoded correctly');
};

# Test: Objects with nested structures on single line
subtest 'nested objects on single line' => sub {
	my $string = q|{"outer":{"inner":"value"}}{"list":[1,2,3]}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 2, 'decoded 2 nested objects');
	is_deeply($data[0], { outer => { inner => 'value' } }, 'nested object correct');
	is_deeply($data[1], { list => [1, 2, 3] }, 'list object correct');
};

# Test: Objects with escaped quotes in strings
subtest 'objects with escaped quotes' => sub {
	my $string = q|{"msg":"hello \"world\""}{"msg":"test"}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 2, 'decoded 2 objects with escaped quotes');
	is_deeply($data[0], { msg => 'hello "world"' }, 'escaped quotes preserved');
	is_deeply($data[1], { msg => 'test' }, 'second object correct');
};

# Test: Objects with brackets in strings (should not confuse parser)
subtest 'brackets inside strings' => sub {
	my $string = q|{"code":"if (x) { y }"}{"code":"[1,2]"}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 2, 'decoded 2 objects with brackets in strings');
	is_deeply($data[0], { code => 'if (x) { y }' }, 'brackets in string preserved');
	is_deeply($data[1], { code => '[1,2]' }, 'array-like string preserved');
};

# Test: Arrays on single line
subtest 'arrays on single line' => sub {
	my $string = q|[1,2,3][4,5,6]["a","b"]|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 3, 'decoded 3 arrays from single line');
	is_deeply($data[0], [1, 2, 3], 'first array correct');
	is_deeply($data[1], [4, 5, 6], 'second array correct');
	is_deeply($data[2], ['a', 'b'], 'third array correct');
};

# Test: Mixed arrays and objects on single line
subtest 'mixed arrays and objects' => sub {
	my $string = q|{"type":"data"}[1,2,3]{"type":"end"}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 3, 'decoded 3 mixed items');
	is_deeply($data[0], { type => 'data' }, 'first object correct');
	is_deeply($data[1], [1, 2, 3], 'array correct');
	is_deeply($data[2], { type => 'end' }, 'last object correct');
};

# Test: Whitespace between objects on same line
subtest 'whitespace between objects' => sub {
	my $string = q|{"a":1}  {"b":2}   {"c":3}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 3, 'decoded 3 objects with whitespace between');
	is_deeply(\@data, [{ a => 1 }, { b => 2 }, { c => 3 }], 'all correct');
};

# Test: Empty input
subtest 'empty input' => sub {
	my @data = $jsonl->decode('');
	is(scalar @data, 0, 'empty string returns empty array');

	@data = $jsonl->decode('   ');
	is(scalar @data, 0, 'whitespace-only returns empty array');
};

# Test: Single object (regression test)
subtest 'single object still works' => sub {
	my $string = q|{"single":"object"}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 1, 'decoded 1 object');
	is_deeply($data[0], { single => 'object' }, 'object correct');
};

# Test: Traditional newline-separated format still works
subtest 'traditional newline format' => sub {
	my $string = qq|{"line":1}\n{"line":2}\n{"line":3}|;

	my @data = $jsonl->decode($string);

	is(scalar @data, 3, 'decoded 3 newline-separated objects');
	is_deeply(\@data, [
		{ line => 1 },
		{ line => 2 },
		{ line => 3 },
	], 'all objects correct');
};

# Test: error_cb is called for invalid JSON within multi-object line
subtest 'error callback with multi-object' => sub {
	my @errors;
	my $jsonl_with_cb = JSON::Lines->new(
		error_cb => sub {
			my ($action, $error, $data) = @_;
			push @errors, { action => $action, error => $error };
			return undef;
		},
	);

	# Valid objects should still be parsed even with garbage between
	my $string = q|{"valid":1}not-json{"valid":2}|;
	my @data = $jsonl_with_cb->decode($string);

	is(scalar @data, 2, 'decoded valid objects, skipped garbage');
	is_deeply($data[0], { valid => 1 }, 'first valid object');
	is_deeply($data[1], { valid => 2 }, 'second valid object');
};

done_testing();
