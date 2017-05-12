#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 8;

use Math::AnyNum;

my $q = Math::AnyNum->new_q('3/4');
$q = $q->inc;
is($q, '7/4');
$q = $q->dec;
is($q, '3/4');

my $f = Math::AnyNum->new_f('9.92');
$f = $f->inc;
is($f, '10.92');
$f = $f->dec;
is($f, '9.92');

my $z = Math::AnyNum->new_z('41');
$z = $z->inc;
is($z, '42');
$z = $z->dec;
is($z, '41');

my $c = Math::AnyNum->new_c('3', '4');
$c = $c->inc;
is($c, '4+4i');
$c = $c->dec;
is($c, '3+4i');
