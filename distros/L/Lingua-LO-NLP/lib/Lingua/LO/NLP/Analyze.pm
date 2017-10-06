package Lingua::LO::NLP::Analyze;
use strict;
use warnings;
use 5.012000;
use utf8;
use feature qw/ unicode_strings say /;
use charnames qw/ :full lao /;
use version 0.77; our $VERSION = version->declare('v1.0.1');
use Unicode::Normalize 'NFC';
use Carp;
use Class::Accessor::Fast 'antlers';
use Lingua::LO::NLP::Data ':all';

use constant SUNG => 0; # "high class"
use constant KANG => 1; # "middle class"
use constant TAM  => 2; # "low class"

=encoding utf8

=head1 NAME

Lingua::LO::NLP::Analyze - Analyze a Lao syllable and provide accessors to its constituents

=head1 FUNCTION

Objects of this class represent a Lao syllable with an analysis of its
constituents. After passing a valid syllable to the constructor, the parts are
available via accessor methods as outlined below.

=cut

for my $attribute (qw/ syllable parse vowel consonant end_consonant vowel_length tone tone_mark h semivowel live /) {
    has $attribute => (is => 'ro');
}

# This is a 2-level lookup table. The first level is the tone mark, the second
# is the consonant class (SUNG/KANG/TAM, see constant definitions)
my %TONE_MARKS = (
    "\N{LAO TONE MAI EK}"     => [ qw/ MID MID MID / ],
    "\N{LAO TONE MAI THO}"    => [ qw/ MID_FALLING HIGH_FALLING HIGH_FALLING / ],
    # TODO: is this HIGH or HIGH_FALLING? Opinions seem to differ
    # and I haven't found a definitive source yet
    "\N{LAO TONE MAI TI}"     => [ qw/ HIGH HIGH HIGH / ],
    "\N{LAO TONE MAI CATAWA}" => [ qw/ RISING RISING RISING /],
);

# This is a 2-level lookup table. The first level is the consonant class
# (SUNG/KANG/TAM, see constant definitions), the second is an index as
# calculated in classify(): 0 for live, 1 for dead+short, 2 for dead+long
my @TONE_NOMARK = (
    [qw/ RISING HIGH MID_FALLING /],  # SUNG/high
    [qw/ LOW HIGH MID_FALLING /],         # KANG/mid
    [qw/ HIGH MID HIGH_FALLING /],        # TAM/low
);

my %CONSONANTS = (
   'ກ'  => KANG,
   'ຂ'  => SUNG,
   'ຄ'  => TAM,
   'ງ'  => TAM,
   'ຈ'  => KANG,
   'ສ'  => SUNG,
   'ຊ'  => TAM,
   'ຍ'  => TAM,
   'ດ'  => KANG,
   'ຕ'  => KANG,
   'ຖ'  => SUNG,
   'ທ'  => TAM,
   'ນ'  => TAM,
   'ບ'  => KANG,
   'ປ'  => KANG,
   'ຜ'  => SUNG,
   'ຝ'  => SUNG,
   'ພ'  => TAM,
   'ຟ'  => TAM,
   'ມ'  => TAM,
   'ຢ'  => KANG,
   'ລ'  => TAM,
   'ວ'  => TAM,
   'ຫ'  => SUNG,
   'ອ'  => KANG,
   'ຮ'  => TAM,
   'ຣ'  => TAM,
   'ຫງ' => SUNG,
   'ຫຍ' => SUNG,
   'ຫນ' => SUNG,
   'ໜ'  => SUNG,
   'ຫມ' => SUNG,
   'ໝ'  => SUNG,
   'ຫລ' => SUNG,
   'ຫຼ'  => SUNG,
   'ຫວ' => SUNG,
);

my %CONS_H_MNL = ( 'ມ' => 'ໝ', 'ນ' => 'ໜ', 'ລ' => "\N{LAO SEMIVOWEL SIGN LO}" );
my %ENDCONS_STOP = ( 'ກ' => 1, 'ດ' => 1, 'ບ' => 1 );

=head1 METHODS

=head2 new

C<new( $syllable, %options )>

The constructor takes a syllable and any number of options as hash-style
arguments. The only option specified so far is C<normalize>, a boolean value
indicating whether to run the syllable through
L<Unicode::Normalize::NFC|Unicode::Normalize/NFC> and tone mark normalization
(see L<Lingua::LO::NLP::Data/normalize_tone_marks>). Set this if you are unsure
that your text is well-formed according to Unicode rules.

=cut

sub new {
    my $class = shift;
    my $syllable = shift;
    my %opts = @_;
    if($opts{normalize}) {
        $syllable = NFC($syllable);
        normalize_tone_marks($syllable);
    }
    return bless _classify($syllable), $class;
}

{
    my $regexp = get_sylre_named();

    sub _classify {
        my $s = shift // croak("`syllable' argument missing or undefined");

        $s =~ /^$regexp/ or croak("`$s' does not start with a valid syllable");

        my %class = (
            syllable => $s,
            parse => { %+ }
        );

        (my $consonant, my $end_consonant, @class{qw/ h semivowel tone_mark /}) =
        @+{qw/ consonant end_consonant h semivowel tone_mark /};

        my @vowels = $+{vowel0} // ();
        push @vowels, "\N{DOTTED CIRCLE}";
        push @vowels, grep { defined } @+{qw/ vowel1 vowel2 vowel3 /};
        $class{vowel} = join('', @vowels);

        my $cc = $CONSONANTS{ $consonant };  # consonant category
        if( $class{h} ) {
            $cc = SUNG; # $CONSONANTS{'ຫ'}

            # If consonant is one of ມ, ນ or ລ *and* no vowel precedes the ຫ,
            # pretend we saw the combined form
            if(exists $CONS_H_MNL{ $consonant } and not $+{vowel0}) {
                $class{consonant} = $CONS_H_MNL{ $consonant };
                delete $class{h};
            } else {
                # If there is a preceding vowel, it uses the ຫ as a consonant and the
                # one parsed as core consonant is actually an end consonant
                unless($consonant eq 'ວ' or $consonant eq 'ຍ') {
                    $end_consonant = $consonant;
                    $consonant = 'ຫ';
                    delete $class{h};
                }
            }
        }

        # Set both $class{vowel_length} and a quick flag that we'll need later
        my $long_vowel = 1;
        if(is_long_vowel( $class{vowel} )) {
            $class{vowel_length} = 'long';
        } else {
            $class{vowel_length} = 'short';
            $long_vowel = 0;
        }

        # Determine syllable liveness.
        my $live;
        if( defined $end_consonant ) {
            # If we have an end consonant, a syllable is considered live if the
            # former is not a stopped consonant
            $live = exists $ENDCONS_STOP{ $end_consonant } ? 0 : 1;
        } else {
            # Syllables without an end consonant are live iff the vowel is long
            $live = $long_vowel;
        }
        $class{live} = $live;

        if(defined $class{tone_mark}) {
            # If a tone mark exists, it and the consonant's class
            # determine the tone
            $class{tone} = $TONE_MARKS{ $class{tone_mark} }[$cc];
        } else {
            # No tone mark, so calculate the index
            $class{tone} = $TONE_NOMARK[$cc][ $live ? 0 : $long_vowel + 1 ];
        }
        $class{consonant} = $consonant;
        $class{end_consonant} = $end_consonant if defined $end_consonant;
        #say Dumper(\%class);
        return \%class;
    }
}

=head2 ACCESSORS


=head3 syllable

The original syllable as used by the parser. This may be subtly different from
the one passed to the constructor:

=over 4

=item

If the C<normalize> option was set, tone marks and vowels may have been reordered

=item

If the decomposed form of LAO VOWEL SIGN AM (◌າ) is used, it will have been
converted to the composed form

=item

Combinations of ຫ with ລ, ມ or ນ will have been converted to the combined characters.

=back

=head3 parse

A hash of raw constituents as returned by the parsing regexp. Although the
other accessors present constituents in a more accessible way and take care of
morphological special cases like the treatment of ຫ, this may come in handy to
quickly check e.g. if there was a vowel component before the core consonant.

=head3 vowel

The syllable's vowel or diphthong. As the majority of vowels have more than one
code point, the consonant position is represented by the Unicode character
designated for this function, DOTTED CIRCLE or U+25CC.

=head3 consonant

The syllable's core consonant.

=head3 end_consonant

The end consonant if present, C<undef> otherwise.

=head3 tone_mark

The tone mark if present, C<undef> otherwise.

=head3 semivowel

The semivowel following the core consonant if present, C<undef> otherwise.

=head3 h

"ຫ" if the syllable contained a combining ຫ, i.e. one that isn't the core consonant.

=head3 vowel_length

The string 'long' or 'short'.

=head3 live

Boolean indicating whether this is a "live" or a "dead" syllable. Dead
syllables end in a short vowel or stopped consonant (ກ, ດ or ບ), lives ones end
in a long vowel, diphthong, semivowel or nasal consonant. This is used for tone
determination but also available as an attribute, just in case it might be
useful. C<true> indicates a live syllable.

=head3 tone

One of the following strings, depending on core consonant class, vowel length and tone mark:

=over 4

=item LOW_RISING

=item LOW

=item MID

=item HIGH

=item MID_FALLING

=item HIGH_FALLING

=back

The latter two occur with short vowels, the other ones with long vowels.

=cut

1;

