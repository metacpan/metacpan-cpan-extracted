# -*- coding: utf-8-unix -*-

package Math::Polynomial::Chebyshev;

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

Math::Polynomial::Chebyshev - Chebyshev polynomials of the first kind

=head1 SYNOPSIS

    use Math::Polynomial::Chebyshev;

    # create a Chebyshev polynomial of the first kind of order 7
    my $p = Math::Polynomial::Chebyshev -> chebyshev(7);

    # get the location of all extremas
    my $x = $p -> extremas();

    # get the location of all roots
    $x = $p -> roots();

    # use higher accuracy
    use Math::BigFloat;
    Math::BigFloat -> accuracy(60);
    my $n = Math::BigFloat -> new(7);
    $x = Math::Polynomial::Chebyshev -> chebyshev($n);

=head1 DESCRIPTION

This package extends Math::Polynomial, so each instance polynomial created by
this modules is a subclass of Math::Polynomial.

The Chebyshev polynomials of the first kind are orthogonal with respect to the
weight function 1/sqrt(1-x^2).

The first Chebyshev polynomials of the first kind are

    T₀(x) = 1
    T₁(x) = x
    T₂(x) = 2 x^2 - 1
    T₃(x) = 4 x^3 - 3 x
    T₄(x) = 8 x^4 - 8 x^2 + 1
    T₅(x) = 16 x^5 - 20 x^3 + 5 x
    T₆(x) = 32 x^6 - 48 x^4 + 18 x^2 - 1
    T₇(x) = 64 x^7 - 112 x^5 + 56 x^3 - 7 x
    T₈(x) = 128 x^8 - 256 x^6 + 160 x^4 - 32 x^2 + 1
    T₉(x) = 256 x^9 - 576 x^7 + 432 x^5 - 120 x^3 + 9 x

=head1 CLASS METHODS

=head2 Constructors

=over 4

=item I<chebyshev($n)>

C<Math::Polynomial::Chebyshev-E<gt>chebyshev($n)> creates a new polynomial of
order C<$n>, where C<$n> is a non-negative integer.

    # create a Chebyshev polynomial of the first kind of order 7
    $p = Math::Polynomial::Chebyshev -> chebyshev(7);

    # do the same, but with Math::BigFloat coefficients
    use Math::BigFloat;
    $n = Math::BigFloat -> new(7);
    $p = Math::Polynomial::Chebyshev -> chebyshev($n);

    # do the same, but with Math::Complex coefficients
    use Math::Complex;
    $n = Math::Complex -> new(7);
    $p = Math::Polynomial::Chebyshev -> chebyshev($n);

=cut

sub chebyshev {
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
        $c = [ $zero, $one ];
    } else {
        my $a = [ $one ];
        my $b = [ $zero, $one ];

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

=item I<roots()>

C<$p-E<gt>roots> return the location of all root of C<$p>. All roots
are located in the open interval (-1,1).

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
    my $c = $pi / $n;

    my @x = ();

    # First compute all roots in the open interval (0,1).

    @x = map { cos($c * ($_ - 0.5)) } 1 .. int($n / 2);

    # Now create an array with all extremas on the closed interval [-1,1].

    @x = (map({ -$_ } @x),
          ($n % 2 ? $zero : ()),
          reverse(@x));

    return @x;
}

=pod

=item I<extremas()>

C<$p-E<gt>extremas> returns the location of all extremas of C<$p> located in
the closed interval [-1,1]. There are no extremas outside of this interval.
Only the extremas in the closed interval (-1,1) are local extremas. All
extremas have values +/-1.

    # get the extremas of a polynomial
    @x = $p -> extremas();

=cut

sub extremas {
    my $self = shift;
    croak 'array context required' unless wantarray;

    my $n = $self -> degree();

    # Quick exit for the simple case N = 0.

    my $zero = $self -> coeff_zero();
    return $zero if $n == 0;

    # The general case, when N > 0.

    my $one  = $self -> coeff_one();
    my $pi = atan2 $zero, -$one;
    my $c = $pi / $n;

    my @x = ();

    # First compute all extremas in the open interval (0, 1).

    @x = map { cos($c * $_) } 1 .. int(($n - 1) / 2);

    # Now create an array with all extremas on the closed interval [-1,1].

    @x = (-$one,
          map({ -$_ } @x),
          ($n % 2 ? () : $zero),
          reverse(@x),
          $one);

    return @x;
}

=pod

=back

=head1 BUGS

Please report any bugs through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-Polynomial-Chebyshev>
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Polynomial::Chebyshev

You can also look for information at:

=over 4

=item * GitHub Source Repository

L<https://github.com/pjacklam/p5-Math-Polynomial-Chebyshev>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Polynomial-Chebyshev>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-Polynomial-Chebyshev>

=item * MetaCPAN

L<https://metacpan.org/release/Math-Polynomial-Chebyshev>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-Polynomial-Chebyshev>

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
