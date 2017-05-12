#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 8;

use Math::AnyNum;

my $q = Math::AnyNum->new_q('3/4');
is($q->inv, '4/3');
is($q,      '3/4');

my $f = Math::AnyNum->new_f('5');
is($f->inv, '0.2');
is($f,      '5');

my $z = Math::AnyNum->new_z('41');
is($z->inv, '1/41');
is($z,      '41');

my $c = Math::AnyNum->new_c('3', '4');
is($c->inv, '0.12-0.16i');
is($c,      '3+4i');
