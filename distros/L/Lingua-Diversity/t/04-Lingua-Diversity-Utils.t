#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;

# Module is usable...
BEGIN {
    use_ok( 'Lingua::Diversity::Utils', qw(
        split_text
        split_tagged_text
    ) )
      || print "Bail out!\n";
}

# Subroutine split_text requires parameter 'text'...
eval { split_text() };
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTextMissingParam',
    'Subroutine split_text() correctly croaks when called without '
 . q{parameter 'text'}
);

my $text = 'of the people, by the people, for the people';

# Get a reference to an array of words...
my $word_array_ref = split_text(
    'text'      => \$text,
    'regexp'    => qr{[^a-zA-Z]+},
);

# Subroutine split_text() correctly splits text...
ok(
       $word_array_ref->[0] eq 'of'
    && $word_array_ref->[1] eq 'the'
    && $word_array_ref->[2] eq 'people'
    && $word_array_ref->[3] eq 'by'
    && $word_array_ref->[4] eq 'the'
    && $word_array_ref->[5] eq 'people'
    && $word_array_ref->[6] eq 'for'
    && $word_array_ref->[7] eq 'the'
    && $word_array_ref->[8] eq 'people',
    'Subroutine split_text() correctly splits text'
);

# Subroutine split_tagged_text requires parameter 'unit'...
eval { split_tagged_text() };
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextMissingUnitParam',
    'Subroutine split_tagged_text() correctly croaks when called without '
 . q{parameter 'unit'}
);

# Parameter 'unit' must be either 'original', 'lemma', or 'tag'...
eval { split_tagged_text( 'unit' => 'word' ) };
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongUnitParam',
    'Subroutine split_tagged_text() correctly croaks when called with '
 . q{illegal value for parameter 'unit'}
);

# Subroutine split_tagged_text requires parameter 'tagged_text'...
eval { split_tagged_text( 'unit' => 'original' ) };
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextMissingTaggedTextParam',
    'Subroutine split_tagged_text() correctly croaks when called without '
 . q{parameter 'tagged_text'}
);

# Parameter 'tagged_text' must be a Lingua::TreeTagger::TaggedText...
eval {
    split_tagged_text(
        'unit'          => 'original',
        'tagged_text'   => 1,
    )
};
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongTaggedTextParamType',
    'Subroutine split_tagged_text() correctly croaks when call with a '
 . q{parameter 'tagged_text' that is not a Lingua::TreeTagger::TaggedText}
);

# Parameter 'category' must be either 'lemma' or 'tag'...
my $mock_tagged_text = {};
bless $mock_tagged_text, 'Lingua::TreeTagger::TaggedText';
eval {
    split_tagged_text(
        'unit'          => 'original',
        'tagged_text'   => $mock_tagged_text,
        'category'      => 'root',
    )
};
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongCategoryParam',
    'Subroutine split_tagged_text() correctly croaks when called with '
 . q{illegal value for parameter 'category'}
);

# Key 'mode' of parameter 'condition' must be either 'include' or 'exclude'...
eval {
    split_tagged_text(
        'unit'          => 'original',
        'tagged_text'   => $mock_tagged_text,
        'condition'     => {
            'mode'      => 'illegal value',
        },
    )
};
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongModeParam',
    'Subroutine split_tagged_text() correctly croaks when called with '
 . q{illegal value for key 'mode' of parameter 'condition'}
);

# Key 'logical' of parameter 'condition' must be either 'and' or 'or'...
eval {
    split_tagged_text(
        'unit'          => 'original',
        'tagged_text'   => $mock_tagged_text,
        'condition'     => {
            'logical'      => 'illegal value',
        },
    )
};
is(
    ref $@,
    'Lingua::Diversity::X::Utils::SplitTaggedTextWrongLogicalParam',
    'Subroutine split_tagged_text() correctly croaks when called with '
 . q{illegal value for key 'logical' of parameter 'condition'}
);

SKIP: {
    eval { require Lingua::TreeTagger };

    skip "Lingua::TreeTagger not installed", 10 if $@;

    # Get a tagged text
    my $tagger = Lingua::TreeTagger->new(
        'language' => 'english',
        'options'  => [ qw( -token -lemma -no-unknown ) ],
    );
    my $tagged_text = $tagger->tag_text( \$text );

    # Get the first token...
    my $token = $tagged_text->sequence()->[0];
    
    my $condition_ref = {
        'mode'      => 'include',
        'logical'   => 'and',
        'original'  => qr/^of$/,
        'tag'       => qr/^NN$/,
    };
    
    # Subroutine _should_skip skips correctly ('include'+'and')...
    is(
        Lingua::Diversity::Utils::_should_skip( $condition_ref, $token ),
        1,
        q{Subroutine _should_skip skips correctly ('include'+'and')}
    );

    # Subroutine _should_skip correctly avoids skipping ('include'+'and')...
    delete $condition_ref->{'original'};
    $condition_ref->{'lemma'}       = 'of';
    $condition_ref->{'tag'}         = 'IN';
    is(
        Lingua::Diversity::Utils::_should_skip( $condition_ref, $token ),
        0,
        q{Subroutine _should_skip correctly avoids skipping ('include'+'and')}
    );

    # Subroutine _should_skip skips correctly ('exclude'+'and')...
    $condition_ref->{'mode'}        = 'exclude';
    $condition_ref->{'original'}    = 'of';
    $condition_ref->{'lemma'}       = 'of';
    delete $condition_ref->{'tag'};
    is(
        Lingua::Diversity::Utils::_should_skip( $condition_ref, $token ),
        1,
        q{Subroutine _should_skip skips correctly ('exclude'+'and')}
    );

    # Subroutine _should_skip correctly avoids skipping ('exclude'+'and')...
    delete $condition_ref->{'original'};
    delete $condition_ref->{'lemma'};
    delete $condition_ref->{'tag'};
    is(
        Lingua::Diversity::Utils::_should_skip( $condition_ref, $token ),
        0,
        q{Subroutine _should_skip correctly avoids skipping ('exclude'+'and')}
    );

    # Subroutine _should_skip skips correctly ('include'+'or')...
    $condition_ref->{'logical'}     = 'or';
    $condition_ref->{'mode'}        = 'include';
    $condition_ref->{'original'}    = 'for';
    $condition_ref->{'lemma'}       = 'for';
    is(
        Lingua::Diversity::Utils::_should_skip( $condition_ref, $token ),
        1,
        q{Subroutine _should_skip skips correctly ('include'+'or')}
    );

    # Subroutine _should_skip correctly avoids skipping ('include'+'or')...
    $condition_ref->{'original'}    = 'of';
    delete $condition_ref->{'lemma'};
    $condition_ref->{'tag'}         = 'NN';
    is(
        Lingua::Diversity::Utils::_should_skip( $condition_ref, $token ),
        0,
        q{Subroutine _should_skip correctly avoids skipping ('include'+'or')}
    );

    # Subroutine _should_skip skips correctly ('exclude'+'or')...
    $condition_ref->{'mode'}        = 'exclude';
    delete $condition_ref->{'original'};
    $condition_ref->{'lemma'}       = 'for';
    $condition_ref->{'tag'}         = 'IN';
    is(
        Lingua::Diversity::Utils::_should_skip( $condition_ref, $token ),
        1,
        q{Subroutine _should_skip skips correctly ('exclude'+'or')}
    );

    # Subroutine _should_skip correctly avoids skipping ('exclude'+'or')...
    delete $condition_ref->{'original'};
    delete $condition_ref->{'lemma'};
    delete $condition_ref->{'tag'};
    is(
        Lingua::Diversity::Utils::_should_skip( $condition_ref, $token ),
        0,
        q{Subroutine _should_skip correctly avoids skipping ('exclude'+'or')}
    );

    # Get a reference to an array of words (without commas)...
    my $word_array_ref = split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
        'condition'     => {
            'mode'      => 'exclude',
            'original'  => qr{^,$},
        },
    );

    # Subroutine split_tagged_text() correctly splits text (1 array)...
    ok(
        _compare_arrays(
            $word_array_ref,
            [ qw( of the people by the people for the people ) ],
        ),
        'Subroutine split_tagged_text() correctly splits text (1 array)'
    );

    # Get a reference to an array of words and an array of POS tags
    # (remove commas)...
    ( $word_array_ref, my $category_array_ref ) = split_tagged_text(
        'tagged_text'   => $tagged_text,
        'unit'          => 'original',
        'category'      => 'tag',
        'condition'     => {
            'mode'      => 'include',
            'original'  => qr{^[^,]+$},
        },
    );

    # Subroutine split_tagged_text() correctly splits text (2 arrays)...
    ok(
        _compare_arrays(
            $word_array_ref,
            [ qw( of the people by the people for the people ) ],
        )
        && _compare_arrays(
            $category_array_ref,
            [ qw( IN DT NNS IN DT NNS IN DT NNS ) ],
        ),
        'Subroutine split_tagged_text() correctly splits text (2 arrays)'
    );
}


#-----------------------------------------------------------------------------
# Subroutine _compare_arrays
#-----------------------------------------------------------------------------
# Synopsis:      Compare two arrays and return 1 if they're identical or
#                0 otherwise.
# Arguments:     - two array references
# Return values: - 0 or 1.
#-----------------------------------------------------------------------------

sub _compare_arrays {
    my ( $first_array_ref, $second_array_ref ) = @_;
    return 0 if @$first_array_ref != @$second_array_ref;
    foreach my $index ( 0..@$first_array_ref-1 ) {
        return 0 if    $first_array_ref->[$index]
                    ne $second_array_ref->[$index];
    }
    return 1;
}


