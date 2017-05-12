#!/usr/bin/perl -I.

use strict;
use Test::More qw(no_plan);
use HTML::Transmorgify;
use warnings;

my $finished = 0;

END { ok($finished, "finished"); }

my $test_start_line = __LINE__+3;
my @tests = split(/^>+TEST/m, <<'END_OF_TESTS');
>>>>>>>>>>>>>>>>>>TEST link crumb
<a href="http://example.com">example</a>
>>>>RESULT
<a href="http://example.com?%20crumb=18">example</a>
>>>>>>>>>>>>>>>>>>TEST image crumb
<img src="http://example.com/foo.jpg">
>>>>RESULT
<img src="http://example.com/foo.jpg?%20crumb=26">
>>>>>>>>>>>>>>>>>>TEST domain does not match
<a href="http://domain.com">example</a>
>>>>RESULT
<a href="http://domain.com">example</a>
>>>>>>>>>>>>>>>>>>TEST form
<form method=GET action="http://example.com/foo.cgi">
<input type=hidden name=h1 value=v1>
</form>
>>>>RESULT
<form method=GET action="http://example.com/foo.cgi">
<input type=hidden name=h1 value=v1>
<input type=hidden name=' crumb' value='26'></form>
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

$HTML::Transmorgify::Crumbs::sign = 
$HTML::Transmorgify::Crumbs::sign = sub {
	my ($url) = @_;
	if ($url =~ m{^https?://([^/]+\.)?example\.com(/|\z)}) {
#print STDERR "CRUMB FOR $url\n";
		return length($url);
	} else {
#print STDERR "NO CRUMB FOR $url\n";
		return;
	}
};

my $magic = HTML::Transmorgify->new();
$magic->mixin('HTML::Transmorgify::Crumbs');

for my $t (@tests) {
	$t =~ /^ ([^\n]+)\n(?=((.*?)\n>+RESULT\n))\2(.*)/s or die "t='$t'";
	my ($text, $input, $output) = ($1, $3, $4);
	chomp($output);
	undef %HTML::Transmorgify::compiled;
	my $res;
	eval {
		$res = $magic->process($input, { input_file => __FILE__, input_line => $test_start_line }, %vars);
	};
	ok(! $@,"eval error at $text");
	if (($@ || $res ne $output) && ! $onebad++) {
		local($HTML::Transmorgify::debug) = 1;
		undef %HTML::Transmorgify::compiled;
		pos($input) = 0;
		$res = $magic->process($input, { input_file => __FILE__, input_line => $test_start_line }, %vars);
	}
	is($res, $output, $text);
	exit if ($res ne $output);
	$test_start_line += ($t =~ tr/\n/\n/);
}

$finished = 1;

