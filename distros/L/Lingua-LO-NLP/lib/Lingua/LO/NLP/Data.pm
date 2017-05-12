package Lingua::LO::NLP::Data;
use strict;
use warnings;
use 5.012000;
use utf8;
use feature 'unicode_strings';
use version 0.77; our $VERSION = version->declare('v0.2.0');
use charnames qw/ :full lao /;
use parent 'Exporter';

=encoding utf8

=head1 NAME

Lingua::LO::NLP::Data - Helper module to keep common read-only data

=head1 FUNCTION

Provides a few functions that return regular expressions for matching and
extracting parts from Lao syllables. Instead of hardcoding these expressions as
strings, they are constructed from fragments at runtime, trading maintainability
for a small one-time initialization cost.

Also holds common read-only data such as vowel classifications.

You will probably not want to use this module on its own. If you do, see the
other L<Lingua::LO::NLP> modules for examples.

=cut

our %EXPORT_TAGS = (
    all => [ qw/
        get_sylre_basic get_sylre_full get_sylre_named is_long_vowel
        normalize_tone_marks
        /
    ]
);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} };

# Character classes
my $TONE_MARKS = "\N{LAO TONE MAI EK}\N{LAO TONE MAI THO}" .
"\N{LAO TONE MAI TI}\N{LAO TONE MAI CATAWA}";

my $CONSONANTS = "\N{LAO LETTER KO}\N{LAO LETTER KHO SUNG}\N{LAO LETTER KHO TAM}" .
"\N{LAO LETTER NGO}\N{LAO LETTER CO}\N{LAO LETTER SO TAM}\N{LAO LETTER NYO}" .
"\N{LAO LETTER DO}\N{LAO LETTER TO}\N{LAO LETTER THO SUNG}\N{LAO LETTER THO TAM}" .
"\N{LAO LETTER NO}\N{LAO LETTER BO}\N{LAO LETTER PO}\N{LAO LETTER PHO SUNG}" .
"\N{LAO LETTER FO TAM}\N{LAO LETTER PHO TAM}\N{LAO LETTER FO SUNG}" .
"\N{LAO LETTER MO}\N{LAO LETTER YO}\N{LAO LETTER LO LING}\N{LAO LETTER LO LOOT}" .
"\N{LAO LETTER WO}\N{LAO LETTER SO SUNG}\N{LAO LETTER HO SUNG}\N{LAO LETTER O}" .
"\N{LAO LETTER HO TAM}";

my $VOWELS_COMBINING = "\N{LAO VOWEL SIGN MAI KAN}" .
"\N{LAO VOWEL SIGN AM}\N{LAO VOWEL SIGN I}\N{LAO VOWEL SIGN II}" .
"\N{LAO VOWEL SIGN Y}\N{LAO VOWEL SIGN YY}\N{LAO VOWEL SIGN U}" .
"\N{LAO VOWEL SIGN UU}\N{LAO VOWEL SIGN MAI KON}\N{LAO NIGGAHITA}";

my $VOWELS = "\N{LAO VOWEL SIGN A}\N{LAO VOWEL SIGN MAI KAN}\N{LAO VOWEL SIGN AA}" .
"\N{LAO VOWEL SIGN AM}\N{LAO VOWEL SIGN I}\N{LAO VOWEL SIGN II}" .
"\N{LAO VOWEL SIGN Y}\N{LAO VOWEL SIGN YY}\N{LAO VOWEL SIGN U}" .
"\N{LAO VOWEL SIGN UU}\N{LAO VOWEL SIGN MAI KON}\N{LAO SEMIVOWEL SIGN LO}" .
"\N{LAO SEMIVOWEL SIGN NYO}\N{LAO VOWEL SIGN E}\N{LAO VOWEL SIGN EI}" .
"\N{LAO VOWEL SIGN O}\N{LAO VOWEL SIGN AY}\N{LAO VOWEL SIGN AI}" .
"\N{LAO NIGGAHITA}";

# Regular expression fragments. The cryptic names correspond to the naming
# in PHISSAMAY et al: Syllabification of Lao Script for Line Breaking
# Using what looks like interpolated variables in single-quoted strings is
# intentional; the interpolation is done manually later to be able to construct
# expressions with and without named captures.
my %regexp_fragments = (
    x0_1    => 'ເ',
    x0_2    => 'ແ',
    x0_3    => 'ໂ',
    x0_4    => 'ໄ',
    x0_5    => 'ໃ',

    x1      => 'ຫ',

    x       => '[ກຂຄງຈສຊຍດຕຖທນບປຜຝພຟມຢຣລວຫອຮໜໝ]',

    x2      => "[\N{LAO SEMIVOWEL SIGN LO}ຣວລ]",

    x3      => "[\N{LAO VOWEL SIGN U}\N{LAO VOWEL SIGN UU}]",

    x4_12   => "[\N{LAO VOWEL SIGN I}\N{LAO VOWEL SIGN II}]",
    x4_34   => "[\N{LAO VOWEL SIGN Y}\N{LAO VOWEL SIGN YY}]",
    x4_5    => "\N{LAO NIGGAHITA}",
    x4_6    => "\N{LAO VOWEL SIGN MAI KON}",
    x4_7    => "\N{LAO VOWEL SIGN MAI KAN}",
    x4_1t4  => "[\N{LAO VOWEL SIGN I}\N{LAO VOWEL SIGN II}\N{LAO VOWEL SIGN Y}\N{LAO VOWEL SIGN YY}]",

    x5      => "[$TONE_MARKS]",

    x6_1    => 'ວ',
    x6_2    => 'ອ',
    x6_3    => 'ຽ',
    x6      => '[ວອຽ]',

    x7_1    => 'ະ',
    x7_2    => 'າ',
    x7_3    => "\N{LAO VOWEL SIGN AM}",

    x8_3t8  => '[ຍດນມຢບ]',
    x8      => '[ກງຍດນມຢບວ]',

    x9      => '[ຈສຊພຟລ]',

    x10_12  => '[ຯໆ]',
    x10_3   => "\N{LAO CANCELLATION MARK}",

    x9a10_3 => '(?: $x9 $x10_3)',
);
my $re1_all = '$x0_1 $x1? $x $x2?';
my $re1_1   = '$x5? $x8? $x9a10_3?';
my $re1_2   = '$x4_12 $x5? $x8? $x9a10_3?';
my $re1_3   = '$x4_34 $x5? $x6_2 $x8? $x9a10_3?';
my $re1_4   = '$x7_2? $x7_1';
my $re1_5   = '$x4_6 $x5? $x7_2';
my $re1_6   = '$x4_7 $x5? $x8  $x9a10_3?';
my $re1_8   = '$x4_7? $x5? $x6_3';

my $re2_all = '$x0_2 $x1? $x $x2?';
my $re2_1   = '$x5? $x6? $x8? $x9a10_3?';
my $re2_2   = '$x7_1';
my $re2_3   = '$x4_7 $x5? $x8 $x9a10_3?';

my $re3_all = '$x0_3 $x1? $x $x2?';
my $re3_1   = '$x5? $x8? $x9a10_3?';
my $re3_2   = '$x7_1';
my $re3_3   = '$x4_7 $x5? $x8_3t8?';

my $re4     = '$x0_4 $x1? $x $x2? $x5? $x6_1? $x9a10_3?';

my $re5     = '$x0_5 $x1? $x $x2? $x5? $x6_1?';

my $re6     = '$x1? $x $x2? $x3 $x5? $x8? $x9a10_3?';

my $re7     = '$x1? $x $x2? $x4_1t4 $x5? $x8? $x9a10_3?';

my $re8     = '$x1? $x $x2? $x4_5 $x5? $x7_2? $x9a10_3?';

my $re9     = '$x1? $x $x2? $x4_6 $x5? (?: $x8 $x9a10_3? | $x6_1 $x7_1 )';

my $re10    = '$x1? $x $x2? $x4_7 $x5? $x6_1? $x8 $x9a10_3?';

my $re11    = '$x1? $x $x2? $x5? $x6 $x8 $x9a10_3?';

my $re12    = '$x1? $x $x2? $x5? $x7_1';

my $re13    = '$x1? $x $x2? $x5? $x7_2 $x8? $x9a10_3?';

my $re14    = '$x1? $x $x2? $x5? $x7_3 $x9a10_3?';

my $re_num  = '[໑໒໓໔໕໖໗໘໙໐]';

my $rex1012 = '$x10_12';

# This is the basic regexp that matches a syllable, still with variables to be
# substituted
my $re_basic = <<"EOF";
(?:
  (?:
    (?: $re1_all (?: $re1_1 | $re1_2 | $re1_3 | $re1_4 | $re1_5 | $re1_6 | $re1_8 ) ) |
    (?: $re2_all (?: $re2_1 | $re2_2 | $re2_3 ) ) |
    (?: $re3_all (?: $re3_1 | $re3_2 | $re3_3 ) ) |
    $re4  | $re5  | $re6  | $re7  | $re8  | $re9  |
    $re10 | $re11 | $re12 | $re13 | $re14
  ) $rex1012? |
  $re_num+
)
EOF
$re_basic =~ s/\n//gs;
$re_basic =~ s/\s+/ /g; # keep it a bit more readable. could use s/\s+//g

# Functional names for all the x-something groups from the original paper
# Used for named catures.
my %CAPTURE_NAMES = (
    'x'             => 'consonant',
    'x0_\d'         => 'vowel0',
    'x1'            => 'h',
    'x2'            => 'semivowel',
    'x3'            => 'vowel1',
    'x4_[1-9t]{1,3}'=> 'vowel1',
    'x5'            => 'tone_mark',
    'x6'            => 'vowel2',
    'x6_\d'         => 'vowel2',
    'x7_2'          => 'vowel2',
    'x7_[13]'       => 'vowel3',
    'x8'            => 'end_consonant',
    'x8_3t8'        => 'end_consonant',
    'x9'            => 'foreign_consonant',
    'x10_12'        => 'extra',
    'x10_3'         => 'cancel',
);

# Substitute longer fragment names first so their matches don't get swallowed
# by the shorter ones. x9a10_3 is a convenience shotcut for '(?: $x9 $x10_3)'
# so we have to do it first.
my @SORTED_X_NAMES = ('x9a10_3', reverse sort { length $a <=> length $b } keys %CAPTURE_NAMES);

our %VOWEL_LENGTH = (
    ### Monophthongs
    'Xະ'   => 0,  # /a/
    'Xັ'    => 0,  # /a/ with end consonant
    'Xາ'   => 1,  # /aː/

    'Xິ'    => 0,  # /i/
    'Xີ'    => 1,  # /iː/

    'Xຶ'    => 0,  # /ɯ/
    'Xື'    => 1,  # /ɯː/

    'Xຸ'    => 0,  # /u/
    'Xູ'    => 1,  # /uː/

    'ເXະ'  => 0,  # /e/
    'ເXັ'   => 0,  # /e/ with end consonant
    'ເX'   => 1,  # /eː/

    'ແXະ'  => 0,  # /ɛ/
    'ແXັ'   => 0,  # /ɛ/ with end consonant
    'ແX'   => 1,  # /ɛː/

    'ໂXະ'  => 0,  # /o/
    'Xົ'    => 0,  # /o/
    'ໂX'   => 1,  # /oː/

    'ເXາະ' => 0,  # /ɔ/
    'Xັອ'   => 0,  # /ɔ/ with end consonant
    'Xໍ'    => 1,  # /ɔː/
    'Xອ'   => 1,  # /ɔː/ with end consonant

    'ເXິ'   => 0,  # /ɤ/
    'ເXີ'   => 1,  # /ɤː/

    ###' Diphthongs
    'ເXັຍ'  => 0,  # /iə/
    'Xັຽ'   => 0,  # /iə/
    'ເXຍ'  => 1,  # /iːə/
    'Xຽ'   => 1,  # /iːə/

    'ເXຶອ'  => 0,  # /ɯə/
    'ເXືອ'  => 1,  # /ɯːə/

    'Xົວະ'  => 0,  # /uə/
    'Xັວ'   => 0,  # /uə/
    'Xົວ'   => 1,  # /uːə/
    'Xວ'   => 1,  # /uːə/ with end consonant

    'ໄX'   => 1,  # /aj/ - Actually short but counts as long for rules
    'ໃX'   => 1,  # /aj/ - Actually short but counts as long for rules
    'Xາຍ'  => 1,  # /aj/ - Actually short but counts as long for rules
    'Xັຍ'   => 0,  # /aj/

    'ເXົາ'  => 0,  # /aw/
    'Xໍາ'   => 0,  # /am/
);
{
    # Replace "X" in %VOWELS keys with DOTTED CIRCLE. Makes code easier to edit.
    my %v;
    foreach my $v (keys %VOWEL_LENGTH) {
        (my $w = $v) =~ s/X/\N{DOTTED CIRCLE}/;
        $v{$w} = $VOWEL_LENGTH{$v};
    }
    %VOWEL_LENGTH = %v;
}


=head1 FUNCTIONS

=head2 get_sylre_basic

Returns a basic regexp that can match a Lao syllable. It consists of a bunch of
alternations and will thus return the I<first> possible match which is neither
guaranteed to be the longest nor the appropriate one in a longer sequence of
characters. It is useful as a building block and for verifying syllables
though.

=cut

sub get_sylre_basic {
    my $syl_re = $re_basic;
    for my $atom (@SORTED_X_NAMES) {
        $syl_re =~ s/\$($atom)/$regexp_fragments{$1}/eg;
    }

    return qr/ $syl_re /x;
}

=head2 get_sylre_full

In addition to the matching done by L<get_sylre_basic>, this one makes sure
matches are either followed by another complete syllable, a blank, the end of
string/line or some non-Lao character. This ensures correct matching of
ambiguous syllable boundaries where the core consonant of a following syllable
could also be an end consonant of the current one.

=cut

sub get_sylre_full {
    my $syl_short = get_sylre_basic();
    return qr/ $syl_short (?= \P{Lao} | \s | $ | $syl_short ) /x;
}

=head2 get_sylre_named

The expression returned is the same as for L<get_sylre_full> but also includes
named captures that upon a successful match allow to get the syllable's parts
from C<%+>.

=cut

sub get_sylre_named {
    my $syl_short = get_sylre_basic();
    my $syl_capture = $re_basic;
    for my $atom (@SORTED_X_NAMES) {
        $syl_capture =~ s/\$($atom)/_named_capture(\%regexp_fragments, $atom, $1)/eg;
    }

    return qr/ $syl_capture (?= \P{Lao} | \s | $ | $syl_short )/x;
}

=head2 is_long_vowel

C<is_long_vowel( $lao_vowel )>

Returns a boolean indicating whether the vowel passed in is long. Consonant
placeholders must be included in the form of DOTTED CIRCLE (U+25CC). Note that
for speed there is no check if the vowel actually exists in the data, so
passing many bogus values may lead to uncontrolled growth of the
C<%VOWEL_LENGTH> hash due to autovivification!

=cut

sub is_long_vowel { return $VOWEL_LENGTH{+shift} }

=head2 normalize_tone_marks

C<normalize_tone_marks( $text )>

Normalize tone mark order in C<$text>. Usually when using a combining vowel
such as ◌ິ, ◌ຸ or ◌ໍ with a tone mark, they have to be typed in the order
I<consonant-vowel-tonemark> as renderers are supposed to stack above-consonant
signs in the order they appear in the text, and tone marks are supposed to go
on top. As some renderers will put them on top no matter what, these sequences
are sometimes incorrectly entered as I<consonant-tonemark-vowel> and would thus
not be parsed correctly.

This function is just meant for internal use and modifies its argument in place
for speed!

=cut

sub normalize_tone_marks {
    my $t = $_[0];
    $_[0] =~ s/([$CONSONANTS])([$TONE_MARKS])([$VOWELS_COMBINING])/$1$3$2/og;
}

sub _named_capture {
    my ($fragments, $atom, $match) = @_;

    return sprintf(
        '(?<%s> %s)',
        $CAPTURE_NAMES{$atom}, $fragments->{$match}
    ) if defined $CAPTURE_NAMES{$atom};

    return $fragments->{$match};
}

1;
