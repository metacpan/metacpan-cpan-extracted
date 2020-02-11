# -*- coding: utf-8-unix

package Math::Summation;

use strict;
use warnings;

use Carp qw< croak >;
use Exporter;

our $VERSION = '0.02';

our @ISA = qw< Exporter >;
our @EXPORT = ();
our @EXPORT_OK = qw< sum kahansum neumaiersum kleinsum pairwisesum >;
our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK, );

=pod

=encoding UTF-8

=head1 NAME

Math::Summation - add numbers in ways that give less numerical errors

=head1 SYNOPSIS

    use Math::Summation 'sum';  # and/or 'kahansum' etc.

    my @values = (1, 1e100, 1, -1e100);

    # use the standard way of adding numbers
    my $sum = sum(@values);

    # use the Kahan summation algorithm
    my $sum_khn = kahansum(@values);

    # use the Neumaier summation algorithm
    my $sum_nmr = neumaiersum(@values);

    # use the Klein summation algorithm
    my $sum_kln = kleinsum(@values);

    # use the pairwise summation algorithm
    my $sum_pws = pairwisesum(@values);

=head1 DESCRIPTION

This module implements various algorithms that significantly reduces the
numerical error in the total obtained by adding a sequence of finite-precision
floating-point numbers, compared to the obvious approach.

No functions are exported by default. The desired functions can be imported
like in the following example:

    use Math::Summation 'sum';      # and/or 'kahansum' etc.

To import all exportable functions, use the 'all' tag:

    use Math::Summation ':all';     # import all fucntions

=head1 FUNCTIONS

=over 4

=item sum LIST

Returns the sum of the elements in LIST. This is done by naively adding each
number directly to the accumulating total.

    # use the standard way of adding numbers
    my $sum = sum(@values);

=cut

sub sum {

    # Prepare the accumulator.
    my $sum = 0.0;

    for (my $i = 0 ; $i <= $#_ ; ++$i) {
        $sum += $_[$i];
    }

    return $sum;
}

=pod

=item kahansum LIST

Returns the sum of the elements in LIST.

    # use the Kahan summation algorithm
    my $sum_khn = kahansum(@values);

The Kahan summation algorithm, also known as "compensated summation",
significantly reduces the numerical error in the total obtained by adding a
sequence of finite-precision floating-point numbers, compared to the obvious
approach. This is done by keeping a separate running compensation (a variable
to accumulate small errors).

This function is more accurate than a direct summation, but at the expence of
more computational complexity.

=cut

sub kahansum {

    # Prepare the accumulator.
    my $sum = 0.0;

    # A running compensation for lost low-order bits.
    my $c = 0.0;

    for (my $i = 0 ; $i <= $#_ ; ++$i) {

        # $c is zero the first time around.
        my $y = $_[$i] - $c;

        # Alas, $sum is big, $y small, so low-order digits of $y are lost.
        my $t = $sum + $y;

        # ($t - $sum) cancels the high-order part of $y; subtracting y recovers
        # negative (low part of $y)
        $c = ($t - $sum) - $y;

        # Algebraically, $c should always be zero. Beware overly-aggressive
        # optimizing compilers!
        $sum = $t;

        # Next time around, the lost low part will be added to $y in a fresh
        # attempt.
    }

    return $sum;
}

=pod

=item neumaiersum LIST

Returns the sum of the elements in LIST.

    # use the Neumaier summation algorithm
    my $sum_nmr = neumaiersum(@values);

Neumaier introduced an improved version of the Kahan algorithm, which Neumaier
calls an "improved Kahan–Babuška algorithm", which also covers the case when
the next term to be added is larger in absolute value than the running sum,
effectively swapping the role of what is large and what is small.

The difference between Neumaier's algorithm and Kahan's algorithm can be seen
when summing the four numbers (1, 1e100, 1, -1e100) with double or quad
precision. Kahan's algorithm gives 0, but Neumeier's algorithm gives 2, which
is the correct result.

=cut

sub neumaiersum {
    my $sum = 0.0;

    # A running compensation for lost low-order bits.
    my $c = 0.0;

    for (my $i = 0 ; $i <= $#_ ; ++$i) {
        my $t = $sum + $_[$i];
        if (abs($sum) >= abs($_[$i])) {
            # If $sum is bigger, low-order digits of $_[$i] are lost.
            $c += ($sum - $t) + $_[$i];
        } else {
            # Else low-order digits of $sum are lost.
            $c += ($_[$i] - $t) + $sum;
        }
        $sum = $t;
    }

    # Correction only applied once in the very end.
    return $sum + $c;
}

=pod

=item kleinsum LIST

Returns the sum of the elements in LIST.

    # use the Klein summation algorithm
    my $sum_kln = kleinsum(@values);

Higher-order modifications of the above algorithms, to provide even better
accuracy are also possible. Klein suggested what he called a second-order
"iterative Kahan–Babuška algorithm".

This method has some advantages over Kahan's and Neumaier's algorithms, but at
the expense of even more computational complexity.

=cut

sub kleinsum {
    my $s = 0.0;
    my $cs = 0.0;
    my $ccs = 0.0;
    for (my $i = 0 ; $i <= $#_ ; ++$i) {
        my ($c, $cc);
        my $t = $s + $_[$i];
        if (abs($s) >= abs($_[$i])) {
            $c = ($s - $t) + $_[$i];
        } else {
            $c = ($_[$i] - $t) + $s;
        }
        $s = $t;
        $t = $cs + $c;
        if (abs($cs) >= abs($c)) {
            $cc = ($cs - $t) + $c;
        } else {
            $cc = ($c - $t) + $cs;
        }
        $cs = $t;
        $ccs = $ccs + $cc;
    }

    return $s + $cs + $ccs;
}

=pod

=item pairwisesum LIST

Returns the sum of the elements in LIST.

    # use the pairwise summation algorithm
    my $sum_pws = pairwisesum(@values);

The summation is done by recursively splitting the set in half and computing
the sum of each half.

This algorithm has the same number of arithmetic operations as a direct
summation, but the recursion introduces some overhead.

=cut

sub pairwisesum {
    if (@_ > 2) {
        my $i = int($#_ / 2);
        return pairwisesum(@_[0 .. $i]) + pairwisesum(@_[$i+1 .. $#_]);
    }

    return $_[0] + $_[1] if @_ == 2;
    return $_[0]         if @_ == 1;
    return 0             if @_ == 0;
}

=pod

=back

=head1 BUGS

Please report any bugs through the web interface at
L<https://rt.cpan.org/Ticket/Create.html?Queue=Math-Summation>
(requires login). We will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Summation

You can also look for information at:

=over 4

=item * GitHub Source Repository

L<https://github.com/pjacklam/p5-Math-Summation>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Math-Summation>

=item * CPAN Ratings

L<https://cpanratings.perl.org/dist/Math-Summation>

=item * MetaCPAN

L<https://metacpan.org/release/Math-Summation>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Math-Summation>

=back

=head1 SEE ALSO

=over

=item *

The Wikipedia page for Kahan summation, which describes the algorithms by
Kahan, Neumaier, and Klein
L<https://en.wikipedia.org/wiki/Kahan_summation_algorithm>.

=item *

The Wikipedia page for pairwise summation
L<https://en.wikipedia.org/wiki/Pairwise_summation>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2020 Peter John Acklam.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Peter John Acklam E<lt>pjacklam (at) gmail.comE<gt>.

=cut

1;
