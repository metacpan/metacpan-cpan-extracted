package Lingua::Diversity::Variety;

use Moose;

our $VERSION = '0.03';

extends 'Lingua::Diversity';

use Lingua::Diversity::Result;
use Lingua::Diversity::SamplingScheme;
use Lingua::Diversity::Internals qw( :all );



#=============================================================================
# Class variables.
#=============================================================================

# Define transforms. 1st arg of each sub = variety, 2nd arg = num. tokens...
our %builtin_transform = (
    'none'                  => sub { $_[0] },
    'type_token_ratio'      => sub { $_[0] / $_[1] },
    'mean_frequency'        => sub { $_[1] / $_[0] },
    'guiraud'               => sub { $_[0] / sqrt($_[1]) },
    'herdan'                => sub { log($_[0]) / log($_[1]) },
    'rubet'                 => sub { log($_[0]) / log(log($_[1])) },
    'maas'                  => sub {
                                          ( log($_[1]) - log($_[0]) )
                                    * 1 / ( log($_[1]) * log($_[1]) )
                               },
    'dugast'                => sub {
                                          ( log($_[1]) * log($_[1]) )
                                    * 1 / ( log($_[1]) - log($_[0]) )
                               },
    'lukjanenkov_nesitoj'   => sub {
                                          ( 1 - ( $_[0] * $_[0] ) )
                                    * 1 / ( $_[0] * $_[0] * log($_[1]) )
                               },
);


#=============================================================================
# Attributes.
#=============================================================================

has 'transform' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::VarietyTransform | CodeRef',
    reader      => 'get_transform',
    writer      => 'set_transform',
    default     => 'none',
);

has 'unit_weighting' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::BetweenZeroAndOneIncl',
    reader      => 'get_unit_weighting',
    writer      => 'set_unit_weighting',
    default     => 0,
);

has 'category_weighting' => (
    is          => 'rw',
    isa         => 'Bool',
    reader      => 'get_category_weighting',
    writer      => 'set_category_weighting',
    default     => 0,
);

has 'sampling_scheme' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::SamplingScheme',
    reader      => 'get_sampling_scheme',
    writer      => 'set_sampling_scheme',
    predicate   => 'has_sampling_scheme',
    clearer     => 'clear_sampling_scheme',
);


#=============================================================================
# Private instance methods.
#=============================================================================

#-----------------------------------------------------------------------------
# Method _measure
#-----------------------------------------------------------------------------
# Synopsis:      Compute variety, possibly per category.
# Arguments:     - A reference to an array of (recoded) units.
#                - An optional reference to an array of categories.
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub _measure {
    my ( $self, $recoded_unit_array_ref, $category_array_ref ) = @_;

    # If resampling is requested...
    if ( $self->has_sampling_scheme() ) {

        # Validate argument array wrt subsample size...
        my $min_num_items= $self->get_sampling_scheme()->get_subsample_size();
        my $num_items    = @$recoded_unit_array_ref;
        if ( $num_items < $min_num_items ) {
            Lingua::Diversity::X::ValidateSizeArrayTooSmall->throw(
                'method'        => ( caller(1) )[3],
                'num_items'     => $num_items,
                'min_num_items' => $min_num_items,
            );
        }

        # Compute and return the average variety per subsample (per cat.)...
        return $self->_compute_variety_average(
            $recoded_unit_array_ref,
            $category_array_ref,
        );
    }

    # Else if no resampling is requested...
    else {

        # Compute variety (per category)...
        my $variety = $self->_compute_variety(
            $recoded_unit_array_ref,
            $category_array_ref,
        );

        # Get and apply transform...
        my $transform;
        if ( ref( $self->get_transform() ) eq 'CODE' ) {
            $transform = $self->get_transform();
        }
        else {
            $transform = $builtin_transform{ $self->get_transform() };
        }
        $variety = $transform->( $variety, scalar @$recoded_unit_array_ref );

        # Create, fill, and return a new Result object...
        return Lingua::Diversity::Result->new(
            'diversity' => $variety,
        );
    }
}


#-----------------------------------------------------------------------------
# Method _compute_variety_average
#-----------------------------------------------------------------------------
# Synopsis:      Resample an array, compute the variety of each subsample
#                (possibly per category), compute the average, variance and
#                count, and return them in a Lingua::Diversity::Result object.
#                Also, transform variety after or before averaging if needed.
# Arguments:     - A reference to a validated array of (recoded) units.
#                - An optional reference to a validated array of categories.
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub _compute_variety_average {
    my ( $self, $unit_array_ref, $category_array_ref ) = @_;

    # Get the transform...
    my $transform;
    if ( ref( $self->get_transform() ) eq 'CODE' ) {
        $transform = $self->get_transform();
    }
    else {
        $transform = $builtin_transform{ $self->get_transform() };
    }

    # Get the sampling scheme...
    my $scheme = $self->get_sampling_scheme();

    my ( @varieties, @unit_subsample, @category_subsample );

    # If resampling mode is 'random'...
    if ( $scheme->get_mode() eq 'random' ) {

        SUBSAMPLE:
        foreach ( 1..$scheme->get_num_subsamples() ) {

            # Get unit subsample...
            my $sampled_indices_ref = _sample_indices(
                scalar( @$unit_array_ref ),
                $scheme->get_subsample_size(),
            );
            @unit_subsample = @$unit_array_ref[@$sampled_indices_ref];

            # If category array was provided...
            if ( defined $category_array_ref ) {

                # Get category subsample...
                @category_subsample
                    = @$category_array_ref[@$sampled_indices_ref];

                # Compute and store variety...
                push @varieties, $self->_compute_variety(
                    \@unit_subsample,
                    \@category_subsample,
                );
            }

            # Else if no category array was provided...
            else {

                # Compute and store variety...
                push @varieties, $self->_compute_variety( \@unit_subsample );
            }
        }
    }

    # Else if resampling mode is 'segmental'...
    else {

        my $start_pos = 0;

        SEGMENT:
        while (
            $start_pos + $scheme->get_subsample_size() <= @$unit_array_ref
        ){

            # Compute end position of segment...
            my $end_pos = $start_pos + $scheme->get_subsample_size() - 1;

            # Get unit subsample...
            @unit_subsample = @$unit_array_ref[$start_pos..$end_pos];

            # If category array was provided...
            if ( defined $category_array_ref ) {

                # Get category subsample...
                @category_subsample
                    = @$category_array_ref[$start_pos..$end_pos];

                # Compute and store variety...
                push @varieties, $self->_compute_variety(
                    \@unit_subsample,
                    \@category_subsample,
                );
            }

            # Else if no category array was provided...
            else {

                # Compute and store variety...
                push @varieties, $self->_compute_variety( \@unit_subsample );
            }

            # Increment start position...
            $start_pos += $scheme->get_subsample_size();
        }
    }

    # Transform if requested...
    if ( $self->get_transform() ne 'none' ) {
        @varieties = map {
            $transform->( $_, $scheme->get_subsample_size() )
        } @varieties;
    }

    # Get average and variance of variety.
    my ( $average, $variance, $count ) = _get_average( \@varieties );

    # Create, fill, and return a new Result object...
    return Lingua::Diversity::Result->new(
        'diversity' => $average,
        'variance'  => $variance,
        'count'     => $count,
    );
}


#-----------------------------------------------------------------------------
# Method _compute_variety
#-----------------------------------------------------------------------------
# Synopsis:      Compute the variety of an array of units, possibly per
#                category.
# Arguments:     - A reference to a validated array of (recoded) units.
#                - An optional reference to a validated array of categories.
# Return values: - The variety of units (possibly per category).
#-----------------------------------------------------------------------------

sub _compute_variety {
    my ( $self, $unit_array_ref, $category_array_ref ) = @_;

    my $variety;

    # If no category array was provided...
    if ( ! defined $category_array_ref ) {

        # Compute variety...
        if ( $self->get_unit_weighting() == 0 ) {
            $variety = _count_types( $unit_array_ref );
        }
        elsif ( $self->get_unit_weighting() == 1 ) {
            $variety = _perplexity( $unit_array_ref );
        }
        else {
            $variety = exp _renyi_entropy(
                'array_ref' => $unit_array_ref,
                'exponent'  => $self->get_unit_weighting(),
            );
        }
    }

    # Else if a category array was provided...
    else {

        # Special case: plain unweighted variety (per category)...
        if (
               $self->get_unit_weighting()      == 0
            && $self->get_category_weighting()  == 0
        ) {
            $variety =     _count_types( $unit_array_ref )
                     * 1 / _count_types( $category_array_ref );
        }
        # All other cases rely on frequency of units per category...
        else {

            # Get lists of recoded units per category...
            my $units_in_category_ref = _get_units_per_category(
                $unit_array_ref,
                $category_array_ref
            );

            my ( $unit_freq_ref, $category_freq_ref );

            # Count frequency of categories...
            $category_freq_ref = _count_frequency( $category_array_ref );

            # Count frequency of recoded units if needed...
            if ( $self->get_unit_weighting() == 1 ) {
                $unit_freq_ref = _count_frequency( $unit_array_ref );
            }

            my ( @varieties, @weights );

            CATEGORY:
            foreach my $category ( keys %$category_freq_ref ) {

                # Compute category weight if needed...
                if ( $self->get_category_weighting() == 1 ) {
                    push @weights, $category_freq_ref->{$category};
                }

                # compute local variety (for this category)...
                my $local_variety;
                if ( $self->get_unit_weighting() == 0 ) {
                    $local_variety = _count_types(
                        $units_in_category_ref->{$category}
                    );
                }
                elsif ( $self->get_unit_weighting() == 1 ) {
                    $local_variety = _perplexity(
                        $units_in_category_ref->{$category}
                    );
                }
                else {
                    $local_variety = exp _renyi_entropy(
                        'array_ref' => $units_in_category_ref->{$category},
                        'exponent'  => $self->get_unit_weighting(),
                    );
                }
                push @varieties, $local_variety;
            }

            # Compute average variety per category...
            if ( $self->get_category_weighting() == 1 ) {
                ( $variety ) = _get_average(
                     \@varieties,
                     \@weights
                );
            }
            else {
                ( $variety ) = _get_average( \@varieties );
            }
        }
    }

    return $variety;
}



#=============================================================================
# Standard Moose cleanup.
#=============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::Diversity::Variety - measuring the variety of text units

=head1 VERSION

This documentation refers to Lingua::Diversity::Variety version 0.03.

=head1 SYNOPSIS

    use Lingua::Diversity::Variety;
    use Lingua::Diversity::Utils qw( split_text split_tagged_text );

    my $text = 'of the people, by the people, for the people';

    # Create a Diversity object...
    my $diversity = Lingua::Diversity::Variety->new();

    # Given some text, get a reference to an array of words...
    my $word_array_ref = split_text(
        'text'          => \$text,
        'unit_regexp'   => qr{[^a-zA-Z]+},
    );

    # Measure lexical diversity...
    my $result = $diversity->measure( $word_array_ref );
    
    # Display results...
    print "Lexical diversity:       ", $result->get_diversity(), "\n";

    # Tag text using Lingua::TreeTagger...
    use Lingua::TreeTagger;
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
        'options'  => [ qw( -token -lemma -no-unknown ) ],
    );
    my $tagged_text = $tagger->tag_text( \$text );

    # Get references to an array of wordforms and an array of lemmas...
    my ( $wordform_array_ref, $lemma_array_ref ) = split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
        'category'      => 'lemma',
    );

    # Measure morphological diversity...
    $result = $diversity->measure_per_category(
        $wordform_array_ref,
        $lemma_array_ref,
    );

    # Display results...
    print "Morphological diversity: ", $result->get_diversity(), "\n";


=head1 DESCRIPTION

This module computes the variety of text units, which is the number of
distinct units (i.e. unit "types") in a text, or the average number of unit
types per category.

It provides independent controls for weighting units according to their
relative frequency (yielding the so-called I<perplexity> measure, i.e. the
exponential of the entropy) and for weighting categories according to their
relative frequency. In this documentation, unless specified otherwise, the
term I<variety> will be used to cover all four possible combinations of unit
and category weighting.

The module includes a number of predefined transforms that can be applied to
variety to obtain derived indices such as type-token ratio, mean frequency,
and so on. Users may also define custom transforms.

Furthermore, the user may request variety to be computed on subsamples of
the text, which yields an estimate of the average variety per subsample (see
e.g. Xanthos, A., & Gillis, S. (2010). Quantifying the development of
inflectional diversity, I<First Language, 30(2)>: 175-198. (L<read preprint
version
online|http://www.cnts.ua.ac.be/~gillis/pdf/FL_Xanthos_Gillis_in_press.pdf>).

=head1 CREATOR

The creator (C<new()>) returns a new Lingua::Diversity::Variety object. It
takes five optional named parameters:

=over 4

=item unit_weighting

A boolean value indicating whether the relative frequency of unit types should
taken into account in the computation. If so, the module will compute the
perplexity of units instead of their variety, i.e. the exponential of the
Shannon entropy (in nats), which is expressed on the same scale as variety.
Default is 0 (no unit weighting).

Perplexity tends toward a minimal value of 1 when the text contain very few
occurrences of all unit types but one very frequent one; its maximal value is
the variety and it is attained when all types have the same frequency.

Intuitively, using perplexity instead of variety (i.e. setting unit_weighting
to 1 instead of 0) amounts to considering that a text with 10 occurrences of
word I<a>, 1 occurrence of word I<b>, and 1 occurrence of word I<c>, has a
lesser diversity than a text where each of these words has a frequency of 4.

=item category_weighting

A boolean value indicating whether the relative frequency of category types
should taken into account in the computation (this is relevant only for method
C<measure_per_category()>). If so, the module will compute the weighted
average of units per type instead of the unweighted average. Default is 0 (no
category weighting).

Intuitively, using a weighted average (i.e. setting category_weighting to 1
instead of 0) amounts to considering that the variety of units within a
category that has relative frequency 0.9 should contribute more to the overall
diversity (per category) than the variety of units within a category with
relative frequency 0.1.

=item transform

This parameter specifies the transform that should be applied to variety, if
any. Transforms are various functions of variety and text length (i.e. number
of types and tokens respectively).

The value of this parameter can be a reference to a (possibly anonymous)
subroutine. The subroutine will be passed the variety as first argument and
the number of tokens as second argument. It should return the transformed
variety.

Alternatively, the value of this parameter can be a string referring to one
of the following predefined transforms, where M stands for the variety and N
stands for the number of tokens:

=over 4

=item none (default value)

No transform.

=item type_token_ratio

M / N

=item mean_frequency

N / M = 1 / type_token_ratio

=item guiraud

M / sqrt( N )

=item herdan

ln( M ) / ln( N )

=item rubet

ln( M ) / ln( ln( N ) )

=item maas

( ln( N ) - ln( M ) ) / ln( N )^2

=item dugast

ln( N )^2 / ( ln( N ) - ln( M ) ) = 1 / maas

=item lukjanenkov_nesitoj

( 1 - ln( M )^2 ) / ( ln( N ) * ln( M )^2 )

=back

=item sampling_scheme

This parameter indicates which form of resampling should be applied, if any.
Default is undef, i.e. no resampling. Otherwise, the value must be a
L<Lingua::Diversity::SamplingScheme> object. In this case, the reported
diversity will be the average number of distinct unit types in subsamples of
a given size (possibly per categroy), cf. Xanthos, A., & Gillis, S. (2010).
Quantifying the development of inflectional diversity, I<First Language,
30(2)>: 175-198. (L<read preprint version
online|http://www.cnts.ua.ac.be/~gillis/pdf/FL_Xanthos_Gillis_in_press.pdf>)

Note that resampling and averaging (if any) are applied after any tranform
specified by the I<transform> parameter, so that the reported variety is the
average transformed diversity per subsample and the reported variance is the
variance of the transformed diversity. The number of tokens used in the
transform is set to the value of the I<subsample_size> attribute of the
sampling scheme (see L<Lingua::Diversity::SamplingScheme>).

=back

=head1 ACCESSORS, PREDICATES, AND CLEARERS

=over 4

=item get_unit_weighting() and set_unit_weighting()

Getter and setter for the I<unit_weighting> attribute.

=item get_category_weighting() and set_category_weighting()

Getter and setter for the I<category_weighting> attribute.

=item get_transform() and set_transform()

Getter and setter for the I<transform> attribute.

=item get_sampling_scheme(), set_sampling_scheme(), has_sampling_scheme(),
and clear_sampling_scheme()

Getter, setter, predicate, and clearer for the I<sampling_scheme> attribute.

=back

=head1 METHODS

=over 4

=item measure()

Compute the variety of text units and return the result in a new
L<Lingua::Diversity::Result> object.

If no resampling is applied (which is the default behavior), the result
includes only the I<diversity> field (no variance and count).

If resampling is applied, the result includes the average, variance, and
number of observations (the latter being the value of the sampling scheme's
I<num_subsamples> attribute, cf. L<Lingua::Diversity::SamplingScheme>).

The method requires a reference to a non-empty array of text units (typically
words) as argument. Units don't need to be in the text's order (unless you are
using a sampling scheme with mode I<segmental>, cf.
L<Lingua::Diversity::SamplingScheme>).

The L<Lingua::Diversity::Utils> module contained within the
L<Lingua::Diversity> distribution provides tools for helping with the creation
of the array of units.

=item measure_per_category()

Compute the average variety of text units per category and return the result
in a new L<Lingua::Diversity::Result> object. For instance, units might be
wordforms and categories might be lemmas, so that the result would correspond
to the variety of wordforms per lemma (i.e. an estimate of the text's
morphological diversity).

If no resampling is applied (which is the default behavior), the result
includes only the I<diversity> field (no variance and count).

If resampling is applied, the result includes the average, variance, and
number of observations (the latter being the value of the sampling scheme's
I<num_subsamples> attribute, cf. L<Lingua::Diversity::SamplingScheme>).

The method requires a reference to a non-empty array of text units and a
reference to a non-empty array of categories as arguments. Units and
categories don't need to be in the text's order (unless you are using a
sampling scheme with mode I<segmental>, cf.
L<Lingua::Diversity::SamplingScheme>). They must be in one-to-one
correspondence (so that there should be the same number of items in the unit
and category arrays).

The L<Lingua::Diversity::Utils> module contained within this distribution
provides tools for helping with the creation of the array of units and
categories.

=back

=head1 DIAGNOSTICS

=over 4

=item Method [measure()/measure_per_category()] must be called with a
reference to an array as 1st argument

This exception is raised when either method C<measure()> or method
C<measure_per_category()> is called without a reference to an array as a
first argument.

=item Method measure_per_category() must be called with a reference to an
array as 2nd argument

This exception is raised when method C<measure_per_category()> is called
without a reference to an array as a second argument.

=item Method [measure()/measure_per_category()] was called with an array
containing M item(s) while this measure requires at least N item(s)

This exception is raised when either method C<measure()> or method
C<measure_per_category()> is called with an array argument that does not
contain enough items. In practice, it may be that the array is empty, or that
it contains less items than the value of the I<subsample_size> attribute of
the sampling scheme, if any (see L<Lingua::Diversity::SamplingScheme>).

=back

=head1 DEPENDENCIES

This module is part of the Lingua::Diversity distribution, and extends
L<Lingua::Diversity>.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

There is a known problem with 'dugast' transform (see above): if a text (or
subsample) has maximal variety (i.e. the number of types is equal to the
number of tokens), the denominator of this transform becomes 0, which raises
an "illegal division by zero error".

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

L<Lingua::Diversity> and L<Lingua::Diversity::SamplingScheme>

