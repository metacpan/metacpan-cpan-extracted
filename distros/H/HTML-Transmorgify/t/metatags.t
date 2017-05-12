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
>>>>>>>>>>>>>>>>>>TEST overrides
<define first>John</define>
<define middle>Henry</define>
<define last>Smith</define>
<define name last="Jones" eval=1><macro first> <macro middle> <macro last></define>
<define name2 last="Jones" eval=0><macro first> <macro middle> <macro last></define>
<define first>James</define>
<macro name middle="Fred">
<hr>
<macro name2 middle="Barney">
<hr>
<define first>Wilma</define>
<macro name2 middle="Betty">
<hr>
<macro name middle="Suzy">
>>>>RESULT
James Fred Jones
<hr>
John Henry Jones
<hr>
John Henry Jones
<hr>
Wilma Suzy Jones
>>>>>>>>>>>>>>>>>>TEST local vars
<define a>xyz</define>
<define foo a=1 b=2 trim=all>
	<define a>foobar</define>
	<define c><macro a></define>
</define>
foo: <macro foo>
a: <macro a>
c: <macro c>
>>>>>>RESULT
foo: 
a: xyz
c: foobar
>>>>>>>>>>>>>>>>>>TEST created containers
<define x.0 value="x0" />
<macro x.0>
>>>>>RESULT
x0
>>>>>>>>>>>>>>>>>>TEST multi-container foreach
<define x.0>x0</define>
<define x.1>x1</define>
<define x.2>x2</define>
<define y.foo>yfoo</define>
<define y.bar>ybar</define>
<define o1.new.stuff.3.1>o1newstuff31</define>
<define o1.new.stuff.3.2>o1newstuff32</define>
<define array1.5>array15</define>
<foreach thingy x y o1.new.stuff.3 array1 trim=start>
thing: <macro _thingy> * <macro thingy>
</foreach>
>>>>>RESULT
thing: 0 * x0
thing: 1 * x1
thing: 2 * x2
thing: bar * ybar
thing: foo * yfoo
thing: 1 * o1newstuff31
thing: 2 * o1newstuff32
thing: 0 * one
thing: 1 * two
thing: 2 * three
thing: 5 * array15

>>>>>>>>>>>>>>>>>>TEST nested if
<define x 1>
<define y 1>
<if is_set=x>x
<if is_set=z>z
<else>Z
</if>
<else>X</if>
y
>>>>>RESULT
x
Z
y
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
	o1	=> ZZa->new(a => [ 'x', 'y', { z => 3 }], b => 'bee', c => 3000000)
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
	is($res, $output, $text);
	exit if ($res ne $output);
	$test_start_line += ($t =~ tr/\n/\n/);
}

$finished = 1;

package ZZa;

use strict;
use warnings;
use HTML::Transmorgify::ObjectGlue;
use base 'HTML::Transmorgify::ObjectGlue';

sub new
{
	my ($pkg, %kv) = @_;
	return bless { %kv };
}

sub text
{
	my ($self) = @_;
	return join('*', sort keys %$self);
}

sub expand
{
	my ($self) = @_;
	return $self;
}

sub set
{
	my ($self, $key, $value) = @_;
	$self->{$key} = $value;
}

sub lookup
{
	my ($self, $key) = @_;
	return () unless exists $self->{$key};
	return $self->{$key};
}

1;
