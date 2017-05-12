# Copyright (c) 2009-2016 by Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: Generic.pm 129 2016-08-08 17:27:26Z demetri $

package Math::Polynomial::Generic;

use 5.006;
use strict;
use warnings;
use Carp qw(carp croak);
use Math::Polynomial 1.000;

require Exporter;

use base qw(Math::Polynomial Exporter);

our @EXPORT_OK = qw( X C );
our %EXPORT_TAGS = ( legacy => [] );

our $VERSION = '1.011';

my $deprecated  = 1;
my $x_singleton = Math::Polynomial::Generic->new(0, 1);

sub X () {
    _warn_deprecated() if $deprecated;
    return $x_singleton;
}

sub C ($) {
    my ($value) = @_;
    return Math::Polynomial->new($value);
}

sub import {
    $deprecated = 1;
    foreach my $arg (@_[1 .. $#_]) {
        $deprecated = 0, last if ':legacy' eq $arg;
    }
    _warn_deprecated() if $deprecated;
    Math::Polynomial::Generic->export_to_level(1, @_);
}

sub _warn_deprecated {
    $deprecated = 0;
    carp __PACKAGE__, ' is deprecated';
}

sub _is_generic { return 1; }

sub _cast {
    my ($this, $that) = @_;
    my ($zero, $one) = ($that->coeff_zero, $that->coeff_one);
    my @coeff =
        map {
            my $n = $_;
            my ($r, $c) = ($zero, $one);
            if ($n < 0) {
                $n = -$n;
                $c = -$c;
            }
            while ($n) {
                if (1 & $n) {
                    $r = $r + $c;
                }
                $n >>= 1 and $c = $c + $c;
                # note: "+=" intentionally avoided
            }
            $r
        } $this->coeff;
    return $that->new( @coeff );
}

sub divmod {
    croak 'implementation restriction: generic division not defined';
}

sub div { goto &divmod; }
sub mod { goto &divmod; }

1;
__END__

=head1 NAME

Math::Polynomial::Generic - syntactical sugar coating Math::Polynomial

=head1 VERSION

This documentation refers to version 1.011 of Math::Polynomial::Generic.

=head1 DEPRECATION NOTICE

This module has always been declared as experimental and its interface
as not to be taken for granted.  The intention was to give users
more expressive flexibility through a kind of polynomial object
that is not bound to a particular coefficient space.

This experiment is now considered a failure.  Coefficient spaces need to
be specified at one point, and delaying this part of proper initialization
seems do do more harm than good in terms of clarity.

Therefore, Math::Polynomial::Generic is now deprecated.  Using the module
now triggers a deprecation warning unless the special symbol C<:legacy>
appears on the import list.  At some time after January 1, 2017, the
module will be discontinued altogether.

=head1 SYNOPSIS

  use Math::Polynomial::Generic qw(:legacy X C);

  $p = X**2 - 3 * X + 5;
  $q = $p * X;
  $r = (X - $some_value) * (X - $some_other_value);
  $s = C($some_value) * X**2 + C($some_other_value);

=head1 DESCRIPTION

Math::Polynomial::Generic allows to create Math::Polynomial objects
in a more descriptive way than with basic constructors.  It offers
a symbol I<X> that will act as a polynomial when used as the variable
in a polynomial expression.  Another one-letter symbol I<C> turns
constants into constant polynomials.

=head2 SUBROUTINES

=over 4

=item I<X>

C<X> is different from C<Math::Polynomial-E<gt>new(0, 1)> in that
it is not bound to a particular coefficient space.  C<X> can be
coupled in expressions with polynomials of arbitrary coefficient
types, such as complex numbers, big rationals, square matrices,
etc.  The coefficients actually used determine the coefficient space
of the whole expression.  Incompatible coefficient types must not
be mixed in a single expression, of course.

The mechanism to make this work is based on a kind of generic object
(hence the name) which will be cast to a proper polynomial when it
is used in a binary operation together with something already bound
to a coefficient space: either another polynomial or a plain
coefficient.

=item I<C>

C<C($coeff)> creates a constant polynomial from a given coefficient
value C<$coeff>.

Coefficients other than simple numerical values should be turned
into polynomials to prevent perl from carrying out the overloaded
operator in the coefficient class rather than the polynomial class
(see below).

Expressions containing I<X> but lacking any coefficient values will
produce generic polynomial objects.  These must not be mistaken for
proper polynomials, nor should Math::Polynomial methods be invoked
on them.

In order to turn an otherwise generic expression into a regular
polynomial object, add a C<C()>-wrapped zero value.

=back

=head2 EXAMPLES

  $c = Math::BigRat->new('2/3');   # some coefficient value
  $p = Math::Polynomial->new(1);   # some regular polynomial

  $q = X;                          # wrong (generic)
  $q = X * X - X;                  # wrong (generic)
  $q = X * X - X + C(0);           # OK
  $q = $p + X;                     # OK
  $q = X + $p;                     # OK
  $q = $p - X;                     # OK
  $q = X - $p;                     # OK
  $q = $p * X;                     # OK
  $q = $p / X;                     # OK
  $q = $p % X;                     # OK

  $q = $c + X;                     # wrong (operand types)
  $q = X + $c;                     # wrong (operand types)
  $q = C($c) + X;                  # OK
  $q = X + C($c);                  # OK
  $q = C($c) * X**2;               # OK

  $q = X / X + C(0);               # wrong (generic division)

=head2 OVERRIDDEN METHODS

=over 4

=item I<divmod>

=item I<div>

=item I<mod>

Currently, division of generic objects by generic objects (like C<X/X>) is
not implemented.  The methods I<divmod>, I<div> and I<mod> are overridden
to guard against such cases.

=back

=head2 PROTECTED METHODS

=over 4

=item I<_is_generic>

Boolean true for generic objects, false for regular polynomials.

=item I<_cast>

C<$p-E<gt>_cast($q)> generates a regular polynomial from a generic
object C<$p>, the result sharing the coefficient space with C<$q>.

=back

=head2 EXPORT

By default, nothing is exported into the caller's namespace.  The
polynomial generators X and C can be explicitly imported, however.

The special symbol C<:legacy> can be imported in order to suppress
deprecation warnings.

=head2 DIAGNOSTICS

=over 4

=item Math::Polynomial::Generic is deprecated

This warning is issued when the module is imported without the C<:legacy>
tag in the import list or when Math::Polynomial::Generic::X is called
for the first time after the module has been loaded without an import.

=back

=head2 MIGRATION

As this module has been declared deprecated, existing applications
should be migrated to no longer use it.  This, fortunately, is
rather easy.  Instead of the symbol C<X>, we recommend to use a
variable C<$X> that is initialized as
C<Math::Polynomial-E<gt>new($zero, $one)> with appropriate coefficient
values C<$zero> and C<$one>.

C<C($coeff)> can be replaced by C<Math::Polynomial-E<gt>new($coeff)>
or it can be defined locally as a small wrapper for the same.

=head1 SEE ALSO

  Math::Polynomial

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp@cozap.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2016 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This module is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
