# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lingua-UK-Translit.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 6 };
use utf8;
use Lingua::UK::Translit;
ok(1); # If we made it this far, than ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#test2 - common transliteration of Ukrainian letters
ok( uk2ascii("АаБбВвГгҐґДдЕеЄєЖжЗзИиІіЇїЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЮюЯяЬь"),
	"AaBbVvHhGgDdEeIeieZhzhZzYyIiIiIiKkLlMmNnOoPpRrSsTtUuFfKhkhTstsChchShshSchschIuiuIaia\'\'");

#test3 - common transliteration of Ukrainian and Latin Letters
ok( uk2ascii("АаБбВвГгҐґsomeLatinLettersДдЕеЄєЖжЗзИиІіЇїAnotherPortionOfLatinSymbolsЙйКкЛлМмНнОоПпРрСсТтУуФфХхЦцЧчШшЩщЮюЯяЬь"),
	"AaBbVvHhGgsomeLatinLettersDdEeIeieZhzhZzYyIiIiAnotherPortionOfLatinSymbolsIiKkLlMmNnOoPpRrSsTtUuFfKhkhTstsChchShshSchschIuiuIaia\'\'");

#test4 - common transliteration of Ukrainian and Latin Letters plus some formatting (\t)
ok( uk2ascii("АаБбВвГгҐґsomeLatinLettersДдЕеЄєЖж\tЗзИиІіЇїAnotherPortionOfLatinSymbolsЙйКкЛлМмНнОо\tПпРрСсТтУуФфХхЦцЧчШшЩщЮю\tЯяЬь"),
	"AaBbVvHhGgsomeLatinLettersDdEeIeieZhzh\tZzYyIiIiAnotherPortionOfLatinSymbolsIiKkLlMmNnOo\tPpRrSsTtUuFfKhkhTstsChchShshSchschIuiu\tYaia\'\'");

#test5 - uncommon transliteration of Ukrainian Letters at the first position of words plus formatting plus Latin Symbols
ok( uk2ascii("АаБбВвГгҐґsomeLatinLettersДдЕе Є єЖж\tЗзИиІі Ї їAnotherPortionOfLatinSymbols Й йКкЛлМмНнОо\tПпРрСсТтУуФфХхЦцЧчШшЩщ Ю ю\t Я яЬь"), 
	     "AaBbVvHhGgsomeLatinLettersDdEe Ye yeZhzh\tZzYyIi Y yAnotherPortionOfLatinSymbols Y yKkLlMmNnOo\tPpRrSsTtUuFfKhkhTstsChchShshSchsch Yu yu\t Ya ya\'\'");

#test6 - uncommon transliteration of Ukrainian Letters in special cases
ok( uk2ascii("Зг зг зГ ЗГ Зґ зґ зҐ ЗҐ"),
	"Zgh zgh zGh ZGh Zg zg zG ZG");

