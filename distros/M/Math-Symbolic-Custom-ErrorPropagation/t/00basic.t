use strict;
use warnings;
use Test::More tests => 5;
use_ok('Math::Symbolic');
use Math::Symbolic qw/:all/;
use_ok('Math::Symbolic::Custom::ErrorPropagation');
use Math::Symbolic::Custom::ErrorPropagation;

my $f = parse_from_string('m*a');

ok( $f->apply_error_propagation()->is_identical('0'), 'No dependencies -> 0' );

my $variance = $f->apply_error_propagation('m');
ok(
    $variance->is_identical(
        '((sigma_m ^ 2) * ((partial_derivative(m * a, m)) ^ 2)) ^ 0.5'),
    'variance in case of one dependency'
);

$variance = $f->apply_error_propagation(qw/a m/);

ok( $variance->is_identical(<<'HERE'), 'variance in case of two dependencies' );
(
  ((sigma_a ^ 2) * ((partial_derivative(m * a, a)) ^ 2)) +
  ((sigma_m ^ 2) * ((partial_derivative(m * a, m)) ^ 2))
) ^ 0.5
HERE

