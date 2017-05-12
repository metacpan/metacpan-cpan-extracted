#!perl  -T

BEGIN { require './t/test.pl' }

use Test::More tests => 34;
use Scalar::Util 'refaddr';
use strict;
use utf8;
no warnings 'utf8';

#--------------------------------------------------------------------#
# Tests 1-2: See if the modules load

BEGIN { &use_ok(qw'JE::Code add_line_number') }; # Make sure it loads
                                # without JE already loaded.
BEGIN { use_ok 'JE' };


#--------------------------------------------------------------------#
# Tests 3-7: Create some JE::Code objects

# I need a global object.
our $j = JE->new,;
isa_ok $j, 'JE', 'global object';

our $this = $j->parse('this');
isa_ok $this, 'JE::Code', '"this" code';

our $assignment = parse $j 'x';
isa_ok $assignment, 'JE::Code', 'identifier code';

our $deletion = parse $j 'function y(){} delete y';
isa_ok $deletion, 'JE::Code', 'deletion code';

our $non_var = parse $j 'nonexistent_var';
isa_ok $non_var, 'JE::Code', '"nonexistent-var" code';


#--------------------------------------------------------------------#
# Tests 8-10: execute -- 'this' value

ok(refaddr $j == refaddr $this->execute,
	'global obj is used if "this" is omitted');
ok(refaddr $j == refaddr $this->execute(undef),
	'global obj is used if "this" is undef');
ok(refaddr $this == refaddr $this->execute($this),
	'first arg becomes the "this" value');


#--------------------------------------------------------------------#
# Tests 11-14: execute -- scope chain

# Looks as though I need another global object.
our $j2 = JE->new,;
isa_ok $j2, 'JE', 'global object no. 2';

$j ->prop(x => 1);
$j2->prop(x => 2);

ok($assignment->execute eq 1,
	'global obj is used if scope is omitted');
ok($assignment->execute(undef,undef) eq 1,
	'global obj is used if scope is undef');
ok($assignment->execute(undef, bless [$j2], 'JE::Scope') eq 2,
	'second arg is used as the scope chain');


#--------------------------------------------------------------------#
# Tests 15-18: execute -- type of code

ok(!$deletion->execute,
	'code is global if third arg is omitted');
ok(!$deletion->execute(undef,undef,undef),
	'code is global if third arg is undef');
ok($deletion->execute(undef, undef, 1),
	'code is eval code if third arg is 1');
ok($this->execute(undef, undef, 2) eq 'undefined',
	'code is function code if third arg is 2');


#--------------------------------------------------------------------#
# Tests 19-21: execute -- $@

$@ = 'wwaaahhooohoooooooooo@@@@@@@@@@@T$!@#!!!!!!!!!!!!!!!!!!!';
$this->execute;
ok($@ eq '', '$@ is reset upon successful ->execute');

ok(!defined $non_var->execute, '->execute returns undef upon failure');
ok($@->isa('JE::Object::Error::ReferenceError'),
	'$@ contains the error when ->execute fails');

#--------------------------------------------------------------------#
# Tests 22-33: add_line_number
#              abbreviated as 'aln' in test names

{
	# multiline code
	my $code = $j->parse("1\n+\r2", 'phial nayme', 7);
	my $nameless = $j->parse("1\n+\r2", undef, 8);

	is add_line_number('a'), 'a', 'aln with one arg';
	is add_line_number('a', $code), "a in phial nayme.\n",
		'aln with two args';
	is add_line_number('a', $nameless), "a",
		'aln with two args and nameless code';
	is add_line_number('a', $code, 1), "a at phial nayme, line 7.\n",
		'aln with three args';
	is add_line_number('a', $nameless, 4), "a at line 10.\n",
		'aln with three args and nameless code';
	is add_line_number('a', undef, 'b'), "a",
		'aln with undef second arg';

	local $JE::Code::code = $code;
	local $JE::Code::pos  = 2;
	is add_line_number('a'), "a at phial nayme, line 8.\n",
		'aln with two implicit args';
	is add_line_number('a', $code), "a at phial nayme, line 8.\n",
		'aln with one implicit arg';
	is add_line_number('a', undef), 'a',
		'undef second arg to aln prevents argument inference';
	is add_line_number('a', $code, undef), "a in phial nayme.\n",
		'undef third arg to aln prevents pos inference';

	$JE::Code::code = $nameless;
	is add_line_number('a'), "a at line 9.\n",
		'aln with two implicit args and no filename';

	$code = $j->parse("'\x{d800}'");
	eval { add_line_number 'a', $code };
	is $@, '',
	  'add_line_number can handle mangled source code with surrogates';
}

#--------------------------------------------------------------------#
# Test 34: Bug in 0.016: line numbers were always counting from 1 for
#                        parse errors (JE::Code was not passing the arg
#                        to JE::Parser::_parse).

$j->parse('#', '`', 47);
like $@, qr/ at `, line 47.\n\z/, 'parse errors have the right line no.';

