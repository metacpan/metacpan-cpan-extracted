#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 605;

{
    use Math::AnyNum;

    my $q = Math::AnyNum->new_q('2');
    my $z = Math::AnyNum->new_z('3');
    my $f = Math::AnyNum->new_f('4');
    my $c = Math::AnyNum->new_c('5');

    is($q->numify,    2);
    is((-$q)->numify, -2);
    is($z->numify,    3);
    is((-$z)->numify, -3);
    is($f->numify,    4);
    is((-$f)->numify, -4);
    is($c->numify,    5);
    is((-$c)->numify, -5);

    is(($q + '1/2')->numify, '2.5');
    is(('1/2' - $q)->numify, '-1.5');

    is(($z + 0.5)->numify, '3.5');
    is((0.5 - $z)->numify, '-2.5');

    is(($f + 0.5)->numify, '4.5');
    is((0.5 - $f)->numify, '-3.5');

    is(($c + 0.5)->numify, '5.5');
    is((0.5 - $c)->numify, '-4.5');

    ok($q == 2);
    ok($z == 3);
    ok($f == 4);
    ok($c == 5);

    ok(not $q != 2);
    ok(not $z != 3);
    ok(not $f != 4);
    ok(not $c != 5);

    is($q, 2);
    is($z, 3);
    is($f, 4);
    is($c, 5);

    is(ref($$q), 'Math::GMPq');
    is(ref($$z), 'Math::GMPz');
    is(ref($$f), 'Math::MPFR');
    is(ref($$c), 'Math::MPC');

    #
    ## Addition
    #
    is($q + $q, 4);
    is($q + $z, 5);
    is($q + $f, 6);
    is($q + $c, 7);

    is($z + $q, 5);
    is($z + $z, 6);
    is($z + $f, 7);
    is($z + $c, 8);

    is($f + $q, 6);
    is($f + $z, 7);
    is($f + $f, 8);
    is($f + $c, 9);

    is($c + $q, 7);
    is($c + $z, 8);
    is($c + $f, 9);
    is($c + $c, 10);

    #
    ## Subtraction
    #
    is($q - $q, 0);
    is($q - $z, -1);
    is($q - $f, -2);
    is($q - $c, -3);

    is($z - $q, 1);
    is($z - $z, 0);
    is($z - $f, -1);
    is($z - $c, -2);

    is($f - $q, 2);
    is($f - $z, 1);
    is($f - $f, 0);
    is($f - $c, -1);

    is($c - $q, 3);
    is($c - $z, 2);
    is($c - $f, 1);
    is($c - $c, 0);

    #
    ## Subtraction (Scalar - AnyNum)
    #

    is(5 - $q,    3);
    is(3.5 - $q,  1.5);
    is((-4) - $q, -6);

    is(6 - $z,    3);
    is(4.5 - $z,  1.5);
    is((-5) - $z, -8);

    is(7 - $f,    3);
    is(5.5 - $f,  1.5);
    is((-6) - $f, -10);

    is(8 - $c,    3);
    is(6.5 - $c,  1.5);
    is((-7) - $c, -12);

    #
    ## Multiplication
    #
    is($q * $q, 4);
    is($q * $z, 6);
    is($q * $f, 8);
    is($q * $c, 10);

    is($z * $q, 6);
    is($z * $z, 9);
    is($z * $f, 12);
    is($z * $c, 15);

    is($f * $q, 8);
    is($f * $z, 12);
    is($f * $f, 16);
    is($f * $c, 20);

    is($c * $q, 10);
    is($c * $z, 15);
    is($c * $f, 20);
    is($c * $c, 25);

    #
    ## Division
    #
    is($q / $q, 1);
    is($q / $z, '2/3');
    is($q / $f, '0.5');
    is($q / $c, '0.4');

    is($z / $q, '3/2');
    is($z / $z, 1);
    is($z / $f, '0.75');
    is($z / $c, '0.6');

    is($f / $q, 2);
    like($f / $z, qr/^1\.333333333333333333333333333*\z/);
    is($f / $f, 1);
    is($f / $c, '0.8');

    is($c / $q, '2.5');
    like($c / $z, qr/^1\.66666666666666666666666666\d*\z/);
    is($c / $f, '1.25');
    is($c / $c, 1);

    #
    ## Division (Scalar / AnyNum)
    #

    is(16 / $q,   8);
    is(15 / $q,   '15/2');
    is(4.5 / $q,  2.25);
    is((-8) / $q, -4);

    is(18 / $z,    6);
    is(14 / $z,    '14/3');
    is(4.5 / $z,   1.5);
    is((-27) / $z, -9);

    is(16 / $f,    4);
    is(15 / $f,    3.75);
    is(4.5 / $f,   1.125);
    is((-42) / $f, -10.5);

    is(20 / $c,    4);
    is(14 / $c,    2.8);
    is(13.5 / $c,  2.7);
    is((-42) / $c, -8.4);

    #
    ## mpq [+, -] mpz
    #

    is(Math::AnyNum->new_q('5/12') + Math::AnyNum->new_z('100'), '1205/12');
    is(Math::AnyNum->new_q('5/12') - Math::AnyNum->new_z('100'), '-1195/12');

    is(Math::AnyNum->new_z('100') + Math::AnyNum->new_q('5/12'), '1205/12');
    is(Math::AnyNum->new_z('100') - Math::AnyNum->new_q('5/12'), '1195/12');

    #
    ## mpq [*, /] mpz
    #

    is(Math::AnyNum->new_q('5/12') * Math::AnyNum->new_z('100'), '125/3');
    is(Math::AnyNum->new_q('5/12') / Math::AnyNum->new_z('42'),  '5/504');

    is(Math::AnyNum->new_z('100') * Math::AnyNum->new_q('5/12'), '125/3');
    is(Math::AnyNum->new_z('42') / Math::AnyNum->new_q('5/12'),  '504/5');

    #
    ## Negation
    #
    is(-$q, -2);
    is(-$z, -3);
    is(-$f, -4);
    is(-$c, -5);

    # Division by zero
    is($q / 0, 'Inf');
    is($z / 0, 'Inf');
    is($f / 0, 'Inf');
    is($c / 0, 'Inf+NaNi');

    is(-$q / 0, '-Inf');
    is(-$z / 0, '-Inf');
    is(-$f / 0, '-Inf');
    is(-$c / 0, '-Inf+NaNi');

    #
    ## Square root
    #
    like(sqrt($q), qr/^1\.414213562373095048\d*\z/);
    like(sqrt($z), qr/^1\.732050807568877293527446\d*\z/);
    is(sqrt($f), '2');
    like(sqrt($c), qr/^2\.2360679774997896964091736\d*\z/);

    #
    ## Complex square root
    #
    like(sqrt(-$q), qr/^1\.414213562373095048\d*i\z/);
    like(sqrt(-$z), qr/^1\.732050807568877293\d*i\z/);
    is(sqrt(-$f), '2i');
    like(sqrt(-$c), qr/^-2\.2360679774997896964091736\d*i\z/);

    #
    ## Power
    #

    is($q**$q, 4);
    is($q**$z, 8);
    is($q**$f, 16);
    is($q**$c, 32);

    is($z**$q, 9);
    is($z**$z, 27);
    is($z**$f, 81);
    is($z**$c, 243);

    is($f**$q, 16);
    is($f**$z, 64);
    is($f**$f, 256);
    is($f**$c, 1024);

    is($c**$q, 25);
    is($c**$z, 125);
    is($c**$f, 625);
    is($c**$c, 3125);

#<<<
    like(Math::AnyNum->new('-1.2') ** Math::AnyNum->new('3.4'),
         qr/^-0\.5743790627709710900290932\d*-1\.767756985588369210401232327481\d*i\z/);
#>>>

    like((-$z)**(1 / $q),  qr/^1\.7320508075688772935274463415058723669\d*i\z/);
    like((-$q)**(-1 / $q), qr/^-0\.70710678118654752440084436210484903928\d*i\z/);
    like((-$q)**(-1 / $z), qr/^0\.39685026299204986868792640981\d*-0\.6873648184993013131917395984430\d*i\z/);

    is((-$z)**(-$q), '1/9');
    is((-$q)**(-$z), '-1/8');
    is((-$q)**$z,    '-8');
    is((-2)**$z,     '-8');
    is((-$z)**$q,    '9');
    is((1 / $q)**$z, '1/8');
    is((-$z)**$z,    '-27');
    is((-$z)**2,     '9');

    like($z**(1 / $q),  qr/^1\.732050807568877293527446\d*\z/);
    like($q**(1 / $q),  qr/^1\.4142135623730950488016887\d*\z/);
    like($q**(-1 / $f), qr/^0\.8408964152537145430311254762\d*\z/);
    like($z**(-1 / $f), qr/^0\.7598356856515925473311877506\d*\z/);

    like((-$z)**(-1 / $f), qr/^0\.537284965911770959776669078352965\d*-0\.53728496591177095977666907835296\d*i\z/);

    like((-$q)**(-1 / $f), qr/^0\.5946035575013605333587499852\d*\-0\.59460355750136053335874998528023\d*i\z/);

    like((-$q)**(1 / $f), qr/^0\.8408964152537145430311254762332\d*\+0\.840896415253714543031125\d*i\z/);

    is(ref(${(-$f)**$f}),       'Math::MPFR');
    is(ref(${(-$f)**(1 / $f)}), 'Math::MPC');

    is((-$f)**$f,        256);
    is((-$f)**(1 / $q),  '2i');
    is((-$f)**(1 / $f),  '1+i');
    is((-$f)**(-1 / $f), '0.5-0.5i');
    like((-$f)**(1 / $z), qr/^0\.79370052598409973737585\d*\+1\.37472963699860262638347919\d*i\z/);

    #
    ## Natural exponentiation
    #
    like(exp(Math::AnyNum->pi * Math::AnyNum->i)->real->zeta, qr/^-0\.083333333333333333333333333\d*\z/);

    #
    ## MPC to MPFR
    #
    like((($z + $f * sqrt($q - $z)) - sqrt(-$z + $q) * $f)->zeta, qr/^1\.202056903159594285399738161511449\d*\z/);

    like((($z + $f * sqrt($q - $z)) - sqrt(-$z + $q) * ($c - 1))->zeta, qr/^1\.202056903159594285399738161511449\d*\z/);

    like((($z + $f * sqrt($q - $z)) - ($z + 1) * sqrt(-$z + $q))->zeta, qr/^1\.202056903159594285399738161511449\d*\z/);

    like((($z + $f * sqrt($q - $z)) - sqrt(-$z + $q) * ($z + 1))->zeta, qr/^1\.202056903159594285399738161511449\d*\z/);

    like((($z + $f * sqrt($q - $z)) - sqrt(-$z + $q) * ($q + 2))->zeta, qr/^1\.202056903159594285399738161511449\d*\z/);

    is(($z + $q * sqrt($q - $z))->real, $z);
    is(($z + $q * sqrt($q - $z))->imag, $q);
    is(($q + $z * sqrt($q - $z))->real, $q);
    is(($q + $z * sqrt($q - $z))->imag, $z);

    #
    ## zeta
    #
    like($q->zeta, qr/^1\.64493406684822643647\d*\z/);
    like($z->zeta, qr/^1\.20205690315959428\d*\z/);
    like($f->zeta, qr/^1\.0823232337111381915160\d*\z/);
    like($c->zeta, qr/^1\.03692775514336992633136\d*\z/);

    #
    ## Equality
    #
    ok($q == $q);
    ok($z == $z);
    ok($f == $f);
    ok($c == $c);

    ok($q == sqrt($q * $q));
    ok($z == sqrt($z * $z));
    ok($f == sqrt($f * $f));
    ok($c == sqrt($c * $c));

    ok(sqrt($q * $q) == $q);
    ok(sqrt($z * $z) == $z);
    ok(sqrt($f * $f) == $f);
    ok(sqrt($c * $c) == $c);

    ok($q * $f == $f * $q);
    ok($q * $z == $z * $q);
    ok($q * $c == $c * $q);
    ok($z * $f == $f * $z);
    ok($z * $c == $c * $z);
    ok($f * $c == $c * $f);

    ok(!($q * $f != $f * $q));
    ok(!($q * $z != $z * $q));
    ok(!($q * $c != $c * $q));
    ok(!($z * $f != $f * $z));
    ok(!($z * $c != $c * $z));
    ok(!($f * $c != $c * $f));

    ok(!($q != $q));
    ok(!($z != $z));
    ok(!($f != $f));
    ok(!($c != $c));

    ok(!($z == $q));
    ok(!($z == $f));
    ok(!($z == $c));

    ok(!($q == $z));
    ok(!($q == $f));
    ok(!($q == $c));

    ok(!($f == $z));
    ok(!($f == $q));
    ok(!($f == $c));

    ok(!($c == $z));
    ok(!($c == $f));
    ok(!($c == $q));

    #
    ## Inequality
    #
    ok($q != $z);
    ok($q != $f);
    ok($q != $c);

    ok($z != $q);
    ok($z != $f);
    ok($z != $c);

    ok($f != $q);
    ok($f != $z);
    ok($f != $c);

    ok($c != $q);
    ok($c != $z);
    ok($c != $f);

    #
    ## Comparisons
    #

    is($q * $f <=> $f * $q, 0);
    is($q * $z <=> $z * $q, 0);
    is($z * $f <=> $f * $z, 0);
    is($c * $f <=> $f * $c, 0);

    is($q <=> 3, -1);
    is($q <=> 2, 0);
    is($q <=> 1, 1);

    is($c <=> 7, -1);
    is($c <=> 5, 0);
    is($c <=> 2, 1);

    is(3 <=> $q, 1);
    is(2 <=> $q, 0);
    is(1 <=> $q, -1);

    is(2 <=> $c, -1);
    is(5 <=> $c, 0);
    is(7 <=> $c, 1);

    is($f <=> 5, -1);
    is($f <=> 4, 0);
    is($f <=> 3, 1);

    ok(5 > $f);
    ok(4 >= $f);
    ok(4 <= $f);
    ok(4 == $f);

    ok($f == 4);
    ok($f > 3);
    ok(!($f > 6));
    ok($f > 2.5);
    ok($f >= 2.5);
    ok($f < 4.5);
    ok($f <= 4.5);

    ok(5 >= $c);
    ok(5 <= $c);
    ok(6 > $c);
    ok(4 < $c);

    ok($c > 4);
    ok($c < 6);

    is($z <=> $q, +1);
    is($q <=> $z, -1);
    is($f <=> $z, 1);
    is($z <=> $f, -1);

    ok($f > $q);
    ok($f > $z);
    ok($f >= $f);
    ok($f <= $f);

    ok($z > $q);
    ok($z >= $z);
    ok($z <= $z);
    ok($z < $f);

    ok($q < $z);
    ok($q >= $q);
    ok($q <= $q);
    ok($q < $f);

    #
    ## Scalar
    #
    is($q + (-7), '-5');
    is($q + (7),  '9');
    is($z + (-7), '-4');
    is($z + (7),  '10');
    is($f + (-7), '-3');
    is($f + (7),  '11');
    is($c + (-7), '-2');
    is($c + (7),  '12');

    is($q - (-7), '9');
    is($q - (7),  '-5');
    is($z - (-7), '10');
    is($z - (7),  '-4');
    is($f - (-7), '11');
    is($f - (7),  '-3');
    is($c - (-7), '12');
    is($c - (7),  '-2');

    is($q * (-7), '-14');
    is($q * (7),  '14');
    is($z * (-7), '-21');
    is($z * (7),  '21');
    is($f * (-7), '-28');
    is($f * (7),  '28');
    is($c * (-7), '-35');
    is($c * (7),  '35');

    is($q / (-7), '-2/7');
    is($q / (7),  '2/7');
    is($z / (-7), '-3/7');
    is($z / (7),  '3/7');
    like($f / (-7), qr/^-0\.57142857142857142857142\d*\z/);
    like($f / (7),  qr/^0\.57142857142857142857142\d*\z/);
    like($c / (-7), qr/^-0\.714285714285714285714\d*\z/);
    like($c / (7),  qr/^0\.714285714285714285714\d*\z/);

    # With common factors
    is($q / (2),  '1');
    is($q / (-2), '-1');
    is(($q * 26) / (13),  '4');
    is((26 * $q) / (-13), '-4');
    is($q / (-2), '-1');
    is($z / (3),  '1');
    is($z / (-3), '-1');
    is(($z * 10) / 5, '6');
    is((10 * $z) / (-5), '-6');

    #
    ## Scalar power
    #
    is($q**7,       '128');
    is($q**(-7),    '1/128');
    is($q**6,       '64');
    is((-$q)**(7),  '-128');
    is((-$q)**(6),  '64');
    is((-$q)**(-6), '1/64');
    is((-$q)**(-7), '-1/128');

    is($z**7,       '2187');
    is($z**(-7),    '1/2187');
    is($z**6,       '729');
    is((-$z)**6,    '729');
    is((-$z)**(-7), '-1/2187');
    is((-$z)**(-6), '1/729');
    is((-$z)**7,    '-2187');

    is($f**7,       '16384');
    is($f**(-7),    '0.00006103515625');
    is($f**6,       '4096');
    is((-$f)**6,    '4096');
    is((-$f)**(-7), '-0.00006103515625');
    is((-$f)**(-6), '0.000244140625');
    is((-$f)**7,    '-16384');

    is($c**7,       '78125');
    is($c**(-7),    '0.0000128');
    is($c**6,       '15625');
    is((-$c)**6,    '15625');
    is((-$c)**(-7), '-0.0000128');
    is((-$c)**(-6), '0.000064');
    is((-$c)**7,    '-78125');

    is($z + 'abc',   'NaN');
    is($z + 'a.bc',  'NaN');
    is($f**'a.bc',   'NaN');
    is($f**'abc',    'NaN');
    is($q**'123ez',  'NaN');
    is($c**'123e.z', 'NaN+NaNi');

    is($q + '89123891263487912648128462184612836', '89123891263487912648128462184612838');
    is($z + '89123891263487912648128462184612836', '89123891263487912648128462184612839');
    is($f + '89123891263487912648128462184612836', '89123891263487912648128462184612840');
    is($c + '89123891263487912648128462184612836', '89123891263487912648128462184612841');

    is($q - '89123891263487912648128462184612836', '-89123891263487912648128462184612834');
    is($z - '89123891263487912648128462184612836', '-89123891263487912648128462184612833');
    is($f - '89123891263487912648128462184612836', '-89123891263487912648128462184612832');
    is($c - '89123891263487912648128462184612836', '-89123891263487912648128462184612831');

    is($q * '89123891263487912648128462184612836', '178247782526975825296256924369225672');
    is($z * '89123891263487912648128462184612836', '267371673790463737944385386553838508');
    is($f * '89123891263487912648128462184612836', '356495565053951650592513848738451344');
    is($c * '89123891263487912648128462184612836', '445619456317439563240642310923064180');

    is($q / '89123891263487912648128462184612836',         '1/44561945631743956324064231092306418');
    is($z / '89123891263487912648128462184612836',         '3/89123891263487912648128462184612836');
    is(($f / '89123891263487912648128462184612836')**(-1), '22280972815871978162032115546153209');
    is(($c / '89123891263487912648128462184612836')**(-1), '17824778252697582529625692436922567.2');

    #
    ## Natural logarithm
    #
    like(log($q),  qr/^0\.69314718055994530941723212145817\d*\z/);
    like(log(-$q), qr/^0\.6931471805599453094172321214581765\d*\+3\.1415926535897932384626433832795028841\d*i\z/);

    like(log($z),  qr/^1\.098612288668109691395245236922525704\d*\z/);
    like(log(-$z), qr/^1\.09861228866810969139524523692252570\d*\+3\.14159265358979323846264338327\d*i\z/);

    like($f->log, qr/^1\.38629436111989061883446424291\d*\z/);
    like($c->log, qr/^1\.6094379124341003746007593332\d*\z/);

    like($c->log(3), qr/^1\.46497352071792716719704040\d*\z/);
    like($f->log(3), qr/^1\.261859507142914874199054228\d*\z/);
    like($z->log(5), qr/^0\.682606194485985295134566359271052253\d*\z/);

    is($z->log($z), 1);
    is($q->log($q), 1);
    is($f->log($f), 1);
    is($c->log($c), 1);

    like($z->log($q), qr/^1\.5849625007211561814537\d*\z/);
    like($q->log($z), qr/^0\.6309297535714574370995271\d*\z/);

    is($q->log2, 1);
    like($z->log2, qr/^1\.5849625007211561814537389\d*\z/);
    is($f->log2, 2);
    like($c->log2, qr/^2\.3219280948873623478703194294\d*\z/);

    like($q->log10, qr/^0\.3010299956639811952137\d*\z/);
    like($z->log10, qr/^0\.47712125471966243729502\d*\z/);
    like($f->log10, qr/^0\.60205999132796239042747\d*\z/);
    like($c->log10, qr/^0\.69897000433601880478626110527\d*\z/);

    is(Math::AnyNum->new(),      '0');
    is(Math::AnyNum->new(''),    '0');
    is(Math::AnyNum->new(undef), '0');
    is(Math::AnyNum->new(undef, 10), '0');
    is(Math::AnyNum->new(undef, 36), '0');

    my $NaN = Math::AnyNum->nan;
    my $Inf = Math::AnyNum->inf;

    ok($z != $NaN);
    ok($q != $NaN);
    ok($f != $NaN);
    ok($c != $NaN);

    ok($NaN != $z);
    ok($NaN != $q);
    ok($NaN != $f);
    ok($NaN != $c);

    ok($z != $Inf);
    ok($q != $Inf);
    ok($f != $Inf);
    ok($c != $Inf);

    ok($Inf != $z);
    ok($Inf != $q);
    ok($Inf != $f);
    ok($Inf != $c);

    ok(not $z == $NaN);
    ok(not $q == $NaN);
    ok(not $f == $NaN);
    ok(not $c == $NaN);

    ok(not $z == $Inf);
    ok(not $q == $Inf);
    ok(not $f == $Inf);
    ok(not $c == $Inf);

    ok(not $NaN == $z);
    ok(not $NaN == $q);
    ok(not $NaN == $f);
    ok(not $NaN == $c);

    ok(not $Inf == $z);
    ok(not $Inf == $q);
    ok(not $Inf == $f);
    ok(not $Inf == $c);

    ok(not $NaN == 2);
    ok(not $Inf == 2);

    ok($NaN != 2);
    ok($Inf != 2);

    ok($Inf->is_inf);
    ok((-$Inf)->is_ninf);
    ok($NaN->is_nan);

    ok(not $NaN->is_inf);
    ok(not $NaN->is_ninf);
    ok(not $Inf->is_nan);
    ok(not $Inf->is_ninf);
    ok(not((-$Inf)->is_inf));
    ok(not((-$Inf)->is_nan));

    ok(2 != $NaN);
    ok(2 != $Inf);

    ok(not 2 == $NaN);
    ok(not 2 == $Inf);

    ok(not $NaN == 0);
    ok(not 0 == $NaN);

    ok($NaN != 0);
    ok(0 != $NaN);

    my $zero = Math::AnyNum->zero;
    ok(not $NaN == $zero);
    ok(not $zero == $NaN);

    ok($NaN != $zero);
    ok($zero != $NaN);

    ok(not defined($NaN <=> 42));
    ok(not defined($NaN <=> Math::AnyNum->new_f(42)));
    ok(not defined(Math::AnyNum->new_f(42) <=> $NaN));
    ok(not defined(42 <=> $NaN));

    my $NaN_NaN = Math::AnyNum->new_c("NaN", "NaN");
    ok(not defined($NaN_NaN <=> 42));
    ok(not defined(42 <=> $NaN_NaN));
    ok(not defined($NaN_NaN <=> $NaN_NaN));
    ok(not defined($NaN <=> $NaN_NaN));
    ok(not defined($NaN_NaN <=> $NaN));

    ok(not $NaN == $NaN);
    ok(not $NaN == $NaN_NaN);
    ok(not $NaN_NaN == $NaN_NaN);
    ok(not $NaN_NaN == $NaN);

    ok($NaN_NaN != $Inf);
    ok(not $NaN_NaN == $Inf);

    ok($NaN != $NaN);
    ok($NaN != $NaN_NaN);
    ok($NaN_NaN != $NaN_NaN);
    ok($NaN_NaN != $NaN);

    ok(not defined(42 < $NaN));
    ok(not defined(42 > $NaN));

    ok(not defined(42 <= $NaN));
    ok(not defined(42 >= $NaN));

    ok(not defined($NaN < 42));
    ok(not defined($NaN > 42));

    ok(not defined($NaN <= 42));
    ok(not defined($NaN >= 42));

    ok(not defined(42 < $NaN_NaN));
    ok(not defined(42 > $NaN_NaN));

    ok(not defined(42 <= $NaN_NaN));
    ok(not defined(42 >= $NaN_NaN));

    ok(not defined($NaN_NaN < 42));
    ok(not defined($NaN_NaN > 42));

    ok(not defined($NaN_NaN <= 42));
    ok(not defined($NaN_NaN >= 42));

    ok(not defined($NaN < $NaN));
    ok(not defined($NaN > $NaN));
    ok(not defined($NaN <= $NaN));
    ok(not defined($NaN >= $NaN));

    ok(not defined($NaN_NaN < $NaN));
    ok(not defined($NaN_NaN > $NaN));
    ok(not defined($NaN_NaN <= $NaN));
    ok(not defined($NaN_NaN >= $NaN));
}

{
    #
    ## Complex
    #

    my $i = Math::AnyNum->i;
    my $x = Math::AnyNum->new('3');
    my $y = Math::AnyNum->new('4');

    my $z = $x + $y * $i;

    is($z + 2, "5+4i");
    is($z + (-2), "1+4i");
}

{
    #
    ## Complex numbers in Cartesian form
    #

    my $p = Math::AnyNum->new(100);

    is($p + "(0.2 1/2)",    '100.2+0.5i');
    is($p + "(0.2 0.2)",    '100.2+0.2i');
    is($p + "(1/2 0.2)",    '100.5+0.2i');
    is($p + "(1/2 13)",     '100.5+13i');
    is($p + "(13 1/2)",     '113+0.5i');
    is($p + "(-13 1/2)",    '87+0.5i');
    is($p + "(-13 -1/2)",   '87-0.5i');
    is($p + "(13 +1/2)",    '113+0.5i');
    is($p + "(13 +0.2)",    '113+0.2i');
    is($p + "(+13 0.2)",    '113+0.2i');
    is($p + "(+13 +1/2)",   '113+0.5i');
    is($p + "(-13 +1/2)",   '87+0.5i');
    is($p + "(-13 -1/2)",   '87-0.5i');
    is($p + "(1/2 1/5)",    '100.5+0.2i');
    is($p + "(5 9)",        '105+9i');
    is($p + "(-5 -9)",      '95-9i');
    is($p + "(-1/5 -1/2)",  '99.8-0.5i');
    is($p + "(3+4i 5-6i)",  '109+9i');
    is($p + "(1/2 5+6i)",   '94.5+5i');
    is($p + "(3 5-6i)",     '109+5i');
    is($p + "(0.2 -5+6i)",  '94.2-5i');
    is($p + "(5-6i 5)",     '105-i');
    is($p + "(3+6i 5)",     '103+11i');
    is($p + "(-3-6i -1/2)", '97-6.5i');
    is($p + "(-3+6i -0.5)", '97+5.5i');
}

{
    #
    ## Division by zero
    #
    my $z = Math::AnyNum->new_z('0');
    my $q = Math::AnyNum->new_q('0');
    my $f = Math::AnyNum->new_f('0');
    my $c = Math::AnyNum->new_c('0');

    my $nz = Math::AnyNum->new_z('13');
    my $nq = Math::AnyNum->new_q('13');
    my $nf = Math::AnyNum->new_f('13');
    my $nc = Math::AnyNum->new_c('13');

    is($nz / $z, 'Inf');
    is($nz / $q, 'Inf');
    is($nz / $f, 'Inf');
    is($nz / $c, 'Inf+NaNi');

    is($nq / $z, 'Inf');
    is($nq / $q, 'Inf');
    is($nq / $f, 'Inf');
    is($nq / $c, 'Inf+NaNi');

    is($nf / $z, 'Inf');
    is($nf / $q, 'Inf');
    is($nf / $f, 'Inf');
    is($nf / $c, 'Inf+NaNi');

    is($nc / $z, 'Inf+NaNi');
    is($nc / $q, 'Inf+NaNi');
    is($nc / $f, 'Inf+NaNi');
    is($nc / $c, 'Inf+NaNi');

    is($z / $z, 'NaN');
    is($z / $q, 'NaN');
    is($z / $f, 'NaN');
    is($z / $c, 'NaN+NaNi');

    is($q / $z, 'NaN');
    is($q / $q, 'NaN');
    is($q / $f, 'NaN');
    is($q / $c, 'NaN+NaNi');

    is($f / $z, 'NaN');
    is($f / $q, 'NaN');
    is($f / $f, 'NaN');
    is($f / $c, 'NaN+NaNi');

    is($c / $z, 'NaN+NaNi');
    is($c / $q, 'NaN+NaNi');
    is($c / $f, 'NaN+NaNi');
    is($c / $c, 'NaN+NaNi');
}

{
    # Lambert W
    like(Math::AnyNum->new('-0.35787944117144232159552377016146086744581113103177')->LambertW,
         qr/^-0\.7832291989812967764330746/);
    like(log(Math::AnyNum->new(100))->LambertW->exp, qr/^3\.59728502354041750549765/);
    like(Math::AnyNum->mone->LambertW,               qr/^-0\.31813150520476413\d*\+1\.33723570143068\d*i\z/);
    like(Math::AnyNum->new(-42.5)->LambertW,         qr/^2\.50845139125332570\d*\+2\.3820376343818060087\d*i\z/);
    like(Math::AnyNum->one->LambertW,                qr/^0\.5671432904097838729999/);
    is(Math::AnyNum->e->LambertW, 1);
}

{
    is(Math::AnyNum->new_c(3, 4), '3+4i');
    is(Math::AnyNum->new_c(5),     '5');
    is(Math::AnyNum->new_c('1e2'), '100');
    is(Math::AnyNum->new_c('1e2', '1e3'), '100+1000i');
    is(Math::AnyNum->new_c("ff", "ae", 16), '255+174i');
}

{
    # Trigonometric functions
    my $f = Math::AnyNum->new_f('12.3');
    my $c = Math::AnyNum->new_c('3.5', '5.2');

    like(cos($f), qr/^0\.964732617886609590915710186\d*\z/);
    like(sin($f), qr/^-0\.263231791365801650601707825888\d*\z/);

    like(cos($c), qr/\-84\.87938457391136851218282456\d*\+31\.79266348861286277038879360747474\d*i\z/);
    like(sin($c), qr/^-31\.79459860688613495225058132\d*\-84\.87421855026867660849447320745263\d*i\z/);
}
