package Lingua::Diversity::VOCD;

use Moose;

our $VERSION = '0.03';

extends 'Lingua::Diversity';

use Lingua::Diversity::Variety;
use Lingua::Diversity::Internals qw( _get_average );


#=============================================================================
# Attributes.
#=============================================================================

has 'length_range' => (
    is          => 'rw',
    isa         => 'ArrayRef[Lingua::Diversity::Subtype::Natural]',
    reader      => 'get_length_range',
    writer      => 'set_length_range',
    trigger     => \&_length_range_set,
    default     => sub { [ 35..50 ] },
);

has 'num_subsamples' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::Natural',
    reader      => 'get_num_subsamples',
    writer      => 'set_num_subsamples',
    default     => 100,
);

has 'min_value' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::PosNum',
    reader      => 'get_min_value',
    writer      => 'set_min_value',
    default     => '0.01',
);

has 'max_value' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::PosNum',
    reader      => 'get_max_value',
    writer      => 'set_max_value',
    default     => '200',
);

has 'precision' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::PosNum',
    reader      => 'get_precision',
    writer      => 'set_precision',
    default     => '0.01',
);

has 'num_trials' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::PosNum',
    reader      => 'get_num_trials',
    writer      => 'set_num_trials',
    default     => '3',
);


#=============================================================================
# Private instance methods.
#=============================================================================

#-----------------------------------------------------------------------------
# Method _measure
#-----------------------------------------------------------------------------
# Synopsis:      Apply VOCD, possibly per category.
# Arguments:     - A reference to a validated array of recoded units.
#                - An optional reference to a validated array of categories.
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub _measure {
    my ( $self, $recoded_unit_array_ref, $category_array_ref ) = @_;

    # Create a L::D::Variety object for computing TTR of subsamples...
    my $diversity = Lingua::Diversity::Variety->new(
        'transform'         => 'type_token_ratio',
        'sampling_scheme'   => Lingua::Diversity::SamplingScheme->new(
            'subsample_size'    => 100,
            'num_subsamples'    => $self->get_num_subsamples(),
        ),
    );

    my @optimal_values;

    TRIALS:
    foreach ( 1..$self->get_num_trials() ) {

        # Get average TTR value for each length in length_range...
        my %ttr;
        foreach my $length ( @{ $self->get_length_range() } ) {
            $diversity->get_sampling_scheme()->set_subsample_size( $length );
            $ttr{$length} = $diversity->_measure(
                $recoded_unit_array_ref,
                $category_array_ref,
            )->get_diversity();
        }

        my $min_sum_squared_residuals;
        my $argmin_sum_squared_residuals;

        # For each value of the parameter...
        VALUE:
        for ( my $value  = $self->get_min_value();
                 $value <= $self->get_max_value();
                 $value += $self->get_precision()
        ) {

            my $sum_squared_residuals;

            # For each length...
            LENGTH:
            foreach my $length ( @{ $self->get_length_range() } ) {

                # Compute expected TTR...
                my $expected_ttr = $value / $length
                                 * (
                                      sqrt(
                                          1
                                        + 2 * $length / $value
                                      )
                                    - 1
                                 )
                                 ;

                # Compute residual...
                my $residual = $expected_ttr - $ttr{$length};

                # Increment sum of squared residuals...
                $sum_squared_residuals += $residual * $residual;
            }

            # Store the length if sum of squared residuals is minimal...
            if (
                   ! ( defined $min_sum_squared_residuals )
                || $sum_squared_residuals <= $min_sum_squared_residuals
            ) {
                $min_sum_squared_residuals      = $sum_squared_residuals;
                $argmin_sum_squared_residuals   = $value;
            }
            else { last VALUE; }  # Remove this line to keep searching even
                                  # if the sum of squared residuals increases!
        }

        # Round optimal value...
        $argmin_sum_squared_residuals
            = $self->_round_to_precision( $argmin_sum_squared_residuals );

        # Store optimal value...
        push @optimal_values, $argmin_sum_squared_residuals
    }
    
    # Get average and variance of optimal value.
    my ( $average, $variance, $count ) = _get_average( \@optimal_values );

    # Round average...
    $average    = $self->_round_to_precision( $average );

    # Create, fill, and return a new Result object...
    return Lingua::Diversity::Result->new(
        'diversity' => $average,
        'variance'  => $variance,
        'count'     => $count,
    );
}



#-----------------------------------------------------------------------------
# Method _round_to_precision
#-----------------------------------------------------------------------------
# Synopsis:      Rounds a number to the object's precision.
# Arguments:     - A number.
# Return values: - The rounded number.
#-----------------------------------------------------------------------------

sub _round_to_precision {
    my ( $self, $number ) = @_;
    if ( $self->get_precision() =~ qr{\.([^eE]+)$} ) {
        my $num_digits_after_point = length $1;
        return sprintf ( "%.${num_digits_after_point}f", $number );
    }
    return $number;
}


        
#-----------------------------------------------------------------------------
# Method _length_range_set
#-----------------------------------------------------------------------------
# Synopsis:      Modifies min_num_items attribute according to length_range.
# Arguments:     - The new value of length_range.
#                - The old value of length_range.
# Return values: - None.
#-----------------------------------------------------------------------------

sub _length_range_set {
    my ( $self, $length_range ) = @_;

    use List::Util qw( max );
    
    $self->_set_min_num_items( max( @$length_range ) );

    return;
}



#=============================================================================
# Moose construction hooks.
#=============================================================================

sub BUILD {
    my ( $self, $param ) = @_;
    if ( ! exists $param->{'length_range'} ) {
        $self->_length_range_set( $self->get_length_range() );
    }
    return;
}



#=============================================================================
# Standard Moose cleanup.
#=============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::Diversity::VOCD - 'VOCD' method for measuring diversity of text units

=head1 VERSION

This documentation refers to Lingua::Diversity::VOCD version 0.03

=head1 SYNOPSIS

    use Lingua::Diversity::VOCD;
    use Lingua::Diversity::Utils qw( split_text split_tagged_text );

    my $text = 'of the people, by the people, for the people';

    # Create a Diversity object...
    my $diversity = Lingua::Diversity::VOCD->new(
        'length_range'      => [ 35..50 ],
        'num_subsamples'    => 100,
        'min_value'         => 1,
        'max_value'         => 200,
        'precision'         => 0.01,
        'num_trials'        => 3
    );

    # Given some text, get a reference to an array of words...
    my $word_array_ref = split_text(
        'text'          => \$text,
        'unit_regexp'   => qr{[^a-zA-Z]+},
    );

    # Measure lexical diversity...
    my $result = $diversity->measure( $word_array_ref );
    
    # Display results...
    print "Lexical diversity:       ", $result->get_diversity(), "\n";
    print "Variance:                ", $result->get_variance(),  "\n";

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
    print "Variance:                ", $result->get_variance(),  "\n";


=head1 DESCRIPTION

This module implements the 'VOCD' method for measuring the diversity
of text units, cf. McKee, G., Malvern, D., & Richards, B. (2000). Measuring
Vocabulary Diversity Using Dedicated Software, I<Literary and Linguistic
Computing, 15(3)>: 323-337 (L<read it
online|http://childes.psy.cmu.edu/manuals/vocd.doc>).

In a nutshell, this method consists in taking a number of subsamples
of 35, 36, ..., 49, and 50 tokens at random from the data, then computing
the average type-token ratio for each of these lengths, and finding the
curve that best fits the type-token ratio curve just produced (among a family
of curves generated by expressions that differ only by the value of a single
parameter). The parameter value corresponding to the best-fitting curve is
reported as the result of diversity measurement. The whole procedure can be
repeated several times and averaged.

This implementation also attempts to generalize the authors' original idea to
the computation of morphological diversity (see method
C<measure_per_category()> below).

NB: The curve fitting procedure used in this implementation relies on the
assumption that there is no use in trying larger values of the parameter
when the sum of squared residuals has stopped decreasing. This assumption is
based on a limited number of tests (as opposed to function analysis), so while
it speeds processing greatly, it might prove wrong. If you have analytical
or empirical reasons to think the assumption is wrong, please let the author
know, he'll be glad to fix the code accordingly.

=head1 CREATOR

The creator (C<new()>) returns a new Lingua::Diversity::VOCD object. It
takes six optional named parameters:

=over 4

=item length_range

A reference to an array specifying the lengths at which the data should be
sampled to estimate the growth of type-token ratio. Default is C<[ 35..50 ]>.

=item num_subsamples

The number of subsamples to be drawn for each length in I<length_range>.
Default is 100.

=item min_value

The minimal parameter value that can be tried during curve-fitting (a positive
number). Default is 0.01.

=item max_value

The maximal parameter value that can be tried during curve-fitting (a positive
number). Default is 200.

=item precision

The amount by which the parameter value is changed at each iteration of the
curve-fitting procedure (a positive number). Default is 0.01.

=item num_trials

The number of times that the whole procedure is repeated (a positive number).
Default is 3.

=back

=head1 ACCESSORS

=over 4

=item get_length_range() and set_length_range()

Getter and setter for the I<length_range> attribute.

=item get_num_subsamples() and set_num_subsamples()

Getter and setter for the I<num_subsamples> attribute.

=item get_min_value() and set_min_value()

Getter and setter for the I<min_value> attribute.

=item get_max_value() and set_max_value()

Getter and setter for the I<max_value> attribute.

=item get_precision() and set_precision()

Getter and setter for the I<precision> attribute.

=item get_num_trials() and set_num_trials()

Getter and setter for the I<num_trials> attribute.


=back

=head1 METHODS

=over 4

=item measure()

Apply the VOCD algorithm and return the result in a new
L<Lingua::Diversity::Result> object. The result includes the average,
variance, and number of observations (i.e. trials in this case).

The method requires a reference to a non-empty array of text units (typically
words) as argument. Units need not be in the text's order.

The L<Lingua::Diversity::Utils> module contained within the
L<Lingua::Diversity> distribution provides tools for helping with the creation
of the array of units.

=item measure_per_category()

Apply the VOCD algorithm per category and return the result in a
new L<Lingua::Diversity::Result> object. For instance, units might be
wordforms and categories might be lemmas, so that the result would correspond
to the diversity of wordforms per lemma (i.e. an estimate of the text's
morphological diversity). The result includes the average, variance, and
number of observations  (i.e. trials in this case).

The original method described by McGee, Malvern, & Richards (2000) is modified
by replacing the type count in the type-token ratio with the number of unit
types (e.g. wordform types) divided by the number of category types
(e.g. lemma types).

The method requires a reference to a non-empty array of text units and a
reference to a non-empty array of categories as arguments. Units and
categories need not be in the text's order. They should be in one-to-one
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
C<measure_per_category()> is called with an array argument that contains less
tokens than the upper limit of the I<length_range> attribute (default is 50).

=back

=head1 DEPENDENCIES

This module is part of the Lingua::Diversity distribution, and extends
L<Lingua::Diversity>.

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

