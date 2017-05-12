package Math::Round::Fair;
use warnings;
use strict;
use 5.005000;
use Devel::Assert;
use Carp;
use base qw/Exporter/;
use List::Util qw/shuffle sum min/;
use POSIX qw/floor ceil DBL_EPSILON/;

our $VERSION = '0.03';

our @EXPORT_OK = qw/round_fair round_adjacent/;

BEGIN {
    my $debug;
    sub DEBUG { $debug }

    $debug = $ENV{MATH_ROUND_FAIR_DEBUG} || 0;
    use Devel::Assert DEBUG() ? ('-all -verbose') : ();

    # used in assertions
    eval q{use Perl6::Junction 'none'} if DEBUG();
}


=head1 NAME

Math::Round::Fair - distribute rounding errors fairly

=head1 SYNOPSIS

  use Math::Round::Fair 'round_fair', 'round_adjacent';

  my $cents = 7;
  my @weights = (1, 2, 3, 2, 1);
  my @allocation = round_fair($cents, @weights);

  print "@allocation\n";

  # output will be one of the following:
  # 0 1 3 2 1
  # 0 2 2 2 1
  # 0 2 3 1 1
  # 0 2 3 2 0
  # 1 1 2 2 1
  # 1 1 3 1 1
  # 1 1 3 2 0
  # 1 2 2 1 1
  # 1 2 2 2 0

  my @total;
  for ( 1..900 ) {
      @allocation = round_fair($cents, @weights);
      @total[$_] += @allocation[$_] for 0..$#allocation;
  }
  print "@total\n";

  # output will be *near* 700 1400 2100 1400 700, e.g.:
  # 698 1411 2096 1418 677


  my @rounded = round_adjacent(0.95, 0.65, 0.41, 0.99);
  # @rounded will be one of the following:
  # 59% of the time: 1, 1, 0, 1
  # 35% of the time: 1, 0, 1, 1
  #  5% of the time: 0, 1, 1, 1
  #  1% of the time: 1, 1, 1, 0


=head1 DESCRIPTION

This module provides two exportable functions, C<round_fair>, which
allocates an integer value, fairly distributing rounding errors, and
C<round_adjacent>, which takes a list of real numbers and rounds them up, or
down, to an adjacent integer, fairly. Both functions return a list of fairly
rounded integer values.

C<round_fair> and C<round_adjacent> round up, or down, randomly, where the
probability of rounding up is equal to the fraction to round.  For example, 0.5
will round to 1.0 with a probability of 0.5.  0.3 will round to 1.0 3 out of 10
times and to zero 7 out of 10 times, on average.

Consider the problem of distributing one indivisible item, for example a penny,
across three evenly weighted accounts, A, B, and C.

Using a naive approach, none of the accounts will receive an allocation since
the allocated portion to each is 1/3 and 1/3 rounds to zero.  We are left with
1 unallocated item.

Another approach is to adjust the basis at each step.  We start with 1 item to
allocate to 3 accounts.  1/3 rounds to 0, so account A receives no allocation,
and we drop it from consideration.  Now, we have 2 accounts and one item to
allocate.  1/2 rounds to 1, so we allocate 1 item to account B.  Account C
gets no allocation since there is nothing left to allocate.

But what happens if we allocate one item to the same three accounts 10,000
times? Ideally, two accounts should end up with 3,333 items and one should end
up with 3,334 items.

Using the naive approach, all three accounts receive no allocation since at
each round the allocation is 1/3 which rounds to zero. Using the second method,
account A and account C will receive no allocation, and account B will receive
a total allocation of 10,000 items.  Account B always receives the benefit of
the rounding errors using the second method.

The algorithm employed by this module uses randomness to ensure a fair distribution of
rounding errors.  In our example problem, we start with 1 item to allocate.  We
calculate account A's share, 1/3.  Since it is less than one item, we give it a
1/3 chance of rounding up (and, therefore, a 2/3 chance of rounding down).  It
wins the allocation 1/3 of the time.  2/3 of the time we continue to B. We
calculate B's allocation as 1/2 (since there are only 2 accounts remaining and
one item to allocate).  B rounds up 1/2 of 2/3 (or 1/3) of the time and down
1/2 of 2/3 (or 1/3) of the time.  If neither A nor B rounds up (which occurs
2/3 * 1/2, or 1/3 of the time), C's allocation is calculated as 1/1 since we
have one item to allocate and only one account to allocate it to.  So, 1/3 of
the time C receives the benefit of the rounding error.  We never end up with
any unallocated items.

This algorithm works for any number of weighted allocations.

=over 4

=item round_fair($value, @weights)

Returns a list of integer values that sum to C<$value> where each return value
is a portion of C<$value> allocated by the respective weights in C<@weights>.
The number of return values is equal to the number of elements in C<@weights>

C<$value> must be an integer.

=cut

sub round_fair {
    my $value = shift;

    croak "Value to be allocated must be an integer >= 0" unless int($value) == $value && $value >= 0;

    return ($value) if @_ == 1;
    return (0) x @_ if $value == 0;

    my $basis = 0;
    for my $w ( @_ ) {
        croak "Weights must be > 0" unless $w > 0;
        $basis += $w;
    }

    my $sum = 0;
    my @in = map { my $r = $value * $_ / $basis; $sum += $r; $r } @_;

    # First, create the extra entry for the total, so that the sum of
    # the new array is zero.
    push @in, -$sum;

    my $out = _round_adjacent_arrayref(\@in);
    pop @$out; # Discard the entry for the total

    return @$out;
}

=item round_adjacent(@input_values)

Returns a list of integer values, each of which is numerically
adjacent to the corresponding element of @input_values, and whose total is
numerically adjacent to the total of @input_values.

The expected value of each output value is equal to the corresponding element
of @input_values (within a small error margin due to the limited machine
precision).

=cut

sub round_adjacent {
    return () unless @_; # identity

    # First, create the extra entry for the total, so that the sum of
    # the new array is zero.
    push @_, -sum(@_);

    # use a reference to eliminate an unnecessary copy
    my $out = _round_adjacent_arrayref(\@_);

    pop @$out; # Discard the entry for the total
    return @$out;
}

sub _round_adjacent_arrayref {
    my $in = shift;

    # Next, shuffle the order, so that the input order has no effect
    # on the randomness characteristics.
    my @order = shuffle($[ .. $#{$in});
    @$in = map $in->[$_], @order;

    my $out = _round_adjacent_core($in);

    assert(sum(@$out) == 0);

    # put the output back into original order
    my @r;
    $r[$order[$_]] = $out->[$_] for $[ .. $#order;

    return \@r;
}

# Like _round_adjacent_arrayref, except that the inputs must sum to zero, and the
# input order may affect the variance and correlations, etc.
sub _round_adjacent_core {
    my $in = shift;

    assert(scalar @$in); # @$in must not be empty

    my $eps1 = 4.0 * DBL_EPSILON() * (1 + @$in);
    my $eps = $eps1;
    my @fp = map { my $ip = floor($_); $_ - $ip } @$in;

    assert(none(@fp) < 0.0);

    # TBD: Maybe accuracy or fairness can be improved by
    # re-adjusting after every iteration.  This would slow it
    # down significantly, though.
    _adjust_input(\@fp);

    my @out;
    INPUT: while() {
        $eps += $eps1;

        assert(_check_invariants($eps, $in, \@fp));

        # Calculate the next output.  Discard the next input in the
        # process.
        my $p0 = shift @fp; # Probability of having to overpay
        my $r0 = rand()<$p0 ? 1 : 0; # 1 if selected to overpay; else 0
        push @out, floor(shift @$in) + $r0;

        last unless @fp;

        # Now adjust the remaining fractional parts.

        # $slack[i] = min( $p0 * $fp[i], (1-$p0) * (1-$fp[i]) ).
        my @slack;
        my $tslack = 0.0;
        do {
            @slack = map {
                if ( 1 ) {
                    my $slack = min $p0 * $_, (1 - $_) * (1.0 - $p0);
                    $tslack += $slack;
                    $slack;
                }
                else {
                    # This is fewer FLOPS, but the perf benefit
                    # is only 1% on a modern system, and it leads
                    # to greater numerical errors for some reason.
                    my $add = $p0 + $_;
                    my $mult = $p0 * $_;
                    $add > 1.0 ? 1.0 - $add + $mult : $mult
                }
            } @fp;
        };

        # See bottom of file for proof of this property:
        assert($tslack + $eps >= $p0 * (1.0 - $p0));

        # wrapped in assert to make it a noop when DEBUG() == 0
        assert(do { warn "TSLACK = $tslack\n" if DEBUG() > 1; 1 });

        if ( $tslack > $eps1 ) {
            $eps += 128.0 * $eps1 * $eps / $tslack;
            # NOTE: The expected value of gain is
            #	$p0 * ($p0 - 1.0) /$tslack +
            #	(1.0 - $p0) * $p0 / $tslack = 0
            my $gain = do {
                if ( $r0 ) {
                    # Last guy overpaid, so the probabilities for
                    # subsequent payers drop.
                    ($p0 - 1.0) / $tslack;
                }
                else {
                    # Last guy underpaid, so the probabilities for
                    # subsequent payers rise.
                    $p0 / $tslack;
                }
            };

            # NOTE: The change in the sum of @fp due to this step
            # is $tslack * $gain, which is either $p0 or ($p0 - 1).
            # Either way, the sum remains an integer, because it
            # was reduced by $p0 when we shifted off the first
            # element early in the INPUT loop iteration.
            # Also note that each element of @fp stays in the range
            # [0,1] because if $r0, then slack($_, $p0) * -$gain <=
            # $p0 * $_ * (1.0 - $p0) / ($p0 * (1.0 - $p0)) ==
            # $_, and otherwise slack($_, $p0) * $gain <=
            # (1 - $p0) * (1 - $_) * $p0 / ($p0 * (1.0 - $p0)) ==
            # 1 - $_.
            # We modify in place here, for performance.
            $_ += shift(@slack) * $gain for @fp;
        }
    }
    assert(@$in == 0);
    return \@out;
}

sub _adjust_input {
    my $p = shift;

    # Adjust @$p to account for numerical errors due to small
    # difference of large numbers when the integer parts are big.
    my $sum = sum @$p;
    if ( $sum != floor($sum) ) {
        my $target = floor($sum + 0.5);

        die "Total loss of precision"
            unless abs($sum - $target) < 0.1 && $sum + 0.05 != $sum;

        my $adj = $target / $sum;
        if ( $adj <= 1.0 ) {
            $_ *= $adj for @$p;
        } else {
            $adj = (@$p - $target) / (@$p - $sum);
            $_ = 1.0 - (1.0-$_) * $adj for @$p;
        }
    }
}

sub _check_invariants {
    my ( $eps, $v, $fp ) = @_;

    if ( DEBUG() > 1 ) {
        warn sprintf "%d %f\n", floor($_), $_ for @$fp;
    }

    assert(@$v && @$v == @$fp);

    for ( @$fp ) {
        assert($_ >= -$eps);
        assert($_ <= 1.0 + $eps);
    }

    my $sum = sum @$fp;
    assert(abs($sum - floor($sum + 0.5)) < $eps * (1 + $sum));

    1;
}

1;

__END__

=back

=head1 CAVEATS

=over 2

=item *

A number of in-situ integrity checks are enabled by setting
C<$ENV{MATH_ROUND_FAIR_DEBUG}> before loading C<Math::Round::Fair>.  These
integrity checks increase runtime by approximately one-third.  Set
C<$ENV{MATH_ROUND_FAIR_DEBUG}> to 1 to enable integrity checks, 2 for some
extra debug output, 0, or unset to disable the checks.  By default, the integrity
checks are disabled.

=item *

The algorithm that satisfies these constraints is not necessarily unique,
and the implementation may change over time.

=item *

Randomness is obtained via calls to rand().
You might want to call srand() first.
The number of invocations to rand() per call may change in subsequent versions.

=item *

The rounding of each element in the list is I<not> independent of the rounding
of the other elements.
This is the price that you pay for guaranteeing that the total is also fair
and accurate.

=back

=head1 AUTHORS

Marc Mims <marc@questright.com>, Anders Johnson <anders@ieee.org>

=head1 LICENSE

Copyright (c) 2009-2010 Marc Mims

This is free software.  You may use it, distributed it, and modify it under the
same terms as Perl itself.

=cut

PROOF THAT $tslack >= $p0 * (1 - $p0)

At the beginning of each iteration (i.e. initially and immediately before each
time the first element of @fp is removed), the sum of @fp must be an integer.
As a result, at least one of the following statements is true after each time
the first element of @fp is removed as $p0 but before the remaining elements
are adjusted:

(1) $_==0 || $_==1 for $p0 and for all @fp.
(2) sum { $_ <= 1-$p0 ? $_ : 0 } @fp >= 1-$p0. [That is, the remaining
    elements that would alone increase the fractional part must sum to at least
    enough to make the total integral.]
(3) sum { $_ >= 1-$p0 ? 1-$_ : 0 } @fp >= $p0. [That is, the complements of
    the remaining elements that would alone decrease the fractional part must
    sum to at least enough to make the total integral.]

To understand this, consider the following:
    If no element of @fp is neither 0 nor 1, then (1) must be true.
    If any element of @fp is 1-$p0, then both (2) and (3) must be true.

    OTHERWISE, consider the subset @fpf of @fp whose members are neither
    0 nor 1 (nor 1-$p0).
    Let @fpp = @fpf[0..$#fpf-1] and let $fpN = $fpf[-1].  It must be true
    that frac($p0 + (sum @fpp) + $fpN) == 0.

    For (2), consider:
    * $fpN == 1 - frac($p0 + sum @fpp).
    * If $fpN < 1-$p0 and (3) is false, then:
      * sum { $_ >= 1-$p0 ? 1-$_ : 0 } @fp < $p0  [converse of (3)]
      * sum { $_ >= 1-$p0 ? 1-$_ : 0 } @fp ==
        sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp +
          sum { $_ >= 1-$p0 && frac($_)==0 ? 1-$_ : 0 } @fp
      * sum { $_ >= 1-$p0 && frac($_)==0 ? 1-$_ : 0 } @fp == 0
      * sum { $_ >= 1-$p0 ? 1-$_ : 0 } @fp ==
        sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp
      * sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp < $p0
      * $fpN ==
        1 - frac($p0 + sum { $_ > 1-$p0 ? $_ : 0 } @fpp +
          sum { $_ < 1-$p0 ? $_ : 0 } @fpp) ==
        1 - frac($p0 - sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp +
          sum { $_ < 1-$p0 ? $_ : 0 } @fpp)
        [because frac(y + sum @x) = frac(y - sum { 1-$_ } @x), for all
         y >= sum { 1-$_ } @x and sum(@x) >= -y]
      * $fpN >=
        1 - ($p0 - sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp +
          sum { $_ < 1-$p0 ? $_ : 0 } @fpp)
        [because frac(x) <= x for all x >= 0, and recall that
         sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp < $p0]
      * 1 - ($p0 - sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp +
          sum { $_ < 1-$p0 ? $_ : 0 } @fpp) >=
        1 - ($p0 + sum { $_ < 1-$p0 ? $_ : 0 } @fpp)
        [because 1 - (x - y) >= 1 - x for all y >= 0]
      * Transitively, $fpN >= 1 - ($p0 + sum { $_ < 1-$p0 ? $_ : 0 } @fpp)
      * Therefore $fpN + sum { $_ < 1-$p0 ? $_ : 0 } @fpp >= 1-$p0,
        which is equivalent to (2), because:
        * sum { $_ <= 1-$p0 ? $_ : 0 } @fp ==
          $fpN + sum { $_ < 1-$p0 ? $_ : 0 } @fpp +
            sum { $_ < 1-$p0 && frac($_) == 0 ? $_ : 0 } @fp ==
          $fpN + sum { $_ < 1-$p0 ? $_ : 0 } @fpp.

    Similarly for (3), consider:
    * 1-$fpN == frac($p0 + sum @fpp) == 1 - frac(1-$p0 + sum { 1-$_ } @fpp)
    * If $fpN > 1-$p0 and (2) is false, then:
      * sum { $_ <= 1-$p0 ? $_ : 0 } @fp < 1-$p0
      * sum { $_ <= 1-$p0 ? $_ : 0 } @fp ==
        sum { $_ < 1-$p0 ? $_ : 0 } @fpp +
          sum { $_ <= 1-$p0 && frac($_)==0 ? $_ : 0 } @fp ==
        sum { $_ < 1-$p0 ? $_ : 0 } @fpp < 1-$p0
      * 1-$fpN ==
        1 - frac(1-$p0 + sum { $_ < 1-$p0 ? 1-$_ : 0 } @fpp +
          sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp) ==
        1 - frac(1-$p0 - sum { $_ < 1-$p0 ? $_ : 0 } @fpp +
          sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp)
      * 1-$fpN >= 1 - (1-$p0 + sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp)
      * Therefore 1-$fpN + sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp >= $p0,
        which is equivalent to (3), because:
        * sum { $_ >= 1-$p0 ? 1-$_ : 0 } @fp ==
          1-$fpN + sum { $_ > 1-$p0 ? 1-$_ : 0 } @fpp

[More intuitively, think of a clock where the hour hand represents the
fractional part, 12 o'clock being zero and 6 o'clock being one half.
If $p0 is 0.25, then you start at 3 o'clock.  You can group the remaining
@fp's into the ones that are > 0.75 (call them the "counter-clockwise" ones)
and the ones that are < 0.75 (call them the "clockwise" ones).
If you can't get to noon or beyond clockwise by summing the ones <= 0.75, then
it's not going to help to include any of the ones > 0.75, because each one of
them would increase the remaining angle to get to noon clockwise.  In that
case, it is still possible that you can get to noon or beyond counter-clockwise
by summing the ones >= 0.75, but, similarly, if you can't then it's not going
to help to include any of the ones < 0.75.  Since it is a pre-condition that
the full sum winds up exactly at noon, in particular it must be true that
there exists a (possibly improper) subset whose sum gets you to noon or beyond
in one direction or the other.]

Note that $tslack == sum { $_ <= 1-$p0 ? $p0*$_ : (1-$p0)*(1-$_) } @fp ==
  $p0 * sum { $_ <= 1-$p0 ? $_ : 0 } @fp +
  (1-$p0) * sum { $_ > 1-$p0 ? 1-$_ : 0 } @fp ==
  $p0 * sum { $_ < 1-$p0 ? $_ : 0 } @fp +
  (1-$p0) * sum { $_ >= 1-$p0 ? 1-$_ : 0 } @fp.

Because $_ >= 0 and (1-$_) >= 0 for $p0 and for all @fp, we have
  $p0 * sum { $_ < 1-$p0 ? $_ : 0 } @fp >= 0 and
  (1-$p0) * sum { $_ > 1-$p0 ? 1-$_ : 0 } @fp >= 0; therefore
  $tslack >= $p0 * sum { $_ <= 1-$p0 ? $_ : 0 } @fp, and
  $tslack >= (1-$p0) * sum { $_ >= 1-$p0 ? 1-$_ : 0 } @fp.

If (1) is true, then $tslack == $p0 * (1 - $p0) == 0; therefore
$tslack >= $p0 * (1 - $p0).

If (2) is true, then $p0 * sum { $_ <= 1-$p0 ? $_ : 0 } @fp >= $p0 * (1-$p0);
therefore, by transitivity, $tslack >= $p0 * (1 - $p0).

If (3) is true, then (1-$p0) * sum { $_ >= 1-$p0 ? 1-$_ : 0 } @fp >=
(1-$p0) * $p0; therefore, by transitivity, $tslack >= $p0 * (1 - $p0).

q.e.d.

