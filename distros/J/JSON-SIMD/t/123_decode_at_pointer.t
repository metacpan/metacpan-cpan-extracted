BEGIN { $| = 1; }

use utf8;
use JSON::SIMD;
use Test::More;
no warnings;


sub selects {
	my ($decoder, $text, $pointer, $expected, $name) = @_;

	my ($actual, $error);
	{
		local $@;
		my $success = eval {
			$actual = $decoder->decode_at_pointer($text, $pointer);
			1;
		};
		$error = $success ? '' : $@;
	}

	is($error, '', "$name: no exception");
	is_deeply($actual, $expected, "$name: value")
		if $error eq '';
	}

sub rejects {
    my ($decoder, $text, $pointer, $name) = @_;

    my ($success, $error);
    {
        local $@;
        $success = eval {
            $decoder->decode_at_pointer($text, $pointer);
            1;                  # Do not confuse false/null with failure.
        };
        $error = $@;
    }

    ok(!$success, "$name: rejected");
    like($error, qr/\S/, "$name: exception supplied");
}

sub test {
	my ($J, $escaped) = @_;

	my $obj = '{
		"foo" : [
			{ "bar": "baz" },
			[ 1, 2, 3 ],
			null
		],
		"quux": true,
		"~/path": "xxx",
		"": "empty key",
		"árvíztűrő": "tükörfúrógép",
		"k\u0065y": "value"
	}';

	my $arr = '[1, {"a": 2}, 3]';

	ok $J->decode_at_pointer($obj, '/foo/1/1') == 2;
	ok $J->decode_at_pointer($obj, '/foo/0/bar') eq "baz";

	ok $J->decode_at_pointer($obj, '/') eq "empty key";

	my $s = $J->decode_at_pointer($obj, '/foo/0');
	ok ref $s eq 'HASH' and exists $s->{bar};

	ok $J->decode_at_pointer($obj, '/~0~1path') eq 'xxx';
	eval {$J->decode_at_pointer($obj, '/~asdff');}; ok $@ =~ /Invalid JSON pointer syntax/;
	eval {$J->decode_at_pointer($obj, '/~');}; ok $@ =~ /Invalid JSON pointer syntax/;

	ok $J->decode_at_pointer($obj, '/árvíztűrő') eq 'tükörfúrógép';

	if ($escaped) {
		ok $J->decode_at_pointer($obj, '/key') eq 'value';
	} else {
		ok $J->decode_at_pointer($obj, '/k\u0065y') eq 'value';
	}

	eval {$J->decode_at_pointer($obj, '/nonexistent/1');}; ok $@ =~ /JSON field referenced does not exist/;
	eval {$J->decode_at_pointer($obj, 'missing /');}; ok $@ =~ /Invalid JSON pointer syntax/;

	ok $J->decode_at_pointer($arr, '/1/a') == 2;
	eval {$J->decode_at_pointer($arr, '/5');}; ok $@ =~ /Attempted to access an element of a JSON array/;
	eval {$J->decode_at_pointer($arr, '/foo');}; ok $@ =~ /The JSON element does not have the requested type/;

	eval {$J->decode_at_pointer($arr, '/-');}; ok $@ =~ /Attempted to access an element of a JSON array/;
	eval {$J->decode_at_pointer($arr, '/001');}; ok $@ =~ /Invalid JSON pointer syntax/;
	eval {$J->decode_at_pointer($arr, '/');}; ok $@ =~ /Invalid JSON pointer syntax/;

	ok $J->decode_at_pointer('1111', '') == 1111;
	eval {$J->decode_at_pointer('1111', '/bar');}; ok $@ =~ /only the empty path is allowed for scalar documents/;
}

test(JSON::SIMD->new->use_simdjson(0), 1);
test(JSON::SIMD->new, 0);



my $document = <<'JSON';
{
    "items": [
        {"name": "first"},
        [10, 20, 30],
        null
    ],
    "": "empty",
    "~/": "escaped",
    "~1": "literal tilde-one",
    "árvíztűrő": "tükörfúrógép",
    "k\u0065y": "decoded key"
}
JSON

for my $native (0, 1) {
    my $j = JSON::SIMD->new->use_simdjson($native);
    my $mode = $native ? 'native' : 'legacy';

    selects($j, $document, '/items/1/1', 20,
            "$mode: zero-based array indices");
    selects($j, $document, '/items/0/name', 'first',
            "$mode: mixed object/array traversal");
    selects($j, $document, '/items/0', {name => 'first'},
            "$mode: selected object");
    selects($j, $document, '/items/1', [10, 20, 30],
            "$mode: selected array");
    selects($j, $document, '/items/2', undef,
            "$mode: selected null");
    selects($j, $document, '/', 'empty',
            "$mode: empty member name");
    selects($j, $document, '/~0~1', 'escaped',
            "$mode: tilde and slash escapes");
    selects($j, $document, '/~01', 'literal tilde-one',
            "$mode: escapes decoded only once");
    selects($j, $document, "/árvíztűrő", "tükörfúrógép",
            "$mode: Unicode member name");

    # Keep the documented backend distinction for JSON-escaped keys.
    selects($j, $document,
            $native ? '/k\u0065y' : '/key',
            'decoded key', "$mode: JSON-escaped member name");

    selects($j, '{"x":[7]}', '', {x => [7]},
            "$mode: whole object");
    selects($j, '[7,8]', '', [7, 8],
            "$mode: whole array");
    selects($j, '17', '', 17,
            "$mode: whole scalar");

    for my $pointer ('missing-slash', '/~', '/~2', '/items/~9') {
        rejects($j, $document, $pointer,
                "$mode: invalid pointer $pointer");
    }

    rejects($j, $document, '/absent/0',
            "$mode: missing member");

    for my $pointer ('/3', '/-', '/', '/001', '/word') {
        rejects($j, '[10,20,30]', $pointer,
                "$mode: invalid array access $pointer");
    }

    rejects($j, '17', '/child',
            "$mode: cannot traverse root number");
}

my $legacy = JSON::SIMD->new->use_simdjson(0);

# Previously dangerous: a scalar reached after a successful lookup.
# eval catches Perl exceptions, NOT segmentation faults.
for my $atom ('123', '"text"', 'null', 'true', 'false') {
    rejects($legacy, qq({"value":$atom}), '/value/child',
            "legacy: cannot traverse nested $atom");
    rejects($legacy, qq([$atom]), '/0/',
            "legacy: empty token still traverses nested $atom");
    rejects($legacy, $atom, '/child',
            "legacy: cannot traverse root $atom");
}

# Empty tokens must not be dropped.
selects($legacy, '{"":{"":9}}', '//', 9,
        'legacy: consecutive empty member names');
selects($legacy, '{"parent":{"":11}}', '/parent/', 11,
        'legacy: trailing empty member name');

# NUL belongs to a token; it is not a path terminator.
selects($legacy, '{"a\\u0000b":41,"a":99}', "/a\0b", 41,
        'legacy: embedded NUL member');
selects($legacy, '{"\\u0000":{"x":42}}', "/\0/x", 42,
        'legacy: traversal after NUL');
rejects($legacy, '{"a":99}', "/a\0missing",
        'legacy: NUL must not truncate a missing member');
rejects($legacy, '[10,20]', "/1\0suffix",
        'legacy: NUL must not truncate an array index');
rejects($legacy, '{"":99}', "/\0~2",
        'legacy: invalid escape after NUL is still checked');

# Strict array syntax, not general Perl numeric syntax.
for my $token ('+1', '-1', ' 1', '1 ', '1.0', '1e0',
               '00', '01', '0x1') {
    rejects($legacy, '[10,20,30]', "/$token",
            "legacy: rejects non-index token [$token]");
}

# The same strings remain perfectly valid object keys.
selects($legacy, '{"01":51,"+1":52,"-":53}', '/01', 51,
        'legacy: leading zero allowed in object key');
selects($legacy, '{"01":51,"+1":52,"-":53}', '/+1', 52,
        'legacy: plus allowed in object key');
selects($legacy, '{"01":51,"+1":52,"-":53}', '/-', 53,
        'legacy: dash allowed in object key');

# Empty-array, signed-conversion, and integer-overflow boundaries.
for my $text ('[]', '[7]') {
    for my $index ('1', '9223372036854775808',
                   '18446744073709551615',
                   '18446744073709551616', ('9' x 200)) {
        rejects($legacy, $text, "/$index",
                "legacy: out-of-range index $index in $text");
    }
}
rejects($legacy, '[]', '/0', 'legacy: index zero in empty array');
selects($legacy, '[7]', '/0', 7, 'legacy: index zero in singleton');

# Long paths and lengths near common allocation boundaries.
for my $length (1, 15, 16, 31, 32, 63, 64, 255, 256, 4096) {
    my $key = 'x' x $length;
    my $text = $legacy->encode({$key => 61});
    my $pointer = "/$key";
    utf8::upgrade($pointer);

    my $shared = $pointer;
    selects($legacy, $text, $pointer, 61,
            "legacy: key length $length");
    is($pointer, $shared, "legacy: path unchanged at length $length");
}

# Do not upgrade the caller's Latin-1 scalar in place.
{
    my $key = chr(0xe9);
    my $pointer = "/$key";
    utf8::downgrade($pointer, 1);

    my $before = $pointer;
    my $was_utf8 = !!utf8::is_utf8($pointer);

    selects($legacy, $legacy->encode({$key => 71}), $pointer, 71,
            'legacy: Latin-1 character path');
    is($pointer, $before, 'legacy: caller path value unchanged');
    is(!!utf8::is_utf8($pointer), $was_utf8,
       'legacy: caller path representation unchanged');
}

# Read-only/shared paths must not require writable caller storage.
{
    my $pointer = '/readonly';
    utf8::upgrade($pointer);
    my $shared = $pointer;
    Internals::SvREADONLY($pointer, 1);

    selects($legacy, '{"readonly":81}', $pointer, 81,
            'legacy: read-only path');
    is($shared, '/readonly', 'legacy: shared path unchanged');
}

# Returned containers must remain valid after temporary-root cleanup.
{
    my $selected = $legacy->decode_at_pointer(
        '{"keep":{"values":[1,2]},"discard":[3,4]}', '/keep'
    );

    # Separate statements create opportunities for temporary cleanup.
    my @churn = map { {payload => ('x' x 100)} } 1 .. 100;
    is_deeply($selected, {values => [1,2]},
              'legacy: selected object survives temporary cleanup');
    push @{$selected->{values}}, 5;
    is_deeply($selected->{values}, [1,2,5],
              'legacy: selected object remains writable');
}

done_testing();
