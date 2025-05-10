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

done_testing();
