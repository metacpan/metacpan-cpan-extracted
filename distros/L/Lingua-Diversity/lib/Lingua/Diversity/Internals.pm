#!/usr/bin/perl

package Lingua::Diversity::Internals;

use strict;
use warnings;
use Carp;

use Exporter   ();

our $VERSION     = 0.04;

our @ISA         = qw( Exporter );
our %EXPORT_TAGS = (
    'all' => [ qw(
        _get_average
        _sample_indices
        _count_types
        _count_frequency
        _get_units_per_category
        _shannon_entropy
        _perplexity
        _renyi_entropy
    ) ],
);
Exporter::export_ok_tags( 'all' );

use Lingua::Diversity::X;


#=============================================================================
# Subroutines
#=============================================================================

#-----------------------------------------------------------------------------
# Subroutine _get_average
#-----------------------------------------------------------------------------
# Synopsis:      Computes the (possible weighted) average and variance of
#                an array of numbers.
# Arguments:     - A reference to a non-empty array.
#                - An optional reference to an array of weights of same size.
# Return values: - The (possibly weighted) average.
#                - The (possibly weighted) variance.
#                - The number of observations.
#-----------------------------------------------------------------------------

sub _get_average {
    my ( $number_array_ref, $weight_array_ref ) = @_;

    # Get number of items in array.
    my $number_of_items = @$number_array_ref;

    # Number array must not be empty...
    Lingua::Diversity::X::Internals::GetAverageEmptyArray->throw()
        if $number_of_items == 0;

    # Special case if number of items = 1...
    if ( $number_of_items == 1 ) {
        my $count = defined $weight_array_ref ?
                    $weight_array_ref->[0]    :
                    1                         ;
        return ( $number_array_ref->[0], 0, $count )
    }
    
    # Weight array must have the same size as number array (if provided)...
    if (
           defined $weight_array_ref
        && @$weight_array_ref != $number_of_items
    ) {
     Lingua::Diversity::X::Internals::GetAverageArraysOfDifferentSize->throw()
    }

    # Set the default, uniform weight if no weights were provided.
    my $uniform_weight = ( defined $weight_array_ref ? undef : 1 );

    my $sum_of_weights          = 0;
    my $weighted_sum            = 0;
    my $weighted_sum_squares    = 0;

    NUMBER_INDEX:
    foreach my $index ( 0..@$number_array_ref-1 ) {
        my $number = $number_array_ref->[$index];
        my $weight = ( $uniform_weight ? 1 : $weight_array_ref->[$index] );
        $sum_of_weights         += $weight;
        $weighted_sum           += $weight * $number;
        $weighted_sum_squares   += $weight * $number * $number;
    }

    # Compute average and variance...
    my $average  = $weighted_sum / $sum_of_weights;
    my $variance = $weighted_sum_squares / $sum_of_weights
                 - $average * $average
                 ;

    # Fix negative variances (precision error).
    $variance = $variance < 0 ? 0 : $variance;
    
    return $average, $variance, $sum_of_weights;
}


#-----------------------------------------------------------------------------
# Method _sample_indices
#-----------------------------------------------------------------------------
# Synopsis:      Returns a reference to a list of random array indices.
# Arguments:     - The size of the array.
#                - The number of indices to be picked.
# Return values: - A reference to an array of indices.
#-----------------------------------------------------------------------------

sub _sample_indices {
    my ( $population_size, $sample_size ) = @_;

    Lingua::Diversity::X::Internals::SampleIndicesSampleSizeTooLarge->throw()
        if $sample_size > $population_size;

    my @sampled_indices;

    INDICES:
    foreach my $num_processed_items ( 0..$population_size-1 ) {

        # If current index is sampled...
        if (
            rand() <        ( $sample_size     - @sampled_indices      )
                      * 1 / ( $population_size - $num_processed_items  )
        ) {

            # Add it to array.
            push @sampled_indices, $num_processed_items;

            # Exit loop if sample is complete.
            last INDICES if @sampled_indices == $sample_size;
        }
    }

    return \@sampled_indices;
}


#-----------------------------------------------------------------------------
# Subroutine _count_frequency
#-----------------------------------------------------------------------------
# Synopsis:      Count the frequency of each item type in an array.
# Arguments:     - A reference to an array of units.
# Return values: - A reference to a frequency hash.
#-----------------------------------------------------------------------------

sub _count_frequency {
    my ( $unit_array_ref, $category_array_ref ) = @_;
    my %frequency;
    foreach ( @$unit_array_ref ) { $frequency{$_}++; }
    return \%frequency;
}


#-----------------------------------------------------------------------------
# Subroutine _get_units_per_category
#-----------------------------------------------------------------------------
# Synopsis:      Build a hash whose keys are categories and whose values are
#                references to corresponding lists of units.
# Arguments:     - A reference to an array of units.
#                - A reference to an array of categories.
# Return values: - A reference to a hash.
#-----------------------------------------------------------------------------

sub _get_units_per_category {
    my ( $unit_array_ref, $category_array_ref ) = @_;

    my %units_in_category;

    foreach my $index ( 0..@$unit_array_ref-1 ) {
        push    @{ $units_in_category{$category_array_ref->[$index]} },
                $unit_array_ref->[$index];
    }
    return \%units_in_category;
}


#-----------------------------------------------------------------------------
# Subroutine _count_types
#-----------------------------------------------------------------------------
# Synopsis:      Count the number of distinct items in an array.
# Arguments:     - A reference to an array.
# Return values: - The number of distinct items.
#-----------------------------------------------------------------------------

sub _count_types {
    my ( $array_ref ) = @_;
    my %frequency;
    foreach ( @$array_ref ) { $frequency{$_} = 1; }
    return scalar keys %frequency;
}


#-----------------------------------------------------------------------------
# Subroutine _shannon_entropy
#-----------------------------------------------------------------------------
# Synopsis:         Compute Shannon's entropy.
# Arguments:        - A reference to an array.
#                   - The log base (default is exp(1)).
# Valeur de retour: - The entropy in the requested base.
#-----------------------------------------------------------------------------

sub _shannon_entropy {
    my ( $array_ref, $base ) = @_;

    # Default base is exp(1).
    $base ||= exp(1);

    # Count frequency.
    my $frequency_ref = _count_frequency( $array_ref );

    my( $sum, $weighted_sum_of_logs);

    FREQUENCY:
    foreach my $frequency ( values %$frequency_ref ) {

        # Skip zero frequencies.
        next if $frequency == 0;

        # Increment sums...
        $sum                  += $frequency;
        $weighted_sum_of_logs += $frequency * log $frequency;
    }

    # Compute entropy.
    my $entropy = log( $sum )
                - $weighted_sum_of_logs / $sum;

    return $entropy / log $base;
}


#-----------------------------------------------------------------------------
# Subroutine _perplexity
#-----------------------------------------------------------------------------
# Synopsis:         Compute perplexity.
# Arguments:        - A reference to an array.
# Valeur de retour: - The perplexity.
#-----------------------------------------------------------------------------

sub _perplexity {
    my ( $array_ref ) = @_;
    return exp _shannon_entropy( $array_ref );
}


#-----------------------------------------------------------------------------
# Subroutine _renyi_entropy
#-----------------------------------------------------------------------------
# Synopsis:         Compute Renyi's entropy.
# Arguments:        - 'array_ref' => a reference to an array.
#                   - 'exponent'  => a number between 0 and 1 inclusive
#                                    (default is 0.5).
#                   - 'base'      => the log base (default is exp(1)).
# Valeur de retour: - The Renyi's entropy in the requested base.
#-----------------------------------------------------------------------------

sub _renyi_entropy {
    my ( %parameter ) = @_;

    # Default base is exp(1).
    $parameter{'base'} ||= exp(1);

    # Default exponent is 0.5..
    my $exponent = defined $parameter{'exponent'} ?
                   $parameter{'exponent'}         :
                   0.5                            ;

    # Check exponent...
    Lingua::Diversity::X::Internals::RenyiEntropyInvalidExponent->throw()
        if $exponent < 0 || $exponent > 1;

    # Fallback on log number of types if needed...
    return (log(_count_types($parameter{'array_ref'}))/log $parameter{'base'})
        if $exponent == 0;

    # Fallback on Shannon's entropy if needed...
    return _shannon_entropy( $parameter{'array_ref'}, $parameter{'base'} )
        if $exponent == 1;

    # Count frequency.
    my $frequency_ref = _count_frequency( $parameter{'array_ref'} );

    my( $sum, $sum_to_the_exponent_th );

    FREQUENCY:
    foreach my $frequency ( values %$frequency_ref ) {

        # Skip zero frequencies.
        next if $frequency == 0;

        # Increment sums...
        $sum                    += $frequency;
        $sum_to_the_exponent_th += $frequency**$exponent;
    }

    # Compute entropy.
    my $entropy = 1 / ( 1-$exponent )
                * log (
                        ( 1/$sum )**$exponent
                      * $sum_to_the_exponent_th
                  );

    return $entropy / log $parameter{'base'};
}


1;


__END__


=head1 NAME

Lingua::Diversity::Internals - utility subroutines for classes derived from
Lingua::Diversity

=head1 VERSION

This documentation refers to Lingua::Diversity::Internals version 0.03.

=head1 SYNOPSIS

    use Lingua::Diversity::Internals qw( :all );
    
    # NB: the following subroutine calls are meant to illustrate the various
    #     possibilities of this module -- the order in which they appear here
    #     is not meaningful. Furthermore, it is assumed here that a number of
    #     variables ($array_ref, $unit_array_ref, etc.) have been defined.

    # Get a random subsample of 20 items taken from an array...
    my $sampled_indices_ref = _sample_indices(
        scalar( @original_array ),
        20,
    )
    my @subsample = @original_array[@$sampled_indices_ref];

    # Get the average, variance and count of a list of numbers...
    my ( $average, $variance, $count ) = _get_average( \@numbers );

    # Get the weighted average, variance and count of a list of numbers...
    my( $average, $variance, $count ) = _get_average( \@numbers, \@weights );

    # Get the number of types (distinct items) in an array...
    my $number_of_types = _count_types( $array_ref );

    # Get the frequency of types in an array...
    my $freq_hash_ref = _count_frequency( $array_ref );
    foreach my $item ( sort keys %$freq_hash_ref ) {
        print $item, "\t", $freq_hash_ref->{$item}, "\n";
    }

    # Get the list of unit types associated to each category type...
    my $units_in_category_hash_ref = _get_units_per_category(
        $unit_array_ref,
        $category_array_ref,
    );
    foreach my $category ( sort keys %$units_in_category_hash_ref ) {
        print $category, "\t",
              join( q{,}, $units_in_category_hash_ref->{$category} ), "\n";
    }

    # Get the perplexity of items in an array...
    my $perplexity = _perplexity( $array_ref );

    # Get the shannon entropy of items in an array...
    my $shannon_entropy = _shannon_entropy( $array_ref );

    # Get the Renyi entropy of items in an array...
    my $renyi_entropy = _renyi_entropy(
        'array_ref' => $array_ref,
        'exponent'  => 0.7,
    );


=head1 DESCRIPTION

This module provides utility subroutines that are or could be used by various
classes derived from L<Lingua::Diversity>. These subroutines are marked as
internal (i.e. their name starts with an underscore) because
they are meant to be used by developers creating classes derived from
L<Lingua::Diversity> (as opposed to being used by clients of such classes).

No subroutine is exported by default. All subroutines are exportable, and tag
':all' results in the export of all subroutines.

=head1 SUBROUTINES

=over 4

=item _sample_indices()

Return a reference to an array of random array indices. The subroutine takes
two arguments, namely the size of the array (i.e. 1 plus the maximum possible
index) and the number of indices to be sampled. An exception is thrown if the
latter exceeds the former.

=item _get_average()

Compute the (possibly weighted) average and variance of a list of numbers.
Return the average, variance, and count (number of observations).

The subroutine requires a reference to an array of numbers as argument.
Passing an empty array throws an exception.

Optionally, a reference to an array of counts may be passed as a second
argument. An exception is thrown if this array's size does not match the first
one. Counts may be real instead of integers, in which case the number of
observations returned may not be an integer. In all cases, reported results
are weighted according to the counts.

=item _count_types()

Count the number of distinct items in an array. Takes an array reference as
argument.

=item _count_frequency()

Count the number of occurrences of each distinct item in an array. Takes an
array reference as argument. The result is a reference to a hash where each
key correspond to a distinct item and each value to the number of occurrences
of this item in the array.

=item _get_units_per_category()

Take a reference to an array of units and an array of categories, and build a
hash where each key is a category and the corresponding value is a reference
to the list of units that are associated with this category.

NB: It is assumed that two non-empty arrays of identical size are passed in
argument.

=item _perplexity()

Compute the perplexity of items in an array, i.e. the exponential of the
Shannon entropy of items in base e (see below). Takes a reference to an
array as argument.

=item _shannon_entropy()

Compute the Shannon entropy of items in an array. Takes a reference to an
array as first argument, and optionally the requested log base for the
computation (default is e, i.e. exp(1)).

NB: It is assumed that a non-empty array is passed in argument.

=item _renyi_entropy()

Compute the Renyi entropy of items in an array. Takes one required and two
optional named parameters:

=over 4

=item array_ref

A reference to a non-empty array.

=item exponent

The numeric parameter involved in the computation of Renyi's entropy (a number
between 0 and 1 inclusive). Note that 0 amounts to computing the log of the
number of types, and 1 amounts to computing Shannon's entropy. Default is 0.5.

=item base

A positive number to be used as the log base in the computation. Default is
I<e> (i.e. exp(1)).

=back

=back

=head1 DIAGNOSTICS

=over 4

=item The second argument of subroutine sampled_indices() cannot be larger
than the first

This exception is raised when the second argument of subroutine
C<sampled_indices()> is larger than the first, i.e. when the requested sample
size exceeds the array size.

=item Parameter 'exponent' of subroutine _renyi_entropy() must be between 0
and 1 inclusive

This exception is raised when the parameter I<exponent> of subroutine
C<_renyi_entropy()> is set to a value lesser than 0 or greater than 1.

=back

=head1 DEPENDENCIES

This module is part of the L<Lingua::Diversity> distribution.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Aris Xanthos (aris.xanthos@unil.ch)

Patches are welcome.

=head1 AUTHOR

Aris Xanthos  (aris.xanthos@unil.ch)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011 Aris Xanthos (aris.xanthos@unil.ch).

This program is released under the GPL license (see
L<http://www.gnu.org/licenses/gpl.html>).

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

L<Lingua::Diversity>

