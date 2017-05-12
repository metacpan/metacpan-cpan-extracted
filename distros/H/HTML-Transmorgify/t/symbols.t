#!/usr/bin/perl -I.

use strict;
use Test::More qw(no_plan);
use HTML::Transmorgify::Symbols;
use warnings;

my $finished = 0;

END { ok($finished, "finished"); }

my $x = new_hash(
	foo	=> 'bar'
);

is($x->{foo}, 'bar', 'initial value');

{
	local($x->{foo}) = 'localized';
	is($x->{foo}, 'localized', 'localized');
	bar();
}

sub bar
{
	is($x->{foo}, 'localized', 'localized in bar');
}
	

is($x->{foo}, 'bar', 'back to initial value');

my $a = new_array('base');

is($a->[0], 'base', 'initial array value');

{
	local($a->[0]) = 'override';
	is($a->[0], 'override', 'override array');
	foo();
}

sub foo 
{
	is($a->[0], 'override', 'override array in foo');
}
	

is($a->[0], 'base', 'return to initial array value');

$finished = 1;
