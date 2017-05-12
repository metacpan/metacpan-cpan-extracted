use strict;
require 5.008;
use utf8;

use Test::More tests => 5;

my $name	=   "ISO 9";

# Taken from http://www.unhchr.ch/udhr/lang/rus.htm
my $udohr_cyr	=   "Каждый человек должен обладать всеми правами и всеми " .
		    "свободами, провозглашенными настоящей Декларацией, " .
		    "без какого бы то ни было различия, как-то в отношении " .
		    "расы, цвета кожи, пола, языка, религии, политических " .
		    "или иных убеждений, национального или социального " .
		    "происхождения, имущественного, сословного или иного " .
		    "положения.";
my $udohr_lat	=   "Každyj čelovek dolžen obladatʹ vsemi pravami i vsemi " .
		    "svobodami, provozglašennymi nastoâŝej Deklaraciej, " .
		    "bez kakogo by to ni bylo različiâ, kak-to v otnošenii " .
		    "rasy, cveta koži, pola, âzyka, religii, političeskih " .
		    "ili inyh ubeždenij, nacionalʹnogo ili socialʹnogo " .
		    "proishoždeniâ, imuŝestvennogo, soslovnogo ili inogo " .
		    "položeniâ.";

# Test hard and soft signs
my $context_cyr	=   "ВЪЕЗД - въезд - альбом";
my $context_lat	=   "VʺEZD - vʺezd - alʹbom";

use Lingua::Translit;

my $tr = new Lingua::Translit($name);

# 1
is($tr->can_reverse(), 1, "$name: is reversible");

my $o = $tr->translit($context_cyr);

# 2
is($o, $context_lat, "$name: hard and soft signs");

$o = $tr->translit_reverse($o);

# 3
is($o, $context_cyr, "$name: hard and soft signs: reverse");

$o = $tr->translit($udohr_cyr);

# 4
is($o, $udohr_lat, "$name: UDOHR transliteration");

$o = $tr->translit_reverse($o);

# 5
is($o, $udohr_cyr, "$name: UDOHR transliteration (reverse)");
