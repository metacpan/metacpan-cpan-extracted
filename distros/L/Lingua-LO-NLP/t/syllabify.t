#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature 'unicode_strings';
use open ':encoding(UTF-8)', ':std';
use Test::More;
use Test::Fatal;
use charnames qw/ :full lao /;
use Unicode::Normalize qw/ reorder NFC /;
use Lingua::LO::NLP::Syllabify;

my %TEST_SYLLABLES = (
    ""          => [],
    ສະບາຍດີ      => [ qw/ ສະ ບາຍ ດີ / ],
    ກວ່າດອກ      => [ qw/ ກວ່າ ດອກ /],
    ເພື່ອນ        => [ qw/ ເພື່ອນ / ],
    # ຜູ້ເຂົ້າ        => [ qw/ ຜູ້ ເຂົ້າ /],    # drop invalid second syllable
    "\N{LAO LETTER PHO SUNG}\N{LAO VOWEL SIGN UU}\N{LAO TONE MAI THO}\N{LAO VOWEL SIGN E}\N{LAO LETTER KHO SUNG}\N{LAO VOWEL SIGN I}\N{LAO TONE MAI THO}\N{LAO VOWEL SIGN AA}"
    => [ "\N{LAO LETTER PHO SUNG}\N{LAO VOWEL SIGN UU}\N{LAO TONE MAI THO}" ],
    "\N{LAO LETTER PHO SUNG}\N{LAO VOWEL SIGN UU}\N{LAO TONE MAI THO}\N{ZERO WIDTH SPACE}\N{LAO VOWEL SIGN E}\N{LAO LETTER KHO SUNG}\N{LAO VOWEL SIGN I}\N{LAO TONE MAI THO}\N{LAO VOWEL SIGN AA}"
    => [ "\N{LAO LETTER PHO SUNG}\N{LAO VOWEL SIGN UU}\N{LAO TONE MAI THO}" ],
    ກວ່າດອກ໐໑໒໓  => [qw/ ກວ່າ ດອກ ໐໑໒໓ /],
    ຄຳດີ         => [qw/ ຄຳ ດີ /],   # composed sala am
    ຄໍາດີ         => [qw/ ຄໍາ ດີ /],   # decomposed sala am
    ຄໍາູດີ         => [qw/ ດີ /],      # malformed first syllable "khamu" dropped
    ກັ           => [ ],
    ກັນ          => [qw/ ກັນ / ],
    ກັວນ         => [qw/ ກັວນ / ],
    ກົ           => [ ],
    ກົດ          => [qw/ ກົດ / ],
    ກັອກ         => [ ],
    ແປຽ         => [qw/ ແປຽ / ],
    ເກັາະ        => [ ],
    ມື້ນີ້          => [qw/ ມື້ ນີ້ /],
    'ມະນຸດທຸກຄົນເກີດມາມີກຽດສັກສີ/ສິດທິ/ເສຣີພາບແລະຄວາມສເມີພາບເທົ່າທຽມກັນ. ທຸກໆຄົນມີເຫດຜົນແລະຄວາມຄິດຄວາມເຫັນສ່ວນຕົວຂອງໃຜຂອງມັນ/ແຕ່ວ່າມະນຸດທຸກໆຄົນຄວນປະພຶດຕໍ່ກັນຄືກັນກັບເປັນອ້າຍນ້ອງກັນ' => [ qw/ ມະ ນຸດ ທຸກ ຄົນ ເກີດ ມາ ມີ ກຽດ ສັກ ສີ ສິດ ທິ ເສຣີ ພາບ ແລະ ເມີ ພາບ ເທົ່າ ທຽມ ກັນ ທຸກໆ ຄົນ ມີ ເຫດ ຜົນ ແລະ ຄວາມ ຄິດ ຄວາມ ເຫັນ ສ່ວນ ຕົວ ຂອງ ໃຜ ຂອງ ມັນ ແຕ່ ວ່າ ມະ ນຸດ ທຸກໆ ຄົນ ຄວນ ປະ ພຶດ ຕໍ່ ກັນ ຄື ກັນ ກັບ ເປັນ ອ້າຍ ນ້ອງ ກັນ /],
);

my %TEST_FRAGMENTS = (
    'bla ສະບາຍ ດີ foo ດີ bar baz' => {
        result => [
            { text => 'bla ', is_lao => '' },
            { text => 'ສະ', is_lao => 1 },
            { text => 'ບາຍ', is_lao => 1 },
            { text => ' ', is_lao => '' },
            { text => 'ດີ', is_lao => 1 },
            { text => ' foo ', is_lao => '' },
            { text => 'ດີ', is_lao => 1 },
            { text => ' bar baz', is_lao => '' },
        ],
        message => "get_fragments() segments mixed Lao/other text",
    },
    "bla\nfoo ສະບາຍດີ\nbazດີ ເພື່ອນ" => {
        result => [
            { text => "bla\nfoo ", is_lao => '' },
            { text => "ສະ", is_lao => 1 },
            { text => "ບາຍ", is_lao => 1 },
            { text => "ດີ", is_lao => 1 },
            { text => "\nbaz", is_lao => '' },
            { text => "ດີ", is_lao => 1 },
            { text => " ", is_lao => '' },
            { text => "ເພື່ອນ", is_lao => 1 },
        ],
        message => "get_fragments() segments mixed text with newlines",
    },
    "ບ່ອນ\N{ZERO WIDTH SPACE}ຈອດ\N{ZERO WIDTH SPACE}ລົດ" => {
        result => [
            { text => "ບ່ອນ", is_lao => 1 },
            { text => "ຈອດ", is_lao => 1 },
            { text => "ລົດ", is_lao => 1 },
        ],
        message => "get_fragments() ignores embedded ZERO WIDTH SPACE",
    }
);


sub dump_unicode {
    my $s = shift;
    return sprintf(q["%s"], join(" ", map { sprintf("%03x", ord) } split //, $s));
}

sub dump_unicode_list {
    return sprintf('[ %s ]', join(", ", map { dump_unicode($_) } @_));
}

sub test_method {
    my ($tests, $method, $options) = @_;
    $options //= [];

    for my $text (sort keys %$tests) {
        my $o = Lingua::LO::NLP::Syllabify->new($text, @$options);
        my ($result, $message);
        if(ref $tests->{$text} eq 'HASH') {
            $result = $tests->{$text}{result};
            $message = $tests->{$text}{message};
        } else {
            $result = $tests->{$text};
            $message = "`$text' split correctly by $method [@$options]";
        }
        my $syl = [ $o->$method ];
        unless( is_deeply($syl, $result, $message) ) {
            warn "Wanted: " . dump_unicode_list(@$result) .
            "\nFound : " . dump_unicode_list(@$syl) .
            "\nText:   " . dump_unicode($text) . sprintf('(%s)', $text). 
            "\nNormal: " . dump_unicode(reorder(NFC($text))) . sprintf('(%s)' ,reorder(NFC($text))) .
            "\n";
        }
    }
}

my $o = Lingua::LO::NLP::Syllabify->new('ສະບາຍດີ');
isa_ok($o, 'Lingua::LO::NLP::Syllabify');

like(
    exception { Lingua::LO::NLP::Syllabify->new },
    qr/`text' argument missing or undefined/,
    "Constructor dies w/o text arg"
);

# Normalization
is_deeply(
    [ Lingua::LO::NLP::Syllabify->new(
        "ຄຳດີ".
        "\N{LAO VOWEL SIGN E}\N{LAO LETTER MO}\N{LAO TONE MAI EK}" .
        "\N{LAO VOWEL SIGN YY}\N{LAO LETTER O}",
        normalize => 1
    )->get_syllables ],
    [
        "ຄຳ",
        "ດີ",
        "\N{LAO VOWEL SIGN E}\N{LAO LETTER MO}\N{LAO VOWEL SIGN YY}".
        "\N{LAO TONE MAI EK}\N{LAO LETTER O}"
    ],
    "Normalization works"
);
test_method(\%TEST_SYLLABLES, "get_syllables");
test_method(\%TEST_FRAGMENTS, "get_fragments");

done_testing;

