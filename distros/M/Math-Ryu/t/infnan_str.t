use strict;
use warnings;

use Math::Ryu qw(:all);

# $Math::Ryu::PERL_INFNAN is initially set to 0.

#use Test2::V0;
use Test::More;

if   (Math::Ryu::MAX_DEC_DIG == 17) { *NV2S = \&d2s }
elsif(Math::Ryu::MAX_DEC_DIG == 21) { *NV2S = \&ld2s }
else                                { *NV2S = \&q2s }

my($pinfcount, $ninfcount, $nanvcount) = (ryu_refcnt($Math::Ryu::pinfstr),
                                          ryu_refcnt($Math::Ryu::ninfstr),
                                          ryu_refcnt($Math::Ryu::nanvstr));

cmp_ok($pinfcount, '==', 1, '$Math::Ryu::pinfstr refcount is 1');
cmp_ok($ninfcount, '==', 1, '$Math::Ryu::ninfstr refcount is 1');
cmp_ok($nanvcount, '==', 1, '$Math::Ryu::nanvstr refcount is 1');

my $nv = 1e5000;
cmp_ok(nv2s($nv), 'eq', 'inf', '+inf stringifies as per default');
$nv *= -1;
cmp_ok(nv2s($nv), 'eq', '-inf', '-inf stringifies as per default');
$nv /= $nv;
cmp_ok(nv2s($nv), 'eq', 'nan', 'nan stringifies as per default');

$nv = 1e5000;
cmp_ok(fmtpy_pp(NV2S($nv)), 'eq', 'inf', 'fmtpy_pp: +inf stringifies as per default');
$nv *= -1;
cmp_ok(fmtpy_pp(NV2S($nv)), 'eq', '-inf', 'fmtpy_pp: -inf stringifies as per default');
$nv /= $nv;
cmp_ok(fmtpy_pp(NV2S($nv)), 'eq', 'nan', 'fmtpy_pp: nan stringifies as per default');

$Math::Ryu::PERL_INFNAN = 1;

$nv = 1e5000;
cmp_ok(nv2s($nv), 'eq', $Math::Ryu::pinfstr, '+inf stringifies as per perl');
cmp_ok(ryu_refcnt($Math::Ryu::pinfstr), '==', $pinfcount, '1: $pinfcount ok');
$nv *= -1;
cmp_ok(nv2s($nv), 'eq', $Math::Ryu::ninfstr, '-inf stringifies as per perl');
cmp_ok(ryu_refcnt($Math::Ryu::ninfstr), '==', $ninfcount, '1: $ninfcount ok');
$nv /= $nv;
cmp_ok(nv2s($nv), 'eq', $Math::Ryu::nanvstr, 'nan stringifies as per perl');
cmp_ok(ryu_refcnt($Math::Ryu::nanvstr), '==', $nanvcount, '1: $nanvcount ok');

$nv = 1e5000;
cmp_ok(fmtpy_pp(NV2S($nv)), 'eq', $Math::Ryu::pinfstr, 'fmtpy_pp: +inf stringifies as per perl');
cmp_ok(ryu_refcnt($Math::Ryu::pinfstr), '==', $pinfcount, '2: $pinfcount ok');
$nv *= -1;
cmp_ok(fmtpy_pp(NV2S($nv)), 'eq', $Math::Ryu::ninfstr, 'fmtpy_pp: -inf stringifies as per perl');
cmp_ok(ryu_refcnt($Math::Ryu::ninfstr), '==', $ninfcount, '2: $ninfcount ok');
$nv /= $nv;
cmp_ok(fmtpy_pp(NV2S($nv)), 'eq', $Math::Ryu::nanvstr, 'fmtpy_pp: nan stringifies as per perl');
cmp_ok(ryu_refcnt($Math::Ryu::nanvstr), '==', $nanvcount, '2: $nanvcount ok');

my($x, $y, $z) = (\$Math::Ryu::pinfstr, \$Math::Ryu::ninfstr, \$Math::Ryu::nanvstr);

cmp_ok(ryu_refcnt($Math::Ryu::pinfstr), '==', 2, '$Math::Ryu::pinfstr refcount is 2');
cmp_ok(ryu_refcnt($Math::Ryu::ninfstr), '==', 2, '$Math::Ryu::ninfstr refcount is 2');
cmp_ok(ryu_refcnt($Math::Ryu::nanvstr), '==', 2, '$Math::Ryu::nanvstr refcount is 2');

my $s = nv2s($nv);
cmp_ok($s, 'eq', $Math::Ryu::nanvstr, "\$s is '$Math::Ryu::nanvstr'");
cmp_ok(ryu_refcnt($Math::Ryu::nanvstr), '==', 2, '$Math::Ryu::nanvstr refcount is still 2');

$z = 'hello world';
cmp_ok(ryu_refcnt($Math::Ryu::nanvstr), '==', 1, '$Math::Ryu::nanvstr refcount is back to 1');

done_testing();
__END__

