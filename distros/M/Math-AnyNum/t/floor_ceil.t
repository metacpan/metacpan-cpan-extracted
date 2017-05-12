#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 34;

use Math::AnyNum;

my $q = Math::AnyNum->new_q('123/5');

is($q->floor, '24');
is($q->ceil,  '25');

is($q->neg->floor, '-25');
is($q->neg->ceil,  '-24');

my $f = Math::AnyNum->new_f('24.6');

is($f->floor, '24');
is($f->ceil,  '25');

is($f->neg->floor, '-25');
is($f->neg->ceil,  '-24');

my $f2 = Math::AnyNum->new_f('123');

is($f2->floor, '123');
is($f2->ceil,  '123');

is($f2->neg->floor, '-123');
is($f2->neg->ceil,  '-123');

my $z = Math::AnyNum->new_z('42');
is($z->floor,      '42');
is($z->ceil,       '42');
is($z->neg->floor, '-42');
is($z->neg->ceil,  '-42');

my $c = Math::AnyNum->new_c('3.321', '4.623');

is($c->floor, '3+4i');
is($c->ceil,  '4+5i');

is($c->neg, '-3.321-4.623i');

is($c->neg->floor, '-4-5i');
is($c->neg->ceil,  '-3-4i');

my $c2 = Math::AnyNum->new_c('-12.9', '17.3');

is($c2->floor, '-13+17i');
is($c2->ceil,  '-12+18i');

is($c2->neg, '12.9-17.3i');

is($c2->neg->floor, '12-18i');
is($c2->neg->ceil,  '13-17i');

my $c3 = Math::AnyNum->new_c('13.5');

is($c3->floor, '13');
is($c3->ceil,  '14');

is($c3->neg->floor, '-14');
is($c3->neg->ceil,  '-13');

my $c4 = Math::AnyNum->new_c('42');

is($c4->floor, '42');
is($c4->ceil,  '42');

is($c4->neg->floor, '-42');
is($c4->neg->ceil,  '-42');
