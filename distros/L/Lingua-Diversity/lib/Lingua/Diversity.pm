package Lingua::Diversity;

use Moose;

our $VERSION = '0.07';

# TODO
# Add option for prepending units with lemmas in measure().
# Document the use of _prepend_units... in measure_per_category().

use Lingua::Diversity::Result;
use Lingua::Diversity::Variety;
use Lingua::Diversity::MTLD;
use Lingua::Diversity::VOCD;
use Lingua::Diversity::X;
use Lingua::Diversity::Subtype;



#=============================================================================
# Attributes (marked as internal, meant to be set from within derived classes)
#=============================================================================

has 'min_num_items' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::Natural',
    reader      => '_get_min_num_items',
    writer      => '_set_min_num_items',
    default     => 1,
    init_arg    => undef,
);

has 'max_num_items' => (
    is          => 'rw',
    isa         => 'Lingua::Diversity::Subtype::Natural',
    reader      => '_get_max_num_items',
    writer      => '_set_max_num_items',
    init_arg    => undef,
);


#=============================================================================
# Public instance methods.
#=============================================================================

#-----------------------------------------------------------------------------
# Method measure
#-----------------------------------------------------------------------------
# Synopsis:      Validate array and call internal _measure().
# Arguments:     - A reference to an array of units.
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub measure {
    my ( $self, $array_ref ) = @_;

    # Validate argument array...
    _validate_size(
        'unit_array_ref'    => $array_ref,
        'min_num_items'     => $self->_get_min_num_items(),
    );

    # Apply measure and return Result object...
    return $self->_measure( $array_ref );
}


#-----------------------------------------------------------------------------
# Method measure_per_category
#-----------------------------------------------------------------------------
# Synopsis:      Validate arrays, recode units and call internal
#                _measure_per_category().
# Arguments:     - A reference to an array of units (in the text's order).
#                - A reference to an array of categories (in the same order).
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub measure_per_category {
    my ( $self, $unit_array_ref, $category_array_ref ) = @_;

    # Validate argument arrays...
    _validate_size(
        'unit_array_ref'        => $unit_array_ref,
        'category_array_ref'    => $category_array_ref,
        'min_num_items'         => $self->_get_min_num_items(),
    );

    # Prepend each unit with its category...
    my $recoded_unit_array_ref = _prepend_unit_with_category(
        $unit_array_ref,
        $category_array_ref,
    );

    # Apply measure and return Result object...
    return $self->_measure(
        $recoded_unit_array_ref,
        $category_array_ref,
    );
}


#=============================================================================
# Private abstract instance methods.
#=============================================================================

#-----------------------------------------------------------------------------
# ABSTRACT Method _measure
#-----------------------------------------------------------------------------
# Synopsis:      Apply the selected measure, possibly per category.
# Arguments:     - A reference to a validated array of units.
# Return values: - A Lingua::Diversity::Result object.
#-----------------------------------------------------------------------------

sub _measure {
    my ( $self ) = @_;
    
    # Get object's class.
    my $class = ref( $self );

    # Abstract object exception...
    Lingua::Diversity::X::AbstractObject->throw()
        if $class eq 'Lingua::Diversity';

    # Abstract method exception...
    Lingua::Diversity::X::AbstractMethod->throw(
        'class'     => $class,
        'method'    => '_measure',
    );
}


#=============================================================================
# Private subroutines.
#=============================================================================

#-----------------------------------------------------------------------------
# Subroutine _validate_size
#-----------------------------------------------------------------------------
# Synopsis:      Validate the array arguments of methods measure() and
#                measure_per_category().
# Parameters:    - unit_array_ref:     a non-empty array of text units.
#                - category_array_ref: a non-empty array of categories.
#                - min_num_items:      an optional min number of items
#                                      (default is 1).
#                - max_num_items:      an optional max number of items.
# Return values: None.
#-----------------------------------------------------------------------------

sub _validate_size {
    my ( %parameter ) = @_;

    # Parameter 'unit_array_ref' is required...
    Lingua::Diversity::X::ValidateSizeMissingParam->throw()
        if ! exists $parameter{'unit_array_ref'};

    # Get caller method...
    my $method = ( caller(1) )[3];

    # Parameter 'unit_array_ref' must be a ref to an array...
    if ( ref $parameter{'unit_array_ref'} ne 'ARRAY' ) {
        Lingua::Diversity::X::ValidateSizeMissing1stArrayRef->throw(
            'method' => $method,
        )
    }

    # Default min number of items is 1...
    $parameter{'min_num_items'} ||= 1;

    # Get number of items in unit array.
    my $num_items = @{ $parameter{'unit_array_ref'} };

    # Validate min number of items...
    if ( $num_items < $parameter{'min_num_items'} ) {
        Lingua::Diversity::X::ValidateSizeArrayTooSmall->throw(
            'method'        => $method,
            'num_items'     => $num_items,
            'min_num_items' => $parameter{'min_num_items'},
        );
    }

    # Validate max number of items...
    if (
           defined $parameter{'max_num_items'}
        && $num_items > $parameter{'max_num_items'}
    ) {
        Lingua::Diversity::X::ValidateSizeArrayTooLarge->throw(
            'method'        => $method,
            'num_items'     => $num_items,
            'max_num_items' => $parameter{'max_num_items'},
        );
    }

    # If caller is measure_per_category...
    if ( $method =~ qr{measure_per_category$} ) {

        # Parameter 'unit_array_ref' must be a ref to an array...
        if ( ref $parameter{'category_array_ref'} ne 'ARRAY' ) {
            Lingua::Diversity::X::ValidateSizeMissing2ndArrayRef->throw(
                'method' => $method,
            )
        }

        # Get number of items in category array.
        my $num_categories = scalar @{ $parameter{'category_array_ref'} };

        # Check that arrays have the same size...
        if ( $num_items != $num_categories ) {
            Lingua::Diversity::X::ValidateSizeArraysOfDifferentSize->throw(
                'method'            => $method,
                'num_units'         => $num_items,
                'num_categories'    => $num_categories,
            );
        }
    }

    return;
}


#-----------------------------------------------------------------------------
# Subroutine _prepend_unit_with_category
#-----------------------------------------------------------------------------
# Synopsis:      Prepend every unit in an array with its category.
# Arguments:     - A reference to an array of units.
#                - A reference to an array of categories of same size.
# Return values: - A reference to an array of recoded units.
#-----------------------------------------------------------------------------

sub _prepend_unit_with_category {
    my ( $unit_array_ref, $category_array_ref ) = @_;

    my @recoded_array;

    ITEM_INDEX:
    foreach my $item_index ( 0..@$unit_array_ref-1 ) {

        # Prepend unit with category and add to recoded array.
        push @recoded_array,
                $category_array_ref->[$item_index]
              . $unit_array_ref->[$item_index]
              ;
    }

    return \@recoded_array;
}


#=============================================================================
# Standard Moose cleanup.
#=============================================================================

no Moose;
__PACKAGE__->meta->make_immutable;


__END__


=head1 NAME

Lingua::Diversity - measuring the diversity of text units

=head1 VERSION

This documentation refers to Lingua::Diversity version 0.06.

=head1 SYNOPSIS

    use Lingua::Diversity;
    use Lingua::Diversity::Utils qw( split_text split_tagged_text );

    my $text = 'of the people, by the people, for the people';

    # Create a Diversity object (here using method 'Variety')...
    my $diversity = Lingua::Diversity::Variety->new();

    # Given some text, get a reference to an array of words...
    my $word_array_ref = split_text(
        'text'      => \$text,
        'regexp'    => qr{[^a-zA-Z]+},
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

This is the base module of distribution Lingua::Diversity, which provides a
simple object-oriented interface for applying various measures of diversity
to text units. At present, it implements the VOCD algorithm (see
L<Lingua::Diversity::VOCD>, the MTLD algorithm (see
L<Lingua::Diversity::MTLD>), and many variants of variety (see
L<Lingua::Diversity::Variety>).

The documentation of this module is designed as a tutorial exposing the main
features of this distribution. For details about measure-specific features,
please refer to L<Lingua::Diversity::VOCD>, L<Lingua::Diversity::MTLD>), and
L<Lingua::Diversity::Variety> (which itself is related to
L<Lingua::Diversity::SamplingScheme>). For details about utility subroutines,
please refer to L<Lingua::Diversity::Utils>. Finally, details about the format
in which results are stored, please refer to L<Lingua::Diversity::Result>

=head2 Basics

This module is all about measuring diversity. While it is able to deal with
any kind of nominal (as opposed to numeric) data, its design has been
guided by a particular interest in I<text> data. In this context, diversity
often means I<lexical> diversity, i.e. an estimate of the rate at which new
words appear in a text.

It turns out that there are many different ways to measure lexical diversity,
quite a few of which are implemented in Lingua::Diversity. In this framework,
all measures operate on the same kind of data, namely arrays, e.g.:

    my @data = qw( say you say me );


In general, we will speak of I<units> to refer to the elements of such an
array. In this example, they are words, but they might as well be other kinds
of linguistic units, such as letters for example--although in the latter case
we would be measuring a I<graphemic> rather than a lexical sort of diversity.

As shown in the previous example, units in the array need not be unique. In
fact, arrays consisting only of unique items are a very special case, the case
where diversity is maximal. In most cases, arrays will contain repeated items,
and thus have a less than maximal diversity.

In order to measure the diversity of units in a given array, we must first
create a Lingua::Diversity object. More precisely, we should create an object
from a class I<derived from> Lingua::Diversity, such as
L<Lingua::Diversity::Variety> (other options are L<Lingua::Diversity::MTLD>
and L<Lingua::Diversity::VOCD>). Since this module (Lingua::Diversity) imports
all derived classes, we may simply C<use> it and call the C<new()> method of
a derived class as follows:

    use Lingua::Diversity;
    my $diversity = Lingua::Diversity::Variety->new();


This creates a new object for measuring the I<variety> of units in an array.
In its most basic form, variety is simply the number of I<distinct> units in
the array, i.e. 3 in our example (I<say>, I<you>, and I<me>). Distinct units
are also called unit I<types>, while unit I<tokens> refer to the possibly
repeated units found in the array (so the number of tokens is the size of the
array, i.e. 4 in our example).

With this new object at hand, we may measure the variety of words in our array
by calling the C<measure()> method on the object:

    my $result = $diversity->measure( \@data );


This method takes a single argument, namely a reference to an array of units.
It is important to note that it uses a reference (C<\@data>) and not the array
itself (C<@data>), because this is the way all diversity measures in the
distribution operate.

Now the return value of method C<measure()> is a L<Lingua::Diversity::Result>
object, and such objects store the measured diversity in a field called
I<diversity> which may be accessed like this:

    print $result->get_diversity();


To sum up, here's how to compute and display the variety of units in an array:

    use Lingua::Diversity;

    my @data      = qw( say you say me );

    my $diversity = Lingua::Diversity::Variety->new();
    my $result    = $diversity->measure( \@data );

    print $result->get_diversity();


This will print 3, the number of types in the array. If you're not impressed,
hold on, this was just the basics.

=head2 Tweaking a diversity measure

All diversity measures in Lingua::Diversity can be parameterized in a number
of ways. For instance, rather than plain variety, you might be interested in
the so-called I<type-token ratio>, i.e. the ratio of the number of types to
the number of tokens. As it happens, L<Lingua::Diversity::Variety> objects
have a I<transform> attribute which is set to I<none> by default, but which
can be set to I<type_token_ratio> (among others). This can be done either at
object creation:

    my $diversity = Lingua::Diversity::Variety->new(
        'transform' => 'type_token_ratio',
    );


or using the C<set_transform()> method on a previously created object:

    $diversity->set_transform( 'type_token_ratio' );


To display the type-token ratio of an array, you may proceed as before:

    my $result = $diversity->measure( \@data );
    print $result->get_diversity();


By the way, if you don't plan to re-use the result, you can also chain
method calls like this:

    print $diversity->measure( \@data )->get_diversity();


Both approaches will display the type-token ratio, i.e. 0.75 in our example
(3 types divided by 4 tokens).

To take a more sophisticated example, suppose that you are not merely
interested in the type-token ratio, but in the I<average> type-token ratio
over segments of I<N> tokens in the array (sometimes called I<mean segmental
type-token ratio>). Setting I<N> to 2, and reading from left to right, there
are two such segments in our example, namely I<say you> and I<say me>. Each
has a type-token ratio of 1 (2 types divided by 2 tokens), so the average is
1. This is what you get with the following piece of code:

    use Lingua::Diversity;

    my @data        = qw( say you say me );

    my $diversity   = Lingua::Diversity::Variety->new(
        'transform'       => 'type_token_ratio',
        'sampling_scheme' => Lingua::Diversity::SamplingScheme->new(
            'mode'           => 'segmental',
            'subsample_size' => 2,
        ),
    );
    my $result      = $diversity->measure( \@data );

    print 'Average type-token ratio: ', $result->get_diversity(), "\n";
    print 'Variance:                 ', $result->get_variance(),  "\n";
    print 'Number of observations:   ', $result->get_count(),     "\n";


As a bonus, you also get the variance of type-token ratio over segments (0 in
this case, since both segments have the same type-token ratio) as well as the
number of segments over which the average was computed, i.e. 2. This extra
information is available because we have specified a sampling
scheme at object construction, so that method C<measure()> knows that it must
work on a number of subsamples and return a L<Lingua::Diversity::Result>
object storing an average (accessed with method C<get_diversity()>), variance
(accessed with method C<get_variance()>), and number of observations (accessed
with method C<get_count()>).

This fairly involved example gives an idea of how versatile Lingua::Diversity
can be. The reader is invited to refer to L<Lingua::Diversity::Variety> and
L<Lingua::Diversity::SamplingScheme> for detailed explanations on how to
parameterize a variety measure; other measures have yet other sets of
parameters, as documented in L<Lingua::Diversity::MTLD> and
L<Lingua::Diversity::VOCD>.

=head2 Average diversity per category

Suppose that you do not only have an array of units, but also an array of
corresponding I<categories>. For instance, categories might be part-of-speech
tags:

    my @units      = qw( say  you     say  me      );
    my @categories = qw( VERB PRONOUN VERB PRONOUN );


Categories can be anything that can be put in one-to-one correspondence with
units. Indeed, the only constraint here is that the number of elements be the
same in the two arrays, so that you might as well use letters and letter
categories:

    my @units      = qw( l e t t e r s );
    my @categories = qw( C V C C V C C );


If this extra bit of information is available, we can estimate the diversity
of units I<per category>. What this means exactly depends on the diversity
measure being considered. In the case of variety, it would be the average
variety (or type-token ratio, etc.) per category. From the example above,
it can be seen that there is one unit type in category I<VERB> (namely I<say>)
and two unit types in category I<PRONOUN> (namely I<you> and I<me>), so the
average variety per category is 1.5. This what you will obtain by calling
method I<measure_per_category()> with references to the two arrays as
arguments:

    use Lingua::Diversity;

    my @units      = qw( say  you     say  me      );
    my @categories = qw( VERB PRONOUN VERB PRONOUN );

    my $diversity  = Lingua::Diversity::Variety->new();
    my $result     = $diversity->measure_per_category(
        \@units,
        \@categories,
    );

    print $result->get_diversity();


Furthermore, you may request that the average be weighted according to the
relative frequency of categories. Consider the example of letters and letter
categories above. Category I<C> has a variety of 4 and a relative frequency
of 5/7, while category I<V> has a variety of 1 and a relative frequency of
2/7. Thus, the unweighted average is 2.5, but the weighted average is 3.143,
which reflects the greater weight of the category with highest variety. To
compute the weighted variant with L<Lingua:Diversity::Variety> simply set
the I<category_weighting> parameter to true at object creation (or using
method C<category_weighting()>):

    my $diversity = Lingua::Diversity::Variety->new(
        'category_weighting' => 1,
    );


Of course, this can be parameterized with the I<transform> or
I<sampling_scheme> parameters seen above, or any of the parameters documented
in L<Lingua:Diversity::Variety>. Classes L<Lingua::Diversity::VOCD> and
L<Lingua::Diversity::MTLD> also support method C<measure_per_category()>,
with their own semantics and parameters.

=head2 Utility subroutines

The Lingua::Diversity distribution includes a couple of utility subroutines
intended to facilitate the creation of unit and category arrays. These
subroutines are exported by module L<Lingua::Diversity::Utils>.

Subroutine C<split_text()> splits a text based on a regular expression
describing delimiter sequences (just like the built-in C<split()> function),
removes empty elements (if any), and returns a reference to the resulting
array, which can then be used as the argument of a call to method
C<measure()>:

    use Lingua::Diversity;
    use Lingua::Diversity::Utils qw( split_text );
    
    my $text           = 'of the people, by the people, for the people';
    my $word_array_ref = split_text(
        'text'      => \$text,
        'regexp'    => qr{[^a-zA-Z]+},
    );

    my $diversity      = Lingua::Diversity::Variety->new();
    my $result         = $diversity->measure( $word_array_ref );


This module also exports a subroutine (C<_split_tagged_text()>) to build both
a unit array and a category array on the basis of the output of the
L<Lingua::TreeTagger> module, cf. L</SYNOPSIS> for an example and
L<Lingua::Diversity::Utils> for detailed explanations.

=head1 METHODS

=over 4

=item measure()

Apply the selected diversity measure and return the result in a new
L<Lingua::Diversity::Result> object.

The method requires a reference to a non-empty array of text units (typically
words) as argument.

Some measures, in particular L<Lingua::Diversity::MTLD> (as well as
L<Lingua::Diversity::Variety> under I<segmental> sampling scheme) take the
order of units into account. Specific measures may set conditions on the
minimal or maximal number of units and raise exceptions when these conditions
are not met.

The L<Lingua::Diversity::Utils> module contained within this distribution
provides tools for helping with the creation of the array of units.

=item measure_per_category()

Apply the selected diversity measure per category and return the result in a
new L<Lingua::Diversity::Result> object. For instance, units might be
wordforms and categories might be lemmas, so that the result would correspond
to the diversity of wordforms per lemma (i.e. an estimate of the text's
morphological diversity).

Some measures, in particular L<Lingua::Diversity::MTLD> (as well as
L<Lingua::Diversity::Variety> under I<segmental> sampling scheme) take the
order of units into account. Specific measures may set conditions on the
minimal or maximal number of units and raise exceptions when these conditions
are not met. There should always be the same number of items in both arrays.

The L<Lingua::Diversity::Utils> module contained within this distribution
provides tools for helping with the creation of the array of units and lemmas.

=back

=head1 DIAGNOSTICS

=over 4

=item Call to abstract method CLASS::_measure()

This exception is raised when either method C<measure()> or method
C<measure_per_category()> is called while internal method C<_measure()> is not
implemented in a class derived from Lingua::Diversity.

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
containing N item(s) while this measure requires [at least/at most] M item(s)

This exception is raised when either method C<measure()> or method
C<measure_per_category()> is called with an argument array that is either too
small or too large relative to conditions set by the selected measure.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Some subroutines in module Lingua::Diversity::Utils require a working
version of TreeTagger (available at
L<http://www.ims.uni-stuttgart.de/projekte/corplex/TreeTagger>).

=head1 DEPENDENCIES

This is the base module of the Lingua::Diversity distribution, which comprises
modules L<Lingua::Diversity::Result>, L<Lingua::Diversity::SamplingScheme>,
L<Lingua::Diversity::Internals>, L<Lingua::Diversity::Internals>,
L<Lingua::Diversity::Variety>, L<Lingua::Diversity::MTLD>,
L<Lingua::Diversity::VOCD>, and L<Lingua::Diversity::X>.

The Lingua::Diversity distribution uses CPAN modules
L<Moose>, L<Exception::Class>, and optionally L<Lingua::TreeTagger>.

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

L<Lingua::Diversity::Result>, L<Lingua::Diversity::SamplingScheme>,
L<Lingua::Diversity::Internals>, L<Lingua::Diversity::Internals>,
L<Lingua::Diversity::Variety>, L<Lingua::Diversity::MTLD>,
L<Lingua::Diversity::VOCD>, L<Lingua::Diversity::X>, and
L<Lingua::TreeTagger>.


