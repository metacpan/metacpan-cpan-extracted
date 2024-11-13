use strict;
use warnings;

use Math::MPFR qw(:mpfr);

# $Math::MPFR::PERL_INFNAN is initially set to 0.

#use Test2::V0;
use Test::More;

*_refcnt = \&Math::MPFR::get_refcnt;

my($pinfcount, $ninfcount, $nanvcount) = (_refcnt($Math::MPFR::pinfstr),
                                          _refcnt($Math::MPFR::ninfstr),
                                          _refcnt($Math::MPFR::nanvstr));

cmp_ok($pinfcount, '==', 1, '$Math::MPFR::pinfstr refcount is 1');
cmp_ok($ninfcount, '==', 1, '$Math::MPFR::ninfstr refcount is 1');
cmp_ok($nanvcount, '==', 1, '$Math::MPFR::nanvstr refcount is 1');

my $nv = 1e5000;
cmp_ok(nvtoa ($nv), 'eq', 'Inf', 'nvtoa : +inf stringifies as per default');
cmp_ok(numtoa($nv), 'eq', 'Inf', 'numtoa: +inf stringifies as per default');
$nv *= -1;
cmp_ok(nvtoa ($nv), 'eq', '-Inf', 'nvtoa :  inf stringifies as per default');
cmp_ok(numtoa($nv), 'eq', '-Inf', 'numtoa: -inf stringifies as per default');
$nv /= $nv;
cmp_ok(nvtoa ($nv), 'eq', 'NaN', 'nvtoa : nan stringifies as per default');
cmp_ok(numtoa($nv), 'eq', 'NaN', 'numtoa: nan stringifies as per default');

$Math::MPFR::PERL_INFNAN = 1;

$nv = 1e5000;
cmp_ok(nvtoa($nv), 'eq', $Math::MPFR::pinfstr, '+inf stringifies as per perl');
cmp_ok(_refcnt($Math::MPFR::pinfstr), '==', $pinfcount, '1: $pinfcount ok');
$nv *= -1;
cmp_ok(nvtoa($nv), 'eq', $Math::MPFR::ninfstr, '-inf stringifies as per perl');
cmp_ok(_refcnt($Math::MPFR::ninfstr), '==', $ninfcount, '1: $ninfcount ok');
$nv /= $nv;
cmp_ok(nvtoa($nv), 'eq', $Math::MPFR::nanvstr, 'nan stringifies as per perl');
cmp_ok(_refcnt($Math::MPFR::nanvstr), '==', $nanvcount, '1: $nanvcount ok');

my($x, $y, $z) = (\$Math::MPFR::pinfstr, \$Math::MPFR::ninfstr, \$Math::MPFR::nanvstr);

cmp_ok(_refcnt($Math::MPFR::pinfstr), '==', 2, '$Math::MPFR::pinfstr refcount is 2');
cmp_ok(_refcnt($Math::MPFR::ninfstr), '==', 2, '$Math::MPFR::ninfstr refcount is 2');
cmp_ok(_refcnt($Math::MPFR::nanvstr), '==', 2, '$Math::MPFR::nanvstr refcount is 2');

my $s = nvtoa($nv);
cmp_ok($s, 'eq', $Math::MPFR::nanvstr, "\$s is '$Math::MPFR::nanvstr'");
cmp_ok(_refcnt($Math::MPFR::nanvstr), '==', 2, '$Math::MPFR::nanvstr refcount is still 2');

$z = 'hello world';
cmp_ok(_refcnt($Math::MPFR::nanvstr), '==', 1, '$Math::MPFR::nanvstr refcount is back to 1');

done_testing();
__END__

