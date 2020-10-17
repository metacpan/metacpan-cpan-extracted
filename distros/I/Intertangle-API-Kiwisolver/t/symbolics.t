#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Intertangle::API::Kiwisolver;

subtest "Test symbolics" => fun() {
	my $x = Intertangle::API::Kiwisolver::Variable->new('x');
	my $y = Intertangle::API::Kiwisolver::Variable->new('y');
	my $z = Intertangle::API::Kiwisolver::Variable->new('z');

	my $exception = qr/std::invalid_argument/;
	my $undef = undef;
	throws_ok { my $r = $x + $undef } $exception, 'exception: Variable + undef';
	throws_ok { my $r = $undef + $x } $exception, 'exception: undef + Variable';
	throws_ok { my $r = $x - $undef } $exception, 'exception: Variable - undef';
	throws_ok { my $r = $undef - $x } $exception, 'exception: undef - Variable';
	throws_ok { my $r = $x * $undef } $exception, 'exception: Variable * undef';
	throws_ok { my $r = $undef * $x } $exception, 'exception: undef * Variable';

	throws_ok { my $r = 2*$x + $undef } $exception, 'exception: Term + undef';
	throws_ok { my $r = $undef + 2*$x } $exception, 'exception: undef + Term';
	throws_ok { my $r = (2*$x) * $undef } $exception, 'exception: Term * undef';
	throws_ok { my $r = $undef * (2*$x) } $exception, 'exception: undef * Term';

	throws_ok { my $r = (2*$x + $y / 2) + $undef } $exception, 'exception: Expression + undef';
	throws_ok { my $r = $undef + (2*$x + $y / 2) + $undef } $exception, 'exception: Expression + undef';

	isa_ok $x + 5,  'Intertangle::API::Kiwisolver::Expression', 'Variable + double';
	isa_ok $x - 5,  'Intertangle::API::Kiwisolver::Expression', 'Variable - double';
	isa_ok 5 + $x,  'Intertangle::API::Kiwisolver::Expression', 'double + Variable';
	isa_ok 5 - $x,  'Intertangle::API::Kiwisolver::Expression', 'double - Variable';

	isa_ok -$x,  'Intertangle::API::Kiwisolver::Term', '- Variable (unary)';

	isa_ok 2 * $x,  'Intertangle::API::Kiwisolver::Term', 'double * Variable';
	isa_ok $x * 2,  'Intertangle::API::Kiwisolver::Term', 'Variable * double';

	isa_ok $y / 2,  'Intertangle::API::Kiwisolver::Term', 'Variable / double';

	isa_ok $x + $y, 'Intertangle::API::Kiwisolver::Expression', 'Variable + Variable';
	isa_ok $x - $y, 'Intertangle::API::Kiwisolver::Expression', 'Variable - Variable';

	isa_ok -(2 * $x),  'Intertangle::API::Kiwisolver::Term', '- Term (unary)';

	isa_ok 2 * $x + $y / 2, 'Intertangle::API::Kiwisolver::Expression', 'Term + Term';
	isa_ok 2 * $x - $y / 2, 'Intertangle::API::Kiwisolver::Expression', 'Term - Term';

	isa_ok 2 * $x + 3, 'Intertangle::API::Kiwisolver::Expression', 'Term + double';
	isa_ok 2 * $x - 3, 'Intertangle::API::Kiwisolver::Expression', 'Term - double';
	isa_ok 3 + 2 * $x, 'Intertangle::API::Kiwisolver::Expression', 'double + Term';
	isa_ok 3 - 2 * $x, 'Intertangle::API::Kiwisolver::Expression', 'double - Term';

	isa_ok 2 * $x / 3,  'Intertangle::API::Kiwisolver::Term', 'Term / double';

	isa_ok -(2 * $x + $y / 2),  'Intertangle::API::Kiwisolver::Expression', '- Expression (unary)';

	isa_ok( (2 * $x + $y / 2) / 3,  'Intertangle::API::Kiwisolver::Expression', 'Expression / double');

	isa_ok 0 == 2 * $x + $y / 2, 'Intertangle::API::Kiwisolver::Constraint', 'double == Expression';
	isa_ok $z == 2 * $x + $y / 2, 'Intertangle::API::Kiwisolver::Constraint', 'Variable == Expression';
	isa_ok 4 * $z == 2 * $x + $y / 2, 'Intertangle::API::Kiwisolver::Constraint', 'Term == Expression';
	isa_ok 4 * $z == 2 * $x + $y / 2, 'Intertangle::API::Kiwisolver::Constraint', 'Term == Expression';
};

done_testing;
