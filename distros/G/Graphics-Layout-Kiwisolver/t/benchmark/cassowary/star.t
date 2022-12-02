#!/usr/bin/env perl

use Test::Most tests => 1;

use strict;
use warnings;
use Graphics::Layout::Kiwisolver;

sub star {
	my ($solver, $n, $z) = @_;
	die unless $n >= 1;
	my %vars;
	note 'There are \(n\) required constraints \( x_i + z = y_i \).';
	note 'Each input variable \(x_i\) has a medium stay.';
	note 'And each output variable \(y_i\) has a weak stay.';
	for my $i (1..$n) {
		push @{$vars{x}}, my $x_i = Graphics::Layout::Kiwisolver::Variable->new("x_${i}");
		push @{$vars{y}}, my $y_i = Graphics::Layout::Kiwisolver::Variable->new("y_${i}");

		$solver->addEditVariable($x_i, Graphics::Layout::Kiwisolver::Strength::STRONG );
		$solver->addEditVariable($y_i, Graphics::Layout::Kiwisolver::Strength::WEAK   );
		$solver->suggestValue($x_i, $i);

		$solver->addConstraint(
			( $y_i == $x_i + $z )
			| Graphics::Layout::Kiwisolver::Strength::REQUIRED
		);
	}
	\%vars;
}

subtest "Star benchmark" => sub {
	my $solver = Graphics::Layout::Kiwisolver::Solver->new;
	my $n = 100;
	my $z = Graphics::Layout::Kiwisolver::Variable->new('z');
	my $vars = star($solver, $n, $z);

	note 'Add a strong edit constraint to the offset \(z\)';
	$solver->addEditVariable($z, Graphics::Layout::Kiwisolver::Strength::STRONG );

	$solver->updateVariables;
	is $vars->{y}[-1]->value, $n, "@{[ $vars->{y}[-1]->name ]} initially $n";

	note 'Change value of offset one time';
	my $value = 42;
	$solver->suggestValue($z, $value);
	$solver->updateVariables;

	is $vars->{y}[-1]->value, $value + $n, "@{[ $vars->{y}[-1] ]} changed to @{[ $value + $n ]}";
};

done_testing;
