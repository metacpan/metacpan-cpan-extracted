use strict;
use warnings;
use Test::More;
binmode Test::More->builder->$_ => ':utf8'
    for qw(output failure_output todo_output);

use Unicode::Normalize::Mac;

my %map = (
    "\x{00E9}" => "\x{0065}\x{0301}", # LATIN SMALL LETTER E WITH ACUTE
    "\x{3060}" => "\x{305F}\x{3099}", # HIRAGANA LETTER DA
    "\x{FA1B}" => "\x{FA1B}",         # Chinese Kanji FUKU(lucky) / NFD() => U+798F
    "0"        => "0",                # 0
    ""         => "",                 # empty string
);

while (my ($c, $d) = each %map) {
    is(Unicode::Normalize::Mac::NFD($c), $d, "($c)");
    is(Unicode::Normalize::Mac::NFC($d), $c, "($c)");
}

subtest 'export functions' => sub {
    use Unicode::Normalize::Mac qw/NFD_mac NFC_mac/;

    my $text = NFC_mac("\x{FA1B}\x{2F872}\x{305F}\x{3099}");
    is($text, "\x{FA1B}\x{2F872}\x{3060}", "synopsis");

    while (my ($c, $d) = each %map) {
        is(NFD_mac($c), $d);
        is(NFC_mac($d), $c);
    }
};

done_testing();
