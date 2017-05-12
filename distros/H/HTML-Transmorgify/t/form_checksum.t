#!/usr/bin/perl -I.

use strict;
use Test::More qw(no_plan);
use Test::Differences;
use HTML::Transmorgify;
use HTML::Transmorgify::FormChecksum;
use warnings;
use YAML;

$Data::Dumper::Deparse = 1;

my $finished = 0;

END { ok($finished, "finished"); }

my $test_start_line = __LINE__+3;
my @tests = split(/^>+TEST/m, <<'END_OF_TESTS');
>>>>>>>>>>>>>>>>>>TEST no secret
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
<input type="hidden" id="two" value="2.0" name="two">
<input type="submit" name="sub1" value="sval1">
</form>
After
>>>>SUBMIT
---
one: '1.0'
two: '2.0'
sub1: sval1
>>>>>>>>>>>>>>>>>>TEST with secret
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
<input type="hidden" id="two" value="2.0" name="two">
<input type="submit" name="sub1" value="sval1">
<input type="hidden" name=" constraint" value="one'v'sub1'm'two'v sval1"
><input type="hidden" name=" csum" value="313f34f15b26f5c9a6a9851bf1f65b70"
></form>
After
>>>>SUBMIT
---
one: '1.0'
two: '2.0'
sub1: sval1
' constraint': "one'v'sub1'm'two'v sval1"
' csum': "313f34f15b26f5c9a6a9851bf1f65b70"
>>>>>>>>>>>>>>>>>TEST multiple submits
Before
<form method="POST">
<input type="submit" name="sub" value="sval1">
<input type="submit" name="sub" value="sval2">
<input type="submit" name="sub" value="sval3">
</form>
After
>>>>RESULT
Before
<form method="POST">
<input type="submit" name="sub" value="sval1">
<input type="submit" name="sub" value="sval2">
<input type="submit" name="sub" value="sval3">
<input type="hidden" name=" constraint" value="sub'm sval1'sval2'sval3"
><input type="hidden" name=" csum" value="02321de9ef83742d2535f4f855d67705"
></form>
After
>>>>SUBMIT
---
sub: sval2
' constraint': "sub'm sval3'sval2'sval1"
' csum': "c9aa0ea2c50c9ba3411e598a3edee65a"
>>>>>>>>>>>>>>>>TEST other form elements
Before
<form method=POST>
<input type=radio name=radio1 value="r1v1">
<input type="radio" name="radio1" value=r1v2>
<input type=radio name=radio1 value=r1v3>
<select name="select1" multiple>
<option>s1v1</option>
<option value="s1v2">s 1 v 2</option>
</select>
<select name="select2" multiple>
<option>s2v1</option>
<option value="s2v2">s 2 v 2</option>
</select>
<input type="hidden" name="h1" value="h1v1">
<textarea name=ta>FOO</textarea>
<input type=checkbox name="cb1">
<input type=submit name="sub1" value="sub1v1">
</form>
After
>>>>RESULT
Before
<form method="POST">
<input type="radio" name="radio1" value="r1v1">
<input type="radio" name="radio1" value="r1v2">
<input type="radio" name="radio1" value="r1v3">
<select name="select1" multiple>
<option>s1v1</option>
<option value="s1v2">s 1 v 2</option>
</select>
<select name="select2" multiple>
<option>s2v1</option>
<option value="s2v2">s 2 v 2</option>
</select>
<input type="hidden" name="h1" value="h1v1">
<textarea name="ta">FOO</textarea>
<input type="checkbox" name="cb1">
<input type="submit" name="sub1" value="sub1v1">
<input type="hidden" name=" constraint" value="cb1'M'h1'v'radio1'm'select1'M'select2'M'sub1'm'ta'x on r1v1'r1v2'r1v3 s1v1's1v2 s2v1's2v2 sub1v1"
><input type="hidden" name=" csum" value="add3329cf65eceb2b48d3b538bd0ce4b"
></form>
After
>>>>SUBMIT
---
radio1: r1v3
select1: s1v2
select2: s2v1
ta: FOO
cb1: on
sub1: sub1v1
h1: h1v1
' csum': "7cefcacbbe7f5a187dceab4ba3d17d65"
' constraint': "cb1'M'h1'v'radio1'm'select1'M'select2'M'sub1'm'ta'x on r1v1'r1v3'r1v2 s1v2's1v1 s2v2's2v1 sub1v1"
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
$magic->mixin('HTML::Transmorgify::FormChecksum');

for my $t (@tests) {
	$t =~ /^ ([^\n]+)\n(.*?)\n>>+RESULT\n(.*)\n>>+SUBMIT\n(.*)/s or die "t='$t'";
	my ($text, $input, $output, $s_yaml) = ($1, $2, $3, $4);
	my $submit = Load($s_yaml);
	chomp($output);
	undef %HTML::Transmorgify::compiled;
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

	my $v = validate_form_submission($submit, $vars{' secret'});

	if ($vars{' secret'}) {
		is($v, 1, "validate form data");
	} else {
		is($v, undef, "no secret, no validation");
	}

	$test_start_line += ($t =~ tr/\n/\n/);
	$vars{' secret'} = 'set';
}

$finished = 1;

