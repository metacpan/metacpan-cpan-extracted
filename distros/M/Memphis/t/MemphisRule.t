#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 16;
use Memphis;

exit main() unless caller;


sub main {
	my $rule = Memphis::Rule->new();
	isa_ok($rule, 'Memphis::Rule');
	
	is($rule->type, 'unknown', "default type");
	$rule->type('node');
	is($rule->type, 'node', "set type");

	is_deeply($rule->keys, [], "keys empty");
	
	$rule->keys(['ab', 'bc', 'cd']);
	is_deeply($rule->keys, ['ab', 'bc', 'cd'], "keys set");

	$rule->keys(['one', 'two', 'three']);
	is_deeply($rule->keys, ['one', 'two', 'three'], "keys set again");


	is_deeply($rule->values, [], "values empty");

	$rule->values(['ab2', 'bc3', 'cd4']);
	is_deeply($rule->values, ['ab2', 'bc3', 'cd4'], "values set");

	$rule->values(['one-1', 'two-2', 'three-3']);
	is_deeply($rule->values, ['one-1', 'two-2', 'three-3'], "values set again");


	my $copy = $rule->copy();
	isa_ok($copy, 'Memphis::Rule');
	is_deeply($copy->keys, ['one', 'two', 'three'], "keys from copy");
	is_deeply($rule->values, ['one-1', 'two-2', 'three-3'], "values from copy");
	
	$copy->keys(['one-1', 'two-2', 'three-3']);
	is_deeply($copy->keys, ['one-1', 'two-2', 'three-3'], "set keys in copy");
	$copy->values(['one', 'two', 'three']);
	is_deeply($copy->values, ['one', 'two', 'three'], "set values in copy");

	is_deeply($rule->keys, ['one', 'two', 'three'], "keys intact in original");
	is_deeply($rule->values, ['one-1', 'two-2', 'three-3'], "values intact in original");

	return 0;
}
