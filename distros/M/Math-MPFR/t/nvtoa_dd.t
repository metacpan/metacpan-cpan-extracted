# This test script was written for the DoubleDouble NV type.
# But I figure we might as well run it, no matter what NV we have.
# However, there can be an issue with the SvNOK flag on old perls,
# so we avoid anything older than perl-5.12.

use strict;
use warnings;
use 5.012;
use Math::MPFR qw(:mpfr);

use Test::More;

unless(Math::MPFR::MPFR_3_1_6_OR_LATER) {
  plan skip_all => "nvtoa.t utilizes Math::MPFR functionality that requires mpfr-3.1.6\n";
  exit 0;
}

for(-1075..1024) {
  my $nv = 2 ** $_;
  cmp_ok(nvtoa_test(nvtoa($nv), $nv), '==', 15, "2 ** $_");
  cmp_ok(nvtoa_test(nvtoa(-$nv), -$nv), '==', 15, "-(2 ** $_)");
}

my @pows = (50, 100, 150, 200, 250, 300, 350, 400, 450, 500,
         550, 600, 650, 700, 750, 800, 850, 900, 950, 1000);

  die "wrong sized array" unless @pows == 20;

my $ret = (2** -1020) + (2 ** -1021);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2** -1020) + (2 ** -1021)");

$ret = (2** -1021) + (2 ** -1064);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2** -1021) + (2 ** -1064)");

$ret = (2** -1020) - (2 ** -1021);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2** -1020) - (2 ** -1021)");

$ret = (2** -1021) - (2 ** -1064);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2** -1021) - (2 ** -1064)");

#   Failed test '[2 11] / [12 9] repro ok'
#   at t/sparse.t line 64.
#          got: [3.054936363499605e-151 4.9406564584124654e-324]
#     expected: [3.054936363499605e-151 0.0]

my @in0 = qw(2 11);
my @in1 = qw(12 9);
$ret = my_assign(\@in0, \@in1, '/');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 / @in1");

@in0 = qw(2 -17);
@in1 = qw(9 -17);
$ret = my_assign(\@in0, \@in1, '/');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 / @in1");

#   Failed test '[3 3] - [3 10] repro ok'
#   at t/sparse.t line 69.
#          got: [6.223015277861142e-61 -2.713328551617527e-166]
#     expected: [6.223015277861142e-61 -2.7133285516175262e-166]

@in0 = qw(3 3);
@in1 = qw(3 10);
$ret = my_assign(\@in0, \@in1, '-');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 - @in1");

#   Failed test '[13 -1] * [1 -7] repro ok'
#   at t/sparse.t line 54.
#          got: [6.668014432879854e+240 -2.0370359763344865e+90]
#     expected: [6.668014432879854e+240 -2.037035976334486e+90]

@in0 = qw(13 -1);
@in1 = qw(1 -7);
$ret = my_assign(\@in0, \@in1, '*');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 * @in1");

#   Failed test '[14 1] - [11 4] repro ok'
#   at t/sparse.t line 69.
#          got: [5.922386521532856e+225 -4.1495155688809925e+180]
#     expected: [5.922386521532856e+225 -4.149515568880993e+180]

@in0 = qw(14 1);
@in1 = qw(11 4);
$ret = my_assign(\@in0, \@in1, '-');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 - @in1");

#   Failed test '[17 -16] + [11 -2] repro ok'
#   at t/sparse.t line 59.
#          got: [8.452712498170644e+270 4.1495155688809925e+180]
#     expected: [8.452712498170644e+270 4.149515568880993e+180]

@in0 = qw(17 -16);
@in1 = qw(11 -2);
$ret = my_assign(\@in0, \@in1, '+');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 + @in1");

#   Failed test '[1 8] * [0 11] repro ok'
#   at t/sparse.t line 54.
#          got: [1.42724769270596e+45 3.872591914849318e-121]
#     expected: [1.42724769270596e+45 3.8725919148493183e-121]

@in0 = qw(1 8);
@in1 = qw(0 11);
$ret = my_assign(\@in0, \@in1, '*');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 * @in1");

#   Failed test '[8 -18] / [13 -1] repro ok'
#   at t/sparse.t line 64.
#          got: [5.527148e-76 -1.9501547226722595e-92]
#     expected: [5.527147875260445e-76 8.289046058458095e-317]

@in0 = qw(8 -18);
@in1 = qw(13 -1);
$ret = my_assign(\@in0, \@in1, '/');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 / @in1");

# [3 13] / [14 9]

@in0 = qw(3 13);
@in1 = qw(14 9);
$ret = my_assign(\@in0, \@in1, '/');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 / @in1");

# [13 -8] + [12 -6]

@in0 = qw(13 -8);
@in1 = qw(12 -6);
$ret = my_assign(\@in0, \@in1, '+');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "@in0 + @in1");

# 0.66029111258694e-111 fails chop test.
$ret = atonv('0.66029111258694e-111');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "0.66029111258694e-111");

# 0.876771194648327e219 fails chop test
$ret = atonv('0.876771194648327e219');
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "0.876771194648327e219");

#   Failed test 'chop test ok for [11 -14]'
#   at t/sparse.t line 90.
#     '[4.149515568880993e+180 -1.688508503057271e-226]'
#         <
#     '[4.149515568880993e+180 -1.688508503057271e-226]'

@in0 = qw(11 -14);
$ret = (2 ** $pows[11]) - (2 ** -$pows[14]);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2 ** $pows[11]) - (2 ** -$pows[14])");

$ret = atonv(2 ** 550) + nvtoa(2 ** -300);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2 ** 550) + (2 ** -300)");

$ret = atonv(2 ** 1000);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2 ** 1000)");

$ret = atonv(2 ** -550) + nvtoa(2 ** -552) + nvtoa(2 ** -600);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2 ** -550) + (2 ** -552)");

$ret = atonv(2 ** 550) - nvtoa(2 ** -300);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2 ** 550) - (2 ** -300)");

$ret = atonv(2 ** -550);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2 ** -550)");

# [0x1p+950 -0x1p+800]
$ret = atonv(2 ** 950) - nvtoa(2 ** 800);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2 ** 950) - (2 ** 800)");

# [0x1p+900 -0x1p+750]
$ret = atonv(2 ** 900) - nvtoa(2 ** 750);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2**900) - (2** 50)");

#[0x1p-550 -0x1p-1050]
$ret = atonv(2 ** -550) - nvtoa(2 ** -1050);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2**-550) - (2**-1050)");

#[-0x1p+950 0x1p+800]
$ret = atonv(-(2 ** 950)) + nvtoa(2 ** 800);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "-(2**950) + (2**800)");

$ret = atonv(2 ** 700) + nvtoa(2 ** 650) - nvtoa(2 **-350);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2**700) + (2**650) - (2**-350)");

# [-0x1.ffffffffffff8p+849 0x1p-350]
$ret = atonv(2 ** 800) - nvtoa(2 ** 850) - nvtoa(2 **-350);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2**800) - (2**850) - (2**-350)");

#[0x1p+200 0x1p-549]
$ret = atonv(2 ** 200) + nvtoa(2 ** -549);
cmp_ok(nvtoa_test(nvtoa($ret), $ret), '==', 15, "(2 ** 950) - (2 ** 800)");

my(@big, @little);
my @p = @pows;

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

  my $x = atonv( $big[$xb] ) + atonv( $little[$xl] );
     $x += ( atonv($big[$xb]   ) / 2 ** (int(rand(30))) )
            +
           ( atonv($little[$xl]) * 2 ** (int(rand(30))) );
  my $y = atonv( $big[$yb] ) + atonv( $little[$yl] );

  my $u = atonv( $big[$ub] ) - atonv( $little[$ul] );
     $u += ( atonv($big[$xb]   ) / 2 ** (int(rand(30))) )
            -
           ( atonv($little[$xl]) * 2 ** (int(rand(30))) );
  my $v = atonv( $big[$vb] ) - atonv( $little[$vl] );

sparse_test($x, $y);
sparse_test($u, $v);
sparse_test($x, $v);
sparse_test($u, $y);
sparse_test($x, $u);
sparse_test($y, $v);
}

##############################################################
##############################################################
##############################################################

done_testing();

sub my_assign {

my @p = (50, 100, 150, 200, 250, 300, 350, 400, 450, 500,
         550, 600, 650, 700, 750, 800, 850, 900, 950, 1000);

  die "wrong sized array" unless @p == 20;

  my($xb, $xl) = @{$_[0]};
  my($yb, $yl) = @{$_[1]};

  my $x = $xl =~ /\-/ ? (2 **$p[$xb]) - (2** -( $p[-$xl]) )
                      : (2 **$p[$xb]) + (2** -( $p[$xl ]) );
  my $y = $yl =~ /\-/ ? (2 **$p[$yb]) - (2** -( $p[-$yl]) )
                      : (2 **$p[$yb]) + (2** -( $p[$yl ]) );

  my $op = $_[2];

  return $x * $y if($op eq '*') ;
  return $x + $y if($op eq '+') ;
  return $x / $y if($op eq '/') ;
  return $x - $y if($op eq '-') ;

  die "Error in my_assign();"
}

sub sparse_test {
  my ($op1, $op2)     = (shift, shift);

  cmp_ok(nvtoa_test(nvtoa($op1), $op1), '==', 15, "X" . unpack("H*", pack("F>", $op1)));
  cmp_ok(nvtoa_test(nvtoa($op2), $op2), '==', 15, "X" . unpack("H*", pack("F>", $op2)));

  my $mul = $op1 * $op2;
  cmp_ok(nvtoa_test(nvtoa($mul), $mul), '==', 15, "X" . unpack("H*", pack("F>", $mul)));

  my $add = $op1 + $op2;
  cmp_ok(nvtoa_test(nvtoa($add), $add), '==', 15, "X" . unpack("H*", pack("F>", $add)));

  my $div = $op1 / $op2;
  cmp_ok(nvtoa_test(nvtoa($div), $div), '==', 15, "X" . unpack("H*", pack("F>", $div)));

  my $sub = $op1 - $op2;
  cmp_ok(nvtoa_test(nvtoa($sub), $sub), '==', 15, "X" . unpack("H*", pack("F>", $sub)));
}
