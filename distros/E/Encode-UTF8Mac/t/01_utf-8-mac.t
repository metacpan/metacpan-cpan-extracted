use strict;
use warnings;
use Test::More;
binmode Test::More->builder->$_ => ':utf8'
    for qw(output failure_output todo_output);

use Encode;
use Encode::UTF8Mac;

my $unicode = join('',
    "\x{3060}",         # HIRAGANA LETTER DA / NFD() => TA + MARK
    "\x{3093}",         # HIRAGANA LETTER N
    "\x{3053}",         # HIRAGANA LETTER KO
    "\x{304C}",         # HIRAGANA LETTER GA / NFD() => KA + MARK
    "\x{3044}",         # HIRAGANA LETTER I
    "\x{3071}",         # HIRAGANA LETTER PA / NFD() => HA + MARK
    "\x{30D1}",         # KATAKANA LETTER PA / NFD() => HA + MARK
    "\x{FA1B}",         # Chinese Kanji FUKU(lucky)   / NFD() => U+798F
    "\x{2F872}",        # Chinese Kanji JU(long-life) / NFD() => U+5BFF
);

my $utf8bytes = join('',
    "\xe3\x81\x9f",     # HIRAGANA LETTER TA
    "\xe3\x82\x99",     # COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK
    "\xe3\x82\x93",     # HIRAGANA LETTER N
    "\xe3\x81\x93",     # HIRAGANA LETTER KO
    "\xe3\x81\x8b",     # HIRAGANA LETTER KA
    "\xe3\x82\x99",     # COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK
    "\xe3\x81\x84",     # HIRAGANA LETTER I
    "\xe3\x81\xaf",     # HIRAGANA LETTER HA
    "\xe3\x82\x9a",     # COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
    "\xe3\x83\x8f",     # KATAKANA LETTER HA
    "\xe3\x82\x9a",     # COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
    "\xef\xa8\x9b",     # CJK COMPATIBILITY IDEOGRAPH-FA1B
    "\xf0\xaf\xa1\xb2", # CJK COMPATIBILITY IDEOGRAPH-2F872
);

is(Encode::decode('utf-8-mac', $utf8bytes), $unicode, 'decode()');
is(Encode::encode('utf-8-mac', $unicode), $utf8bytes, 'encode()');


for my $code (
    0x2000  .. 0x2FFF,
    0xF900  .. 0xFAFF,
    0x2F800 .. 0x2FAFF,
) {
    is(
        Encode::encode('utf-8-mac', chr $code),
        Encode::encode('utf-8', chr $code),
        sprintf('U+%X', $code)
    );
}

done_testing();
