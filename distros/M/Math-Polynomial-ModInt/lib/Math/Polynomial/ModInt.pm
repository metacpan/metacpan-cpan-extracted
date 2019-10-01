# Copyright (c) 2013-2019 by Martin Becker.  This package is free software,
# licensed under The Artistic License 2.0 (GPL compatible).

package Math::Polynomial::ModInt;

use 5.006;
use strict;
use warnings;
use Math::BigInt;
use Math::ModInt     0.011;
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
    our $VERSION   = '0.002';
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

# ----- public subroutine -----

sub modpoly { __PACKAGE__->from_index(@_) }

# ----- class-specific public methods -----

sub from_index {
    my ($this, $index, $modulus) = @_;
    my $zero;
    if (defined $modulus) {
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

1;

__END__

=encoding utf8

=head1 NAME

Math::Polynomial::ModInt - univariate polynomials over modular integers

=head1 VERSION

This documentation refers to version 0.002 of Math::Polynomial::ModInt.

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

Other constructors defined in the parent class Math::Polynomial,
like I<monomial> and I<from_roots>, are also valid.  Note, however,
that polynomial operations assuming that the coefficient space is a
field, like I<interpolate> and I<divmod>, do not make sense with modular
integers in general.  Some of them could be used with prime moduli, but
specialized modules like Math::GaloisField implement similar operations
more efficiently.

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

When called as an object method, the modulus argument of
constructors can be omitted.  C<$p-E<gt>from_index($index)> is
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

Additionally, a number of comparison operators are defined for modular
integer polynomials only.  Currently, these are implemented in the
L<Math::Polynomial::ModInt::Order|Math::Polynomial::ModInt::Order> helper
module rather than as overloaded operators, for reasons explained there.

=head2 Property Accessors

In addition to properties defined in the parent module Math::Polynomial,
like I<degree>, I<coeff>, and I<is_monic>, some properties specific for
modular integer polynomials are defined.

=over 4

=item I<index>

C<$p-E<gt>index> calculates the index of a modular integer polynomial
C<$p>, as defined above.  Cf. L<#from_index>.

Note that the index grows exponentially with the degree of the polynomial
and is thus represented as a Math::BigInt object.

=item I<modulus>

C<$p-E<gt>modulus> returns the modulus common to all coefficients of
the modular integer polynomial C<$p>.

=item I<number_of_terms>

C<$p-E<gt>number_of_terms> returns the number of non-zero
coefficients of the modular integer polynomial C<$p>.

This method should actually better be provided by the parent class,
as the property is not quite specific to modular integer coefficients.
Expect this to be done in an upcoming Math::Polynomial release.

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
L<Math::ModInt::Event|Math::ModInt::Event>.  Mixing different moduli or
dividing non-coprime elements could be causes.

Other error conditions, like using non-integers or non-objects where they
would be expected, are not rigorously checked and may yield unreliable
behavior rather than error messages.

The few error conditions that are actually diagnosed are these:

=over 4

=item C<usage error: modulus parameter missing>

The I<from_index> or I<from_int_poly> construcors have been used with
insufficient information as to the value of the modulus.  They should
be either invoked with an explicit modulus (recommended) or as an
object method.

=back

=head1 DEPENDENCIES

This library uses Math::ModInt (version 0.011 and up) for modular integer
calculations and Math::Polynomial (version 1.015 and up) for polynomial
arithmetic, as well as Carp (any version) for diagnostic messages.
The minimal required perl version is 5.6.

=head1 BUGS AND LIMITATIONS

Bug reports and suggestions are always welcome
E<8212> please submit them through the CPAN RT,
E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Polynomial-ModIntE<gt>.

=head1 SEE ALSO

=over 4

=item *

L<Math::Polynomial::ModInt::Order>

=item *

L<Math::Polynomial>

=item *

L<Math::ModInt>

=item *

L<Math::GaloisField>

=back

=head1 AUTHOR

Martin Becker, C<< <becker-cpan-mp (at) cozap.com> >>

=head1 CONTRIBUTING

Contributions to this library are welcome (see the CONTRIBUTING file).

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013-2019 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
