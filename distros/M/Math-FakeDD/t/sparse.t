# Tests using values that have long runs of (implied)
# zeros or ones in their middle sections.

use strict;
use warnings;
use Math::FakeDD qw(:all);
use Test::More;

if($ENV{SKIP_REPRO_TESTS}) {
  is(1, 1);
  warn "\n skipping all tests as \$ENV{SKIP_REPRO_TESTS} is set\n";
  done_testing();
  exit 0;
}

*dd_mul_4196 = \&Math::FakeDD::dd_mul_4196;
*dd_add_4196 = \&Math::FakeDD::dd_add_4196;
*dd_div_4196 = \&Math::FakeDD::dd_div_4196;
*dd_sub_4196 = \&Math::FakeDD::dd_sub_4196;

my @p = (50, 100, 150, 200, 250, 300, 350, 400, 450, 500,
         550, 600, 650, 700, 750, 800, 850, 900, 950, 1000);

my(@big, @little);

for(0..19) {
  push(@big, 2 ** $p[$_]);
  push(@little, 2 ** -($p[$_]));
}

for(0..19) {
  my $xb = int(rand(20));
  my $xl = int(rand(20));
  my $yb = int(rand(20));
  my $yl = int(rand(20));
  my $ub = int(rand(20));
  my $ul = int(rand(20));
  my $vb = int(rand(20));
  my $vl = int(rand(20));

  my $x = Math::FakeDD->new( $big[$xb] ) + Math::FakeDD->new( $little[$xl] );
  my $y = Math::FakeDD->new( $big[$yb] ) + Math::FakeDD->new( $little[$yl] );

  my $u = Math::FakeDD->new( $big[$ub] ) - Math::FakeDD->new( $little[$ul] );
  my $v = Math::FakeDD->new( $big[$vb] ) - Math::FakeDD->new( $little[$vl] );

sparse_test($x, $y);
sparse_test($u, $v);
sparse_test($x, $v);
sparse_test($u, $y);
sparse_test($x, $u);
sparse_test($y, $v);
}

my $op1 = Math::FakeDD->new('0x1p-550');
my $op2 = Math::FakeDD->new('0x1p-1050');

my $sub = $op1 - $op2;
chop_inc_test(dd_repro($sub), $sub);

print sprintx(dd_sub_4196($op1, $op2)), "\n";
cmp_ok($sub, '==', dd_sub_4196($op1, $op2), "ok");
cmp_ok($sub, '==', dd_sub_4196($op1, $op2), "$op1 - $op2 ok");


# [0xp1+550 -0xp1-300]
my $ret = Math::FakeDD->new(2 ** 550) - Math::FakeDD->new(2 ** -300);
chop_inc_test(dd_repro($ret), $ret);

# [0xp1+1000 0]
$ret = Math::FakeDD->new(2 ** 1000);
chop_inc_test(dd_repro($ret), $ret);

# [0x1p-550] + [0xp-552] + [0x1p-600]
$ret = Math::FakeDD->new(2 ** -550) + Math::FakeDD->new(2 ** -552) + Math::FakeDD->new(2 ** -600);
chop_inc_test(dd_repro($ret), $ret);

# [0x1p+550 -0x1p-300 ]
$ret = Math::FakeDD->new(2 ** 550) - Math::FakeDD->new(2 ** -300);
chop_inc_test(dd_repro($ret), $ret);

# [0x1p-550 0]
$ret = Math::FakeDD->new(2 ** -550);
chop_inc_test(dd_repro($ret), $ret);

# [0x1p+950 -0x1p+800]
$ret = Math::FakeDD->new(2 ** 950) - Math::FakeDD->new(2 ** 800);
chop_inc_test(dd_repro($ret), $ret);

# [0x1p+900 -0x1p+750]
$ret = Math::FakeDD->new(2 ** 900) - Math::FakeDD->new(2 ** 750);
chop_inc_test(dd_repro($ret), $ret);

# [-0x1p+900 0x1p+750]
$ret = Math::FakeDD->new(-(2 ** 900)) + Math::FakeDD->new(2 ** 750);
chop_inc_test(dd_repro($ret), $ret);

#[0x1p-550 -0x1p-1050]
$ret = Math::FakeDD->new(2 ** -550) - Math::FakeDD->new(2 ** -1050);
chop_inc_test(dd_repro($ret), $ret);

#[-0x1p-550 0x1p-1050]
$ret = Math::FakeDD->new(-(2 ** -550)) + Math::FakeDD->new(2 ** -1050);
chop_inc_test(dd_repro($ret), $ret);

# [0x1p+950 -0x1p+800]
$ret = Math::FakeDD->new(2 ** 950) - Math::FakeDD->new(2 ** 800);
chop_inc_test(dd_repro($ret), $ret);

# [-0x1p+950 0x1p+800]
$ret = Math::FakeDD->new(-(2 ** 950)) + Math::FakeDD->new(2 ** 800);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.0000000000004p+700 -0x1p-350]
$ret = Math::FakeDD->new(2 ** 700) + Math::FakeDD->new(2 ** 650) - Math::FakeDD->new(2 **-350);
chop_inc_test(dd_repro($ret), $ret);

# [-0x1.ffffffffffff8p+849 0x1p-350]
$ret = Math::FakeDD->new(2 ** 800) - Math::FakeDD->new(2 ** 850) - Math::FakeDD->new(2 **-350);
chop_inc_test(dd_repro($ret), $ret);

#[0x1p+200 0x1p-549]
$ret = Math::FakeDD->new(2 ** 200) + Math::FakeDD->new(2 ** -549);
chop_inc_test(dd_repro($ret), $ret);

#[0x1p+200 -0x1p-549]
$ret = Math::FakeDD->new(2 ** 200) - Math::FakeDD->new(2 ** -549);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 0x1p-549]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') + Math::FakeDD->new(2 ** -549);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 -0x1p-549]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') - Math::FakeDD->new(2 ** -549);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 -0x1p-548]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') - Math::FakeDD->new(2 ** -548);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 -0x1p-550]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') - Math::FakeDD->new(2 ** -550);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 -0x1p-551]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') - Math::FakeDD->new(2 ** -551);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 -0x1p-548 - 0xp-555]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') - Math::FakeDD->new(2 ** -548) - Math::FakeDD->new(2 ** -555);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 -0x1p-549 - 0xp-556]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') - Math::FakeDD->new(2 ** -549) - Math::FakeDD->new(2 ** -556) ;
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 -0x1p-550 - 0xp-557]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') - Math::FakeDD->new(2 ** -550) - Math::FakeDD->new(2 ** -557);
chop_inc_test(dd_repro($ret), $ret);

# [0x1.ffffffffffff8p+999 -0x1p-551 - 0xp-558]
$ret = Math::FakeDD->new('0x1.ffffffffffff8p+999') - Math::FakeDD->new(2 ** -551) - Math::FakeDD->new(2 ** -558);
chop_inc_test(dd_repro($ret), $ret);


done_testing();

sub sparse_test {
  my ($op1, $op2)     = (shift, shift);

  chop_inc_test(dd_repro($op1), $op1);

  chop_inc_test(dd_repro($op2), $op2);

  my $mul = $op1 * $op2;
  chop_inc_test(dd_repro($mul), $mul);
  cmp_ok($mul, '==', dd_mul_4196($op1, $op2), "$op1 * $op2 ok");

  my $add = $op1 + $op2;
  chop_inc_test(dd_repro($add), $add);
    cmp_ok($add, '==', dd_add_4196($op1, $op2), "$op1 + $op2 ok");

  my $div = $op1 / $op2;
  chop_inc_test(dd_repro($div), $div);
  cmp_ok($div, '==', dd_div_4196($op1, $op2), "$op1 / $op2 ok");

  my $sub = $op1 - $op2;
  chop_inc_test(dd_repro($sub), $sub);
  cmp_ok($sub, '==', dd_sub_4196($op1, $op2), "$op1 - $op2 ok");
}

sub chop_inc_test {
   my $res;
   my ($repro, $op) = (shift, shift);
   if(defined($_[0])) {
     $res = dd_repro_test($repro, $op, $_[0]);
   }
   else {
     $res = dd_repro_test($repro, $op);
   }
   ok($res == 7) or dd_diag($res, $op);
}

sub dd_diag {
  print STDERR "Failed round-trip for " . sprintx($_[1])     . "\n" unless $_[0] & 1;
  print STDERR "Failed chop test for " . sprintx($_[1])      . "\n" unless $_[0] & 2;
  print STDERR "Failed increment test for " . sprintx($_[1]) . "\n" unless $_[0] & 4;
}


__END__

