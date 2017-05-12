#!/usr/bin/perl -I.

use strict;
use Test::More qw(no_plan);
use HTML::Transmorgify;
use HTML::Transmorgify::Metatags;
use warnings;

my $finished = 0;

END { ok($finished, "finished"); }

my $test_start_line = __LINE__+3;
my @tests = split(/^>+TEST/m, <<'END_OF_TESTS');
>>>>>>>>>>>>>>>>>>TEST simple diversion
Before playback
{<playback foo />}
After playback, before capture
[<capture foo>&
In capture
!</capture>]
After capture
>>>>RESULT
Before playback
{&
In capture
!}
After playback, before capture
[]
After capture
>>>>>>>>>>>>>>>>>>TEST nested diversions
FIRST<playback C />SECOND<capture A>THIRD<playback C />AND
THEN<capture B>FORTH<capture C>-THIS IS C-</capture>OH
THEN</capture>FOR</capture>-FINALLY
A:<playback A />:and B:<playback B />:done
>>>>RESULT
FIRST-THIS IS C-SECOND-FINALLY
A:THIRD-THIS IS C-AND
THENFOR:and B:FORTHOH
THEN:done
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

my $magic = HTML::Transmorgify->new();
$magic->mixin('HTML::Transmorgify::Metatags');

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
use File::Slurp;
write_file("x", $res);
write_file("y", $output);
	is($res, $output, $text);
	exit if ($res ne $output);
	$test_start_line += ($t =~ tr/\n/\n/);
}

$finished = 1;

