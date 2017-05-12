use strict;
require 5.008;

use Test::More tests => 7;

my $name      =   "DIN 1460 RUS";

# Taken from http://www.ohchr.org/EN/UDHR/Pages/Language.aspx?LangID=rus
my $udohr_cyr = 'Все люди рождаются свободными и равными в своем ' .
                'достоинстве и правах. Они наделены разумом и совестью и ' .
                'должны поступать в отношении друг друга в духе братства.';
my $udohr_lat = 'Vse ljudi roždajutsja svobodnymi i ravnymi v svoem ' .
                'dostoinstve i pravach. Oni nadeleny razumom i sovest\'ju ' .
                'i dolžny postupat\' v otnošenii drug druga v duche ' .
                'bratstva.';

my $hypen_cyr = 'также известен как Йа криве́дко - ' .
                'от эск. йугыт, йуит люди - ' .
                'Кандалакшская (ШЧ-20)';
my $hypen_lat = 'takže izvesten kak J-a krivédko - ' .
                'ot ėsk. j-ugyt, j-uit ljudi - ' .
                'Kandalakšskaja (Š-Č-20)';

my $sign_cyr  = 'объявлять - высказаться - ОБЯЗАЛИСЬ - ' .
                'выстроилисъ - ПРЕДЪ';
my $sign_lat  = 'ob"javljat\' - vyskazat\'sja - OBJAZALIS\' - ' .
                'vystroilis" - PRED"';


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

$o = $tr->translit($sign_cyr);

# 6
is($o, $sign_lat, "$name: hard and soft signs");

$o = $tr->translit_reverse($o);

# 7
is($o, $sign_cyr, "$name: hard and soft signs (reverse)");

# vim: sts=4 sw=4 ai et ft=perl
