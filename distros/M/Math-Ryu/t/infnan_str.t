use strict;
use warnings;

use Math::Ryu qw(:all);
# $Math::Ryu::PERL_INFNAN is set to 0.

use Test::More;

my $nv = 1e5000;
cmp_ok(nv2s($nv), 'eq', 'inf', '+inf stringifies as per default');
$nv *= -1;
cmp_ok(nv2s($nv), 'eq', '-inf', '-inf stringifies as per default');
$nv /= $nv;
cmp_ok(nv2s($nv), 'eq', 'nan', 'nan stringifies as per default');

$Math::Ryu::PERL_INFNAN = 1;

$nv = 1e5000;
cmp_ok(nv2s($nv), 'eq', $Math::Ryu::pinf, '+inf stringifies as per perl');
$nv *= -1;
cmp_ok(nv2s($nv), 'eq', $Math::Ryu::ninf, '-inf stringifies as per perl');
$nv /= $nv;
cmp_ok(nv2s($nv), 'eq', $Math::Ryu::nanv, 'nan stringifies as per perl');


done_testing();
