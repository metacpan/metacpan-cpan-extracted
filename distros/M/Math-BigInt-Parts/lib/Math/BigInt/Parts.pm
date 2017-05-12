# -*- mode: perl; coding: us-ascii-unix; -*-

package Math::BigInt::Parts;

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
use utf8;               # enable UTF-8 in source code

use Carp;               # routines like die() and warn() useful for modules
use Exporter;           # implements default import method for modules

our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(fparts eparts);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);

our $VERSION = '0.03';

use Math::BigFloat;

=pod

=head1 NAME

Math::BigInt::Parts - split a Math::BigInt into signed mantissa and exponent

=head1 SYNOPSIS

  use Math::BigInt::Parts;

  # Planck's constant

  $h = Math::BigFloat -> new('6.6260693e-34');

  # A non-zero, finite mantissa $m always satisfies 1 <= $m < 10:

  ($m, $e) = fparts($h);      # $m = 6.6260693, $e = -34

  # A non-zero, finite mantissa $m always satisfies 1 <= $m < 1000
  # and the exponent $e is always a multiple of 3:

  ($m, $e) = eparts($h);      # $m = 662.60693, $e = -36

  # Compare this to the standard parts method, which returns both
  # the mantissa and exponent as integers:

  ($m, $e) = $h -> parts();   # $m = 66260693, $e = -41

  # The functions can also be used as methods, by importing them
  # into the Math::BigInt namespace:

  {
      package Math::BigInt;
      use Math::BigInt::Parts ':all';
  }

  ($m, $e) = $h -> fparts();
  ($m, $e) = $h -> eparts();

=head1 DESCRIPTION

This module implements the Math::BigInt functions fparts() and eparts() which
are variants of the standard Math::BigInt method parts(). The functions
fparts() and eparts() return the mantissa and exponent with the values that are
common for floating point numbers in standard notation and in engineering
notation, respectively.

=head1 FUNCTIONS

=head2 Behaviour common to both functions

The following applies to both functions, and assumes the functions are called
using

  ($m, $e) = fparts($x);      # fparts() or eparts()
  $m = fparts($x);            # fparts() or eparts()

=over 4

=item Values

For a zero value operand C<$x>, both the mantissa C<$m> and the exponent C<$e>
is zero. For plus/minus infinity, the mantissa is a signed infinity and the
exponent is plus infinity. For NaN (Not-a-Number), both the mantissa and the
exponent is NaN. For a non-zero, finite C<$x>, see the appropriate function
below.

Regardless of the operand C<$x> and the function, the returned mantissa C<$m>
and the exponent C<$e> give back the value of C<$x> with

  $x = Math::BigFloat -> new(10) -> bpow($e) -> bmul($m);

or the more efficient

  $x = $m -> copy() -> blsft($e, 10);

Note that since $e is a Math::BigInt, the following

  $x = $m * 10 ** $e;

will only give back the value of C<$x> when C<$e> is non-negative.

=item Context

In list context the mantissa and exponent is returned. In scalar context the
mantissa is returned. In void context a warning is given, since there is no
point in using any of the functions in a void context.

=item Classes

The mantissa is always a Math::BigFloat object, and the exponent is always a
Math::BigInt object.

=back

=head2 Behaviour specific to each function

=over 4

=item fparts ()

For a non-zero, finite C<$x> the mantissa C<$m> always satisfies 1 E<lt>= C<$m>
E<lt> 10 and the exponent is an integer.

=cut

sub fparts {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'fparts';

    # Check the context.

    unless (defined wantarray) {
        carp "$name(): Useless use of $name in void context";
        return;
    }

    # Check the number of input arguments.

    #croak "$name(): Not enough input arguments" if @_ < 0;
    croak "$name(): Too many input arguments"   if @_ > 0;

    # Check the input argument.

    unless (UNIVERSAL::isa($self, 'Math::BigInt')) {
        croak "$name(): Input argument must be a Math::BigInt object",
          " or subclass thereof";
    }

    # Not-a-number.

    if ($self -> is_nan()) {
        my $mant = Math::BigFloat -> bnan();            # mantissa
        return $mant unless wantarray;                  # scalar context
        my $expo = Math::BigInt -> bnan();              # exponent
        return ($mant, $expo);                          # list context
    }

    # Infinity.
    #
    # Work around Math::BigInt inconsistency. The sign() method returns '-' and
    # '+' for negative and non-negative numbers, but '-inf' and '+inf' for
    # negative and positive infinity. Why not '-' and '+' for +/- inf too?

    if ($self -> is_inf()) {
        my $signstr = $self < 0 ? '-' : '+';
        my $mant = Math::BigFloat -> binf($signstr);    # mantissa
        return $mant unless wantarray;                  # scalar context
        my $expo = Math::BigInt -> binf('+');           # exponent
        return ($mant, $expo);                          # list context
    }

    # Finite number.
    #
    # Get the mantissa and exponent. The documentation for Math::BigInt says
    # that one should not assume that the mantissa is an integer. The code
    # below works also if the mantissa is a Math::BigFloat non-integer.

    # Split the number into mantissa and exponent. E.g., convert 3141500 into
    # 31415 and 2, since 3141500 = 31415 * 10^2.

    my ($mant, $expo) = $self -> parts();

    # Make sure the mantissa is a Math::BigFloat.

    $mant = Math::BigFloat -> new($mant)
      unless UNIVERSAL::isa($mant, 'Math::BigFloat');

    # Adjust the exponent so it is zero if the mantissa is zero.

    if ($mant -> bcmp(0)) {

        # The documentation for Math::BigInt says that the output of parts()
        # might not be normalized, i.e., 31400 might give 314 and 2, or 3140
        # and 1, or 314100 and 0. The code below, also works if the output of
        # parts() is 31.4 and 3, or 3.14 and 5, or 0.314 and 6, ...

        my ($ndigtot, $ndigfrac) = $mant -> length();

        # Compute the exponent by which the mantissa and exponent should be
        # adjusted so it is normalized in the sense that the mantissa M
        # satisfies 1 <= M < 10.

        my $expo10adj = $ndigtot - $ndigfrac - 1;

        # Adjust the mantissa. E.g., convert 31415 into 3.1415.

        my $fmant = $mant -> brsft($expo10adj, 10);

        # Scalar context. Return the mantissa only.

        return $fmant unless wantarray;

        # List context. Return the mantissa and the exponent. Adjust the
        # exponent the "opposite way" of how we adjusted the mantissa, to
        # ensure that the input argument = $fmant * 10 ** $fexpo.

        my $fexpo = $expo -> copy() -> badd($expo10adj);

        # We return the exponent as a Math::BigFloat so that people can use
        # $fmant * 10 ** fexpo and get what they expect.

        #$fexpo = Math::BigFloat -> new($fexpo);

        return ($fmant, $fexpo);

    } else {

        return $mant unless wantarray;

        # 0 -> 0e0, not 0e1

        $expo = $expo -> bzero();

        return ($mant, $expo);
    }

}

=pod

=item eparts ()

For a non-zero, finite C<$x> the mantissa C<$m> always satisfies 1 E<lt>= C<$m>
E<lt> 1000 and the exponent is an integer which is a multiple of 3.

=cut

sub eparts {
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;
    my $name    = 'eparts';

    # Check the context.

    unless (defined wantarray) {
        carp "$name(): Useless use of $name in void context";
        return;
    }

    # Check the number of input arguments.

    #croak "$name(): Not enough input arguments" if @_ < 0;
    croak "$name(): Too many input arguments"   if @_ > 0;

    # Check the input argument.

    unless (UNIVERSAL::isa($self, 'Math::BigInt')) {
        croak "$name(): Input argument must be a Math::BigInt object",
          " or subclass thereof";
    }

    # Not-a-number and Infinity.
    #
    # Simply call the "fparts" method in this case.

    if ($self -> is_nan() || $self -> is_inf()) {
        return fparts($self);
    }

    # Finite number.
    #
    # Call the "fparts" method and adjust its output so the exponent becomes a
    # multiple of 3.

    my ($fmant, $fexpo) = fparts($self);

    # Make sure the exponent is a multiple of 3, and adjust the mantissa and
    # accordingly.

    my $c = $fexpo -> copy() -> bmod(3);

    #my $emant = $fmant * 10 ** $c;
    my $emant = $fmant -> blsft($c, 10);

    # Scalar context.  Return the mantissa only.

    return $emant unless wantarray;

    # List context.

    my $eexpo = $fexpo - $c;
    return ($emant, $eexpo);
}

=pod

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-bigint-parts at rt.cpan.org>, or through the web interface at

  L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-BigInt-Parts>

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Math::BigInt::Parts

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Math-BigInt-Parts>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Math-BigInt-Parts>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-BigInt-Parts>

=item * CPAN Testers PASS Matrix

L<http://pass.cpantesters.org/distro/M/Math-BigInt-Parts.html>

=item * CPAN Testers Reports

L<http://www.cpantesters.org/distro/M/Math-BigInt-Parts.html>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-BigInt-Parts>

=back

=head1 SEE ALSO

The documentation for Math::BigInt and Math::BigFloat.

=head1 AUTHOR

Peter John Acklam, E<lt>pjacklam@online.noE<gt>

If you have found this module to be useful, I will be happy to hear about it!

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2010 by Peter John Acklam E<lt>pjacklam@online.noE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;                      # modules must return true
