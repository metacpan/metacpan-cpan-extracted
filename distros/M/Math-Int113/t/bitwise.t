use strict;
use warnings;
use Math::Int113;
use Config;

use Test::More;
my($obj1, $obj2);

if(Math::Int113::IVSIZE_IS_8) {
  $obj1 = Math::Int113->new(~0) * 54321;
  $obj2 = Math::Int113->new(~0) * 12345;
}
else {
  $obj1 = Math::Int113->new(18446744073709551615) * 54321;
  $obj2 = Math::Int113->new(18446744073709551615) * 12345;
}

cmp_ok($obj1, '==', 1002045584827976553278415, "1st object assigned correctly");
cmp_ok($obj2, '==', 227725055589944414687175,  "2nd object assigned correctly");

cmp_ok($obj1 >> 5, '==', 31313924525874267289950, "1st >> 5 == 31313924525874267289950");
cmp_ok($obj2 >> 5, '==', 7116407987185762958974,  "2nd >> 5 == 7116407987185762958974");

cmp_ok($obj1 >> 64, '==', 54320, "1st >> 64 == 54320");
cmp_ok($obj2 >> 64, '==', 12344, "2nd >> 64 == 12344");

cmp_ok($obj1 << 11, '==', 2052189357727695981114193920, "1st << 11 == 2052189357727695981114193920");
cmp_ok($obj2 << 11, '==', 466380913848206161279334400,  "2nd << 11 == 466380913848206161279334400");

cmp_ok($obj1 & $obj2, '==', 76461754185526091385799, "1st & 2nd evaluates correctly");
cmp_ok($obj1 | $obj2, '==', 1153308886232394876579791, "1st | 2nd evaluates correctly");
cmp_ok($obj1 ^ $obj2, '==', 1076847132046868785193992, "1st ^ 2nd evaluates correctly");

my $not_obj1 = ~$obj1;
my $not_obj2 = ~$obj2;

cmp_ok($not_obj1, '==', 10384593716067609672233016105161776, "~1st evaluates correctly");
cmp_ok($not_obj2, '==', 10384593716841930201471048243753016, "~2nd evaluates correctly");

cmp_ok(~$not_obj1, '==', $obj1, "~(~1st) evaluates correctly");
cmp_ok(~$not_obj2, '==', $obj2, "~(~2nd) evaluates correctly");

my $not_zero = ~(Math::Int113->new(0));
cmp_ok($not_zero, '==', Math::Int113->new(10384593717069655257060992658440191), '~(Math::Int113->new(0)) evaluates to 10384593717069655257060992658440191');
cmp_ok($not_zero, '==', (2 ** 113) - 1, '~(Math::Int113->new(0)) evaluates to (2**113)-1');

$not_zero++;
cmp_ok($not_zero, '==', 2 ** 113, '~(Math::Int113->new(0)) increments to 2**113');

$not_zero--;
cmp_ok($not_zero, '==', ~(Math::Int113->new(0)), 'Math::Int113->new(2**113) decrements to ~(Math::Int113->new(0))');

my $other = Math::Int113->new('12345678909876543212345');
my $not_other = ~$other;
cmp_ok($not_zero - $not_other, '==', $other, '~0 - ~$x == $x');
cmp_ok(~(Math::Int113->new(64)) - ~(Math::Int113->new(125)), '==', 61, '~64 - ~125 == 61');

# Test bit-logic operations on -ve values.

my $lim = ~0 >> 1;

for(1..100) {
  my $p = int(rand(~0));
  my $n = int(rand($lim));
  $n *= -1;
  my $pint113 = Math::Int113->new($p);
  my $nint113 = Math::Int113->new($n);
  cmp_ok(~$nint113, '==', ~$n, "~($nint113) correctly calculated");

  my $nint113_alt = ~(-$nint113) + 1;

  my $expected = $p & $n;
  cmp_ok($pint113 & $n, '==', $expected, "1: $p & $n correctly calculated");
  cmp_ok($pint113 & $nint113, '==', $expected, "2: $p & $n correctly calculated");
  cmp_ok($pint113 & $nint113_alt, '==', $expected, "3: $p & $n correctly calculated");

  $expected = $p ^ $nint113;
  cmp_ok($pint113 ^ $n, '==', $expected, "1: $p ^ $n correctly calculated");
  cmp_ok($pint113 ^ $nint113, '==', $expected, "2: $p ^ $n correctly calculated");
  cmp_ok($pint113 ^ $nint113_alt, '==', $expected, "3: $p ^ $n correctly calculated");

  $expected = $p | $nint113;
  cmp_ok($pint113 | $n, '==', $expected, "1: $p | $n correctly calculated");
  cmp_ok($pint113 | $nint113, '==', $expected, "2: $p | $n correctly calculated");
  cmp_ok($pint113 | $nint113_alt, '==', $expected, "3: $p | $n correctly calculated");

}

for(1 .. 10) {
  my $v = int(rand(~0));
  my $pobj = Math::Int113->new($v);
  my $nobj = Math::Int113->new(-$v);
  my $nobj_alt = ~(-$nobj) + 1;
  my $pshift = 1 + int(rand(8));
  my $nshift = -$pshift;

  cmp_ok($pobj >> $nshift, '==', $pobj << $pshift, "$pobj >> $nshift == << $pshift");
  cmp_ok($pobj << $nshift, '==', $pobj >> $pshift, "$pobj << $nshift == >> $pshift");
  cmp_ok($nobj << $nshift, '==', $nobj_alt << $nshift, "$nobj << $nshift == ~-$nobj+1 << $nshift");
  cmp_ok($nobj >> $nshift, '==', $nobj_alt >> $nshift, "$nobj >> $nshift == ~-$nobj+1 >> $nshift");
  cmp_ok($nobj << $pshift, '==', $nobj_alt << $pshift, "$nobj << $pshift == ~-$nobj+1 << $pshift");
  cmp_ok($nobj >> $pshift, '==', $nobj_alt >> $pshift, "$nobj >> $pshift == ~-$nobj+1 >> $pshift");
}

for(1 .. 10) {
  my $v = int(rand(~0));
  my $pobj = Math::Int113->new($v);
  my $nobj = Math::Int113->new(-$v);
  my $nobj_alt = ~(-$nobj) + 1;
  my $pshift = 1 + int(rand(8));
  my $nshift = -$pshift;

  cmp_ok($pobj >> $nshift, '==', $pobj << $pshift, "$pobj >> $nshift == << $pshift");
  cmp_ok($pobj << $nshift, '==', $pobj >> $pshift, "$pobj << $nshift == >> $pshift");
  cmp_ok($nobj << $nshift, '==', $nobj_alt << $nshift, "$nobj << $nshift == ~-$nobj+1 << $nshift");
  cmp_ok($nobj >> $nshift, '==', $nobj_alt >> $nshift, "$nobj >> $nshift == ~-$nobj+1 >> $nshift");
  cmp_ok($nobj << $pshift, '==', $nobj_alt << $pshift, "$nobj << $pshift == ~-$nobj+1 << $pshift");
  cmp_ok($nobj >> $pshift, '==', $nobj_alt >> $pshift, "$nobj >> $pshift == ~-$nobj+1 >> $pshift");
}

for(1 .. 10) {
  my $v = 1.0384593717069655257060992658440191e34 - int(rand(~0));
  my $pobj = Math::Int113->new($v);

  # 10384593717069655257060992658439167 is 10384593717069655257060992658440191 ^ (1 << 10)
  # IOW, 10384593717069655257060992658439167 is 10384593717069655257060992658440191 with
  # its 10 least significant bits set to 0.
  $pobj ^= 10384593717069655257060992658439167;

  my $nobj = -$pobj;
  my $nobj_alt = ~(-$nobj) + 1;

  my $pshift = 1 + int(rand(8));
  my $nshift = -$pshift;

  cmp_ok($pobj >> $nshift, '==', $pobj << $pshift, "$pobj >> $nshift == $pobj << $pshift");
  cmp_ok($pobj << $nshift, '==', $pobj >> $pshift, "$pobj << $nshift == $pobj >> $pshift");
  cmp_ok($nobj << $nshift, '==', $nobj_alt << $nshift, "$nobj << $nshift == ~-$nobj+1 << $nshift");
  cmp_ok($nobj >> $nshift, '==', $nobj_alt >> $nshift, "$nobj >> $nshift == ~-$nobj+1 >> $nshift");
  cmp_ok($nobj << $pshift, '==', $nobj_alt << $pshift, "$nobj << $pshift == ~-$nobj+1 << $pshift");
  cmp_ok($nobj >> $pshift, '==', $nobj_alt >> $pshift, "$nobj >> $pshift == ~-$nobj+1 >> $pshift");
}

my $shift = Math::Int113->new(5);
my $iv = 123456789;
cmp_ok($iv << $shift, '==', $iv << 5, "123456789 << 5 == 3950617248");
cmp_ok($iv >> -$shift, '==', $iv >> -5, "123456789 >> -5 == 3950617248");

cmp_ok($iv >> $shift, '==', $iv >> 5, "123456789 >> 5 == 3858024");
cmp_ok($iv << -$shift, '==', $iv << -5, "123456789 << -5 == 3858024");

for(1..100) {
  my $uv = $Math::Int113::MAX_OBJ ^ ((2 ** 110) - 1);
  my $inc = int(rand(100));
  $uv += $inc;
  my $shift = 3 + int(rand(20));
  cmp_ok($uv << $shift, '==', $inc << $shift, "\$uv << \$shift == \$inc << \$shift");
}



done_testing();
