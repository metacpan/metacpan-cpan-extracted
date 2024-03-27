#!/usr/bin/perl -w
use strict;
use Carp qw{croak confess};
use FileHandle;

# TESTING
# system '/usr/bin/clear';
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# go to test directory
BEGIN {
	use File::Spec;
	use File::Basename();
	my $thisf = File::Spec->rel2abs($0);
	my $thisd = File::Basename::dirname($thisf);
	chdir($thisd);
}

# load libraries
# require './module-lib.pm';

# prepare for tests
use Test::More;
$ENV{'IDOCSDEV'} and die_on_fail();
plan tests => 261;

# load JSON::Relaxed
require_ok( 'JSON::Relaxed' );


#------------------------------------------------------------------------------
# $full_raw
#
my $full_raw = <<'(RJSON)';
// a document containing all the strange things Relaxed allows:
// inline comments
// line comments
// unquoted string
// hash keys with no values
// contiguous commas
{
	// line comment
	/* inline comment  */
	x:unquoted-string,
	
	hash-key-with-no-value,
	
	// extra commas
	,,,,,
	array:[xxx,yyy,,,zzz],
	hash: {}
}
(RJSON)
#
# $full_raw
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= parse_chars
#
if (1) { ##i
	my ($parser, $rjson, @got, @should);
	my $test_name = 'parse_chars';
	
	# instantiate parser
	$parser = JSON::Relaxed::Parser->new();
	
	# set raw rjson
	$rjson = qq|//a\n/*b*/\n["c\\de"]|;
	
	# parse
	@got = $parser->parse_chars($rjson);
	error_from_rjson("parsing RJSON from parse_chars()");
	
	# normalize newlines
	foreach my $el (@got)
		{ $el =~ s|[\r\n]+|\n|sg }
	
	# set array we should get
	@should = ("//", "a", "\n", "/*", "b", "*/", "\n", "[", "\"", "c", "\\d", "e", "\"", "]");
	
	# compare
	# rtarr('parse characters', \@got, \@should);
	is_deeply(\@got, \@should, $test_name );
}
#
# parse_chars
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
##= line comment
#
if (1) { ##i
	my ($parser, $rjson, @chars, @tokens);
	
	$parser = JSON::Relaxed::Parser->new();
	$rjson = qq|//line\r\n|;
	@chars = $parser->parse_chars($rjson);
	
	# should not be any errors
	error_from_rjson('parsing line comment characters');
	
	# tokenize
	@tokens = $parser->tokenize(\@chars);
	
	# should not be any errors
	error_from_rjson('parsing line comment tokens');
	
	# should be empty array
	# rtarr('line comment', \@tokens, []);
	is_deeply(\@tokens, [], 'line comment - should be empty array' );
}
#
# line comment
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= inline comment
#
if (1) { ##i
	my ($parser, $rjson, @chars, @tokens);
	
	# parse and get characters
	$parser = JSON::Relaxed::Parser->new();
	$rjson = qq|/*comment*/|;
	@chars = $parser->parse_chars($rjson);
	
	# should not be any errors
	error_from_rjson('parsing inline comment characters');
	
	# parse tokens
	@tokens = $parser->tokenize(\@chars);
	
	# should not be any errors
	error_from_rjson('parsing inline comment tokens');
	
	# should be empty array
	# rtarr('inline comment', \@tokens, []);
	is_deeply(\@tokens, [], 'inline comment - should be empty array' );
}
#
# inline comment
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= unclosed inline comment
#
if (1) { ##i
	eval_error (
		'unclosed-inline-comment',
		sub { JSON::Relaxed::Parser->new()->parse("/*x\n") },
		'unclosed inline comment'
	);
}
#
# unclosed inline comment
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= string tokenization
#
if (1) { ##i
	my $name = 'string tokenization';
	
	# single quoted string
	token_check(q|'xyz'|, 'xyz', "$name: single quoted string");
	
	# double quoted string
	token_check(q|"xyz"|, 'xyz', "$name: double quoted string");
	
	# special escape chars
	token_check(
		q|'\b\f\n\r\t\v'|,
		qq|\b\f\n\r\t| . chr(11),
		"$name: special escape chars",
	);
	
	# misc escaped character
	token_check(q|'\x'|, 'x',  "$name: misc escaped character");
	
	# single quote in single quote
	token_check(q|'\''|, "'",  "$name: single quote in single quote");
	
	# double quote in double quote
	token_check(q|"\""|, '"',  "$name: double quote in double quote");
	
	# comment-like string in quotes
	token_check(q|"/*x*/"|, '/*x*/',  "$name: comment-like string in quotes");
	
	# unquoted string
	if (1) { ##i
		my ($parser, $rjson, @chars, @tokens, $isa_should);
		
		$parser = JSON::Relaxed::Parser->new();
		$rjson = qq|abc/*whatever*/ \t xyz//aaa\n\n|;
		@chars = $parser->parse_chars($rjson);
		
		# should not be any errors
		error_from_rjson("$name: parsing unquoted string characters");
		
		# get tokens
		@tokens = $parser->tokenize(\@chars);
		
		# should not be any errors
		error_from_rjson("$name: parsing unquoted string tokens");
		
		# should only be two tokens
		ok( (@tokens == 2), "$name: should only be two tokens" );
		
		# convenience variable
		$isa_should = 'JSON::Relaxed::Parser::Token::String::Unquoted';
		
		# first token should be a JSON::Relaxed::Parser::Token::String object
		isa_ok(
			$tokens[0],
			$isa_should,
			"$name: first token should be a String objects",
		);
		
		# second token should be a JSON::Relaxed::Parser::Token::String object
		isa_ok(
			$tokens[1],
			$isa_should,
			"$name: second token should be a String objects",
		);
		
		# first string should be abc
		cmp_ok(
			$tokens[0]->{'raw'}, 'eq', 'abc',
			"$name: first string should be abc",
		);
		
		# second string should be xyz
		cmp_ok(
			$tokens[1]->{'raw'}, 'eq', 'xyz',
			"$name: second string should be xyz",
		);
	}
}
#
# string tokenization
#------------------------------------------------------------------------------




#------------------------------------------------------------------------------
##= structural tokens
#
if (1) { ##i
	my ($parser, $rjson, @chars, @tokens);
	$parser = JSON::Relaxed::Parser->new();
	$rjson = q| {}  [] ,: |;
	@chars = $parser->parse_chars($rjson);
	
	# should not be any errors
	error_from_rjson('parsing structural tokens characters');

	@tokens = $parser->tokenize(\@chars);
	
	# should not be any errors
	error_from_rjson('parsing structural tokens tokens');
	
	# check tokens
	is_deeply(
		\@tokens,
		['{', '}', '[', ']', ',', ':'],
		'structural tokens',
	);
}
#
# structural tokens
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# invalid parse input
#
if (1) { ##i
	my $name = 'invalid parse input';
	
	# no input
	eval_error (
		'missing-parameter',
		sub { JSON::Relaxed::Parser->new()->parse() },
		"$name: no input",
	);
	
	# undefined input
	eval_error (
		'undefined-input',
		sub { JSON::Relaxed::Parser->new()->parse(undef) },
		"$name: undefined input",
	);
	
	# zero-length input
	eval_error (
		'zero-length-input',
		sub { JSON::Relaxed::Parser->new()->parse('') },
		"$name: zero-length input",
	);
	
	# space-only input
	eval_error (
		'space-only-input',
		sub { JSON::Relaxed::Parser->new()->parse(" \t\r\n ") },
		"$name: space-only input",
	);
}
#
# invalid parse input
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= document is a single string
#
if (1) { ##i
	my ($got);
	
	# single quoted string
	$got = JSON::Relaxed::Parser->new()->parse("'x'");
	error_from_rjson('document is a single string: single quoted string, parsing');
	cmp_ok($got, 'eq', 'x', 'document is a single string: single quoted string, got');
	
	# double quoted string
	$got = JSON::Relaxed::Parser->new()->parse('"x"');
	error_from_rjson('document is a single string: double quoted string, parsing');
	cmp_ok($got, 'eq', 'x', 'document is a single string: double quoted string, got');
	
	# unquoted non-boolean string
	$got = JSON::Relaxed::Parser->new()->parse('x');
	error_from_rjson('document is a single string: unquoted non-boolean string, parsing');
	cmp_ok($got, 'eq', 'x', 'document is a single string: unquoted non-boolean string, got');
	
	# null
	$got = JSON::Relaxed::Parser->new()->parse('null');
	error_from_rjson('document is a single string: null, parsing');
	is($got, undef, 'document is a single string: null, got');
	
	# NuLL
	$got = JSON::Relaxed::Parser->new()->parse('NuLL');
	error_from_rjson('document is a single string: NuLL, parsing');
	is($got, undef, 'document is a single string: NuLL, got');
	
	# true
	$got = JSON::Relaxed::Parser->new()->parse('true');
	error_from_rjson('document is a single string: true, parsing');
	cmp_ok($got, 'eq', 1, 'document is a single string: true, got');
	
	# TRuE
	$got = JSON::Relaxed::Parser->new()->parse(' TRuE ');
	error_from_rjson('document is a single string: TRuE, parsing');
	cmp_ok($got, '==', 1, 'document is a single string: TRuE, got');
	
	# false
	$got = JSON::Relaxed::Parser->new()->parse(' false ');
	error_from_rjson('document is a single string: false, parsing');
	cmp_ok($got, '==', 0, 'document is a single string: false, got');
	
	# FaLSE
	$got = JSON::Relaxed::Parser->new()->parse(' FaLSE ');
	error_from_rjson('document is a single string: FaLSE, parsing');
	cmp_ok($got, '==', 0, 'document is a single string: FaLSE, got');
}
#
# document is a single string
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= multiple-structures
#
if (1) { ##i
	my $name = 'multiple-structures';
	
	# two strings
	eval_error (
		'multiple-structures',
		sub { JSON::Relaxed::Parser->new()->parse('"x" "y"') },
		"$name: two strings",
	);
	
	# two strings with comma between them
	eval_error (
		'multiple-structures',
		sub { JSON::Relaxed::Parser->new()->parse('"x" , "y"') },
		"$name: two strings with comma between them",
	);
	
	# a string then a structure
	eval_error (
		'multiple-structures',
		sub { JSON::Relaxed::Parser->new()->parse('"x" {}') },
		"$name: a string then a structure",
	);
}
#
# multiple-structures
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= invalid-structure-opening-character
#
if (1) { ##i
	my $name = 'invalid-structure-opening-character';
	
	# colon
	eval_error (
		'invalid-structure-opening-character',
		sub { JSON::Relaxed::Parser->new()->parse(':') },
		"$name: colon",
	);
	
	# comma
	eval_error (
		'invalid-structure-opening-character',
		sub { JSON::Relaxed::Parser->new()->parse(',') },
		"$name: comma",
	);
	
	# closing }
	eval_error (
		'invalid-structure-opening-character',
		sub { JSON::Relaxed::Parser->new()->parse('}') },
		"$name: closing }",
	);
	
	# closing ]
	eval_error (
		'invalid-structure-opening-character',
		sub { JSON::Relaxed::Parser->new()->parse(']') },
		"$name: closing ]",
	);
}
#
# invalid-structure-opening-character
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= unclosed brace
#
if (1) { ##i
	my $name = 'unclosed brace';
	
	# unclosed array brace
	eval_error (
		'unclosed-array-brace',
		sub { JSON::Relaxed::Parser->new()->parse('["x", "y"') },
		"$name: unclosed array brace",
	);
	
	# unclosed hash brace
	eval_error (
		'unclosed-hash-brace',
		sub { JSON::Relaxed::Parser->new()->parse('{') },
		"$name: unclosed hash brace",
	);
	
	# unclosed hash brace in nested hash
	eval_error (
		'unclosed-hash-brace',
		sub { JSON::Relaxed::Parser->new()->parse('{x:1, y:[]') },
		"$name: unclosed hash brace in nested hash",
	);
}
#
# unclosed brace
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= basic hash and array structures
#
if (1) {
	my $name = 'basic hash and array structures';
	
	# hash
	do {
		my $struct = JSON::Relaxed::Parser->new()->parse('{ }');
		error_from_rjson("$name: parsing");
		
		# should be hash
		isa_ok( $struct, 'HASH', "$name: should be hash" );
		
		# should be empty hash
		is_deeply($struct, {}, "$name: should be empty hash");
	};
	
	# array
	do {
		my $struct = JSON::Relaxed::Parser->new()->parse('[ ]');
		error_from_rjson("$name: array parsing");
		
		# should be array
		isa_ok($struct, 'ARRAY', "$name: should be array");
		
		# should be empty array
		cmp_ok(scalar(@$struct), '==', 0, "$name: should be empty array");
	};
}
#
# basic hash and array structures
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= extra comma in array
#
if (1) {
	my $name = 'extra comma in array';
	
	my $struct = JSON::Relaxed::Parser->new()->parse('[  , , ]');
	error_from_rjson("$name: parse");
	
	# should be array
	isa_ok($struct, 'ARRAY', "$name: should be array");
	
	# should be empty array
	cmp_ok(scalar(@$struct), '==', 0, "$name: should be empty array");
}
#
# extra comma in array
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= array with one element
#
if (1) {
	my $name = 'array with one element';
	
	# quoted string
	do {
		my $array = JSON::Relaxed::Parser->new()->parse('[  "hello world" ]');
		error_from_rjson("$name ~ quoted string: parse");
		
		# should be array
		isa_ok( $array, 'ARRAY', "$name ~ quoted string: should be array");
		
		# should have one element
		cmp_ok(scalar(@$array), '==', 1, "$name ~ quoted string: should have one element");
		
		# element should be 'hello world'
		cmp_ok($array->[0], 'eq', 'hello world', "$name ~ quoted string: element should be 'hello world'");
	};
	
	# true
	do {
		my $array = JSON::Relaxed::Parser->new()->parse('[  true ]');
		error_from_rjson("$name ~ true: parse");
		
		# should be array
		isa_ok( $array, 'ARRAY', "$name ~ true: should be array" );
		
		# should have one element
		cmp_ok(scalar(@$array), '==', 1, "$name ~ true: should have one element");
		
		# element should be 1
		cmp_ok($array->[0], '==', 1, "$name ~ true: element should be 1");
	};
	
	# false
	do {
		my $array = JSON::Relaxed::Parser->new()->parse('[  false ]');
		error_from_rjson("$name ~ false: element should be 1");
		
		# should be array
		isa_ok( $array, 'ARRAY', "$name ~ false: should be array");
		
		# array should have one element
		cmp_ok( scalar(@$array), '==', 1, "$name ~ false: array should have one element" );
		
		# element should be 0
		cmp_ok( $array->[0], 'eq', 0, "$name ~ false: element should be 0" );
	};
	
	# null
	do {
		my $array = JSON::Relaxed::Parser->new()->parse('[  null ]');
		error_from_rjson("$name ~ null: parse");
		
		# should be array
		isa_ok( $array, 'ARRAY', "$name ~ null: should be array" );
		
		# array should have one element
		cmp_ok( scalar(@$array), '==', 1, "$name ~ null: array should have one element");
		
		# element should be undef
		is($array->[0], undef, "$name ~ null: element should be undef");
	};
	
	# unquoted non-boolean string
	do {
		my $array = JSON::Relaxed::Parser->new()->parse('[x]');
		error_from_rjson("$name ~ unquoted non-boolean string: parse");
		
		# should be array
		isa_ok( $array, 'ARRAY', "$name ~ unquoted non-boolean string: should be array" );
		
		# should have one element
		cmp_ok( scalar(@$array), '==', 1, "$name ~ unquoted non-boolean string: should have one element");
		
		# element should be x
		cmp_ok($array->[0], 'eq', 'x', "$name ~ unquoted non-boolean string: element should be x");
	};
}
#
# array with one element
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= unknown object for testing
#
if (1) {
	my ($parser, @chars, @tokens);
	my $name = 'unknown object for testing';
	
	# instantiate
	$parser = JSON::Relaxed::Parser->new(unknown=>'~');
	cmp_ok($parser->{'unknown'}, 'eq', '~', "$name: instantiate");
	
	# parse
	@chars = $parser->parse_chars('~');
	error_from_rjson("$name ~ parse: parse_chars");
	@tokens = $parser->tokenize(\@chars);
	error_from_rjson("$name ~ parse: tokenize");
	cmp_ok( scalar(@tokens), '==', 1, "$name ~ parse: check tokens" );
	
	# check that the first element is an unknown object
	isa_ok(
		$tokens[0],
		'JSON::Relaxed::Parser::Token::Unknown',
		"$name: first element is an unknown object",
	);
}
#
# unknown object for testing
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= missing comma between array elements
#
if (1) {
	my $name = 'missing comma between array elements';
	
	# colon in array
	eval_error (
		'unknown-array-token',
		sub { JSON::Relaxed::Parser->new()->parse('[ : ]') },
		"$name: colon in array",
	);
	
	# contiguous strings
	eval_error (
		'missing-comma-between-array-elements',
		sub { JSON::Relaxed::Parser->new()->parse('[ "x" "y" ]') },
		"$name: contiguous strings",
	);
	
	# invalid character after element
	eval_error (
		'missing-comma-between-array-elements',
		sub { JSON::Relaxed::Parser->new()->parse('[ "x" : ]') },
		"$name: invalid character after element",
	);
	
	# unknown token
	eval_error (
		'unknown-array-token',
		sub { JSON::Relaxed::Parser->new(unknown=>'~')->parse('[ ~ ]') },
		"$name: unknown token",
	);
}
#
# missing comma between array elements
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= nested array
#
if (1) {
	my ($array, $nested);
	my $name = 'nested array';
	
	# get array
	$array = JSON::Relaxed::Parser->new()->parse('[ [ null, "x" ] ]');
	error_from_rjson("$name: get array");
	
	# array should be defined
	if (! defined $array)
		{ die 'did not get defined array' }
	
	# should have array with one element
	isa_ok($array, 'ARRAY', "$name: should have array with one element");
	cmp_ok( scalar(@$array), '==', 1, "$name: should have array with one element");
	
	# nested array should have two elements
	$nested = $array->[0];
	isa_ok($nested, 'ARRAY', "$name: nested array should have two elements");
	cmp_ok(scalar(@$nested), '==', 2, "$name: nested array should have two elements");
	is($nested->[0], undef, "$name: first element should be undef");
	cmp_ok($nested->[1], 'eq', 'x', "$name: second element should be 'x'");
}
#
# nested array
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= extra comma in hash
#
if (1) {
	my ($struct);
	my $name = 'extra comma in hash';
	
	# get structure
	$struct = JSON::Relaxed::Parser->new()->parse('{  , }');
	error_from_rjson("$name: get structure");
	
	# should be hash
	isa_ok($struct, 'HASH', "$name: should be hash");
	
	# should be empty hash
	is_deeply($struct, {}, "$name: should be empty hash");
}
#
# extra comma in hash
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= invalid token after colon
#
if (1) {
	my $name = 'invalid token after colon';
	
	# comma
	do { ##i
		eval_error (
			'unexpected-token-after-colon',
			sub { JSON::Relaxed::Parser->new()->parse('{"a":,}') },
			"$name: comma",
		);
	};
	
	# end of hash
	do { ##i
		eval_error (
			'unexpected-token-after-colon',
			sub { JSON::Relaxed::Parser->new()->parse('{"a":}') },
			"$name: end of hash",
		);
	};
}
#
# invalid token after colon
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= colon last token
#
if (1) {
	my $name = 'colon last token';
	
	eval_error (
		'unclosed-hash-brace',
		sub { JSON::Relaxed::Parser->new()->parse('{"a":') },
		$name,
	);
}
#
# colon last token
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= no hash value after colon
#
if (1) { ##i
	my ($hash);
	my $name = 'no hash value after colon';
	
	# get hash
	$hash = JSON::Relaxed::Parser->new()->parse(q|{"a", 'b':2}|);
	error_from_rjson("$name: get hash");
	
	# should be hash with two elements
	isa_ok($hash, 'HASH', "$name: should be hash with two elements");
	is_deeply( $hash, {a=>undef, b=>2}, "$name: should be hash with two elements");
}
#
# no hash value after colon
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= unclosed quote
#
if (1) { ##i
	my $name = 'unclosed quote';
	
	# single quote
	eval_error (
		'unclosed-quote',
		sub { JSON::Relaxed::Parser->new()->parse("'whatever") },
		"$name: single quote",
	);
	
	# double quote
	eval_error (
		'unclosed-quote',
		sub { JSON::Relaxed::Parser->new()->parse('"whatever') },
		"$name: double quote",
	);
}
#
# unclosed quote
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= unexpected token where there should be a hash key
#
if (1) {
	my $name = 'unexpected token where there should be a hash key';
	
	# another hash
	eval_error (
		'unknown-token-for-hash-key',
		sub { JSON::Relaxed::Parser->new()->parse('{{}}') },
		"$name: another hash",
	);
	
	# an array
	eval_error (
		'unknown-token-for-hash-key',
		sub { JSON::Relaxed::Parser->new()->parse('{[]}') },
		"$name: an array",
	);
	
	# closing brace for array
	eval_error (
		'unknown-token-for-hash-key',
		sub { JSON::Relaxed::Parser->new()->parse('{]}') },
		"$name: closing brace for array",
	);
	
	# colon
	eval_error (
		'unknown-token-for-hash-key',
		sub { JSON::Relaxed::Parser->new()->parse('{:}') },
		"$name: colon",
	);
	
	# end of tokens
	eval_error (
		'unclosed-hash-brace',
		sub { JSON::Relaxed::Parser->new()->parse('{') },
		"$name: end of tokens",
	);
	
	# end of tokens in nested hash
	eval_error (
		'unclosed-hash-brace',
		sub { JSON::Relaxed::Parser->new()->parse('{"x":{') },
		"$name: end of tokens in nested hash",
	);
}
#
# unexpected token where there should be a hash key
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= unexpected token where there should be a hash value
#
if (1) {
	my $name = 'unexpected token where there should be a hash value';
	
	eval_error (
		'unclosed-hash-brace',
		sub { JSON::Relaxed::Parser->new()->parse('{"x":') },
		$name,
	);
}
#
# unexpected token where there should be a hash value
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= multiple-structures
#
if (1) {
	my $name = 'multiple-structures';
	
	# extra structure
	eval_error (
		'multiple-structures',
		sub { JSON::Relaxed::Parser->new()->parse('{}[]') },
		"$name: extra structure",
	);
	
	# extra string
	eval_error (
		'multiple-structures',
		sub { JSON::Relaxed::Parser->new()->parse('{}"whatever"') },
		"$name: extra string",
	);
}
#
# multiple-structures
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= weird space characters
#
if (1) {
	my ($str, $array);
	my $name = 'weird space characters';
	
	# set test string
	$str = qq|\b\f\n\r\t| . chr(11);
	
	# get array
	$array = JSON::Relaxed::Parser->new()->parse('[ $str ]');
	error_from_rjson("$name: parsing");
	
	# should have empty array
	isa_ok($array, 'ARRAY', "$name: should have empty array");
}
#
# weird space characters
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= unquoted boolean strings as keys are strings
#
if (1) {
	my ($hash);
	my $name = 'unquoted boolean strings as keys are strings';
	
	# get hash
	$hash = JSON::Relaxed::Parser->new()->parse('{null:null, true:true, false:false}');
	error_from_rjson("$name: ");
	
	# "null" should exist and be undef
	ok( exists($hash->{'null'}), "$name: 'null' should exist" );
	is($hash->{'null'}, undef, "$name: 'null' should be undef");
	
	# "true" and "false" should exist and be 1 and 0
	cmp_ok($hash->{'true'},  '==', 1, "$name: 'true' should exist and be 1");
	cmp_ok($hash->{'false'}, '==', 0, "$name: 'false' should exist and be 0");
}
#
# unquoted boolean strings as keys are strings
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= no content
#
if (1) {
	my $name = 'no content';
	
	# inline comment only
	eval_error (
		'no-content',
		sub { JSON::Relaxed::Parser->new()->parse("/*x*/  ") },
		"$name: inline comment only",
	);
	
	# line comment only
	eval_error (
		'no-content',
		sub { JSON::Relaxed::Parser->new()->parse("//xxx\n\n") },
		"$name: line comment only",
	);
}
#
# no content
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
##= full test
#
if (1) {
	my ($full);
	my $name = 'full test';
	
	$full = JSON::Relaxed::Parser->new()->parse($full_raw);
	error_from_rjson("$name: parse");
	
	# full object should be a hash
	isa_ok($full, 'HASH', "$name: full object should be a hash");
	
	# 'hash' element should be a hash
	isa_ok($full->{'hash'}, 'HASH', "$name: 'hash' element should be a hash");
	
	# 'array' element should be an array
	isa_ok($full->{'array'}, 'ARRAY', "$name: 'array' element should be an array");
	
	# 'hash-key-with-no-value' element should exist
	ok( exists($full->{'hash-key-with-no-value'}), "$name: 'hash-key-with-no-value' element should exist" );
	
	# should be three elements
	cmp_ok( scalar(@{$full->{'array'}}), '==', 3, "$name: should be three elements");
}
#
# full test
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= unknown-token-after-key
#
if (1) { ##i
	my $name = 'unknown-token-after-key';
	
	# end-curly after open-square
	eval_error (
		'unknown-token-after-key',
		sub { JSON::Relaxed::Parser->new()->parse("{a [ }") },
		"$name: end-curly after open-square",
	);
	
	# unclosed curly
	eval_error (
		'unknown-token-after-key',
		sub { JSON::Relaxed::Parser->new()->parse("{a b") },
		"$name: unclosed curly",
	);
}
#
# unknown-token-after-key
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
##= extra_tokens_ok
#
if (1) { ##i
	my ($parser, $struct);
	my $name = 'extra_tokens_ok';
	
	# get parser
	$parser = JSON::Relaxed::Parser->new();
	
	# line comment only
	cmp_ok(
		$parser->extra_tokens_ok(), '==', 0,
		"$name: initial extra_tokens_ok should be 0",
	);
	
	# set extra_tokens_ok to true
	$parser->extra_tokens_ok(1);
	cmp_ok($parser->extra_tokens_ok(), '==', 1, "$name: set extra_tokens_ok to true");
	
	# rjson with multiple strings
	$struct = $parser->parse('"abc" "whatever"');
	error_from_rjson("$name: rjson with multiple strings, parse");
	cmp_ok($struct, 'eq', 'abc', "$name: rjson with multiple strings");
	
	# rjson with extra hash
	$struct = $parser->parse('{x:11}{j=2}');
	error_from_rjson("$name: rjson with extra hash, parse");
	cmp_ok($struct->{'x'}, '==', 11, "$name: rjson with extra hash");
	
	# rjson with extra string
	$struct = $parser->parse('{x:112}"whatever"');
	error_from_rjson("$name: rjson with extra string, parse");
	cmp_ok($struct->{'x'}, '==', 112, "$name: rjson with extra string");
	
	# set extra_tokens_ok back to false
	$parser->extra_tokens_ok(0);
	cmp_ok($parser->extra_tokens_ok(), '==', 0, "$name: set extra_tokens_ok back to false");
	
	# should now get error when parsing with multiple strings
	eval_error (
		'multiple-structures',
		sub { $parser->parse('"abc" "whatever"') },
		"$name: should now get error when parsing with multiple strings",
	);
	
	# should now get error when parsing with extra structures
	eval_error (
		'multiple-structures',
		sub { $parser->parse('{x:112}[]') },
		"$name: should now get error when parsing with extra structures",
	);
	
	# should now get error when parsing with extra string
	eval_error (
		'multiple-structures',
		sub { $parser->parse('{x:112}"whatever"') },
		"$name: should now get error when parsing with extra string",
	);
}
#
# extra_tokens_ok
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# done
# This routine is purely for a home grown testing system. It has no purpose
# outside of my own system. -Miko
#
if ($ENV{'IDOCSDEV'}) {
	require FileHandle;
	FileHandle->new('> /tmp/regtest-done.txt') or die "unable to open check file: $!";
	print "[done]\n";
}
#
# done
#------------------------------------------------------------------------------



###############################################################################
# subs
#

#------------------------------------------------------------------------------
# eval_error
#
sub eval_error {
	my ($expected, $code, $test_name) = @_;
	my ($object);
	
	# TESTING
	# println subname(); ##i
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# run code
	$object = &$code();
	
	# should not have a structure at this point
	ok((! defined $object), "$test_name: should not have defined structure");
	
	# should have error id
	ok($JSON::Relaxed::err_id, "$test_name: \$JSON::Relaxed::err_id should be true");
	
	# error should have given id
	ok(
		($JSON::Relaxed::err_id eq $expected),
		"$test_name: got $JSON::Relaxed::err_id, expected $expected"
	);
}
#
# eval_error
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# token_check
#
sub token_check {
	my ($rjson, $should, $test_name) = @_;
	my ($parser, @chars, @tokens);
	
	# TESTING
	# println subname(); ##i
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# parse
	$parser = JSON::Relaxed::Parser->new();
	@chars = $parser->parse_chars($rjson);
	
	# should not be any errors
	error_from_rjson("$test_name: parse characters");
	
	# get tokens
	@tokens = $parser->tokenize(\@chars);
	
	# should not be any errors
	error_from_rjson("$test_name: parse tokens");
	
	# should only be one token
	ok( (@tokens == 1), 'should only be one token');
	
	# should be a JSON::Relaxed::Parser::Token::String object
	isa_ok(
		$tokens[0],
		'JSON::Relaxed::Parser::Token::String',
		"$test_name: token should be 'JSON::Relaxed::Parser::Token::String'",
	);
	
	# value of str should be the given value
	ok( ($tokens[0]->{'raw'} eq $should), "$test_name: compare" );
}
#
# token_check
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# error_not_ok
#
sub error_from_rjson {
	my ($test_name) = @_;
	my $bool = $JSON::Relaxed::err_id ? 0 : 1;
	
	# TESTING
	# println subname(); ##i
	
	# $test_name is required
	$test_name or confess ('$test_name is required');
	
	# set ok
	ok($bool, $test_name);
}
#
# error_not_ok
#------------------------------------------------------------------------------


#
# subs
###############################################################################
