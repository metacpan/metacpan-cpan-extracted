use Test::More;
use JSON::Lines;
subtest 'JSON with embedded Perl code in string field' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"type":"user","message":{"content":"sub foo { my $x = { bar => 1 }; return $x; }"}}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'should decode exactly 1 object');
	is($data[0]->{type}, 'user', 'correct type');
	like($data[0]->{message}{content}, qr/sub foo/, 'content contains the code');
};
subtest 'JSON with multiple brace patterns in strings' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"type":"tool_result","content":"{ cats{} } { dogs{} }"}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'should decode exactly 1 object');
	is($data[0]->{type}, 'tool_result', 'correct type');
};
subtest 'Real Claude output with file content containing code' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"type":"user","tool_use_result":{"file":{"content":"package Foo;\nsub bar {\n    my $hash = { key => 'value' };\n    return $hash;\n}\n1;\n"}}}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'should decode exactly 1 object');
	is($data[0]->{type}, 'user', 'correct type');
	like($data[0]->{tool_use_result}{file}{content}, qr/package Foo/, 'content has the code');
};
subtest 'actual multiple JSON objects on one line' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"type":"a"}{"type":"b"}{"type":"c"}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 3, 'should decode 3 objects');
	is($data[0]->{type}, 'a', 'first object');
	is($data[1]->{type}, 'b', 'second object');
	is($data[2]->{type}, 'c', 'third object');
};
subtest 'Debug trace decode behavior' => sub {
	my $jsonl = JSON::Lines->new(
		canonical => 1,
		success_cb => sub {
			my ($action, $struct, $raw) = @_;
			diag "SUCCESS: decoded type=" . ($struct->{type} // 'N/A');
		},
		error_cb => sub {
			my ($action, $error, $data) = @_;
			diag "ERROR: $error (data length=" . length($data // '') . ")";
			return undef;
		},
	);
	my $string = q|{"type":"user","message":{"content":"sub foo { my $x = { bar => 1 }; return $x; }"}}|;
	diag "Input string length: " . length($string);
	my @data = $jsonl->decode($string);
	diag "Got " . scalar(@data) . " objects";
	is(scalar @data, 1, 'should decode exactly 1 object');
};
subtest 'Real Claude tool_use_result with file content' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"type":"user","message":{"role":"user","content":[{"tool_use_id":"toolu_01LUrmyi7jqEFKBwDJFyEmVR","type":"tool_result","content":"     1→package Claude::Agent::Code::Review;\n     2→\n     3→use 5.020;\n     4→use strict;\n     5→use warnings;\n     6→\n     7→use Exporter 'import';\n     8→our @EXPORT_OK = qw(review review_files review_diff);\n     9→\n    10→use Claude::Agent qw(query);\n    11→\n    12→sub review {\n    13→    my (%args) = @_;\n    14→    my $target = $args{target} // die \"requires target\";\n    15→    if ($target eq 'staged') {\n    16→        return review_diff(staged => 1);\n    17→    }\n    18→}\n    19→\n    20→sub _run_review {\n    21→    my ($prompt, $options) = @_;\n    22→    my $iter = query(prompt => $prompt);\n    23→    while (my $msg = $iter->next) {\n    24→        if ($msg->isa('Claude::Agent::Message::Result')) {\n    25→            return $msg;\n    26→        }\n    27→    }\n    28→}\n    29→\n    30→1;\n"}]},"session_id":"test-session"}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'should decode exactly 1 object from Claude tool_result');
	is($data[0]->{type}, 'user', 'correct type');
	ok($data[0]->{message}, 'has message');
	ok($data[0]->{message}{content}, 'has content array');
	is($data[0]->{message}{content}[0]{type}, 'tool_result', 'content is tool_result');
};
subtest 'Claude format with tool_use_result at end' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"type":"user","message":{"role":"user","content":[{"tool_use_id":"toolu_test","type":"tool_result","content":"     1→package Foo;\n     2→sub bar {\n     3→    my $hash = { key => 'value' };\n     4→    return $hash;\n     5→}\n     6→1;\n"}]},"session_id":"test","tool_use_result":{"type":"text","file":{"filePath":"lib/Foo.pm","content":"package Foo;\nsub bar {\n    my $hash = { key => 'value' };\n    return $hash;\n}\n1;\n"}}}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'should decode exactly 1 object with tool_use_result at end');
	is($data[0]->{type}, 'user', 'correct type');
	ok($data[0]->{tool_use_result}, 'has tool_use_result');
	ok($data[0]->{tool_use_result}{file}, 'has file in tool_use_result');
};
subtest 'Very long JSON with many brace patterns' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $code_content = <<'END_CODE';
package Claude::Agent::Query;
use 5.020;
sub BUILD {
    my ($self) = @_;
    $self->_loop($self->loop // IO::Async::Loop->new);
    if ($self->options->has_mcp_servers && $self->options->mcp_servers) {
        for my $name (keys %{$self->options->mcp_servers}) {
            my $server = $self->options->mcp_servers->{$name};
            if ($server->can('type') && $server->type eq 'sdk') {
                my $sdk_server = Claude::Agent::MCP::SDKServer->new(
                    server => $server,
                    loop   => $self->_loop,
                );
                $sdk_server->start();
                $self->_sdk_servers->{$name} = $sdk_server;
            }
        }
    }
}
sub _build_command {
    my ($self) = @_;
    my @cmd = ('claude', '--output-format', 'stream-json');
    if ($self->options->has_mcp_servers && $self->options->mcp_servers) {
        my %servers;
        for my $name (keys %{$self->options->mcp_servers}) {
            my $server = $self->options->mcp_servers->{$name};
            $servers{$name} = $server->to_hash;
        }
    }
    return @cmd;
}
1;
END_CODE
	$code_content =~ s/\\/\\\\/g;
	$code_content =~ s/"/\\"/g;
	$code_content =~ s/\n/\\n/g;
	$code_content =~ s/\t/\\t/g;
	my $json_string = qq|{"type":"user","tool_use_result":{"tool":"Read","content":"$code_content"}}|;
	my @data = $jsonl->decode($json_string);
	is(scalar @data, 1, 'should decode exactly 1 object for large code content');
	is($data[0]->{type}, 'user', 'correct type');
	like($data[0]->{tool_use_result}{content}, qr/package Claude/, 'content contains the code');
};
subtest 'Result message with nested structured output' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"type":"result","result":"Review complete","structured_output":{"summary":"Found issues","issues":[{"severity":"high","category":"bugs","file":"test.pm","line":10,"description":"Bug found"},{"severity":"low","category":"style","file":"test.pm","line":20,"description":"Style issue"}],"metrics":{"files_reviewed":1,"lines_reviewed":100}},"model_usage":{"claude-opus":{"input":100,"output":50}}}|;
	my @data = $jsonl->decode($string);
	diag "Decoded " . scalar(@data) . " objects";
	is(scalar @data, 1, 'should decode exactly 1 result object');
	is($data[0]->{type}, 'result', 'correct type');
	ok($data[0]->{structured_output}, 'has structured_output');
	is(scalar @{$data[0]->{structured_output}{issues}}, 2, 'has 2 issues');
};
subtest 'Partial/chunked JSON input' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $full = q|{"type":"result","structured_output":{"summary":"Found issues","issues":[{"severity":"high"}]}}|;
	my $partial = q|{"type":"result","structured_output":{"summary":"Found issues","issues":[{"severity":"high"}|;
	my @full_data = $jsonl->decode($full);
	is(scalar @full_data, 1, 'full JSON decodes to 1 object');
	$jsonl->clear_buffer;
	my @partial_data = $jsonl->decode($partial);
	diag "Partial JSON decoded to " . scalar(@partial_data) . " objects";
	for my $i (0..$#partial_data) {
		my $obj = $partial_data[$i];
		if (ref $obj eq 'HASH') {
			diag "  Object $i keys: " . join(", ", keys %$obj);
		} else {
			diag "  Object $i is: " . (ref($obj) || $obj // 'undef');
		}
	}
	is(scalar(@partial_data), 0, 'partial/incomplete JSON should return 0 objects, not inner fragments');
};
subtest 'Chunked input with automatic buffering' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $chunk1 = q|{"type":"result","structured_output":{"summary":"Found|;
	my $chunk2 = q| issues","issues":[{"severity":"high"}]}}|;
	my @data1 = $jsonl->decode($chunk1);
	is(scalar @data1, 0, 'first chunk returns nothing (buffered)');
	ok(length($jsonl->remaining) > 0, 'buffer has incomplete data');
	my @data2 = $jsonl->decode($chunk2);
	is(scalar @data2, 1, 'second chunk completes and returns object');
	is($data2[0]->{type}, 'result', 'correct type after reassembly');
	is($data2[0]->{structured_output}{summary}, 'Found issues', 'content correctly reassembled');
	is($jsonl->remaining, '', 'buffer empty after complete parse');
};
subtest 'Multiple objects with chunking' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $chunk1 = q|{"type":"a"}{"type":"b","data":{"nested"|;
	my $chunk2 = q|:"value"}}{"type":"c"}|;
	my @data1 = $jsonl->decode($chunk1);
	is(scalar @data1, 1, 'first chunk returns one complete object');
	is($data1[0]->{type}, 'a', 'first object correct');
	my @data2 = $jsonl->decode($chunk2);
	is(scalar @data2, 2, 'second chunk returns two objects');
	is($data2[0]->{type}, 'b', 'second object correct');
	is($data2[0]->{data}{nested}, 'value', 'nested data correct');
	is($data2[1]->{type}, 'c', 'third object correct');
};
subtest 'clear_buffer resets state' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my @data = $jsonl->decode(q|{"type":"incomplete|);
	is(scalar @data, 0, 'incomplete returns nothing');
	ok(length($jsonl->remaining) > 0, 'buffer has data');
	$jsonl->clear_buffer();
	is($jsonl->remaining, '', 'buffer cleared');
	@data = $jsonl->decode(q|{"type":"fresh"}|);
	is(scalar @data, 1, 'fresh input parses correctly');
	is($data[0]->{type}, 'fresh', 'correct content');
};
subtest 'Unbalanced braces inside strings' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"code":"function foo() {"}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles opening brace in string');
	is($data[0]->{code}, 'function foo() {', 'content preserved');
	$jsonl->clear_buffer;
	$string = q|{"code":"} end of block"}|;
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles closing brace in string');
	$jsonl->clear_buffer;
	$string = q|{"code":"if (x) { } else { unclosed"}|;
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles multiple unbalanced braces');
	$jsonl->clear_buffer;
	$string = q|{"arr":"[1, 2, 3"}|;
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles unbalanced bracket in string');
};
subtest 'Escaped quotes in strings' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"text":"He said \"hello {\" to me"}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles escaped quote before brace');
	like($data[0]->{text}, qr/hello \{/, 'content has brace after escaped quote');
	$jsonl->clear_buffer;
	$string = q|{"text":"\"test\" with { braces }"}|;
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles multiple escaped quotes with braces');
	$jsonl->clear_buffer;
	$string = '{"path":"C:\\\\Users\\\\{name}"}';
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles escaped backslash with braces');
};
subtest 'Deeply nested structures' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"a":{"b":{"c":{"d":{"e":"deep"}}}}}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles deeply nested objects');
	is($data[0]->{a}{b}{c}{d}{e}, 'deep', 'deep value accessible');
	$jsonl->clear_buffer;
	$string = q|{"arr":[[[[["deep"]]]]]}|;
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles deeply nested arrays');
	is($data[0]->{arr}[0][0][0][0][0], 'deep', 'deep array value accessible');
	$jsonl->clear_buffer;
	$string = q|{"a":[{"b":[{"c":"val"}]}]}|;
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles mixed nesting');
};
subtest 'Unicode and special characters' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"emoji":"Hello { world }"}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles emoji with braces');
	$jsonl->clear_buffer;
	$string = q|{"text":"line1\\nline2\\t{ tab }"}|;
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles escaped newlines/tabs with braces');
	$jsonl->clear_buffer;
	$string = q|{"text":"\\u0048ello { \\u007D }"}|;
	@data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles unicode escapes near braces');
};
subtest 'Empty and minimal structures' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my @data = $jsonl->decode(q|{}|);
	is(scalar @data, 1, 'handles empty object');
	$jsonl->clear_buffer;
	@data = $jsonl->decode(q|[]|);
	is(scalar @data, 1, 'handles empty array');
	$jsonl->clear_buffer;
	@data = $jsonl->decode(q|{"":""} |);
	is(scalar @data, 1, 'handles empty string keys/values');
	$jsonl->clear_buffer;
	@data = $jsonl->decode(q|[{}]|);
	is(scalar @data, 1, 'handles array with empty object');
	$jsonl->clear_buffer;
	@data = $jsonl->decode(q|{"a":[]}|);
	is(scalar @data, 1, 'handles object with empty array');
};
subtest 'Multiple objects with complex content' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"a":"x { y"}{"b":"z } w"}{"c":"{ } { }"}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 3, 'decodes 3 objects with unbalanced braces in strings');
	is($data[0]->{a}, 'x { y', 'first object content');
	is($data[1]->{b}, 'z } w', 'second object content');
	is($data[2]->{c}, '{ } { }', 'third object content');
};
subtest 'Whitespace handling' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my @data = $jsonl->decode(q|  {"a":1}  |);
	is(scalar @data, 1, 'handles leading/trailing whitespace');
	$jsonl->clear_buffer;
	@data = $jsonl->decode(qq|{"a":1}\n{"b":2}\n|);
	is(scalar @data, 2, 'handles newline-separated objects');
	$jsonl->clear_buffer;
	@data = $jsonl->decode(qq|\t{"a":1}\t\t{"b":2}\t|);
	is(scalar @data, 2, 'handles tab-separated objects');
};
subtest 'Numbers and booleans near braces' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $string = q|{"num":123,"bool":true,"arr":[1,2,3],"obj":{"x":null}}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles mixed types');
	is($data[0]->{num}, 123, 'number value');
	is($data[0]->{bool}, 1, 'boolean value');
	is_deeply($data[0]->{arr}, [1,2,3], 'array value');
};
subtest 'Very long strings with braces' => sub {
	my $jsonl = JSON::Lines->new(canonical => 1);
	my $long_content = "code { block } " x 100;
	my $string = qq|{"content":"$long_content"}|;
	my @data = $jsonl->decode($string);
	is(scalar @data, 1, 'handles long string with many brace pairs');
	like($data[0]->{content}, qr/code \{ block \}/, 'content preserved');
};
done_testing();
