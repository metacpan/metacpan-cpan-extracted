# Copyright (c) 2013-2022 by Martin Becker.  This package is free software,
# licensed under The Artistic License 2.0 (GPL compatible).

package Math::Polynomial::ModInt;

use 5.006;
use strict;
use warnings;
use Math::BigInt try => 'GMP';
use Math::ModInt 0.012;
use Math::ModInt::Event qw(UndefinedResult);
use Math::Polynomial 1.015;
use Carp qw(croak);

# ----- object definition -----

# Math::Polynomial::ModInt=ARRAY(...)

# .............. index ..............   # .......... value ..........

use constant _OFFSET  => Math::Polynomial::_NFIELDS;
use constant _F_INDEX => _OFFSET + 0;    # ordinal number i, 0 <= i
use constant _NFIELDS => _OFFSET + 1;

# ----- class data -----

BEGIN {
    require Exporter;
    our @ISA       = qw(Math::Polynomial Exporter);
    our @EXPORT_OK = qw(modpoly);
    our $VERSION   = '0.005';
    our @CARP_NOT  = qw(Math::ModInt::Event::Trap Math::Polynomial);
}

my $default_string_config = {
    convert_coeff => sub { $_[0]->residue },
    times         => q[*],
    wrap          => \&_wrap,
};

my $lifted_string_config = {
    times         => q[*],
    fold_sign     => 1,
};

my $ipol = Math::Polynomial->new(Math::BigInt->new);
$ipol->string_config($lifted_string_config);

# ----- private subroutines -----

# event catcher
sub _nonprime_modulus {
    croak 'modulus not prime';
}

# event catcher
sub _no_inverse {
    croak 'undefined inverse';
}

# constructor diagnostic
sub _modulus_too_small {
    croak 'modulus must be greater than one';
}

# wrapper for modular inverse to bail out early if not in a field
sub _inverse {
    my ($element) = @_;
    my $trap = UndefinedResult->trap(\&_no_inverse);
    return $element->inverse;
}

# Does a set of coefficient vectors have a zero linear combination?
# We transform and include them one by one into a matrix in echelon form.
# Argument is an iterator so we can short-cut generating superfluous vectors.
# Supplied vectors may be modified.
sub _linearly_dependent {
    my ($it) = @_;
    my $trap = UndefinedResult->trap(\&_nonprime_modulus);
    my @ech = ();
    while (defined(my $vec = $it->())) {
        my $ex = 0;
        for (; $ex < @ech; ++$ex) {
            my $evec = $ech[$ex];
            last if @{$evec} < @{$vec};
            if (@{$evec} == @{$vec}) {
                my $i = $#{$vec};
                return 1 if !$i;
                my $w = pop(@{$vec}) / $evec->[$i];
                while ($i-- > 0) {
                    $vec->[$i] -= $evec->[$i] * $w;
                }
                while (@{$vec} && !$vec->[-1]) {
                    pop(@{$vec});
                }
            }
        }
        return 1 if !@{$vec};
        splice @ech, $ex, 0, $vec;
    }
    return 0;
}

# ----- private methods -----

# wrapper to decorate stringified polynomial
sub _wrap {
    my ($this, $text) = @_;
    my $modulus = $this->modulus;
    return "$text (mod $modulus)";
}

# ----- protected methods -----

# constructor with index argument
sub _xnew {
    my $this  = shift;
    my $index = shift;
    my $poly  = $this->new(@_);
    $poly->[_F_INDEX] = $index;
    return $poly;
}

# ----- overridden public methods -----

sub new {
    my $this = shift;
    if (!@_ && !ref $this) {
        croak 'insufficient arguments';
    }
    if (grep {$_->is_undefined} @_) {
        _nonprime_modulus();
    }
    if (grep {$_->modulus <= 1} @_) {
        _modulus_too_small();
    }
    return $this->SUPER::new(@_);
}

sub string_config {
    my $this = shift;
    return $this->SUPER::string_config(@_) if ref $this;
    ($default_string_config) = @_          if @_;
    return $default_string_config;
}

sub is_equal {
    my ($this, $that) = @_;
    my $i = $this->degree;
    my $eq = $this->modulus == $that->modulus && $i == $that->degree;
    while ($eq && 0 <= $i) {
        $eq = $this->coeff($i)->residue == $that->coeff($i)->residue;
        --$i;
    }
    return $eq;
}

sub is_unequal {
    my ($this, $that) = @_;
    my $i = $this->degree;
    my $eq = $this->modulus == $that->modulus && $i == $that->degree;
    while ($eq && 0 <= $i) {
        $eq = $this->coeff($i)->residue == $that->coeff($i)->residue;
        --$i;
    }
    return !$eq;
}

sub is_monic {
    my ($this) = @_;
    my $degree = $this->degree;
    return 0 <= $degree && $this->coeff($degree)->residue == 1;
}

sub monize {
    my ($this) = @_;
    my $degree = $this->degree;
    return $this if $degree < 0;
    my $leader = $this->coeff($degree);
    return $this if $leader->residue == 1;
    return $this->mul_const(_inverse($leader));
}

# ----- public subroutine -----

sub modpoly { __PACKAGE__->from_index(@_) }

# ----- class-specific public methods -----

sub from_index {
    my ($this, $index, $modulus) = @_;
    my $zero;
    if (defined $modulus) {
        $modulus > 1 || _modulus_too_small();
        $zero = Math::ModInt::mod(0, $modulus);
    }
    elsif (ref $this) {
        $zero = $this->coeff_zero;
        $modulus = $zero->modulus;
    }
    else {
        croak('usage error: modulus parameter missing');
    }
    my @coeff = ();
    my $q = $index;
    while ($q > 0) {
        ($q, my $r) = $zero->new2($q);
        push @coeff, $r;
    }
    return $this->_xnew(@coeff? ($index, @coeff): (0, $zero));
}

sub from_int_poly {
    my ($this, $poly, $modulus) = @_;
    if (!defined $modulus) {
        if (!ref $this) {
            croak('usage error: modulus parameter missing');
        }
        $modulus = $this->modulus;
    }
    my @coeff = map { Math::ModInt::mod($_, $modulus) } $poly->coefficients;
    return $this->new(@coeff);
}

sub modulus {
    my ($this) = @_;
    return $this->coeff_zero->modulus;
}

sub index {
    my ($this) = @_;
    my $base  = $this->modulus;
    my $index = $this->[_F_INDEX];
    if (!defined $index) {
        $index = Math::BigInt->new;
        foreach my $c (reverse $this->coeff) {
            $index->bmul($base)->badd($c->residue);
        }
        $this->[_F_INDEX] = $index;
    }
    return $index;
}

sub number_of_terms { scalar grep { $_->is_not_zero } $_[0]->coeff }

sub lift       { $ipol->new(map { $_->residue          } $_[0]->coefficients) }

sub centerlift { $ipol->new(map { $_->centered_residue } $_[0]->coefficients) }

sub lambda_reduce {
    my ($this, $lambda) = @_;
    my $degree = $this->degree;
    return $this if $degree <= $lambda;
    my @coeff = map { $this->coeff($_) } 0 .. $lambda;
    for (my $i = 1, my $n = $lambda+1; $n <= $degree; ++$i, ++$n) {
        $coeff[$i] += $this->coeff($n);
        $i = 0 if $i == $lambda;
    }
    return $this->new(@coeff);
}

sub first_root {
    my ($this) = @_;
    my $zero = $this->coeff_zero;
    my $lsc  = $this->coeff(0);
    return $zero if $lsc->is_zero;
    if ($this->degree == 1) {
        my $mscr = $this->coeff(1)->centered_residue;
        return -$lsc if $mscr ==  1;
        return  $lsc if $mscr == -1;
    }
    foreach my $n (1 .. $zero->modulus - 1) {
        my $root = $zero->new($n);
        return $root if $this->evaluate($root)->is_zero;
    }
    return undef;
}

# implementation restriction: defined for prime moduli only
sub is_irreducible {
    my ($this) = @_;
    my $n = $this->degree;
    return 0 if $n <= 0;
    return 1 if $n == 1;
    return 0 if !$this->coeff(0);
    return 0 if $this->gcd($this->differentiate)->degree > 0;
    my $p  = $this->modulus;
    # optimization: O(p) zero search only for small p or very large n
    if ($p <= 43 || log($p - 20) <= $n * 0.24 + 2.68) {
        my $rp = 2 < $p && $p <= $n? $this->lambda_reduce($p-1): $this;
        return 0 if defined $rp->first_root;
        return 1 if $n <= 3;
    }
    # Berlekamp rank < $n - 1?
    my $xp = $this->exp_mod($p);
    my $aj = $xp;
    my $bj = $this->monomial(1);
    my $j  = 0;
    return 0 if _linearly_dependent(
        sub {
            return undef if $j >= $n - 1;
            if ($j++) {
                $aj = $aj * $xp % $this;
                $bj <<= 1;
            }
            return [($aj - $bj)->coeff];
        }
    );
    return 1;
}

1;

__END__

=encoding utf8

=head1 NAME

Math::Polynomial::ModInt - univariate polynomials over modular integers

=head1 VERSION

This documentation refers to version 0.005 of Math::Polynomial::ModInt.

=head1 SYNOPSIS

    use Math::Polynomial;
    use Math::ModInt             qw(mod);
    use Math::Polynomial::ModInt qw(modpoly);

    $p = modpoly(265, 3);               # some polynomial modulo 3
    $p = Math::Polynomial::ModInt->from_index(265, 3);  # the same
    $p = Math::Polynomial::ModInt->new(
        mod(1, 3), mod(1, 3), mod(2, 3), mod(0, 3), mod(0, 3), mod(1, 3)
    );                                  # the same
    $p = Math::Polynomial::ModInt->from_int_poly(
        Math::Polynomial->new(1, 1, 2, 0, 0, 1), 3
    );                                  # the same

    $q = $p->from_index(27);            # x^3 (mod 3)
    $t = $p->isa('Math::Polynomial');   # true
    $s = $p->as_string;                 # '(x^5 + 2*x^2 + x + 1 (mod 3))'
    $d = $p->degree;                    # 5
    $i = $p->index;                     # 265
    $b = $p->modulus;                   # 3
    $n = $p->number_of_terms;           # 4
    $u = $p->lift;                      # x^5 + 2*x^2 + x + 1
    $v = $p->centerlift;                # x^5 - x^2 + x + 1
    $z = $p->first_root;                # undef
    $m = $p->is_irreducible;            # true
    $r = modpoly(131, 3);               # x^4 + x^3 - x^2 + x - 1
    $x = $r->first_root;                # mod(2, 3)
    $c = $r->is_irreducible;            # false
    $f = $r->lambda_reduce(2);          # - x - 1 (mod 3)

=head1 DESCRIPTION

Math::Polynomial::ModInt is a subclass of Math::Polynomial for modular
integer coefficient spaces.  It adds domain-specific methods and
stringification options to the base class.  Notably, it implements a
bijection from unsigned integers to polynomials for a given modulus.

=head1 CLASS METHODS

=head2 Constructors

=over 4

=item I<new>

C<Math::Polynomial::ModInt-E<gt>new(@coeff)> creates a polynomial from
its coefficients in ascending order of degrees.  C<@coeff> must have
at least one value and all values must be Math::ModInt objects with the
same modulus.

Other constructors defined in the parent class Math::Polynomial, like
I<monomial> and I<from_roots>, are also valid.  Note, however, that
polynomial operations assuming that the coefficient space is a field,
like I<interpolate> and I<divmod>, are safe to use only with prime moduli.
Using them with a composite modulus may result in a "modulus not prime"
exception.

=item I<from_index>

As there are finitely many modular integer polynomials for any fixed
modulus and degree, and countably many for any fixed modulus, they
can be enumerated with an unsigned integer index.  Indeed, a number
written with base I<n> digits is equivalent to a polynomial with modulo
I<n> coefficients.  We call the number the index of the polynomial.
C<Math::Polynomial::ModInt-E<gt>from_index($index, $modulus)> creates
a polynomial from its index.  C<$index> can be a perl native integer or
a Math::BigInt object.

=item I<modpoly>

The subroutine I<modpoly> can be imported and used as a shortcut for the
I<from_index> constructor.  C<modpoly($index, $modulus)> is equivalent
to C<Math::Polynomial::ModInt-E<gt>from_index($index, $modulus)>, then.

=item I<from_int_poly>

It is also possible to create a modular integer
polynomial from an integer polynomial and a modulus.
C<Math::Polynomial::ModInt-E<gt>from_int_poly($poly, $modulus)>, where
C<$poly> is a Math::Polynomial object with integer coefficients and
C<$modulus> is a positive integer, does this.

=back

=head1 OBJECT METHODS

=head2 Constructors

=over 4

=item I<from_index>

When called as an object method, the modulus argument of this
constructor can be omitted.  C<$p-E<gt>from_index($index)> is
equivalent to C<$p-E<gt>from_index($index, $p-E<gt>modulus)>, then.
If a modulus is specified, it takes precedence over the invocant.
Thus, C<$p-E<gt>from_index($index, $modulus)> is equivalent to
C<Math::Polynomial::ModInt-E<gt>from_index($index, $modulus)>.

=item I<from_int_poly>

Similarly, C<$p-E<gt>from_int_poly($intpoly)> is equivalent to
C<$p-E<gt>from_int_poly($intpoly, $p-E<gt>modulus)>.

=back

=head2 Operators

All operators of the parent module Math::Polynomial, as far as they do
not involve division, are valid for Math::Polynomial::ModInt objects,
too.  Notably, addition, subtraction, and multiplication of modular
integer polynomials is valid and indeed handled by the parent class.
Invalid operations will yield exceptions from Math::ModInt.

If the modulus is a prime number, division is valid in the coefficient
space and thus all operators, including I<divmod> and I<gcd>, are safe.

Additionally, a number of comparison operators are defined for modular
integer polynomials only.  Currently, these are implemented in the
L<Math::Polynomial::ModInt::Order> helper module rather than as overloaded
operators, for reasons explained there.

=head2 Property Accessors

In addition to properties defined in the parent module Math::Polynomial,
like I<degree>, I<coeff>, and I<is_monic>, some properties specific for
modular integer polynomials are defined.

=over 4

=item I<index>

C<$p-E<gt>index> calculates the index of a modular integer polynomial
C<$p>, as defined above.  Cf. L</from_index>.

Note that the index grows exponentially with the degree of the polynomial
and is thus represented as a Math::BigInt object.

=item I<modulus>

C<$p-E<gt>modulus> returns the modulus common to all coefficients of
the modular integer polynomial C<$p>.

=item I<number_of_terms>

C<$p-E<gt>number_of_terms> returns the number of non-zero coefficients
of the modular integer polynomial C<$p>.  Recent versions of the parent
module also have this method.

=back

=head2 Algebraic Operators

=over 4

=item I<lambda_reduce>

C<$p-E<gt>lambda_reduce($lambda)> generates a polynomial of degree
I<lambda> or lower from a high-degree polynomial in this way: Remove
the highest degree coefficient (for degree I<n>) and add it to the
coefficient of degree I<n - lambda>, and repeat until the degree of the
remaining polynomial is less or equal to I<lambda>.

If I<lambda> happens to be a multiple of the Carmichael totient of the
modulus, which will be one less than the modulus if the modulus is a
prime number, the reduced polynomial will evaluate point-wise equivalent
to the original polynomial.

=item I<first_root>

C<$p-E<gt>first_root> returns the root with the smallest non-negative
residue of the polynomial, if such roots exist, otherwise I<undef>.
As currently implemented, this operation will be time-consuming for
large moduli.

=item I<is_irreducible>

If C<$p> is a modular integer polynomial with prime modulus,
C<$p-E<gt>is_irreducible> returns a boolean value telling if the
polynomial is irreducibe.  An irreducible polynomial is a non-constant
polynomial that is not a product of two or more other non-constant
polynomials.

Irreducibility is mostly of interest for prime moduli, where factorization
is always unique.  This method therefore is implemented for prime moduli
only.  Note, however, that primality of the modulus is not explicitly
checked, as this can be done beforehand once and would unnecessarily
slow down operations on several polynomials with the same modulus.
As currently implemented, the method may either return a meaningless
result or throw a 'modulus is not prime' exception when called with a
non-prime modulus.

=back

=head2 Conversions

=over 4

=item I<as_string>

For conversion to a string, the whole string configuration functionality
of the parent module can be employed.  For convenience, the default
string configuration for Math::Polynomial::ModInt is already adapted to
a more terse representation, so that the modulus is only written once.
C<$p-E<gt>as_string> could return C<'(x^5 + 2*x^2 + x + 1 (mod 3))'>,
for example.

=item I<lift>

The I<lift> method is a reverse operation to I<from_int_poly>.
C<$p-E<gt>lift> returns a Math::Polynomial object with integer
coefficients with values ranging from zero to the modulus minus one.
It is equivalent to the Math::Polynomial::ModInt object C<$p> in the
sense that I<from_int_poly> would turn it back to C<$p>.

=item I<centerlift>

The I<centerlift> method is an alternative to I<lift> with the only
difference that the integer values of the coefficients range from minus
half of the modulus, rounded up, to plus half of the modulus, rounded
down, if the modulus is odd, or minus half of the modulus, plus one,
to plus half of the modulus, if it is even.

All lifting methods may be used together with tree conversions to get
yet more string representations of polynomials, if so desired.

=back

=head1 DIAGNOSTICS

Dealing with Math::ModInt objects can generally trigger exceptions from
L<Math::ModInt::Event>.  Mixing different moduli or dividing non-coprime
elements could be causes.  These exceptions will correctly be propagated
as failures of code calling Math::Polynomial::ModInt in general, but in
some situations Math::Polynomial may be blamed.

Other error conditions, like using non-integers or non-objects where they
would be expected, are not rigorously checked and may yield unreliable
behavior rather than error messages.

The error conditions that are actually reported are these:

=over 4

=item C<modulus not prime>

A method only defined for prime moduli, like I<is_irreducible>, has been
called inappropriately.  Note that this is not always detected and the
result might be just wrong in such cases.

=item C<modulus must be greater than one>

A constructor was called with an inappropriate modulus of zero or one.
Polynomials indexing uses the modulus as the base of a numeral system
with coefficients acting as digits.  This is implemented and actually
useful for bases greater than one only.

=item C<undefined inverse>

A method needing the multiplicative inverse of a coefficient, like
I<monize>, has been called where that coefficient had no inverse.
This can occur with coefficients that are not coprime to the modulus.

=item C<usage error: modulus parameter missing>

The I<from_index> or I<from_int_poly> constructors have been used with
insufficient information as to the value of the modulus.  They should
be either invoked with an explicit modulus (recommended) or as an
object method.

=back

=head1 DEPENDENCIES

This library uses Math::ModInt (version 0.012 and up) for modular integer
calculations and Math::Polynomial (version 1.015 and up) for polynomial
arithmetic, as well as Carp (any version) for diagnostic messages.
The minimal required perl version is 5.6.

=head1 ROADMAP

The toolbox of algebraic operations is by no means complete.
Irreducibility checking is based on Berlekamp's factorization algorithm
but full factorization is not yet implemented.  It is intended to be
added in one of the next releases.

Some applications of modular integer polynomials will be provided by
the Math::GaloisField hierarchy of modules rather than in this package.
Math::Polynomial::ModInt is meant for basic stuff that can more or less
be expected in a sub-class of Math::Polynomial, while algebraic field
properties are more appropriate in the other package.  For example,
division means polynomial division with remainder here, and proper
division governed by field arithmetic there.

Ideally (pun not intended), the element type Math::Polynomial::ModInt
with non-prime moduli should have a corresponding space type like
Math::PolynomialRing::ModInt, where more algebraic ring stuff could
have a home.  It is not yet planned, though, but some tidbits could
make an appearance in the Math::Polynomial::ModInt examples collection
in the meantime.

=head1 BUGS AND LIMITATIONS

Most of the time, method arguments are not rigourosly checked to make
sense.  Cf. Diagnostics.

Some calculations, like root finding and checking for irreducibility,
can be time-consuming.  Operations involving large integer numbers will
be faster if Math::BigInt::GMP is installed.  So far, this package is
pure perl only.  An XS version may be added eventually, but not in the
near future.

Bug reports and more suggestions are always welcome
E<8212> please submit them through the github issue tracker,
L<https://github.com/mhasch/perl-Math-Polynomial-ModInt/issues>.

=head1 SEE ALSO

=over 4

=item *

L<Math::Polynomial::ModInt::Order>

=item *

L<Math::Polynomial>

=item *

L<Math::ModInt>

=item *

Math::GaloisField (sooner or later to be published)

=back

=head1 AUTHOR

Martin Becker, C<< <becker-cpan-mp (at) cozap.com> >>

=head1 CONTRIBUTING

Contributions to this library are welcome (see the CONTRIBUTING file).

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013-2022 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
