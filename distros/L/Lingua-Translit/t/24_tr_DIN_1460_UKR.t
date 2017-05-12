use strict;
require 5.008;

use Test::More tests => 7;

my $name      =   "DIN 1460 UKR";

# Taken from http://www.ohchr.org/EN/UDHR/Pages/Language.aspx?LangID=ukr
my $udohr_cyr = 'Всі люди народжуються вільними і рівними у своїй гідності' .
                ' та правах. Вони наділені розумом і совістю і повинні ' .
                'діяти у відношенні один до одного в дусі братерства.';
my $udohr_lat = 'Vsi ljudy narodžujut\'sja vil\'nymy i rivnymy u svoïj ' .
                'hidnosti ta pravach. Vony nadileni rozumom i sovistju i ' .
                'povynni dijaty u vidnošenni odyn do odnoho v dusi ' .
                'braterstva.';
my $hypen_cyr = 'йехьван - минийаь - зівйуться - ' .
                'цг - тверді ч, шч';
my $hypen_lat = 'j-ech\'van - mynyj-a\' - zivj-ut\'sja - ' .
                'c-h - tverdi č, š-č';

my $caps_cyr  = 'ЗАГАЛЬНА ДЕКЛАРАЦІЯ ПРАВ ЛЮДИНІ';
my $caps_lat  = 'ZAHAL\'NA DEKLARACIJA PRAV LJUDYNI';


use Lingua::Translit;

my $tr = new Lingua::Translit($name);

# 1
is($tr->can_reverse(), 1, "$name: is reversible");

my $o = $tr->translit($udohr_cyr);

# 2
is($o, $udohr_lat, "$name: UDOHR transliteration");

$o = $tr->translit_reverse($o);

# 3
is($o, $udohr_cyr, "$name: UDOHR transliteration (reverse)");

$o = $tr->translit($hypen_cyr);

# 4
is($o, $hypen_lat, "$name: DIN 1460 §3");

$o = $tr->translit_reverse($o);

# 5
is($o, $hypen_cyr, "$name: DIN 1460 §3 (reverse)");

$o = $tr->translit($caps_cyr);

# 6
is($o, $caps_lat, "$name: capital letters only");

$o = $tr->translit_reverse($o);

# 7
is($o, $caps_cyr, "$name: capital letters only (reverse)");


# vim: sts=4 sw=4 ai et ft=perl
