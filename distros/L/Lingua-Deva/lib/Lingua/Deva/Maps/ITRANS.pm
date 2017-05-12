package Lingua::Deva::Maps::ITRANS;

use v5.12.1;
use strict;
use warnings;
use charnames ':full';

# Maps for ITRANS transliteration

our $CASE = 1;

our %Consonants = (
    "k"   => "\N{DEVANAGARI LETTER KA}",
    "kh"  => "\N{DEVANAGARI LETTER KHA}",
    "g"   => "\N{DEVANAGARI LETTER GA}",
    "gh"  => "\N{DEVANAGARI LETTER GHA}",
    "~N"  => "\N{DEVANAGARI LETTER NGA}",
    "c"   => "\N{DEVANAGARI LETTER CA}",
    "Ch"  => "\N{DEVANAGARI LETTER CHA}",
    "j"   => "\N{DEVANAGARI LETTER JA}",
    "jh"  => "\N{DEVANAGARI LETTER JHA}",
    "~n"  => "\N{DEVANAGARI LETTER NYA}",
    "T"   => "\N{DEVANAGARI LETTER TTA}",
    "Th"  => "\N{DEVANAGARI LETTER TTHA}",
    "D"   => "\N{DEVANAGARI LETTER DDA}",
    "Dh"  => "\N{DEVANAGARI LETTER DDHA}",
    "N"   => "\N{DEVANAGARI LETTER NNA}",
    "t"   => "\N{DEVANAGARI LETTER TA}",
    "th"  => "\N{DEVANAGARI LETTER THA}",
    "d"   => "\N{DEVANAGARI LETTER DA}",
    "dh"  => "\N{DEVANAGARI LETTER DHA}",
    "n"   => "\N{DEVANAGARI LETTER NA}",
    "p"   => "\N{DEVANAGARI LETTER PA}",
    "ph"  => "\N{DEVANAGARI LETTER PHA}",
    "b"   => "\N{DEVANAGARI LETTER BA}",
    "bh"  => "\N{DEVANAGARI LETTER BHA}",
    "m"   => "\N{DEVANAGARI LETTER MA}",
    "y"   => "\N{DEVANAGARI LETTER YA}",
    "r"   => "\N{DEVANAGARI LETTER RA}",
    "l"   => "\N{DEVANAGARI LETTER LA}",
    "v"   => "\N{DEVANAGARI LETTER VA}",
    "sh"  => "\N{DEVANAGARI LETTER SHA}",
    "Sh"  => "\N{DEVANAGARI LETTER SSA}",
    "s"   => "\N{DEVANAGARI LETTER SA}",
    "h"   => "\N{DEVANAGARI LETTER HA}",
);

our %Vowels = (
    "a"   => "\N{DEVANAGARI LETTER A}",
    "aa"  => "\N{DEVANAGARI LETTER AA}",
    "i"   => "\N{DEVANAGARI LETTER I}",
    "ii"  => "\N{DEVANAGARI LETTER II}",
    "u"   => "\N{DEVANAGARI LETTER U}",
    "uu"  => "\N{DEVANAGARI LETTER UU}",
    "RRi" => "\N{DEVANAGARI LETTER VOCALIC R}",
    "RRI" => "\N{DEVANAGARI LETTER VOCALIC RR}",
    "LLi" => "\N{DEVANAGARI LETTER VOCALIC L}",
    "LLI" => "\N{DEVANAGARI LETTER VOCALIC LL}",
    "e"   => "\N{DEVANAGARI LETTER E}",
    "ai"  => "\N{DEVANAGARI LETTER AI}",
    "o"   => "\N{DEVANAGARI LETTER O}",
    "au"  => "\N{DEVANAGARI LETTER AU}",
);

our %Diacritics = (
    # no diacritic for the inherent vowel
    "aa"  => "\N{DEVANAGARI VOWEL SIGN AA}",
    "i"   => "\N{DEVANAGARI VOWEL SIGN I}",
    "ii"  => "\N{DEVANAGARI VOWEL SIGN II}",
    "u"   => "\N{DEVANAGARI VOWEL SIGN U}",
    "uu"  => "\N{DEVANAGARI VOWEL SIGN UU}",
    "RRi" => "\N{DEVANAGARI VOWEL SIGN VOCALIC R}",
    "RRI" => "\N{DEVANAGARI VOWEL SIGN VOCALIC RR}",
    "LLi" => "\N{DEVANAGARI VOWEL SIGN VOCALIC L}",
    "LLI" => "\N{DEVANAGARI VOWEL SIGN VOCALIC LL}",
    "e"   => "\N{DEVANAGARI VOWEL SIGN E}",
    "ai"  => "\N{DEVANAGARI VOWEL SIGN AI}",
    "o"   => "\N{DEVANAGARI VOWEL SIGN O}",
    "au"  => "\N{DEVANAGARI VOWEL SIGN AU}",
);

our %Finals = (
    "M"   => "\N{DEVANAGARI SIGN ANUSVARA}",
    # no sign for Candrabindu
    "H"   => "\N{DEVANAGARI SIGN VISARGA}",
);

1;
