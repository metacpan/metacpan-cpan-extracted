#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Math::Symbolic qw/:all/;

# A particle being thrown on the earth:

my $energy = parse_from_string('E_pot(y) + E_kin(v)');

my $velocity =
  parse_from_string(
    '( total_derivative(x(t), t)^2 + total_derivative(y(t), t)^2 )^0.5');

my $x = parse_from_string('x_initial + v_x_initial * t');
my $y = parse_from_string('y_initial + v_y_initial * t - (g*t^2)/2');

$y->implement( g => parse_from_string('9.8') );

$velocity->implement(
    x => $x,
    y => $y
);

$velocity = $velocity->apply_derivatives()->simplify();

$energy->implement(
    E_pot => parse_from_string('m * g * y(t)'),
    E_kin => parse_from_string('0.5 * m * v(t)^2')
);

$energy->implement(
    g => parse_from_string('9.8'),
    v => $velocity,
    y => $y
);

my $specific_velocity = $velocity->new();

$specific_velocity->implement(
    x_initial   => Math::Symbolic::Constant->new(0),
    y_initial   => Math::Symbolic::Constant->new(0),
    v_x_initial => Math::Symbolic::Constant->new(5),
    v_y_initial => Math::Symbolic::Constant->new(2),
);

my ($sub) = Math::Symbolic::Compiler->compile_to_sub($specific_velocity);

foreach my $time ( 1 .. 10 ) {
    print $sub->($time), "\n";
}

