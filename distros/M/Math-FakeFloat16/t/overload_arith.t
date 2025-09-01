use strict;
use warnings;
use Math::FakeFloat16 qw(:all);

use Test::More;

my($have_gmpf, $have_gmpq) = (0, 0);

eval { require Math::GMPf };
$have_gmpf = 1 unless $@;

eval { require Math::GMPq };
$have_gmpq = 1 unless $@;

my $mpfr = Math::MPFR->new(3.875);

my @inputs = ('1.5', '-1.75', 2.625, Math::FakeFloat16->new($mpfr), 42);

if($have_gmpf) {
  my $f = Math::GMPf->new(5.25);
  push (@inputs, Math::FakeFloat16->new($f));
}
if($have_gmpq) {
  my $q = Math::GMPq->new('3/4');
  push(@inputs, Math::FakeFloat16->new($q));
}

my $nan = Math::FakeFloat16->new();

for my $v (@inputs) {
  my $add = $nan + $v;
  cmp_ok(is_f16_nan($add), '==', 1, "NaN + $v is NaN");

  my $mul = $nan * $v;
  cmp_ok(is_f16_nan($mul), '==', 1, "NaN * $v is NaN");

  my $sub = $nan - $v;
  cmp_ok(is_f16_nan($sub), '==', 1, "NaN - $v is NaN");

  my $div = $nan / $v;
  cmp_ok(is_f16_nan($div), '==', 1, "NaN / $v is NaN");
}

for my $v (@inputs) {
  my $add = $v + $nan;
  cmp_ok(is_f16_nan($add), '==', 1, "$v + NaN is NaN");

  my $mul = $v * $nan;
  cmp_ok(is_f16_nan($mul), '==', 1, "$v * NaN  is NaN");

  my $sub = $v - $nan;
  cmp_ok(is_f16_nan($sub), '==', 1, "$v - NaN is NaN");

  my $div = $v / $nan;
  cmp_ok(is_f16_nan($div), '==', 1, "$v / NaN is NaN");
}

my $index = scalar(@inputs);
my @r = ();

for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $r = Math::FakeFloat16->new($inputs[$i]) + $inputs[$j];
     my $s = $inputs[$i] + Math::FakeFloat16->new($inputs[$j]);
     cmp_ok($r, '==', $s, "\$r == $s");
     push @r, $r;
  }
}

my $count = 0;
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $x = $inputs[$i];
     my $y = $inputs[$j];
     my $obj_x = Math::FakeFloat16->new($x);
     my $obj_y = Math::FakeFloat16->new($y);
     $obj_x += $y;
     $obj_y += $x;
     cmp_ok($obj_x, '==', $obj_y, "\$obj_x == $obj_y");
     cmp_ok($obj_x, '==', $r[$count], "cross_check ok for $x $y [$count]");
     $count++;
  }
}

################################################

@r = ();
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $r = Math::FakeFloat16->new($inputs[$i]) * $inputs[$j];
     my $s = $inputs[$i] * Math::FakeFloat16->new($inputs[$j]);
     cmp_ok($r, '==', $s, "\$r == $s");
     push @r, $r;
  }
}

$count = 0;
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $x = $inputs[$i];
     my $y = $inputs[$j];
     my $obj_x = Math::FakeFloat16->new($x);
     my $obj_y = Math::FakeFloat16->new($y);
     $obj_x *= $y;
     $obj_y *= $x;
     cmp_ok($obj_x, '==', $obj_y, "\$obj_x == $obj_y");
     cmp_ok($obj_x, '==', $r[$count], "cross_check ok for $x $y [$count]");
     $count++;
  }
}

################################################
################################################

@r = ();
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $r = Math::FakeFloat16->new($inputs[$i]) - $inputs[$j];
     my $s = $inputs[$i] - Math::FakeFloat16->new($inputs[$j]);
     my $u = Math::FakeFloat16->new($inputs[$j]) - $inputs[$i];
     my $v = $inputs[$j] - Math::FakeFloat16->new($inputs[$i]);
     cmp_ok($r, '==', $s, "\$r == $s");
     cmp_ok($u, '==', $v, "\$u == $v");
     cmp_ok(-$u, '==', $r, "-\$u == $r");
     cmp_ok(-$v, '==', $s, "-\$v == $s");
     push @r, $r;
  }
}

$count = 0;
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $x = $inputs[$i];
     my $y = $inputs[$j];
     my $obj_x = Math::FakeFloat16->new($x);
     my $obj_y = Math::FakeFloat16->new($y);
     $obj_x -= $y;
     $obj_y -= $x;
     cmp_ok($obj_x, '==', -$obj_y, "\$obj_x == -$obj_y");
     cmp_ok($obj_x, '==', $r[$count], "cross_check ok for $x $y [$count]");
     $count++;
  }
}

my $fmod1 = Math::FakeFloat16->new('2.6');
my $fmod2 = Math::FakeFloat16->new('1.2');

cmp_ok($fmod1 % $fmod2, '==', '1.9922e-1', "2.6 % 1.2 == 1.9922e-1");
cmp_ok(-$fmod1 % $fmod2, '==', '-1.9922e-1', "-2.6 % 1.2 == -1.9922e-1");
cmp_ok($fmod1 % -$fmod2, '==', '1.9922e-1', "2.6 % -1.2 == 1.9922e-1");
cmp_ok(-$fmod1 % -$fmod2, '==', '-1.9922e-1', "-2.6 % -1.2 == -1.9922e-1");

cmp_ok($fmod2 % $fmod1, '==', '1.2002', "1.2 % 1.6 == 1.2002");
cmp_ok(-$fmod2 % $fmod1, '==', '-1.2002', "-1.2 % 1.6 == -1.2002");
cmp_ok($fmod2 % -$fmod1, '==', '1.2002', "1.2 % -1.6 == 1.2002");
cmp_ok(-$fmod2 % -$fmod1, '==', '-1.2002', "-1.2 % -1.6 == -1.2002");

$fmod2 %= $fmod1;
cmp_ok($fmod2, '==', '1.2002', "value doesn't change under %= operation");

$fmod1 %= $fmod2;
cmp_ok($fmod1, '==', '1.9922e-1', "value changes to 1.9922e-1 under %= operation");

################################################
################################################


for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $r = Math::FakeFloat16->new($inputs[$i]) / $inputs[$j];
     my $s = $inputs[$i] / Math::FakeFloat16->new($inputs[$j]);
     my $u = Math::FakeFloat16->new($inputs[$j]) / $inputs[$i];
     my $v = $inputs[$j] / Math::FakeFloat16->new($inputs[$i]);
     cmp_ok($r, '==', $s, "\$r == $s");
     cmp_ok($u, '==', $v, "\$u == $v");
     cmp_ok($r * $u, '>=', -0.99, "\$r * $u >= -0.99");
     cmp_ok($v * $s, '<=', 1.01, "$v * \$s <= 1.01");
  }
}

$count = 0;
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $x = $inputs[$i];
     my $y = $inputs[$j];
     my $obj_x = Math::FakeFloat16->new($x);
     my $obj_y = Math::FakeFloat16->new($y);
     $obj_x /= $y;
     $obj_y /= $x;
     cmp_ok($obj_x * $obj_y, '>=', -0.99, "\$obj_x * $obj_y >= -0.99");
     cmp_ok($obj_x * $obj_y, '<=',  1.01, "$obj_x * \$obj_y <= 1.01");
     $count++;
  }
}

################################################

my $root = sqrt(Math::FakeFloat16->new(2));
cmp_ok($root, '==', Math::FakeFloat16->new('1.414'), "sqrt(2) == 1.414 (MPFR)");
cmp_ok($root, '==', '1.414', "sqrt(2) == '1.414'");
cmp_ok($root, '==', Math::FakeFloat16->new(2) ** 0.5, "sqrt(2) == 2 ** 0.5");
cmp_ok($root, '==', 2 ** Math::FakeFloat16->new(0.5), "sqrt(2) == 2 ** 0.5");

my $log = log(Math::FakeFloat16->new(10));
cmp_ok($log, '==', Math::FakeFloat16->new('2.3027'), "log(10) == 2.297 (MPFR)");
cmp_ok($log, '==', '2.3027', "log(10) == '2.3027'");

my $exp = exp(Math::FakeFloat16->new('2.3027'));
cmp_ok($exp, '==', Math::FakeFloat16->new('10'), "exp('2.3027') == 10 (MPFR)");
cmp_ok($exp, '==', '10', "exp('2.3027') == '10'");

my $int = int(Math::FakeFloat16->new(21.9));
cmp_ok($int, '==', 21, "int(21.9) == 21");

################
# overload abs #
################

my $neg = Math::FakeFloat16->new(-10);
my $abs = abs($neg);
cmp_ok(ref($abs), 'eq', 'Math::FakeFloat16', "abs: ref ok");
cmp_ok($abs, '==', -$neg, "\$abs == 10");

my $pos = Math::FakeFloat16->new(100);
$abs = abs($pos);
cmp_ok(ref($abs), 'eq', 'Math::FakeFloat16', "abs: ref ok");
cmp_ok($abs, '==', $pos, "\$abs == 100");

#################
# overload bool #
#################

my $ok = 0;
$ok = 1 if !Math::FakeFloat16->new(0);  # $ok should change to 1.
cmp_ok($ok, '==', 1, "Math::FakeFloat16->new(0) is false");

$ok = 0;
$ok = 1 if !Math::FakeFloat16->new();  # $ok should change to 1.
cmp_ok($ok, '==', 1, "Math::FakeFloat16->new() is false");

$ok = 0;
$ok = 1 if !Math::FakeFloat16->new(1);  # $ok should remain at 0.
cmp_ok($ok, '==', 0, "Math::FakeFloat16->new(1) is true");

##############
# overload ! #
##############

$ok = 0;
$ok = !Math::FakeFloat16->new(0);  # $ok should change to 1.
cmp_ok($ok, '==', 1, "!Math::FakeFloat16->new(0) is true");

$ok = 0;
$ok = !Math::FakeFloat16->new();  # $ok should change to 1.
cmp_ok($ok, '==', 1, "!Math::FakeFloat16->new() is true");

$ok = 1;
$ok = !Math::FakeFloat16->new(1);  # $ok should change to 0.
cmp_ok($ok, '==', 0, "!Math::FakeFloat16->new(1) is false");

my $interp0 = Math::FakeFloat16->new();
cmp_ok("$interp0", 'eq', 'NaN', "interpolates to 'NaN'");
my $stringified = sprintf("%s", $interp0);
cmp_ok("$stringified", 'eq', 'NaN', "sprintf returns 'NaN'");

my $interp1 = sqrt(Math::FakeFloat16->new(2));
cmp_ok("$interp1", 'eq', '1.4141', "interpolates to '1.4141'");
$stringified = sprintf("%s", $interp1);
cmp_ok("$stringified", 'eq', '1.4141', "sprintf returns '1.4141'");

my $f16_obj = Math::FakeFloat16->new('1025.123');
my $interp = "$f16_obj"; # 1.025e3
my $testing = f16_to_MPFR($f16_obj);
cmp_ok($interp, 'eq', "$testing", "interpolation examines object returned by f16_to_MPFR()");

f16_set($f16_obj, '1.175e-38');
my $denorm_min = Math::FakeFloat16->new(2) ** -133;

cmp_ok($f16_obj - $denorm_min, '==', '1.166e-38', 'normal_min - denorm_min == denorm_max');
cmp_ok($denorm_min + '1.166e-38', '==', $f16_obj, "denorm_min + denorm_max == normal_min");

###############
# Error Tests #
###############

eval{ my $x = Math::FakeFloat16->new(1) + Math::MPFR->new(25);};
like($@, qr/^Unrecognized 2nd argument passed/, "+ Math::MPFR object: \$\@ set as expected");

eval{ my $x = Math::FakeFloat16->new() - Math::MPFR->new(25);};
like($@, qr/^Unrecognized 2nd argument passed/, "- Math::MPFR object: \$\@ set as expected");

eval{ my $x = Math::FakeFloat16->new() * Math::MPFR->new(25);};
like($@, qr/^Unrecognized 2nd argument passed/, "* Math::MPFR object: \$\@ set as expected");

eval{ my $x = Math::FakeFloat16->new() / Math::MPFR->new(25);};
like($@, qr/^Unrecognized 2nd argument passed/, "/ Math::MPFR object: \$\@ set as expected");

if($have_gmpf) {
  eval{ my $x = Math::FakeFloat16->new() + Math::GMPf->new(25);};
  like($@, qr/^Unrecognized 2nd argument passed/, "+ Math::GMPf object: \$\@ set as expected");

  eval{ my $x = Math::FakeFloat16->new(1) - Math::GMPf->new(25);};
  like($@, qr/^Unrecognized 2nd argument passed/, "- Math::GMPf object: \$\@ set as expected");

  eval{ my $x = Math::FakeFloat16->new() * Math::GMPf->new(25);};
  like($@, qr/^Unrecognized 2nd argument passed/, "* Math::GMPf object: \$\@ set as expected");

  eval{ my $x = Math::FakeFloat16->new() / Math::GMPf->new(25);};
  like($@, qr/^Unrecognized 2nd argument passed/, "/ Math::GMPf object: \$\@ set as expected");
}

if($have_gmpq) {
  eval{ my $x = Math::FakeFloat16->new() + Math::GMPq->new(25);};
  like($@, qr/^Unrecognized 2nd argument passed/, "+ Math::GMPq object: \$\@ set as expected");

  eval{ my $x = Math::FakeFloat16->new() - Math::GMPq->new(25);};
  like($@, qr/^Unrecognized 2nd argument passed/, "- Math::GMPq object: \$\@ set as expected");

  eval{ my $x = Math::FakeFloat16->new(1) * Math::GMPq->new(25);};
  like($@, qr/^Unrecognized 2nd argument passed/, "* Math::GMPq object: \$\@ set as expected");

  eval{ my $x = Math::FakeFloat16->new() / Math::GMPq->new(25);};
  like($@, qr/^Unrecognized 2nd argument passed/, "/ Math::GMPq object: \$\@ set as expected");
}

done_testing();

__END__
