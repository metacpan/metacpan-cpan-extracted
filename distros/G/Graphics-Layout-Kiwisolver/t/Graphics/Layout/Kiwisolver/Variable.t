#!/usr/bin/env perl

use Test::Most tests => 4;

use strict;
use warnings;
use Graphics::Layout::Kiwisolver;
use aliased 'Graphics::Layout::Kiwisolver::Variable';

subtest "Create variable" => sub {
	my $x = Variable->new('x');
	my $no_name = Variable->new;

	is $x->name, 'x', 'check name';
	is $no_name->name, '', 'has no name';

	$x->setValue(42);
	is $x->value, 42, 'check value';
};

subtest "Reference equality variables" => sub {
	my $x = Variable->new('x');
	my $y = Variable->new('y');

	ok  $x->equals($x), 'Are equal';
	ok !$x->equals($y), 'Are not equal';
};

subtest "Add operators" => sub {
	my $x = Variable->new;
	my $y = Variable->new;
	$x->setValue(5);
	$y->setValue(6);
	my $t = $x + $y;
	is $t->value, 11, 'add up values';
};

subtest "Stringify" => sub {
	my $x = Variable->new('x');
	$x->setValue(42);
	my $whatever = Variable->new;
	$whatever->setValue(32);

	is "$x", '(x : 42)';
	is "$whatever", '([unnamed] : 32)';
};

done_testing;
