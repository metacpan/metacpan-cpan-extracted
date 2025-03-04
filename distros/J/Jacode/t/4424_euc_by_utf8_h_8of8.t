######################################################################
#
# t/4424_euc_by_utf8_h_8of8.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

sub BEGIN {
    eval q<
        use FindBin;
        use lib "$FindBin::Bin/..";
    >;
}
require 'lib/jacode.pl';

# avoid "Allocation too large"
@todo = (
("\xE9\xA8\xAB",'euc','utf8','h',"\xF1\xDA"),
("\xE9\xA8\xB0",'euc','utf8','h',"\xC6\xAD"),
("\xE9\xA8\xB7",'euc','utf8','h',"\xF1\xDB"),
("\xE9\xA8\xBE",'euc','utf8','h',"\xF1\xE0"),
("\xE9\xA9\x80",'euc','utf8','h',"\xF1\xDE"),
("\xE9\xA9\x82",'euc','utf8','h',"\xF1\xDD"),
("\xE9\xA9\x83",'euc','utf8','h',"\xF1\xDF"),
("\xE9\xA9\x85",'euc','utf8','h',"\xF1\xDC"),
("\xE9\xA9\x8D",'euc','utf8','h',"\xF1\xE2"),
("\xE9\xA9\x8E",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xA9\x95",'euc','utf8','h',"\xF1\xE1"),
("\xE9\xA9\x97",'euc','utf8','h',"\xF1\xE4"),
("\xE9\xA9\x9A",'euc','utf8','h',"\xB6\xC3"),
("\xE9\xA9\x9B",'euc','utf8','h',"\xF1\xE3"),
("\xE9\xA9\x9F",'euc','utf8','h',"\xF1\xE5"),
("\xE9\xA9\xA2",'euc','utf8','h',"\xF1\xE6"),
("\xE9\xA9\xA4",'euc','utf8','h',"\xF1\xE8"),
("\xE9\xA9\xA5",'euc','utf8','h',"\xF1\xE7"),
("\xE9\xA9\xA9",'euc','utf8','h',"\xF1\xE9"),
("\xE9\xA9\xAA",'euc','utf8','h',"\xF1\xEB"),
("\xE9\xA9\xAB",'euc','utf8','h',"\xF1\xEA"),
("\xE9\xAA\xA8",'euc','utf8','h',"\xB9\xFC"),
("\xE9\xAA\xAD",'euc','utf8','h',"\xF1\xEC"),
("\xE9\xAA\xB0",'euc','utf8','h',"\xF1\xED"),
("\xE9\xAA\xB8",'euc','utf8','h',"\xB3\xBC"),
("\xE9\xAA\xBC",'euc','utf8','h',"\xF1\xEE"),
("\xE9\xAB\x80",'euc','utf8','h',"\xF1\xEF"),
("\xE9\xAB\x84",'euc','utf8','h',"\xBF\xF1"),
("\xE9\xAB\x8F",'euc','utf8','h',"\xF1\xF0"),
("\xE9\xAB\x91",'euc','utf8','h',"\xF1\xF1"),
("\xE9\xAB\x93",'euc','utf8','h',"\xF1\xF2"),
("\xE9\xAB\x94",'euc','utf8','h',"\xF1\xF3"),
("\xE9\xAB\x98",'euc','utf8','h',"\xB9\xE2"),
("\xE9\xAB\x99",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xAB\x9C",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xAB\x9E",'euc','utf8','h',"\xF1\xF4"),
("\xE9\xAB\x9F",'euc','utf8','h',"\xF1\xF5"),
("\xE9\xAB\xA2",'euc','utf8','h',"\xF1\xF6"),
("\xE9\xAB\xA3",'euc','utf8','h',"\xF1\xF7"),
("\xE9\xAB\xA6",'euc','utf8','h',"\xF1\xF8"),
("\xE9\xAB\xAA",'euc','utf8','h',"\xC8\xB1"),
("\xE9\xAB\xAB",'euc','utf8','h',"\xF1\xFA"),
("\xE9\xAB\xAD",'euc','utf8','h',"\xC9\xA6"),
("\xE9\xAB\xAE",'euc','utf8','h',"\xF1\xFB"),
("\xE9\xAB\xAF",'euc','utf8','h',"\xF1\xF9"),
("\xE9\xAB\xB1",'euc','utf8','h',"\xF1\xFD"),
("\xE9\xAB\xB4",'euc','utf8','h',"\xF1\xFC"),
("\xE9\xAB\xB7",'euc','utf8','h',"\xF1\xFE"),
("\xE9\xAB\xBB",'euc','utf8','h',"\xF2\xA1"),
("\xE9\xAC\x86",'euc','utf8','h',"\xF2\xA2"),
("\xE9\xAC\x98",'euc','utf8','h',"\xF2\xA3"),
("\xE9\xAC\x9A",'euc','utf8','h',"\xF2\xA4"),
("\xE9\xAC\x9F",'euc','utf8','h',"\xF2\xA5"),
("\xE9\xAC\xA2",'euc','utf8','h',"\xF2\xA6"),
("\xE9\xAC\xA3",'euc','utf8','h',"\xF2\xA7"),
("\xE9\xAC\xA5",'euc','utf8','h',"\xF2\xA8"),
("\xE9\xAC\xA7",'euc','utf8','h',"\xF2\xA9"),
("\xE9\xAC\xA8",'euc','utf8','h',"\xF2\xAA"),
("\xE9\xAC\xA9",'euc','utf8','h',"\xF2\xAB"),
("\xE9\xAC\xAA",'euc','utf8','h',"\xF2\xAC"),
("\xE9\xAC\xAE",'euc','utf8','h',"\xF2\xAD"),
("\xE9\xAC\xAF",'euc','utf8','h',"\xF2\xAE"),
("\xE9\xAC\xB1",'euc','utf8','h',"\xDD\xB5"),
("\xE9\xAC\xB2",'euc','utf8','h',"\xF2\xAF"),
("\xE9\xAC\xBB",'euc','utf8','h',"\xE4\xF8"),
("\xE9\xAC\xBC",'euc','utf8','h',"\xB5\xB4"),
("\xE9\xAD\x81",'euc','utf8','h',"\xB3\xA1"),
("\xE9\xAD\x82",'euc','utf8','h',"\xBA\xB2"),
("\xE9\xAD\x83",'euc','utf8','h',"\xF2\xB1"),
("\xE9\xAD\x84",'euc','utf8','h',"\xF2\xB0"),
("\xE9\xAD\x85",'euc','utf8','h',"\xCC\xA5"),
("\xE9\xAD\x8D",'euc','utf8','h',"\xF2\xB3"),
("\xE9\xAD\x8E",'euc','utf8','h',"\xF2\xB4"),
("\xE9\xAD\x8F",'euc','utf8','h',"\xF2\xB2"),
("\xE9\xAD\x91",'euc','utf8','h',"\xF2\xB5"),
("\xE9\xAD\x94",'euc','utf8','h',"\xCB\xE2"),
("\xE9\xAD\x98",'euc','utf8','h',"\xF2\xB6"),
("\xE9\xAD\x9A",'euc','utf8','h',"\xB5\xFB"),
("\xE9\xAD\xAF",'euc','utf8','h',"\xCF\xA5"),
("\xE9\xAD\xB2",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xAD\xB4",'euc','utf8','h',"\xF2\xB7"),
("\xE9\xAD\xB5",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xAE\x83",'euc','utf8','h',"\xF2\xB9"),
("\xE9\xAE\x8E",'euc','utf8','h',"\xB0\xBE"),
("\xE9\xAE\x8F",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xAE\x91",'euc','utf8','h',"\xF2\xBA"),
("\xE9\xAE\x92",'euc','utf8','h',"\xCA\xAB"),
("\xE9\xAE\x93",'euc','utf8','h',"\xF2\xB8"),
("\xE9\xAE\x96",'euc','utf8','h',"\xF2\xBB"),
("\xE9\xAE\x97",'euc','utf8','h',"\xF2\xBC"),
("\xE9\xAE\x9F",'euc','utf8','h',"\xF2\xBD"),
("\xE9\xAE\xA0",'euc','utf8','h',"\xF2\xBE"),
("\xE9\xAE\xA8",'euc','utf8','h',"\xF2\xBF"),
("\xE9\xAE\xAA",'euc','utf8','h',"\xCB\xEE"),
("\xE9\xAE\xAB",'euc','utf8','h',"\xBB\xAD"),
("\xE9\xAE\xAD",'euc','utf8','h',"\xBA\xFA"),
("\xE9\xAE\xAE",'euc','utf8','h',"\xC1\xAF"),
("\xE9\xAE\xB1",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xAE\xB4",'euc','utf8','h',"\xF2\xC0"),
("\xE9\xAE\xB9",'euc','utf8','h',"\xF2\xC3"),
("\xE9\xAE\xBB",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xAF\x80",'euc','utf8','h',"\xF2\xC1"),
("\xE9\xAF\x86",'euc','utf8','h',"\xF2\xC4"),
("\xE9\xAF\x89",'euc','utf8','h',"\xB8\xF1"),
("\xE9\xAF\x8A",'euc','utf8','h',"\xF2\xC2"),
("\xE9\xAF\x8F",'euc','utf8','h',"\xF2\xC5"),
("\xE9\xAF\x91",'euc','utf8','h',"\xF2\xC6"),
("\xE9\xAF\x92",'euc','utf8','h',"\xF2\xC7"),
("\xE9\xAF\x94",'euc','utf8','h',"\xF2\xCB"),
("\xE9\xAF\x96",'euc','utf8','h',"\xBB\xAA"),
("\xE9\xAF\x9B",'euc','utf8','h',"\xC2\xE4"),
("\xE9\xAF\xA1",'euc','utf8','h',"\xF2\xCC"),
("\xE9\xAF\xA2",'euc','utf8','h',"\xF2\xC9"),
("\xE9\xAF\xA3",'euc','utf8','h',"\xF2\xC8"),
("\xE9\xAF\xA4",'euc','utf8','h',"\xF2\xCA"),
("\xE9\xAF\xA8",'euc','utf8','h',"\xB7\xDF"),
("\xE9\xAF\xB0",'euc','utf8','h',"\xF2\xD0"),
("\xE9\xAF\xB1",'euc','utf8','h',"\xF2\xCF"),
("\xE9\xAF\xB2",'euc','utf8','h',"\xF2\xCE"),
("\xE9\xAF\xB5",'euc','utf8','h',"\xB0\xB3"),
("\xE9\xB0\x80",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xB0\x84",'euc','utf8','h',"\xF2\xDA"),
("\xE9\xB0\x86",'euc','utf8','h',"\xF2\xD6"),
("\xE9\xB0\x88",'euc','utf8','h',"\xF2\xD7"),
("\xE9\xB0\x89",'euc','utf8','h',"\xF2\xD3"),
("\xE9\xB0\x8A",'euc','utf8','h',"\xF2\xD9"),
("\xE9\xB0\x8C",'euc','utf8','h',"\xF2\xD5"),
("\xE9\xB0\x8D",'euc','utf8','h',"\xB3\xE2"),
("\xE9\xB0\x90",'euc','utf8','h',"\xCF\xCC"),
("\xE9\xB0\x92",'euc','utf8','h',"\xF2\xD8"),
("\xE9\xB0\x93",'euc','utf8','h',"\xF2\xD4"),
("\xE9\xB0\x94",'euc','utf8','h',"\xF2\xD2"),
("\xE9\xB0\x95",'euc','utf8','h',"\xF2\xD1"),
("\xE9\xB0\x9B",'euc','utf8','h',"\xF2\xDC"),
("\xE9\xB0\xA1",'euc','utf8','h',"\xF2\xDF"),
("\xE9\xB0\xA4",'euc','utf8','h',"\xF2\xDE"),
("\xE9\xB0\xA5",'euc','utf8','h',"\xF2\xDD"),
("\xE9\xB0\xAD",'euc','utf8','h',"\xC9\xC9"),
("\xE9\xB0\xAE",'euc','utf8','h',"\xF2\xDB"),
("\xE9\xB0\xAF",'euc','utf8','h',"\xB0\xF3"),
("\xE9\xB0\xB0",'euc','utf8','h',"\xF2\xE0"),
("\xE9\xB0\xB2",'euc','utf8','h',"\xF2\xE2"),
("\xE9\xB0\xB9",'euc','utf8','h',"\xB3\xEF"),
("\xE9\xB0\xBA",'euc','utf8','h',"\xF2\xCD"),
("\xE9\xB0\xBB",'euc','utf8','h',"\xB1\xB7"),
("\xE9\xB0\xBE",'euc','utf8','h',"\xF2\xE4"),
("\xE9\xB1\x86",'euc','utf8','h',"\xF2\xE3"),
("\xE9\xB1\x87",'euc','utf8','h',"\xF2\xE1"),
("\xE9\xB1\x88",'euc','utf8','h',"\xC3\xAD"),
("\xE9\xB1\x92",'euc','utf8','h',"\xCB\xF0"),
("\xE9\xB1\x97",'euc','utf8','h',"\xCE\xDA"),
("\xE9\xB1\x9A",'euc','utf8','h',"\xF2\xE5"),
("\xE9\xB1\xA0",'euc','utf8','h',"\xF2\xE6"),
("\xE9\xB1\xA7",'euc','utf8','h',"\xF2\xE7"),
("\xE9\xB1\xB6",'euc','utf8','h',"\xF2\xE8"),
("\xE9\xB1\xB8",'euc','utf8','h',"\xF2\xE9"),
("\xE9\xB3\xA5",'euc','utf8','h',"\xC4\xBB"),
("\xE9\xB3\xA7",'euc','utf8','h',"\xF2\xEA"),
("\xE9\xB3\xA9",'euc','utf8','h',"\xC8\xB7"),
("\xE9\xB3\xAB",'euc','utf8','h',"\xF2\xEF"),
("\xE9\xB3\xAC",'euc','utf8','h',"\xF2\xEB"),
("\xE9\xB3\xB0",'euc','utf8','h',"\xF2\xEC"),
("\xE9\xB3\xB3",'euc','utf8','h',"\xCB\xB1"),
("\xE9\xB3\xB4",'euc','utf8','h',"\xCC\xC4"),
("\xE9\xB3\xB6",'euc','utf8','h',"\xC6\xD0"),
("\xE9\xB4\x83",'euc','utf8','h',"\xF2\xF0"),
("\xE9\xB4\x86",'euc','utf8','h',"\xF2\xF1"),
("\xE9\xB4\x87",'euc','utf8','h',"\xC6\xBE"),
("\xE9\xB4\x88",'euc','utf8','h',"\xF2\xEE"),
("\xE9\xB4\x89",'euc','utf8','h',"\xF2\xED"),
("\xE9\xB4\x8E",'euc','utf8','h',"\xB2\xAA"),
("\xE9\xB4\x92",'euc','utf8','h',"\xF2\xF9"),
("\xE9\xB4\x95",'euc','utf8','h',"\xF2\xF8"),
("\xE9\xB4\x9B",'euc','utf8','h',"\xB1\xF5"),
("\xE9\xB4\x9F",'euc','utf8','h',"\xF2\xF6"),
("\xE9\xB4\xA3",'euc','utf8','h',"\xF2\xF5"),
("\xE9\xB4\xA6",'euc','utf8','h',"\xF2\xF3"),
("\xE9\xB4\xA8",'euc','utf8','h',"\xB3\xFB"),
("\xE9\xB4\xAA",'euc','utf8','h',"\xF2\xF2"),
("\xE9\xB4\xAB",'euc','utf8','h',"\xBC\xB2"),
("\xE9\xB4\xAC",'euc','utf8','h',"\xB2\xA9"),
("\xE9\xB4\xBB",'euc','utf8','h',"\xB9\xE3"),
("\xE9\xB4\xBE",'euc','utf8','h',"\xF2\xFC"),
("\xE9\xB4\xBF",'euc','utf8','h',"\xF2\xFB"),
("\xE9\xB5\x81",'euc','utf8','h',"\xF2\xFA"),
("\xE9\xB5\x84",'euc','utf8','h',"\xF2\xF7"),
("\xE9\xB5\x86",'euc','utf8','h',"\xF2\xFD"),
("\xE9\xB5\x88",'euc','utf8','h',"\xF2\xFE"),
("\xE9\xB5\x90",'euc','utf8','h',"\xF3\xA5"),
("\xE9\xB5\x91",'euc','utf8','h',"\xF3\xA4"),
("\xE9\xB5\x99",'euc','utf8','h',"\xF3\xA6"),
("\xE9\xB5\x9C",'euc','utf8','h',"\xB1\xAD"),
("\xE9\xB5\x9D",'euc','utf8','h',"\xF3\xA1"),
("\xE9\xB5\x9E",'euc','utf8','h',"\xF3\xA2"),
("\xE9\xB5\xA0",'euc','utf8','h',"\xB9\xF4"),
("\xE9\xB5\xA1",'euc','utf8','h',"\xCC\xB9"),
("\xE9\xB5\xA4",'euc','utf8','h',"\xF3\xA3"),
("\xE9\xB5\xAB",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xB5\xAC",'euc','utf8','h',"\xCB\xB2"),
("\xE9\xB5\xAF",'euc','utf8','h',"\xF3\xAB"),
("\xE9\xB5\xB0",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xB5\xB2",'euc','utf8','h',"\xF3\xA7"),
("\xE9\xB5\xBA",'euc','utf8','h',"\xF3\xAC"),
("\xE9\xB6\x87",'euc','utf8','h',"\xF3\xA9"),
("\xE9\xB6\x89",'euc','utf8','h',"\xF3\xA8"),
("\xE9\xB6\x8F",'euc','utf8','h',"\xB7\xDC"),
("\xE9\xB6\x9A",'euc','utf8','h',"\xF3\xAD"),
("\xE9\xB6\xA4",'euc','utf8','h',"\xF3\xAE"),
("\xE9\xB6\xA9",'euc','utf8','h',"\xF3\xAF"),
("\xE9\xB6\xAB",'euc','utf8','h',"\xF3\xAA"),
("\xE9\xB6\xAF",'euc','utf8','h',"\xF2\xF4"),
("\xE9\xB6\xB2",'euc','utf8','h',"\xF3\xB0"),
("\xE9\xB6\xB4",'euc','utf8','h',"\xC4\xE1"),
("\xE9\xB6\xB8",'euc','utf8','h',"\xF3\xB4"),
("\xE9\xB6\xBA",'euc','utf8','h',"\xF3\xB5"),
("\xE9\xB6\xBB",'euc','utf8','h',"\xF3\xB3"),
("\xE9\xB7\x81",'euc','utf8','h',"\xF3\xB2"),
("\xE9\xB7\x82",'euc','utf8','h',"\xF3\xB8"),
("\xE9\xB7\x84",'euc','utf8','h',"\xF3\xB1"),
("\xE9\xB7\x86",'euc','utf8','h',"\xF3\xB6"),
("\xE9\xB7\x8F",'euc','utf8','h',"\xF3\xB7"),
("\xE9\xB7\x93",'euc','utf8','h',"\xF3\xBA"),
("\xE9\xB7\x99",'euc','utf8','h',"\xF3\xB9"),
("\xE9\xB7\xA6",'euc','utf8','h',"\xF3\xBC"),
("\xE9\xB7\xAD",'euc','utf8','h',"\xF3\xBD"),
("\xE9\xB7\xAF",'euc','utf8','h',"\xF3\xBE"),
("\xE9\xB7\xB2",'euc','utf8','h',"\xCF\xC9"),
("\xE9\xB7\xB8",'euc','utf8','h',"\xF3\xBB"),
("\xE9\xB7\xB9",'euc','utf8','h',"\xC2\xEB"),
("\xE9\xB7\xBA",'euc','utf8','h',"\xBA\xED"),
("\xE9\xB7\xBD",'euc','utf8','h',"\xF3\xBF"),
("\xE9\xB8\x99",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xB8\x9A",'euc','utf8','h',"\xF3\xC0"),
("\xE9\xB8\x9B",'euc','utf8','h',"\xF3\xC1"),
("\xE9\xB8\x9E",'euc','utf8','h',"\xF3\xC2"),
("\xE9\xB9\xB5",'euc','utf8','h',"\xF3\xC3"),
("\xE9\xB9\xB8",'euc','utf8','h',"\xB8\xB4"),
("\xE9\xB9\xB9",'euc','utf8','h',"\xF3\xC4"),
("\xE9\xB9\xBD",'euc','utf8','h',"\xF3\xC5"),
("\xE9\xB9\xBF",'euc','utf8','h',"\xBC\xAF"),
("\xE9\xBA\x81",'euc','utf8','h',"\xF3\xC6"),
("\xE9\xBA\x88",'euc','utf8','h',"\xF3\xC7"),
("\xE9\xBA\x8B",'euc','utf8','h',"\xF3\xC8"),
("\xE9\xBA\x8C",'euc','utf8','h',"\xF3\xC9"),
("\xE9\xBA\x91",'euc','utf8','h',"\xF3\xCC"),
("\xE9\xBA\x92",'euc','utf8','h',"\xF3\xCA"),
("\xE9\xBA\x93",'euc','utf8','h',"\xCF\xBC"),
("\xE9\xBA\x95",'euc','utf8','h',"\xF3\xCB"),
("\xE9\xBA\x97",'euc','utf8','h',"\xCE\xEF"),
("\xE9\xBA\x9D",'euc','utf8','h',"\xF3\xCD"),
("\xE9\xBA\x9F",'euc','utf8','h',"\xCE\xDB"),
("\xE9\xBA\xA5",'euc','utf8','h',"\xF3\xCE"),
("\xE9\xBA\xA6",'euc','utf8','h',"\xC7\xFE"),
("\xE9\xBA\xA9",'euc','utf8','h',"\xF3\xCF"),
("\xE9\xBA\xAA",'euc','utf8','h',"\xF3\xD1"),
("\xE9\xBA\xAD",'euc','utf8','h',"\xF3\xD2"),
("\xE9\xBA\xB8",'euc','utf8','h',"\xF3\xD0"),
("\xE9\xBA\xB9",'euc','utf8','h',"\xB9\xED"),
("\xE9\xBA\xBA",'euc','utf8','h',"\xCC\xCD"),
("\xE9\xBA\xBB",'euc','utf8','h',"\xCB\xE3"),
("\xE9\xBA\xBC",'euc','utf8','h',"\xD6\xF7"),
("\xE9\xBA\xBE",'euc','utf8','h',"\xDD\xE0"),
("\xE9\xBA\xBF",'euc','utf8','h',"\xCB\xFB"),
("\xE9\xBB\x84",'euc','utf8','h',"\xB2\xAB"),
("\xE9\xBB\x8C",'euc','utf8','h',"\xF3\xD4"),
("\xE9\xBB\x8D",'euc','utf8','h',"\xB5\xD0"),
("\xE9\xBB\x8E",'euc','utf8','h',"\xF3\xD5"),
("\xE9\xBB\x8F",'euc','utf8','h',"\xF3\xD6"),
("\xE9\xBB\x90",'euc','utf8','h',"\xF3\xD7"),
("\xE9\xBB\x91",'euc','utf8','h',"\xA2\xAE"),
("\xE9\xBB\x92",'euc','utf8','h',"\xB9\xF5"),
("\xE9\xBB\x94",'euc','utf8','h',"\xF3\xD8"),
("\xE9\xBB\x98",'euc','utf8','h',"\xE0\xD4"),
("\xE9\xBB\x99",'euc','utf8','h',"\xCC\xDB"),
("\xE9\xBB\x9B",'euc','utf8','h',"\xC2\xE3"),
("\xE9\xBB\x9C",'euc','utf8','h',"\xF3\xD9"),
("\xE9\xBB\x9D",'euc','utf8','h',"\xF3\xDB"),
("\xE9\xBB\x9E",'euc','utf8','h',"\xF3\xDA"),
("\xE9\xBB\xA0",'euc','utf8','h',"\xF3\xDC"),
("\xE9\xBB\xA5",'euc','utf8','h',"\xF3\xDD"),
("\xE9\xBB\xA8",'euc','utf8','h',"\xF3\xDE"),
("\xE9\xBB\xAF",'euc','utf8','h',"\xF3\xDF"),
("\xE9\xBB\xB4",'euc','utf8','h',"\xF3\xE0"),
("\xE9\xBB\xB6",'euc','utf8','h',"\xF3\xE1"),
("\xE9\xBB\xB7",'euc','utf8','h',"\xF3\xE2"),
("\xE9\xBB\xB9",'euc','utf8','h',"\xF3\xE3"),
("\xE9\xBB\xBB",'euc','utf8','h',"\xF3\xE4"),
("\xE9\xBB\xBC",'euc','utf8','h',"\xF3\xE5"),
("\xE9\xBB\xBD",'euc','utf8','h',"\xF3\xE6"),
("\xE9\xBC\x87",'euc','utf8','h',"\xF3\xE7"),
("\xE9\xBC\x88",'euc','utf8','h',"\xF3\xE8"),
("\xE9\xBC\x8E",'euc','utf8','h',"\xC5\xA4"),
("\xE9\xBC\x93",'euc','utf8','h',"\xB8\xDD"),
("\xE9\xBC\x95",'euc','utf8','h',"\xF3\xEA"),
("\xE9\xBC\xA0",'euc','utf8','h',"\xC1\xCD"),
("\xE9\xBC\xA1",'euc','utf8','h',"\xF3\xEB"),
("\xE9\xBC\xAC",'euc','utf8','h',"\xF3\xEC"),
("\xE9\xBC\xBB",'euc','utf8','h',"\xC9\xA1"),
("\xE9\xBC\xBE",'euc','utf8','h',"\xF3\xED"),
("\xE9\xBD\x8A",'euc','utf8','h',"\xF3\xEE"),
("\xE9\xBD\x8B",'euc','utf8','h',"\xE3\xB7"),
("\xE9\xBD\x8E",'euc','utf8','h',"\xEC\xDA"),
("\xE9\xBD\x8F",'euc','utf8','h',"\xF0\xED"),
("\xE9\xBD\x92",'euc','utf8','h',"\xF3\xEF"),
("\xE9\xBD\x94",'euc','utf8','h',"\xF3\xF0"),
("\xE9\xBD\x9F",'euc','utf8','h',"\xF3\xF2"),
("\xE9\xBD\xA0",'euc','utf8','h',"\xF3\xF3"),
("\xE9\xBD\xA1",'euc','utf8','h',"\xF3\xF4"),
("\xE9\xBD\xA2",'euc','utf8','h',"\xCE\xF0"),
("\xE9\xBD\xA3",'euc','utf8','h',"\xF3\xF1"),
("\xE9\xBD\xA6",'euc','utf8','h',"\xF3\xF5"),
("\xE9\xBD\xA7",'euc','utf8','h',"\xF3\xF6"),
("\xE9\xBD\xAA",'euc','utf8','h',"\xF3\xF8"),
("\xE9\xBD\xAC",'euc','utf8','h',"\xF3\xF7"),
("\xE9\xBD\xB2",'euc','utf8','h',"\xF3\xFA"),
("\xE9\xBD\xB6",'euc','utf8','h',"\xF3\xFB"),
("\xE9\xBD\xB7",'euc','utf8','h',"\xF3\xF9"),
("\xE9\xBE\x8D",'euc','utf8','h',"\xCE\xB6"),
("\xE9\xBE\x95",'euc','utf8','h',"\xF3\xFC"),
("\xE9\xBE\x9C",'euc','utf8','h',"\xF3\xFD"),
("\xE9\xBE\x9D",'euc','utf8','h',"\xE3\xD4"),
("\xE9\xBE\xA0",'euc','utf8','h',"\xF3\xFE"),
("\xEF\xA4\xA9",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA7\x9C",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x8E",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x8F",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x90",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x91",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x92",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x93",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x94",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x95",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x96",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x97",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x98",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x99",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x9A",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x9B",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x9C",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x9D",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x9E",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\x9F",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA0",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA1",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA2",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA3",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA4",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA5",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA6",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA7",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA8",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xA9",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xAA",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xAB",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xAC",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xA8\xAD",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xBC\x81",'euc','utf8','h',"\xA1\xAA"),
("\xEF\xBC\x82",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xBC\x83",'euc','utf8','h',"\xA1\xF4"),
("\xEF\xBC\x84",'euc','utf8','h',"\xA1\xF0"),
("\xEF\xBC\x85",'euc','utf8','h',"\xA1\xF3"),
("\xEF\xBC\x86",'euc','utf8','h',"\xA1\xF5"),
("\xEF\xBC\x87",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xBC\x88",'euc','utf8','h',"\xA1\xCA"),
("\xEF\xBC\x89",'euc','utf8','h',"\xA1\xCB"),
("\xEF\xBC\x8A",'euc','utf8','h',"\xA1\xF6"),
("\xEF\xBC\x8B",'euc','utf8','h',"\xA1\xDC"),
("\xEF\xBC\x8C",'euc','utf8','h',"\xA1\xA4"),
("\xEF\xBC\x8D",'euc','utf8','h',"\xA1\xDD"),
("\xEF\xBC\x8E",'euc','utf8','h',"\xA1\xA5"),
("\xEF\xBC\x8F",'euc','utf8','h',"\xA1\xBF"),
("\xEF\xBC\x90",'euc','utf8','h',"\xA3\xB0"),
("\xEF\xBC\x91",'euc','utf8','h',"\xA3\xB1"),
("\xEF\xBC\x92",'euc','utf8','h',"\xA3\xB2"),
("\xEF\xBC\x93",'euc','utf8','h',"\xA3\xB3"),
("\xEF\xBC\x94",'euc','utf8','h',"\xA3\xB4"),
("\xEF\xBC\x95",'euc','utf8','h',"\xA3\xB5"),
("\xEF\xBC\x96",'euc','utf8','h',"\xA3\xB6"),
("\xEF\xBC\x97",'euc','utf8','h',"\xA3\xB7"),
("\xEF\xBC\x98",'euc','utf8','h',"\xA3\xB8"),
("\xEF\xBC\x99",'euc','utf8','h',"\xA3\xB9"),
("\xEF\xBC\x9A",'euc','utf8','h',"\xA1\xA7"),
("\xEF\xBC\x9B",'euc','utf8','h',"\xA1\xA8"),
("\xEF\xBC\x9C",'euc','utf8','h',"\xA1\xE3"),
("\xEF\xBC\x9D",'euc','utf8','h',"\xA1\xE1"),
("\xEF\xBC\x9E",'euc','utf8','h',"\xA1\xE4"),
("\xEF\xBC\x9F",'euc','utf8','h',"\xA1\xA9"),
("\xEF\xBC\xA0",'euc','utf8','h',"\xA1\xF7"),
("\xEF\xBC\xA1",'euc','utf8','h',"\xA3\xC1"),
("\xEF\xBC\xA2",'euc','utf8','h',"\xA3\xC2"),
("\xEF\xBC\xA3",'euc','utf8','h',"\xA3\xC3"),
("\xEF\xBC\xA4",'euc','utf8','h',"\xA3\xC4"),
("\xEF\xBC\xA5",'euc','utf8','h',"\xA3\xC5"),
("\xEF\xBC\xA6",'euc','utf8','h',"\xA3\xC6"),
("\xEF\xBC\xA7",'euc','utf8','h',"\xA3\xC7"),
("\xEF\xBC\xA8",'euc','utf8','h',"\xA3\xC8"),
("\xEF\xBC\xA9",'euc','utf8','h',"\xA3\xC9"),
("\xEF\xBC\xAA",'euc','utf8','h',"\xA3\xCA"),
("\xEF\xBC\xAB",'euc','utf8','h',"\xA3\xCB"),
("\xEF\xBC\xAC",'euc','utf8','h',"\xA3\xCC"),
("\xEF\xBC\xAD",'euc','utf8','h',"\xA3\xCD"),
("\xEF\xBC\xAE",'euc','utf8','h',"\xA3\xCE"),
("\xEF\xBC\xAF",'euc','utf8','h',"\xA3\xCF"),
("\xEF\xBC\xB0",'euc','utf8','h',"\xA3\xD0"),
("\xEF\xBC\xB1",'euc','utf8','h',"\xA3\xD1"),
("\xEF\xBC\xB2",'euc','utf8','h',"\xA3\xD2"),
("\xEF\xBC\xB3",'euc','utf8','h',"\xA3\xD3"),
("\xEF\xBC\xB4",'euc','utf8','h',"\xA3\xD4"),
("\xEF\xBC\xB5",'euc','utf8','h',"\xA3\xD5"),
("\xEF\xBC\xB6",'euc','utf8','h',"\xA3\xD6"),
("\xEF\xBC\xB7",'euc','utf8','h',"\xA3\xD7"),
("\xEF\xBC\xB8",'euc','utf8','h',"\xA3\xD8"),
("\xEF\xBC\xB9",'euc','utf8','h',"\xA3\xD9"),
("\xEF\xBC\xBA",'euc','utf8','h',"\xA3\xDA"),
("\xEF\xBC\xBB",'euc','utf8','h',"\xA1\xCE"),
("\xEF\xBC\xBC",'euc','utf8','h',"\xA1\xC0"),
("\xEF\xBC\xBD",'euc','utf8','h',"\xA1\xCF"),
("\xEF\xBC\xBE",'euc','utf8','h',"\xA1\xB0"),
("\xEF\xBC\xBF",'euc','utf8','h',"\xA1\xB2"),
("\xEF\xBD\x80",'euc','utf8','h',"\xA1\xAE"),
("\xEF\xBD\x81",'euc','utf8','h',"\xA3\xE1"),
("\xEF\xBD\x82",'euc','utf8','h',"\xA3\xE2"),
("\xEF\xBD\x83",'euc','utf8','h',"\xA3\xE3"),
("\xEF\xBD\x84",'euc','utf8','h',"\xA3\xE4"),
("\xEF\xBD\x85",'euc','utf8','h',"\xA3\xE5"),
("\xEF\xBD\x86",'euc','utf8','h',"\xA3\xE6"),
("\xEF\xBD\x87",'euc','utf8','h',"\xA3\xE7"),
("\xEF\xBD\x88",'euc','utf8','h',"\xA3\xE8"),
("\xEF\xBD\x89",'euc','utf8','h',"\xA3\xE9"),
("\xEF\xBD\x8A",'euc','utf8','h',"\xA3\xEA"),
("\xEF\xBD\x8B",'euc','utf8','h',"\xA3\xEB"),
("\xEF\xBD\x8C",'euc','utf8','h',"\xA3\xEC"),
("\xEF\xBD\x8D",'euc','utf8','h',"\xA3\xED"),
("\xEF\xBD\x8E",'euc','utf8','h',"\xA3\xEE"),
("\xEF\xBD\x8F",'euc','utf8','h',"\xA3\xEF"),
("\xEF\xBD\x90",'euc','utf8','h',"\xA3\xF0"),
("\xEF\xBD\x91",'euc','utf8','h',"\xA3\xF1"),
("\xEF\xBD\x92",'euc','utf8','h',"\xA3\xF2"),
("\xEF\xBD\x93",'euc','utf8','h',"\xA3\xF3"),
("\xEF\xBD\x94",'euc','utf8','h',"\xA3\xF4"),
("\xEF\xBD\x95",'euc','utf8','h',"\xA3\xF5"),
("\xEF\xBD\x96",'euc','utf8','h',"\xA3\xF6"),
("\xEF\xBD\x97",'euc','utf8','h',"\xA3\xF7"),
("\xEF\xBD\x98",'euc','utf8','h',"\xA3\xF8"),
("\xEF\xBD\x99",'euc','utf8','h',"\xA3\xF9"),
("\xEF\xBD\x9A",'euc','utf8','h',"\xA3\xFA"),
("\xEF\xBD\x9B",'euc','utf8','h',"\xA1\xD0"),
("\xEF\xBD\x9C",'euc','utf8','h',"\xA1\xC3"),
("\xEF\xBD\x9D",'euc','utf8','h',"\xA1\xD1"),
("\xEF\xBD\x9E",'euc','utf8','h',"\xA1\xC1"),
("\xEF\xBD\xA1",'euc','utf8','h',"\x8E\xA1"),
("\xEF\xBD\xA2",'euc','utf8','h',"\x8E\xA2"),
("\xEF\xBD\xA3",'euc','utf8','h',"\x8E\xA3"),
("\xEF\xBD\xA4",'euc','utf8','h',"\x8E\xA4"),
("\xEF\xBD\xA5",'euc','utf8','h',"\x8E\xA5"),
("\xEF\xBD\xA6",'euc','utf8','h',"\x8E\xA6"),
("\xEF\xBD\xA7",'euc','utf8','h',"\x8E\xA7"),
("\xEF\xBD\xA8",'euc','utf8','h',"\x8E\xA8"),
("\xEF\xBD\xA9",'euc','utf8','h',"\x8E\xA9"),
("\xEF\xBD\xAA",'euc','utf8','h',"\x8E\xAA"),
("\xEF\xBD\xAB",'euc','utf8','h',"\x8E\xAB"),
("\xEF\xBD\xAC",'euc','utf8','h',"\x8E\xAC"),
("\xEF\xBD\xAD",'euc','utf8','h',"\x8E\xAD"),
("\xEF\xBD\xAE",'euc','utf8','h',"\x8E\xAE"),
("\xEF\xBD\xAF",'euc','utf8','h',"\x8E\xAF"),
("\xEF\xBD\xB0",'euc','utf8','h',"\x8E\xB0"),
("\xEF\xBD\xB1",'euc','utf8','h',"\x8E\xB1"),
("\xEF\xBD\xB2",'euc','utf8','h',"\x8E\xB2"),
("\xEF\xBD\xB3",'euc','utf8','h',"\x8E\xB3"),
("\xEF\xBD\xB4",'euc','utf8','h',"\x8E\xB4"),
("\xEF\xBD\xB5",'euc','utf8','h',"\x8E\xB5"),
("\xEF\xBD\xB6",'euc','utf8','h',"\x8E\xB6"),
("\xEF\xBD\xB7",'euc','utf8','h',"\x8E\xB7"),
("\xEF\xBD\xB8",'euc','utf8','h',"\x8E\xB8"),
("\xEF\xBD\xB9",'euc','utf8','h',"\x8E\xB9"),
("\xEF\xBD\xBA",'euc','utf8','h',"\x8E\xBA"),
("\xEF\xBD\xBB",'euc','utf8','h',"\x8E\xBB"),
("\xEF\xBD\xBC",'euc','utf8','h',"\x8E\xBC"),
("\xEF\xBD\xBD",'euc','utf8','h',"\x8E\xBD"),
("\xEF\xBD\xBE",'euc','utf8','h',"\x8E\xBE"),
("\xEF\xBD\xBF",'euc','utf8','h',"\x8E\xBF"),
("\xEF\xBE\x80",'euc','utf8','h',"\x8E\xC0"),
("\xEF\xBE\x81",'euc','utf8','h',"\x8E\xC1"),
("\xEF\xBE\x82",'euc','utf8','h',"\x8E\xC2"),
("\xEF\xBE\x83",'euc','utf8','h',"\x8E\xC3"),
("\xEF\xBE\x84",'euc','utf8','h',"\x8E\xC4"),
("\xEF\xBE\x85",'euc','utf8','h',"\x8E\xC5"),
("\xEF\xBE\x86",'euc','utf8','h',"\x8E\xC6"),
("\xEF\xBE\x87",'euc','utf8','h',"\x8E\xC7"),
("\xEF\xBE\x88",'euc','utf8','h',"\x8E\xC8"),
("\xEF\xBE\x89",'euc','utf8','h',"\x8E\xC9"),
("\xEF\xBE\x8A",'euc','utf8','h',"\x8E\xCA"),
("\xEF\xBE\x8B",'euc','utf8','h',"\x8E\xCB"),
("\xEF\xBE\x8C",'euc','utf8','h',"\x8E\xCC"),
("\xEF\xBE\x8D",'euc','utf8','h',"\x8E\xCD"),
("\xEF\xBE\x8E",'euc','utf8','h',"\x8E\xCE"),
("\xEF\xBE\x8F",'euc','utf8','h',"\x8E\xCF"),
("\xEF\xBE\x90",'euc','utf8','h',"\x8E\xD0"),
("\xEF\xBE\x91",'euc','utf8','h',"\x8E\xD1"),
("\xEF\xBE\x92",'euc','utf8','h',"\x8E\xD2"),
("\xEF\xBE\x93",'euc','utf8','h',"\x8E\xD3"),
("\xEF\xBE\x94",'euc','utf8','h',"\x8E\xD4"),
("\xEF\xBE\x95",'euc','utf8','h',"\x8E\xD5"),
("\xEF\xBE\x96",'euc','utf8','h',"\x8E\xD6"),
("\xEF\xBE\x97",'euc','utf8','h',"\x8E\xD7"),
("\xEF\xBE\x98",'euc','utf8','h',"\x8E\xD8"),
("\xEF\xBE\x99",'euc','utf8','h',"\x8E\xD9"),
("\xEF\xBE\x9A",'euc','utf8','h',"\x8E\xDA"),
("\xEF\xBE\x9B",'euc','utf8','h',"\x8E\xDB"),
("\xEF\xBE\x9C",'euc','utf8','h',"\x8E\xDC"),
("\xEF\xBE\x9D",'euc','utf8','h',"\x8E\xDD"),
("\xEF\xBE\x9E",'euc','utf8','h',"\x8E\xDE"),
("\xEF\xBE\x9F",'euc','utf8','h',"\x8E\xDF"),
("\xEF\xBF\xA0",'euc','utf8','h',"\xA1\xF1"),
("\xEF\xBF\xA1",'euc','utf8','h',"\xA1\xF2"),
("\xEF\xBF\xA2",'euc','utf8','h',"\xA2\xCC"),
("\xEF\xBF\xA3",'euc','utf8','h',"\xA1\xB1"),
("\xEF\xBF\xA4",'euc','utf8','h',"\xA2\xAE"),
("\xEF\xBF\xA5",'euc','utf8','h',"\xA1\xEF"),
("\xFD",'euc','utf8','h',"\xFD"),
("\xFE",'euc','utf8','h',"\xFE"),
("\xFF",'euc','utf8','h',"\xFF"),
);

print "1..", scalar(@todo)/5, "\n";
$tno = 1;

while (($give,$OUTPUT_encoding,$INPUT_encoding,$option,$want) = splice(@todo,0,5)) {
    $got = $give;
    &jacode'convert(*got,$OUTPUT_encoding,$INPUT_encoding,$option);
    if ($got eq $want) {
        printf(    "ok $tno - give=(%s) want=(%s) got=(%s)\n", unpack('H*',$give), unpack('H*',$want), unpack('H*',$got));
    }
    else {
        printf("not ok $tno - give=(%s) want=(%s) got=(%s)\n", unpack('H*',$give), unpack('H*',$want), unpack('H*',$got));
    }
    $tno++;
}

__END__
