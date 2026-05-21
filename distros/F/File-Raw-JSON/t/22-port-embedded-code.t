#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Raw::JSON;
use File::Temp qw(tempdir);

# Ported from JSON-Lines-1.11/t/15-embedded-code.t
# String fields can contain unbalanced braces - the brace-balancer
# must be string-aware to count them correctly.

my $dir = tempdir(CLEANUP => 1);

sub _decode {
    my ($bytes) = @_;
    my $f = "$dir/c.jsonl";
    File::Raw::spew($f, $bytes);
    return File::Raw::slurp($f, plugin => 'jsonl');
}

subtest 'JSON with embedded Perl code in a string field' => sub {
    my $string = q|{"type":"user","message":{"content":"sub foo { my $x = { bar => 1 }; return $x; }"}}|;
    my $rows = _decode($string);
    is(scalar @$rows, 1, 'should decode exactly 1 object');
    is($rows->[0]{type}, 'user', 'correct type');
    like($rows->[0]{message}{content}, qr/sub foo/, 'content contains the code');
};

subtest 'JSON with multiple brace patterns in a string' => sub {
    my $string = q|{"type":"tool_result","content":"{ cats{} } { dogs{} }"}|;
    my $rows = _decode($string);
    is(scalar @$rows, 1, 'should decode exactly 1 object');
    is($rows->[0]{type}, 'tool_result', 'correct type');
};

subtest 'real Claude-output trace with embedded code' => sub {
    my $string = q|{"type":"user","tool_use_result":{"file":{"content":"package Foo;\nsub bar {\n    my $hash = { key => 'value' };\n    return $hash;\n}\n1;\n"}}}|;
    my $rows = _decode($string);
    is(scalar @$rows, 1, 'should decode exactly 1 object');
    is($rows->[0]{type}, 'user', 'correct type');
    like($rows->[0]{tool_use_result}{file}{content}, qr/package Foo/,
         'content has the code');
};

subtest 'three actual concatenated values' => sub {
    my $string = q|{"type":"a"}{"type":"b"}{"type":"c"}|;
    my $rows = _decode($string);
    is(scalar @$rows, 3, 'should decode 3 objects');
    is($rows->[0]{type}, 'a', 'first');
    is($rows->[1]{type}, 'b', 'second');
    is($rows->[2]{type}, 'c', 'third');
};

subtest 'escaped quote inside a string' => sub {
    my $string = q|{"a":"with \"quote\" inside"}|;
    my $rows = _decode($string);
    is(scalar @$rows, 1, 'one object');
    is($rows->[0]{a}, 'with "quote" inside', 'escaped quote preserved');
};

subtest 'unbalanced brace inside a string is not a value boundary' => sub {
    my $string = q|{"a":"start { middle"}|;
    my $rows = _decode($string);
    is(scalar @$rows, 1, 'one object');
    is($rows->[0]{a}, 'start { middle', 'string preserved');
};

done_testing;
