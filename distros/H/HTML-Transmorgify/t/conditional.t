#!/usr/bin/perl -I.

use strict;
use Test::More qw(no_plan);
use HTML::Transmorgify;
use HTML::Transmorgify::Conditionals;
use warnings;

my $finished = 0;

END { ok($finished, "finished"); }

my @parsetests = split(/\n/, <<'END_OF_PARSE_TESTS');
2 * 4 < 83 ? 8 : 0
END_OF_PARSE_TESTS

my $test_start_line = __LINE__+3;
my @tests = split(/^>+TEST/m, <<'END_OF_TESTS');
>>>>>>>>>>>>>>>>>>TEST 1 and 0
<if expr="1 == 1">one is one
</if>
<if expr="1 == 0">and not zero
</if>
<if expr="0 == 0">but zero is zero
</if>
end
>>>>RESULT
one is one
but zero is zero
end
>>>>>>>>>>>>>>>>>>TEST plus and times
<if expr="3 * 4 + 2 * 7 == 26">plus and times work
</if>
end
>>>>RESULT
plus and times work
end
>>>>>>>>>>>>>>>>>>TEST false not
<if expr="not 3">not three
</if>
end
>>>>RESULT
end
>>>>>>>>>>>>>>>>>>TEST unary and trinary ops
<if expr="not 0">not zero
</if>
<if expr="not 3">not three
</if>
<if expr="not (not 4)">not not four
</if>
<if expr="2 ** 4 < 83 ? 8 : 0">tri yes
</if>
<if expr="2 ** 4 < 6 ? 27 : 0">tri no
</if>
end
>>>>RESULT
not zero
not not four
tri yes
end
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

my $expr_grammar = HTML::Transmorgify::Conditionals->new();

for my $pt (@parsetests) {
	next unless $pt =~ /\S/;
	my $expr = $expr_grammar->conditional($pt);
	ok(defined($expr), "parse $pt");
	unless (defined $expr) {
		require HTML::Transmorgify::ConditionalsDebug;
		my $debug_grammar = HTML::Transmorgify::ConditionalsDebug->new();
		$debug_grammar->conditional($pt);
		exit(0);
	}
}

my $magic = HTML::Transmorgify->new();
$magic->mixin('HTML::Transmorgify::Metatags');

for my $t (@tests) {
	$t =~ /^ ([^\n]+)\n(?=((.*?)\n>+RESULT\n))\2(.*)/s or die "t='$t'";
	my ($text, $input, $output) = ($1, $3, $4);
	chomp($output);
	undef %HTML::Transmorgify::compiled;
	my $res = $magic->process($input, { input_file => __FILE__, input_line => $test_start_line }, %vars);
	if ($res ne $output && ! $onebad++) {
		undef %HTML::Transmorgify::compiled;
		pos($input) = 0;
		$res = $magic->process($input, { input_file => __FILE__, input_line => $test_start_line }, %vars);
	}
	is($res, $output, $text);
	exit if ($res ne $output);
}

$finished = 1;

