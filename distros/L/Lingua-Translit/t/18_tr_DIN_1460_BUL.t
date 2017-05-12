use strict;
require 5.008;

use Test::More tests => 7;

my $name	=   "DIN 1460 BUL";

# Taken from http://www.unhchr.ch/udhr/lang/blg.htm
my $udohr_cyr	= "Като взе предвид, че пренебрегването и неуважаването " .
		  "на правата на човека доведоха до варварски деяния, " .
		  "които потресоха съвестта на човечеството, и че ".
		  "създаването на един свят, в който хората ще се радват ".
		  "на свобода на словото и убежденията си и ще бъдат " .
		  "свободни от страх и лишения бе провъзгласено за " .
		  "най-съкровения стремеж на човека,";  

my $udohr_lat	= "Kato vze predvid, če prenebregvaneto i " .
		  "neuvažavaneto na pravata na čoveka dovedocha ".
		  "do varvarski dejanija, koito potresocha săvestta " .
		  "na čovečestvoto, i če săzdavaneto na edin svjat, v " .
		  "kojto chorata šte se radvat na svoboda na slovoto i " .
		  "ubeždenijata si i šte bădat svobodni ot strach i " .
		  "lišenija be provăzglaseno za naj-săkrovenija stremež " .
		  "na čoveka,";  


# Test hyphen
my $hyphen_cyr = "равнище, юрисдикция, задължиха, " .  # small without
		 "Южнославянски, Хърватски, " .	       # capital without
		 "йа, ЙАК, йу, Йуно, пешть, ШТАБ, Штаб";
		  # these need a hyphen, but as it is very unlikely to
		  # find these combinations, the examples are construed

 my $hyphen_lat = "ravnište, jurisdikcija, zadălžicha, " .
		  "Južnoslavjanski, Chărvatski, " .
		  "j-a, J-AK, j-u, J-uno, peš-t', Š-TAB, Š-tab";

# Test all caps, hard and soft signs
my $context_cyr	= "ОБЩОТО , ВСЕОБЩА , ДЕКЛАРАЦЯ , ПРЕАМБЮЛ --- " . #allcaps
		  "внукът , Ъгъл , СЪБРАИНЕ --- " .		# hard sign
		  "актьор , СИНЬО" ;			        # soft sign
my $context_lat	= "OBŠTOTO , VSEOBŠTA , DEKLARACJA , PREAMBJUL --- " .
		  "vnukăt , Ăgăl , SĂBRAINE --- " .
		  "akt'or , SIN'O";

use Lingua::Translit;

my $tr = new Lingua::Translit($name);

# 1
is($tr->can_reverse(), 1, "$name: is reversible");

my $o = $tr->translit($context_cyr);

# 2
is($o, $context_lat, "$name: hard and soft signs");

$o = $tr->translit_reverse($o);

# 3
is($o, $context_cyr, "$name: hard and soft signs (reverse)");

$o = $tr->translit($udohr_cyr);

# 4
is($o, $udohr_lat, "$name: UDOHR transliteration");

$o = $tr->translit_reverse($o);

# 5
is($o, $udohr_cyr, "$name: UDOHR transliteration (reverse)");

$o = $tr->translit($hyphen_cyr);

# 6
is($o, $hyphen_lat, "$name: hyphen separator");

$o = $tr->translit_reverse($o);

# 7
is($o, $hyphen_cyr, "$name: hyphen separator (reverse)");
