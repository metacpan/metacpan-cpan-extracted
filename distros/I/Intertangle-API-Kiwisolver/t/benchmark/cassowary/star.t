#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Intertangle::API::Kiwisolver;

fun star($solver, $n, $z) {
	die unless $n >= 1;
	my %vars;
	note 'There are \(n\) required constraints \( x_i + z = y_i \).';
	note 'Each input variable \(x_i\) has a medium stay.';
	note 'And each output variable \(y_i\) has a weak stay.';
	for my $i (1..$n) {
		push @{$vars{x}}, my $x_i = Intertangle::API::Kiwisolver::Variable->new("x_${i}");
		push @{$vars{y}}, my $y_i = Intertangle::API::Kiwisolver::Variable->new("y_${i}");

		$solver->addEditVariable($x_i, Intertangle::API::Kiwisolver::Strength::STRONG );
		$solver->addEditVariable($y_i, Intertangle::API::Kiwisolver::Strength::WEAK   );
		$solver->suggestValue($x_i, $i);

		$solver->addConstraint(
			( $y_i == $x_i + $z )
			| Intertangle::API::Kiwisolver::Strength::REQUIRED
		);
	}
	\%vars;
}

subtest "Star benchmark" => fun() {
	my $solver = Intertangle::API::Kiwisolver::Solver->new;
	my $n = 100;
	my $z = Intertangle::API::Kiwisolver::Variable->new('z');
	my $vars = star($solver, $n, $z);

	note 'Add a strong edit constraint to the offset \(z\)';
	$solver->addEditVariable($z, Intertangle::API::Kiwisolver::Strength::STRONG );

	$solver->updateVariables;
	is $vars->{y}[-1]->value, $n, "@{[ $vars->{y}[-1]->name ]} initially $n";

	note 'Change value of offset one time';
	my $value = 42;
	$solver->suggestValue($z, $value);
	$solver->updateVariables;

	is $vars->{y}[-1]->value, $value + $n, "@{[ $vars->{y}[-1] ]} changed to @{[ $value + $n ]}";
};

done_testing;
