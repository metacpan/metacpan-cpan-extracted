# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 124;
BEGIN { use_ok('Lingua::PT::Words2Nums', 'word2num') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(word2num('zero'),0);
is(word2num('um'),1);
is(word2num('dois'),2);
is(word2num('três'),3);
is(word2num('quatro'),4);
is(word2num('cinco'),5);
is(word2num('seis'),6);
is(word2num('sete'),7);
is(word2num('oito'),8);
is(word2num('nove'),9);
is(word2num('dez'),10);
is(word2num('onze'),11);
is(word2num('doze'),12);
is(word2num('treze'),13);
is(word2num('catorze'),14);
is(word2num('quinze'),15);
is(word2num('dezasseis'),16);
is(word2num('dezassete'),17);
is(word2num('dezoito'),18);
is(word2num('dezanove'),19);

is(word2num('vinte'),20);
is(word2num('vinte e um'),21);
is(word2num('vinte e dois'),22);
is(word2num('trinta'),30);
is(word2num('trinta e três'),33);
is(word2num('quarenta'),40);
is(word2num('quarenta e quatro'),44);
is(word2num('cinquenta'),50);
is(word2num('cinquenta e cinco'),55);
is(word2num('sessenta'),60);
is(word2num('sessenta e seis'),66);
is(word2num('setenta'),70);
is(word2num('setenta e sete'),77);
is(word2num('oitenta'),80);
is(word2num('oitenta e oito'),88);
is(word2num('noventa'),90);
is(word2num('noventa e nove'),99);

is(word2num('cem'),100);
is(word2num('cento e cinco'),105);
is(word2num('cento e vinte'),120);
is(word2num('cento e trinta e quatro'),134);
is(word2num('cento e setenta e seis'),176);
is(word2num('cento e oitenta e nove'),189);

is(word2num('duzentos'),200);
is(word2num('duzentos e cinquenta'),250);
is(word2num('duzentos e sessenta e três'),263);

is(word2num('trezentos'),300);
is(word2num('quatrocentos'),400);
is(word2num('quinhentos'),500);
is(word2num('seiscentos'),600);
is(word2num('setecentos'),700);
is(word2num('oitocentos'),800);
is(word2num('novecentos'),900);

is(word2num('mil'),1000);

is(word2num('mil e um'),1001);
is(word2num('mil e dez'),1010);
is(word2num('mil e onze'),1011);
is(word2num('mil e cem'),1100);
is(word2num('mil cento e um'),1101);
is(word2num('mil cento e dez'),1110);
is(word2num('mil cento e onze'),1111);

is(word2num('mil e quinhentos'),1500);
is(word2num('mil quinhentos e um'),1501);
is(word2num('mil quinhentos e dez'),1510);
is(word2num('mil quinhentos e onze'),1511);
is(word2num('mil quinhentos e cinquenta'),1550);
is(word2num('mil quinhentos e oitenta e três'),1583);

is(word2num('mil oitocentos e sete'),1807);
is(word2num('mil novecentos e vinte'),1920);
is(word2num('dois mil e quarenta'),2040);
is(word2num('três mil e seis'),3006);
is(word2num('quatro mil'),4000);
is(word2num('quatro mil cento e vinte e três'),4123);
is(word2num('cinco mil oitocentos e setenta e cinco'),5875);
is(word2num('seis mil novecentos e oitenta'),6980);
is(word2num('sete mil e nove'),7009);
is(word2num('oito mil e noventa'),8090);
is(word2num('nove mil cento e um'),9101);

is(word2num('nove mil novecentos e noventa e nove'),9999);

is(word2num('dez mil'),10000);
is(word2num('dez mil e um'),10001);
is(word2num('dez mil e dez'),10010);
is(word2num('dez mil e onze'),10011);
is(word2num('dez mil e cem'),10100);
is(word2num('dez mil cento e um'),10101);
is(word2num('dez mil cento e onze'),10111);
is(word2num('onze mil'),11000);
is(word2num('onze mil e um'),11001);
is(word2num('onze mil e onze'),11011);
is(word2num('onze mil cento e onze'),11111);

is(word2num('doze mil oitocentos e setenta e três'),12873);
is(word2num('treze mil'),13000);
is(word2num('catorze mil e vinte'),14020);
is(word2num('quinze mil e cem'),15100);
is(word2num('dezasseis mil seiscentos e cinco'),16605);
is(word2num('dezassete mil e dois'),17002);
is(word2num('dezoito mil quinhentos e quarenta e três'),18543);
is(word2num('dezanove mil novecentos e noventa e nove'),19999);

is(word2num('vinte mil'),20000);
is(word2num('trinta mil e três'),30003);
is(word2num('quarenta mil e quarenta'),40040);
is(word2num('cinquenta mil e quinhentos'),50500);
is(word2num('sessenta e seis mil'),66000);
is(word2num('setenta e sete mil e setenta'),77070);
is(word2num('oitenta mil oitocentos e oito'),80808);
is(word2num('noventa e nove mil novecentos e noventa e nove'),99999);

is(word2num('cem mil'),100000);
is(word2num('cento e onze mil cento e onze'),111111);
is(word2num('duzentos e vinte e dois mil duzentos e vinte e dois'),222222);
is(word2num('duzentos e dois mil e vinte'),202020);
is(word2num('trezentos e trinta e três mil trezentos e trinta e três'),333333);
is(word2num('trezentos e trinta mil e trinta e três'),330033);
is(word2num('quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro'),444444);
is(word2num('quatrocentos e quarenta e quatro mil'),444000);
is(word2num('quinhentos e cinquenta e cinco mil quinhentos e cinquenta e cinco'),555555);
is(word2num('quinhentos mil e cinquenta e cinco'),500055);
is(word2num('seiscentos e sessenta e seis mil seiscentos e sessenta e seis'),666666);
is(word2num('seiscentos e sessenta mil seiscentos e seis'),660606);
is(word2num('setecentos e setenta e sete mil setecentos e setenta e sete'),777777);
is(word2num('setecentos e sete mil e setecentos'),707700);
is(word2num('oitocentos e oitenta e oito mil oitocentos e oitenta e oito'),888888);
is(word2num('oitocentos e oito mil oitocentos e oitenta'),808880);
is(word2num('novecentos e noventa e nove mil novecentos e noventa e nove'),999999);
