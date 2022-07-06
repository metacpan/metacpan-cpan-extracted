# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More;

use Math::BigInt::Lite;

use Math::BigFloat;

require Math::BigRat;

my $interop;

# The function _register_callback() was removed from Math::BigInt as of version
# 1.999823. Unfortunately, this broke the versions of Math::BigRat that call
# _register_callback() during import(). An empty stub for _register_callback()
# was introduced in Math::BigInt version 1.999836 to fix this problem. The call
# to _register_callback() was removed from Math::BigRat as of version 0.2616.
# Using incompatible versions of Math::BigInt and Math::BigRat gives the error
#
#     Undefined subroutine &Math::BigInt::_register_callback called at ...
#
# The following eval() fails when Math::BigRat version <= 0.2615 is used with
# Math::BigInt versions between 1.999823 and 1.999835, inclusive.

eval { Math::BigRat -> import(); };
unless ($@) {

    # The function _e_add() was removed from Math::BigFloat as of version
    # 1.999831. However, this function was used in the badd() method when adding
    # finite numbers in Math::BigRat up until, and including, Math::BigRat
    # version 0.2622. Math::BigFloat version 1.999836 re-introduced _e_add() as
    # a wrapper function. Using incompatible versions of Math::BigInt and
    # Math::BigRat gives the error
    #
    #     Can't call Math::BigFloat->_e_add, not a valid method at ...
    #
    # The following eval() fails when Math::BigRat versions <= 0.2622 is used
    # with Math::BigInt versions between 1.999831 and 1.999835, inclusive.

    eval { Math::BigRat -> badd(2, 3) };
    unless ($@) {
        $interop = 1;
    }
}

if ($interop) {
    plan tests => 7;
} else {
    diag("WARNING! The currently installed versions of Math::BigInt/",
         "Math::BigFloat and Math::BigRat are not compatible. Please upgrade",
         " to Math::BigInt/Math::BigFloat version 1.999836 or higher and",
         " Math::BigRat version 0.2623 or higher.");
    plan skip_all => 'Incompatible versions of Math::BigInt and Math::BigRat';
}

my ($x, $y);
$y = Math::BigInt::Lite->new(123);
$x = Math::BigRat->new($y);
is($x, 123);

$x->bneg();
is($x, -123);
ok($x->is_odd());
ok(!$x->is_one());

$y = Math::BigInt::Lite->new(-123);
$x = Math::BigRat->new($y);
is($x, -123);

$x->babs();
is($x, 123);
ok($x->is_odd());
