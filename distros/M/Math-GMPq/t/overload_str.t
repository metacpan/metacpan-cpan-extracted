use strict;
use warnings;

use Math::GMPq qw(:mpq);

use Test::More;

{
  my $op = '+';
  my $q1 = '0.7' + Math::GMPq->new('9/10');
  my $q2 = Math::GMPq->new('9/10') + '0.7';
  cmp_ok($q1, '==', $q2, "$op: \$q1 == \$q2");
  cmp_ok(ref($q1), 'eq', 'Math::GMPq', "$op: \$q1 is a Math::GMPq object");
  cmp_ok(ref($q2), 'eq', 'Math::GMPq', "$op: \$q2 is a Math::GMPq object");
}

{
  my $op = '*';
  my $q1 = '0.7' * Math::GMPq->new('9/10');
  my $q2 = Math::GMPq->new('9/10') * '0.7';
  cmp_ok($q1, '==', $q2, "$op: \$q1 == \$q2");
  cmp_ok(ref($q1), 'eq', 'Math::GMPq', "$op: \$q1 is a Math::GMPq object");
  cmp_ok(ref($q2), 'eq', 'Math::GMPq', "$op: \$q2 is a Math::GMPq object");
}

{
  my $op = '-';
  my $q1 = '0.7' - Math::GMPq->new('9/10');
  my $q2 = Math::GMPq->new('9/10') - '0.7';
  cmp_ok($q1, '==', -$q2, "$op: \$q1 == -\$q2");
  cmp_ok(ref($q1), 'eq', 'Math::GMPq', "$op: \$q1 is a Math::GMPq object");
  cmp_ok(ref($q2), 'eq', 'Math::GMPq', "$op: \$q2 is a Math::GMPq object");
}

{
  my $op = '/';
  my $q1 = '0.7' / Math::GMPq->new('9/10');
  my $q2 = Math::GMPq->new('9/10') / '0.7';
  Rmpq_inv($q2, $q2);
  cmp_ok($q1, '==', $q2, "$op: \$q1 == inv \$q2");
  cmp_ok(ref($q1), 'eq', 'Math::GMPq', "$op: \$q1 is a Math::GMPq object");
  cmp_ok(ref($q2), 'eq', 'Math::GMPq', "$op: \$q2 is a Math::GMPq object");
}

{
  my $op = '+=';
  my $s = '0.7';
  my $q = Math::GMPq->new('9/10');
  $s += $q;
  $q += '0.7';
  cmp_ok($s, '==', $q, "$op: \$s == \$q");
  cmp_ok(ref($s), 'eq', 'Math::GMPq', "$op: \$s is a Math::GMPq object");
  cmp_ok(ref($q), 'eq', 'Math::GMPq', "$op: \$q is a Math::GMPq object");
}

{
  my $op = '*=';
  my $s = '0.7';
  my $q = Math::GMPq->new('9/10');
  $s *= $q;
  $q *= '0.7';
  cmp_ok($s, '==', $q, "$op: \$s == \$q");
  cmp_ok(ref($s), 'eq', 'Math::GMPq', "$op: \$s is a Math::GMPq object");
  cmp_ok(ref($q), 'eq', 'Math::GMPq', "$op: \$q is a Math::GMPq object");
}

{
  my $op = '-=';
  my $s = '0.7';
  my $q = Math::GMPq->new('9/10');
  $s -= $q;
  $q -= '0.7';
  cmp_ok($s, '==', -$q, "$op: \$s == -\$q");
  cmp_ok(ref($s), 'eq', 'Math::GMPq', "$op: \$s is a Math::GMPq object");
  cmp_ok(ref($q), 'eq', 'Math::GMPq', "$op: \$q is a Math::GMPq object");
}

{
  my $op = '/=';
  my $s = '0.7';
  my $q = Math::GMPq->new('9/10');
  $s /= $q;
  $q /= '0.7';
  Rmpq_inv($q, $q);
  cmp_ok($s, '==', $q, "$op: \$s == inv \$q");
  cmp_ok(ref($s), 'eq', 'Math::GMPq', "$op: \$s is a Math::GMPq object");
  cmp_ok(ref($q), 'eq', 'Math::GMPq', "$op: \$q is a Math::GMPq object");
}

{
  # Providing a string (PV) as an argument to overload_pow() is not permitted.
  #
  my $s = '5';
  my $s2 = '3';
  my $q = Math::GMPq->new('2/3');

  eval{ my $t = $s ** $q;};
  like($@, qr/Raising a value to an mpq_t power is not allowed/, "**: Overloading of '**' disallows a PV argument");

  eval{ my $t = $q ** $s;};
  like($@, qr/Invalid argument supplied to Math::GMPq::overload_pow/, "** (reversed): Overloading of '**' disallows a PV argument");

  eval{ $s **= $q;};
  like($@, qr/Raising a value to an mpq_t power is not allowed/, "**=: Overloading of '**' disallows a PV argument");

  eval{ $q **= $s;};
  like($@, qr/Invalid argument supplied to Math::GMPq::overload_pow/, "**= (reversed):Overloading of '**' diallows a PV argument");

  my $q1 = $q ** ($s + 0);
  cmp_ok("$q1", 'eq', '32/243', "2/3 ** 5 == 32/243");

  $q1 **= $s2 + 0;
  cmp_ok("$q1", 'eq', '32768/14348907', "\$q1 **= 3 sets \$q1 to 32768/14348907");
}

{
  my $q = Rmpq_init();
  Rmpq_set_str($q, '4/5', 0);

  cmp_ok($q, '>', '0.6', "\$q > '0.6'");
  cmp_ok($q, '>=', '0.6', "\$q >= '0.6'");
  cmp_ok($q, '>=', '0.8', "\$q >= '0.8'");
  cmp_ok('0.8', '>=', $q, "'0.8' >= \$q");
  cmp_ok('0.9', '>', $q, "'0.9' > \$q");
  cmp_ok('0.9', '>=', $q, "'0.9' >= \$q");

  cmp_ok(($q <=> '0.6'), '>', 0, "(\$q <=> '0.6') > 0");
  cmp_ok(('0.6' <=> $q), '<', 0, "('0.6' <=> \$q) < 0");
  cmp_ok(($q <=> '0.8'), '==', 0, "(\$q <=> '0.8') == 0");
  cmp_ok(('0.8' <=> $q), '==', 0, "('0.8' <=> \$q) == 0");

  cmp_ok('0.6', '<', $q, "'0.6' < \$q");
  cmp_ok('0.6', '<=', $q, "'0.6' <= \$q");
  cmp_ok($q, '<=', '0.8', "\$q <= '0.8'");
  cmp_ok('0.8', '<=', $q, "'0.8' <= \$q");

  cmp_ok($q, '==', '0.8', "\$q == '0.8'");
  cmp_ok('0.8', '==', $q, "'0.8' == \$q");
  cmp_ok($q, '!=', '0.6', "\$q != '0.6'");
  cmp_ok('0.6', '!=', $q, "'0.6' != \$q");
}

{
  my $q = Rmpq_init();
  Rmpq_set_str($q, '-4/5', 0);

  cmp_ok($q, '<', '-0.6', "\$q < '-0.6'");
  cmp_ok($q, '<=', '-0.6', "\$q <= '-0.6'");
  cmp_ok($q, '<=', '-0.8', "\$q <= '-0.8'");
  cmp_ok('-0.8', '<=', $q, "'-0.8' <= \$q");
  cmp_ok('-0.9', '<', $q, "'-0.9' < \$q");
  cmp_ok('-0.9', '<=', $q, "'-0.9' <= \$q");

  cmp_ok(($q <=> '-0.6'), '<', 0, "(\$q <=> '-0.6') < 0");
  cmp_ok(('-0.6' <=> $q), '>', 0, "('-0.6' <=> \$q) > 0");
  cmp_ok(($q <=> '-0.8'), '==', 0, "(\$q <=> '-0.8') == 0");
  cmp_ok(('-0.8' <=> $q), '==', 0, "('-0.8' <=> \$q) == 0");

  cmp_ok('-0.6', '>', $q, "'-0.6' > \$q");
  cmp_ok('-0.6', '>=', $q, "'-0.6' >= \$q");
  cmp_ok($q, '>=', '-0.8', "\$q >= '-0.8'");
  cmp_ok('-0.8', '>=', $q, "'-0.8' >= \$q");

  cmp_ok($q, '==', '-0.8', "\$q == '-0.8'");
  cmp_ok('-0.8', '==', $q, "'-0.8' == \$q");
  cmp_ok($q, '!=', '-0.6', "\$q != '-0.6'");
  cmp_ok('-0.6', '!=', $q, "'-0.6' != \$q");
}

##################
### -VE VALUES ###
{
  my $q0 = Math::GMPq->new('-012');
  cmp_ok("$q0", 'eq', "-10", "new('-012') == -10");

  my $q1 = Math::GMPq->new('-012', 0);
  cmp_ok("$q1", 'eq', "-10", "new('-012', 0) == -10");

  my $q2 = Math::GMPq->new('-012', 8);
  cmp_ok("$q2", 'eq', "-10", "new('-012', 8) == -10");

  my $q3 = Math::GMPq->new('-012', 10);
  cmp_ok("$q3", 'eq', "-12", "new('-012', 10) == -12");

  Rmpq_set_str($q0, '-012', 0);
  cmp_ok("$q0", 'eq', "-10", 'Rmpq_set_str($q0, "-012", 0) sets $q0 to -10');

  Rmpq_set_str($q0, '-012', 8);
  cmp_ok("$q0", 'eq', "-10", 'Rmpq_set_str($q0, "-012", 8) sets $q0 to -10');

  my $q = Math::GMPq->new('-012', 10);
  cmp_ok("$q", 'eq', "-12", "new('-012', 10) == -12");
}

{
  my $q0 = Math::GMPq->new('-0x012');
  cmp_ok("$q0", 'eq', "-18", "new('-0x012') == -18");

  my $q1 = Math::GMPq->new('-0x012', 0);
  cmp_ok("$q1", 'eq', "-18", "new('-0x012', 0) == -18");

  Rmpq_set_str($q0, '-0x012', 0);
  cmp_ok("$q0", 'eq', "-18", 'Rmpq_set_str($q0, "-0x012", 0) sets $q0 to -18');
}

{
  my $q0 = Math::GMPq->new('-0x12');
  cmp_ok("$q0", 'eq', "-18", "new('-0x12') == -18");

  my $q1 = Math::GMPq->new('-0x12', 0);
  cmp_ok("$q1", 'eq', "-18", "new('-0x12', 0) == -18");

  Rmpq_set_str($q0, '-0x12', 0);
  cmp_ok("$q0", 'eq', "-18", 'Rmpq_set_str($q0, "-0x12", 0) sets $q0 to -18');
}

{
  my $q = Math::GMPq->new('-0b011');
  cmp_ok("$q", 'eq', "-3", "new('-0b011') == -3");

  my $q1 = Math::GMPq->new('-0b011', 0);
  cmp_ok("$q1", 'eq', "-3", "new('-0b011', 0) == -3");

  Rmpq_set_str($q, '-0b011', 0);
  cmp_ok("$q", 'eq', "-3", 'Rmpq_set_str($q, "-0b011", 0) sets $q to -3');
}

{
  my $q = Math::GMPq->new('-0b11');
  cmp_ok("$q", 'eq', "-3", "new('-0b11') == -3");

  my $q1 = Math::GMPq->new('-0b11', 0);
  cmp_ok("$q1", 'eq', "-3", "new('-0b011', 0) == -3");

  Rmpq_set_str($q, '-0b11', 0);
  cmp_ok("$q", 'eq', "-3", 'Rmpq_set_str($q, "-0b11", 0) sets $q to -3');
}

for my $prefix('-0x', '-0X', '-0b', '-0B', '-0') {
  my $q0 = Math::GMPq->new($prefix);
  cmp_ok("$q0", 'eq', '0', "new('$prefix') is 0");

  my $q1 = Math::GMPq->new($prefix, 0);
  cmp_ok("$q1", 'eq', '0', "new('$prefix', 0) is 0");

  Rmpq_set_str($q0, $prefix, 0);
  cmp_ok("$q0", 'eq', '0', "Rmpq_set_str(\$q0, '$prefix', 0) sets \$q0 to 0");
}

##################
##################
### +VE VALUES ###
{
  my $q0 = Math::GMPq->new('012');
  cmp_ok("$q0", 'eq', "10", "new('012') == 10");

  my $q1 = Math::GMPq->new('012', 0);
  cmp_ok("$q1", 'eq', "10", "new('012', 0) == 10");

  my $q2 = Math::GMPq->new('012', 8);
  cmp_ok("$q2", 'eq', "10", "new('012', 8) == 10");

  my $q3 = Math::GMPq->new('012', 10);
  cmp_ok("$q3", 'eq', "12", "new('012', 10) == 12");

  Rmpq_set_str($q0, '012', 0);
  cmp_ok("$q0", 'eq', "10", 'Rmpq_set_str($q0, "012", 0) sets $q0 to 10');

  Rmpq_set_str($q0, '012', 8);
  cmp_ok("$q0", 'eq', "10", 'Rmpq_set_str($q0, "012", 8) sets $q0 to 10');

  my $q = Math::GMPq->new('012', 10);
  cmp_ok("$q", 'eq', "12", "new('012', 10) == 12");
}

{
  my $q0 = Math::GMPq->new('0x012');
  cmp_ok("$q0", 'eq', "18", "new('0x012') == 18");

  my $q1 = Math::GMPq->new('0x012', 0);
  cmp_ok("$q1", 'eq', "18", "new('0x012', 0) == 18");

  Rmpq_set_str($q0, '0x012', 0);
  cmp_ok("$q0", 'eq', "18", 'Rmpq_set_str($q0, "0x012", 0) sets $q0 to 18');
}

{
  my $q0 = Math::GMPq->new('0x12');
  cmp_ok("$q0", 'eq', "18", "new('0x12') == 18");

  my $q1 = Math::GMPq->new('0x12', 0);
  cmp_ok("$q1", 'eq', "18", "new('0x12', 0) == 18");

  Rmpq_set_str($q0, '0x12', 0);
  cmp_ok("$q0", 'eq', "18", 'Rmpq_set_str($q0, "0x12", 0) sets $q0 to 18');
}

{
  my $q = Math::GMPq->new('0b011');
  cmp_ok("$q", 'eq', "3", "new('0b011') == 3");

  my $q1 = Math::GMPq->new('0b011', 0);
  cmp_ok("$q1", 'eq', "3", "new('0b011', 0) == 3");

  Rmpq_set_str($q, '0b011', 0);
  cmp_ok("$q", 'eq', "3", 'Rmpq_set_str($q, "0b011", 0) sets $q to 3');
}

{
  my $q = Math::GMPq->new('0b11');
  cmp_ok("$q", 'eq', "3", "new('0b11') == 3");

  my $q1 = Math::GMPq->new('0b11', 0);
  cmp_ok("$q1", 'eq', "3", "new('0b11', 0) == 3");

  Rmpq_set_str($q, '0b11', 0);
  cmp_ok("$q", 'eq', "3", 'Rmpq_set_str($q, "0b11", 0) sets $q to 3');
}

for my $prefix('-0x', '-0X', '-0b', '-0B', '-0') {
  my $q0 = Math::GMPq->new($prefix);
  cmp_ok("$q0", 'eq', '0', "new('$prefix') is 0");

  my $q1 = Math::GMPq->new($prefix, 0);
  cmp_ok("$q1", 'eq', '0', "new('$prefix', 0) is 0");

  Rmpq_set_str($q0, $prefix, 0);
  cmp_ok("$q0", 'eq', '0', "Rmpq_set_str(\$q0, '$prefix', 0) sets \$q0 to 0");
}

{
  my $q0 = Math::GMPq->new('-0x1.5p4');
  cmp_ok("$q0", 'eq', "-21", "new('-0x1.5p4') is -21");
  cmp_ok($q0 * -1, '==', Math::GMPq->new('0x1.5p4'), '$q0 * - 1 == 0x1.5p4');
  Rmpq_set_str($q0, '-0x1.6p4', 0);
  cmp_ok("$q0", 'eq', "-22", "new('-0x1.6p4') is -22");

  my $q1 = Math::GMPq->new('-0b100.1p-1');
  cmp_ok("$q1", 'eq', "-9/4", "new('-0b100.1p-1') is -9/4");
  cmp_ok($q1 * -1, '==', Math::GMPq->new('0b100.1p-1'), '$q1 * - 1 == 0b100.1p-1');
  Rmpq_set_str($q1, '-0b101.1p-1', 0);
  cmp_ok("$q1", 'eq', "-11/4", "new('-0b101.1p-1') is -11/4");

  my $q2 = Math::GMPq->new('-0o6100.1p-1');
  cmp_ok("$q2", 'eq', "-25089/16", "new('-0o6100.1p-1') is -25089/16");
  cmp_ok($q2 * -1, '==', Math::GMPq->new('0o6100.1p-1'), '$q2 * - 1 == 0o6100.1p-1');
  Rmpq_set_str($q2, '-0o6100.1p-2', 0);
  cmp_ok("$q2", 'eq', "-25089/32", "new('-0o6100.1p-2') is -25089/32");

  cmp_ok(Math::GMPq->new('-6100.1@-2', 8), '==', Math::GMPq->new('-25089/512'), "new('-6100.1@-2', 8) == new('-25089/512')");
}

{
  my $q1 = Math::GMPq->new('+0x1.67p+002');
  cmp_ok("$q1", 'eq', '359/64', "new('+0x1.67e+002') is 359/64");

  my $q2 = Math::GMPq->new('+0b1.010101p+002');
  cmp_ok("$q2", 'eq', '85/16', "new('+0b1.010101p+002') is 85/16");

  my $q3 = Math::GMPq->new('+0o1.234p+002');
  cmp_ok("$q3", 'eq', '167/32', "new('+0o1.234p+002') is 167/32");

  my $q4 = Math::GMPq->new('+1.67e+002');
  cmp_ok("$q4", 'eq', '167', "new('+1.67e+002') is 167");

  my $q5 = Math::GMPq->new('+167@+002');
  cmp_ok("$q5", 'eq', '16700', "new('+167@+002') is 16700");
}

{
  my $q1 = Math::GMPq->new('-0x1.67p+002');
  cmp_ok("$q1", 'eq', '-359/64', "new('-0x1.67e+002') is -359/64");

  my $q2 = Math::GMPq->new('-0b1.010101p+002');
  cmp_ok("$q2", 'eq', '-85/16', "new('-0b1.010101p+002') is -85/16");

  my $q3 = Math::GMPq->new('-0o1.234p+002');
  cmp_ok("$q3", 'eq', '-167/32', "new('-0o1.234p+002') is -167/32");

  my $q4 = Math::GMPq->new('-1.67e+002');
  cmp_ok("$q4", 'eq', '-167', "new('-1.67e+002') is -167");

  my $q5 = Math::GMPq->new('-167@+002');
  cmp_ok("$q5", 'eq', '-16700', "new('-167@+002') is -16700");
}

{
  cmp_ok(Math::GMPq->new('1.672@3'), '==', Math::GMPq->new('1672'), "new('1.672@3') == new('1672')");

  eval {my $q = Math::GMPq->new('0x1.672@3');};
  like($@, qr/String supplied to Rmpq_set_str function \(1672\@3\)/, "new('0x1.672@3') throws expected error");

  eval { my $q = Math::GMPq->new('0x1.672/3');};
  like($@, qr/String supplied to Rmpq_set_str function \(0x1.672\/3\)/, "new('0x1.672/3') throws expected error");

  cmp_ok(Math::GMPq->new('1.672@3', 16), '==', Math::GMPq->new('1672', 16), 'new("1.672@3", 16) == new("1672", 16)');

  my $ok = 0;
  eval { my $q0 = Math::GMPq->new(0.5) * '01.2p-1';};
  $ok = 1 if $@;

  my $q1 = Math::GMPq->new(0.5) * '0o1.2p-1';
  cmp_ok("$q1", 'eq', '5/16', '0o prefix interpetted correctly');

  my $q2 = Math::GMPq->new(0.5) * '0O1.2p-1';
  cmp_ok($q1, '==', $q2, '0O prefix interpetted correctly');

  my $q3 = Math::GMPq->new('+17/+68');
  cmp_ok("$q3", 'eq', '1/4', "new('+17/+68') is '1/4'");

  my $q4 = Math::GMPq->new('+17/-68');
  cmp_ok("$q4", 'eq', '-1/4', "new('+17/-68') is '-1/4'");

  my $q5 = Math::GMPq->new('-17/+68');
  cmp_ok("$q5", 'eq', '-1/4', "new('-17/+68') is '-1/4'");

  my $q6 = Math::GMPq->new('-17/-68');
  cmp_ok("$q6", 'eq', '1/4', "new('-17/-68') is '1/4'");
}

##################
done_testing();
