#!perl -T

# Test blog function (and bpow, since it uses blog), as well as bexp().

use strict;
use warnings;

use Test::More tests => 29;

use Math::BigNum;

my $cl = 'Math::BigNum';

#############################################################################
# test log($n)

is($cl->new(2)->blog()->int,    '0', "blog(2)");
is($cl->new(288)->blog()->int,  '5', "blog(288)");
is($cl->new(2000)->blog()->int, '7', "blog(2000)");

#############################################################################
# test exp($n)

is($cl->new(1)->bexp()->as_int(), '2',  "bexp(1)");
is($cl->new(2)->bexp()->as_int(), '7',  "bexp(2)");
is($cl->new(3)->bexp()->as_int(), '20', "bexp(3)");

#############################################################################
# test bexp() with cached results

like($cl->new(1)->bexp(), qr/^2\.7182818284590/, 'bexp(1)');
is($cl->new(2)->bexp(1), $cl->new(1)->bexp(1)->bpow(2), 'bexp(2)');

is($cl->new("12.5")->bexp(1), $cl->new(1)->bexp(1)->bpow(12.5), 'bexp(12.5)');

#############################################################################
# test bexp() with big values (non-cached)

is($cl->new(1)->bexp(1)->as_float(10), '2.7182818285', 'bexp(1)->as_float(10)');

is($cl->new("12.5")->bexp(1), $cl->new(1)->bexp(1)->bpow(12.5), 'bexp(12.5) to 91 digits');

#############################################################################
# some integer results
is($cl->new(2)->bpow(32)->blog(2), '32', "2 ** 32");
is($cl->new(3)->bpow(32)->blog(3), '32', "3 ** 32");
is($cl->new(2)->bpow(65)->blog(2), '65', "2 ** 65");

my $x    = $cl->new('777')**256;
my $base = $cl->new('12345678901234');
is($x->log($base)->int, 56, 'blog(777**256, 12345678901234)');

$x    = $cl->new('777')**777;
$base = $cl->new('777');
is($x->copy()->blog($base), 777, 'blog(777**777, 777)');

#
## lgrt
#

is($x->lgrt,        '777');
is($cl->zero->lgrt, 'NaN');
is($cl->one->lgrt,  '1');
is($cl->mone->lgrt, 'NaN');
like($cl->new(100)->lgrt,                                 qr/^3\.59728502354041750549765/);
like($cl->new('0.6922006275553463538654219971827')->lgrt, qr/^0\.3678794411714\d*\z/);

#
## lambert_w
#
like($cl->new('-0.35787944117144232159552377016146086744581113103177')->lambert_w, qr/^-0\.7832291989812967764330746/);
like(log($cl->new(100))->lambert_w->exp,                                           qr/^3\.59728502354041750549765/);
is($cl->mone->lambert_w,       $cl->nan);
is($cl->zero->lambert_w,       0);
is($cl->new(-42.5)->lambert_w, $cl->nan);
like($cl->one->lambert_w, qr/^0\.5671432904097838729999/);
is($cl->e->lambert_w, 1);

# all done
1;
