# -*- Perl -*-
#
# slide rule virtualization for Perl

package Math::SlideRule;

use 5.010000;

use Moo;
use namespace::clean;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '1.06';

########################################################################
#
# ATTRIBUTES

# these are taken from common scale names on a slide rule; see code for
# how they are populated
has A => ( is => 'lazy', );
has C => ( is => 'lazy', );

sub _build_A { $_[0]->_range_exp_weighted( 1, 100 ) }
sub _build_C { $_[0]->_range_exp_weighted( 1, 10 ) }

# increased precision comes at the cost of additional memory use
#
# NOTE changing the precision after A, C and so forth have been
# generated will do nothing to those values. instead, construct a new
# object with a different precision set, if necessary
has precision => ( is => 'rw', default => sub { 10_000 } );

########################################################################
#
# METHODS

# builds two arrays, one of values (1, 2, 3...), another of distances
# based on the log of those values. these arrays returned in a hash
# reference. slide rule lookups obtain the index of a value, then use
# that to find the distance of that value, then uses other distances
# to figure out some new location, that a new value can be worked back
# out from
#
# NOTE that these scales are not calibrated directly to one another
# as they would be on a slide rule
sub _range_exp_weighted {
    my ( $self, $min, $max ) = @_;

    my @range = map log, $min, $max;
    my ( @values, @distances );

    my $slope = ( $range[1] - $range[0] ) / $self->precision;

    for my $d ( 0 .. $self->precision ) {
        # via slope equation; y = mx + b and m = (y2-y1)/(x2-x1) with
        # assumption that precision 0..$mp and @range[min,max]
        push @distances, $slope * $d + $range[0];
        push @values,    exp $distances[-1];
    }

    return { value => \@values, dist => \@distances };
}

# binary search an array of values for a given value, returning index of
# the closest match. used to lookup values and their corresponding
# distances from the various A, C, etc. attribute tables. NOTE this
# routine assumes that the given value has been normalized e.g. via
# standard_form to lie somewhere on or between the minimum and maximum
# values in the given array reference
sub _rank {
    my ( $self, $value, $ref ) = @_;

    my $lo = 0;
    my $hi = $#$ref;

    while ( $lo <= $hi ) {
        my $mid = int( $lo + ( $hi - $lo ) / 2 );
        if ( $ref->[$mid] > $value ) {
            $hi = $mid - 1;
        } elsif ( $ref->[$mid] < $value ) {
            $lo = $mid + 1;
        } else {
            return $mid;
        }
    }

    # no exact match; return index of value closest to the numeral supplied
    if ( $lo > $#$ref ) {
        return $hi;
    } else {
        if ( abs( $ref->[$lo] - $value ) >= abs( $ref->[$hi] - $value ) ) {
            return $hi;
        } else {
            return $lo;
        }
    }
}

# division is just multiplication done backwards on a slide rule, as the
# same physical distances are involved. there are also "CF" and "CI" (C
# scale, folded, or inverse) and so forth scales to assist with such
# operations, though these mostly just help avoid excess motions on the
# slide rule
#
# NOTE cannot just pass m*(1/n) to multiply() because that looses
# precision: .82 for 75/92 while can get .815 on pocket slide rule
sub divide {
    my $self = shift;
    my $n    = shift;
    my $i    = 0;

    die "need at least two numbers\n" if @_ < 1;
    die "argument index $i not a number\n" if !defined $n or !looks_like_number($n);

    my ( $n_coe, $n_exp, $neg_count ) = $self->standard_form($n);

    my $n_idx    = $self->_rank( $n_coe, $self->C->{value} );
    my $distance = $self->C->{dist}[$n_idx];
    my $exponent = $n_exp;

    for my $m (@_) {
        $i++;
        die "argument index $i not a number\n" if !looks_like_number($m);

        $neg_count++ if $m < 0;

        my ( $m_coe, $m_exp, undef ) = $self->standard_form($m);
        my $m_idx = $self->_rank( $m_coe, $self->C->{value} );

        $distance -= $self->C->{dist}[$m_idx];
        $exponent -= $m_exp;

        if ( $distance < $self->C->{dist}[0] ) {
            $distance = $self->C->{dist}[-1] + $distance;
            $exponent--;
        }
    }

    my $d_idx = $self->_rank( $distance, $self->C->{dist} );
    my $product = $self->C->{value}[$d_idx];

    $product *= 10**$exponent;
    $product *= -1 if $neg_count % 2 == 1;

    return $product;
}

sub multiply {
    my $self = shift;
    my $n    = shift;
    my $i    = 0;

    die "need at least two numbers\n" if @_ < 1;
    die "argument index $i not a number\n" if !defined $n or !looks_like_number($n);

    my ( $n_coe, $n_exp, $neg_count ) = $self->standard_form($n);

    # chain method has first lookup on D and then subsequent done by
    # moving C on slider and keeping tabs with the hairline, then reading
    # back on D for the final result. (plus incrementing the exponent
    # count when a reverse slide is necessary, for example for 3.4*4.1, as
    # that jumps to the next magnitude)
    #
    # one can also do the multiplication on the A and B scales, which is
    # handy if you then need to pull the square root off of D. but this
    # implementation ignores such alternatives
    my $n_idx    = $self->_rank( $n_coe, $self->C->{value} );
    my $distance = $self->C->{dist}[$n_idx];
    my $exponent = $n_exp;

    for my $m (@_) {
        $i++;
        die "argument index $i not a number\n" if !looks_like_number($m);

        $neg_count++ if $m < 0;

        my ( $m_coe, $m_exp, undef ) = $self->standard_form($m);
        my $m_idx = $self->_rank( $m_coe, $self->C->{value} );

        $distance += $self->C->{dist}[$m_idx];
        $exponent += $m_exp;

        # order of magnitude change, adjust back to bounds (these are
        # notable on a slide rule by having to index from the opposite
        # direction than usual for the C and D scales (though one could
        # also obtain the value with the A and B or the CI and DI
        # scales, but those would then need some rule to track the
        # exponent change))
        if ( $distance > $self->C->{dist}[-1] ) {
            $distance -= $self->C->{dist}[-1];
            $exponent++;
        }
    }

    my $d_idx = $self->_rank( $distance, $self->C->{dist} );
    my $product = $self->C->{value}[$d_idx];

    $product *= 10**$exponent;
    $product *= -1 if $neg_count % 2 == 1;

    return $product;
}

# relies on conversion from A to C scales (and that the distances in
# said scales are linked to one another)
sub sqrt {
    my ( $self, $n ) = @_;
    die "argument not a number\n" if !defined $n or !looks_like_number($n);
    die "Can't take sqrt of $n\n" if $n < 0;

    my ( $n_coe, $n_exp, undef ) = $self->standard_form($n);

    if ( $n_exp % 2 == 1 ) {
        $n_coe *= 10;
        $n_exp--;
    }

    my $n_idx = $self->_rank( $n_coe, $self->A->{value} );

    # NOTE division is due to A and C scale distances not being calibrated
    # directly with one another
    my $distance = $self->A->{dist}[$n_idx] / 2;

    my $d_idx = $self->_rank( $distance, $self->C->{dist} );
    my $sqrt = $self->C->{value}[$d_idx];

    $sqrt *= 10**( $n_exp / 2 );

    return $sqrt;
}

# converts numbers to standard form (scientific notation) or otherwise
# between a particular range of numbers (to support A/B "double
# decade" scales)
sub standard_form {
    my ( $self, $val, $min, $max ) = @_;

    $min //= 1;
    $max //= 10;

    my $is_neg = $val < 0 ? 1 : 0;

    $val = abs $val;
    my $exp = 0;

    if ( $val < $min ) {
        while ( $val < $min ) {
            $val *= 10;
            $exp--;
        }
    } elsif ( $val >= $max ) {
        while ( $val >= $max ) {
            $val /= 10;
            $exp++;
        }
    }

    return $val, $exp, $is_neg;
}

1;
__END__

=head1 NAME

Math::SlideRule - slide rule support for Perl

=head1 SYNOPSIS

Simulate an analog computer.

  use Math::SlideRule;

  my $sr = Math::SlideRule->new();

  # scientific notation breakdown (discards sign)
  $sr->standard_form(-1234); # [ 1.234, 3, 0 ]

  # these use the "C/D" scales, or values from 1..10 with some
  # degree of precision
  $sr->divide(75, 92);
  $sr->multiply(1.5, 3.7);
  $sr->multiply(-1.1, 2.2, -3.3, 4.4);

  # this uses an A/B to C/D scale conversion
  $sr->sqrt(42);

=head1 DESCRIPTION

Slide rule support for Perl. Or, a complicated way to perform basic
mathematical operations on a digital computer.
L<Math::SlideRule::PickettPocket> approximates a N 3P-ES pocket
slide rule.

=head1 ATTRIBUTES

Scales and settings related to the generation of such. The scales are
not scaled to one another as they are on a slide rule, so relations
between B<A> and B<C> will require appropriate math.

=over 4

=item B<A>

Double decade scale from 1..100. Used by B<sqrt> in conjunction with
B<C> scale. Weighted towards the low end, so has greater precision near
1 than at 100. Overall precision may be set by the B<precision>
attribute only when the object is constructed.

Internally, a hash reference of C<value> and C<dist> arrays, where the
index of a particular value corresponds to a particular logarithmic
distance. The internal B<_rank> method is used to find the index of a
particular value or distance in these arrays.

=item B<C>

Scale from 1..10. Used by B<multiply> and B<divide>. Weighted towards
the low end.

=item B<precision> I<num>

How precise the scales should be, 10000 by default over the range of the
scale. Higher precision entails increased memory use for the resulting
scale structures. Changing this on the fly is not supported.

=back

=head1 METHODS

Calls will throw an exception if something goes awry.

=over 4

=item B<divide> I<n1>, I<n2>, ...

Divide the given numbers.

=item B<multiply> I<n1>, I<n2>, ...

Multiply the given numbers.

  $sr->multiply(2, 3);    # 6 (or so)
  $sr->multiply(2..5);    # 120 (ish)

=item B<sqrt> I<num>

Take the square root of the given number.

=item B<standard_form> I<num>, [ I<min>, I<max> ]

This method returns a number as a list consisting of the characteristic,
exponent, and whether the number is negative or not. Used internally by
various methods.

  $sr->standard_form(5550)    # 5.55, 3, 0
  $sr->standard_form(-640)    # 6.4,  2, 1

The optional min and max values allow for a normal form between values
besides the defaults of 1 and 10, though using a minimum value below 1
may result in unexpected or undefined results, elsewhere.

=item B<_rank> I<value>, I<listofvalues>

Internal use only. Performs a binary search for a given I<value> within
an array reference of values. B<standard_form> or such should be used to
ensure that the I<value> lies within the limits of the given list of
values. The values usually will come from the letter attribute routines
that tie various numerals to given logarithmic distances.

=back

=head1 BUGS

=head2 Reporting Bugs

If the bug is in the latest version, send a report to the author.
Patches that fix problems or add new features are welcome.

L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-SlideRule>

L<https://github.com/thrig/Math-SlideRule>

=head2 Known Issues

Incomplete implementation, e.g. missing log, trig scales. Hilariously
slow compared to just doing the math directly in Perl.

=head1 SEE ALSO

L<Math::Round> for various rounding methods (and the usual disclaimers
about floating point numbers that this module does use).

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<https://opensource.org/licenses/BSD-3-Clause>

=cut
