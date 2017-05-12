package Lingua::Deva::Maps::ISO15919;

use v5.12.1;
use strict;
use warnings;
use charnames ':full';

# Maps for ISO 15919 transliteration (simplified)

our $CASE = 0;

our %Consonants = (
    "k"                 => "\N{DEVANAGARI LETTER KA}",
    "kh"                => "\N{DEVANAGARI LETTER KHA}",
    "g"                 => "\N{DEVANAGARI LETTER GA}",
    "gh"                => "\N{DEVANAGARI LETTER GHA}",
    "n\x{0307}"         => "\N{DEVANAGARI LETTER NGA}",
    "c"                 => "\N{DEVANAGARI LETTER CA}",
    "ch"                => "\N{DEVANAGARI LETTER CHA}",
    "j"                 => "\N{DEVANAGARI LETTER JA}",
    "jh"                => "\N{DEVANAGARI LETTER JHA}",
    "n\x{0303}"         => "\N{DEVANAGARI LETTER NYA}",
    "t\x{0323}"         => "\N{DEVANAGARI LETTER TTA}",
    "t\x{0323}h"        => "\N{DEVANAGARI LETTER TTHA}",
    "d\x{0323}"         => "\N{DEVANAGARI LETTER DDA}",
    "d\x{0323}h"        => "\N{DEVANAGARI LETTER DDHA}",
    "n\x{0323}"         => "\N{DEVANAGARI LETTER NNA}",
    "t"                 => "\N{DEVANAGARI LETTER TA}",
    "th"                => "\N{DEVANAGARI LETTER THA}",
    "d"                 => "\N{DEVANAGARI LETTER DA}",
    "dh"                => "\N{DEVANAGARI LETTER DHA}",
    "n"                 => "\N{DEVANAGARI LETTER NA}",
    "p"                 => "\N{DEVANAGARI LETTER PA}",
    "ph"                => "\N{DEVANAGARI LETTER PHA}",
    "b"                 => "\N{DEVANAGARI LETTER BA}",
    "bh"                => "\N{DEVANAGARI LETTER BHA}",
    "m"                 => "\N{DEVANAGARI LETTER MA}",
    "y"                 => "\N{DEVANAGARI LETTER YA}",
    "r"                 => "\N{DEVANAGARI LETTER RA}",
    "l"                 => "\N{DEVANAGARI LETTER LA}",
    "v"                 => "\N{DEVANAGARI LETTER VA}",
    "s\x{0301}"         => "\N{DEVANAGARI LETTER SHA}",
    "s\x{0323}"         => "\N{DEVANAGARI LETTER SSA}",
    "s"                 => "\N{DEVANAGARI LETTER SA}",
    "h"                 => "\N{DEVANAGARI LETTER HA}",
);

our %Vowels = (
    "a"                 => "\N{DEVANAGARI LETTER A}",
    "a\x{0304}"         => "\N{DEVANAGARI LETTER AA}",
    "i"                 => "\N{DEVANAGARI LETTER I}",
    "i\x{0304}"         => "\N{DEVANAGARI LETTER II}",
    "u"                 => "\N{DEVANAGARI LETTER U}",
    "u\x{0304}"         => "\N{DEVANAGARI LETTER UU}",
    "r\x{0325}"         => "\N{DEVANAGARI LETTER VOCALIC R}",
    "r\x{0325}\x{0304}" => "\N{DEVANAGARI LETTER VOCALIC RR}",
    "l\x{0325}"         => "\N{DEVANAGARI LETTER VOCALIC L}",
    "l\x{0325}\x{0304}" => "\N{DEVANAGARI LETTER VOCALIC LL}",
    "e\x{0304}"         => "\N{DEVANAGARI LETTER E}",
    "ai"                => "\N{DEVANAGARI LETTER AI}",
    "o\x{0304}"         => "\N{DEVANAGARI LETTER O}",
    "au"                => "\N{DEVANAGARI LETTER AU}",
);

our %Diacritics = (
    # no diacritic for the inherent vowel
    "a\x{0304}"         => "\N{DEVANAGARI VOWEL SIGN AA}",
    "i"                 => "\N{DEVANAGARI VOWEL SIGN I}",
    "i\x{0304}"         => "\N{DEVANAGARI VOWEL SIGN II}",
    "u"                 => "\N{DEVANAGARI VOWEL SIGN U}",
    "u\x{0304}"         => "\N{DEVANAGARI VOWEL SIGN UU}",
    "r\x{0325}"         => "\N{DEVANAGARI VOWEL SIGN VOCALIC R}",
    "r\x{0325}\x{0304}" => "\N{DEVANAGARI VOWEL SIGN VOCALIC RR}",
    "l\x{0325}"         => "\N{DEVANAGARI VOWEL SIGN VOCALIC L}",
    "l\x{0325}\x{0304}" => "\N{DEVANAGARI VOWEL SIGN VOCALIC LL}",
    "e\x{0304}"         => "\N{DEVANAGARI VOWEL SIGN E}",
    "ai"                => "\N{DEVANAGARI VOWEL SIGN AI}",
    "o\x{0304}"         => "\N{DEVANAGARI VOWEL SIGN O}",
    "au"                => "\N{DEVANAGARI VOWEL SIGN AU}",
);

our %Finals = (
    "m\x{0307}"         => "\N{DEVANAGARI SIGN ANUSVARA}",
    "m\x{0310}"         => "\N{DEVANAGARI SIGN CANDRABINDU}",
    "h\x{0323}"         => "\N{DEVANAGARI SIGN VISARGA}",
);

1;
