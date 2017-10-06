#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature 'unicode_strings';
use charnames qw/ :full lao /;
use open qw/ :encoding(UTF-8) :std /;
BEGIN { use lib -d 't' ? "t/lib" : "lib"; }
use Test::More;
use Lingua::LO::NLP::Romanize;

my @tests = (
    'ເຄື່ອງກໍາເນີດໄຟຟ້າ' => ['kʰɯ̄ːəŋ kám nɤ̂ːt fáj fâː', 'kʰɯːəŋ kam nɤːt faj faː'],
    'ສະບາຍດີ'    => ['sáʔ bàːj dìː', 'saʔ baːj diː'],
    'ດີໆ'        => ['dìː-dìː', 'diː-diː'],
    'ເລື້ອຍໆ'     => ['lɯ̂ːəi-lɯ̂ːəi', 'lɯːəi-lɯːəi' ],
    'ແນວໃດ'     => ['nɛ́ːw dàj', 'nɛːw daj'],    # TODO: nɛ́ːw or nɛ́ːo?
    'ທີ່ສຸດ'       => ['tʰīː sút', 'tʰiː sut'],
);
@tests % 2 and BAIL_OUT('BUG: set up \@tests correctly!');

my $r_tone = Lingua::LO::NLP::Romanize->new(variant => 'IPA', tone => 1);
isa_ok($r_tone, 'Lingua::LO::NLP::Romanize::IPA');
my $r_notone = Lingua::LO::NLP::Romanize->new(variant => 'IPA');

while(my $word = shift @tests) {
    my $romanized = shift @tests;
    is($r_tone->romanize($word), $romanized->[0], "$word romanized to `$romanized->[0]' with tones");
    is($r_notone->romanize($word), $romanized->[1], "$word romanized to `$romanized->[1]' without tones");
}

done_testing;

