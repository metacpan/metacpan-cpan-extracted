use strict;
use warnings;
use Math::Float32 qw(:all);

use Test::More;


my @inputs = ('1.5', '-1.75', 2.625, 42);

my $nan = Math::Float32->new();

for my $v (@inputs) {
  my $add = $nan + $v;
  cmp_ok(is_flt_nan($add), '==', 1, "NaN + $v is NaN");

  my $mul = $nan * $v;
  cmp_ok(is_flt_nan($mul), '==', 1, "NaN * $v is NaN");

  my $sub = $nan - $v;
  cmp_ok(is_flt_nan($sub), '==', 1, "NaN - $v is NaN");

  my $div = $nan / $v;
  cmp_ok(is_flt_nan($div), '==', 1, "NaN / $v is NaN");
}

for my $v (@inputs) {
  my $add = $v + $nan;
  cmp_ok(is_flt_nan($add), '==', 1, "$v + NaN is NaN");

  my $mul = $v * $nan;
  cmp_ok(is_flt_nan($mul), '==', 1, "$v * NaN  is NaN");

  my $sub = $v - $nan;
  cmp_ok(is_flt_nan($sub), '==', 1, "$v - NaN is NaN");

  my $div = $v / $nan;
  cmp_ok(is_flt_nan($div), '==', 1, "$v / NaN is NaN");
}

my $index = scalar(@inputs);
my @r = ();

for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $r = Math::Float32->new($inputs[$i]) + $inputs[$j];
     my $s = $inputs[$i] + Math::Float32->new($inputs[$j]);
     cmp_ok($r, '==', $s, "\$r == $s");
     push @r, $r;
  }
}

my $count = 0;
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $x = $inputs[$i];
     my $y = $inputs[$j];
     my $obj_x = Math::Float32->new($x);
     my $obj_y = Math::Float32->new($y);
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
     my $r = Math::Float32->new($inputs[$i]) * $inputs[$j];
     my $s = $inputs[$i] * Math::Float32->new($inputs[$j]);
     cmp_ok($r, '==', $s, "\$r == $s");
     push @r, $r;
  }
}

$count = 0;
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $x = $inputs[$i];
     my $y = $inputs[$j];
     my $obj_x = Math::Float32->new($x);
     my $obj_y = Math::Float32->new($y);
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
     my $r = Math::Float32->new($inputs[$i]) - $inputs[$j];
     my $s = $inputs[$i] - Math::Float32->new($inputs[$j]);
     my $u = Math::Float32->new($inputs[$j]) - $inputs[$i];
     my $v = $inputs[$j] - Math::Float32->new($inputs[$i]);
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
     my $obj_x = Math::Float32->new($x);
     my $obj_y = Math::Float32->new($y);
     $obj_x -= $y;
     $obj_y -= $x;
     cmp_ok($obj_x, '==', -$obj_y, "\$obj_x == -$obj_y");
     cmp_ok($obj_x, '==', $r[$count], "cross_check ok for $x $y [$count]");
     $count++;
  }
}

################################################
################################################


for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $r = Math::Float32->new($inputs[$i]) / $inputs[$j];
     my $s = $inputs[$i] / Math::Float32->new($inputs[$j]);
     my $u = Math::Float32->new($inputs[$j]) / $inputs[$i];
     my $v = $inputs[$j] / Math::Float32->new($inputs[$i]);
     cmp_ok($r, '==', $s, "\$r == $s");
     cmp_ok($u, '==', $v, "\$u == $v");
     cmp_ok($r * $u, '>=', -0.99, "\$r * $u >= -0.99");
     cmp_ok($v * $s, '<=', 1.01, "$v * \$s <= 1.01");
  }
}

my $fmod1 = Math::Float32->new('2.6');
my $fmod2 = Math::Float32->new('1.2');

cmp_ok($fmod1 % $fmod2, '==', '1.99999809e-1', "2.6 % 1.2 == 1.99999809e-1");
cmp_ok(-$fmod1 % $fmod2, '==', '-1.99999809e-1', "-2.6 % 1.2 == -1.99999809e-1");
cmp_ok($fmod1 % -$fmod2, '==', '1.99999809e-1', "2.6 % -1.2 == 1.99999809e-1");
cmp_ok(-$fmod1 % -$fmod2, '==', '-1.99999809e-1', "-2.6 % -1.2 == -1.99999809e-1");

cmp_ok($fmod2 % $fmod1, '==', '1.20000005', "1.2 % 1.6 == 1.20000005");
cmp_ok(-$fmod2 % $fmod1, '==', '-1.20000005', "-1.2 % 1.6 == -1.20000005");
cmp_ok($fmod2 % -$fmod1, '==', '1.20000005', "1.2 % -1.6 == 1.20000005");
cmp_ok(-$fmod2 % -$fmod1, '==', '-1.20000005', "-1.2 % -1.6 == -1.20000005");

$fmod2 %= $fmod1;
cmp_ok($fmod2, '==', '1.20000005', "value doesn't change under %= operation");

$fmod1 %= $fmod2;
cmp_ok($fmod1, '==', '1.99999809e-1', "value changes to 1.99999809e-1 under %= operation");

$count = 0;
for (my $i = 0; $i < $index; $i++) {
  for (my $j = 0; $j < $index; $j++) {
     my $x = $inputs[$i];
     my $y = $inputs[$j];
     my $obj_x = Math::Float32->new($x);
     my $obj_y = Math::Float32->new($y);
     $obj_x /= $y;
     $obj_y /= $x;
     cmp_ok($obj_x * $obj_y, '>=', -0.99, "\$obj_x * $obj_y >= -0.99");
     cmp_ok($obj_x * $obj_y, '<=',  1.01, "$obj_x * \$obj_y <= 1.01");
     $count++;
  }
}

################################################

my $root = sqrt(Math::Float32->new(2));
cmp_ok($root, '==', Math::Float32->new('1.41421354'), "sqrt(2) == 1.41421354");
cmp_ok($root, '==', '1.41421354', "sqrt(2) == '1.41421354'");
cmp_ok($root, '==', Math::Float32->new(2) ** 0.5, "sqrt(2) == 2 ** 0.5");
cmp_ok($root, '==', 2 ** Math::Float32->new(0.5), "sqrt(2) == 2 ** 0.5");

cmp_ok(flt_signbit($root), '==', 0, "signbit of $root is unset");
cmp_ok(flt_signbit(-$root), '==', 1, "signbit of -$root is set");

my $log = log(Math::Float32->new(10));
cmp_ok($log, '==', Math::Float32->new('2.30258512'), "log(10) == 2.30258512");
cmp_ok($log, '==', '2.30258512', "log(10) == '2.30258512'");

cmp_ok(flt_signbit($log), '==', 0, "signbit of $log is unset");
cmp_ok(flt_signbit($log * -1), '==', 1, "signbit of -$log is set");

my $exp = exp(Math::Float32->new('2.30258512'));
cmp_ok($exp, '==', Math::Float32->new('10'), "exp('2.30258512') == 10");
cmp_ok($exp, '==', '10', "exp('2.30258512') == '10'");

cmp_ok(flt_signbit($exp), '==', 0, "signbit of $exp is unset");
cmp_ok(flt_signbit($exp - 15), '==', 1, "signbit of $exp - 15 is set");

my $int = int(Math::Float32->new(21.9));
cmp_ok($int, '==', 21, "int(21.9) == 21");

cmp_ok(flt_signbit($int), '==', 0, "signbit of $int is unset");
cmp_ok(flt_signbit($int / -3), '==', 1, "signbit of $int / -3 is set");

################
# overload abs #
################

my $neg = Math::Float32->new(-10);
my $abs = abs($neg);
cmp_ok(ref($abs), 'eq', 'Math::Float32', "abs: ref ok");
cmp_ok($abs, '==', -$neg, "\$abs == 10");

my $pos = Math::Float32->new(100);
$abs = abs($pos);
cmp_ok(ref($abs), 'eq', 'Math::Float32', "abs: ref ok");
cmp_ok($abs, '==', $pos, "\$abs == 100");

#################
# overload bool #
#################

my $ok = 0;
$ok = 1 if !Math::Float32->new(0);  # $ok should change to 1.
cmp_ok($ok, '==', 1, "Math::Float32->new(0) is false");

$ok = 0;
$ok = 1 if !Math::Float32->new();  # $ok should change to 1.
cmp_ok($ok, '==', 1, "Math::Float32->new() is false");

$ok = 0;
$ok = 1 if !Math::Float32->new(1);  # $ok should remain at 0.
cmp_ok($ok, '==', 0, "Math::Float32->new(1) is true");

##############
# overload ! #
##############

$ok = 0;
$ok = !Math::Float32->new(0);  # $ok should change to 1.
cmp_ok($ok, '==', 1, "!Math::Float32->new(0) is true");

$ok = 0;
$ok = !Math::Float32->new();  # $ok should change to 1.
cmp_ok($ok, '==', 1, "!Math::Float32->new() is true");

$ok = 1;
$ok = !Math::Float32->new(1);  # $ok should change to 0.
cmp_ok($ok, '==', 0, "!Math::Float32->new(1) is false");

my $interp0 = Math::Float32->new();
cmp_ok("$interp0", 'eq', 'NaN', "interpolates to 'NaN'");
my $stringified = sprintf("%s", $interp0);
cmp_ok("$stringified", 'eq', 'NaN', "sprintf returns 'NaN'");

my $interp1 = sqrt(Math::Float32->new(2));
cmp_ok("$interp1", 'eq', '1.41421354', "interpolates to '1.41421354'");
$stringified = sprintf("%s", $interp1);
cmp_ok("$stringified", 'eq', '1.41421354', "sprintf returns '1.41421354'");


my $flt_obj = Math::Float32->new('1025.123');

flt_set($flt_obj, '1.175e-38');
my $denorm_min = Math::Float32->new(2) ** -133;

cmp_ok($flt_obj - $denorm_min, '==', '1.16581642e-38', 'normal_min - denorm_min == denorm_max');
cmp_ok($denorm_min + '1.16581642e-38', '==', $flt_obj, "denorm_min + denorm_max == normal_min");

done_testing();

__END__
