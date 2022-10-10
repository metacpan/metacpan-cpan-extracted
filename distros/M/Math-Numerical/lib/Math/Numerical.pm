package Math::Numerical;

use 5.022;
use strict;
use warnings;
use utf8;

our $VERSION = 0.02;

use feature 'signatures';
no warnings 'experimental::signatures';

use Carp;
use Config;
use Exporter 'import';
use POSIX ();

=pod

=encoding utf8

=head1 NAME

Math::Numerical

=head1 SYNOPSIS

Numerical analysis and scientific computing related functions.

  use Math::Numerical ':all';

  sub f { cos($_[0]) * $_[0] ** 2 }  # cos(x)·x²

  my $root = find_root(\&f, -1, 1);

=head1 DESCRIPTION

This module offers functions to manipulate numerical functions such as root
finding (solver), derivatives, etc. Most of the functions of this module can receive a
C<$func> argument. This argument should always be a code reference (an anonymous
sub or a reference to a named code block). And that referenced function should
expect a single scalar (numeric) argument and return a single scalar (numeric)
value. For efficiency reason, it is recommended to not name the argument of that
function (see the L<example above|/SYNOPSIS>).

=head1 FUNCTIONS

By default, none of the functions below are exported by this package. They can
be selectively imported or you can import them all with the tag C<:all>.

=cut

our @EXPORT = ();
our @EXPORT_OK = qw(find_root bracket);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# This will need to be adapted if we start using bigfloat.
use constant _EPS => $Config{uselongdouble} ? POSIX::LDBL_EPSILON : POSIX::DBL_EPSILON;
use constant _DEFAULT_TOLERANCE => 0.00001;

# Wraps the given numerical function in a way where we’re guaranteeing that it’s
# called in a scalar context and where we’re trapping its errors.
sub _wrap_func($func) {
  croak "The passed $func is not a code reference" unless ref($func) eq 'CODE';
  return sub {
    my $r = eval { &$func };
    return $r if defined $r;
    croak "The function failed: $@" if $@;
    croak "The function returned no value";
  }
}

# Returns a value with the same magnitude as $val and the same sign as $sign.
sub _sign {  # ($val, $sign)
  return $_[0] * $_[1] > 0 ? $_[0] : -$_[0];
}

=head2 find_root

  find_root($func, $x1, $x2, %params)

Given a function C<$func> assumed to be continuous and a starting interval
C<[$x1, $x2]>, tries to find a root of the function (a point where the
function’s value is 0). The root found may be either inside or outside the
starting interval.

If the function is successful it returns the root found in scalar context or, in
list context, a list with the root and the value of the function at that point
(which may not be exactly C<0>).

The current implementation of this function is based on the method C<zbrent>
from the I<L<Numerical Recipes/NR>> book.

The function supports the following parameters:

=over

=item C<max_iteration>

How many iterations of our algorithm will be applied at most while trying to
find a root for the given function. This gives an order of magnitude of the
number of times that C<$func> will be evaluated. Defaults to I<100>.

=item C<do_bracket>

Whether the C<L<bracket|/bracket>> function should be used to bracket a root of the
function before finding the root. If this is set to a false value, then the
passed C<$x1> and C<$x2> values must already form a bracket (that is, the
function must take values of opposite sign at these two points). Note that, when
they do, the C<L<bracket|/bracket>> function will immediately return these values. So,
if C<find_root> return a result with C<do_bracket> set to a I<false> value, it
will return the same result when C<do_bracket> is set to a I<true> value.
However, if C<do_bracket> is set to a I<false> value, then C<find_root> will
immediately C<L<croak|Carp>> if the starting interval does not form a bracket
of a root of the function.

When set to a I<true> value, the C<L<bracket|/bracket>> function is called with the
same arguments as those given to C<find_root>, so any parameter supported by
C<L<bracket|/bracket>> can also be passed to C<find_root>.

Defaults to I<1>.

=item C<tolerance>

Defaults to I<0.00001>.

=back

In addition, as noted above, when C<do_bracket> is true, any of the parameters
supported by the C<L<bracket|/bracket>> function can be passed and they will be
forwarded to that function.

=cut

sub find_root($func, $x1, $x2, %params) {
  my $do_bracket = $params{do_bracket} // 1;
  my $tol = $params{tolerance} // _DEFAULT_TOLERANCE;
  my $max_iter = $params{max_iteration} // 100;
  my $f = _wrap_func($func);
  my ($a, $b, $c, $d, $e);  # = ($x1, $x2, $x2);
  my ($fa, $fb, $fc);  # = ($f->($a), $f->($b));
  my ($p, $q, $r, $s, $tol1, $xm);
  if ($do_bracket) {
    ($a, $b, $fa, $fb) = bracket($func, $x1, $x2, %params);
    croak "Can’t bracket a root of the function" unless defined $a;
  } else {
    ($a, $b) = ($x1, $x2);
    ($fa, $fb) = ($f->($a), $f->($b));
    croak "A root must be bracketed in [\$x1; \$x2]"
      if ($fa > 0 && $fb > 0) || ($fa < 0 && $fb <0);
  }
  ($c, $fc) = ($b, $fb);
  for my $i (1..$max_iter) {
    if (($fb > 0 && $fc > 0) || ($fb < 0 && $fc < 0)) {
      ($c, $fc) = ($a, $fa);
      $e = $d = $b - $a;
    }
    if (abs($fc) < abs($fb)) {
      ($a, $b, $c) = ($b, $c, $b);
      ($fa, $fb, $fc) = ($fb, $fc, $fb);
    }
    $tol1 = 2 * _EPS * abs($b) + 0.5 * $tol;
    $xm = 0.5 * ($c - $b);
    return wantarray ? ($b, $fb) : $b if abs($xm) <= $tol1 || $fb == 0;
    if (abs($e) >= $tol1 && abs($fa) > abs($fb)) {
      $s = $fb / $fa;
      if ($a == $c) {
        $p = 2 * $xm *$s;
        $q = 1 - $s;
      } else {
        $q = $fa / $fc;
        $r = $fb / $fc;
        $p = $s * (2 * $xm * $q * ($q - $r)- ($b - $a) * ($r - 1));
        $q = ($q - 1) * ($r - 1) * ($s - 1);
      }
      $q = -$q if $p > 0;
      $p = abs($p);
      my $min1 = 3 * $xm * $q - abs($tol1 * $q);
      my $min2 = abs($e* $q);
      if (2 * $p < ($min1 < $min2 ? $min1 : $min2)) {
        $e = $d;
        $d = $p / $q;
      } else {
        $d = $xm;
        $e = $d;
      }
    } else {
      $d = $xm;
      $e = $d;
    }
    ($a, $fa) = ($b, $fb);
    if (abs($d) > $tol1) {
      $b +=$d;
    } else {
      $b += _sign($tol1, $xm);
    }
    $fb = $f->($b);
  }
  return;
}

=head2 bracket

  bracket($func, $x1, $x2, %params)

Given a function C<$func> assumed to be continuous and a starting interval
C<[$x1, $x2]>, tries to find a pair of point C<($a, $b)> such that the function
has a root somewhere between these two points (the root is I<bracketed> by these
points). The found points will be either inside or outside the starting
interval.

If the function is successful, it returns a list of four elements with the values
C<$a> and C<$b> and then the values of function at these two points. Otherwise
it returns an empty list.

The function will C<L<croak|Carp>> if C<$x1> and C<$x2> are equal.

The current implementation of this method is a mix of the methods C<zbrac> and
C<zbrak> from the I<L<Numerical Recipes/NR>> book.

The function supports the following parameters:

=over

=item C<max_iteration>

How many iterations of our algorithm will be applied at most while trying to
bracket the given function. This gives an order of magnitude of the number of
times that C<$func> will be evaluated. Defaults to I<100>.

=item C<do_outward>

Whether the function will try to bracket a root in an interval larger than the
one given by C<[$x1, $x2]>. Defaults to I<1>.

=item C<do_inward>

Whether the function will try to bracket a root in an interval smaller than the
one given by C<[$x1, $x2]>. Defaults to I<1>.

=item C<inward_split>

Tuning parameter describing the starting number of intervals into which the
starting interval is split when looking inward for a bracket. Defaults to I<3>.

Note that the algorithm may change and this parameter may stop working or may
take a different meaning in the future.

=item C<inward_factor>

Tuning parameter describing a factor by which the inwards interval are split
at each iteration. Defaults to I<3>.

Note that the algorithm may change and this parameter may stop working or may
take a different meaning in the future.

=item C<outward_factor>

Tuning parameter describing how much the starting interval is grown at each
iteration when looking outward for a bracket. Defaults to I<1.6>.

Note that the algorithm may change and this parameter may stop working or may
take a different meaning in the future.

=back

=cut

sub bracket ($func, $x1, $x2, %params) {
  croak "\$x1 and \$x2 must be distinct in calls to Math::Numerical::bracket (${x1})" if $x1 == $x2;
  my $max_iter = $params{max_iteration} // 100;
  croak "max_iteration must be positive" unless $max_iter > 0;
  my $do_outward = $params{do_outward} // 1;
  my $do_inward = $params{do_inward} // 1;
  croak "One of do_outward and do_inward at least should be true"
    unless $do_outward || $do_inward;
  my $inward_split = $params{inward_split} // 3;
  croak "inward_split must be at least 2" unless $inward_split >= 2;
  my $inward_factor = $params{inward_factor} // 3;
  croak "inward_factor must be at least 2" unless $inward_factor >= 2;
  my $outward_factor = $params{outward_factor} // 1.6;
  croak "outward_factor must be larger than 1" unless $outward_factor > 1;
  my $f = _wrap_func($func);
  my ($xl1, $xl2) = ($x1, $x2);
  my $f1 = $f->($x1);
  my ($fl1, $fl2) = ($f1, $f->($xl2));
  for my $i (1..$max_iter) {
    # We start with outward because the first iteration does nothing and just
    # checks the bounds that were given by the user.
    if ($do_outward) {
      return ($xl1, $xl2, $fl1, $fl2) if $fl1 * $fl2 < 0;
      if (abs($fl1) < abs($fl2)) {
        $xl1 += $outward_factor * ($xl1 -$xl2);
        $fl1 = $f->($xl1);
      } else {
        $xl2 += $outward_factor * ($xl2 -$xl1);
        $fl2 = $f->($xl2);
      }
    }
    if ($do_inward) {
      my $dx = ($x2 - $x1) / $inward_split;
      my $a = $x1;
      my ($fa, $fb) = ($f1);
      for my $j (1..$inward_split) {
        my $b = $a + $dx;
        $fb = $f->($b);
        return ($a, $b, $fa, $fb) if $fa * $fb < 0;
        ($a, $fa) = ($b, $fb);
      }
      $inward_split *= $inward_factor;
    }
    # We stop doing the inward algorithm when the number of splits exceeds
    # max_iteration, to bound the number of times the function is executed to a
    # reasonable value.
    $do_inward = 0 if $inward_split >= $max_iter;
  }
  return;
}

=head1 AUTHOR

Mathias Kende

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Mathias Kende

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over

=item NR

L<http://numerical.recipes/>

=back

=cut

1;
