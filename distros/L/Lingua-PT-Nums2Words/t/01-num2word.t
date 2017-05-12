# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 263;

BEGIN { use_ok('Lingua::PT::Nums2Words', 'num2word') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

is(num2word(0),'zero');
is(num2word(1),'um');
is(num2word(2),'dois');
is(num2word(3),'três');
is(num2word(4),'quatro');
is(num2word(5),'cinco');
is(num2word(6),'seis');
is(num2word(7),'sete');
is(num2word(8),'oito');
is(num2word(9),'nove');
is(num2word(10),'dez');
is(num2word(11),'onze');
is(num2word(12),'doze');
is(num2word(13),'treze');
is(num2word(14),'catorze');
is(num2word(15),'quinze');
is(num2word(16),'dezasseis');
is(num2word(17),'dezassete');
is(num2word(18),'dezoito');
is(num2word(19),'dezanove');

is(num2word(20),'vinte');
is(num2word(21),'vinte e um');
is(num2word(22),'vinte e dois');
is(num2word(30),'trinta');
is(num2word(33),'trinta e três');
is(num2word(40),'quarenta');
is(num2word(44),'quarenta e quatro');
is(num2word(50),'cinquenta');
is(num2word(55),'cinquenta e cinco');
is(num2word(60),'sessenta');
is(num2word(66),'sessenta e seis');
is(num2word(70),'setenta');
is(num2word(77),'setenta e sete');
is(num2word(80),'oitenta');
is(num2word(88),'oitenta e oito');
is(num2word(90),'noventa');
is(num2word(99),'noventa e nove');

is(num2word(100),'cem');
is(num2word(105),'cento e cinco');
is(num2word(120),'cento e vinte');
is(num2word(134),'cento e trinta e quatro');
is(num2word(176),'cento e setenta e seis');
is(num2word(189),'cento e oitenta e nove');

is(num2word(200),'duzentos');
is(num2word(250),'duzentos e cinquenta');
is(num2word(263),'duzentos e sessenta e três');

is(num2word(300),'trezentos');
is(num2word(400),'quatrocentos');
is(num2word(500),'quinhentos');
is(num2word(600),'seiscentos');
is(num2word(700),'setecentos');
is(num2word(800),'oitocentos');
is(num2word(900),'novecentos');

is(num2word(1000),'mil');

is(num2word(1001),'mil e um');
is(num2word(1010),'mil e dez');
is(num2word(1011),'mil e onze');
is(num2word(1100),'mil e cem');
is(num2word(1101),'mil cento e um');
is(num2word(1110),'mil cento e dez');
is(num2word(1111),'mil cento e onze');

is(num2word(1500),'mil e quinhentos');
is(num2word(1501),'mil quinhentos e um');
is(num2word(1510),'mil quinhentos e dez');
is(num2word(1511),'mil quinhentos e onze');
is(num2word(1550),'mil quinhentos e cinquenta');
is(num2word(1583),'mil quinhentos e oitenta e três');

is(num2word(1807),'mil oitocentos e sete');
is(num2word(1920),'mil novecentos e vinte');
is(num2word(2040),'dois mil e quarenta');
is(num2word(3006),'três mil e seis');
is(num2word(4000),'quatro mil');
is(num2word(4123),'quatro mil cento e vinte e três');
is(num2word(5875),'cinco mil oitocentos e setenta e cinco');
is(num2word(6980),'seis mil novecentos e oitenta');
is(num2word(7009),'sete mil e nove');
is(num2word(8090),'oito mil e noventa');
is(num2word(9101),'nove mil cento e um');

is(num2word(9999),'nove mil novecentos e noventa e nove');

is(num2word(10000),'dez mil');
is(num2word(10001),'dez mil e um');
is(num2word(10010),'dez mil e dez');
is(num2word(10011),'dez mil e onze');
is(num2word(10100),'dez mil e cem');
is(num2word(10101),'dez mil cento e um');
is(num2word(10111),'dez mil cento e onze');
is(num2word(11000),'onze mil');
is(num2word(11001),'onze mil e um');
is(num2word(11011),'onze mil e onze');
is(num2word(11111),'onze mil cento e onze');

is(num2word(12873),'doze mil oitocentos e setenta e três');
is(num2word(13000),'treze mil');
is(num2word(14020),'catorze mil e vinte');
is(num2word(15100),'quinze mil e cem');
is(num2word(16605),'dezasseis mil seiscentos e cinco');
is(num2word(17002),'dezassete mil e dois');
is(num2word(18543),'dezoito mil quinhentos e quarenta e três');
is(num2word(19999),'dezanove mil novecentos e noventa e nove');

is(num2word(20000),'vinte mil');
is(num2word(30003),'trinta mil e três');
is(num2word(40040),'quarenta mil e quarenta');
is(num2word(50500),'cinquenta mil e quinhentos');
is(num2word(66000),'sessenta e seis mil');
is(num2word(77070),'setenta e sete mil e setenta');
is(num2word(80808),'oitenta mil oitocentos e oito');
is(num2word(99999),'noventa e nove mil novecentos e noventa e nove');

is(num2word(100000),'cem mil');
is(num2word(111111),'cento e onze mil cento e onze');
is(num2word(222222),'duzentos e vinte e dois mil duzentos e vinte e dois');
is(num2word(202020),'duzentos e dois mil e vinte');
is(num2word(333333),'trezentos e trinta e três mil trezentos e trinta e três');
is(num2word(330033),'trezentos e trinta mil e trinta e três');
is(num2word(444444),'quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(444000),'quatrocentos e quarenta e quatro mil');
is(num2word(555555),'quinhentos e cinquenta e cinco mil quinhentos e cinquenta e cinco');
is(num2word(500055),'quinhentos mil e cinquenta e cinco');
is(num2word(666666),'seiscentos e sessenta e seis mil seiscentos e sessenta e seis');
is(num2word(660606),'seiscentos e sessenta mil seiscentos e seis');
is(num2word(777777),'setecentos e setenta e sete mil setecentos e setenta e sete');
is(num2word(707700),'setecentos e sete mil e setecentos');
is(num2word(888888),'oitocentos e oitenta e oito mil oitocentos e oitenta e oito');
is(num2word(808880),'oitocentos e oito mil oitocentos e oitenta');
is(num2word(999999),'novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(1000000),'um milhão');
is(num2word(1000001),'um milhão e um');
is(num2word(1001000),'um milhão e mil');
is(num2word(1001001),'um milhão mil e um');
is(num2word(2020202),'dois milhões vinte mil duzentos e dois');
is(num2word(3300330),'três milhões trezentos mil trezentos e trinta');
is(num2word(4004004),'quatro milhões quatro mil e quatro');
is(num2word(5050055),'cinco milhões cinquenta mil e cinquenta e cinco');
is(num2word(6660000),'seis milhões seiscentos e sessenta mil');
is(num2word(7700777),'sete milhões setecentos mil setecentos e setenta e sete');
is(num2word(8888888),'oito milhões oitocentos e oitenta e oito mil oitocentos e oitenta e oito');
is(num2word(9999900),'nove milhões novecentos e noventa e nove mil e novecentos');

is(num2word(10000000),'dez milhões');
is(num2word(20202020),'vinte milhões duzentos e dois mil e vinte');
is(num2word(33003300),'trinta e três milhões três mil e trezentos');
is(num2word(40044004),'quarenta milhões quarenta e quatro mil e quatro');
is(num2word(55500055),'cinquenta e cinco milhões quinhentos mil e cinquenta e cinco');
is(num2word(66000000),'sessenta e seis milhões');
is(num2word(70000007),'setenta milhões e sete');
is(num2word(88080808),'oitenta e oito milhões oitenta mil oitocentos e oito');
is(num2word(98989898),'noventa e oito milhões novecentos e oitenta e nove mil oitocentos e noventa e oito');
is(num2word(99999999),'noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(100000000),'cem milhões');
is(num2word(202020200),'duzentos e dois milhões vinte mil e duzentos');
is(num2word(303303303),'trezentos e três milhões trezentos e três mil trezentos e três');
is(num2word(444444444),'quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(550055000),'quinhentos e cinquenta milhões e cinquenta e cinco mil');
is(num2word(666600000),'seiscentos e sessenta e seis milhões e seiscentos mil');
is(num2word(700000007),'setecentos milhões e sete');
is(num2word(881234599),'oitocentos e oitenta e um milhões duzentos e trinta e quatro mil quinhentos e noventa e nove');
is(num2word(999999999),'novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(1000000000),'mil milhões');
is(num2word(2020202020),'dois mil e vinte milhões duzentos e dois mil e vinte');
is(num2word(3033033030),'três mil e trinta e três milhões trinta e três mil e trinta');
is(num2word(4444444444),'quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(5500550000),'cinco mil e quinhentos milhões quinhentos e cinquenta mil');
is(num2word(6666600000),'seis mil seiscentos e sessenta e seis milhões e seiscentos mil');
is(num2word(7000000007),'sete mil milhões e sete');
is(num2word(8812345999),'oito mil oitocentos e doze milhões trezentos e quarenta e cinco mil novecentos e noventa e nove');
is(num2word(9999999999),'nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(10000000000),'dez mil milhões');
is(num2word(20202020200),'vinte mil duzentos e dois milhões vinte mil e duzentos');
is(num2word(30330330300),'trinta mil trezentos e trinta milhões trezentos e trinta mil e trezentos');
is(num2word(44444444444),'quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(55005500000),'cinquenta e cinco mil e cinco milhões e quinhentos mil');
is(num2word(66666000000),'sessenta e seis mil seiscentos e sessenta e seis milhões');
is(num2word(70000000007),'setenta mil milhões e sete');
is(num2word(88123459999),'oitenta e oito mil cento e vinte e três milhões quatrocentos e cinquenta e nove mil novecentos e noventa e nove');
is(num2word(99999999999),'noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(100000000000),'cem mil milhões');
is(num2word(202020202020),'duzentos e dois mil e vinte milhões duzentos e dois mil e vinte');
is(num2word(303303303303),'trezentos e três mil trezentos e três milhões trezentos e três mil trezentos e três');
is(num2word(444444444444),'quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(550055005500),'quinhentos e cinquenta mil e cinquenta e cinco milhões cinco mil e quinhentos');
is(num2word(666666000000),'seiscentos e sessenta e seis mil seiscentos e sessenta e seis milhões');
is(num2word(700000000007),'setecentos mil milhões e sete');
is(num2word(881234599999),'oitocentos e oitenta e um mil duzentos e trinta e quatro milhões quinhentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(999999999999),'novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(1000000000000),'um bilião');
is(num2word(2020202020200),'dois biliões vinte mil duzentos e dois milhões vinte mil e duzentos');
is(num2word(3033033033030),'três biliões trinta e três mil e trinta e três milhões trinta e três mil e trinta');
is(num2word(4444444444444),'quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(5500550055000),'cinco biliões quinhentos mil quinhentos e cinquenta milhões e cinquenta e cinco mil');
is(num2word(6666660000000),'seis biliões seiscentos e sessenta e seis mil seiscentos e sessenta milhões');
is(num2word(7000000000007),'sete biliões e sete');
is(num2word(8812345999999),'oito biliões oitocentos e doze mil trezentos e quarenta e cinco milhões novecentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(9999999999999),'nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(10000000000000),'dez biliões');
is(num2word(20202020202020),'vinte biliões duzentos e dois mil e vinte milhões duzentos e dois mil e vinte');
is(num2word(30330330330300),'trinta biliões trezentos e trinta mil trezentos e trinta milhões trezentos e trinta mil e trezentos');
is(num2word(44444444444444),'quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(55005500550000),'cinquenta e cinco biliões cinco mil e quinhentos milhões quinhentos e cinquenta mil');
is(num2word(66666660000000),'sessenta e seis biliões seiscentos e sessenta e seis mil seiscentos e sessenta milhões');
is(num2word(70000000000007),'setenta biliões e sete');
is(num2word(88123459999999),'oitenta e oito biliões cento e vinte e três mil quatrocentos e cinquenta e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(99999999999999),'noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(100000000000000),'cem biliões');
is(num2word(202020202020200),'duzentos e dois biliões vinte mil duzentos e dois milhões vinte mil e duzentos');
is(num2word(303303303303303),'trezentos e três biliões trezentos e três mil trezentos e três milhões trezentos e três mil trezentos e três');
is(num2word(444444444444444),'quatrocentos e quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(550055005500000),'quinhentos e cinquenta biliões cinquenta e cinco mil e cinco milhões e quinhentos mil');
is(num2word(666666600000000),'seiscentos e sessenta e seis biliões seiscentos e sessenta e seis mil e seiscentos milhões');
is(num2word(700000000000007),'setecentos biliões e sete');
is(num2word(881234599999999),'oitocentos e oitenta e um biliões duzentos e trinta e quatro mil quinhentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(999999999999999),'novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

TODO: {
  local $TODO = "haven't got it working for thousands of billions and above yet";

is(num2word(1000000000000000),'mil biliões');
is(num2word(2020202020202020),'dois mil e vinte biliões duzentos e dois mil e vinte milhões duzentos e dois mil e vinte');
is(num2word(3033033033033030),'três mil e trinta e três biliões trinta e três mil e trinta e três milhões trinta e três mil e trinta');
is(num2word(4444444444444444),'quatro mil quatrocentos e quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(5500550055005500),'cinco mil e quinhentos biliões quinhentos e cinquenta mil e cinquenta e cinco milhões e cinco mil e quinhentos');
is(num2word(6666666600000000),'seis mil seiscentos e sessenta e seis biliões seiscentos e sessenta e seis mil e seiscentos milhões');
is(num2word(7000000000000007),'sete mil biliões e sete');
is(num2word(8812345999999999),'oito mil oitocentos e doze biliões trezentos e quarenta e cinco mil novecentos e noventa e nove mil milhões novecentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(9999999999999999),'nove mil novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(10000000000000000),'dez mil biliões');
is(num2word(20202020202020200),'vinte mil duzentos e dois biliões vinte mil duzentos e dois milhões vinte mil e duzentos');
is(num2word(30330330330330300),'trinta mil trezentos e trinta biliões trezentos e trinta mil trezentos e trinta milhões trezentos e trinta mil e trezentos');
is(num2word(44444444444444444),'quarenta e quatro mil quatrocentos e quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(55005500550055000),'cinquenta e cinco mil e cinco biliões quinhentos mil quinhentos e cinquenta milhões e cinquenta e cinco mil');
is(num2word(66666666000000000),'sessenta e seis mil seiscentos e sessenta e seis biliões seiscentos e sessenta e seis mil milhões');
is(num2word(70000000000000007),'setenta mil biliões e sete');
is(num2word(88123459999999999),'oitenta e oito mil cento e vinte e três biliões quatrocentos e cinquenta e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(99999999999999999),'noventa e nove mil novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(100000000000000000),'cem mil biliões');
is(num2word(202020202020202020),'duzentos e dois mil e vinte biliões duzentos e dois mil e vinte milhões duzentos e dois mil e vinte');
is(num2word(303303303303303303),'trezentos e três mil trezentos e três biliões trezentos e três mil trezentos e três milhões trezentos e três mil trezentos e três');
is(num2word(444444444444444444),'quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(550055005500550000),'quinhentos e cinquenta mil e cinquenta e cinco biliões e cinco mil e quinhentos milhões e quinhentos e cinquenta mil');
is(num2word(666666666000000000),'seiscentos e sessenta e seis mil seiscentos e sessenta e seis biliões seiscentos e sessenta e seis mil milhões');
is(num2word(700000000000000007),'setecentos mil biliões e sete');
is(num2word(881234599999999999),'oitocentos e oitenta e um mil duzentos e trinta e quatro biliões quinhentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(999999999999999999),'novecentos e noventa e nove mil novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(1000000000000000000),'um trilião');
is(num2word(2020202020202020200),'dois triliões vinte mil duzentos e dois biliões vinte mil duzentos e dois milhões vinte mil e duzentos');
is(num2word(3033033033033033030),'três triliões e trinta e três mil e trinta e três biliões trinta e três mil e trinta e três milhões trinta e três mil e trinta');
is(num2word(4444444444444444444),'quatro triliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(5500550055005500000),'cinco triliões e quinhentos mil quinhentos e cinquenta biliões e cinquenta e cinco mil e cinco milhões e quinhentos mil');
is(num2word(6666666660000000000),'seis triliões seiscentos e sessenta e seis mil seiscentos e sessenta e seis biliões seiscentos e sessenta mil milhões');
is(num2word(7000000000000000007),'sete triliões e sete');
is(num2word(8812345999999999999),'oito triliões oitocentos e doze mil trezentos e quarenta e cinco mil novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(9999999999999999999),'nove triliões novecentos e noventa e nove mil novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(10000000000000000000),'dez triliões');
is(num2word(20202020202020202020),'vinte triliões duzentos e dois mil e vinte biliões duzentos e dois mil e vinte milhões duzentos e dois mil e vinte');
is(num2word(30330330330330330300),'trinta triliões trezentos e trinta mil trezentos e trinta biliões trezentos e trinta mil trezentos e trinta milhões trezentos e trinta mil e trezentos');
is(num2word(44444444444444444444),'quarenta e quatro triliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro biliões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro milhões quatrocentos e quarenta e quatro mil quatrocentos e quarenta e quatro');
is(num2word(55005500550055005500),'cinquenta e cinco triliões e cinco mil e quinhentos biliões quinhentos e cinquenta mil e cinquenta e cinco milhões e cinco mil e quinhentos');
is(num2word(66666666660000000000),'sessenta e seis triliões seiscentos e sessenta e seis mil seiscentos e sessenta e seis biliões seiscentos e sessenta mil milhões');
is(num2word(70000000000000000007),'setenta triliões e sete');
is(num2word(88123459999999999999),'oitenta e oito triliões cento e vinte e três mil quatrocentos e cinquenta e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');
is(num2word(99999999999999999999),'noventa e nove triliões novecentos e noventa e nove mil novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

is(num2word(100000000000000000000),'cem triliões');
is(num2word(222666555444333222111),'duzentos e vinte e dois triliões seiscentos e sessenta e seis mil quinhentos e cinquenta e cinco biliões quatrocentos e quarenta e quatro mil trezentos e trinta e três milhões duzentos e vinte e dois mil cento e onze');
is(num2word(333222111000999888777),'trezentos e trinta e três triliões duzentos e vinte e dois mil cento e onze biliões novecentos e noventa e nove milhões oitocentos e oitenta e oito mil setecentos e setenta e sete');
is(num2word(432123765890876345839),'quatrocentos e trinta e dois triliões cento e vinte e três mil setecentos e sessenta e cinco biliões oitocentos e noventa mil oitocentos e setenta e seis milhões trezentos e quarenta e cinco mil oitocentos e trinta e nove');
is(num2word(550050050505555555555),'quinhentos e cinquenta triliões cinquenta mil e cinquenta biliões quinhentos e cinco mil quinhentos e cinquenta e cinco milhões quinhentos e cinquenta e cinco mil quinhentos e cinquenta e cinco');
is(num2word(666606000000000006606),'seiscentos e sessenta e seis triliões seiscentos e seis mil biliões seis mil seiscentos e seis');
is(num2word(700007070700070077007),'setecentos triliões sete mil e setenta biliões setecentos mil e setenta milhões setenta e sete mil e sete');
is(num2word(808808808808808808808),'oitocentos e oito triliões oitocentos e oito mil oitocentos e oito biliões oitocentos e oito mil oitocentos e oito milhões oitocentos e oito mil oitocentos e oito');
is(num2word(999999999999999999999),'novecentos e noventa e nove triliões novecentos e noventa e nove mil novecentos e noventa e nove biliões novecentos e noventa e nove mil novecentos e noventa e nove milhões novecentos e noventa e nove mil novecentos e noventa e nove');

}
