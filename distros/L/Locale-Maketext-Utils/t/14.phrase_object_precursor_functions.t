use Test::More;

use Locale::Maketext::Utils::Phrase;

my %tests = (
    'Hello World' => {
        'name'                         => 'Simple String',
        'has_bracket_notation'         => 0,
        'is_entirely_bracket_notation' => 0,
        'struct'                       => [
            'Hello World',
        ],
    },
    'Hello [_1] World' => {
        'name'                         => 'Simple Has Bracket Notation',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'struct'                       => [
            'Hello ',
            {
                'orig' => '[_1]',
                'cont' => '_1',
                'list' => [
                    '_1'
                ],
                'type' => 'var',
            },
            ' World',
        ],
    },
    'This is [] empty bad.' => {
        'name'                         => 'Empty Bracket Notation',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'struct'                       => [
            'This is ',
            {
                'orig' => '[]',
                'cont' => '',
                'list' => [],
                'type' => '_invalid',
            },
            ' empty bad.',
        ],
    },
    '[output,strong,Howdy]' => {
        'name'                         => 'Simple All Bracket Notation',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 1,
        'struct'                       => [
            {
                'orig' => '[output,strong,Howdy]',
                'cont' => 'output,strong,Howdy',
                'list' => [
                    'output',
                    'strong',
                    'Howdy',
                ],
                'type' => 'basic',
            },
        ],
    },

    # Unbalanced:
    'Hello left [ bar' => {
        'name'                         => 'hanging left plain',
        'has_bracket_notation'         => 0,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello right ] bar' => {
        'name'                         => 'hanging right plain',
        'has_bracket_notation'         => 0,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello ] both [ bar' => {
        'name'                         => 'hanging left/right plain',
        'has_bracket_notation'         => 0,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [_1] left [ bar [_2]' => {
        'name'                         => 'hanging left BN',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [_1] right ] bar [_2]' => {
        'name'                         => 'hanging right BN',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [output,strong,foo[] bar' => {
        'name'                         => 'nested hanging left',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [output,strong,foo]] bar' => {
        'name'                         => 'nested hanging right',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [output,strong,[_2]] foo' => {
        'name'                         => 'nested pair',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello left [ bar Hello left [ bar' => {
        'name'                         => 'hanging left plain MULTI',
        'has_bracket_notation'         => 0,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello right ] bar Hello right ] bar' => {
        'name'                         => 'hanging right plain MULTI',
        'has_bracket_notation'         => 0,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello ] both [ bar Hello ] both [ bar' => {
        'name'                         => 'hanging left/right plain MULTI',
        'has_bracket_notation'         => 0,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [_1] left [ bar [_2] Hello [_1] left [ bar [_2]' => {
        'name'                         => 'hanging left BN MULTI',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [_1] right ] bar [_2] Hello [_1] right ] bar [_2]' => {
        'name'                         => 'hanging right BN MULTI',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [output,strong,foo[] bar Hello [output,strong,foo[] bar' => {
        'name'                         => 'nested hanging left MULTI',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [output,strong,foo]] bar Hello [output,strong,foo]] bar' => {
        'name'                         => 'nested hanging right MULTI',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
    'Hello [output,strong,[_2]] foo Hello [output,strong,[_2]] foo' => {
        'name'                         => 'nested pair MULTI',
        'has_bracket_notation'         => 1,
        'is_entirely_bracket_notation' => 0,
        'unbalanced_bracket'           => 1,
    },
);

plan tests => ( ( keys %tests ) * 6 );

for my $phrase ( sort keys %tests ) {
    my $name = $tests{$phrase}->{'name'};
    my $struct;
    if ( $tests{$phrase}->{'unbalanced_bracket'} ) {
        eval { $struct = Locale::Maketext::Utils::Phrase::phrase2struct($phrase); };

        diag explain( [ $phrase, $struct ] ) if !$@;    # parsing missed unbalanced so lets get some info to help find out why

        like( $@, qr/Unbalanced bracket/, "Unbalanced bracket is fatal: $name" );
      SKIP: {
            skip "Skipping phrase tests that do not apply to unbalanced bracket failures.", 5;
        }
        next;
    }
    else {
        $struct = Locale::Maketext::Utils::Phrase::phrase2struct($phrase);
        is_deeply( $struct, $tests{$phrase}->{'struct'}, "structure is correct: $name" );
    }

    is(
        Locale::Maketext::Utils::Phrase::phrase_has_bracket_notation($phrase),
        Locale::Maketext::Utils::Phrase::struct_has_bracket_notation($struct),
        "phrase/struct has_bracket_notation() match: $name"
    );
    if ( $tests{$phrase}->{'has_bracket_notation'} ) {
        ok( Locale::Maketext::Utils::Phrase::phrase_has_bracket_notation($phrase), "*has_bracket_notation() is correct, true, value: $name" );
    }
    else {
        ok( !Locale::Maketext::Utils::Phrase::phrase_has_bracket_notation($phrase), "*has_bracket_notation() is correct, false, value: $name" );
    }

    is(
        Locale::Maketext::Utils::Phrase::phrase_is_entirely_bracket_notation($phrase),
        Locale::Maketext::Utils::Phrase::struct_is_entirely_bracket_notation($struct),
        "phrase/struct is_entirely_bracket_notation() match: $name"
    );
    if ( $tests{$phrase}->{'is_entirely_bracket_notation'} ) {
        ok( Locale::Maketext::Utils::Phrase::phrase_is_entirely_bracket_notation($phrase), "*is_entirely_bracket_notation() is correct, true, value: $name" );
    }
    else {
        ok( !Locale::Maketext::Utils::Phrase::phrase_is_entirely_bracket_notation($phrase), "*is_entirely_bracket_notation() is correct, false, value: $name" );
    }

    is( Locale::Maketext::Utils::Phrase::struct2phrase($struct), $phrase, "phrase is correct: $name" );
}
