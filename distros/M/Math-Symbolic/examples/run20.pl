#!/usr/bin/perl
use strict;
use warnings;

use lib '../lib';
use Math::Symbolic qw/:all/;

BEGIN {
	warn "foo";
	my $in = <STDIN>;
};

my $latex_str = "\\documentclass[12pt]{article}\n\\begin{document}\n";

# oscillation
my $term = parse_from_string(<<'HERE');
Omega * e^(i*omega*t)
HERE
$latex_str .= $term->to_latex( replace_default_greek => 1 ) . "\n\n";

# Lagrange function of Euler angles
$term = parse_from_string(<<'HERE');
(1/2)*omega*Theta*omega-U(phi, theta, psi, t)
HERE
$latex_str .= $term->to_latex( replace_default_greek => 1 ) . "\n\n";

# mapping Math::Symbolic::Variable names to plain LaTeX
my $vars = {
    p_i => 'p_{i}',
    q_i => 'q_{i}',
};

# i-th term of the Poisson parenthesis
$term = parse_from_string(<<'HERE');
partial_derivative(g, p_i)
*
partial_derivative(f, q_i)
-
partial_derivative(g, q_i)
*
partial_derivative(f, p_i)
HERE
$latex_str .= $term->to_latex(
    replace_default_greek   => 1,
    implicit_multiplication => 1,
    variable_mappings       => $vars
  )
  . "\n\n";

$latex_str .= "\\end{document}\n";

# This is a valid LaTeX document:
print $latex_str;
