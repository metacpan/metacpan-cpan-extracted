#!/usr/bin/perl

package Lingua::Diversity::X;

use strict;
use warnings;
use Carp;

our $VERSION = 0.03;


#=============================================================================
# Exception declarations
#=============================================================================


use Exception::Class ( 

    # Lingua::Diversity exceptions...
    #--------------------------------

    'Lingua::Diversity::X' => {
        description => 'Lingua::Diversity exception',
    },

    'Lingua::Diversity::X::AbstractObject' => {
        isa         => 'Lingua::Diversity::X',
        description => 'Used abstract Lingua::Diversity object',
    },

    'Lingua::Diversity::X::AbstractMethod' => {
        isa         => 'Lingua::Diversity::X',
        description => 'Called abstract method',
        fields      => [ qw( class method ) ],
    },

        'Lingua::Diversity::X::ValidateSizeMissingParam' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'Missing parameter in call to _validate_size',
    },

    'Lingua::Diversity::X::ValidateSizeMissing1stArrayRef' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'Missing 1st array ref in call to _validate_size',
        fields      => [ qw( method ) ],
    },

    'Lingua::Diversity::X::ValidateSizeMissing2ndArrayRef' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'Missing 2nd array ref in call to _validate_size',
        fields      => [ qw( method ) ],
    },

    'Lingua::Diversity::X::ValidateSizeArrayTooSmall' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'validate_size spotted a too small array',
        fields      => [ qw( method num_items min_num_items ) ],
    },

    'Lingua::Diversity::X::ValidateSizeArrayTooLarge' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'validate_size spotted a too large array',
        fields      => [ qw( method num_items max_num_items ) ],
    },

    'Lingua::Diversity::X::ValidateSizeArraysOfDifferentSize' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'validate_size spotted unevenly sized arrays',
        fields      => [ qw( method num_units num_categories ) ],
    },

    # Lingua::Diversity::Internals exceptions...
    #-------------------------------------------

    'Lingua::Diversity::X::Internals' => {
        isa         => 'Lingua::Diversity::X',
        description => 'Lingua::Diversity::Internals exception',
    },


    'Lingua::Diversity::X::Internals::GetAverageEmptyArray' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'Empty array argument in call to _get_average',
    },

    'Lingua::Diversity::X::Internals::GetAverageArraysOfDifferentSize' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'Unevenly sized array arguments in call to '
                     . '_get_average',
    },

    'Lingua::Diversity::X::Internals::SampleIndicesSampleSizeTooLarge' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'Sample size too large in call to _sample_indices',
    },

    'Lingua::Diversity::X::Internals::RenyiEntropyInvalidExponent' => {
        isa         => 'Lingua::Diversity::X::Internals',
        description => 'Invalid exponent in call to _sample_indices',
    },

    # Lingua::Diversity::Utils exceptions...
    #---------------------------------------

    'Lingua::Diversity::X::Utils' => {
        isa         => 'Lingua::Diversity::X',
        description => 'Lingua::Diversity::Utils exception',
    },

    'Lingua::Diversity::X::Utils::SplitTextMissingParam' => {
        isa         => 'Lingua::Diversity::X::Utils',
        description => 'Missing parameter in call to split_text',
    },

    'Lingua::Diversity::X::Utils::SplitTaggedTextMissingTaggedTextParam' => {
        isa         => 'Lingua::Diversity::X::Utils',
        description => 'Missing parameter in call to split_tagged_text',
    },

    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongTaggedTextParamType' => {
        isa         => 'Lingua::Diversity::X::Utils',
        description => 'Wrong parameter type in call to split_tagged_text',
    },

    'Lingua::Diversity::X::Utils::SplitTaggedTextMissingUnitParam' => {
        isa         => 'Lingua::Diversity::X::Utils',
        description => 'Missing parameter in call to split_tagged_text',
    },

    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongUnitParam' => {
        isa         => 'Lingua::Diversity::X::Utils',
        description => 'Wrong parameter value in call to split_tagged_text',
    },

    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongCategoryParam' => {
        isa         => 'Lingua::Diversity::X::Utils',
        description => 'Wrong parameter value in call to split_tagged_text',
    },

    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongModeParam' => {
        isa         => 'Lingua::Diversity::X::Utils',
        description => 'Wrong parameter value in call to split_tagged_text',
    },

    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongLogicalParam' => {
        isa         => 'Lingua::Diversity::X::Utils',
        description => 'Wrong parameter value in call to split_tagged_text',
    },


);

# Enable exception tracing.
Lingua::Diversity::X->Trace(1);


#=============================================================================
# Redefine extended error messages
#=============================================================================


# Lingua::Diversity exceptions...
#--------------------------------

sub Lingua::Diversity::X::AbstractObject::full_message {
    my ( $self ) = @_;
    return 'Someone used an (abstract) Lingua::Diversity object';
}

sub Lingua::Diversity::X::AbstractMethod::full_message {
    my ( $self ) = @_;
    return 'Call to abstract method '
         . $self->class()
         . '::'
         . $self->method()
         ;
}

sub Lingua::Diversity::X::ValidateSizeMissingParam::full_message {
    my ( $self ) = @_;
    return q{Missing parameter 'unit_array_ref' in call to subroutine }
         . q{_validate_size()};
}

sub Lingua::Diversity::X::ValidateSizeMissing1stArrayRef::full_message {
    my ( $self ) = @_;
    return q{Method }
         . $self->method()
         . q{() must be called with a reference to an array as 1st argument}
}

sub Lingua::Diversity::X::ValidateSizeArrayTooSmall::full_message {
    my ( $self ) = @_;
    return q{Method }
         . $self->method()
         . q{() was called with an array containing }
         . $self->num_items()
         . q{ item(s) while this measure requires at least }
         . $self->min_num_items()
         . q{ item(s)};
}

sub Lingua::Diversity::X::ValidateSizeArrayTooLarge::full_message {
    my ( $self ) = @_;
    return q{Method }
         . $self->method()
         . q{() was called with an array containing }
         . $self->num_items()
         . q{ item(s) while this measure requires at most }
         . $self->max_num_items()
         . q{ item(s)};
}

sub Lingua::Diversity::X::ValidateSizeMissing2ndArrayRef::full_message {
    my ( $self ) = @_;
    return q{Method }
         . $self->method()
         . q{() must be called with a reference to an array as 2nd argument}
}

sub Lingua::Diversity::X::ValidateSizeArraysOfDifferentSize::full_message {
    my ( $self ) = @_;
    return q{Method }
         . $self->method()
         . q{() was called with arrays of unequal size: }
         . $self->num_units()
         . q{ unit(s) versus }
         . $self->num_categories()
         . q{ category(-ies)};
}

# Lingua::Diversity::Internals exceptions...
#-------------------------------------------

sub Lingua::Diversity::X::Internals::GetAverageEmptyArray::full_message {
    my ( $self ) = @_;
    return q{Subroutine '_get_average' was called with an empty array }
         . q{reference as argument}
}

sub Lingua::Diversity::X::Internals::GetAverageArraysOfDifferentSize::full_message {
    my ( $self ) = @_;
    return q{Subroutine '_get_average' was called with references to arrays }
         . q{of unequal size}
}

sub Lingua::Diversity::X::Internals::SampleIndicesSampleSizeTooLarge::full_message {
    my ( $self ) = @_;
    return q{The second argument of subroutine _sampled_indices() cannot be }
         . q{larger than the first}
}

sub Lingua::Diversity::X::Internals::RenyiEntropyInvalidExponent::full_message {
    my ( $self ) = @_;
    return q{Parameter 'exponent' of subroutine _renyi_entropy() must be }
         . q{between 0 and 1 inclusive}
}

# Lingua::Diversity::Utils exceptions...
#-------------------------------------------

sub Lingua::Diversity::X::Utils::SplitTextMissingParam::full_message {
    my ( $self ) = @_;
    return q{Missing parameter 'text' in call to subroutine split_text()};
}

sub Lingua::Diversity::X::Utils::SplitTextMissingTaggedTextParam::full_message {
    my ( $self ) = @_;
    return q{Missing parameter 'tagged_text' in call to subroutine }
         . q{split_tagged_text()};
}

sub Lingua::Diversity::X::Utils::SplitTextWrongTaggedTextParamType::full_message {
    my ( $self ) = @_;
    return q{Parameter 'tagged_text' in call to subroutine }
         . q{split_tagged_text() must be a Lingua::TreeTagger::TaggedText }
         . q{object};
}

sub Lingua::Diversity::X::Utils::SplitTextMissingUnitParam::full_message {
    my ( $self ) = @_;
    return q{Missing parameter 'unit' in call to subroutine }
         . q{split_tagged_text()};
}

sub Lingua::Diversity::X::Utils::SplitTaggedTextWrongUnitParam::full_message {
    my ( $self ) = @_;
    return q{Parameter 'unit' in call to subroutine split_tagged_text() }
         . q{must be either 'original', 'lemma', or 'tag'};
}

sub Lingua::Diversity::X::Utils::SplitTaggedTextWrongCategoryParam::full_message {
    my ( $self ) = @_;
    return q{Parameter 'category' in call to subroutine split_tagged_text() }
         . q{must be either 'lemma' or 'tag'};
}

sub Lingua::Diversity::X::Utils::SplitTaggedTextWrongModeParam::full_message {
    my ( $self ) = @_;
    return q{Key 'mode' of hash 'condition' in call to subroutine }
         . q{split_tagged_text() must have value either 'include' or }
         . q{'exclude'};
}

sub Lingua::Diversity::X::Utils::SplitTaggedTextWrongLogicalParam::full_message {
    my ( $self ) = @_;
    return q{Key 'logical' of hash 'condition' in call to subroutine }
         . q{split_tagged_text() must have value either 'and' or 'or'};
}


1;


__END__


=head1 NAME

Lingua::Diversity::X - exception classes for Lingua::Diversity

=head1 VERSION

This documentation refers to Lingua::Diversity:X version 0.03.

=head1 DESCRIPTION

This module provides OO-based exceptions for the Lingua::Diversity
distribution.

=head1 DEPENDENCIES

This module is part of the Lingua::Diversity distribution. It uses
L<Exception::Class>.

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

