use strict;
use warnings;
use Math::Ryu qw(:all);
use Test::More;

my @in = (
 0.1,
 -0.1,
 1.4 / 10,
 sqrt 2,
 sqrt 3,
 2 ** -1074,
 -(2 ** -1074),
);

my @res = (
 '1E-1',
 '-1E-1',
 '1.3999999999999999E-1',
 '1.4142135623730951E0',
 '1.7320508075688772E0',
 '5E-324',
 '-5E-324',
);

my @fixed = (
 '0.1000000000000000055511151231257827021181583404541015625'  . ('0' x 269),
 '-0.1000000000000000055511151231257827021181583404541015625' . ('0' x 269),
 '0.1399999999999999855671006798729649744927883148193359375'  . ('0' x 269),
 '1.4142135623730951454746218587388284504413604736328125'     . ('0' x 272),
 '1.732050807568877193176604123436845839023590087890625'      . ('0' x 273),
 '0.'  . ('0' x 323) . '5',
 '-0.' . ('0' x 323) . '5',
);

my @exp = (
 '1.0000000000000000555111512312578270211815834045410156250e-01',
 '-1.0000000000000000555111512312578270211815834045410156250e-01',
 '1.3999999999999998556710067987296497449278831481933593750e-01',
 '1.4142135623730951454746218587388284504413604736328125000e+00',
 '1.7320508075688771931766041234368458390235900878906250000e+00',
 '4.9406564584124654417656879286822137236505980261432476443e-324',
 '-4.9406564584124654417656879286822137236505980261432476443e-324',
);


for(0 .. @in - 1) {

  # I know of cases where 2 ** -1074 is incorrectly deemed to be zero.
  next if $in[$_] == 0;

###########

## d2s() ##
  like(d2s($in[$_]), qr/^\Q$res[$_]\E$/i, "d2s() stringifies $in[$_] correctly");

## d2s_buffered_n() ##
  my(@ret) = d2s_buffered_n($in[$_]);
  cmp_ok(@ret, '==', 2, "returned array contains 2 elements");
  cmp_ok($ret[0], 'eq', d2s($in[$_]),  "d2s_buffered_n($in[$_]) returns same value as d2s()");
  cmp_ok($ret[1], '==', length($res[$_]), "d2s_buffered_n($in[$_]) returns correct character count");

## d2s_buffered() ##
  cmp_ok(d2s_buffered($in[$_]), 'eq', d2s($in[$_]), "d2s_buffered($in[$_]) returns same value as d2s()");

###############
###############

## d2fixed() ##
  cmp_ok(d2fixed($in[$_], 324), 'eq', $fixed[$_], "d2fixed($in[$_], 324) stringifies correctly");

## d2fixed_buffered_n() ##
  @ret = d2fixed_buffered_n($in[$_], 324);
  cmp_ok(@ret, '==', 2, "returned array contains 2 elements");
  cmp_ok($ret[0], 'eq', d2fixed($in[$_], 324),  "d2fixed_buffered_n($in[$_], 324) returns same value as d2fixed()");
  cmp_ok($ret[1], '==', length($fixed[$_]), "d2fixed_buffered_n($in[$_], 324) returns correct character count");

## d2fixed_buffered() ##
  cmp_ok(d2fixed_buffered($in[$_], 324), 'eq', d2fixed($in[$_], 324), "d2fixed_buffered($in[$_], 324) returns same value as d2fixed()");

#############
#############

## d2exp() ##
  like(d2exp($in[$_], 55), qr/^\Q$exp[$_]\E$/i, "d2exp($in[$_], 55) stringifies correctly");

## d2exp_buffered_n() ##
  @ret = d2exp_buffered_n($in[$_], 55);
  cmp_ok(@ret, '==', 2, "returned array contains 2 elements");
  cmp_ok($ret[0], 'eq', d2exp($in[$_], 55),  "d2exp_buffered_n($in[$_], 55) returns same value as d2exp()");
  cmp_ok($ret[1], '==', length($exp[$_]), "d2exp_buffered_n($in[$_], 55) returns correct character count");

## d2exp_buffered() ##
  cmp_ok(d2exp_buffered($in[$_], 55), 'eq', d2exp($in[$_], 55), "d2exp_buffered($in[$_], 55) returns same value as d2exp()");

######################
}

my $v = Math::Ryu::_sis_perl_version;
my $v_check = $];
$v_check =~ s/\.//;

cmp_ok($v, 'eq', $v_check);
cmp_ok($Math::Ryu::VERSION, 'eq', '0.02', "\$VERSION stringifies as expected");
cmp_ok($Math::Ryu::VERSION, '==',  0.02,  "\$VERSION numifies as expected");

done_testing();

