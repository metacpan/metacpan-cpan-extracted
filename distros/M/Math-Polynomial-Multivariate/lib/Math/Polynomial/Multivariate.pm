# Copyright (c) 2011-2014 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: Multivariate.pm 17 2014-02-21 12:51:52Z demetri $

package Math::Polynomial::Multivariate;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);

use overload (
    q[neg]      => \&_neg,
    q[+]        => \&_add,
    q[-]        => \&_sub,
    q[*]        => \&_mul,
    q[**]       => \&_pow,
    q[==]       => \&_eq,
    q[!=]       => \&_ne,
    q[!]        => 'is_null',
    q[bool]     => 'is_not_null',
    q[""]       => 'as_string',
    q[fallback] => undef,
);

# ----- object definition -----

# Math::Polynomial::Multivariate=ARRAY(...)

# .......... index ..........   # .......... value ..........
use constant F_TERMS  => 0;     # monomial terms hashref
use constant F_ZERO   => 1;     # zero element of coefficient space
use constant F_ONE    => 2;     # unit element of coefficient space
use constant NFIELDS  => 3;

# a term value is an anonymous arrayref:
# .......... index ..........   # .......... value ..........
use constant T_COEFF  => 0;     # coefficient
use constant T_VARS   => 1;     # variables hashref, mapping names to exponents

use constant K_SEP    => chr 0;
use constant K_SEP_RE => qr/\0/;

use constant _MINUS_INFINITY => - (~0) ** (~0);

# ----- class data -----

our $VERSION = '0.005';

# ----- private subroutines -----

# create a "clean" copy of a variables hashref, without zero exponents
sub _vclean {
    my %vars = %{$_[0]};
    delete @vars{grep {!$vars{$_}} keys %vars};
    die "hash of integer exponents expected"
        if grep {!eval { $_ == int abs $_ }} values %vars;
    return \%vars;
}

# map a clean variables hashref to a key
sub _key {
    my ($vars) = @_;
    return
        join K_SEP,
        map { ($_, chr $vars->{$_}) }
        reverse sort keys %{$vars};
}

# map an arbitrary variables hashref to a key
sub _keyvc {
    my ($vars) = @_;
    return
        join K_SEP,
        map { ($_, chr $vars->{$_}) }
        reverse sort
        grep { $vars->{$_} }
        keys %{$vars};
}

# ----- private methods -----

# extract coefficient space information from an invocant and some coefficient
sub _space {
    my ($this, $const) = @_;
    my $class = ref $this;
    my ($zero, $one);
    if ($class) {
        ($zero, $one) = @{$this}[F_ZERO, F_ONE];
    }
    else {
        $class = $this;
        $zero = $const - $const;
        $one  = $const ** 0;
    }
    return ($class, $zero, $one);
}

# create an independent duplicate of an object
sub _clone {
    my ($this) = @_;
    my $terms = $this->[F_TERMS];
    return
        bless [
            { map {($_ => [@{$terms->{$_}}])} keys %{$terms} },
            @{$this}[F_ZERO, F_ONE]
        ], ref $this;
}

# overloaded operators

sub _neg {
    my ($this) = @_;
    my $result = $this->_clone;
    foreach my $term (values %{$result->[F_TERMS]}) {
        $term->[T_COEFF] = -$term->[T_COEFF];
    }
    return $result;
}

sub _add {
    my ($this, $that) = @_;
    $that = $this->const($that) if !ref($that) || !$that->isa(__PACKAGE__);
    my $result = $this->_clone;
    my $rterms = $result->[F_TERMS];
    my $zero   = $this->[F_ZERO];
    while (my ($key, $term) = each %{$that->[F_TERMS]}) {
        if (exists $rterms->{$key}) {
            if ($zero == ($rterms->{$key}->[T_COEFF] += $term->[T_COEFF])) {
                delete $rterms->{$key};
            }
        }
        else {
            $rterms->{$key} = [@{$term}];
        }
    }
    return $result;
}

sub _sub {
    my ($this, $that, $swap) = @_;
    $that = $this->const($that) if !ref($that) || !$that->isa(__PACKAGE__);
    ($this, $that) = ($that, $this) if $swap;
    my $result = $this->_clone;
    my $rterms = $result->[F_TERMS];
    my $zero   = $this->[F_ZERO];
    while (my ($key, $term) = each %{$that->[F_TERMS]}) {
        if (exists $rterms->{$key}) {
            if ($zero == ($rterms->{$key}->[T_COEFF] -= $term->[T_COEFF])) {
                delete $rterms->{$key};
            }
        }
        else {
            my $rterm = $rterms->{$key} = [@{$term}];
            $rterm->[T_COEFF] = -$rterm->[T_COEFF];
        }
    }
    return $result;
}

sub _mul {
    my ($this, $that) = @_;
    $that = $this->const($that) if !ref($that) || !$that->isa(__PACKAGE__);
    my $result = $this->null;
    my $bterms = $that->[F_TERMS];
    my $rterms = $result->[F_TERMS];
    my $zero   = $this->[F_ZERO];
    foreach my $aterm (values %{$this->[F_TERMS]}) {
        my @avars = %{$aterm->[T_VARS]};
        foreach my $bterm (values %{$bterms}) {
            my %vars = @avars;
            my $const = $aterm->[T_COEFF] * $bterm->[T_COEFF];
            my $bvars = $bterm->[T_VARS];
            foreach my $bv (keys %{$bvars}) {
                $vars{$bv} += $bvars->{$bv};
            }
            my $key = _key(\%vars);
            if (exists $rterms->{$key}) {
                $rterms->{$key}->[T_COEFF] += $const;
            }
            else {
                $rterms->{$key} = [$const, \%vars];
            }
        }
    }
    delete @{$rterms}{
        grep {$zero == $rterms->{$_}->[T_COEFF]} keys %{$rterms}
    };
    return $result;
}

sub _pow {
    my ($this, $exp, $swap) = @_;
    croak 'illegal exponent' if $swap || $exp != int abs $exp;
    return $this->const($this->[F_ONE]) if !$exp;
    my $result = $this->_clone;
    while (--$exp > 0) {
        $result *= $this;
    }
    return $result;
}

sub _eq_ne {
    my ($this, $that, $eq) = @_;
    $that = $this->const($that) if !ref($that) || !$that->isa(__PACKAGE__);
    my $aterms = $this->[F_TERMS];
    my $bterms = $that->[F_TERMS];
    return !$eq if keys(%{$aterms}) != keys(%{$bterms});
    while (my ($key, $term) = each %{$aterms}) {
        return !$eq
            if !exists($bterms->{$key}) ||
                $term->[T_COEFF] != $bterms->{$key}->[T_COEFF];
    }
    return $eq;
}

sub _eq {
    my ($this, $that) = @_;
    return $this->_eq_ne($that, !0);
}

sub _ne {
    my ($this, $that) = @_;
    return $this->_eq_ne($that, !1);
}

# ----- public methods -----

# constructors

sub null {
    my ($this) = @_;
    my ($class, $zero, $one) = $this->_space(1);
    return bless [{}, $zero, $one], $class;
}

sub const {
    my ($this, $value) = @_;
    my ($class, $zero, $one) = $this->_space($value);
    my %terms = $zero == $value? (): (q[] => [$value, {}]);
    return bless [\%terms, $zero, $one], $class;
}

sub var {
    my ($this, $varname) = @_;
    my ($class, $zero, $one) = $this->_space(1);
    my $vars = { $varname => 1 };
    my $key = _key($vars);
    my %terms = ($key => [$one, $vars]);
    return bless [\%terms, $zero, $one], $class;
}

sub monomial {
    my ($this, $const, $vars) = @_;
    my ($class, $zero, $one) = $this->_space($const);
    $vars = _vclean($vars);
    my %terms = $zero == $const? (): (_key($vars) => [$const, $vars]);
    return bless[\%terms, $zero, $one], $class;
}

sub subst {
    my ($this, $varname, $that) = @_;
    my @exps = (-1, $this->exponents_of($varname));
    return $this->null if 1 == @exps;
    my $exp    = pop @exps;
    my $result = $this->factor_of($varname, $exp);
    my $nexp   = pop @exps;
    while ($exp > 0) {
        $result *= $that;
        if (--$exp == $nexp) {
            $result += $this->factor_of($varname, $exp);
            $nexp = pop @exps;
        }
    }
    return $result;
}

sub partial_derivative {
    my ($this, $varname, $cast) = @_;
    my $result = $this->null;
    foreach my $exp ($this->exponents_of($varname)) {
        next if !$exp;
        my $const = $cast? $cast->($exp): $exp;
        $result +=
            $this->factor_of($varname, $exp) *
            $this->monomial($const, { $varname => $exp-1 });
    }
    return $result;
}

# inspection methods

sub is_null     {  !keys %{$_[0]->[F_TERMS]} }
sub is_not_null { !!keys %{$_[0]->[F_TERMS]} }

sub variables {
    my ($this) = @_;
    my %vars = map {%{$_->[T_VARS]}} values %{$this->[F_TERMS]};
    return sort keys %vars;
}

sub exponents_of {
    my ($this, $varname) = @_;
    my $terms = $this->[F_TERMS];
    my %exps = ();
    foreach my $term (values %{$terms}) {
        $exps{$term->[T_VARS]->{$varname} || 0} = undef;
    }
    return sort { $a <=> $b } keys %exps;
}

sub factor_of {
    my ($this, $varname, $exp) = @_;
    my $terms  = $this->[F_TERMS];
    my $result = $this->null;
    my $rterms = $result->[F_TERMS];
    foreach my $term (values %{$terms}) {
        my $aexp = $term->[T_VARS]->{$varname} || 0;
        if ($aexp == $exp) {
            my %vars = %{$term->[T_VARS]};
            delete $vars{$varname};
            $rterms->{_key(\%vars)} = [$term->[T_COEFF], \%vars];
        }
    }
    return $result;
}

sub coefficient {
    my ($this, $vars) = @_;
    my $key = _keyvc($vars);
    my $terms = $this->[F_TERMS];
    return exists($terms->{$key})? $terms->{$key}->[T_COEFF]: $this->[F_ZERO];
}

sub degree {
    my ($this) = @_;
    my $terms = $this->[F_TERMS];
    return _MINUS_INFINITY if !keys %{$terms};
    my $max_degree = 0;
    foreach my $term (values %{$terms}) {
        my $degree = 0;
        foreach my $e (values %{$term->[T_VARS]}) {
            $degree += $e;
        }
        if ($max_degree < $degree) {
            $max_degree = $degree;
        }
    }
    return $max_degree;
}

sub multidegree {
    my ($this) = @_;
    my $terms = $this->[F_TERMS];
    my %result = ();
    foreach my $term (values %{$terms}) {
        while (my ($name, $exp) = each %{$term->[T_VARS]}) {
            if (($result{$name} || 0) < $exp) {
                $result{$name} = $exp;
            }
        }
    }
    return \%result;
}

sub number_of_terms { scalar keys %{$_[0]->[F_TERMS]} }

sub evaluate {
    my ($this, $values) = @_;
    my @vars = $this->variables;
    if (my @miss = grep { !exists $values->{$_} } @vars) {
        my $s = 1 == @miss? q[]: 's';
        croak "missing variable$s: @miss";
    }
    my $result = $this;
    foreach my $varname (@vars) {
        $result = $result->subst($varname, $this->const($values->{$varname}));
    }
    return $result->coefficient({});
}

sub as_monomials {
    my ($this) = @_;
    my $terms = $this->[F_TERMS];
    return scalar keys %{$terms}   if !wantarray;
    return ([$this->[F_ZERO], {}]) if !keys %{$terms};
    return
        map {
            my ($coeff, $vars) = @{$terms->{$_}};
            [$coeff, {%{$vars}}]
        } sort keys %{$terms};
}

sub as_string {
    my ($this) = @_;
    my $one = $this->[F_ONE];
    return
        join q[ + ],
        map {
            my ($const, $vars) = @{$_};
            join q[*],
            keys(%{$vars}) && $one == $const? (): $const,
            map {
                my $exp = $vars->{$_};
                1 == $exp? $_: "$_^$exp"
            }
            sort keys %{$vars}
        }
        $this->as_monomials;
}

1;
__END__

=head1 NAME

Math::Polynomial::Multivariate - Perl class for multivariate polynomials

=head1 VERSION

This documentation refers to version 0.005 of Math::Polynomial::Multivariate.

=head1 SYNOPSIS

  use Math::Polynomial::Multivariate;

  my $two = Math::Polynomial::Multivariate->const(2);
  my $x   = Math::Polynomial::Multivariate->var('x');
  my $xy  = Math::Polynomial::Multivariate->
                    monomial(1, {'x' => 1, 'y' => 1});
  my $pol = $x**2 + $xy - $two;
  print "$pol\n";               # prints: -2 + x^2 + x*y

  my @mon = $pol->as_monomials;
  # assigns: ([-2, {}], [1, {x => 2}], [1, {x => 1, y => 1}])
  my $n_terms = $pol->as_monomials;
  print "$n_terms\n";           # prints: 3

  my $rat = Math::BigRat->new('-1/3');
  my $c   = Math::Polynomial::Multivariate->const($rat);
  my $y   = $c->var('y');
  my $lin = $x - $c;
  print "$lin\n";               # prints: 1/3 + x

  my $zero = $c - $c;           # zero polynomial on rationals
  my $null = $c->null;          # dito

  my $p = $c->monomial($rat, { 'a' => 2, 'b' => 1 });
  print "$p\n";                 # prints: -1/3*a^2*b
  my $f = $p->coefficient({'a' => 2, 'b' => 1});
  print "$f\n";                 # prints: -1/3
  my $q = $p->subst('a', $c);
  print "$q\n";                 # prints: -1/27*b
  my $v = $p->evaluate({'a' => 6, 'b' => -1});
  print "$v\n";                 # prints: 12

  my @vars = $pol->variables;
  print "@vars\n";              # prints: x y
  my @exp = $pol->exponents_of('x');
  print "@exp\n";               # prints: 0 1 2
  my $r   = $pol->factor_of('x', 1);
  print "$r\n";                 # prints: y
  my $d = $pol->degree;
  print "$d\n";                 # prints: 2
  my $z = $zero->degree;
  print "$z\n";                 # prints:
  # platform-dependent equivalent of minus infinity

  my $pd = $pol->partial_derivative('x');
  print "$pd\n";                # prints: 2*x + y

=head1 DESCRIPTION

Math::Polynomial::Multivariate is a Perl class representing polynomials
in any number of variables.  It provides a set of operations defined
for these polynomials, like addition, multiplication, evaluation,
variable substitution, etc., as well as attribute inspection and
formatting capabilities.

Objects of this class can be created using some simple constructors
and expressions with overloaded arithmetic operators.  They are
immutable.

Each polynomial object is bound to specific variables.  For practical
purposes, variables are identified by unique names given as strings.
Polynomials bound to different variables can be combined in a single
expression, resulting in a new polynomial bound to the union of all
contributing variables.  Any polynomial will be treated as a
polynomial of degree zero with respect to a variable it is not already
bound to.  Therefore, all polynomials sharing a common coefficient
space are compatible to each other.

Polynomials are considered equal if they are bound to the same set
of variables and have equal non-zero coefficients.  Zero coefficients
do not bind, thus the zero polynomial is not bound to any variable.

=head2 Constructors

=over 4

=item null

Invoked as a class method, C<Math::Polynomial::Multivariate-E<gt>null>
returns a null polynomial on Perl numerical values.

Invoked as an object method, C<$obj-E<gt>null> returns a null
polynomial on the coefficient space of C<$obj>.

=item const

Invoked as a class method,
C<Math::Polynomial::Multivariate-E<gt>const($value)> returns a
constant polynomial on the coefficent space containing C<$value>.

Invoked as an object method, C<$obj-E<gt>const($value)> returns a
constant polynomial on the coefficient space of C<$obj>.
C<$value> must belong to the same coefficient space.

=item var

Invoked as a class method,
C<Math::Polynomial::Multivariate-E<gt>var($varname)> returns an
identity polynomial in the named variable on Perl numerical values.

Invoked as an object method, C<$obj-E<gt>var($varname)> returns an
identity polynomial in the named variable on the coefficient space
of C<$obj>.

=item monomial

Invoked as a class method,
C<Math::Polynomial::Multivariate-E<gt>monomial($const, $vars)>
returns a one-term polynomial on the coefficent space containing
C<$const>.

Invoked as an object method, C<$obj-E<gt>monomial($const, $vars)>
returns a one-term polynomial on the coefficient space of C<$obj>.
C<$const> must belong to the same coefficient space.

In both cases, C<$vars> is a hashref mapping variable names to
non-negative integer exponents.

Example: C<$p-E<gt>monomial(1, {'x' =E<gt> 1})> is equivalent to
C<$p-E<gt>var('x')>.

=back

=head2 Overloaded Perl Operators

=over 4

=item Negation

If C<$p> is a polynomial, C<-$p> evaluates as the negative of C<$p>.

=item Addition

If C<$p> and C<$q> are polynomials on the same coefficient space,
C<$p + $q> evaluates as the sum of C<$p> and C<$q>.

=item Subtraction

If C<$p> and C<$q> are polynomials on the same coefficient space,
C<$p - $q> evaluates as the difference of C<$p> and C<$q>.

=item Multiplication

If C<$p> and C<$q> are polynomials on the same coefficient space,
C<$p * $q> evaluates as the product of C<$p> and C<$q>.

=item Exponentiation

If C<$p> is a polynomial and C<$n> is a non-negative integer number,
C<$p ** $n> evaluates as the C<$n>th power of C<$p>.

=item Checks for Equality

If C<$p> and C<$q> are polynomials on the same coefficient space,
C<$p == $q> and C<$p != $q> are boolean expressions telling whether
C<$p> and C<$q> are equal or unequal, respectively.

Equality implies that both polynomials are bound to the same variables
and are composed of the same terms.

=item Boolean Context

In boolean context, null polynomials evaluate as false and all other
polynomials as true.

=item String Context

In string context, polynomials are converted to a string representation.
See L</as_string>.

=back

=head2 Other Operators

=over 4

=item subst

If C<$p> and C<$q> are polynomials on the same coefficient space,
C<$p-E<gt>subst($varname, $q)> returns a polynomial obtained
from C<$p> by substituting the variable named C<$varname> by the
polynomial C<$q>.

=item partial_derivative

If C<$p> is a polynomial on a coefficient space compatible to Perl
integer numbers, C<$p-E<gt>partial_derivative($varname)> returns
the first partial derivative of C<$p> with respect to the variable
named C<$varname>.

If C<$p> is a polynomial on any coefficient space and C<$cast> is
a coderef referencing a subroutine that takes a positive integer
I<n> and returns the element representing I<n> times the unit element
of this coefficient space, C<$p-E<gt>partial_derivative($varname,
$cast)> returns the first partial derivative of C<$p> with respect
to the variable named C<$varname>.

Example: For the coefficient space of 4E<215>4 matrices of Perl
numerical values, C<$cast> could be a reference to a function taking
a single value and returning a 4E<215>4 diagonal matrix with this
value.

=back

=head2 Inspection Methods

=over 4

=item is_null

If C<$p> is a polynomial, C<$p-E<gt>is_null> returns a boolean value
telling whether C<$p> is the null polynomial.

=item is_not_null

If C<$p> is a polynomial, C<$p-E<gt>is_not_null> returns a boolean
value telling whether C<$p> is not the null polynomial.

=item variables

If C<$p> is a polynomial, C<$p-E<gt>variables> returns an alphabetically
ordered list of names of variables this polynomial is bound to.

Note that only variables in terms with non-zero coefficients are
taken into account.  For example, a null polynomial will yield an
empty list even if it was the result of an addition of non-zero
polynomials.

=item exponents_of

If C<$p> is a polynomial, C<$p-E<gt>exponents_of($varname)> returns
a list of non-negative integer exponents in ascending numerical
order, specifying all powers of the named variable that are present
in terms with non-zero coefficients of the polynomial.

Note that if C<$p> is not bound to the named variable and not zero,
a single exponent of zero will be returned.  If C<$p> is the null
polynomial, an empty list will be returned.

=item factor_of

If C<$p> is a polynomial, C<$p-E<gt>factor_of($varname, $exponent)>
returns the polynomial factor of the given variable power in that
polynomial.  In other words, the terms in C<$p> are grouped by
powers of the named variable, the specific power is selected, and
factored out.

Example:

  $c = Math::Polynomial::Multivariate->const(3);
  $x = $c->var('x');
  $y = $c->var('y');
  $p = ($y**2 + $c * $y - $c) * $x**2 + ($y - $c) * $x**3;
  $q = $p->factor_of('x', 2);   # (I)
  $q = $y**2 + $c * $y - $c;    # same as (I)

=item coefficient

If C<$p> is a polynomial and C<$variables> is a hashref mapping
variable names to non-negative integer exponents,
C<$p-E<gt>coefficient($variables)> returns the coefficient of an
individual term in C<$p> with the given signature.

Example:

  $c = Math::Polynomial::Multivariate->const(4);
  $x = $c->var('x');
  $y = $c->var('y');
  $p = $x**2 * $y - $c * $x * $y**2;
  $a = $p->coefficient( {'x' => 2, 'y' => 1} );
  $b = $p->coefficient( {'x' => 1, 'y' => 2} );
  $c = $p->coefficient( {'x' => 0, 'y' => 3} );
  # now $a is 1, $b is -4, $c is 0

Note that in the C<$variables> hashref, variables with zero exponent
may be omitted.

=item degree

If C<$p> is a polynomial with only one term with non-zero coefficient,
C<$p-E<gt>degree> returns the sum of all exponents of the variables
present there.

If C<$p> is an arbitrary polynomial other than null, C<$p-E<gt>degree>
returns the largest degree of all its terms with non-zero coefficients.

If C<$p> is the null polynomial, C<$p-E<gt>degree> returns
minus infinity.

Example:

  $c = Math::Polynomial::Multivariate->const(5);
  $x = $c->var('x');
  $y = $c->var('y');
  $p = $x**3 * $y**3 - $c * $x**2 * $y**5;
  $d = $p->degree;
  # now $d is 7

=item multidegree

If C<$p> is a polynomial, C<$p-E<gt>multidegree> returns a hashref
mapping variable names to positive integer exponents, denoting the
largest degree of each variable in any term of C<$p> with non-zero
coefficient.  Zero exponents are omitted.  Thus, the null polynomial
as well as constant polynomials will yield an empty hashref.

Example:

  $c = Math::Polynomial::Multivariate->const(6);
  $x = $c->var('x');
  $y = $c->var('y');
  $p = $x**3 * $y**3 - $c * $x**2 * $y**5;
  $m = $p->multidegree;
  # now $m is { 'x' => 3, 'y' => 5 }

=item number_of_terms

If C<$p> is a polynomial, C<$p-E<gt>number_of_terms> returns the
number of distinct terms with non-zero coefficients of C<$p>.

This number will be at least 0 and at most the product of all
values, incremented by one, of the multidegree hashref.

=item evaluate

If C<$p> is a polynomial and $values is a hashref mapping variable
names to values in the coefficient space of C<$p>,
C<$p-E<gt>evaluate($values)> returns the value of the polynomial
at the given coordinates.  The C<$values> hashref must contain all
names of variables that appear in terms with non-zero coefficients.
It may contain values of additional variables.

Example:

  $c = Math::Polynomial::Multivariate->const(7);
  $x = $c->var('x');
  $y = $c->var('y');
  $p = $c + $x + $y;
  $z = $p->evaluate({'x' => 8, 'y' => 9});
  # now $z is 24

=item as_string

If C<$p> is a polynomial, C<$p-E<gt>as_string> returns a text
representation of it.  It is the same as the value of C<$p> in
string context.

Variables are ordered lexically, terms are ordered from lowest
exponent to highest, exponents of last variables taking precedence
over earlier ones.  Each term is represented as a product of the
coefficient and the variable powers, with an asterisk as a
multiplication symbol and a plus as addition symbol between terms.
A caret is used as exponentiation symbol.  Terms with zero coefficient
are suppressed except for the null polynomial which is represented
by the constant zero.  Variables are given by their name.  Coefficients
appear in whatever form they take on in string context.  Values of
one as a coefficient or as an exponent are omitted where possible.

Example:

  1 + 2*x + x^2 + 2*y + 2*x*y + y^2

=item as_monomials

If C<$p> is a polynomial, C<$p-E<gt>as_monomials> returns a list
of monomial term descriptors in the same order as as_string.
A descriptor is an arrayref of a coefficient and a variables hashref
(like the pair of parameters for the L</monomial> constructor).

For the zero polynomial, a single term with a zero coefficient and an
empty variables hash is returned.

In scalar context, the number of nonzero terms is returned.

=back

=head2 EXPORT

None.

=head1 DIAGNOSTICS

This module generally croaks on usage errors it detects.  This
means, outside of an eval block program execution will terminate
with an error message indicating the offending method call.

=over 4

=item illegal exponent

The power operator (C<**>) was used with a negative or non-integer
exponent.  In the domain of polynomials, only exponentiation by
non-negative integers is defined in general.

=item missing variable: %s

=item missing variables: %s

The I<evaluate> method was called with a hashref not containing all
required variable names.  The missing name or names are listed in
the message.

=back

=head1 DEPENDENCIES

This version of Math::Polynomial::Multivariate requires these other
modules and libraries to run:

=over 4

=item *

perl version 5.8.0 or higher

=item *

overload (usually bundled with perl)

=item *

Carp (usually bundled with perl)

=back

Additional requirements to run the test suite are:

=over 4

=item *

Test::More (usually bundled with perl)

=back

Recommended modules for increased functionality are:

=over 4

=item *

Math::BigRat (usually bundled with perl)

=item *

Any other module providing a coefficient space with overloaded
arithmetic operators C<+>, C<->, C<*>, C<**>, C<==>, C<!=>, and
stringification.

=back

=head1 BUGS AND LIMITATIONS

Currently, not a lot of usage errors are caught and reported via
individual diagnostics.  Notably, there are no safeguards against
mixing incompatible coefficients within one polynomial expression.

Some constructors may look more generic than they actually are: It
would be best, perhaps, not to use I<null> and I<var> as class
methods at all, as this usage implies a coefficient space, and one
with many shortcomings at that.

There may be a hidden limitation on the maximal exponent of a
variable on some platforms.  This will go away or become an explicit
limitation before this library is declared stable.  If your exponents
stay well below 2**32 you probably should not worry.

The functionality of this module should not be taken as final.

Bug reports and suggestions are always welcome -- please submit
them via the CPAN RT:
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Polynomial-Multivariate>

=head1 ROADMAP

As of version 0.004, the module interface is still in beta state.
While upcoming improvements are intended to be mostly extensions,
changes breaking backwards compatibility may yet be considered.

Features planned for future releases include:

=over 4

=item *

Polynomial substitution, using remainder decomposition.
This generalizes simple variable substitution.

=item *

Interoperability with, or conversion functions to/from, Math::Polynomial
objects.

=item *

Division with remainder.

=item *

More string formatting options.

=back

=head1 SEE ALSO

=over 4

=item *

L<Math::Polynomial> - perl class for univariate polynomials

=item *

L<Math::Symbolic> - perl class for more general arithmetic expressions

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp@cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2014 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
