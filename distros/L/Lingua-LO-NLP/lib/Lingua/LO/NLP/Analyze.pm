package Lingua::LO::NLP::Analyze;
use strict;
use warnings;
use 5.012000;
use utf8;
use feature qw/ unicode_strings say /;
use charnames qw/ :full lao /;
use version 0.77; our $VERSION = version->declare('v0.2.0');
use Carp;
use Class::Accessor::Fast 'antlers';
use Lingua::LO::NLP::Data ':all';

=encoding utf8

=head1 NAME

Lingua::LO::NLP::Analyze - Analyze a Lao syllable and provide accessors to its constituents

=head1 FUNCTION

Objects of this class represent a Lao syllable with an analysis of its
constituents. After passing a valid syllable to the constructor, the parts are
available via accessor methods as outlined below.

=cut

for my $attribute (qw/ syllable parse vowel consonant end_consonant vowel_length tone tone_mark h semivowel /) {
    has $attribute => (is => 'ro');
}

my %TONE_MARKS = (
    ""  => {
        SUNG => 'LOW_RISING',
        KANG => 'LOW',
        TAM  => 'HIGH',
    },
    "\N{LAO TONE MAI EK}" => {
        SUNG => 'MID',
        KANG => 'MID',
        TAM  => 'MID',
    },
    "\N{LAO TONE MAI THO}" => {
        SUNG => 'MID_FALLING',      # TODO: should this be LOW_FALLING?
        KANG => 'HIGH_FALLING',
        TAM  => 'HIGH_FALLING',
    },
    "\N{LAO TONE MAI TI}" => {
        # TODO: is this HIGH or HIGH_FALLING? Opinios seem to differ
        # and I haven't found a definitive source yet
        SUNG => 'HIGH',
        KANG => 'HIGH',
        TAM  => 'HIGH',
    },
    "\N{LAO TONE MAI CATAWA}" => {
        SUNG => 'LOW_RISING',
        KANG => 'LOW_RISING',
        TAM  => 'LOW_RISING',
    }
);

my %CONSONANTS = (
   'ກ'  => 'KANG',
   'ຂ'  => 'SUNG',
   'ຄ'  => 'TAM',
   'ງ'  => 'TAM',
   'ຈ'  => 'KANG',
   'ສ'  => 'SUNG',
   'ຊ'  => 'TAM',
   'ຍ'  => 'TAM',
   'ດ'  => 'KANG',
   'ຕ'  => 'KANG',
   'ຖ'  => 'SUNG',
   'ທ'  => 'TAM',
   'ນ'  => 'TAM',
   'ບ'  => 'KANG',
   'ປ'  => 'KANG',
   'ຜ'  => 'SUNG',
   'ຝ'  => 'SUNG',
   'ພ'  => 'TAM',
   'ຟ'  => 'TAM',
   'ມ'  => 'TAM',
   'ຢ'  => 'KANG',
   'ລ'  => 'TAM',
   'ວ'  => 'TAM',
   'ຫ'  => 'SUNG',
   'ອ'  => 'KANG',
   'ຮ'  => 'TAM',
   'ຣ'  => 'TAM',
   'ຫງ' => 'SUNG',
   'ຫຍ' => 'SUNG',
   'ຫນ' => 'SUNG',
   'ໜ'  => 'SUNG',
   'ຫມ' => 'SUNG',
   'ໝ'  => 'SUNG',
   'ຫລ' => 'SUNG',
   'ຫຼ'  => 'SUNG',
   'ຫວ' => 'SUNG',
);

my %CONS_H_MNL = ( 'ມ' => 'ໝ', 'ນ' => 'ໜ', 'ລ' => "\N{LAO SEMIVOWEL SIGN LO}" );

=head1 METHODS

=head2 new

C<new( $syllable, %options )>

The constructor takes a syllable and any number of options as hash-style
arguments. The only option specified so far is C<normalize>, a boolean value
indicating whether to run the syllable through tone mark normalization (see
L<Lingua::LO::NLP::Data/normalize_tone_marks>). It does not fail but may
produce nonsense if the argument is not valid according to Lao morphology
rules.

=cut

sub new {
    my $class = shift;
    my $syllable = shift;
    my %opts = @_;
    normalize_tone_marks($syllable) if $opts{normalize};
    return bless _classify($syllable), $class;
}

{
    my $regexp = get_sylre_named();

    sub _classify {
        my $s = shift // croak("`syllable' argument missing or undefined");

        $s =~ /^$regexp/ or croak("`$s' does not start with a valid syllable");
        my %class = ( syllable => $s, parse => { %+ } );
        (my $consonant, @class{qw/ end_consonant h semivowel tone_mark /}) = @+{qw/ consonant end_consonant h semivowel tone_mark /};

        my @vowels = $+{vowel0} // ();
        push @vowels, "\N{DOTTED CIRCLE}";
        push @vowels, grep { defined } @+{qw/ vowel1 vowel2 vowel3 /};
        $class{vowel} = join('', @vowels);

        my $cc = $CONSONANTS{ $consonant };  # consonant category
        if( $class{h} ) {
            $cc = 'SUNG'; # $CONSONANTS{'ຫ'}

            # If consonant is one of ມ, ນ or ລ *and* no vowel precedes the ຫ,
            # pretend we saw the combined form
            if(exists $CONS_H_MNL{ $consonant } and not $+{vowel0}) {
                $class{consonant} = $CONS_H_MNL{ $consonant };
                delete $class{h};
            } else {
                # If there is a preceding vowel, it uses the ຫ as a consonant and the
                # one parsed as core consonant is actually an end consonant
                unless($consonant eq 'ວ' or $consonant eq 'ຍ') {
                    $class{end_consonant} = $consonant;
                    $consonant = 'ຫ';
                    delete $class{h};
                }
            }
        }
        if(is_long_vowel( $class{vowel} )) {
            $class{vowel_length} = 'long';
            $class{tone} = $TONE_MARKS{ $class{tone_mark} // '' }{ $cc };
        } else {
            $class{vowel_length} = 'short';
            $class{tone} = $cc eq 'TAM' ? 'MID_STOP' : 'HIGH_STOP';
        }
        $class{consonant} = $consonant;
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

The syllable's core consonant

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

=head3 tone

One of the following strings, depending on core consonant class, vowel length and tone mark:

=over 4

=item LOW_RISING

=item LOW

=item HIGH

=item MID_FALLING

=item HIGH_FALLING

=item MID_STOP

=item HIGH_STOP

=back

The latter two occur with short vowels, the other ones with long vowels.

=cut

1;

