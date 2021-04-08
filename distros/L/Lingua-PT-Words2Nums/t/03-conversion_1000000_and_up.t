# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 87;
BEGIN { use_ok('Lingua::PT::Words2Nums', 'word2num') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(word2num('um milhão'),1000000);
is(word2num('um milhão e um'),1000001);
is(word2num('um milhão e mil'),1001000);
is(word2num('um milhão mil e um'),1001001);
is(word2num('dois milhões vinte mil duzentos e dois'),2020202);
is(word2num('três milhões trezentos mil trezentos e trinta'),3300330);
is(word2num('quatro milhões quatro mil e quatro'),4004004);
is(word2num('cinco milhões cinquenta mil e cinquenta e cinco'),5050055);
is(word2num('seis milhões seiscentos e sessenta mil'),6660000);
is(word2num('sete milhões setecentos mil setecentos e setenta e sete'),7700777);
is(word2num('oito milhões oitocentos e oitenta e oito mil oitocentos e oitenta e oito'),8888888);
is(word2num('nove milhões novecentos e noventa e nove mil e novecentos'),9999900);

is(word2num('dez milhões'),10000000);
is(word2num('vinte milhões duzentos e dois mil e vinte'),20202020);
is(word2num('trinta e três milhões três mil e trezentos'),33003300);
is(word2num('quarenta milhões quarenta e quatro mil e quatro'),40044004);
is(word2num('cinquenta e cinco milhões quinhentos mil e cinquenta e cinco'),55500055);
is(word2num('sessenta e seis milhões'),66000000);
is(word2num('setenta milhões e sete'),70000007);
is(word2num('oitenta e oito milhões oitenta mil oitocentos e oito'),88080808);
is(word2num('noventa e oito milhões novecentos e oitenta e nove mil oitocentos e noventa e oito'),98989898);
is(word2num('noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),99999999);

is(word2num('cem milhões'),100000000);
is(word2num('duzentos e dois milhões vinte mil e duzentos'),202020200);
is(word2num('trezentos e três milhões trezentos e três mil trezentos e três'),303303303);
is(word2num('quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro'),444444444);
is(word2num('quinhentos e cinquenta milhões e cinquenta e cinco mil'),550055000);
is(word2num('seiscentos e sessenta e seis milhões e seiscentos mil'),666600000);
is(word2num('setecentos milhões e sete'),700000007);
is(word2num('oitocentos e oitenta e um milhões duzentos e trinta e quatro mil quinhentos e noventa e nove'),881234599);
is(word2num('novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),999999999);

is(word2num('mil milhões'),1000000000);
is(word2num('dois mil e vinte milhões duzentos e dois mil e vinte'),2020202020);
is(word2num('três mil e trinta e três milhões trinta e três mil e trinta'),3033033030);
is(word2num('quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro'),4444444444);
is(word2num('cinco mil e quinhentos milhões quinhentos e cinquenta mil'),5500550000);
is(word2num('seis mil seiscentos e sessenta e seis milhões e seiscentos mil'),6666600000);
is(word2num('sete mil milhões e sete'),7000000007);
is(word2num('oito mil oitocentos e doze milhões trezentos e quarenta e cinco mil novecentos e noventa e nove'),8812345999);
is(word2num('nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),9999999999);

is(word2num('dez mil milhões'),10000000000);
is(word2num('vinte mil duzentos e dois milhões vinte mil e duzentos'),20202020200);
is(word2num('trinta mil trezentos e trinta milhões trezentos e trinta mil e trezentos'),30330330300);
is(word2num('quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro'),44444444444);
is(word2num('cinquenta e cinco mil e cinco milhões e quinhentos mil'),55005500000);
is(word2num('sessenta e seis mil seiscentos e sessenta e seis milhões'),66666000000);
is(word2num('setenta mil milhões e sete'),70000000007);
is(word2num('oitenta e oito mil cento e vinte e três milhões quatrocentos e cinquenta e nove mil novecentos e noventa e nove'),88123459999);
is(word2num('noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),99999999999);

is(word2num('cem mil milhões'),100000000000);
is(word2num('duzentos e dois mil e vinte milhões duzentos e dois mil e vinte'),202020202020);
is(word2num('trezentos e três mil trezentos e três milhões trezentos e três mil trezentos e três'),303303303303);
is(word2num('quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro'),444444444444);
is(word2num('quinhentos e cinquenta mil e cinquenta e cinco milhões cinco mil e quinhentos'),550055005500);
is(word2num('seiscentos e sessenta e seis mil seiscentos e sessenta e seis milhões'),666666000000);
is(word2num('setecentos mil milhões e sete'),700000000007);
is(word2num('oitocentos e oitenta e um mil duzentos e trinta e quatro milhões quinhentos e noventa e nove mil novecentos e noventa e nove'),881234599999);
is(word2num('novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),999999999999);

is(word2num('um bilião'),1000000000000);
is(word2num('dois biliões vinte mil duzentos e dois milhões vinte mil e duzentos'),2020202020200);
is(word2num('três biliões trinta e três mil e trinta e três milhões trinta e três mil e trinta'),3033033033030);
is(word2num('quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro'),4444444444444);
is(word2num('cinco biliões quinhentos mil quinhentos e cinquenta milhões e cinquenta e cinco mil'),5500550055000);
is(word2num('seis biliões seiscentos e sessenta e seis mil seiscentos e sessenta milhões'),6666660000000);
is(word2num('sete biliões e sete'),7000000000007);
is(word2num('oito biliões oitocentos e doze mil trezentos e quarenta e cinco milhões novecentos e noventa e nove mil novecentos e noventa e nove'),8812345999999);
is(word2num('nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),9999999999999);

is(word2num('dez biliões'),10000000000000);
is(word2num('vinte biliões duzentos e dois mil e vinte milhões duzentos e dois mil e vinte'),20202020202020);
is(word2num('trinta biliões trezentos e trinta mil trezentos e trinta milhões trezentos e trinta mil e trezentos'),30330330330300);
is(word2num('quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro'),44444444444444);
is(word2num('cinquenta e cinco biliões cinco mil e quinhentos milhões quinhentos e cinquenta mil'),55005500550000);
is(word2num('sessenta e seis biliões seiscentos e sessenta e seis mil seiscentos e sessenta milhões'),66666660000000);
is(word2num('setenta biliões e sete'),70000000000007);
is(word2num('oitenta e oito biliões cento e vinte e três mil quatrocentos e cinquenta e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),88123459999999);
is(word2num('noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),99999999999999);

is(word2num('cem biliões'),100000000000000);
is(word2num('duzentos e dois biliões vinte mil duzentos e dois milhões vinte mil e duzentos'),202020202020200);
is(word2num('trezentos e três biliões trezentos e três mil trezentos e três milhões trezentos e três mil trezentos e três'),303303303303303);
is(word2num('quatrocentos e quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro'),444444444444444);
is(word2num('quinhentos e cinquenta biliões cinquenta e cinco mil e cinco milhões e quinhentos mil'),550055005500000);
is(word2num('seiscentos e sessenta e seis biliões seiscentos e sessenta e seis mil e seiscentos milhões'),666666600000000);
is(word2num('setecentos biliões e sete'),700000000000007);
is(word2num('oitocentos e oitenta e um biliões duzentos e trinta e quatro mil quinhentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),881234599999999);
is(word2num('novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),999999999999999);
is(word2num('novecentos e noventa e nove mil novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove'),999999999999999999);

TODO: {

  local $TODO = 'up, up... and away!!!';

}
