#! /usr/bin/env perl

## 02-eig.t --- test procedure for eigenvalues and eigenvectors.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

## Code:

use strict;
use warnings;
use POSIX qw(:float_h);

use Test::Simple tests => 15;

BEGIN
{
  unshift (@INC, 'lib', '../lib');
}

use Math::MatrixDecomposition::Eigen;

# Create eigenvalues/eigenvectors object.
my $eigen = Math::MatrixDecomposition::Eigen->new;

if (1)
  {
    my ($A, @e, $v);

    # Symmetric matrix.
    $A = [ 3,  0, -1,
           0,  4,  1,
          -1,  1,  3];

    $eigen->decompose ($A)->sort ("asc");

    # >> [v, e] = eig([3, 0, -1; 0, 4, 1; -1, 1, 3])
    @e = $eigen->values;
    ok (approx (\@e, [ 1.75302039628253,
		       3.44504186791263,
		       4.80193773580484],
		5E-14),
	"eig/e");

    $v = $eigen->vector (0);
    ok (approx ($v, [ 0.591009048506104,
		     -0.327985277605682,
		      0.736976229099578],
		5E-14),
	"eig/v(0)");

    # First non-zero element is a positive value.
    $v = $eigen->vector (1);
    ok (approx ($v, [ 0.736976229099578,
		      0.591009048506104,
		     -0.327985277605681],
		5E-14),
	"eig/v(1)");

    $v = $eigen->vector (2);
    ok (approx ($v, [ 0.327985277605682,
		     -0.736976229099578,
		     -0.591009048506104],
		5E-14),
	"eig/v(2)");
  }

if (1)
  {
    my ($A, @e, $v);

    # Non-symmetric matrix.
    $A = [ 2, -3,  1,
           3,  1,  3,
          -5,  2, -4];

    $eigen->decompose ($A)->sort ("asc");

    # >> [v, e] = eig([2, -3, 1; 3, 1, 3; -5, 2, -4])
    # v =
    #      -0.46499     -0.65938     -0.70711
    #      -0.34874     -0.19781      0
    #       0.81373      0.72532      0.70711
    # e =
    #            -2            0            0
    #             0            0            0
    #             0            0            1
    @e = $eigen->values;
    ok (approx (\@e, [-2,
		       0,
		       1],
		5E-14),
	"eig/e");

    $v = $eigen->vector (0);
    ok (approx ($v, [ 0.464990554975278,
		      0.348742916231458,
		     -0.813733471206735],
		5E-14),
	"eig/v(0)");

    $v = $eigen->vector (1);
    ok (approx ($v, [ 0.659380473395787,
		      0.197814142018738,
		     -0.725318520735366],
		5E-14),
	"eig/v(1)");

    $v = $eigen->vector (2);
    ok (approx ($v, [ 0.707106781186548,
		      0.000000000000000,
		     -0.707106781186547],
		5E-14),
	"eig/v(2)");
  }

if (1)
  {
    my ($A, @e, $v);

    # A (2, 2) non-symmetric matrix.
    $A = [ 3,  1,
           0,  4];

    $eigen->decompose ($A)->sort ("asc");

    # >> [v, e] = eig([3, 1; 0, 4])
    @e = $eigen->values;
    ok (approx (\@e, [ 3,
		       4],
		5E-14),
	"eig/e");

    $v = $eigen->vector (0);
    ok (approx ($v, [ 1,
		      0],
		5E-14),
	"eig/v(0)");

    # First non-zero element is a positive value.
    $v = $eigen->vector (1);
    ok (approx ($v, [sqrt (0.5),
		     sqrt (0.5)],
		5E-14),
	"eig/v(1)");
  }

if (1)
  {
    my ($A, @e, $v);

    # An ill-conditioned non-symmetric matrix.
    $A = [ -64,   82,   21,
	   144, -178,  -46,
	  -771,  962,  248];

    $eigen->decompose ($A)->sort ("asc");

    @e = $eigen->values;
    ok (approx (\@e, [1,
		      2,
		      3],
		5E-12),
	"eig/e");

    $v = $eigen->vector (0);
    map { $_ /= @$v[2] } @$v;
    ok (approx ($v, [ 13 / 173,
		     -34 / 173,
		     173 / 173],
		5E-12),
	"eig/v(0)");

    $v = $eigen->vector (1);
    map { $_ /= @$v[2] } @$v;
    ok (approx ($v, [ 2 / 18,
		     -3 / 18,
		     18 / 18],
		5E-12),
	"eig/v(1)");

    $v = $eigen->vector (2);
    map { $_ /= @$v[2] } @$v;
    ok (approx ($v, [ 1 / 11,
		     -2 / 11,
		     11 / 11],
		5E-12),
	"eig/v(2)");
  }

sub approx
{
  my ($val, $ref, $tol, $err) = @_;

  for my $i (0 .. $#$ref)
    {
      # Absolute error.
      $err = $$val[$i] - $$ref[$i];
      return 0 if abs ($err) > $tol * (abs ($$ref[$i]) || 1);
      # Relative error.
      next unless ($$ref[$i]);
      $err = $$val[$i] / $$ref[$i] - 1;
      return 0 if abs ($err) > $tol;
    }

  1;
}

## 02-eig.t ends here
