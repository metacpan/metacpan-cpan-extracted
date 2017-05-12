use strict;
use Test::More tests => 5;
use Encode qw/decode/;

my $name        = "ISO/R 9 - SR";

# Copyright (c) Zoran Radisavljević
my $pangram1      = "Њој пљачком згрћеш туђ ЦД, ВХС, беж филџан!";
my $pangram1_ok   = "Njoj pljačkom zgrćeš tuđ CD, VHS, bež fildžan!";

# Copyright (c) Rastko Ćirić
my $pangram2      = "Дебљој згужвах смеђ филц – њен шкрт џепчић.";
my $pangram2_ok   = "Debljoj zgužvah smeđ filc – njen škrt džepčić.";

# Copyright (c) Ivan Klajn
my $pangram3      = "Ђаче, уштеду плаћај жаљењем због џиновских цифара.";
my $pangram3_ok   = "Đače, uštedu plaćaj žaljenjem zbog džinovskih cifara.";

my $lower_case    = "абвгдђежзијклљмнњопрстћуфхцчџш";
my $lower_case_ok = "abvgdđežzijklljmnnjoprstćufhcčdžš";

my $upper_case    = "АБВГДЂЕЖЗИЈКЛЉМНЊОПРСТЋУФХЦЧЏШ";
my $upper_case_ok = "ABVGDĐEŽZIJKLLJMNNJOPRSTĆUFHCČDŽŠ";

use Lingua::Translit;

my $tr = new Lingua::Translit("ISO/R 9");

# 1
my $output = $tr->translit($pangram1);
is($output, $pangram1_ok, "$name: Serbian pangram (33) transliteration");

# 2
$output = $tr->translit($pangram2);
is($output, $pangram2_ok, "$name: Serbian pangram (34) transliteration");

# 3
$output = $tr->translit($pangram3);
is($output, $pangram3_ok, "$name: Serbian pangram (42) transliteration");

# 4
$output = $tr->translit($lower_case);
is($output, $lower_case_ok, "$name: lower case alphabet");

# 5
$output = $tr->translit($upper_case);
is($output, $upper_case_ok, "$name: upper case alphabet");
