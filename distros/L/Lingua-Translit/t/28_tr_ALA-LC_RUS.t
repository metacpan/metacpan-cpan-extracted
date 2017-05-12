use strict;
use Test::More tests => 4;

my $name        =   "ALA-LC RUS";
my $reversible  =   0;

my $upper       =   "AБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ";
my $upper_ok    =   "ABVGDEËZhZIĬKLMNOPRSTUFKhTSChShShch″Y′ĖIUIA";

my $lower       =   "aбвгдеёжзийклмнопрстуфхцчшщъыьэюя";
my $lower_ok    =   "abvgdeëzhziĭklmnoprstufkhtschshshch″y′ėiuia";

my $context     =   "труъ ТРУЪ";
my $context_ok  =   "tru TRU";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);

my $output;


# 1
is($tr->can_reverse(), $reversible, "$name: reversibility");

# 2
$output = $tr->translit($upper);
is($output, $upper_ok, "$name: upper transliteration");

# 3
$output = $tr->translit($lower);
is($output, $lower_ok, "$name: lower transliteration");

# 4
$output = $tr->translit($context);
is($output, $context_ok, "$name: transliteration (context-sensitive)");

# vim: sts=4 sw=4 ai et
