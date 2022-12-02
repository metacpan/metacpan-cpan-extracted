#!/usr/bin/env perl

use Test::Most tests => 1;

use strict;
use warnings;
use Graphics::Layout::Kiwisolver;

subtest "Test symbolics" => sub {
	my $x = Graphics::Layout::Kiwisolver::Variable->new('x');
	my $y = Graphics::Layout::Kiwisolver::Variable->new('y');
	my $z = Graphics::Layout::Kiwisolver::Variable->new('z');

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

	isa_ok $x + 5,  'Graphics::Layout::Kiwisolver::Expression', 'Variable + double';
	isa_ok $x - 5,  'Graphics::Layout::Kiwisolver::Expression', 'Variable - double';
	isa_ok 5 + $x,  'Graphics::Layout::Kiwisolver::Expression', 'double + Variable';
	isa_ok 5 - $x,  'Graphics::Layout::Kiwisolver::Expression', 'double - Variable';

	isa_ok -$x,  'Graphics::Layout::Kiwisolver::Term', '- Variable (unary)';

	isa_ok 2 * $x,  'Graphics::Layout::Kiwisolver::Term', 'double * Variable';
	isa_ok $x * 2,  'Graphics::Layout::Kiwisolver::Term', 'Variable * double';

	isa_ok $y / 2,  'Graphics::Layout::Kiwisolver::Term', 'Variable / double';

	isa_ok $x + $y, 'Graphics::Layout::Kiwisolver::Expression', 'Variable + Variable';
	isa_ok $x - $y, 'Graphics::Layout::Kiwisolver::Expression', 'Variable - Variable';

	isa_ok -(2 * $x),  'Graphics::Layout::Kiwisolver::Term', '- Term (unary)';

	isa_ok 2 * $x + $y / 2, 'Graphics::Layout::Kiwisolver::Expression', 'Term + Term';
	isa_ok 2 * $x - $y / 2, 'Graphics::Layout::Kiwisolver::Expression', 'Term - Term';

	isa_ok 2 * $x + 3, 'Graphics::Layout::Kiwisolver::Expression', 'Term + double';
	isa_ok 2 * $x - 3, 'Graphics::Layout::Kiwisolver::Expression', 'Term - double';
	isa_ok 3 + 2 * $x, 'Graphics::Layout::Kiwisolver::Expression', 'double + Term';
	isa_ok 3 - 2 * $x, 'Graphics::Layout::Kiwisolver::Expression', 'double - Term';

	isa_ok 2 * $x / 3,  'Graphics::Layout::Kiwisolver::Term', 'Term / double';

	isa_ok -(2 * $x + $y / 2),  'Graphics::Layout::Kiwisolver::Expression', '- Expression (unary)';

	isa_ok( (2 * $x + $y / 2) / 3,  'Graphics::Layout::Kiwisolver::Expression', 'Expression / double');

	isa_ok 0 == 2 * $x + $y / 2, 'Graphics::Layout::Kiwisolver::Constraint', 'double == Expression';
	isa_ok $z == 2 * $x + $y / 2, 'Graphics::Layout::Kiwisolver::Constraint', 'Variable == Expression';
	isa_ok 4 * $z == 2 * $x + $y / 2, 'Graphics::Layout::Kiwisolver::Constraint', 'Term == Expression';
	isa_ok 4 * $z == 2 * $x + $y / 2, 'Graphics::Layout::Kiwisolver::Constraint', 'Term == Expression';
};

done_testing;
