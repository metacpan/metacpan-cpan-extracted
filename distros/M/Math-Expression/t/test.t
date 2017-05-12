#!/usr/bin/perl -w
#      /\
#     /  \		(C) Copyright 2003 Parliament Hill Computers Ltd.
#     \  /		All rights reserved.
#      \/
#       .		Author: Alain Williams, January 2003
#       .		addw@phcomp.co.uk
#        .
#          .
#
#	SCCS: @(#)test.t	1.30 07/21/16 01:05:03
#
# Test program for the module Math::Expression.
# This also serves as a demonstration program on how to use the module.
#
# May want to run as:
#	PERL5LIB=blib/lib t/test.t
#	PERL5LIB=../blib/lib test.t

# You can also set environment variables:
#  TRACE	1	print out expression and result
#		2	also print out the parse tree
# eg:
#	TRACE=1 perl -Iblib/lib t/test.t

#  ERR_TREE	1	Print out the parse tree on error
# eg:
#	ERR_TREE=1 perl -Iblib/lib t/test.t

# Copyright (c) 2003 Parliament Hill Computers Ltd/Alain D D Williams. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. You must preserve this entire copyright
# notice in any use or distribution.
# The author makes no warranty what so ever that this code works or is fit
# for purpose: you are free to use this code on the understanding that any problems
# are your responsibility.

# Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is
# hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and
# this permission notice appear in supporting documentation.

use strict;
use Math::Expression;
use POSIX qw(strftime mktime);



# Values of variables in here.
# This is made the hash that stores variables by the use of SetOpt() below.
# These variables may be used in expressions, see 'Test variables defined elsewhere' below.
my %Vars = (
	'var'		=>	[42],
	'foo'		=>	[6],
	'bar'		=>	['bar'],
	'variable'	=>	[9],
);

# Return the value of a variable - return an array
# 0	Magic value to Math::Expression
# 1	Variable name
# See SetOpt() below.
sub VarValue {
	my ($self, $name) = @_;

	my @nil;
	return @nil unless(exists($Vars{$name}));

	return @{$Vars{$name}};
}

# Return 1 if a variable is defined - ie has been assigned to
# 0	Magic value to Math::Expression
# 1	Variable name
# See SetOpt() below.
sub VarIsDef {
	my ($self, $name) = @_;

	return exists($Vars{$name}) ? 1 : 0;
}

my $NumFails = 0;
my $ExprError;
my $RunError;
my $errtree = 0;
my $verbose = 0;
my $var=0;
my @arr = (1,2,3);

my $OriginalExpression;
my $Operation;

sub MyPrintError {
	printf "#Error in $Operation '%s': ", $OriginalExpression;
	printf @_;
	print "\n";

	if($Operation eq 'parsing') {
		$ExprError = 1;
	} else {
		$RunError = 1;
	}
}

sub printv {
	return unless($verbose > 1);

	if($#_ > 0) {
		my $fmt = shift @_;
		printf $fmt, @_;
	} else {
		print $_[0];
	}
}

# **** Start here ****

# Debug/trace options from the environment:
$verbose = $ENV{TRACE}    if(exists($ENV{TRACE}));
$errtree = $ENV{ERR_TREE} if(exists($ENV{ERR_TREE}));

# So that print does not complain when Unicode characters are output:
binmode(STDOUT, ":utf8");
# So that UTF8 encoded strings below are handled properly:
use utf8;

printf "Math::Expression Version '%s'\n", $Math::Expression::VERSION if($verbose);

my $ArithEnv = new Math::Expression;

# Function that provides extra functions - ie user functions
# numArgs	return # arguments
# sumArgs	numeric sum of arguments
# A user defined function must return a scalar or list; it MUST not return undef.
sub moreFunctions {
	my ($self, $tree, $fname, @arglist) = @_;

	print "moreFunctions fname=$fname\n" if($verbose);

	return scalar @arglist if($fname eq 'numArgs');

	if($fname eq 'sumArgs') {
		my $sum = 0;
		$sum += $_ for @arglist;
		return $sum;
	}

	# Return undef so that in built functions are scanned
	return undef;
}

# MUST put user defined functions here so that it is known as a function - while parsing:
$ArithEnv->{Functions}->{numArgs} = 1;
$ArithEnv->{Functions}->{sumArgs} = 1;

$ArithEnv->SetOpt('VarHash' => \%Vars,
		  'VarGetFun' => \&VarValue,
		  'VarIsDefFun' => \&VarIsDef,
#		  'VarSetValueFunction' => \&VarSet,
		  'PrintErrFunc' => \&MyPrintError,
		  PermitLoops => 1,
		  EnablePrintf => 1,
		  ExtraFuncEval => \&moreFunctions,
		);

my $Now = time;
$ArithEnv->ParseToScalar("_Time := $Now");	# This var used in some tests


# Some of the 'tests' below look tedious/repetitive but they are setting up variables with values
# for subsequent tests, even if this is only checking that they get changed.

# Test return value against a string/number/array or the special values:
# * EmptyArray
# * RunTimeError
# * SyntaxError
# * Undefined		A value is returned but this is undef


my @Test = (
	'123'					=>	'123',
	'1.23'					=>	'1.23',
	'"string"'				=>	'string',
	'\'ab\ncd\''				=>	'ab\ncd',
	'"ab\ncd\td\re\\f\x0a!"'		=>	"ab\ncd\td\re\\f\x0a!",
	'"Pound=\\u{a3} Euro=\\u{20ac}"'	=>	"Pound=\x{a3} Euro=\x{20ac}",	# 'Pound=£ Euro=€'
	# Something outside of the BMP:
	'"G Clef=\u{1D11E}"'			=>	"G Clef=\x{1D11E}",	# 'G Clef=𝄞'
	# UTF8 literals:
	'"Pound £ Euro € G Clef 𝄞"'		=>	'Pound £ Euro € G Clef 𝄞',
	'1 + 2 - 3'				=>	'0',
	'1 * 2 + 3'				=>	'5',
	'1 + 2 * 3'				=>	'7',
	"1 + 2 + 3 + 4"				=>	'10',
	'2 * 3 / 4'				=>	'1.5',
	'1.23 + 2'				=>	'3.23',
	'10 % 4'				=>	'2',
	'6 * 5 / 3'				=>	'10',
	'6 * 5 / 3 % 4'				=>	'2',
	'2 + 3 * 4 + 5'				=>	'19',
	'( 2 + 3 ) * 4'				=>	20,
	'1 + 2 * 3 / 4 - 5'			=>	'-2.5',
	'2 + 3 * 4 + 5 . "foo"'			=>	'19foo',
	'"foo" . 2 + 3 * 4 - 5'			=>	'foo9',
	'"foo" . 2 + 3 * 4 - 5 . "bar"'		=>	'foo9bar',
	'1 . 2 * 3 + 4 + ( 5 . 6 )',		=>	'166',
	'1 . 2 * 3 + 4 * ( 5 + 6 )'		=>	150,
	'2 * (3 + 4) * 5'			=>	'70',
	'2 * (3 + 4) * 5 * (1 + 2) . "bar"'	=>	'210bar',
	'(15 / 3)'				=>	'5',
	'12 / 2 * 3'				=>	18,
	'(12 / 2) * 3'				=>	18,
	'12 / (2 * 3)'				=>	2,

	'2 ** 3'				=>	'8',
	'2 ** (3 + 1)'				=>	'16',
	'2 ** 3 + 1'				=>	'9',
	'2 ** (0-3)'				=>	'0.125',

	'a := 2; ++a'				=>	3,
	'a'					=>	3,
	'++a'					=>	4,
	'a := 2; --a'				=>	1,
	'a'					=>	1,

	'1.23 + 0'				=>	'1.23',
	'.5 + 0'				=>	'0.5',
	'1e2 + 0'				=>	'100',
	'1.2e2 + 0'				=>	'120',
	'1.2e+2 + 0'				=>	'120',
	'1.2e-2 + 0'				=>	'0.012',
	'(1+.12)'				=>	'1.12',
	'(1*.12)'				=>	'0.12',

	# You might expect the following to produce syntax errors, but they aren't (monadic operators):
	'+2'					=>	2,
	'1-12'					=>	'-11',
	'1 - 12'				=>	'-11',
	'-12'					=>	'-12',
	'+12'					=>	'12',
	'0 + +12'				=>	'12',
	'0 + -12'				=>	'-12',
	'2 + + 3'				=>	'5',
	'2 + + + 3'				=>	'5',
	'2 -+ 3'				=>	'-1',
	'2 +- 3'				=>	'-1',
	'2 - - 3'				=>	'5',
	'2 +-+ 3'				=>	'-1',
	'2 +- -+ 3'				=>	'5',
	'2 * int(+3.5)'				=>	'6',
	'2 + int(+3.5)'				=>	'5',
	'(4)'					=>	'4',
	'(-4)'					=>	'-4',
	'-(4 * 3)'				=>	'-12',
	'(-4 * 3)'				=>	'-12',
	'(-4 * -3)'				=>	'12',
	'(4 * -3)'				=>	'-12',

	'0 + (44, 66, 22 + 1)'			=>	'23',
	'(44, 66, 22)'				=>	'44, 66, 22',

	'1 > 2'					=>	'0',
	'2 > 2'					=>	'0',
	'3 > 2'					=>	'1',

	'3 < 2'					=>	'0',
	'2 < 2'					=>	'0',
	'2 < 3'					=>	'1',

	'2 >= 3'				=>	'0',
	'3 >= 3'				=>	'1',
	'3 >= 3'				=>	'1',

	'2 <= 3'				=>	'1',
	'2 <= 2'				=>	'1',
	'3 <= 2'				=>	'0',

	'3 == 2'				=>	'0',
	'3 == 3'				=>	'1',

	'3 != 2'				=>	'1',
	'3 != 3'				=>	'0',
	'3 <> 2'				=>	'1',
	'3 <> 3'				=>	'0',

	'3 > 2 && 4 > 5'			=>	'0',
	'3 > 2 ? 99 : 200'			=>	'99',
	'3 > 4 ? 99 : 200'			=>	'200',
	'3 > 4 ? 6 + 7 : 2 + 3'			=>	'5',
	'3 > 2 ? 6 + 7 : 2 + 3'			=>	'13',

	# This used to work
#	'c := 2'				=>	2,
#	'a > b ? ( c := 3 ) : 0'		=>	3,
#	'c'					=>	3,

	'1.234e2 * 1'				=>	'123.4',
	'1.234e-2 * 1'				=>	'0.01234',
	'1.234e2 * 10'				=>	'1234',
	'1.234e2 + 12'				=>	'135.4',

	'"abc" lt "def"'			=>	'1',
	'"abc" lt "abc"'			=>	'0',
	'"def" lt "abc"'			=>	'0',

	'"abc" gt "def"'			=>	'0',
	'"abc" gt "abc"'			=>	'0',
	'"def" gt "abc"'			=>	'1',

	'"abc" le "def"'			=>	'1',
	'"abc" le "abc"'			=>	'1',
	'"def" le "abc"'			=>	'0',

	'"abc" ge "def"'			=>	'0',
	'"abc" ge "abc"'			=>	'1',
	'"def" ge "abc"'			=>	'1',

	'"abc" eq "def"'			=>	'0',
	'"abc" eq "abc"'			=>	'1',

	'"abc" ne "def"'			=>	'1',
	'"abc" ne "abc"'			=>	'0',

	'2 && 1'				=>	'1',
	'2 && 0'				=>	'0',
	'0 && 1'				=>	'0',
	'0 && 0'				=>	'0',
	'2 || 1'				=>	'1',
	'2 || 0'				=>	'1',
	'0 || 1'				=>	'1',
	'0 || 0'				=>	'0',
	'"abc" lt "def" ? (1 + 2) : (30 * 40)'	=>	'3',
	'"abc" gt "def" ? (1 + 2) : 30 * 40'	=>	'1200',
	'"abc" gt "def" ? 1 + 2 : (30 * 40)'	=>	'1200',
	'"abc" gt "def" ? 1 + 2 : 30 * 40'	=>	'1200',


	'a := 42'				=>	'42',
	'a := -42'				=>	-42,
	# Variables can contain '_'
	'_fred := 10'				=>	'10',
	'_ := 9'				=>	'9',

	# Perl would treat 012 as an octal number, that would confuse.
	# Test that it is treated as a decimal number
	'1 + 012'				=>	'13',

	# Test variables defined elsewhere:
	'$var'					=>	'42',
	'1 * 2 + $variable'			=>	'11',
	'"foo" . $bar'				=>	'foobar',
	'$foo . $bar'				=>	'6bar',

	# Assignment to variables & the different forms that a variable can take:
	'$a := 10'				=>	'10',
	'3 * $a'				=>	'30',
	'3 * a'					=>	'30',

	# Multiple assignment:
# The test below no longer works
#	'$b := ($c := 98)'			=>	'98',
	'$b := $c := (97 - 3)'			=>	'94',
	'b'					=>	'94',
	'c'					=>	'94',
	'$b := $c := 99'			=>	'99',
	'b'					=>	'99',
	'c'					=>	'99',

	# This checks the code that checks that operands to numeric operators
	# are numeric. The point is that it failed for -ve numbers 'till I fixed it.
	'a := 0 - 2'				=>	'-2',
	'b := 3 + a'				=>	'1',

	# LH of := can yeild a variable that gets assigned to:
	'aa := 8'				=>	'8',
	'bb := 9'				=>	'9',
	'1 ? aa : bb := 123'			=>	'123',
	'aa'					=>	'123',
	'bb'					=>	'9',
	'0 ? aa : bb := 124'			=>	'124',
	'aa'					=>	'123',
	'bb'					=>	'124',

	# Previously this was: (e := 10 );( f := 11) - which no longer works
	'{e := 10 };{ f := 11}'			=>	'11',
	'e'					=>	'10',
	'f'					=>	'11',
	'{e := 20 };{ f := 21};'		=>	'21',
	'e'					=>	'20',
	'f'					=>	'21',

	# Variable with no value:
	'notset'				=>	'EmptyArray',

	# A variable can be assigned an array
	'y := (13, 14, 15, 16)'			=>	'13, 14, 15, 16',

	# () generates the empty list
	'em := ()'				=>	'EmptyArray',
	# If there is nothing there pushing something puts something there:
	'push(em, 10); em'			=>	'10',
	# Check can put space between paren:
	'em := (  )'				=>	'EmptyArray',

	# The simple operand value is the last element of the array:
	'y + 1'					=>	'17',

	# Array assignment:
	'z := y'				=>	'13, 14, 15, 16',

	# Check that assignment to the original does affact what we assigned to:
	'y := (42, 43)'				=>	'42, 43',
	'z'					=>	'13, 14, 15, 16',

	# Array concatenation:
	'a1 := (1, 2, 3, 4)'			=>	'1, 2, 3, 4',
	'a2 := (9, 8, 7, 6)'			=>	'9, 8, 7, 6',
	'a1 . a2'				=>	'46',		# Last values of each array
	'a1 , a2'				=>	'1, 2, 3, 4, 9, 8, 7, 6',

	# Array functions:
	'a1 := (10, 20, 30, 40)'		=>	'10, 20, 30, 40',
	'a2 := (9, 8, 7, 6)'			=>	'9, 8, 7, 6',
	'pop(a1)'				=>	40,
	'a1'					=>	'10, 20, 30',
	'shift(a1)'				=>	10,
	'a1'					=>	'20, 30',
	'push(a1, 15)'				=>	3,
	'a1'					=>	'20, 30, 15',
	'unshift(a1, 100)'			=>	4,
	'a1'					=>	'100, 20, 30, 15',
	'unshift(a1, a2)'			=>	8,
	'a1'					=>	'9, 8, 7, 6, 100, 20, 30, 15',
	'unshift(a1, (-2, 32))'			=>	10,
	'a1'					=>	'-2, 32, 9, 8, 7, 6, 100, 20, 30, 15',
	'count(a1)'				=>	10,
	'count((32, "fred", -3))'		=>	3,
	'l := "foo"; count(l)'			=>	1,
	'str := "hello there"; strlen(str)'	=>	11,

	# Check multiple assignment, assign corresponding values:
	'(v1, v2, v3) := (42, 44, 48)'		=>	'42, 44, 48',
	'v1'					=>	'42',
	'v2'					=>	'44',
	'v3'					=>	'48',

	# The last one gets the remaining values:
	'(v4, v5) := (42, 44, 48)'		=>	'42, 44, 48',
	'v4'					=>	'42',
	'v5'					=>	'44, 48',

	# Not enough values, so the last one is unchanged:
	'v8 := 1234'				=>	'1234',
	'(v6, v7, v8) := (42, 44)'		=>	'42, 44',
	'v6'					=>	'42',
	'v7'					=>	'44',
	'v8'					=>	'1234',

	# Assignment of arrays as part of multiple works:
	'(w1, w2) := ( 2, ( 3, 4) )'		=>	'2, 3, 4',
	'w1'					=>	'2',
	'w2'					=>	'3, 4',

	# Array assignment, where the array is one of the RH values:
	'ar := ("cat", "dog")'			=>	'cat, dog',
	'ar := (ar, "cow")'			=>	'cat, dog, cow',
	'ar'					=>	'cat, dog, cow',
	'ar := ("ant", ar)'			=>	'ant, cat, dog, cow',
	'ar'					=>	'ant, cat, dog, cow',
	'ar := ("bee", ar, "duck")'		=>	'bee, ant, cat, dog, cow, duck',
	'ar'					=>	'bee, ant, cat, dog, cow, duck',

	# Conditional actions:
	'z := 10'				=>	'10',
	'if(1) { z := 12 }'			=>	'12',
	'z'					=>	'12',
	'if(0) { z := 20 }'			=>	'0',
	'z'					=>	'12',
# These no longer work:
#	'1 ? ( z := 22 ) : 9'			=>	'22',
#	'z'					=>	'22',
#	'0 ? ( z := 25 ) : 9'			=>	'9',
#	'z'					=>	'22',

	'zl := ""'				=>	'',
	'zl := zl, "fish"'			=>	', fish',
	'zl'					=>	', fish',

	# Note that is it OK to string concat undef/empty and join undef/empty lists
	'zl := EmptyList',			=>	'EmptyArray',
	'zl'					=>	'EmptyArray',
	'zl . "foo"'				=>	'foo',
	'zl := zl, zl'				=>	'EmptyArray',
	'zl := zl, "fish"'			=>	'fish',

	# Arrays:
	'a := (20,21,22); a[1] := 9'		=>	9,
	'a'					=>	'20, 9, 22',
	'a := (20,21,22); a[1] := 9; a'		=>	'20, 9, 22',
	'i := -1; a:=(20,21,22); a[(i+1)*3+2]'	=>	22,
	'a := (20,21,22); if(1)a[1] := 9'	=>	9,
	'a := (20,21,22); i := 1;'		=>	1,
	'if(i) a[i] := 9'			=>	9,
	'a := (20,21,22);i:=1'			=>	1,
	'if(i)a[++i] := 9'			=>	9,
	'anew_a[1] := 2'			=>	'RunTimeError',
	'anew_a[0] := 2'			=>	2,

	'a := (20,21,22);i := -1;'		=>	-1,
	'a[++i] := "a"; a[++i] := "b"; a[++i] := "c"' => 'c',
	'a[0]'					=>	'a',
	'a[1]'					=>	'b',
	'a[2]'					=>	'c',

	'a := (20,21,22); a[1] - a[2]'		=>	-1,
	'i := -1; j := 2; a := (20,21,22)'	=>	'20, 21, 22',
	'a[i + j] := 3'				=>	3,
	'a[1]'					=>	3,
	'a'					=>	'20, 3, 22',

	'a := (20,30,40); i := 1; ++a[i]'	=>	31,
	'a'					=>	'20, 31, 40',
	'i := -1; j := 2'			=>	2,
	'a := (20,30,40); ++a[i + j]'		=>	31,
	'a'					=>	'20, 31, 40',

	'a := (20,30,40); i := -1; a[i]'	=>	40,
	'a := (20,30,40); i := -3; a[i]'	=>	20,
	'a := (20,30,40); i := -4; a[i]'	=>	'Undefined',
	'a := (20,30,40); i := 4; a[i]'		=>	'Undefined',

	'a := (20,30,40); i := -1; ++a[i]'	=>	41,
	'a := (20,30,40); i := -3; ++a[i]'	=>	21,
	'a := (20,30,40); i := -4; ++a[i]'	=>	'Undefined',
	'a := (20,30,40); i :=  4; ++a[i]'	=>	'Undefined',

	'a := (20,30,40); i :=  -1; ++a[i]'	=>	41,
	'a'					=>	'20, 30, 41',
	'a[-2] := 15'				=>	15,
	'a'					=>	'20, 15, 41',
	'i := -2; a[i] := 16'			=>	16,
	'a'					=>	'20, 16, 41',
	'i := -2; a[++i] := 7'			=>	7,
	'a'					=>	'20, 16, 7',
	'a[-3] := -6'				=>	-6,
	'a'					=>	'-6, 16, 7',
	'i := 4; i := a[-3] := -30'		=>	-30,
	'a'					=>	'-30, 16, 7',
	'i'					=>	-30,
	'i := 4; a[-3] := i := -32'		=>	-32,
	'a'					=>	'-32, 16, 7',
	'i'					=>	-32,
	'i := 4; a[-3] := a[2] := -33'		=>	-33,
	'a'					=>	'-33, 16, -33',

	# Max index exceeded:
	'a := (20,21,22); a[200] := 3'		=>	'RunTimeError',



	# Functions:
	'printf(">>%3.3d<<", 12)'		=>	'>>012<<',
	'int(0 - 16 / 3)'			=>	'-5',
	'int(16 / 3) + 1'			=>	'6',

	'round( 1.2 )'				=>	'1',
	'round( - 1.2 )'			=>	'0',
	'round( 0 )'				=>	'0',

	'abs(4)'				=>	'4',
	'abs(-4)'				=>	'4',
	'abs(4 * 3)'				=>	'12',
	'abs(-4 * 3)'				=>	'12',
	'abs(-4 * -3)'				=>	'12',
	'abs(4 * -3)'				=>	'12',
	'1 + int(16 / 3)'			=>	'6',
	'1 + int(16 / 3) * 2'			=>	'11',

	# Don't use built in _TIME as there may be race conditions
	"loc := localtime(_Time)"		=>	(join ', ', localtime($Now)),
	"strftime('%H:%M:%S' , loc)"		=>	strftime('%H:%M:%S', localtime($Now)),
	"mktime(loc)"				=>	"$Now",
	'_TIME != 0'				=>	1,
	# Tests multiple args/function-as-argument:
	"strftime('%H:%M:%S',localtime(_Time))"	=>	strftime('%H:%M:%S', localtime($Now)),

	# Array value search:
	# (Could have also initialised with split)
	"months := 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'"	=>
		'Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec',
	"Feb := aindex(months, 'Feb')"		=>	1,
	"Sep := aindex(months, 'Sep')"		=>	8,
	"aindex(months, 'September')"		=>	-1,	# -1 is 'not found'

	'strs := split("[, ]+", "1, 2,3, 4")'	=>	'1, 2, 3, 4',
	'strs[0]'				=>	1,
	'strs[1]'				=>	2,
	'strs[2]'				=>	3,
	'strs[3]'				=>	4,
	'strs := split("[, ]+", "1")'		=>	'1',
	'strs := split("[, ]+", "the cat sat on the mat")'	=>	'the, cat, sat, on, the, mat',
	'strs[1]'				=>	'cat',
	'strs[-1]'				=>	'mat',
	"cat := aindex(strs, 'cat')"		=>	1,
	'strs := split("\.", "en_GB.utf8")'	=>	'en_GB, utf8',
	'strs[1]'				=>	'utf8',

	'list := (1, "abc", 44)'		=>	'1, abc, 44',
	'str := join("_", list)'		=>	'1_abc_44',
	'str := join("_", (1, "abc", 44))'	=>	'1_abc_44',
	'str := join("_", (144))'		=>	'144',

	# User defined functions, numArgs() returns the number of arguments:
	'numArgs(12)'				=>	'1',
	'numArgs()'				=>	'0',
	'em := ()'				=>	'EmptyArray',
	'numArgs(em)'				=>	'0',
	'list := (2, 4, 6, 8)'			=>	'2, 4, 6, 8',
	'numArgs(list)'				=>	'4',

	# sumArgs() returns the numeric sum of the argument listg:
	'sumArgs()'				=>	'0',
	'sumArgs(em)'				=>	'0',
	'sumArgs(list)'				=>	'20',
	'sumArgs(1, 2, 3)'			=>	'6',

	# Variables defined or not, this function has special status in the evaluator:
	'defined(FooBar)'			=>	'0',
	'FooBar := "baz"'			=>	'baz',
	'defined(FooBar)'			=>	'1',

	# Here is another way that we could do a sort of defined, not not so nice:
	'BarFoo . "" ne "" ? 1 : 0'		=>	'0',
	'BarFoo := "value"'			=>	'value',
	'BarFoo . "" ne "" ? 1 : 0'		=>	'1',

	# Multiple expressions, semi-colon separated. Check that all expressions were evaluated:
	'c := 12; d := 3; c * d'		=>	36,
	'c'					=>	12,
	'd'					=>	3,

	'a := 42; b := 8; c := 10 + b'		=>	18,
	'a'					=>	42,
	'b'					=>	8,

	'a := b := 5; c := d := 7'		=>	7,
	'a'					=>	5,
	'b'					=>	5,
	'c'					=>	7,
	'd'					=>	7,

	'a := 42 + 10 * 8'			=>	122,
	'a := 42 + 10 * 8;'			=>	122,
	'a := 42 + 10 * 8;;;;'			=>	122,
	'a := 42 - 1; b:= 10 * 2 ; c := 99;'	=>	99,
	'a'					=>	41,
	'b'					=>	20,
	'c'					=>	99,
	'a := 42 - 2;;; b:= 11 * 2 ;; c := 89;'	=>	89,
	'a'					=>	40,
	'b'					=>	22,
	'c'					=>	89,
	'a := 42 - 1; b:= 10 * 2 + a; c := 99;'	=>	99,
	'b'					=>	61,

	# Maybe it should error this, but it is benign:
	'; b := 9'				=>	9,

	# Curly braces:
	'{a := 42; b := 7; c := 9 + b}'		=>	16,
	'a'					=>	42,
	'b'					=>	7,
	'c'					=>	16,
	# Check that can put (useless) ';' in various places
	# Quite a few tests differ in having/not-having a trailing ';'
	'{a := 52; b := 6; c := 8 + b;}'	=>	14,
	'a'					=>	52,
	'b'					=>	6,
	'c'					=>	14,
	'{a := 42; b := 8; c := 10 + b};;'	=>	18,
	'{a := (42 + 1); b:=10*2; c := 99};;;{ d := 999}' => 999,
	'a'					=>	43,
	'b'					=>	20,
	'c'					=>	99,
	'd'					=>	999,

	'a := 1'				=>	1,
	'if(0){ a := 9}'			=>	0,
	'a'					=>	1,
	'a := 1'				=>	1,
	'if(0) a := 9'				=>	0,
	'a'					=>	1,
	'a := 1'				=>	1,
	'if(10){ a := 9}'			=>	9,
	'a'					=>	9,
	'a := 1'				=>	1,
	'if(10) a := 9'				=>	9,

	'a := 1'				=>	1,
	'if(0){ a := 9};'			=>	0,
	'a'					=>	1,
	'a := 1'				=>	1,
	'if(0) a := 9;'				=>	0,
	'a'					=>	1,
	'a := 1'				=>	1,
	'if(10){ a := 9};'			=>	9,
	'a'					=>	9,
	'a := 1'				=>	1,
	'if(10) a := 9;'			=>	9,
	'a'					=>	9,

	'a := 0'				=>	0,
	'b := 2'				=>	2,
	'a := 11; if(0) {a := 99; b := b+5}; a := a * 2'	=>	22,
	'a'					=>	22,
	'b'					=>	2,

	'a := 0; b := 2'			=>	2,
	'a := 11; if(1) {a := 99; b := b+5}; a := a * 2'	=>	198,
	'a'					=>	198,
	'b'					=>	7,

	'a := 0; b := 2'			=>	2,
	'a := 11; if(1 && a == 11) {a := 99; b := b+5}; a := a * 2'	=>	198,
	'a'					=>	198,
	'b'					=>	7,

	'a := 11'				=>	11,
	'if(a == 11) a := 99; a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'if(a == 11) {a := 99} a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'if(a == 11) {a := 99;} a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'if(a == 11) {a := 99}; a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'if(a == 11) {a := 99;}; a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'b := 2'				=>	2,
	'if(a == 11) {if(b == 2)a := 99}; a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'b := 2'				=>	2,
	'if(a == 11) {if(b == 2)a := 99;}; a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'b := 2'				=>	2,
	'if(a == 11) {if(b == 2){a := 99;}}; a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'b := 2'				=>	2,
	'if(a == 11) {if(b == 2){a := 99;};}; a := a * 2'	=>	198,
	'a'					=>	198,

	'a := 11'				=>	11,
	'b := 2'				=>	2,
	'if(a == 12) {if(b == 2){a := 99;};}; a := a * 2'	=>	22,
	'a'					=>	22,

	'a := b := 3; if(0) a:= b := 4; b'	=>	3,
	'a'					=>	3,
	'a := b := 3; if(1) a:= b := 4; b'	=>	4,
	'a'					=>	4,

	'a := (10, 20, 30, 40)'			=>	'10, 20, 30, 40',
	'b := 1; c := 2; if(count(a)){b:=pop(a); c:=pop(a)}'	=>	30,
	'a'					=>	'10, 20',
	'b'					=>	40,
	'c'					=>	30,
	'a := (10, 20, 30, 40)'			=>	'10, 20, 30, 40',
	'b := 3'				=>	3,
	'b := 1; if(count(a)){b:=pop(a); }'	=>	40,
	'b'					=>	40,
	'if(count(a)){ b:=pop(a) }'		=>	30,
	'b'					=>	30,
	'if(count(a))b:=pop(a)'			=>	20,
	'b'					=>	20,

	# Loops
	'i := -1'				=>	-1,
	'a := i'				=>	-1,
	'i := 0; a := 0; while(i < 4) {i := i + 1; a := a + 2}; a+i'	=>	12,
	'i'					=>	4,
	'a'					=>	8,

	'i := -1'				=>	-1,
	'i := 0; while(i < 4) {i := i + 1; }; i;' =>	4,
	'i'					=>	4,
	'i := -1'				=>	-1,
	'i := 0; while(i < 4) {i := i + 1; }; i' =>	4,
	'i'					=>	4,
	'i := -1'				=>	-1,
	'i := 0; while(i < 4) {i := i + 1 }; i'	=>	4,
	'i'					=>	4,
	'i := -1'				=>	-1,
	'i := 0; while(i < 4) {i := i + 1; }; 2*i;' =>	8,
	'i'					=>	4,
	'i := -1'				=>	-1,
	'i := 0; while(i < 4) i := i + 1;  2*i'	=>	8,
	'i'					=>	4,

	'i := -1'				=>	-1,
	'i := 0; b := 1; while(++i < 4) b := b * 2;  b'	=>	8,
	'i'					=>	4,
	'b'					=>	8,

	'a := 0; i := 0; j := 10'		=>	10,
	'while(i < 4) {j := 5; while(j > 0){j:=j-1; a:=a+1} i:=i+1}; a'	=>	20,
	'i'					=>	4,
	'j'					=>	0,
	'a'					=>	20,

	'a := 0; i := 0; j := 10'		=>	10,
	'while(i < 4) {j := 5; while(j > 0){--j; ++a} ++i}; a'	=>	20,
	'i'					=>	4,
	'j'					=>	0,
	'a'					=>	20,

	# Nest: while -> while -> if
	'a := 0; i := 0; c := 0; j := 10'		=>	10,
	'while(i < 4) {j := 5; while(j > 0){--j; if(++a % 3 == 0) ++c} ++i}; c'	=>	6,
	'i'					=>	4,
	'j'					=>	0,
	'a'					=>	20,
	'c'					=>	6,


	# The following cause syntax errors:
	'^ xxx'					=>	'SyntaxError',
	'2 ? 3'					=>	'SyntaxError',
	'2 +'					=>	'SyntaxError',
	'+'					=>	'SyntaxError',
# This should be a syntax error but is not:
#	'2 3'					=>	'SyntaxError',
	'2 + ( 1 +'				=>	'SyntaxError',
	'2 + ( 1'				=>	'SyntaxError',
	'2 + ('					=>	'SyntaxError',
	') + 2'					=>	'SyntaxError',
	'3 ) + 2'				=>	'SyntaxError',

# The following 2 should be syntax errors, but are not:
#	'( 3 ) 2'				=>	'SyntaxError',
#	'2 ( 3 )'				=>	'SyntaxError',

	'int( 3 '				=>	'SyntaxError',
	'foo(3)'				=>	'SyntaxError',
	'{ a := 3'				=>	'SyntaxError',
	' a := 3 }'				=>	'SyntaxError',
	'++(b)'					=>	'SyntaxError',
	'++2'					=>	'SyntaxError',

	# The following generate run time errors
	'1 + "fred"'				=>	'RunTimeError',
);

use Test::Simple;

# Output # tests that we expect to do:
my $NumTests = (scalar @Test) / 2;
print "1..$NumTests\n";

my $Tests = 0;
for(my $inx = 0; $inx < $#Test; $inx += 2 ) {

	my $in = $Test[$inx];
	my $result = $Test[$inx + 1];

	$Tests++;

	$OriginalExpression = $in;
	$RunError = $ExprError = 0;

	print "\nParse: ''$in'' FailsSoFar=$NumFails\n" if($verbose);
	$Operation = 'parsing';
	my $tree = $ArithEnv->Parse($in);

	if($ExprError) {
		if($result eq 'SyntaxError') {
			print "ok $Tests - Parse fail -- as expected: ''$in''\n";
		} else {
			print "not ok $Tests - Parse fail -- unexpectedly: ''$in''\n";

			$NumFails++;
		}
		$ArithEnv->PrintTree($tree) if($errtree);
		next;
	}

	unless(defined($tree)) {
		print "not ok $Tests - Tree undefined for expression ''$in''\n";

		$NumFails++;
		next;
	}

	&printv("parse => $tree\n");

	$ArithEnv->PrintTree($tree) if($verbose > 1);

	$Operation = 'evaluating';
	my @res = $ArithEnv->Eval($tree);

	if($#res == -1 and $result eq 'EmptyArray') {
		if($RunError) {
			printf "not ok $Tests - Failed unexpectedly: ''%s''\n", $in;

			$NumFails++;
			$ArithEnv->PrintTree($tree) if($errtree);
		}
		printf "ok $Tests - Result is empty array, as expected: ''%s''\n", $in;
		next;
	}

	if($#res == -1 or $RunError) {
		my $rterp = $RunError ? "run time error reported" : "run time error not reported";
		if($result eq 'RunTimeError') {
			printf "ok $Tests - Failed at run time - as expected, %s: ''%s''\n", $rterp, $in;
			next;
		}
		printf "not ok $Tests - Failed unexpectedly, %s: ''%s''\n", $rterp, $in;

		$NumFails++;
		next;
	}

	&printv("expr ''$in'' ");
	if($#res == 0) {
		if( !defined($res[0])) {
			# Value returned in element 0 is not defined - as opposed to the test above which is
			# the entire array is not defined, ie undef returned
			if($result eq 'Undefined') {
				# This is what was expected
				printf "ok $Tests - Undefined value - as expected: ''%s'\n", $in;
				next;
			}
			print "not ok $Tests - res=undef Should be '$result' ''$in''\n";
			next;
		}
		# I have written better code:
		printf "%s $Tests - res='%s'%s: ''%s''\n", (($res[0] eq $result) ? 'ok' : "not ok"), $res[0], (($res[0] eq $result) ? '' : " Should be '$result'"), $in;

		unless($res[0] eq $result) {
			$NumFails++;
			$ArithEnv->PrintTree($tree) if($errtree);
		}
	} else {
		my @ref = reverse split /, /, $result;
		my $ok = 'ok';
		my $res = "res=Array #elems=".@res." vals=";
		my $ev = 'Extra val ';
		foreach my $x (@res) {
			 $res .= "'$x' ";
			 my $ref = pop @ref;
			 unless(defined($ref)) {
				$res .= "$ev";
				$ev = '';
				$ok = 'not ok';
				next;
			 }
			 next if($ref eq $x);
			 $res .= "!= '$ref', ";
			 $ok = 'not ok'
		}

		printf "$ok $Tests - %s\n", $res;
		$NumFails++ if($ok ne 'ok');
	}
}

print "\n\n";
print "# $Tests tests run\n";
print $NumFails == 0 ? "# All tests OK\n" : "# $NumFails tests failed\n";

# end
