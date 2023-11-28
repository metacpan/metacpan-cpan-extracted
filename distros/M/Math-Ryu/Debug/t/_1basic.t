use strict;
use warnings;

use Test::More;

END { done_testing(); };

use Math::Ryu qw(:all);
use Math::Ryu::Debug; # Don't import anything as function names will clash with the
                      # functions already imported into the Math::Ryu namespace.

if(Math::Ryu::Debug::_has_uint128()) { warn "DEBUG HAS_UINT128: 1\n" }
else { warn "DEBUG HAS_UINT128: 0\n" }

cmp_ok($Math::Ryu::Debug::VERSION, '==', 0.05, "version is as expected");
cmp_ok($Math::Ryu::Debug::VERSION, '==', $Math::Ryu::VERSION, "version matches Math::Ryu");

my $s1 = d2s(1.4 / 10);
my $s2 = Math::Ryu::Debug::d2s(1.4 / 10);

cmp_ok($s2, 'eq', $s1, "d2s(1.4 / 10) is consistent");

$s1 = d2s(2 ** -1074);
$s2 = Math::Ryu::Debug::d2s(2 ** -1074);

cmp_ok($s2, 'eq', $s1, "d2s(2 ** -1074) is consistent");
