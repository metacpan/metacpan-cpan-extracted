## Math/MatrixDecomposition/Eigen.pm --- eigenvalues and eigenvectors.

# Copyright (C) 2010 Ralph Schleicher.  All rights reserved.

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Commentary:
#
# Code derived from EiSPACK procedures and
# Jama's 'EigenvalueDecomposition' class.

## Code:

package Math::MatrixDecomposition::Eigen;

use strict;
use warnings;
use Carp;
use Exporter qw(import);
use Math::Complex qw();
use Scalar::Util qw(looks_like_number);

use Math::BLAS;
use Math::MatrixDecomposition::Util qw(:all);

BEGIN
{
  our $VERSION = '1.03';
  our @EXPORT_OK = qw(eig);
}

# Calculate eigenvalues and eigenvectors (convenience function).
sub eig
{
  __PACKAGE__->new (@_);
}

# Standard constructor.
sub new
{
  my $class = shift;
  my $self =
    {
     # Eigenvalues (a vector).
     value => undef,

     # Eigenvectors (an array of vectors).
     vector => undef,
    };

  bless ($self, ref ($class) || $class);

  # Process arguments.
  $self->decompose (@_)
    if @_ > 0;

  # Return object.
  $self;
}

# Calculate eigenvalues and eigenvectors.
sub decompose
{
  my $self = shift;

  # Check arguments.
  my $a = shift;

  my $m = @_ > 0 && looks_like_number ($_[0]) ? shift : sqrt (@$a);
  my $n = @_ > 0 && looks_like_number ($_[0]) ? shift : $m ? @$a / $m : 0;

  croak ('Invalid argument')
    if (@$a != ($m * $n)
	|| mod ($m, 1) != 0 || $m < 1
	|| mod ($n, 1) != 0 || $n < 1);

  croak ('Matrix has to be square')
    if $m != $n;

  # Get properties.
  my %prop = @_;

  $prop{balance} //= 1;
  $prop{normalize} //= 1;
  $prop{positive} //= 1;

  # Index of last row/column.
  my $end = $n - 1;

  # Eigenvalues (a vector).
  $$self{value} //= [];

  # Vector $d contains the real part of the eigenvalues and vector $e
  # contains the imaginary part of the eigenvalues.
  my $d = $$self{value};
  my $e = [];

  splice (@$d, $n)
    if @$d > $n;

  # Eigenvectors (an array of vectors).
  $$self{vector} //= [];

  # Matrix $Z contains the eigenvectors.
  my $Z = $$self{vector};

  splice (@$Z, $n)
    if @$Z > $n;

  for my $v (@$Z)
    {
      splice (@$v, $n)
	if @$v > $n;
    }

  # True if matrix is symmetric.
  my $sym = 1;

 SYM:

  for my $i (0 .. $end)
    {
      for my $j ($i + 1 .. $end)
	{
	  if ($$a[$i * $n + $j] != $$a[$j * $n + $i])
	    {
	      $sym = 0;
	      last SYM;
	    }
	}
    }

  if ($sym)
    {
      # Copy matrix elements.
      for my $j (0 .. $end)
	{
	  $$Z[$j] //= [];

	  for my $i (0 .. $end)
	    {
	      $$Z[$j][$i] = $$a[$i * $n + $j];
	    }
	}

      # Reduce a real symmetric matrix to a symmetric tridiagonal matrix
      # using and accumulating orthogonal similarity transformations.
      #
      # See EiSPACK procedure 'tred2'.
      if (1)
	{
	  my ($i, $j, $k, $l,
	      $f, $g, $h, $hh, $scale);

	  for $i (0 .. $end)
	    {
	      $$d[$i] = $$Z[$i][$end];
	    }

	  for $i (reverse (1 .. $end))
	    {
	      $l = $i - 1;
	      $h = 0;

	      # Scale row.
	      $scale = 0;

	      for $k (0 .. $l)
		{
		  $scale += abs ($$d[$k]);
		}

	      if ($scale == 0)
		{
		  $$e[$i] = $$d[$l];

		  for $j (0 .. $l)
		    {
		      $$d[$j] = $$Z[$j][$l];

		      $$Z[$j][$i] = 0;
		      $$Z[$i][$j] = 0;
		    }
		}
	      else
		{
		  for $k (0 .. $l)
		    {
		      $$d[$k] /= $scale;
		      $h += $$d[$k] ** 2;
		    }

		  $f = $$d[$l];
		  $g = - sign (sqrt ($h), $f);
		  $h -= $f * $g;

		  $$d[$l] = $f - $g;
		  $$e[$i] = $scale * $g;

		  # Form a*u.
		  for $j (0 .. $l)
		    {
		      $$e[$j] = 0;
		    }

		  for $j (0 .. $l)
		    {
		      $f = $$d[$j];
		      $$Z[$i][$j] = $f;
		      $g = $$e[$j] + $$Z[$j][$j] * $f;

		      for $k ($j + 1 .. $l)
			{
			  $g += $$Z[$j][$k] * $$d[$k];
			  $$e[$k] += $$Z[$j][$k] * $f;
			}

		      $$e[$j] = $g;
		    }

		  # Form p.
		  $f = 0;

		  for $j (0 .. $l)
		    {
		      $$e[$j] /= $h;
		      $f += $$e[$j] * $$d[$j];
		    }

		  # Form q.
		  $hh = $f / ($h + $h);

		  for $j (0 .. $l)
		    {
		      $$e[$j] -= $hh * $$d[$j];
		    }

		  # Form reduced a.
		  for $j (0 .. $l)
		    {
		      $f = $$d[$j];
		      $g = $$e[$j];

		      for $k ($j .. $l)
			{
			  $$Z[$j][$k] -= ($f * $$e[$k] + $g * $$d[$k]);
			}

		      $$d[$j] = $$Z[$j][$l];
		      $$Z[$j][$i] = 0;
		    }
		}

	      $$d[$i] = $h;
	    }

	  # Accumulation of transformation matrices.
	  for $i (1 .. $end)
	    {
	      $l = $i - 1;

	      $$Z[$l][$end] = $$Z[$l][$l];
	      $$Z[$l][$l] = 1;

	      $h = $$d[$i];
	      if ($h != 0)
		{
		  for $k (0 .. $l)
		    {
		      $$d[$k] = $$Z[$i][$k] / $h;
		    }

		  for $j (0 .. $l)
		    {
		      $g = 0;

		      for $k (0 .. $l)
			{
			  $g += $$Z[$i][$k] * $$Z[$j][$k];
			}

		      for $k (0 .. $l)
			{
			  $$Z[$j][$k] -= $g * $$d[$k];
			}
		    }
		}

	      for $k (0 .. $l)
		{
		  $$Z[$i][$k] = 0;
		}
	    }

	  for $j (0 .. $end)
	    {
	      $$d[$j] = $$Z[$j][$end];
	      $$Z[$j][$end] = 0;
	    }

	  $$Z[$end][$end] = 1;
	  $$e[0] = 0;
	}

      # Find the eigenvalues and eigenvectors of a symmetric tridiagonal
      # matrix by the QL method.
      #
      # See EiSPACK procedure 'tql2'.
      if (1)
	{
	  my ($i, $j, $k, $l, $m,
	      $c, $c2, $c3, $dl1, $el1, $f, $g, $h, $p, $r, $s, $s2, $t, $t2);

	  for $i (1 .. $end)
	    {
	      $$e[$i - 1] = $$e[$i];
	    }

	  $$e[$end] = 0;

	  $f = 0;
	  $t = 0;

	  for $l (0 .. $end)
	    {
	      $t2 = abs ($$d[$l]) + abs ($$e[$l]);
	      $t = $t2 if $t2 > $t;

              for ($m = $l; $m < $n; ++$m)
		{
		  last if abs ($$e[$m]) <= eps * $t;
		}

	      if ($m > $l)
		{
		  while (1)
		    {
		      $g = $$d[$l];
		      $p = ($$d[$l + 1] - $g) / (2 * $$e[$l]);
		      $r = sign (hypot ($p, 1), $p);

		      $$d[$l] = $$e[$l] / ($p + $r);
		      $$d[$l + 1] = $$e[$l] * ($p + $r);
		      $dl1 = $$d[$l + 1];
		      $h = $g - $$d[$l];

		      for $i ($l + 2 .. $end)
			{
			  $$d[$i] -= $h;
			}

		      $f += $h;

		      $p = $$d[$m];
		      $c = 1;
		      $c2 = $c;
		      $el1 = $$e[$l + 1];
		      $s = 0;

		      for $i (reverse ($l .. $m - 1))
			{
			  $c3 = $c2;
			  $c2 = $c;
			  $s2 = $s;
			  $g = $c * $$e[$i];
			  $h = $c * $p;
			  $r = hypot ($p, $$e[$i]);
			  $$e[$i + 1] = $s * $r;
			  $s = $$e[$i] / $r;
			  $c = $p / $r;
			  $p = $c * $$d[$i] - $s * $g;
			  $$d[$i + 1] = $h + $s * ($c * $g + $s * $$d[$i]);

			  for $k (0 .. $end)
			    {
			      $h = $$Z[$i + 1][$k];
			      $$Z[$i + 1][$k] = $s * $$Z[$i][$k] + $c * $h;
			      $$Z[$i][$k] = $c * $$Z[$i][$k] - $s * $h;
			    }
			}

		      $p = 0 - $s * $s2 * $c3 * $el1 * $$e[$l] / $dl1;

		      $$e[$l] = $s * $p;
		      $$d[$l] = $c * $p;

		      # Check convergence.
		      last if abs ($$e[$l]) <= eps * $t;
		    }
		}

	      $$d[$l] = $$d[$l] + $f;
	      $$e[$l] = 0;
	    }
	}
    }
  else
    {
      # Hessenberg matrix (an array of row vectors).
      my @H = map ([], 0 .. $end);

      for my $i (0 .. $end)
	{
	  for my $j (0 .. $end)
	    {
	      $H[$i][$j] = $$a[$i * $n + $j];
	    }
	}

      # Row and column indices of the beginning and end
      # of the principal sub-matrix.
      my $lo = 0;
      my $hi = $end;

      # Permutation vector.
      my @perm = ();

      # Scaling vector.
      my @scale = ();

      # Balance a real matrix and isolate eigenvalues whenever possible.
      #
      # See EiSPACK procedure 'balanc' and LAPACK procedure 'dgebal'.
      if ($prop{balance})
	{
	  @perm = (0 .. $end);
	  @scale = map (1, 0 .. $end);

	  # Work variables.
	  my ($i, $j, $k, $l,
	      $b, $b2, $c, $f, $g, $r, $s, $no_conv);

	  # Scale factors are powers of two.
	  $b = 2;
	  $b2 = $b ** 2;

	  $k = 0;
	  $l = $end;

	  if ($l > 0)
	    {
	      # Search for rows isolating an eigenvalue
	      # and push them down.
	    L:
	      {
		for $j (reverse (0 .. $l))
		  {
		    $r = 0;

		    for $i (0 .. $l)
		      {
			$r = 1 if $i != $j && $H[$j][$i] != 0;
		      }

		    next if $r != 0;

		    if ($j != $l)
		      {
			# Exchange row and column.
			@perm[$j, $l] = @perm[$l, $j];

			for $i (0 .. $l)
			  {
			    ($H[$i][$j], $H[$i][$l])
			      = ($H[$i][$l], $H[$i][$j]);
			  }

			for $i ($k .. $end)
			  {
			    ($H[$j][$i], $H[$l][$i])
			      = ($H[$l][$i], $H[$j][$i]);
			  }
		      }

		    $l -= 1;
		    next L;
		  }
	      }

	      # Search for columns isolating an eigenvalue
	      # and push them left.
	    K:
	      {
		for $j ($k .. $l)
		  {
		    $c = 0;

		    for $i ($k .. $l)
		      {
			$c = 1 if $i != $j && $H[$i][$j] != 0;
		      }

		    next if $c != 0;

		    if ($j != $k)
		      {
			# Exchange row and column.
			@perm[$j, $k] = @perm[$k, $j];

			for $i (0 .. $l)
			  {
			    ($H[$i][$j], $H[$i][$k])
			      = ($H[$i][$k], $H[$i][$j]);
			  }

			for $i ($k .. $end)
			  {
			    ($H[$j][$i], $H[$k][$i])
			      = ($H[$k][$i], $H[$j][$i]);
			  }
		      }

		    $k += 1;
		    next K;
		  }
	      }

	      ## Now balance the sub-matrix in rows k to l.

	      # Iterative loop for norm reduction.
	      while (1)
		{
		  $no_conv = 0;

		  for $i ($k .. $l)
		    {
		      $c = 0;
		      $r = 0;

		      for $j ($k .. $l)
			{
			  next if $j == $i;

			  $c += abs ($H[$j][$i]);
			  $r += abs ($H[$i][$j]);
			}

		      # Guard against zero c or r due to underflow.
		      next if $c == 0 || $r == 0;

		      $s = $c + $r;
		      $f = 1;

		      $g = $r / $b;
		      while ($c < $g)
			{
			  $f *= $b;
			  $c *= $b2;
			}

		      $g = $r * $b;
		      while ($c >= $g)
			{
			  $f /= $b;
			  $c /= $b2;
			}

		      # Now balance.
		      if (($c + $r) / $f < 0.95 * $s)
			{
			  $g = 1 / $f;

			  for $j ($k .. $end)
			    {
			      $H[$i][$j] *= $g;
			    }

			  for $j (0 .. $l)
			    {
			      $H[$j][$i] *= $f;
			    }

			  $scale[$i] *= $f;
			  $no_conv = 1;
			}
		    }

		  last unless $no_conv;
		}
	    }

	  $lo = $k;
	  $hi = $l;
	}

      # Reduce matrix to upper Hessenberg form by orthogonal similarity
      # transformations.
      #
      # See EiSPACK procedure 'orthes'.
      my @ort = ();

      if (1)
	{
	  my ($i, $j, $k, $m,
	      $f, $g, $h, $scale);

	  for $m ($lo + 1 .. $hi - 1)
	    {
	      $scale = 0;

	      for $i ($m .. $hi)
		{
		  $scale += abs ($H[$i][$m - 1]);
		}

	      next if $scale == 0;

	      $h = 0;

	      for $i (reverse ($m .. $hi))
		{
		  $ort[$i] = $H[$i][$m - 1] / $scale;
		  $h += $ort[$i] ** 2;
		}

	      $g = - sign (sqrt ($h), $ort[$m]);
	      $h -= $ort[$m] * $g;
	      $ort[$m] -= $g;

	      for $j ($m .. $end)
		{
		  $f = 0;

		  for $i (reverse ($m .. $hi))
		    {
		      $f += $ort[$i] * $H[$i][$j];
		    }

		  $f /= $h;

		  for $i ($m .. $hi)
		    {
		      $H[$i][$j] -= $f * $ort[$i];
		    }
		}

	      for $i (0 .. $hi)
		{
		  $f = 0;

		  for $j (reverse ($m .. $hi))
		    {
		      $f += $ort[$j] * $H[$i][$j];
		    }

		  $f /= $h;

		  for $j ($m .. $hi)
		    {
		      $H[$i][$j] -= $f * $ort[$j];
		    }
		}

	      $ort[$m] *= $scale;
	      $H[$m][$m - 1] = $scale * $g;
	    }
	}

      # Accumulate the orthogonal similarity transformations.
      #
      # See EiSPACK procedure 'ortran'.
      if (1)
	{
	  my ($i, $j, $k, $m,
	      $g);

	  for $j (0 .. $end)
	    {
	      $$Z[$j] //= [];

	      for $i (0 .. $end)
		{
		  $$Z[$j][$i] = ($i == $j ? 1 : 0);
		}
	    }

	  for $m (reverse ($lo + 1 .. $hi - 1))
	    {
	      next if $H[$m][$m - 1] == 0;

	      for $i ($m + 1 .. $hi)
		{
		  $ort[$i] = $H[$i][$m - 1];
		}

	      for $j ($m .. $hi)
		{
		  $g = 0;

		  for $i ($m .. $hi)
		    {
		      $g += $ort[$i] * $$Z[$j][$i];
		    }

		  $g = ($g / $ort[$m]) / $H[$m][$m - 1];

		  for $i ($m .. $hi)
		    {
		      $$Z[$j][$i] += $g * $ort[$i];
		    }
		}
	    }
	}

      # Find the eigenvalues and eigenvectors of a real upper Hessenberg
      # matrix by the QR method.
      #
      # See EiSPACK procedure 'hqr2'.
      if (1)
	{
	  my ($i, $j, $k, $l, $m,
	      $h, $g, $f, $p, $q, $r, $s, $t, $w, $x, $y, $z,
	      $norm, $iter, $not_last, $vr, $vi, $ra, $sa);

	  $t = 0;

	  # Store isolated roots.
	  for $i (0 .. $end)
	    {
	      if ($i < $lo || $i > $hi)
		{
		  $$d[$i] = $H[$i][$i];
		  $$e[$i] = 0;
		}
	    }

	  # Compute matrix norm.
	  $norm = 0;

	  for $i (0 .. $end)
	    {
	      for $j ($i .. $end)
		{
		  $norm += abs ($H[$i][$j]);
		}
	    }

	  # Search for next eigenvalue.
	  $iter = 0;

	  for ($n = $end; $n >= $lo; )
	    {
	      # Look for single small sub-diagonal element.
	      for ($l = $n; $l > $lo; --$l)
		{
		  $s = abs ($H[$l - 1][$l - 1]) + abs ($H[$l][$l]);
		  $s = $norm
		    if $s == 0;

		  last if abs ($H[$l][$l - 1]) < eps * $s;
		}

	      $x = $H[$n][$n];

	      if ($l == $n)
		{
		  # One root found,
		  $H[$n][$n] = $x + $t;

		  $$d[$n] = $H[$n][$n];
		  $$e[$n] = 0;

		  $n -= 1;
		  $iter = 0;
		}
	      elsif ($l == $n - 1)
		{
		  # Two roots found.
		  $y = $H[$n - 1][$n - 1];
		  $w = $H[$n][$n - 1] * $H[$n - 1][$n];

		  $p = ($y - $x) / 2;
		  $q = $p * $p + $w;
		  $z = sqrt (abs ($q));

		  $H[$n][$n] = $x + $t;
		  $H[$n - 1][$n - 1] = $y + $t;
		  $x = $H[$n][$n];

		  if ($q >= 0)
		    {
		      # Real pair.
		      $z = $p + sign ($z, $p);

		      $$d[$n - 1] = $x + $z;
		      $$d[$n] = $$d[$n - 1];
		      $$d[$n] = $x - $w / $z
			if $z != 0;

		      $$e[$n - 1] = 0;
		      $$e[$n] = 0;

		      $x = $H[$n][$n - 1];
		      $s = abs ($x) + abs ($z);
		      $p = $x / $s;
		      $q = $z / $s;
		      $r = sqrt ($p * $p + $q * $q);
		      $p = $p / $r;
		      $q = $q / $r;

		      # Row modification.
		      for $j ($n - 1 .. $end)
			{
			  $z = $H[$n - 1][$j];
			  $H[$n - 1][$j] = $q * $z + $p * $H[$n][$j];
			  $H[$n][$j] = $q * $H[$n][$j] - $p * $z;
			}

		      # Column modification.
		      for $i (0 .. $n)
			{
			  $z = $H[$i][$n - 1];
			  $H[$i][$n - 1] = $q * $z + $p * $H[$i][$n];
			  $H[$i][$n] = $q * $H[$i][$n] - $p * $z;
			}

		      # Accumulate transformations.
		      for $i ($lo .. $hi)
			{
			  $z = $$Z[$n - 1][$i];
			  $$Z[$n - 1][$i] = $q * $z + $p * $$Z[$n][$i];
			  $$Z[$n][$i] = $q * $$Z[$n][$i] - $p * $z;
			}
		    }
		  else
		    {
		      # Complex pair.
		      $$d[$n - 1] = $x + $p;
		      $$d[$n] = $x + $p;
		      $$e[$n - 1] = $z;
		      $$e[$n] = 0 - $z;
		    }

		  $n -= 2;
		  $iter = 0;
		}
	      else
		{
		  # Form shift.
		  $y = $H[$n - 1][$n - 1];
		  $w = $H[$n][$n - 1] * $H[$n - 1][$n];

		  # Wilkinson's original ad hoc shift.
		  if ($iter == 10 || $iter == 20)
		    {
		      $t += $x;

		      for $i ($lo .. $n)
			{
			  $H[$i][$i] -= $x;
			}

		      $s = abs ($H[$n][$n - 1]) + abs ($H[$n - 1][$n - 2]);
		      $x = 0.75 * $s;
		      $y = $x;
		      $w = -0.4375 * $s * $s;
		    }

		  # Matlab's new ad hoc shift.
		  if ($iter == 30)
		    {
		      $s = ($y - $x) / 2;
		      $s = $s * $s + $w;
		      if ($s > 0)
			{
			  $s = sqrt ($s);
			  $s = - $s if $y < $x;
			  $s = $x - $w / (($y - $x) / 2 + $s);

			  for $i ($lo .. $n)
			    {
			      $H[$i][$i] -= $s;
			    }

			  $t += $s;
			  $x = 0.964;
			  $w = $y = $x;
			}
		    }

		  ++$iter;

		  # Look for two consecutive small sub-diagonal elements.
		  for ($m = $n - 2; $m >= $l; --$m)
		    {
		      $z = $H[$m][$m];
		      $r = $x - $z;
		      $s = $y - $z;
		      $p = ($r * $s - $w) / $H[$m + 1][$m] + $H[$m][$m + 1];
		      $q = $H[$m + 1][$m + 1] - $z - $r - $s;
		      $r = $H[$m + 2][$m + 1];
		      $s = abs ($p) + abs ($q) + abs ($r);
		      $p = $p / $s;
		      $q = $q / $s;
		      $r = $r / $s;

		      last if $m == $l;
		      last if abs ($H[$m][$m - 1]) * (abs ($q) + abs ($r)) < eps * (abs ($p) * (abs ($H[$m - 1][$m - 1]) + abs ($z) + abs ($H[$m + 1][$m + 1])));
		    }

		  for $i ($m + 2 .. $n)
		    {
		      $H[$i][$i - 2] = 0;
		      $H[$i][$i - 3] = 0
			if $i > $m + 2;
		    }

		  # Double QR step.
		  for $k ($m .. $n - 1)
		    {
		      $not_last = ($k != $n - 1);

		      if ($k != $m)
			{
			  $p = $H[$k][$k - 1];
			  $q = $H[$k + 1][$k - 1];
			  $r = $not_last ? $H[$k + 2][$k - 1] : 0;
			  $x = abs ($p) + abs ($q) + abs ($r);

			  next if $x == 0;

			  $p = $p / $x;
			  $q = $q / $x;
			  $r = $r / $x;
			}

		      $s = sign (sqrt ($p * $p + $q * $q + $r * $r), $p);
		      if ($s != 0)
			{
			  if ($k != $m)
			    {
			      $H[$k][$k - 1] = 0 - $s * $x;
			    }
			  elsif ($l != $m)
			    {
			      $H[$k][$k - 1] = - $H[$k][$k - 1];
			    }

			  $p = $p + $s;
			  $x = $p / $s;
			  $y = $q / $s;
			  $z = $r / $s;
			  $q = $q / $p;
			  $r = $r / $p;

			  if ($not_last)
			    {
			      # Row modification.
			      for $j ($k .. $end)
				{
				  $p = $H[$k][$j] + $q * $H[$k + 1][$j] + $r * $H[$k + 2][$j];

				  $H[$k][$j] -= $p * $x;
				  $H[$k + 1][$j] -= $p * $y;
				  $H[$k + 2][$j] -= $p * $z;
				}

			      # Column modification.
			      for $i (0 .. min ($n, $k + 3))
				{
				  $p = $x * $H[$i][$k] + $y * $H[$i][$k + 1] + $z * $H[$i][$k + 2];

				  $H[$i][$k] -= $p;
				  $H[$i][$k + 1] -= $p * $q;
				  $H[$i][$k + 2] -= $p * $r;
				}

			      # Accumulate transformations.
			      for $i ($lo .. $hi)
				{
				  $p = $x * $$Z[$k][$i] + $y * $$Z[$k + 1][$i] + $z * $$Z[$k + 2][$i];

				  $$Z[$k][$i] -= $p;
				  $$Z[$k + 1][$i] -= $p * $q;
				  $$Z[$k + 2][$i] -= $p * $r;
				}
			    }
			  else
			    {
			      # Row modification.
			      for $j ($k .. $end)
				{
				  $p = $H[$k][$j] + $q * $H[$k + 1][$j];

				  $H[$k][$j] -= $p * $x;
				  $H[$k + 1][$j] -= $p * $y;
				}

			      # Column modification.
			      for $i (0 .. min ($n, $k + 3))
				{
				  $p = $x * $H[$i][$k] + $y * $H[$i][$k + 1];

				  $H[$i][$k] -= $p;
				  $H[$i][$k + 1] -= $p * $q;
				}

			      # Accumulate transformations.
			      for $i (0 .. $end)
				{
				  $p = $x * $$Z[$k][$i] + $y * $$Z[$k + 1][$i];

				  $$Z[$k][$i] -= $p;
				  $$Z[$k + 1][$i] -= $p * $q;
				}
			    }
			}
		    }
		}
	    }

	  # Backsubstitute to find vectors of upper triangular form.
	  return if $norm == 0;

	  for $n (reverse (0 .. $end))
	    {
	      $p = $$d[$n];
	      $q = $$e[$n];

	      if ($q == 0)
		{
		  # Real vector.
		  $m = $n;
		  $H[$n][$n] = 1;

		  for $i (reverse (0 .. $n - 1))
		    {
		      $w = $H[$i][$i] - $p;
		      $r = 0;

		      for $j ($m .. $n)
			{
			  $r += $H[$i][$j] * $H[$j][$n];
			}

		      if ($$e[$i] < 0)
			{
			  $z = $w;
			  $s = $r;
			}
		      else
			{
			  $m = $i;

			  if ($$e[$i] == 0)
			    {
			      $H[$i][$n] = ($w != 0 ?
					    0 - $r / $w :
					    0 - $r / (eps * $norm));
			    }
			  else
			    {
			      # Solve real equations.
			      $x = $H[$i][$i + 1];
			      $y = $H[$i + 1][$i];
			      $q = ($$d[$i] - $p) ** 2 + $$e[$i] ** 2;
			      $t = ($x * $s - $z * $r) / $q;

			      $H[$i][$n] = $t;
			      $H[$i + 1][$n] = (abs ($x) > abs ($z) ?
						(0 - $r - $w * $t) / $x :
						(0 - $s - $y * $t) / $z);
			    }

			  # Overflow control.
			  $t = abs ($H[$i][$n]);
			  if ((eps * $t) * $t > 1)
			    {
			      for $j ($i .. $n)
				{
				  $H[$j][$n] /= $t;
				}
			    }
			}
		    }
		}
	      elsif ($q < 0)
		{
		  # Complex vector.
		  $m = $n - 1;

		  # Last vector component chosen imaginary so that
		  # eigenvector matrix is triangular.
		  if (abs ($H[$n][$n - 1]) > abs ($H[$n - 1][$n]))
		    {
		      $H[$n - 1][$n - 1] = $q / $H[$n][$n - 1];
		      $H[$n - 1][$n] = ($p - $H[$n][$n]) / $H[$n][$n - 1];
		    }
		  else
		    {
		      ($H[$n - 1][$n - 1], $H[$n - 1][$n])
			= cdiv (0, - $H[$n - 1][$n],
				$H[$n - 1][$n - 1] - $p, $q);
		    }

		  $H[$n][$n - 1] = 0;
		  $H[$n][$n] = 1;

		  for $i (reverse (0 .. $n - 2))
		    {
		      $w = $H[$i][$i] - $p;

		      $ra = 0;
		      $sa = 0;

		      for $j ($m .. $n)
			{
			  $ra += $H[$i][$j] * $H[$j][$n - 1];
			  $sa += $H[$i][$j] * $H[$j][$n];
			}

		      if ($$e[$i] < 0)
			{
			  $z = $w;
			  $r = $ra;
			  $s = $sa;
			}
		      else
			{
			  $m = $i;

			  if ($$e[$i] == 0)
			    {
			      ($H[$i][$n - 1], $H[$i][$n])
				= cdiv (- $ra, - $sa, $w, $q);
			    }
			  else
			    {
			      # Solve complex equations.
			      $x = $H[$i][$i + 1];
			      $y = $H[$i + 1][$i];

			      $vr = ($$d[$i] - $p) ** 2 + $$e[$i] ** 2 - $q ** 2;
			      $vi = ($$d[$i] - $p) * 2 * $q;

			      if ($vr == 0 && $vi == 0)
				{
				  $vr = eps * $norm * (abs ($w) + abs ($q) + abs ($x) + abs ($y) + abs ($z));
				}

			      ($H[$i][$n - 1], $H[$i][$n])
				= cdiv ($x * $r - $z * $ra + $q * $sa,
					$x * $s - $z * $sa - $q * $ra,
					$vr,
					$vi);

			      if (abs ($x) > (abs ($z) + abs ($q)))
				{
				  $H[$i + 1][$n - 1] = (0 - $ra - $w * $H[$i][$n - 1] + $q * $H[$i][$n]) / $x;
				  $H[$i + 1][$n] = (0 - $sa - $w * $H[$i][$n] - $q * $H[$i][$n - 1]) / $x;
				}
			      else
				{
				  ($H[$i + 1][$n - 1], $H[$i + 1][$n])
				    = cdiv (0 - $r - $y * $H[$i][$n - 1],
					    0 - $s - $y * $H[$i][$n],
					    $z,
					    $q);
				}
			    }

			  # Overflow control.
			  $t = max (abs ($H[$i][$n - 1]), abs ($H[$i][$n]));
			  if ((eps * $t) * $t > 1)
			    {
			      for $j ($i .. $n)
				{
				  $H[$j][$n - 1] /= $t;
				  $H[$j][$n] /= $t;
				}
			    }
			}
		    }
		}
	    }

	  # Vectors of isolated roots.
	  for $i (0 .. $end)
	    {
	      if ($i < $lo || $i > $hi)
		{
		  for $j ($i .. $end)
		    {
		      $$Z[$j][$i] = $H[$i][$j];
		    }
		}
	    }

	  # Multiply by transformation matrix to give
	  # vectors of original full matrix.
	  for $j (reverse ($lo .. $end))
	    {
	      $m = min ($j, $hi);

	      for $i ($lo .. $hi)
		{
		  $z = 0;

		  for $k ($lo .. $m)
		    {
		      $z += $$Z[$k][$i] * $H[$k][$j];
		    }

		  $$Z[$j][$i] = $z;
		}
	    }
	}

      # Form the eigenvectors of a real general matrix by back
      # transforming those of the corresponding balanced matrix
      # determined by 'balance'.
      #
      # See EiSPACK procedure 'balbak'.
      if ($prop{balance})
	{
	  my ($i, $j, $k);

	  # Undo permutations.
	  for $i (reverse (0 .. $lo - 1))
	    {
	      $k = $perm[$i];
	      if ($k != $i)
		{
		  for $j (0 .. $end)
		    {
		      ($$Z[$j][$i], $$Z[$j][$k])
			= ($$Z[$j][$k], $$Z[$j][$i]);
		    }
		}
	    }

	  for $i ($hi + 1 .. $end)
	    {
	      $k = $perm[$i];
	      if ($k != $i)
		{
		  for $j (0 .. $end)
		    {
		      ($$Z[$j][$i], $$Z[$j][$k])
			= ($$Z[$j][$k], $$Z[$j][$i]);
		    }
		}
	    }
	}
    }

  # Create complex eigenvalues.
  for my $i (0 .. $end)
    {
      $$d[$i] = Math::Complex->make ($$d[$i], $$e[$i])
	if $$e[$i] != 0;
    }

  # Normalize eigenvectors.
  $self->normalize
    if $prop{normalize};

  # Make first non-zero vector element a positive number.
  if ($prop{positive})
    {
      my ($i, $j, $k);

      for $j (0 .. $end)
	{
	  for $i (0 .. $end)
	    {
	      next if $$Z[$j][$i] == 0;

	      if ($$Z[$j][$i] < 0)
		{
		  for $k ($i .. $end)
		    {
		      $$Z[$j][$k] = - $$Z[$j][$k];
		    }
		}

	      last;
	    }
	}
    }

  # Return object.
  $self;
}

# Normalize eigenvectors.
sub normalize
{
  my $self = shift;

  # Work variables.
  my $len;

  for my $v (@{ $$self{vector} })
    {
      $len = blas_norm (@$v, $v, norm => BLAS_TWO_NORM);
      blas_rscale (@$v, $v, alpha => $len) if $len != 0;
    }

  # Return object.
  $self;
}

# Sort eigenvalues and corresponding eigenvectors.
sub sort
{
  my $self = shift;
  my $order = shift // 'abs_desc';

  # Permutation vector.
  my @p = ();

  if ($order =~ m/\Avec_/)
    {
      my $Z = $$self{vector};

      @p = ($order eq 'vec_desc' ?
	    sort { _cmp_vec ($$Z[$b], $$Z[$a]) } 0 .. $#$Z :
	    ($order eq 'vec_asc' ?
	     sort { _cmp_vec ($$Z[$a], $$Z[$b]) } 0 .. $#$Z :
	     croak ("Invalid argument")));
    }
  elsif (grep (ref ($_), @{ $$self{value} }))
    {
      # Consider complex eigenvalues.
      my (@d, @e, @m) = ();

      for (@{ $$self{value} })
	{
	  if (ref ($_))
	    {
	      push (@d, $_->Re);
	      push (@e, $_->Im);
	      push (@m, abs ($_));
	    }
	  else
	    {
	      push (@d, $_);
	      push (@e, 0);
	      push (@m, abs ($_));
	    }
	}

      @p = ($order eq 'abs_desc' ?
	    sort { abs ($d[$b]) <=> abs ($d[$a]) || $m[$b] <=> $m[$a] || $d[$b] <=> $d[$a] || $e[$b] <=> $e[$a] } 0 .. $#d :
	    ($order eq 'abs_asc' ?
	     sort { abs ($d[$a]) <=> abs ($d[$b]) || $m[$a] <=> $m[$b] || $d[$a] <=> $d[$b] || $e[$a] <=> $e[$b] } 0 .. $#d :
	     ($order eq 'norm_desc' ?
	      sort { $m[$b] <=> $m[$a] || $d[$b] <=> $d[$a] || $e[$b] <=> $e[$a] } 0 .. $#d :
	      ($order eq 'norm_asc' ?
	       sort { $m[$a] <=> $m[$b] || $d[$a] <=> $d[$b] || $e[$a] <=> $e[$b] } 0 .. $#d :
	       ($order eq 'desc' ?
		sort { $d[$b] <=> $d[$a] || $e[$b] <=> $e[$a] } 0 .. $#d :
		($order eq 'asc' ?
		 sort { $d[$a] <=> $d[$b] || $e[$a] <=> $e[$b] } 0 .. $#d :
		 croak ("Invalid argument")))))));
    }
  else
    {
      # Only real eigenvalues.
      my $d = $$self{value};

      @p = ($order eq 'abs_desc' || $order eq 'norm_desc' ?
	    sort { abs ($$d[$b]) <=> abs ($$d[$a]) || $$d[$b] <=> $$d[$a] } 0 .. $#$d :
	    ($order eq 'abs_asc' || $order eq 'norm_asc' ?
	     sort { abs ($$d[$a]) <=> abs ($$d[$b]) || $$d[$a] <=> $$d[$b] } 0 .. $#$d :
	     ($order eq 'desc' ?
	      sort { $$d[$b] <=> $$d[$a] } 0 .. $#$d :
	      ($order eq 'asc' ?
	       sort { $$d[$a] <=> $$d[$b] } 0 .. $#$d :
	       croak ("Invalid argument")))));
    }

  # Reorder eigenvalues and corresponding eigenvectors.
  if (@p > 0)
    {
      my $ref;

      $ref = $$self{value};
      @$ref = @$ref[@p];

      $ref = $$self{vector};
      @$ref = @$ref[@p];
    }

  # Return object.
  $self;
}

# Compare two eigenvectors.
sub _cmp_vec
{
  my ($u, $v) = @_;

  croak ("Invalid argument")
    if $#$u != $#$v;

  my $d = 0;

  for my $i (0 .. $#$u)
    {
      last if $d = ($$u[$i] <=> $$v[$i]);
    }

  $d;
}

# Return one or more eigenvalues.
sub value
{
  my $self = shift;

  @_ > 0 ? @{ $$self{value} }[@_] : @{ $$self{value} };
}

*values = \&value;

# Return one or more eigenvectors.
sub vector
{
  my $self = shift;

  @_ > 0 ? @{ $$self{vector} }[@_] : @{ $$self{vector} };
}

*vectors = \&vector;

1;

__END__

=pod

=head1 NAME

Math::MatrixDecomposition::Eigen - eigenvalues and eigenvectors


=head1 SYNOPSIS

Object-oriented interface.

    use Math::MatrixDecomposition::Eigen;

    $eigen = Math::MatrixDecomposition::Eigen->new;
    $eigen->decompose ($A = [...]);

    # Decomposition is the default action for 'new'.
    # This one-liner is equivalent to the command sequence above.
    $eigen = Math::MatrixDecomposition::Eigen->new ($A = [...]);

The procedural form is even shorter.

    use Math::MatrixDecomposition qw(eig);

    $eigen = eig ($A = [...]);


=head1 DESCRIPTION


=head2 Object Instantiation

=over

=item C<eig> (...)

The C<eig> function is the short form of
C<< Math::MatrixDecomposition::Eigen->new >> (which see).
The C<eig> function has to be used as a subroutine.
It is not exported by default.

=item C<new> (...)

Create a new object.  Any arguments are forwarded to the C<decompose>
method (which see).  The C<new> constructor can be used as a class or
instance method.

=back


=head2 Instance Methods

=over

=item C<decompose> (I<a>, I<m>, I<n>, ...)

Calculate eigenvalues and eigenvectors of a real matrix.

=over

=item *

First argument I<a> is an array reference to the matrix elements.
Matrix elements are interpreted in row-major layout.

=item *

Optional second argument I<m> is the number of matrix rows.
If omitted, it is assumed that the matrix is square.

=item *

Optional third argument I<n> is the number of matrix columns.  If
omitted, the number of matrix columns is calculated automatically.

=item *

Remaining arguments are property/value pairs with the following meaning.

=over

=item C<balance> I<flag>

Whether or not to balance a non-symmetric matrix I<a>.  Default is true.

=item C<normalize> I<flag>

Whether or not to normalize the eigenvectors.  Default is true.

=item C<positive> I<flag>

Whether or not to make the first non-zero element of an eigenvector a
positive number.  Default is true.

=back

=back

Return value is the eigenvalue/eigenvector object.


=item C<normalize>

Normalize the eigenvectors.

Return value is the eigenvalue/eigenvector object.


=item C<sort> (I<order>)

Sort eigenvalues and corresponding eigenvectors or vice versa.

=over

=item *

Argument I<order> is the sorting order (a string).  The possible values
for I<order> together with their meaning is described in the following
table.

=over

=item C<"abs_desc">

Sort eigenvalues in descending order by first comparing the absolute
value of the real part, then the absolute value, then the real part,
and finally the imaginary part.

=item C<"abs_asc">

Sort eigenvalues in ascending order.  This is the reverse order of
C<"abs_desc">.

=item C<"norm_desc">

Sort eigenvalues in descending order by first comparing the absolute
value, then the real part, and finally the imaginary part.  If all
eigenvalues are real, this sorting order is equal to C<"abs_desc">.

=item C<"norm_asc">

Sort eigenvalues in ascending order.  This is the reverse order of
C<"norm_desc">.  If all eigenvalues are real, this sorting order is
equal to C<"abs_asc">.

=item C<"desc">

Sort eigenvalues in descending order by first comparing the real part
and then the imaginary part.

=item C<"asc">

Sort eigenvalues in ascending order.  This is the reverse order of
C<"desc">.

=item C<"vec_desc">

Sort eigenvectors in descending order.

=item C<"vec_asc">

Sort eigenvectors in ascending order.

=back

=back

Return value is the eigenvalue/eigenvector object.


=item C<value> (...)

=item C<values> (...)

Return one or more eigenvalues.

Arguments are one or more indices.  If no argument is specified, return
all eigenvalues as a list.

If C<$eigen> is a eigenvalues/eigenvectors object, the following
expressions are valid use cases of the C<value>/C<values> method.

    # Get all eigenvalues.
    @all = $eigen->values;

    # Get a single eigenvalue.
    $first = $eigen->value (0);

    # Get multiple eigenvalues.
    ($first, $last) = $eigen->values (0, -1);

Complex eigenvalues are L<Math::Complex|Math::Complex> objects.


=item C<vector> (...)

=item C<vectors> (...)

Return one or more eigenvectors.

Arguments are one or more indices.  If no argument is specified, return
all eigenvectors as a list.

If C<$eigen> is a eigenvalues/eigenvectors object, the following
expressions are valid use cases of the C<vector>/C<vectors> method.

    # Get all eigenvectors.
    @all = $eigen->vectors;

    # Get a single eigenvector.
    $first = $eigen->vector (0);

    # Get multiple eigenvectors.
    ($first, $last) = $eigen->vectors (0, -1);

An eigenvector is a Perl array reference.  If you modify the elements of
an eigenvector, you modify the elements of the original eigenvector.

=back


=head1 SEE ALSO

Math::L<MatrixDecomposition|Math::MatrixDecomposition>


=head2 External Links

=over

=item *

Wikipedia, L<http://en.wikipedia.org/wiki/Eigenvalue>,
L<http://en.wikipedia.org/wiki/Eigendecomposition_of_a_matrix>

=item *

MathWorld, L<http://mathworld.wolfram.com/Eigenvalue.html>,
L<http://mathworld.wolfram.com/EigenDecomposition.html>

=back


=head1 AUTHOR

Ralph Schleicher <ralph@cpan.org>

=cut

## Math/MatrixDecomposition/Eigen.pm ends here
