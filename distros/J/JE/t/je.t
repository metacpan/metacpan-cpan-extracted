#!perl  -T

# Some of the stuff in here needs to be moved elsewhere.
# This is supposed to test JE.pm's Perl interface (as opposed to that of
# its accompanying modules, or its JS features).
# The bind_class method has its own test file.

BEGIN { require './t/test.pl' }

use Test::More tests => 49;
use strict;
use Scalar::Util 'refaddr';
use utf8;

diag("To do: finish writing this test script");

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok 'JE' }


#--------------------------------------------------------------------#
# Tests 2-3: Object creation

ok our $j = JE->new, 'Create JE global object';
isa_ok $j, 'JE';


#--------------------------------------------------------------------#
# Tests 4-9: Compilation and string concatenation

ok our $code = $j->parse('"aa" + "bb"');
isa_ok $code, 'JE::Code';

isa_ok +(our $result = $code->execute), 'JE::String';
ok $result eq 'aabb', 'JE::String\'s overloaded ops';
ok !ref(our $value = $result->value),
	'(string)->value is scalar';
ok $value eq 'aabb', '(string)->value eq "aabb"';

#--------------------------------------------------------------------#
# Tests 10-15: object literals

ok $code = $j->parse('({a:"b"})');

isa_ok +($result = $code->execute), 'JE::Object';
ok $result eq '[object Object]', 'JE::Object\'s overloaded string op';
ok $result->{a} eq 'b', 'JE::Object\'s overloaded hash ref op';
ok ref($value = $result->value) eq 'HASH',
	'(obj)->value is hash ref';
ok $value->{a} eq 'b', '(obj)->value->{a} eq "b"';

#--------------------------------------------------------------------#
# Tests 16-18: bare identifiers

ok $code = $j->parse('parseFloat');

isa_ok +($result = $code->execute), 'JE::LValue';
isa_ok get $result, 'JE::Object::Function';

#--------------------------------------------------------------------#
# Tests 19-20: various js ops

ok $j->eval("new(String)('𝄐').length")                          eq '2'; 
ok !defined $j->eval('{ a = 6; b= tru\u003d; }');

#--------------------------------------------------------------------#
# Tests 21-25: more complicated js stuff

isa_ok $j->new_function(ok => \&ok), 'JE::Object::Function';

defined $j->eval(<<'---') or die;

var func = new Function('this,and','a','that');
ok(typeof func === 'function');
//TO DO: ok(func.length === 3);

ok(double(-3) === -6);
function double(number) {
	return number*2
}

ok(function double(number) {
	return number*2
}(89) === 178);

$ = '\n,rekcah tpircSAMCE rehtona tsuJ'.split(/(?:)/)
function next_char() { eval('function chr(){}'); delete chr;
var chr = $.pop(); return chr } $_ = ''
while (next_char()) $_ += chr;
ok($_ === 'Just another ECMAScript hacker,\n')


---

#--------------------------------------------------------------------#
# Test 26: Make sure that surrogates that cause invalid syntax don’t
#          make parse die.  (Fixed in 0.020 via a workaround  for a
#          perl bug.)

{ no warnings 'utf8';
	my $code;
	ok eval {
		$code = $j->parse("\x{dfff}"); # should simply return undef
		1;
	} && !defined $code, 'surrogates cause syntax errors';
}

#--------------------------------------------------------------------#
# Tests 27-8: Make sure that regexp syntax errors or invalid modifiers
#          don’t make parse die. (Fixed in 0.020.)

{
	my $code;
	ok eval {
		$code = $j->parse("/a**/"); # should simply return undef
		1;
	} && !defined $code, 'regexp syntax errors don\'t make parse die';
	ok eval {
		$code = $j->parse("/a/PCYFGRC");
		1;
	} && !defined $code, 'invalid regexp modifiers don\'t slay parse';
}

#--------------------------------------------------------------------#
# Tests 29-35: max_ops

SKIP: { skip 'unimplemented in the experimental version', 7
		if $ENV{YES_I_WANT_JE_TO_OPTIMISE};# stop it from hanging
	my $j = new JE max_ops => 100;
	is $j->max_ops, 100, 'max_ops as arg to constructor';
	$j->max_ops(110);
	is $j->max_ops, 110, 'max_ops with arg';

	is $j->eval("1+1"), 2, "110 max_ops doesn't catch 1+1";
	is $j->eval("for(var i =0; ;++i);"), undef,
		'eval dies when max_ops is exceeded';
	ok !ref $@, '$@ is not a reference after max_ops makes eval die';
	like $@, qr/^max_ops \(110\) exceeded at/, 'max_ops error message';
	ok $j->{i} < 110 && $j->{i} > 0,
	  "max_ops stopped in mid-processing (at $j->{i} to be precise)";
}

#--------------------------------------------------------------------#
# Tests 36-49: html_mode

SKIP: { skip 'unimplemented in the experimental version', 13
		if $ENV{YES_I_WANT_JE_TO_OPTIMISE};
	my $j = new JE html_mode => 1;
	ok $j->html_mode, 'html_mode as arg to constructor';
	$j->html_mode(0);
	ok! $j->html_mode, 'html_mode with arg';
	$j->html_mode(1);

	$j->eval(' brext = cled = 1 ');
	is $j->eval("1<!--"), 1,
	 "<!-- is equivalent to // in HTML mode";
	is $j->eval("brext<!--cled ||cled+''\n+brext"), 2,
	 "<!-- with line break is equivalent to // in HTML mode";
	is $j->eval("brext\n\t -->-1\n+1"), '2',
		'--> acts like // when preceded only by whitespace';
	$j->eval('brext=1');
	is $j->eval("brext-->-1\n+1"), 'true',
		'but is two ops (-- >) otherwise';
	is $j->eval("//\n2"), 2,
	 "comments at the beginning of code still work in HTML mode";

	is $j->eval('"\"<!--"'), '"<!--',
	 'HTML comment delimiters in double-quoted strings';
	is $j->eval("'\\'<!--'"), "'<!--",
	 'HTML comment delimiters in single-quoted strings';
	is $j->eval("m=1; /* <!-- */\n 3 */4/m.multiline"), 3,
	 '<!-- is ignored between /* and */ (& does not wipe out the */)';
	is $j->eval("m=1; /*\n --> */\n 3 */4/m.multiline"), 3,
	 '\n--> is ignored between /* and */ (& does not wipe out the */)';
	is $j->eval('/<!--/.test("<!--")'), 'true',
	 'delimiters work in regexps';

	$j->html_mode(0);
	$j->eval(' brext = cled = 1 ');
	is $j->eval("brext<!--cled ||cled+''\n+brext"), '01',
	 "<!-- is equivalent to < ! -- when HTML mode is off";
	is $j->eval("brext\n\t -->-1\n+1"), undef,
		'\n--> is a syntax error when HTML mode is off';
	# ~~~ Since this particular case is always a syntax error (a line
	#     break being prohibited before a postfix), maybe we could sup-
	#     port the closing delimiter all the time.
}
