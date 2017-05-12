package Math::Fraction::Egyptian;

use strict;
use warnings FATAL => 'all';
use base 'Exporter';
use List::Util qw(first reduce max);

our @EXPORT_OK = qw( to_egyptian to_common );

our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.01';

my %PRIMES = map { $_ => 1 } primes();

=head1 NAME

Math::Fraction::Egyptian - construct Egyptian representations of fractions

=head1 SYNOPSIS

    use Math::Fraction::Egyptian ':all';
    my @e = to_egyptian(43, 48);  # returns 43/48 in Egyptian format
    my @v = to_common(2, 3, 16);  # returns 1/2 + 1/3 + 1/16 in common format

=head1 DESCRIPTION

From L<Wikipedia|http://en.wikipedia.org/wiki/Egyptian_fractions>:

=over 4

An Egyptian fraction is the sum of distinct unit fractions, such as

    1/2 + 1/3 + 1/16

That is, each fraction in the expression has a numerator equal to 1 and a
denominator that is a positive integer, and all the denominators differ
from each other. The sum of an expression of this type is a positive
rational number C<a/b>; for instance the Egyptian fraction above sums to
C<43/48>.

Every positive rational number can be represented by an Egyptian fraction.
Sums of this type, and similar sums also including C<2/3> and C<3/4> as
summands, were used as a serious notation for rational numbers by the
ancient Egyptians, and continued to be used by other civilizations into
medieval times.

In modern mathematical notation, Egyptian fractions have been superseded by
L<vulgar fractions|http://en.wikipedia.org/wiki/Vulgar_fraction> and
decimal notation.  However, Egyptian fractions continue to be an object of
study in modern number theory and recreational mathematics, as well as in
modern historical studies of ancient mathematics.

=back

A common fraction has an infinite number of different Egyptian fraction
representations.  This module only implements a handful of conversion
strategies for conversion of common fractions to Egyptian form; see section
L<STRATEGIES> below for details.

=head1 FUNCTIONS

=head2 to_egyptian($numer, $denom, %attr)

Converts fraction C<$numer/$denom> to its Egyptian representation.

Example:

     my @egypt = to_egyptian(5,9);  # converts 5/9
     print "@egypt";                # prints FIXME

=cut

sub to_egyptian {
    my ($n,$d,%attr) = @_;
    ($n,$d) = (abs(int($n)), abs(int($d)));
    $attr{dispatch} ||= \&_dispatch;

    # oh come on
    if ($d == 0) { die "can't convert $n/$d"; }

    # handle improper fractions
    if ($n >= $d) {
        my $n2 = $n % $d;
        warn "$n/$d is an improper fraction; expanding $n2/$d instead";
        $n = $n2;
    }

    my @egypt;
    while ($n && $n != 0) {
        ($n, $d, my @e) = $attr{dispatch}->($n,$d);
        push @egypt, @e;
    }
    return @egypt;
}

# default strategy dispatcher
sub _dispatch {
    my ($n, $d) = @_;
    my @egypt;

    my @strategies = (
        [ trivial          => \&s_trivial, ],
        [ small_prime      => \&s_small_prime, ],
        [ practical_strict => \&s_practical_strict, ],
        [ practical        => \&s_practical, ],
        [ greedy           => \&s_greedy, ],
    );

    STRATEGY:
    for my $s (@strategies) {
        my ($name,$coderef) = @$s;
        my @result = eval { $coderef->($n,$d); };
        next STRATEGY if $@;
        my ($n2, $d2, @e2) = @result;
        ($n,$d) = ($n2,$d2);
        push @egypt, @e2;
        last STRATEGY;
    }
    return $n, $d, @egypt;
}

=head2 to_common(@denominators)

Converts an Egyptian fraction into a common fraction.

Example:

    my ($num,$den) = to_common(2,5,11);     # 1/2 + 1/5 + 1/11 = ?
    print "$num/$den";                      # prints "87/110"

=cut

sub to_common {
    my ($n,$d) = (0,1);
    for my $a (@_) {
        ($n, $d) = simplify($a * $n + $d, $a * $d);
    }
    return ($n,$d);
}

=head2 GCD($x,$y)

Uses Euclid's algorithm to determine the greatest common denominator
("GCD") of C<$x> and C<$y>.  Returns the GCD.

=cut

sub GCD {
    my ($x, $y) = (int($_[0]), int($_[1]));
    return ($y) ? GCD($y, $x % $y) : $x;
}

=head2 simplify($n,$d)

Reduces fraction C<$n/$d> to simplest terms.

Example:

    my @x = simplify(25,100);   # @x is (1,4)

=cut

sub simplify {
    my ($n, $d) = @_;
    my $gcd = GCD($n,$d);
    return ($n / $gcd, $d / $gcd);
}

=head2 primes()

Returns a list of all prime numbers below 1000.

=cut

sub primes {
    return qw(
        2 3 5 7 11 13 17 19 23 29 31 37 41 43 47 53 59 61 67 71 73 79 83 89
        97 101 103 107 109 113 127 131 137 139 149 151 157 163 167 173 179
        181 191 193 197 199 211 223 227 229 233 239 241 251 257 263 269 271
        277 281 283 293 307 311 313 317 331 337 347 349 353 359 367 373 379
        383 389 397 401 409 419 421 431 433 439 443 449 457 461 463 467 479
        487 491 499 503 509 521 523 541 547 557 563 569 571 577 587 593 599
        601 607 613 617 619 631 641 643 647 653 659 661 673 677 683 691 701
        709 719 727 733 739 743 751 757 761 769 773 787 797 809 811 821 823
        827 829 839 853 857 859 863 877 881 883 887 907 911 919 929 937 941
        947 953 967 971 977 983 991 997
    );
}

=head2 prime_factors($n)

Returns the prime factors of C<$n> as a list of (prime,multiplicity) pairs.
The list is sorted by increasing prime number.

Example:

    my @pf = prime_factors(120);    # 120 = 2 * 2 * 2 * 3 * 5
    # @pf = ([2,3],[3,1],[5,1])

=cut

sub prime_factors {
    my $n = shift;
    my @primes = primes();
    my %pf;
    for my $i (0 .. $#primes) {
        my $p = $primes[$i];
        while ($n % $p == 0) {
            $pf{$p}++;
            $n /= $p;
        }
        last if $n == 1;
    }
    return unless $n == 1;
    return map { [ $_, $pf{$_} ] } sort { $a <=> $b } keys %pf;
}

=head2 decompose($n)

If C<$n> is a composite number, returns ($p,$q) such that:

    * $p != 1
    * $q != 1
    * $p x $q == $n

=cut

sub decompose {
    my @pf = reverse map { ($_->[0]) x $_->[1] } prime_factors($_[0]);
    my ($p, $q) = (1, 1);
    for my $f (@pf) {
        if ($p < $q) { $p *= $f }
        else         { $q *= $f }
    }
    return sort { $a <=> $b } $p, $q;
}

=head2 sigma(@pairs)

Helper function for determining whether a number is "practical" or not.

=cut

sub sigma {
    # see http://en.wikipedia.org/wiki/Divisor_function
    my @pairs = @_;
    my $term = sub {
        my ($p,$a) = @_;
        return (($p ** ($a + 1)) - 1) / ($p - 1);
    };
    return reduce { $a * $b } map { $term->(@$_) } @pairs;
}

=head1 STRATEGIES

Fibonacci, in his Liber Abaci, identifies seven different methods for
converting common to Egyptian fractions:

=over 4

=item 1.

=item 2.

=item 3.

=item 4.

=item 5.

=item 6.

=item 7.

=back

The strategies as implemented below have the following features in common:

=over 4

=item *

Each function call has a signature of the form C<I<strategy>($numerator,
$denominator)>.

=item *

The return value from a successful strategy call is the list C<($numerator,
$denominator, @egyptian)>: the new numerator, the new denominator, and
zero or more new Egyptian factors extracted from the input fraction.

=item *

Some strategies are not applicable to all inputs.  If the strategy
determines that it cannot determine the next number in the expansion, it
throws an exception (via C<die()>) to indicate the strategy is unsuitable.

=back

=cut

=head2 s_trivial($n,$d)

Strategy for dealing with "trivial" expansions--if C<$n> is C<1>, then this
fraction is already in Egyptian form.

Example:

    my @x = s_trivial(1,5);     # @x = (0,1,5)

=cut

sub s_trivial {
    my ($n,$d) = @_;
    if (defined($n) && $n == 1) {
        return (0,1,$d);
    }
    die "unsuitable strategy";
}

=head2 s_small_prime($n,$d)

For a numerator of 2 with odd prime denominator d, one can use this
expansion:

    2/d = 2/(d + 1) + 2/d(d + 1)

=cut

sub s_small_prime {
    my ($n,$d) = @_;
    if ($n == 2 && $d > 2 && $d < 30 && $PRIMES{$d}) {
        my $x = ($d + 1) / 2;
        return (0, 1, $x, $d * $x);
    }
    else {
        die "unsuitable strategy";
    }
}

=head2 s_practical($n,$d)

Attempts to find a multiplier C<$M> such that the scaled denominator C<$M *
$d> is a practical number.  This lets us break up the scaled numerator C<$M
* $numer> as in this example:

    examining 2/9:
        9 * 2 is 18, and 18 is a practical number
        choose $M = 2

    scale 2/9 => 4/18
              =  3/18 + 1/18
              =  1/6 + 1/18

By definition, all numbers N < P, where P is practical, can be represented
as a sum of distinct divisors of P.

=cut

sub s_practical {
    my ($n,$d) = @_;

    # look for a multiple of $d that is a practical number
    my $M = first { is_practical($_ * $d) } 1 .. $d;
    die "unsuitable strategy" unless $M;

    $n *= $M;
    $d *= $M;

    my @divisors = grep { $d % $_ == 0 } 1 .. $d;

    my @N;
    my %seen;
    while ($n) {
        @divisors = grep { $_ <= $n } @divisors;
        my $x = max @divisors;
        push @N, $x;
        $n -= $x;
        @divisors = grep { $_ < $x } @divisors;
    }
    my @e = map { $d / $_ } @N;
    return (0, 1, @e);
}

=head2 s_practical_strict($n,$d)




=cut

sub s_practical_strict {
    my ($N,$D) = @_;

    # find multiples of $d that are practical numbers
    my @mult = grep { is_practical($_ * $D) } 1 .. $D;

    die "unsuitable strategy" unless @mult;

    MULTIPLE:
    for my $M (@mult) {
        my $n = $N * $M;
        my $d = $D * $M;

        # find the divisors of $d
        my @div = grep { $d % $_ == 0 } 1 .. $d;

        # expand $n into a sum of divisors of $d
        my @N;
        while ($n) {
            next MULTIPLE unless @N;
            @div = grep { $_ <= $n } @div;
            my $x = max @div;
            push @N, $x;
            $n -= $x;
            @div = grep { $_ < $x } @div;
        }
        my @e = map { $d / $_ } @N;

        next MULTIPLE if $e[0] != $M;
        next MULTIPLE if grep { $d % $_ } @e[1 .. $#e]; # FIXME

# o
#    4. As an observation a1, ..., ai were always divisors of the
#       denominator a of the first partition 1/a

        return (0, 1, @e);
    }
    die "unsuitable strategy";
}

=head2 is_practical($n)

Returns a true value if C<$n> is a practical number.

=cut

my $_practical;
sub is_practical {
    my $n = shift;
    unless (exists $_practical->{$n}) {
        $_practical->{$n} = _is_practical($n);
    }
    return $_practical->{$n};
}

sub _is_practical {
    my $n = shift;
    return 1 if $n == 1;        # edge case
    return 0 if $n % 2 == 1;    # no odd practicals except 1
    my @pf = prime_factors($n);
    foreach my $i (1 .. $#pf) {
        my $p = $pf[$i][0];
        return 0 if ($p > 1 + sigma( @pf[0 .. $i-1]));
    }
    return 1;
}

=head2 s_composite($n,$d)

From L<Wikipedia|http://en.wikipedia.org/wiki/Egyptian_fraction>:

=over 4

For composite denominators, factored as p×q, one can expand 2/pq using the
identity 2/pq = 1/aq + 1/apq, where a = (p+1)/2.  Clearly p must be odd.

For instance, applying this method for d = pq = 21 gives p=3, q=7, and
a=(3+1)/2=2, producing the expansion 2/21 = 1/14 + 1/42.

=back

=cut

sub s_composite {
    my ($n,$d) = @_;
    die "unsuitable strategy" if $PRIMES{$d};
    my ($p,$q) = decompose($d);

    # is $p odd
    if ($p % 2 == 1) {
        my $a = ($p + 1) / 2;
        return (0, 1, $a * $q, $a * $p * $q);
    }

    # is $q odd
    if ($q % 2 == 1) {
        my $a = ($q + 1) / 2;
        return (0, 1, $a * $p, $a * $p * $q);
    }

    die "unsuitable strategy";
}

=head2 s_greedy($n,$d)

Implements Fibonacci's greedy algorithm for computing Egyptian fractions:

    n/d => 1/ceil(d/n) + ((-d)%n)/(d*ceil(d/n))

Example:

    # performing the greedy expansion of 3/7:
    #   ceil(7/3) = 3
    #   new numerator = (-7)%3 = 2
    #   new denominator = 7 * 3 = 21
    # so 3/7 => 1/3 + 2/21

    my ($n,$d,$e) = greedy(2,7);
    print "$n/$d ($e)";     # prints "2/21 (3)"

=cut

sub s_greedy {
    use POSIX 'ceil';
    my ($n,$d) = @_;
    my $e = ceil( $d / $n );
    ($n, $d) = simplify((-1 * $d) % $n, $d * $e);
    return ($n, $d, $e);
}

=head1 AUTHOR

John Trammell, C<< <johntrammell <at> gmail <dot> com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-fraction-egyptian at
rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Fraction-Egyptian>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Fraction::Egyptian

You can also look for information at:

=over 4

=item * GitHub

L<http://github.com/jotr/math-fraction-egyptian>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Fraction-Egyptian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Fraction-Egyptian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Fraction-Egyptian>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Fraction-Egyptian/>

=back

=head1 RESOURCES

=over 4

=item L<http://en.wikipedia.org/wiki/Category:Egyptian_fractions>

=item L<http://en.wikipedia.org/wiki/Common_fraction>

=item L<http://en.wikipedia.org/wiki/Rhind_Mathematical_Papyrus>

=item L<http://en.wikipedia.org/wiki/RMP_2/n_table>

=item L<http://en.wikipedia.org/wiki/Liber_Abaci>

=item L<http://en.wikipedia.org/wiki/Egyptian_fraction>

=item L<http://mathpages.com/home/kmath340/kmath340.htm>

=item L<http://mathworld.wolfram.com/RhindPapyrus.html>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Project Euler, L<http://projecteuler.net/>, for stretching my mind
into obscure areas of mathematics.  C<< :-) >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 John Trammell, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

