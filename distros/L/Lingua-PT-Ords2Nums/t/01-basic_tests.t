# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 50;
BEGIN { use_ok('Lingua::PT::Ords2Nums', 'ord2num') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(ord2num('primeiro'),1);
is(ord2num('segundo'),2);
is(ord2num('terceiro'),3);
is(ord2num('quarto'),4);
is(ord2num('quinto'),5);
is(ord2num('sexto'),6);
is(ord2num('sétimo'),7);
is(ord2num('oitavo'),8);
is(ord2num('nono'),9);

is(ord2num('décimo'),10);
is(ord2num('décimo primeiro'),11);

is(ord2num('trigésimo'),30);
is(ord2num('trigésimo terceiro'),33);
is(ord2num('septuagésimo'),70);

is(ord2num('centésimo primeiro'),101);
is(ord2num('centésimo quinquagésimo'),150);
is(ord2num('centésimo nonagésimo nono'),199);
is(ord2num('ducentésimo nonagésimo nono'),299);
is(ord2num('tricentésimo primeiro'),301);
is(ord2num('quadrigentésimo vigésimo primeiro'),421);
is(ord2num('quingentésimo vigésimo'),520);
is(ord2num('seiscentésimo vigésimo segundo'),622);
is(ord2num('septigentésimo'),700);
is(ord2num('octigentésimo quinquagésimo quinto'),855);
is(ord2num('nongentésimo octogésimo oitavo'),988);

is(ord2num('milésimo'),1000);
is(ord2num('dez milésimos'),10000);
is(ord2num('onze milésimos'),11000);
is(ord2num('dez milésimos nonagésimo'),10090);
is(ord2num('cem milésimos'),100000);
is(ord2num('trezentos milésimos'),300000);
is(ord2num('trezentos e vinte e um milésimos nongentésimo octogésimo sétimo'),321987);
is(ord2num('quatrocentos e quarenta e quatro milésimos quadrigentésimo quadragésimo quarto'),444444);
is(ord2num('novecentos e oitenta e sete milésimos seiscentésimo quinquagésimo quarto'),987654);

is(ord2num('milionésimo'),1000000);
is(ord2num('milionésimo primeiro'),1000001);
is(ord2num('milionésimo milésimo primeiro'),1001001);
is(ord2num('dois milionésimos'),2000000);
is(ord2num('novecentos e noventa e nove milionésimos novecentos e noventa e nove milésimos nongentésimo nonagésimo nono'),999999999);

is(ord2num('bilionésimo'),1000000000);
is(ord2num('bilionésimo primeiro'),1000000001);
is(ord2num('dois bilionésimos'),2000000000);
is(ord2num('dois bilionésimos dois milésimos'),2000002000);
is(ord2num('três bilionésimos dois milionésimos milésimo'),3002001000);
is(ord2num('três bilionésimos dois milionésimos milésimo nono'),3002001009);
is(ord2num('nove bilionésimos noventa milionésimos novecentos e nove milésimos nonagésimo'),9090909090);
is(ord2num('oito bilionésimos oitocentos e oito milionésimos oitenta milésimos octigentésimo oitavo'),8808080808);
is(ord2num('sete bilionésimos seiscentos e cinquenta e quatro milionésimos trezentos e vinte e um milésimos nongentésimo octogésimo sétimo'),7654321987);
is(ord2num('novecentos e noventa e nove bilionésimos novecentos e noventa e nove milionésimos novecentos e noventa e nove milésimos nongentésimo nonagésimo nono'),999999999999);
