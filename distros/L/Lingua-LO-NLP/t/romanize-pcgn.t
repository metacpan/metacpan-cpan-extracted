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
    'ເຄື່ອງກໍາເນີດໄຟຟ້າ' => 'khuang-kam-neut-fai-fa',
    'ສະບາຍດີ'    => 'sa-bay-di',
    'ດີໆ'        => 'di-di',
    'ແຫນ'       => 'hèn',
    'ແໜ'        => 'nè',
    'ຫົກສິບ'      => 'hôk-sip',
    'ມື້ນີ້'        => 'mu-ni',
    'ມື້ວານນີ້'     => 'mu-van-ni',
    'ໃຫຍ່'       => 'gnai',
    'ຕົວ'        => 'toua',
    'ຄົນ'        => 'khôn',
    'ໃນວົງ'      => 'nai-vông',
    'ເຫຼົາ'       => 'lao',
    'ເຫງ'       => 'héng',
    'ຫວາດ'      => 'vat',
    'ເສລີ'       => 'sleu',
    'ຄວາມ'      => 'khoam',
    'ຫຼາຍ'       => 'lay',
    'ຊອຍ'       => 'xoy',
    'ສະບາຍດີ foo bar ສະ' => 'sa-bay-di foo bar sa',
    'ຫນ່າງກັນຍຸງ'  => 'nang-kan-gnoung',
    'ພອຍໄພລິນ'   => 'phoy-phai-lin',
    'ຄ່ອຍໆ'      => 'khoy-khoy',
    'ມາຕີອາຊ໌'    => 'ma-ti-a',   # TODO?
    'ຫິວ'        => 'hiou',
    'ເພາະ'      => 'pho',
    'ແນວໃດ'     => 'nèo-dai',
    'ຂີ້ເຫຍື່ອ'     => 'khi-gnua',
    'ເຄີຍ'       => 'kheuy',
);
@tests % 2 and BAIL_OUT('BUG: set up \@tests correctly!');

my $r = Lingua::LO::NLP::Romanize->new(variant => 'PCGN', hyphen => 1);
isa_ok($r, 'Lingua::LO::NLP::Romanize::PCGN');

while(my $word = shift @tests) {
    my $romanized = shift @tests;
    is($r->romanize($word), $romanized, "$word romanized to `$romanized'");
}

# No hyphentaion
is(
    Lingua::LO::NLP::Romanize->new(variant => 'PCGN')->romanize('ສະບາຍດີ'), 'sa bay di',
    "ສະບາຍດີ => 'sa bay di'"
);

# Unicode hyphentaion
is(
    Lingua::LO::NLP::Romanize->new(variant => 'PCGN', hyphen => "\N{HYPHEN}")->romanize('ສະບາຍດີ'),
    "sa\N{HYPHEN}bay\N{HYPHEN}di",
    "ສະບາຍດີ => 'sa\N{HYPHEN}bay\N{HYPHEN}di'"
);

done_testing;

