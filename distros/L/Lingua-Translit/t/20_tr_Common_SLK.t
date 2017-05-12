use strict;
use Test::More tests => 4;

my $name	=   "Common SLK";

# Taken from http://www.unhchr.ch/udhr/lang/slo.htm
my $input	=   "že ľud Spojených národov zdoraznil v Charte " .
		    "znovu svoju vieru v základné ľudské práva, v " .
		    "dostojnosť a hodnotu ľudskej osobnosti, v rovnaké " .
		    "práva mužov a žien a že sa rozhodol podporovať " .
		    "sociálny pokrok a vytvoriť lepšie životné " .
		    "podmienky za vačšej slobody, že členské štáty " .
		    "prevzaly závazok zaistiť v spolupráci s " .
		    "Organizáciou Spojeých národov všeobecné uznávanie " .
		    "a zachovávanie ľudských práv a základýých slobod. " .
		    "- dôstojnosti";
my $output_ok	=   "ze lud Spojenych narodov zdoraznil v Charte " .
		    "znovu svoju vieru v zakladne ludske prava, v " .
		    "dostojnost a hodnotu ludskej osobnosti, v rovnake " .
		    "prava muzov a zien a ze sa rozhodol podporovat " .
		    "socialny pokrok a vytvorit lepsie zivotne podmienky " .
		    "za vacsej slobody, ze clenske staty prevzaly " .
		    "zavazok zaistit v spolupraci s Organizaciou " .
		    "Spojeych narodov vseobecne uznavanie a zachovavanie " .
		    "ludskych prav a zakladyych slobod. - dostojnosti";

my $all_caps	=   "VŠOBECNÁ DEKLARÁCIA LUDSKÝCH PRÁV";
my $all_caps_ok	=   "VSOBECNA DEKLARACIA LUDSKYCH PRAV";

my $digraphs	=   "MEǱI - ǄEM";
my $digraphs_ok	=   "MEDZI - DZEM";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);


my $output = $tr->translit($input);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

# 2
is($output, $output_ok, "$name: UDOHR transliteration");

my $o = $tr->translit($all_caps);

# 3
is($o, $all_caps_ok, "$name: all caps");

$o = $tr->translit($digraphs);

# 4
is($o, $digraphs_ok, "$name: digraphs");
