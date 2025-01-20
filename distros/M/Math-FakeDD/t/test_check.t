
# Check that the values that dd_repro_test uses internally are as expected.
# It's intended that additional tests will be included over time.
# DBL_MIN = 2.2250738585072014e-308 = 2 ** -1022

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

for my $val(119984 .. 120006) {
  my $s = "$val" . '.0';
  my $dd = Math::FakeDD->new($s);
  cmp_ok($dd, '==', $s + 0, "$s: equivalence ok");
  my $repro = dd_repro($dd);
  cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$s: dd_repro_test ok");
  cmp_ok($s, 'eq', $Math::FakeDD::examine{repro}, "$s: \$Math::FakeDD::examine{repro} ok");
  my $chopped = "$val";
  my $exponent = 0;
  while($chopped =~ /0$/) {
    chop $chopped;
    $exponent++;
  }
  chop $chopped;
  my $inc = ($chopped + 1) . 0;
  $chopped .= 0;
  $chopped .= "e$exponent" if $exponent;
  cmp_ok($chopped, 'eq', $Math::FakeDD::examine{chop}, "$s: \$Math::FakeDD::examine{chop} ok");
  cmp_ok($inc, 'eq', (split(/e/i, $Math::FakeDD::examine{inc}))[0], "$s: \$Math::FakeDD::examine{inc} ok");
}

my $dd = Math::FakeDD->new(2 ** 150) + (2 ** -200);
my $repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "(2 ** 150) + (2 ** -200) ok");
cmp_ok('1427247692705959881058285969449495136382746624.0000000000000000000000000000000000000000000000000000000000006223015277861142',
       'eq', $Math::FakeDD::examine{repro}, "(2 ** 150) + (2 ** -200): \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1427247692705959881058285969449495136382746624.0000000000000000000000000000000000000000000000000000000000006223015277861140',
       'eq', $Math::FakeDD::examine{chop}, "(2 ** 150) + (2 ** -200): \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1427247692705959881058285969449495136382746624.0000000000000000000000000000000000000000000000000000000000006223015277861150e0',
       'eq', $Math::FakeDD::examine{inc}, "(2 ** 150) + (2 ** -200): \$Math::FakeDD::examine{inc} ok") ;


$dd = Math::FakeDD->new('0x1p+200') - (2 ** -549);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "(2 ** 200) - (2 ** -549) ok");
cmp_ok('1606938044258990275541962092341162602522202993782792835301375.9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994573342896764947',
       'eq', $Math::FakeDD::examine{repro}, "(2 ** 200) - (2 ** -549): \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1606938044258990275541962092341162602522202993782792835301375.9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994573342896764940',
       'eq', $Math::FakeDD::examine{chop}, "(2 ** 200) - (2 ** -549): \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1606938044258990275541962092341162602522202993782792835301375.9999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999994573342896764950e0',
       'eq', $Math::FakeDD::examine{inc}, "(2 ** 200) - (2 ** -549): \$Math::FakeDD::examine{inc} ok") ;

my $str = '0.0772793798106974e-295';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('7.72793798106974e-297',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('7.72793798106970e-297',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('7.72793798106980e-297',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0.562971464820421e16';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('5629714648204210.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('562971464820420e1',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('562971464820430e1',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0.59951823306102625e15';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('599518233061026.25',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('599518233061026.20',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('599518233061026.30e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.8p+982';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('61312214308906592614083769744491680749592102720577255674958251287671149318214576100913908699933768737464599967053593453894833295003451197257907357643310021232230574273057351982618758802770830966251111119192389345075122497181313138346665633846723916518618754259223225599253252973476167984984621056.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('61312214308906592614083769744491680749592102720577255674958251287671149318214576100913908699933768737464599967053593453894833295003451197257907357643310021232230574273057351982618758802770830966251111119192389345075122497181313138346665633846723916518618754259223225599253252973476167984984621050',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('61312214308906592614083769744491680749592102720577255674958251287671149318214576100913908699933768737464599967053593453894833295003451197257907357643310021232230574273057351982618758802770830966251111119192389345075122497181313138346665633846723916518618754259223225599253252973476167984984621060e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1p+55';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('36028797018963968.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('36028797018963960',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('36028797018963970e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.8p+55';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('54043195528445952.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('54043195528445950',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('54043195528445960e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.8ep+55';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('56013520365420544.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('56013520365420540',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('56013520365420550e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.ep+58';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('540431955284459520.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('54043195528445950e1',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('54043195528445960e1',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1p+1006';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('685765508599211085406992031398401158759299079491541508764000248557024672719959118395646962442045349201660590667234013968119772982843080987903012964780708787451812337588750783066948774723991753080189067657794974398949244241113521123786594812548932026532556574571938698730267509225767960757581162756440064.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('685765508599211085406992031398401158759299079491541508764000248557024672719959118395646962442045349201660590667234013968119772982843080987903012964780708787451812337588750783066948774723991753080189067657794974398949244241113521123786594812548932026532556574571938698730267509225767960757581162756440060',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('685765508599211085406992031398401158759299079491541508764000248557024672719959118395646962442045349201660590667234013968119772982843080987903012964780708787451812337588750783066948774723991753080189067657794974398949244241113521123786594812548932026532556574571938698730267509225767960757581162756440070e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.ffffffffffff8p+999';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('10715086071862663692576036232788416198014059957691751234372213263578972554309461602911777961568967892198733953774887693540039195621895617526639006087302044942618848719498625974407695741319177908684931242647530505452728934218200648725573819927644498709137978246274810890571754925131582314738973254090752.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('10715086071862663692576036232788416198014059957691751234372213263578972554309461602911777961568967892198733953774887693540039195621895617526639006087302044942618848719498625974407695741319177908684931242647530505452728934218200648725573819927644498709137978246274810890571754925131582314738973254090750',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('10715086071862663692576036232788416198014059957691751234372213263578972554309461602911777961568967892198733953774887693540039195621895617526639006087302044942618848719498625974407695741319177908684931242647530505452728934218200648725573819927644498709137978246274810890571754925131582314738973254090760e0',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1.8p-23';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1.78813934326171875e-07',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.78813934326171870e-07',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1.78813934326171880e-07',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

#### Start tests for values that currently depend on  ####
#### mpfrtoa() being called with a second arg of 728. ####

# [0x1p-348 0x0p+0] - largest absolute value that needs that second arg.
# [0xp-1067 0x0p+0] - smallest absolute value that needs that second arg.

$str = '0x1p-348';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1.74406035046733853487515800217489770424180602237365518373890051762028905625417815502235110757472538703793801018276066319613730066266467094593207137055975531305773012905286447297432836868736576258182935459523088539413038e-105',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.74406035046733853487515800217489770424180602237365518373890051762028905625417815502235110757472538703793801018276066319613730066266467094593207137055975531305773012905286447297432836868736576258182935459523088539413030e-105',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1.74406035046733853487515800217489770424180602237365518373890051762028905625417815502235110757472538703793801018276066319613730066266467094593207137055975531305773012905286447297432836868736576258182935459523088539413040e-105',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$dd = dd_nextup($dd); # This value should NOT require that second arg. (LSD is not zero, anyway.)
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "dd_nextup($str) ok");
cmp_ok('1.744060350467338534875158002174897704241806022373655183738900517620289056254178155022351107574725387037938010182760663196137300662664670945932071370559755313057730129052864472974328368687365762581829354595230885394130387e-105',
       'eq', $Math::FakeDD::examine{repro}, "dd_nextup($str)$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.744060350467338534875158002174897704241806022373655183738900517620289056254178155022351107574725387037938010182760663196137300662664670945932071370559755313057730129052864472974328368687365762581829354595230885394130380e-105',
       'eq', $Math::FakeDD::examine{chop}, "dd_nextup($str): \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1.744060350467338534875158002174897704241806022373655183738900517620289056254178155022351107574725387037938010182760663196137300662664670945932071370559755313057730129052864472974328368687365762581829354595230885394130390e-105',
       'eq', $Math::FakeDD::examine{inc}, "dd_nextup($str): \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1p-1067';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('6.3e-322',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('6.0e-322',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('7.0e-322',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$dd = dd_nextdown($dd); # This value should NOT require that second arg.
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "dd_nextdown($str) ok");
cmp_ok('6.27e-322',
       'eq', $Math::FakeDD::examine{repro}, "dd_nextdown($str): \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('6.20e-322',
       'eq', $Math::FakeDD::examine{chop}, "dd_nextdown($str): \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('6.30e-322',
       'eq', $Math::FakeDD::examine{inc}, "dd_nextdown($str): \$Math::FakeDD::examine{inc} ok") ;

#### End of tests for values that currently depend on ####
#### mpfrtoa() being called with a second arg of 728. ####

#### Start confirmation that (2 ** -$x) is being handled     ####
#### correctly for $x in the range 1068 to 1074 (inclusive). ####

# 2 ** -1068: 3.16e-322
$str = '0x1p-1068';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('3.16e-322',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('3.10e-322',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('3.20e-322',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

# 2 ** -1069: 1.6e-322
$str = '0x1p-1069';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1.6e-322',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.0e-322',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('2.0e-322',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

# 2 ** -1070: 8e-323
$str = '0x1p-1070';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('8e-323',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

# 2 ** -1071: 4e-323
$str = '0x1p-1071';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('4e-323',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

# 2 ** -1072: 2e-323
$str = '0x1p-1072';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('2e-323',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

# 2 ** -1073: 1e-323
$str = '0x1p-1073';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1e-323',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;


# 2 ** -1074: 5e-324
$str = '0x1p-1074';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('5e-324',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

#### End of confirmation that (2 ** -$x) is being handled     ####
#### correctly for $x in the range 1068 to 1074 (inclusive). ####

# 2 ** -1025: # 2.781342323134e-309
$str = '0x1p-1025';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('2.781342323134e-309',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('2.781342323130e-309',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('2.781342323140e-309',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '0x1p-1025';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('2.781342323134e-309',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('2.781342323130e-309',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('2.781342323140e-309',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '2.781342323134002e-309';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('2.781342323134e-309',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('2.781342323130e-309',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('2.781342323140e-309',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$str = '2.781342323134e-309';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('2.781342323134e-309',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('2.781342323130e-309',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('2.781342323140e-309',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

#### Begin examples where sprintf("%.17g", $val) and nvtoa($val) assign to different
#### Math::FakeDD objects, even though nvtoa($val) == sprintf("%.17g", $val).

$str = '1.2256808040331321e+24';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1225680804033132100000000.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('12256808040331320e8',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('12256808040331330e8',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

my $hi = dd_nextdown($dd);

$str = '1.225680804033132e+24';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1225680804033132000000000.0',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1225680804033130e9',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1225680804033140e9',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

my $lo = dd_nextup($dd);
cmp_ok($hi, '>', $lo, "nextdown (1.2256808040331321e+24) > nextup (1.225680804033132e+24)");

######################################
######################################

$str = '1.571784478151522e-95';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1.571784478151522e-95',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.571784478151520e-95',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1.571784478151530e-95',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$hi = dd_nextdown($dd);

$str = '1.5717844781515219e-95';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1.5717844781515219e-95',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.5717844781515210e-95',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1.5717844781515220e-95',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$lo = dd_nextup($dd);
cmp_ok($hi, '>', $lo, "nextdown (1.571784478151522e-95) > nextup (1.5717844781515219e-95)");

######################################
######################################

$str = '1.256442731808205e-86';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1.256442731808205e-86',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.256442731808200e-86',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1.256442731808210e-86',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$hi = dd_nextdown($dd);

$str = '1.2564427318082049e-86';
$dd = Math::FakeDD->new($str);
$repro = dd_repro($dd);
cmp_ok(dd_repro_test($repro, $dd, 'examine'), '==', 15, "$str ok");
cmp_ok('1.2564427318082049e-86',
       'eq', $Math::FakeDD::examine{repro}, "$str: \$Math::FakeDD::examine{repro} ok") ;
cmp_ok('1.2564427318082040e-86',
       'eq', $Math::FakeDD::examine{chop}, "$str: \$Math::FakeDD::examine{chop} ok") ;
cmp_ok('1.2564427318082050e-86',
       'eq', $Math::FakeDD::examine{inc}, "$str: \$Math::FakeDD::examine{inc} ok") ;

$lo = dd_nextup($dd);
cmp_ok($hi, '>', $lo, "nextdown (1.256442731808205e-86) > nextup (1.2564427318082049e-86)");

#### End examples where sprintf("%.17g", $val) and nvtoa($val) assign to different
#### Math::FakeDD objects, even though nvtoa($val) == sprintf("%.17g", $val).

done_testing();

__END__

TODO:
1.2256808040331321e+24:
[1.225680804033132e+24 129440000.0]
[1.225680804033132e+24 29440000.0]

1.2564427318082049e-86:
[1.256442731808205e-86 -5.122305591076454e-103]
[1.256442731808205e-86 4.877694408923547e-103]

-1.5717844781515219e-95:
[-1.571784478151522e-95 -4.909479124227983e-113]
[-1.571784478151522e-95 -1.0490947912422798e-111]


