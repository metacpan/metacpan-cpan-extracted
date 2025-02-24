# Test overloading of gmp objects.
# The only gotcha here is that Math::GMP overloading of Math::MPFR objects does not work.
# Therefore, while the following DWIMs:
# $ perl -MMath::MPFR -MMath::GMP -le 'print "ok" if Math::MPFR->new(0) < Math::GMP->new(10);'
#   ok
# the converse does not, and will crash in some cases:
# $ perl -MMath::MPFR -MMath::GMP -le 'print "ok" if Math::GMP->new(10) > Math::MPFR->new(0);'
#
# That is, while Math::MPFR evaluates Math::GMP objects as intended, Math::MPFR objects are
# meaningless to Math::GMP.
# It is therefore up to the user to ensure that Math::MPFR is doing the overloading.
# (It seems to me that all Math::MPFR objects will be evaluated by Math::GMP as being zero.)


use strict;
use warnings;

use Math::MPFR qw(:mpfr);
use Test::More;

eval { require Math::GMP; };

if($@) {
  warn "\$\@: $@\n";
  warn "Skipping all tests as Math::GMP could not be loaded\n";
  is(1, 1);
  done_testing();
  exit 0;
}

my $z = Math::GMP->new('1234' x 2);
my $f = Math::MPFR->new(0);

cmp_ok( $f, '<', $z, "'<' ok");
cmp_ok( $f, '<', $z, "'!=' ok");
cmp_ok( $f, '<=', $z, "'<=' ok");
cmp_ok( $f + $z, '==', $z, "'==' ok");
cmp_ok( $f + $z, '==', $z, "'>=' ok");
cmp_ok( $f += $z, '==', $z, "'+=' ok");
$f += $z;
cmp_ok( $f, '>', $z, "'>' ok");
cmp_ok( $f - $z, '==', $z, "'-' ok");
$f -= $z;
cmp_ok($f, '==', $z, "'-=' ok");
cmp_ok($f ** Math::GMP->new(2), '==', $z ** 2, "'**' ok");
$f **= Math::GMP->new(2);
cmp_ok($f, '==', $z ** 2, "'**=' ok");

$f **= 0.5;

cmp_ok($f * 5, '==', $z * 5, "'*' ok");
cmp_ok($f *= Math::GMP->new(5), '==', $z * 5, "'*=' ok");
cmp_ok($f / Math::GMP->new(5), '==', $z, "'/' ok");
cmp_ok($f /= Math::GMP->new(5), '==', $z, "'/=' ok");

Rmpfr_sprintf(my $buf, "%Zd", $z, 32);
cmp_ok($buf, 'eq', "$z", "'%Zd' formatting ok");

Rmpfr_sprintf($buf, "%Zu", $z, 32);
cmp_ok($buf, 'eq', "$z", "'%Zu' formatting ok");

Rmpfr_sprintf($buf, "%Zx", $z, 32);
cmp_ok($buf, 'eq', 'bc4ff2', "'%Zx' formatting ok");

Rmpfr_sprintf($buf, "%ZX", $z, 32);
cmp_ok($buf, 'eq', 'BC4FF2', "'%ZX' formatting ok");





done_testing();
