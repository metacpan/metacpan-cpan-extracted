use strict;
use warnings;
use utf8;
my $HEBREW_STRING = q{שלום כתה א'. היום נסייר בחצר ביה"ס ובבניין אגף המנהלה. בנוסף, נתרוצץ בהפסקה כך שנתעייף.  א ב ג ד ה ו ז ח ט י ך כ ל ם מ ן נ ס ע ף פ ץ צ ק ר ש ת}; #'
my $TREEBANK_STRING = q{FLWM KTH A'. HIWM NSIIR BXCR BIHUS WBBNIIN AGP HMNHLH. BNWSP, NTRWCC BHPSQH KK FNTEIIP.  A B G D H W Z X J I K K L M M N N S E P P C C Q R F T}; #'
my $EREL_STRING = q{$LWM KTH A'. HIWM NSIIR BXCR BIH"S WBBNIIN AGP HMNHLH. BNWSP, NTRWCC BHPSQH KK $NT&IIP.  A B G D H W Z X @ I K K L M M N N S & P P C C Q R $ T}; #'
my $FSMA_STRING = q{elwm kth a'. hiwm nsiir bxcr bih"s wbbniin agp hmnhlh. bnwsp, ntrwcc bhpsqh kk entyiip.  a b g d h w z x v i k k l m m n n s y p p c c q r e t}; #'
my $HEBREW_STRING_NO_FINAL_LETTERS = q{שלומ כתה א'. היומ נסייר בחצר ביה"ס ובבניינ אגפ המנהלה. בנוספ, נתרוצצ בהפסקה ככ שנתעייפ.  א ב ג ד ה ו ז ח ט י כ כ ל מ מ נ נ ס ע פ פ צ צ ק ר ש ת}; #'


use Test::More tests => 9;

use lib "lib";
use MILA::Transliterate qw(hebrew2treebank treebank2hebrew hebrew2erel erel2hebrew hebrew2fsma fsma2hebrew);

ok( hebrew2treebank($HEBREW_STRING) eq $TREEBANK_STRING, "hebrew2treebank transliteration" );
ok( hebrew2erel($HEBREW_STRING) eq $EREL_STRING, "hebrew2erel transliteration" );
ok( hebrew2fsma($HEBREW_STRING) eq $FSMA_STRING, "hebrew2fsma transliteration" );
ok( treebank2hebrew($TREEBANK_STRING) eq $HEBREW_STRING_NO_FINAL_LETTERS, "treebank2hebrew transliteration" );
ok( erel2hebrew($EREL_STRING) eq $HEBREW_STRING_NO_FINAL_LETTERS, "erel2hebrew transliteration" );
ok( fsma2hebrew($FSMA_STRING) eq $HEBREW_STRING_NO_FINAL_LETTERS, "fsma2hebrew transliteration" );
ok( treebank2hebrew($TREEBANK_STRING) ne $HEBREW_STRING, "treebank2hebrew transliteration: final letters not perserved (OK)" );
ok( erel2hebrew($EREL_STRING) ne $HEBREW_STRING, "erel2hebrew transliteration: final letters not perserved (OK)" );
ok( fsma2hebrew($FSMA_STRING) ne $HEBREW_STRING, "fsma2hebrew transliteration: final letters not perserved (OK)" );
