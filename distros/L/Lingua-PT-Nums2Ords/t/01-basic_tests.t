# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 50;
BEGIN { use_ok('Lingua::PT::Nums2Ords', 'num2ord') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(num2ord(1),'primeiro');
is(num2ord(2),'segundo');
is(num2ord(3),'terceiro');
is(num2ord(4),'quarto');
is(num2ord(5),'quinto');
is(num2ord(6),'sexto');
is(num2ord(7),'sétimo');
is(num2ord(8),'oitavo');
is(num2ord(9),'nono');

is(num2ord(10),'décimo');
is(num2ord(11),'décimo primeiro');

is(num2ord(30),'trigésimo');
is(num2ord(33),'trigésimo terceiro');
is(num2ord(70),'septuagésimo');

is(num2ord(101),'centésimo primeiro');
is(num2ord(150),'centésimo quinquagésimo');
is(num2ord(199),'centésimo nonagésimo nono');
is(num2ord(299),'ducentésimo nonagésimo nono');
is(num2ord(301),'tricentésimo primeiro');
is(num2ord(421),'quadrigentésimo vigésimo primeiro');
is(num2ord(520),'quingentésimo vigésimo');
is(num2ord(622),'seiscentésimo vigésimo segundo');
is(num2ord(700),'septigentésimo');
is(num2ord(855),'octigentésimo quinquagésimo quinto');
is(num2ord(988),'nongentésimo octogésimo oitavo');

is(num2ord(1000),'milésimo');
is(num2ord(10000),'dez milésimos');
is(num2ord(11000),'onze milésimos');
is(num2ord(10090),'dez milésimos nonagésimo');
is(num2ord(100000),'cem milésimos');
is(num2ord(300000),'trezentos milésimos');
is(num2ord(321987),'trezentos e vinte e um milésimos nongentésimo octogésimo sétimo');
is(num2ord(444444),'quatrocentos e quarenta e quatro milésimos quadrigentésimo quadragésimo quarto');
is(num2ord(987654),'novecentos e oitenta e sete milésimos seiscentésimo quinquagésimo quarto');

is(num2ord(1000000),'milionésimo');
is(num2ord(1000001),'milionésimo primeiro');
is(num2ord(1001001),'milionésimo milésimo primeiro');
is(num2ord(2000000),'dois milionésimos');
is(num2ord(999999999),'novecentos e noventa e nove milionésimos novecentos e noventa e nove milésimos nongentésimo nonagésimo nono');

is(num2ord(1000000000),'bilionésimo');
is(num2ord(1000000001),'bilionésimo primeiro');
is(num2ord(2000000000),'dois bilionésimos');
is(num2ord(2000002000),'dois bilionésimos dois milésimos');
is(num2ord(3002001000),'três bilionésimos dois milionésimos milésimo');
is(num2ord(3002001009),'três bilionésimos dois milionésimos milésimo nono');
is(num2ord(9090909090),'nove bilionésimos noventa milionésimos novecentos e nove milésimos nonagésimo');
is(num2ord(8808080808),'oito bilionésimos oitocentos e oito milionésimos oitenta milésimos octigentésimo oitavo');
is(num2ord(7654321987),'sete bilionésimos seiscentos e cinquenta e quatro milionésimos trezentos e vinte e um milésimos nongentésimo octogésimo sétimo');
is(num2ord(999999999999),'novecentos e noventa e nove bilionésimos novecentos e noventa e nove milionésimos novecentos e noventa e nove milésimos nongentésimo nonagésimo nono');
