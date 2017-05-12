#!/usr/bin/perl -I.

use strict;
use Test::More qw(no_plan);
use Test::Differences;
use HTML::Transmorgify;
use HTML::Transmorgify::FormDefault;
use warnings;
use YAML;

$Data::Dumper::Deparse = 1;

my $finished = 0;

END { ok($finished, "finished"); }

my $test_start_line = __LINE__+3;
my @tests = split(/^>+TEST/m, <<'END_OF_TESTS');
>>>>>>>>>>>>>>>>>>TEST hidden variables
Before
<form method="POST">
<input type="hidden" name="one" value="1.0">
<input type="hidden" id="two" value="2.0">
<input type="submit" name="sub1" value="sval1">
</form>
After
>>>>RESULT
Before
<form method="POST">
<input type="hidden" name="one" value="1.0">
<input type="hidden" id="two" value="2.0">
<input type="submit" name="sub1" value="sval1">
</form>
After
>>>>QUERY_PARAMETERS
---
one: '1.0'
two: '2.0'
sub1: sval1
>>>>>>>>>>>>>>>>>>>TEST comprehensive
Before
<form method="POST">
<input type="hidden" name="h1" value="1.0">
<input type="text" name="t1" value="t1fv">
<input type="text" name="t2" value="t2fv">
<input type="text" name="t3">
<input type="text" name="t4">
<input type="checkbox" name="cb1" value="cb1v1" checked>
<input type="checkbox" name="cb2" value="cb2v1" checked>
<input type="checkbox" name="cb3" value="cb3v1">
<input type="checkbox" name="cb4" value="cb4v1">
<input type="checkbox" name="cb5" checked>
<input type="checkbox" name="cb6" checked>
<input type="checkbox" name="cb7">
<input type="checkbox" name="cb8">
<input type="checkbox" name="cb9" value="cb9v1" checked>
<input type="checkbox" name="cb9" value="cb9v2" checked>
<input type="checkbox" name="cb9" value="cb9v3">
<input type="checkbox" name="cb9" value="cb9v4">
<input type="radio" name="r1" value="r1v1" checked>
<input type="radio" name="r1" value="r1v2">
<input type="radio" name="r1" value="r1v3">
<textarea name="ta1">ta1v1</textarea>
<textarea name="ta2">ta2v1</textarea>
<select name="s1" multiple>
<option name="o1" value="o1v1" selected>
<option name="o2" value="o2v2" selected>
<option name="o3" value="o3v2">
<option name="o4" value="o4v2">
<option name="o5" selected>o5v1</option>
<option name="o6" selected>o6v1</option>
<option name="o7">o7v1</option>
<option name="o8">o8v1</option>
</select>
<select name="s2">
<option name="o1" value="o1v1" selected>
<option name="o2" value="o2v2">
<option name="o5">o5v1</option>
<option name="o6">o6v1</option>
</select>
<input type="submit" name="sub1" value="sval1">
</form>
After
>>>>RESULT
Before
<form method="POST">
<input type="hidden" name="h1" value="1.0">
<input type="text" name="t1" value="t1v2">
<input type="text" name="t2" value="t2fv">
<input type="text" name="t3">
<input type="text" name="t4" value="t4v2">
<input type="checkbox" name="cb1" value="cb1v1" checked>
<input type="checkbox" name="cb2" value="cb2v1" checked>
<input type="checkbox" name="cb3" value="cb3v1" checked>
<input type="checkbox" name="cb4" value="cb4v1">
<input type="checkbox" name="cb5" checked>
<input type="checkbox" name="cb6" checked>
<input type="checkbox" name="cb7" checked>
<input type="checkbox" name="cb8">
<input type="checkbox" name="cb9" value="cb9v1" checked>
<input type="checkbox" name="cb9" value="cb9v2">
<input type="checkbox" name="cb9" value="cb9v3" checked>
<input type="checkbox" name="cb9" value="cb9v4">
<input type="radio" name="r1" value="r1v1">
<input type="radio" name="r1" value="r1v2" checked>
<input type="radio" name="r1" value="r1v3">
<textarea name="ta1">ta1v2</textarea>
<textarea name="ta2">ta2v1</textarea>
<select name="s1" multiple>
<option name="o1" value="o1v1">
<option name="o2" value="o2v2" selected>
<option name="o3" value="o3v2">
<option name="o4" value="o4v2" selected>
<option name="o5">o5v1</option>
<option name="o6" selected>o6v1</option>
<option name="o7">o7v1</option>
<option name="o8">o8v1</option>
</select>
<select name="s2">
<option name="o1" value="o1v1">
<option name="o2" value="o2v2">
<option name="o5">o5v1</option>
<option name="o6" selected>o6v1</option>
</select>
<input type="submit" name="sub1" value="sval1">
</form>
After
>>>>QUERY_PARAMETERS
---
cb1: "cb1v1"
cb3: "cb3v1"
cb5: "on"
cb7: "on"
cb9:
 - "cb9v1"
 - "cb9v3"
r1: "r1v2"
t1: "t1v2"
t4: "t4v2"
ta1: "ta1v2"
s1:
 - "o2v2"
 - "o4v2"
 - "o6v1"
s2: "o6v1"
END_OF_TESTS

shift(@tests);

my $onebad = 0;

my %vars = (
	simple1	=> 'value 1',
	foo1	=> 'foo one',
	bar2	=> 'bar two',
	baz3	=> 'baz three',
	bof4	=> 'bof four',
	array1	=> [qw(one two three)],
	a3	=> [qw(1 2 3 4 5)],
	hash1	=> { key1 => { key2 => 'foo' }, other => 'bar' },
);

my $magic = HTML::Transmorgify->new(xml_quoting => 1);
$magic->mixin('HTML::Transmorgify::FormDefault');

for my $t (@tests) {
	$t =~ /^ ([^\n]+)\n(.*?)\n>>+RESULT\n(.*)\n>>+QUERY_PARAMETERS\n(.*)/s or die "t='$t'";
	my ($text, $input, $output, $s_yaml) = ($1, $2, $3, $4);
	my $qp = Load($s_yaml);
	chomp($output);
	undef %HTML::Transmorgify::compiled;
	$HTML::Transmorgify::query_param = $qp;
	my $res;
	my $bomb = sub {
		print STDERR "############################################ BOMB\n";
		print STDERR "@_\n";
		$onebad++;
		local($HTML::Transmorgify::debug) = 1;
		undef %HTML::Transmorgify::compiled;
		pos($input) = 0;
		$res = $magic->process($input, { input_file => __FILE__, input_line => $test_start_line }, %vars);
	};

	eval {
		$res = $magic->process($input, { input_file => __FILE__, input_line => $test_start_line }, %vars);
	};
	$bomb->("eval: $@") if $@;
	ok(! $@, $@ || "error return");
	$bomb->("output mismatch") unless $res eq $output;
	eq_or_diff_text($res, $output, $text);
	exit if ($res ne $output);

	$test_start_line += ($t =~ tr/\n/\n/);
}

$finished = 1;

