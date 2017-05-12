use strict;
require 5.008;
use utf8;

use Test::More tests => 3;

my $name	=   "Streamlined System BUL";

# Taken from http://www.unhchr.ch/udhr/lang/blg.htm
my $udohr_cyr	= "Като взе предвид, че пренебрегването и неуважаването " .
		  "на правата на човека доведоха до варварски деяния, " .
		  "които потресоха съвестта на човечеството, и че ".
		  "създаването на един свят, в който хората ще се радват ".
		  "на свобода на словото и убежденията си и ще бъдат " .
		  "свободни от страх и лишения бе провъзгласено за " .
		  "най-съкровения стремеж на човека,";  

my $udohr_lat	= "Kato vze predvid, che prenebregvaneto i " .
		  "neuvazhavaneto na pravata na choveka dovedoha do " .
		  "varvarski deyaniya, koito potresoha savestta na " .
		  "chovechestvoto, i che sazdavaneto na edin svyat, v " .
		  "koyto horata shte se radvat na svoboda na slovoto " .
		  "i ubezhdeniyata si i shte badat svobodni ot strah i " .
		  "lisheniya be provazglaseno za nay-sakroveniya " .
		  "stremezh na choveka,";  

my $all_caps	= "ОБЩОТО , ВСЕОБЩА , ДЕКЛАРАЦЯ , ПРЕАМБЮЛ , ЧОВЕКА" .
		  " --- Член, Живопис, Шоуто, Южна Америка";
my $all_caps_ok	= "OBSHTOTO , VSEOBSHTA , DEKLARATSYA , PREAMBYUL , " .
		  "CHOVEKA --- Chlen, Zhivopis, Shouto, Yuzhna Amerika";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

my $o = $tr->translit($udohr_cyr);

# 2
is($o, $udohr_lat, "$name: UDOHR transliteration");

$o = $tr->translit($all_caps);

# 3
is($o, $all_caps_ok, "$name: all caps");
