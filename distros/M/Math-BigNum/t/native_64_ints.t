#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 52;

use Math::BigNum;

my $i = '9223372036854775818';                        # 2^63 + 10
my $x = Math::BigNum->new('18446744073709551636');    # 2 * (2^63 + 10)

is($x->fadd($i), '27670116110564327454');
is($x->fmul($i), '170141183460469232100622185190075138248');
is($x->fdiv($i), '2');
is($x->iadd($i), '27670116110564327454');
is($x->imul($i), '170141183460469232100622185190075138248');
is($x->idiv($i), '2');

is($x->copy->bfadd($i), '27670116110564327454');
is($x->copy->bfmul($i), '170141183460469232100622185190075138248');
is($x->copy->bfdiv($i), '2');
is($x->copy->biadd($i), '27670116110564327454');
is($x->copy->bimul($i), '170141183460469232100622185190075138248');
is($x->copy->bidiv($i), '2');

#<<<
is($i ** Math::BigNum->new(2), '85070591730234616050311092595037569124');
is($i * $x,                  '170141183460469232100622185190075138248');
is($i / $x,                  '0.5');
is($i - $x,                  '-9223372036854775818');
is($i + $x,                  '27670116110564327454');
#>>>

is(($x + 1)->lcm($i),       '170141183460469232109845557226929914066');
is($x->kronecker($i),       '0');
is(($x + 1)->kronecker($i), '-1');
is(($x + 5)->kronecker($i), '1');

is($x->imod($i),        '0');
is($x->fmod($i),        '0');
is($x->copy->bimod($i), '0');
is($x->copy->bfmod($i), '0');

is($x->mod($i),        '0');
is($x->copy->bmod($i), '0');

is(($x + 13)->mod($i),  '13');
is(($x + 13)->bmod($i), '13');

is(($x + 13)->bimod($i),   '13');
is(($x + 13)->bfmod($i),   '13');
is($x->fadd(13)->imod($i), '13');
is($x->iadd(13)->fmod($i), '13');

is(join(' ', $x->divmod($i)), "2 0");
is(($x + 13)->modinv($i), '3547450783405683007');
is(($x + 13)->modpow(2,  $i),     '169');
is(($x + 13)->modpow($i, $x + 1), '8227411628627543261');

ok($x->is_div($i));
ok(!(($x + 1)->is_div($i)));

is($x->acmp($i),        1);
is((-$x)->acmp($i),     1);
is(($x >> 1)->acmp($i), 0);

is($x->cmp($i),        1);
is(($x >> 1)->cmp($i), 0);

ok($x->gt($i));
ok($x->ge($i));

ok(not $x->lt($i));
ok(not $x->le($i));

is($x <=> $i, 1);
is($i <=> $x, -1);
ok($x != $i);
ok($i != $x);
