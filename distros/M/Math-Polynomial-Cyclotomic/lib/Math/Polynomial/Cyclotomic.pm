# Copyright (c) 2019-2021 by Martin Becker.  This package is free software,
# licensed under The Artistic License 2.0 (GPL compatible).

package Math::Polynomial::Cyclotomic;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);
use Math::BigInt try => 'GMP';
use Math::Polynomial 1.019;
use Math::Prime::Util qw(
    divisors factor factor_exp euler_phi gcd is_square_free is_power
    moebius kronecker vecprod
);
require Exporter;

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
    cyclo_poly cyclo_factors cyclo_plusfactors cyclo_poly_iterate
    cyclo_lucas_cd cyclo_schinzel_cd cyclo_int_factors cyclo_int_plusfactors
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $VERSION     = '0.004';

# some polynomial with coefficient type Math::BigInt
my $default = Math::Polynomial->new(Math::BigInt->new('1'));
$default->string_config({fold_sign => 1, times => '*'});

# ----- private subroutines -----

sub _cyclo_poly {
    my ($poly, $table, $n, $divisors) = @_;
    return $table->{$n} if exists $table->{$n};
    my $m = vecprod(map { $_->[0] } factor_exp($n));    # $m = radix($n)
    my $o = $m & 1;
    $m >>= 1 if !$o;
    my $p;
    if (exists $table->{$m}) {
        $p = $table->{$m};
    }
    else {
        my $one = $poly->coeff_one;
        my @d = $divisors? (grep { not $m % $_ } @{$divisors}): divisors($m);
        $p = $poly->monomial(pop @d)->sub_const($one);
        if (@d) {
            my $b = $d[-1];
            $p /= $poly->monomial($b)->sub_const($one);
            for (my $i = 1; $i < $#d; ++$i) {
                my $r = $d[$i];
                if ($b % $r) {
                    $p /= $table->{$r} || _cyclo_poly($poly, $table, $r, \@d);
                }
            }
        }
        $table->{$m} = $p;
    }
    if (!$o) {
        $p = -$p if $m == 1;
        $m <<= 1;
        $p = $p->mirror;
        $table->{$m} = $p;
    }
    if ($m != $n) {
        $p = $p->inflate($n/$m);
        $table->{$n} = $p;
    }
    return $p;
}

# for a positive integer n, return r,s so that r is square-free and n=rs^2
sub _square_free_square {
    my ($n) = @_;
    my ($r, $s) = (1, 1);
    foreach my $be (factor_exp($n)) {
        my ($b, $e) = @{$be};
        $r *= $b if $e & 1;
        $e >>= 1;
        while ($e) {
            $s *= $b if $e & 1;
            $e >>= 1 and $b *= $b;
        }
    }
    return ($r, $s);
}

# generate polynomials C, D, satisfying the identity of Aurifeuille,
# Le Lasseur and Lucas: for n > 1, square-free,
#   n === 1 (mod 4): Phi_n(x)  = C^2 - n*x*D^2
#   else:            Phi_2n(x) = C^2 - n*x*D^2
sub _lucas_cd {
    my ($poly, $table, $n) = @_;
    my $c1 = 1 == ($n & 3);
    my $n1 = $c1? $n: $n + $n;
    if (exists $table->{"$n1 $n"}) {
        return (@{$table->{"$n1 $n"}})
    }
    my $c2 = !($n & 1);
    my $ee = euler_phi($n1);
    my $e  = $ee >> 1;
    my $one = $poly->coeff_one;
    my $nul = $poly->coeff_zero;

    my $E = $e | 1;
    my @q = ($one);
    my $cos = $one;
    my %MP = ();
    for (my $k = 2; $k <= $E; ++$k) {
        if ($k & 1) {
            push @q, $nul + kronecker($n, $k);
            next;
        }
        if ($c2 && $k & 2) {
            push @q, $nul;
            next;
        }
        $cos = -$cos if !$c1;           # $cos is cos((n-1)*k*pi/4)
        my $gk = gcd($n1, $k);
        my $mp = $MP{$gk} ||= moebius($n1 / $gk) * euler_phi($gk);
        push @q, $cos * $mp;
    }

    my @cs = ($one);
    my @ds = ($one);
    $cs[$e] = $ds[$e-1] = $one;
    for(my $k = 1, my $kk = $e - 1; $k <= $kk; ++$k, --$kk) {
        my ($c, $d) = ($nul, $nul);
        for (my $i = 0, my $j = $k-1; $j >= 0; $i += 2, --$j) {
            my $cc = $cs[$j];
            my $dd = $ds[$j];
            my ($q1, $q2) = @q[$i, $i+1];
            $c += $q1 * $n * $dd - $q2 * $cc;
            $d += $q[$i+2] * $cc - $q2 * $dd;
        }
        $c /= ($k + $k);
        $cs[$k] = $cs[$kk] = $c;
        $ds[$k] = $ds[$kk-1] = ($d + $c) / ($k + $k + 1) if $k < $kk;
    }

    my $cp = $poly->new(@cs);
    my $dp = $poly->new(@ds);
    $table->{"$n1 $n"} = [$cp, $dp];
    return ($cp, $dp);
}

# generate polynomials C, D, satisfying the identity of Beeger and Schinzel:
# for k > 1, square-free, k1 = k (if k === 1 (mod 4)), k1 = 2*k (else),
# n = odd multiple of k1: Phi_n(x) = C^2 - k*x*D^2
sub _schinzel_cd {
    my ($poly, $table, $n, $k) = @_;
    my $K = ($k & 3) == 1? $k: $k << 1;
    my $f = $n / $K;
    return () if not $f & 1;
    my $r = vecprod(map { $_->[0] } factor_exp($f));
    my $m = $f / $r * gcd($f, $k);
    if ($m > 1) {
        $n /= $m;
        $f /= $m;
    }
    my ($C, $D) = ();
    if (exists $table->{"$n $k"}) {
        ($C, $D) = @{$table->{"$n $k"}};
    }
    else {
        ($C, $D) = _lucas_cd($poly, $table, $k);
        my ($L, $M, $Q) = ();
        foreach my $p (factor($f)) {
            my $p2 = $p >> 1;
            my $kp2 = Math::BigInt->new($k)->bpow($p2);
            if (!defined $M) {
                $Q = $poly->monomial(2, $k);
                my $CC = $C->nest($Q);
                my $DD = $D->nest($Q)->shift_up(1)->mul_const($k);
                $L = $CC - $DD;
                $M = $CC + $DD;
            }
            if (kronecker($k, $p) < 0) {
                ($L, $M) = (
                    $L->nest($poly->monomial($p, $kp2)) / $M,
                    $M->nest($poly->monomial($p, $kp2)) / $L,
                );
            }
            else {
                ($L, $M) = (
                    $M->nest($poly->monomial($p, $kp2)) / $M,
                    $L->nest($poly->monomial($p, $kp2)) / $L,
                );
            }
        }
        if (defined $M) {
            $C = ($M + $L)->div_const(2)->unnest($Q);
            $D = (($M - $L) / $poly->monomial(1, $k << 1))->unnest($Q);
            $table->{"$n $k"} = [$C, $D];
        }
    }
    if ($m > 1) {
        $C = $C->inflate($m);
        $D = $D->inflate($m)->shift_up($m >> 1);
    }
    return ($C, $D);
}

# for r > 1, integer, square-free, s > 0, integer, x = r*s^2,
# r1 = r (if r === 1 (mod 4)), r1 = 2*r (else), n = odd multiple of r1,
# generate integer factors l < m such that l * m = Phi_n(x).
# if l = 1, return (m) else (l, m).
sub _schinzel_lm {
    my ($poly, $table, $n, $r, $s, $x) = @_;
    my ($c, $d) = _schinzel_cd($poly, $table, $n, $r);
    my $cx = $c->evaluate($x);
    my $dx = $d->evaluate($x) * $r * $s;
    my ($l, $m) = ($cx - $dx, $cx + $dx);
    return $m if $l == $poly->coeff_one;
    return ($l, $m);
}

# ----- Math::Polynomial extension -----

sub Math::Polynomial::cyclotomic {
    my ($this, $n, $table) = @_;
    return _cyclo_poly($this, $table || {}, $n);
}

sub Math::Polynomial::cyclo_factors {
    my ($this, $n, $table) = @_;
    my @d = divisors($n);
    $table ||= {};
    return map { _cyclo_poly($this, $table, $_, \@d) } @d;
}

sub Math::Polynomial::cyclo_int_factors {
    my ($this, $x, $n, $table) = @_;
    return ($this->coeff_zero) if !$n || $x == $this->coeff_one;
    return ($x - $this->coeff_one) if $n == 1 || !$x;
    $table ||= {};
    if (my $exp = is_power($x, 0, \my $root)) {
        $x = $root;
        $n *= $exp;
    }
    my ($r, $s) = _square_free_square($x);
    my $r1 = (1 == ($r & 3))? $r: $r+$r;
    my @d = divisors($n);
    my $i = $x == 2 || 0;
    return
        map {
            !($_ % $r1) && ($_ / $r1) & 1?
            _schinzel_lm($this, $table, $_, $r, $s, $x):
            (_cyclo_poly($this, $table, $_, \@d))->evaluate($x)
        } @d[$i .. $#d];
}

sub Math::Polynomial::cyclo_plusfactors {
    my ($this, $n, $table) = @_;
    my @d = divisors($n << 1);
    my $m = $n ^ ($n - 1);
    $table ||= {};
    return
        map { _cyclo_poly($this, $table, $_, \@d) }
        grep { !($_ & $m) } @d;
}

sub Math::Polynomial::cyclo_int_plusfactors {
    my ($this, $x, $n, $table) = @_;
    my $u = $this->coeff_one;
    return ($u + $u) if !$n;
    return ($x + $u) if $n == 1 || !$x || $x == $u;
    if (my $exp = is_power($x, 0, \my $root)) {
        $x = $root;
        $n *= $exp;
    }
    my ($r, $s) = _square_free_square($x);
    my $r1 = (1 == ($r & 3))? $r: $r+$r;
    my @d = divisors($n << 1);
    my $m = $n ^ ($n - 1);
    $table ||= {};
    return
        map {
            !($_ % $r1) && ($_ / $r1) & 1?
            _schinzel_lm($this, $table, $_, $r, $s, $x):
            (_cyclo_poly($this, $table, $_, \@d))->evaluate($x)
        } grep { !($_ & $m) } @d;
}

sub Math::Polynomial::cyclo_lucas_cd {
    my ($this, $n, $table) = @_;
    if ($n <= 1 || !is_square_free($n)) {
        croak "$n: not a square-free integer greater than one";
    }
    return _lucas_cd($this, $table || {}, $n);
}

sub Math::Polynomial::cyclo_schinzel_cd {
    my ($this, $n, $k, $table) = @_;
    if ($k <= 1 || !is_square_free($k)) {
        croak "$k: not a square-free integer greater than one";
    }
    my @cd = _schinzel_cd($this, $table || {}, $n, $k);
    if (!@cd) {
        my $k1 = ($k & 3) == 1? 'k': '2*k';
        croak "$n: n is not an odd multiple of $k1";
    }
    return @cd;
}

sub Math::Polynomial::cyclo_poly_iterate {
    my ($this, $n, $table) = @_;
    $n ||= 1;
    --$n;
    $table ||= {};
    return
        sub {
            ++$n;
            _cyclo_poly($this, $table, $n);
        };
}

# ----- public subroutines -----

sub cyclo_poly            { $default->cyclotomic(@_)            }
sub cyclo_factors         { $default->cyclo_factors(@_)         }
sub cyclo_plusfactors     { $default->cyclo_plusfactors(@_)     }
sub cyclo_poly_iterate    { $default->cyclo_poly_iterate(@_)    }
sub cyclo_lucas_cd        { $default->cyclo_lucas_cd(@_)        }
sub cyclo_schinzel_cd     { $default->cyclo_schinzel_cd(@_)     }
sub cyclo_int_factors     { $default->cyclo_int_factors(@_)     }
sub cyclo_int_plusfactors { $default->cyclo_int_plusfactors(@_) }

1;

__END__

=encoding utf8

=head1 NAME

Math::Polynomial::Cyclotomic - cyclotomic polynomials generator

=head1 VERSION

This documentation refers to Version 0.004 of Math::Polynomial::Cyclotomic.
The fall 2021 releases of this library are dedicated to the memory of
Andrzej Schinzel.

=head1 SYNOPSIS

  use Math::Polynomial::Cyclotomic qw(
    cyclo_poly cyclo_factors cyclo_plusfactors cyclo_poly_iterate
    cyclo_lucas_cd cyclo_int_factors cyclo_int_plusfactors
  );
  use Math::Polynomial::Cyclotomic qw(:all);

  $p6 = cyclo_poly(6);                    # x^2-x+1

  # complete factorization of x^6-1
  @fs = cyclo_factors(6);                 # x-1, x+1, x^2+x+1, x^2-x+1

  # complete factorization of x^6+1
  @fp = cyclo_plusfactors(6);             # x^2+1, x^4-x^2+1

  # iterator generating consecutive cyclotomic polynomials
  $it = cyclo_poly_iterate(1);
  $p1 = $it->();                          # x-1
  $p2 = $it->();                          # x+1
  $p3 = $it->();                          # x^2+x+1

  # generate C, D so that C^2 - 7*x*D^2 is a cyclotomic polynomial
  ($c, $d) = cyclo_lucas_cd(7);           # x^3+3x^2+3x+1, x^2+x+1
  ($c, $d) = cyclo_schinzel_cd(14, 7);    # the same

  # constructors for a given coefficient type, such as Math::AnyNum
  $poly = Math::Polynomial->new(Math::AnyNum->new(0));
  $p6 = $poly->cyclotomic(6);             # x^2-x+1
  @fs = $poly->cyclo_factors(6);          # x-1, x+1, x^2+x+1, x^2-x+1
  @fp = $poly->cyclo_plusfactors(6);      # x^2+1, x^4-x^2+1
  $it = $poly->cyclo_poly_iterate(1);     # like sub cyclo_poly_iterate
  @cd = $poly->cyclo_lucas_cd(7);         # x^3+3x^2+3x+1, x^2+x+1
  @cd = $poly->cyclo_schinzel_cd(12, 2);  # x^2+x+1, x+1

  # partial factorization of 5^15-1
  @fs = cyclo_int_factors(5, 15);         # 4, 31, 11, 71, 181, 1741

  # partial factorization of 7^21+1
  @fs = cyclo_int_plusfactors(7, 21);     # 8, 43, 113, 911, 51031, 309079

  # optional argument: hashref of read-write polynomial index
  %table = ();
  @f6    = cyclo_factors(6, \%table);
  $p18   = cyclo_poly(18, \%table);                   # faster now
  @cd12  = cyclo_lucas_cd(6, \%table);
  @cd36  = cyclo_schinzel_cd(36, 6, \%table);         # faster now

=head1 DESCRIPTION

This extension of Math::Polynomial adds a constructor for cyclotomic
polynomials and a factoring algorithm for rational polynomials of the
form I<x^n-1> and I<x^n+1>.  Cyclotomic polynomials are monic irreducible
polynomials with integer coefficients that are a divisor of some binomial
I<x^n-1> but not of any other binomial I<x^k-1> with I<k> E<lt> I<n>.

This module works best with coefficient spaces allowing arbitrary
precision integer arithmetic, like Math::BigInt, or Math::BigRat,
or Math::AnyNum.  Integer arguments may be given as perl integers,
strings of decimal digits, or elements of the coefficient space then,
and will be converted accordingly.  By contrast, Perl built-in numerical
values as coefficients will introduce rounding errors in all but the
most trivial cases and thus produce mostly nonsense.

=head2 Constructors

=over 4

=item I<cyclo_poly>

If C<$n> is a positive integer number, C<cyclo_poly($n)> calculates
the I<n>th cyclotomic polynomial over Math::BigInt numbers.

If C<%table> is a dictionary mapping indexes to previously computed
cyclotomic polynomials, C<cyclo_poly($n, \%table)> will do the same,
but use the table to store and look up intermediate results that also
happen to be cyclotomic polynomials.  This can speed up subsequent
calculations considerably.  The table may only contain entries created
by this module and with matching coefficient types.  To be safe, start
with an empty hash but re-use it for similar calculations.

=item I<Math::Polynomial::cyclotomic>

If C<$poly> is a Math::Polynomial object and Math::Polynomial::Cyclotomic
has been loaded, C<$poly-E<gt>cyclotomic($n)> is essentially equivalent
to C<cyclo_poly($n)>, but returns a polynomial sharing the coefficient
type of C<$poly>.

With an optional hashref argument for memoization,
C<$poly-E<gt>cyclotomic($n, \%table)> will work similar to
C<cyclo_poly($n, \%table)>.

=item I<cyclo_factors>

If C<$n> is a positive integer number, C<cyclo_factors($n)> calculates a
complete factorization of I<x^n-1> over the field of rational numbers.
These are precisely the cyclotomic polynomials with index I<k>, I<k>
running through all positive integer divisors of I<n>.  The factors are
ordered by increasing index, so that the I<n>th cyclotomic polynomial
will be the last element of the list returned.

Like all calculation methods, this function takes an optional hashref
argument for memoization, as in C<cyclo_factors($n, \%table)>.

=item I<Math::Polynomial::cyclo_factors>

If C<$poly> is a Math::Polynomial object and Math::Polynomial::Cyclotomic
has been loaded, C<$poly-E<gt>cyclo_factors($n)> is essentially equivalent
to C<cyclo_factors($n)>, but returns a list of polynomials sharing the
coefficient type of C<$poly>.

With an optional hashref argument for memoization,
C<$poly-E<gt>cyclo_factors($n, \%table)> will work similar to
C<cyclo_factors($n, \%table)>.

=item I<cyclo_plusfactors>

If C<$n> is a positive integer number, C<cyclo_plusfactors($n)> calculates
a complete factorization of I<x^n+1> over the field of rational numbers.
These are precisely the cyclotomic polynomial factors of I<x^(2n)-1>
that are not also factors of I<x^n-1>.  The factors are ordered by
increasing index, so that the I<2n>th cyclotomic polynomial will be the
last element of the list returned.

Like all calculation methods, this function takes an optional hashref
argument for memoization, as in C<cyclo_plusfactors($n, \%table)>.

=item I<Math::Polynomial::cyclo_plusfactors>

If C<$poly> is a Math::Polynomial object and Math::Polynomial::Cyclotomic
has been loaded, C<$poly-E<gt>cyclo_plusfactors($n)> is essentially
equivalent to C<cyclo_plusfactors($n)>, but returns a list of polynomials
sharing the coefficient type of C<$poly>.

With an optional hashref argument for memoization,
C<$poly-E<gt>cyclo_plusfactors($n, \%table)> will work similar to
C<cyclo_plusfactors($n, \%table)>.

=item I<cyclo_poly_iterate>

If C<$n> is a positive integer number, C<cyclo_poly_iterate($n)> returns
a coderef that, repeatedly called, returns consecutive cyclotomic
polynomials starting with index I<n>.  If C<$n> is omitted it defaults
to 1.  Iterating this way is more time-efficient than repetitive
calls of I<cyclo_poly>, as intermediate results that would otherwise
be re-calculated later are memoized in the state of the closure.
Re-assigning or undefining the coderef will free the memory used for that.

Alternatively, an external memoization table can be used, if supplied
as optional hashref argument, as in C<cyclo_poly_iterate($n, \%table)>.

=item I<Math::Polynomial::cyclo_poly_iterate>

If C<$poly> is a Math::Polynomial object and Math::Polynomial::Cyclotomic
has been loaded, C<$poly-E<gt>cyclo_poly_iterate($n)> is essentially
equivalent to C<cyclo_poly_iterate($n)>, but the polynomials returned
by the iterator will share the coefficient type of C<$poly>.

With an optional hashref argument for memoization,
C<$poly-E<gt>cyclo_poly_iterate($n, \%table)> will work similar to
C<cyclo_poly_iterate($n, \%table)>.

=back

=head2 Aurifeuillean Factorization

Cyclotomic polynomials are irreducible over the integers and rationals,
but when restricted to particular integer values they may have an
algebraic factorization.

For example, since
I<cyclo_poly(4) = x^2 + 1 = (x + 1 - sqrt(2*x)) * (x + 1 + sqrt(2*x))>,
I<cyclo_poly(4)> has integer factors for values of x where the square
root is an integer, i.e. where x is twice a square.

Such factorizations are called Aurifeuillean after
LE<233>on-FranE<231>ois-Antoine Aurifeuille (1822-1882), who found
our example algebraically explaining FortunE<eacute> Landry's famous
factorization of I<2^58+1> in 1871.

Richard Peirce Brent (b. 1946) gave a calculation method for the identity
of Aurifeuille, Henri Le Lasseur (1821-1894) and E<201>douard Lucas
(1842-1891), yielding Polynomials I<C> and I<D> with the property
that I<C^2 - n*x*D^2> with square-free I<n E<gt> 1> is equal to one
of the cyclotomic polynomials I<cyclo_poly(n)> or I<cyclo_poly(2*n)>.
This method can be generalized to odd multiples of I<n> or I<2*n>,
satisfying the identities of N.G.W.H. Beeger (1884-1965) and Andrzej
Schinzel (1937-2021).  We do so here and name these polynomials Schinzel
C,D polynomials.  This is not an official name so far, but seems quite
appropriate, honoring Schinzel's work on the subject and commemorating
his recent demise.

=over 4

=item I<cyclo_lucas_cd>

If C<$n> is a square-free integer greater than one,
C<($C, $D) = cyclo_lucas_cd($n)> returns two polynomials I<C> and I<D>
with the property that I<E<934> = C^2 - n*x*D^2>, where I<E<934>> is
I<cyclo_poly(n)> if I<n E<8801> 1 (mod 4)>, otherwise I<cyclo_poly(2*n)>.
This can be used to derive Aurifeuillean factors I<C E<177> D * sqrt(n*x)>
of I<E<934>(x)> where I<x> is I<n> times a square number.

Like all calculation methods, this function takes an optional hashref
argument for memoization, as in C<cyclo_lucas_cd($n, \%table)>.

=item I<Math::Polynomial::cyclo_lucas_cd>

If C<$poly> is a Math::Polynomial object and Math::Polynomial::Cyclotomic
has been loaded, C<$poly-E<gt>cyclo_lucas_cd($n)> is essentially
equivalent to C<cyclo_lucas_cd($n)>, but the polynomials returned
will share the coefficient type of C<$poly>.

With an optional hashref argument for memoization,
C<$poly-E<gt>cyclo_lucas_cd($n, \%table)> will work similar to
C<cyclo_lucas_cd($n, \%table)>.

=item I<cyclo_schinzel_cd>

If C<$k> is a square-free integer greater than one, and
C<$k1 = ($k % 4 == 1)? $k: 2*$k>, and C<$n> is an odd multiple of C<$k1>,
C<($C, $D) = cyclo_schinzel_cd($n, $k)> returns two polynomials I<C> and I<D>
with the property that I<cyclo_poly(n) = C^2 - k*x*D^2>.
This can be used to derive Aurifeuillean factors I<C E<177> D * sqrt(k*x)>
of I<cyclo_poly(n)> where I<x> is I<k> times a square number.
C<cyclo_schinzel_cd($k1, $k)> is equivalent to C<cyclo_lucas_cd($k)>.

Like all calculation methods, this function takes an optional hashref
argument for memoization, as in C<cyclo_schinzel_cd($n, $k, \%table)>.

=item I<Math::Polynomial::cyclo_schinzel_cd>

If C<$poly> is a Math::Polynomial object and Math::Polynomial::Cyclotomic
has been loaded, C<$poly-E<gt>cyclo_schinzel_cd($n, $k)> is essentially
equivalent to C<cyclo_schinzel_cd($n, $k)>, but the polynomials returned
will share the coefficient type of C<$poly>.

With an optional hashref argument for memoization,
C<$poly-E<gt>cyclo_schinzel_cd($n, $k, \%table)> will work similar to
C<cyclo_schinzel_cd($n, $k, \%table)>.

=item I<cyclo_int_factors>

If C<$x> and C<$n> are positive integers, C<cyclo_int_factors($x, $n)>
returns a partial factorization of C<$x ** $n - 1>, using cyclotomic and
Aurifeuillean factors where possible, as a list of Math::BigInt objects.

Like all calculation methods, this function takes an optional hashref
argument for memoization, as in C<cyclo_int_factors($x, $n, \%table)>.

=item I<Math::Polynomial::cyclo_int_factors>

If C<$poly> is a Math::Polynomial object and Math::Polynomial::Cyclotomic
has been loaded, C<$poly-E<gt>cyclo_int_factors($x, $n)> is essentially
equivalent to C<cyclo_int_factors($x, $n)>, but the numbers returned
will have the coefficient type of C<$poly>.

With an optional hashref argument for memoization,
C<$poly-E<gt>cyclo_int_factors($x, $n, \%table)> will work similar to
C<cyclo_int_factors($x, $n, \%table)>.

=item I<cyclo_int_plusfactors>

If C<$x> and C<$n> are positive integers, C<cyclo_int_plusfactors($x, $n)>
returns a partial factorization of C<$x ** $n + 1>, using cyclotomic and
Aurifeuillean factors where possible, as a list of Math::BigInt objects.

Like all calculation methods, this function takes an optional hashref
argument for memoization, as in C<cyclo_int_plusfactors($x, $n, \%table)>.

=item I<Math::Polynomial::cyclo_int_plusfactors>

If C<$poly> is a Math::Polynomial object and Math::Polynomial::Cyclotomic
has been loaded, C<$poly-E<gt>cyclo_int_plusfactors($x, $n)> is essentially
equivalent to C<cyclo_int_plusfactors($x, $n)>, but the numbers returned
will have the coefficient type of C<$poly>.

With an optional hashref argument for memoization,
C<$poly-E<gt>cyclo_int_plusfactors($x, $n, \%table)> will work similar to
C<cyclo_int_plusfactors($x, $n, \%table)>.

=back

=head1 EXAMPLES

This distribution has an examples directory with scripts generating
cyclotomic polynomials and demonstrating Aurifeuillean factorization.

=over 4

=item cyclo_poly

C<cyclo_poly n> with positive integer I<n> prints the I<n>th cyclotomic
polynomial.

C<cyclo_poly min max> with positive integers I<min> and I<max> prints
cyclotomic polynomials with orders I<n> ranging from I<min> to I<max>.

Option C<-f> as in C<cyclo_poly -f 12> switches to printing a complete
factorization of I<x^n - 1> into cyclotomic polynomials.

Option C<-F> as in C<cyclo_poly -F 9> switches to printing a complete
factorization of I<x^n + 1> into cyclotomic polynomials.

=item lucas_cd

C<lucas_cd n> with square-free integer I<n> E<gt> 1 prints Lucas C,D
polynomials with parameter I<n>.

The output is a data structure C<[n1,n,C,D]> suitable to be parsed
by Pari/GP, with the order of the cyclotomic polynomial I<n1>, the
parameter I<n>, and the coefficients of the polynomials I<C> and I<D>,
starting with the leading coefficient.

=item schinzel_cd

C<schinzel_cd n k> with square-free integer I<k> E<gt> 1 and suitable I<n>
(see equally named method above) prints Schinzel C,D polynomials with
parameters I<n> and I<k>.

The output is a data structure C<[n,k,C,D]> suitable to be parsed by
Pari/GP, with the order of the cylotomic polynomial I<n>, the parameter
I<k>, and the coefficients of the polynomials I<C> and I<D>, starting
with the leading coefficient.

=item int_factors

C<int_factors x n> with positive integers I<x> and I<n> calculates a
partial factorization of I<x^n - 1> using cyclotomic and Aurifeuillean
factors.

=item int_plusfactors

C<int_plusfactors x n> with positive integers I<x> and I<n> calculates
a partial factorization of I<x^n + 1> using cyclotomic and Aurifeuillean
factors.

=back

=head1 DIAGNOSTICS

In addition to this library's specific diagnostic messages, some
exceptions from Math::Polynomial or Math::Prime::Util may indicate
inappropriate arguments.

=over 4

=item C<%d: not a square-free integer greater than one>

An integer argument of I<cyclo_lucas_cd> or I<cyclo_schinzel_cd> should
be square-free and greater than one, but was not.

=item C<%d: n is not an odd multiple of k>

=item C<%d: n is not an odd multiple of 2*k>

I<cyclo_schinzel_cd> was called with arguments I<n> and I<k> no Schinzel
polynomials are defined for.  I<n> has to be an odd multiple of I<k>
if I<k E<8801> 1 (mod 4)> or of I<2E<183>k> otherwise.

=item C<exponent too large> (from Math::Polynomial)

The integer argument I<n>, which necessitates operations on polynomials up
to degree I<2*n>, was too large for current Math::Polynomial limitations.

=item C<Parameter '%s' must be a positive integer> (from Math::Prime::Util)

The argument I<n> should have been a positive integer number but was not.

=back

=head1 DEPENDENCIES

This library uses Math::BigInt as default type for coefficients,
Math::Polynomial (version 1.014 and up) for polynomial arithmetic,
and Math::Prime::Util (version 0.47 and up) for factoring integers.
The minimal required perl version is 5.6.  For better performance,
Math::BigInt::GMP and Math::Prime::Util::GMP are also recommended.
Other supported coefficient types are Math::BigRat and Math::AnyNum.

=head1 ROADMAP

It will be not very hard to extend the interface to factor not just
I<x^nE<177>1> but, more generally, I<x^nE<177>y^n>, too.  We consider
adding this feature in an upcoming release.

Functions like I<poliscyclo> and I<poliscycloprod> in Pari/GP, for finding
out whether a given polynomial is cyclotomic or a product of cyclotomic
polynomials, would also fit into the scope of this library.

Other improvements should address performance with large degrees,
eventually.  This is, however, not a priority so far.

One way to achieve better time efficiency could be adding precomputed
data.  As this would imply a space penalty, it would have to be kept in
a separately installable module, like Math::Polynomial::Cyclotomic::Data.
An experimental version with Cyclotomic and Schinzel polynomials for I<n>
up to 10000 took about 1 GB of disk storage.

For calculating Schinzel polynomials, intermediate steps operating in
quadratic fields E<8474>[E<8730>n] are currently implemented employing
a rather costly parameter substitution I<x E<8594> nE<183>tE<178>>.
An efficient implementation of quadratic field arithmetic might speed
that up.

The optional arguments for memoization are considered somewhat inelegant.
Exposing them is intended as a way to avoid memory leaks, and to avoid
mixing different coefficient spaces in some global cache.  We are still
looking for better ways to achieve both.

=head1 BUGS AND LIMITATIONS

This implementation is optimized for I<n> E<8804> 5000.  It assumes
that factoring numbers up to I<n> is cheap, and it employs polynomial
division via Math::Polynomial, using pure Perl to operate on arrays
of coefficients.

For larger I<n>, C<$Math::Polynomial::max_degree> must be raised or
undefined.  For very large I<n>, a memory-efficient polynomial type
and an arbitrary precision coefficient type should be used.  Note that
although Math::BigInt is not in general a coefficient type suitable
for polynomial division, in this case it would be sufficent, as all of
our divisions in the coefficient space have integer results.

Currently, our algorithms do not always avoid factoring integer numbers
more than once.  Doing so more rigorously, or establishing access to
pre-computed factorization data, could speed up calculations for very
large I<n>.

In order to avoid overflow, most calculations are carried out with
Math::BigInt objects or in the given coefficient space, even when the
numbers are small enough to fit into native integers.  Distinguishing
these cases, in a similar way Math::Prime::Util does, could speed up
calculations for very small I<n>.

Finally, there are faster algorithms for calculating single cyclotomic
polynomials.  Our recursive algorithm employing polynomial division
can take profit from polynomials calculated earlier, but may compare
unfavorably in a single-run situation.  We also leave out some advantages
that could be taken from recognizing more special cases.

Bug reports and suggestions are always welcome.
Please submit them through the github issue tracker,
L<https://github.com/mhasch/perl-Math-Polynomial-Cyclotomic/issues>.

=head1 SEE ALSO

=over 4

=item *

L<Math::Polynomial>

=item *

L<Math::Prime::Util>

=item *

I<Cyclotomic polynomial> in Wikipedia,
L<https://en.wikipedia.org/wiki/Cyclotomic_polynomial>

=item *

Richard P. Brent, On computing factors of cyclotomic polynomials, in:
Mathematics of Computation 61 (1993),
L<https://maths-people.anu.edu.au/~brent/pub/pub135.html>

=item *

Bill Allombert & Karim Belabas, Practical Aurifeuillian Factorization (2008),
in: Journal de ThE<eacute>orie des Nombres de Bordeaux 20, 10.5802/jtnb.641,
L<https://www.researchgate.net/publication/267478352_Practical_Aurifeuillian_Factorization>

=item *

I<Andrzej Schinzel> in Wikipedia,
L<https://en.wikipedia.org/wiki/Andrzej_Schinzel>

=back

=head1 AUTHOR

Martin Becker, Blaubeuren, E<lt>becker-cpan-mp (at) cozap.comE<gt>

=head1 ACKNOWLEDGEMENTS

Thanks go to Slaven ReziE<263> for pointing out a dependency issue,
and for CPAN smoketesting in general.  Good work!

=head1 CONTRIBUTING

Contributions to this library are welcome (see the CONTRIBUTING file).

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019-2021 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
