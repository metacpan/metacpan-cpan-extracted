package Math::Random::Discrete;
$Math::Random::Discrete::VERSION = '1.02';
use strict;
use warnings;

use Carp qw(croak);

# ABSTRACT: Discrete random variables with general distributions

# This is an implementation of Walker's alias method.

sub new {
    my ($class, $_weights, $values) = @_;

    croak("No weights specified")
        if !defined($_weights) || !@$_weights;
    croak("Number of values must equal number of weights")
        if defined($values) && @$values != @$_weights;

    my @weights = @$_weights;

    # compute average weight

    my $N   = @weights;
    my $sum = 0;

    for my $weight (@weights) {
        $sum += $weight;
    }

    my $avg = $sum / $N;

    # split weights into two groups: smaller and larger than average

    my (@small, @large);

    for (my $i = 0; $i < $N; ++$i) {
        if ($weights[$i] <= $avg) {
            push(@small, $i);
        }
        else {
            push(@large, $i);
        }
    }

    # generate F and A arrays

    my (@F, @A);

    while (@small and @large) {
        my $i  = pop(@small);
        my $j  = $large[-1];
        $A[$i] = $j;
        $F[$i] = $weights[$i] / $avg;

        $weights[$j] -= $avg - $weights[$i];

        push(@small, pop(@large))
            if $weights[$j] <= $avg;
    }

    for my $i (@small, @large) {
        $A[$i] = $i;
        $F[$i] = 1.0;
    }

    # create blessed ref

    my $self = {
        values => $values,
        A      => \@A,
        F      => \@F,
    };

    return bless($self, $class);
}

sub rand {
    my $self = shift;

    my $F  = $self->{F};
    my $r  = CORE::rand(@$F);
    my $ri = int($r);  # integer part
    my $rf = $r - $ri; # fractional part

    my $i = $rf < $F->[$ri] ? $ri : $self->{A}[$ri];

    my $values = $self->{values};

    return $values ? $values->[$i] : $i;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Random::Discrete - Discrete random variables with general distributions

=head1 VERSION

version 1.02

=head1 SYNOPSIS

    use Math::Random::Discrete;

    my $fruit = Math::Random::Discrete->new(
        [ 40, 20, 10 ],
        [ 'Apple', 'Orange', 'Banana' ],
    );

    print $fruit->rand, "\n";

=head1 DESCRIPTION

Math::Random::Discrete generates discrete random variables according to a
user-defined distribution. It uses Walker's alias method to create random
values in O(1) time.

=head1 METHODS

=head2 new

    my $generator = Math::Random::Discrete->new(\@weights, \@items);

Creates a random generator for the distribution given by values in @weights.
These values can be probabilities, frequencies or any kind of weights. They
don't have to add up to 1. @items is an array of items corresponding to the
weights. If it is omitted, numbers 0, 1, 2, ... are used.

=head2 rand

    my $item = $generator->rand;

Returns a random item according to the given distribution. That is, item i
is returned with probability

    p[i] = weight[i] / sum_of_all_weights

=head1 AUTHOR

Nick Wellnhofer <wellnhofer@aevum.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nick Wellnhofer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
