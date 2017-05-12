#!/usr/bin/perl

package Lingua::Diversity::Utils;

use strict;
use warnings;
use Carp;

use Exporter   ();

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(
    split_text
    split_tagged_text
);

our $VERSION     = 0.05;

use Lingua::Diversity::X;


#=============================================================================
# Public subroutines
#=============================================================================

#-----------------------------------------------------------------------------
# Subroutine split_text
#-----------------------------------------------------------------------------
# Synopsis:      Split a text into units, delete empty units, and return a
#                reference to the array of units.
# Parameters:    - text (required): a reference to the string to be split.
#                - regexp:          a regular expression describing unit
#                                   delimiter sequences.
# Return values: - A reference to an array of units.
#-----------------------------------------------------------------------------

sub split_text {
    my ( %parameter ) = @_;

    # Parameter 'text' is required...
    Lingua::Diversity::X::Utils::SplitTextMissingParam->throw()
        if ! exists $parameter{'text'};

    # Default regexp parameter is any sequence of blanks.
    $parameter{'regexp'} ||= qr{\s+};

    # Split text with regexp.
    my @array = split $parameter{'regexp'}, ${ $parameter{'text'} };

    # Delete empty elements.
    @array = grep { $_ } @array;

    # Return a reference to the array of units.
    return \@array;
}


#-----------------------------------------------------------------------------
# Subroutine split_tagged_text
#-----------------------------------------------------------------------------
# Synopsis:      Given a Lingua::TreeTagger::TaggedText object, return a
#                reference to the array of units (e.g. wordforms). Optionally,
#                return a second reference to the array of categories
#                (e.g. lemmas).
# Parameters:    - taggged_text (required): a Lingua::TreeTagger::TaggedText.
#                - unit (required):         'original', 'lemma', or 'tag'.
#                - category:                'lemma', or 'tag'.
#                - condition:               a hash ref with following keys:
#                   - mode:     'include' (default) or 'exclude'.
#                   - logical:  'and' (default) or 'or'.
#                   - original:  a regexp.
#                   - lemma:     a regexp.
#                   - tag:       a regexp.
# Return values: - A reference to an array of units.
#                - An optional reference to an array of categories.
#-----------------------------------------------------------------------------

sub split_tagged_text {
    my ( %parameter ) = @_;

    # Parameter 'unit' is required...
    Lingua::Diversity::X::Utils::SplitTaggedTextMissingUnitParam->throw()
        if ! exists $parameter{'unit'};

    # Parameter 'unit' must be either 'original', 'lemma', or 'tag'...
    Lingua::Diversity::X::Utils::SplitTaggedTextWrongUnitParam->throw()
        if $parameter{'unit'} ne 'original'
        && $parameter{'unit'} ne 'lemma'
        && $parameter{'unit'} ne 'tag';

    # Parameter 'tagged_text' is required...
    Lingua::Diversity::X::Utils::SplitTaggedTextMissingTaggedTextParam->throw()
        if ! exists $parameter{'tagged_text'};

    # Parameter 'tagged_text' must be a Lingua::TreeTagger::TaggedText...
    Lingua::Diversity::X::Utils::SplitTaggedTextWrongTaggedTextParamType->throw()
        if ref( $parameter{'tagged_text'} )
           ne 'Lingua::TreeTagger::TaggedText';

    # If parameter 'condition' is provided...
    if ( exists $parameter{'condition'} ) {

        # If it has key 'mode'...
        if  ( exists $parameter{'condition'}{'mode'} ) {

            # ... its value must be 'include' or 'exclude'...
            Lingua::Diversity::X::Utils::SplitTaggedTextWrongModeParam->throw()
                if $parameter{'condition'}{'mode'} ne 'include'
                && $parameter{'condition'}{'mode'} ne 'exclude'
        }
        # Default is 'include'.
        else { $parameter{'condition'}{'mode'} = 'include'; }

        # If it has key 'logical'...
        if  ( exists $parameter{'condition'}{'logical'} ) {

            # ... its value must be 'and' or 'or'...
            Lingua::Diversity::X::Utils::SplitTaggedTextWrongLogicalParam->throw()
                if $parameter{'condition'}{'logical'} ne 'and'
                && $parameter{'condition'}{'logical'} ne 'or'
        }
        # Default is 'and'.
        else { $parameter{'condition'}{'logical'} = 'and'; }

    }

    my @units;

    # If parameter 'category' is provided...
    if ( exists $parameter{'category'} ) {

        # Parameter 'category' must be either 'lemma' or 'tag'...
        Lingua::Diversity::X::Utils::SplitTaggedTextWrongCategoryParam->throw()
            if $parameter{'category'} ne 'lemma'
            && $parameter{'category'} ne 'tag';
            
        my @categories;
        
        TOKEN:
        foreach my $token ( @{ $parameter{'tagged_text'}->sequence() } ) {

            # Skip SGML tags.
            next TOKEN if $token->is_SGML_tag();

            # Skip based on 'condition' parameter...
            next if _should_skip(
                $parameter{'condition'},
                $token,
            );

                     # Unit param value...              # Token attribute...
            my $unit = $parameter{'unit'} eq 'original' ? $token->original()
                     : $parameter{'unit'} eq 'lemma'    ? $token->lemma()
                     :                                    $token->tag()
                     ;

            # Add unit to array.
            push @units, $unit;

                         # Category param value...       # Token attribute...
            my $category = $parameter{'category'} eq 'lemma' ? $token->lemma()
                         :                                     $token->tag()
                         ;

            # Add category to array.
            push @categories, $category;
        }
        
        # Return refs to both arrays.
        return \@units, \@categories;
    }

    # Otherwise, if no parameter 'category' is provided...
    
    TOKEN:
    foreach my $token ( @{ $parameter{'tagged_text'}->sequence() } ) {

        # Skip SGML tags.
        next TOKEN if $token->is_SGML_tag();

        # Skip based on 'condition' parameter...
        next if _should_skip(
            $parameter{'condition'},
            $token,
        );
        
                 # Unit param value...              # Token attribute...
        my $unit = $parameter{'unit'} eq 'original' ? $token->original()
                 : $parameter{'unit'} eq 'lemma'    ? $token->lemma()
                 :                                    $token->tag()
                 ;

        # Add unit to array.
        push @units, $unit;
    }

    # Return ref to unit array.
    return \@units;
}


#=============================================================================
# Private subroutines
#=============================================================================

#-----------------------------------------------------------------------------
# Subroutine _should_skip
#-----------------------------------------------------------------------------
# Synopsis:      Tell whether a Lingua::TreeTagger::Token should be skipped
#                based on a given condition.
# Arguments:     - A Lingua::TreeTagger::Token.
#                - A reference to a hash with the following keys:
#                   - mode:     'include' (default) or 'exclude'.
#                   - logical:  'and' (default) or 'or'.
#                   - original:  a regexp.
#                   - lemma:     a regexp.
#                   - tag:       a regexp.
# Return values: - 1 (skip) or 0 (don't skip).
#-----------------------------------------------------------------------------

sub _should_skip {
    my ( $condition_ref, $token ) = @_;
    
    # Don't skip if condition is not defined.
    return 0 if ! defined $condition_ref;

    my $token_matches_condition;
    
    # In case of logical 'and'...
    if ( $condition_ref->{'logical'} eq 'and' ) {

        # Token matches condition...
        $token_matches_condition = 1;

        # ... unless none of 'original', 'lemma', and 'tag' is specified...
        if (
               ! exists $condition_ref->{'original'}
            && ! exists $condition_ref->{'lemma'}
            && ! exists $condition_ref->{'tag'}
        ) {
            $token_matches_condition = 0;
        }
        # ... or at least one of 'original', 'lemma', and 'tag' is
        # specified and doesn't match...
        elsif (
            (
                exists $condition_ref->{'original'}
             && $token->original()  !~ $condition_ref->{'original'}
            )
            ||
            (
                exists $condition_ref->{'lemma'}
             && $token->lemma()     !~ $condition_ref->{'lemma'}
            )
            ||
            (
                exists $condition_ref->{'tag'}
             && $token->tag()       !~ $condition_ref->{'tag'}
            )
        ) {
            $token_matches_condition = 0;
        }
    }
    # In case of logical 'or'...
    else {

        # Token doesn't match condition...
        $token_matches_condition = 0;

        # Unless at least one of 'original', 'lemma', and 'tag' is
        # specified and matches...
        if (
            (
                exists $condition_ref->{'original'}
             && $token->original()  =~ $condition_ref->{'original'}
            )
            ||
            (
                exists $condition_ref->{'lemma'}
             && $token->lemma()     =~ $condition_ref->{'lemma'}
            )
            ||
            (
                exists $condition_ref->{'tag'}
             && $token->tag()       =~ $condition_ref->{'tag'}
            )
        ) {
            $token_matches_condition = 1;
        }
    }

    # Skip if condition matches in 'exclude' mode...
    return 1 if    $token_matches_condition
                && $condition_ref->{'mode'} eq 'exclude';

    # Skip if condition doesn't match in 'include' mode...
    return 1 if    ( ! $token_matches_condition )
                && $condition_ref->{'mode'} eq 'include';

    # Else don't skip.
    return 0;
}



1;


__END__


=head1 NAME

Lingua::Diversity::Utils - utility subroutines for users of classes
derived from L<Lingua::Diversity>

=head1 VERSION

This documentation refers to Lingua::Diversity::Utils version 0.05.

=head1 SYNOPSIS

    use Lingua::Diversity::Utils qw( split_text split_tagged_text );

    my $text = 'of the people, by the people, for the people';

    # Get a reference to an array of words...
    my $word_array_ref = split_text(
        'text'      => \$text,
        'regexp'    => qr{[^a-zA-Z]+},
    );

    # Alternatively, tag the text using Lingua::TreeTagger...
    use Lingua::TreeTagger;
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
        'options'  => [ qw( -token -lemma -no-unknown ) ],
    );
    my $tagged_text = $tagger->tag_text( \$text );

    # ... get a reference to an array of words...
    $word_array_ref = Lingua::Diversity::Utils->split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
    );

    # ... or get a reference to an array of wordforms and an array of lemmas.
    ( $wordform_array_ref, my $lemma_array_ref )= split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
        'category'      => 'lemma',
    );

    # Conditions may be imposed on the selection of tokens...
    ( $wordform_array_ref, $lemma_array_ref )= split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
        'category'      => 'lemma',
        'condition'     => {
            'tag'       => qr{^NNS?$},
        },
    );



=head1 DESCRIPTION

This module provides utility subroutines intended to facilitate the
use of a class derived from L<Lingua::Diversity>.

=head1 SUBROUTINES

=over 4

=item split_text()

Split a text into units (typically words), delete empty units, and return a
reference to the array of units.

The subroutine takes one required and one optional named parameter.

=over 4

=item text (required)

A reference to the text to be split.

=item regexp

A reference to a regular expression describing unit delimiter sequences.
Default is C<qr{\s+}>.

=back

=item split_tagged_text()

Given a L<Lingua::TreeTagger::TaggedText> object, return a reference to the
array of units (e.g. wordforms). Optionally, return a second reference to the
array of categories (e.g. lemmas).

The subroutine requires two named parameters and may take up to four of them.

=over 4

=item tagged_text (required)

The Lingua::TreeTagger::TaggedText object to be split.

=item unit (required)

The L<Lingua::TreeTagger::Token> attribute (either I<original>, I<lemma>, or
I<tag>) that should be used to build the unit array. NB: make sure the
requested attribute is available in the L<Lingua::TreeTagger::TaggedText>
object!

=item category

The L<Lingua::TreeTagger::Token> attribute (either I<lemma> or I<tag>) that
should be used to build the category array. NB: make sure the requested
attribute is available in the L<Lingua::TreeTagger::TaggedText> object!

=item condition

A reference to a hash specifying conditional inclusion or exclusion of tokens.
The hash may have a I<mode> key, a I<logical> key and up to three keys among
I<original>, I<lemma>, and I<tag>:

=over 4

=item mode

A string indicating whether the condition specifies which tokens should
be included (value I<include>) or excluded (value I<exclude>). Default
is I<include>.

=item logical

A string indicating whether the conditions set with the I<original>, I<lemma>,
and I<tag> keys (see below) must all be satisfied (value I<and>) or whether it
suffices that one of them be satisfied (value I<or>). Default is I<and>.

=item original

A regular expression specifying the I<original> attribute of tokens to be
in-/excluded.

=item lemma

A regular expression specifying the I<lemma> attribute of tokens to be
in-/excluded.

=item tag

A regular expression specifying the I<tag> attribute of tokens to be
in-/excluded.

=back

=back

=back

=head1 DIAGNOSTICS

=over 4

=item Missing parameter 'text' in call to subroutine split_text()

This exception is raised when subroutine C<split_text()> is called without a
parameter named I<text> (whose value should be a reference to a string).

=item Missing parameter 'tagged_text' in call to subroutine
split_tagged_text()

This exception is raised when subroutine C<split_tagged_text()> is called
without a parameter named I<tagged_text>.

=item Parameter 'tagged_text' in call to subroutine split_tagged_text()
must be a Lingua::TreeTagger::TaggedText object

This exception is raised when subroutine C<split_tagged_text()> is called
with a parameter named I<tagged_text> whose value is not a
L<Lingua::TreeTagger::TaggedText> object.

=item Missing parameter 'unit' in call to subroutine split_tagged_text()

This exception is raised when subroutine C<split_tagged_text()> is called
without a parameter named I<unit>.

=item Parameter 'unit' in call to subroutine split_tagged_text() must be
either 'original', 'lemma', or 'tag'

This exception is raised when subroutine C<split_tagged_text()> is called
with a parameter named I<unit> whose value is not I<original>, I<lemma>, or
I<tag>.

=item Parameter 'category' in call to subroutine split_tagged_text() must
be either 'lemma' or 'tag'

This exception is raised when subroutine C<split_tagged_text()> is called
with a parameter named I<category> whose value is not I<lemma> or I<tag>.

=item Key 'mode' of hash 'condition' in call to subroutine split_tagged_text()
must have value either 'include' or 'exclude'

This exception is raised when subroutine C<split_tagged_text()> is called
with a parameter named I<condition> referring to a hash whose key I<mode> has
another value than I<include> or I<exclude>.

=item Key 'logical' of hash 'condition' in call to subroutine
split_tagged_text() must have value either 'and' or 'or'

This exception is raised when subroutine C<split_tagged_text()> is called
with a parameter named I<condition> referring to a hash whose key I<mode> has
another value than I<and> or I<or>.

=back

=head1 DEPENDENCIES

This module is part of the L<Lingua::Diversity> distribution. Some subroutines
are designed to operate on L<Lingua::TreeTagger::TaggedText> objects.

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

L<Lingua::Diversity>, L<Lingua::TreeTagger>.

