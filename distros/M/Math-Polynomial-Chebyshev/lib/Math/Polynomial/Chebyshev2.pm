# -*- coding: utf-8-unix -*-

package Math::Polynomial::Chebyshev2;

use 5.008;
use utf8;
use strict;
use warnings;

use Carp qw< croak >;
use Math::Polynomial;

our $VERSION = '0.01';
our @ISA = qw< Math::Polynomial >;

=pod

=encoding UTF-8

=head1 NAME

Math::Polynomial::Chebyshev2 - Chebyshev polynomials of the second kind

=head1 SYNOPSIS

    use Math::Polynomial::Chebyshev2;

    # create a Chebyshev polynomial of the second kind of order 7
    my $p = Math::Polynomial::Chebyshev2 -> chebyshev2(7);

    # get the location of all roots
    my $x = $p -> roots();

    # use higher accuracy
    use Math::BigFloat;
    Math::BigFloat -> accuracy(60);
    my $n = Math::BigFloat -> new(7);
    $x = Math::Polynomial::Chebyshev2 -> chebyshev2($n);

=head1 DESCRIPTION

This package extends Math::Polynomial, so each instance polynomial created by
this modules is a subclass of Math::Polynomial.

The Chebyshev polynomials of the second kind are orthogonal with respect to the
weight function sqrt(1-x^2).

The first Chebyshev polynomials of the second kind are

    U₀(x) = 1
    U₁(x) = 2 x
    U₂(x) = 4 x^2 - 1
    U₃(x) = 8 x^3 - 4 x
    U₄(x) = 16 x^4 - 12 x^2 + 1
    U₅(x) = 32 x^5 - 32 x^3 + 6 x
    U₆(x) = 64 x^6 - 80 x^4 + 24 x^2 - 1
    U₇(x) = 128 x^7 - 192 x^5 + 80 x^3 - 8 x
    U₈(x) = 256 x^8 - 448 x^6 + 240 x^4 - 40 x^2 + 1
    U₉(x) = 512 x^9 - 1024 x^7 + 672 x^5 - 160 x^3 + 10 x

=head1 CLASS METHODS

=head2 Constructors

=over 4

=item I<chebyshev2($n)>

C<Math::Polynomial::Chebyshev2-E<gt>chebyshev2($n)> creates a new polynomial of
order C<$n>, where C<$n> is a non-negative integer.

    # create a Chebyshev polynomial of the second kind of order 7
    $p = Math::Polynomial::Chebyshev2 -> chebyshev2(7);

    # do the same, but with Math::BigFloat coefficients
    use Math::BigFloat;
    $n = Math::BigFloat -> new(7);
    $p = Math::Polynomial::Chebyshev2 -> chebyshev2($n);

    # do the same, but with Math::Complex coefficients
    use Math::Complex;
    $n = Math::Complex -> new(7);
    $p = Math::Polynomial::Chebyshev2 -> chebyshev2($n);

=cut

sub chebyshev2 {
    my $class = shift;
    my $n = shift;

    croak "order must be an integer" unless $n == int $n;

    my $zero = $n - $n;
    my $one  = $n ** 0;
    my $two  = $one + $one;

    my $c = [];
    if ($n == 0) {
        $c = [ $one ];
    } elsif ($n == 1) {
        $c = [ $zero, $two ];
    } else {
        my $a = [ $one ];
        my $b = [ $zero, $two ];

        for (my $i = 2 ; $i <= $n ; ++$i) {
            $c = [ $zero, map { $two * $_ } @$b ];

            for (my $i = 0 ; $i <= $#$a ; ++$i) {
                $c -> [$i] -= $a -> [$i];
            }

            $a = $b;
            $b = $c;
        }
    }

    return $class -> new(@$c);
}

=pod

=back

=head2 Property Accessors

=over 4

=item I<roots()>

C<$p-E<gt>roots> returns the location of all root of C<$p>. All roots are
located in the open interval (-1,1).

    # get the roots of a polynomial
    @x = $p -> roots();

=cut

sub roots {
    my $self = shift;
    croak 'array context required' unless wantarray;

    my $n = $self -> degree();

    # Quick exit for the simple case N = 0.

    return () if $n == 0;

    # Quick exit for the simple case N = 1.

    my $zero = $self -> coeff_zero();
    return $zero if $n == 1;

    # The general case, when N > 0.

    my $one  = $self -> coeff_one();
    my $pi = atan2 $zero, -$one;
    my $c = $pi / ($n + 1);

    my @x = ();

    # First compute all roots in the open interval (0,1).

    @x = map { cos($c * $_) } 1 .. int($n / 2);

    # Now create an array with all extremas on the closed interval [-1,1].

    @x = (map({ -$_ } @x),
          ($n % 2 ? $zero : ()),
          reverse(@x));

    return @x;
}

=pod

=back

=head1 BUGS

Please report any bugs through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-Polynomial-Chebyshev2>
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Polynomial::Chebyshev2

You can also look for information at:

=over 4

=item * GitHub Source Repository

L<https://github.com/pjacklam/p5-Math-Polynomial-Chebyshev2>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Polynomial-Chebyshev2>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-Polynomial-Chebyshev2>

=item * MetaCPAN

L<https://metacpan.org/release/Math-Polynomial-Chebyshev2>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-Polynomial-Chebyshev2>

=back

=head1 SEE ALSO

=over

=item *

The Perl module L<Math::Polynomial>.

=item *

The Wikipedia page L<https://en.wikipedia.org/wiki/Chebyshev_polynomials>.

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2020 Peter John Acklam.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Peter John Acklam E<lt>pjacklam (at) gmail.comE<gt>.

=cut

1;
