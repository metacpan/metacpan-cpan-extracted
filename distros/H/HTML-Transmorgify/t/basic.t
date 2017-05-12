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
>>>>>>>>>>>>>>>>>>TEST no magic stuff at all
This is some text with some <html> tags in it.
None of these <tags are=treated specially>
>>>>RESULT
This is some text with some <html> tags in it.
None of these <tags are=treated specially>
>>>>>>>>>>>>>>>>>>TEST In-tag unit test
<tag val="<macro simple1>">
>>>>RESULT
<tag val="value 1">
>>>>>>>>>>>>>>>>>>TEST In-tag define
Some text.
<define xyz value="1 2 3" />
use it: <macro xyz>.
>>>>RESULT
Some text.
use it: 1 2 3.
>>>>>>>>>>>>>>>>>>TEST simple block define
This is some text with some <html> tags in it.
<define foo>bar</define>
And now let's use it: <macro foo>
>>>>RESULT
This is some text with some <html> tags in it.
And now let's use it: bar
>>>>>>>>>>>>>>>>>>TEST macro expand in a tag
Some text 3.
<define abc>def</define>
<xyz tag="<macro abc>">
>>>>RESULT
Some text 3.
<xyz tag=def>
>>>>>>>>>>>>>>>>>>TEST macro expand in a special tag
Some text 4.
<define abc>def</define>
<src tag="<macro abc>">
>>>>RESULT
Some text 4.
<src tag=def>
>>>>>>>>>>>>>>>>>>TEST macro "pointers"
Stuff.
<define foo>foo value</define>
<define bar>bar value</define>
<define pointer>foo</define>
Pointer is '<macro pointer>'.
Pointer indirect: '<macro name="<macro pointer>">'.
<define pointer>bar</define>
Pointer is '<macro pointer>'.
Pointer indirect: '<macro name="<macro pointer>">'.
>>>>RESULT
Stuff.
Pointer is 'foo'.
Pointer indirect: 'foo value'.
Pointer is 'bar'.
Pointer indirect: 'bar value'.
>>>>>>>>>>>>>>>>>>TEST macro defines macro
Foo
<define bar>original bar</define>
<define foo eval=1><define bar>baz</define></define>
Use bar: <macro bar>.
Now use foo: <macro foo>.
Now use bar again: <macro bar>.
>>>>RESULT
Foo
Use bar: original bar.
Now use foo: .
Now use bar again: baz.
>>>>>>>>>>>>>>>>>>TEST array lookup
<macro array1.1>
end
>>>>RESULT
two
end
>>>>>>>>>>>>>>>>>>TEST hash lookup
<macro hash1.key1.key2>
end
>>>>RESULT
foo
end
>>>>>>>>>>>>>>>>>>TEST basic foreach
<foreach xyz array1>
Showing <macro xyz>.
</foreach>
end
>>>>RESULT
Showing one.
Showing two.
Showing three.
end
>>>>>>>>>>>>>>>>>>TEST basic if (true)
<if is_set=simple1>simple1 is set</if>
>>>>>RESULT
simple1 is set
>>>>>>>>>>>>>>>>>>TEST basic if (false)
<if is_set=unsetvar>simple1 is set</if>
>>>>>RESULT
>>>>>>>>>>>>>>>>>>TEST basic else
<if is_set=simple1>
is set
<else>
is not set
</if>
<if is_set=other_var>
ov is set
<else>
ov is not set
</if>
end
>>>>>RESULT
is set
ov is not set
end
>>>>>>>>>>>>>>>>>>TEST nested foreach
<foreach x array1>
<macro x>: <foreach y a3><macro y> </foreach>

</foreach>
end
>>>>>RESULT
one: 1 2 3 4 5 
two: 1 2 3 4 5 
three: 1 2 3 4 5 
end
>>>>>>>>>>>>>>>>>>TEST combined: foreach w/pointer elsif test
<foreach ptr a3>
<if is_set="foo<macro ptr>">
got an if <macro ptr>
<elsif is_set="bar<macro ptr>">
got a bar <macro ptr>
<elsif is_set="baz<macro ptr>">
got a baz <macro ptr>
<elsif is_set="bof<macro ptr>">
got a bof <macro ptr>
<else>
or else <macro ptr>
</if>
</foreach>
whew
>>>>RESULT
got an if 1
got a bar 2
got a baz 3
got a bof 4
or else 5
whew
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
	is($res, $output, $text);
	exit if ($res ne $output);
	$test_start_line += ($t =~ tr/\n/\n/);
}

$finished = 1;

