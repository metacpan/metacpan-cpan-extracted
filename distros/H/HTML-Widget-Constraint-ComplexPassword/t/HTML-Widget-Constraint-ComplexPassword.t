#!/usr/bin/perl

use strict;
use warnings;

use Test::More;# 'no_plan';
BEGIN { plan tests => 18 };

BEGIN {
	use_ok ( 'HTML::Widget::Constraint::ComplexPassword', qw{
		$MIN_LENGTH
		$SPECIAL_CHARACTERS
	}) or exit;
}

is($MIN_LENGTH, 8, 'check minlength changes')
	or diag('update the pods if this default value changes.');
is($SPECIAL_CHARACTERS, '~`!@#$%^&*()-_+={}[]\\|:;"\'<>,.?/', 'check special characters changes')
	or diag('update the pods if this default value changes.');

my $constraint = HTML::Widget::Constraint::ComplexPassword->new();
isa_ok($constraint, 'HTML::Widget::Constraint') or exit;
isa_ok($constraint, 'HTML::Widget::Constraint::ComplexPassword') or exit;
can_ok($constraint, 'validate');

ok($constraint->validate('AbcDefG9'), 'complex password');
ok($constraint->validate('Ab@cDefG'), 'complex password2');
ok($constraint->validate('!AbcDefG'), 'complex password3');
ok($constraint->validate('AbcDefG?'), 'complex password4');
ok(!$constraint->validate('AbcDefGh'), 'not complex password');
ok(!$constraint->validate('1abcdefgh'), 'not complex password2');
ok(!$constraint->validate('1ABCDEFGH'), 'not complex password3');
ok(!$constraint->validate('AbcefG9'), 'short password');
$HTML::Widget::Constraint::ComplexPassword::MIN_LENGTH = 7;
ok($constraint->validate('AbcefG9'), 'short password but now ok after MIN_LENGTH change');

#test temporary setting minimum length
$constraint->min_length(4);
ok($constraint->validate('AfG9'), 'short password, ->min_length(4)');

#return back the MIN_LENGTH
$constraint->min_length(undef);
ok(!$constraint->validate('AfG9'), 'short password, ->min_length(4)');
ok($constraint->validate('AbcD^fG'), 'complex password5');


