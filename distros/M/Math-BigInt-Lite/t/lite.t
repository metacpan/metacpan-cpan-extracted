#!perl

use strict;
use warnings;

use Test::More tests => 99;

use Math::BigInt::Lite;

my $c = 'Math::BigInt::Lite';
my $mbi = 'Math::BigInt';

is(Math::BigInt::Lite->config()->{version}, $Math::BigInt::VERSION);
is(Math::BigInt::Lite->config()->{version_lite}, $Math::BigInt::Lite::VERSION);

my ($x, $y, $z);

##############################################################################
$x = $c->new(1234);     is(ref($x), $c);        is($x, 1234);
ok($x->isa('Math::BigInt::Lite'));
ok(!$x->isa('Math::BigRat'));
ok(!$x->isa('Math::BigFloat'));

$x = $c->new('1e3');    is(ref($x), $c);        is($x, '1000');
$x = $c->new('1000');   is(ref($x), $c);        is($x, '1000');
$x = $c->new('1234');   is(ref($x), $c);        is($x, 1234);
$x = $c->new('1e12');   is(ref($x), $mbi);
$x = $c->new('1.');     is(ref($x), $c);        is($x, 1);
$x = $c->new('1.0');    is(ref($x), $c);        is($x, 1);
$x = $c->new('1.00');   is(ref($x), $c);        is($x, 1);
$x = $c->new('1.02');   is(ref($x), $mbi);      is($x, 'NaN');
$x = $c->new('-0');     is(ref($x), $c);        is($x, '0');

$x = $c->new('1');      is(ref($x), $c); $y = $x->copy(); is(ref($y), $c);
is($x, $y);

$x = $c->new('6');      $y = $c->new('2');
is(ref($x), $c); is(ref($y), $c);

$z = $x; $z += $y;      is(ref($z), $c);        is($z, 8);
$z = $x + $y;           is(ref($z), $c);        is($z, 8);
$z = $x - $y;           is(ref($z), $c);        is($z, 4);
$z = $y - $x;           is(ref($z), $c);        is($z, -4);
$z = $x * $y;           is(ref($z), $c);        is($z, 12);
$z = $x / $y;           is(ref($z), $c);        is($z, 3);
$z = $x % $y;           is(ref($z), $c);        is($z, 0);

$z = $y / $x;           is(ref($z), $c);        is($z, 0);
$z = $y % $x;           is(ref($z), $c);        is($z, 2);

$z = $x->as_number();   is(ref($z), $mbi);      is($z, 6);

###############################################################################
# bone/binf etc

$z = $c->bone();        is(ref($z), $c);        is($z, 1);
$z = $c->bone('-');     is(ref($z), $c);        is($z, -1);
$z = $c->bone('+');     is(ref($z), $c);        is($z, 1);
$z = $c->bzero();       is(ref($z), $c);        is($z, 0);
$z = $c->binf();        is(ref($z), $mbi);      is($z, 'inf');
$z = $c->binf('+');     is(ref($z), $mbi);      is($z, 'inf');
$z = $c->binf('+inf');  is(ref($z), $mbi);      is($z, 'inf');
$z = $c->binf('-');     is(ref($z), $mbi);      is($z, '-inf');
$z = $c->binf('-inf');  is(ref($z), $mbi);      is($z, '-inf');
$z = $c->bnan();        is(ref($z), $mbi);      is($z, 'NaN');

$x = $c->new(3);
$z = $x->copy()->bone();        is(ref($z), $c);        is($z, 1);
$z = $x->copy()->bone('-');     is(ref($z), $c);        is($z, -1);
$z = $x->copy()->bone('+');     is(ref($z), $c);        is($z, 1);
$z = $x->copy()->bzero();       is(ref($z), $c);        is($z, 0);
$z = $x->copy()->binf();        is(ref($z), $mbi);      is($z, 'inf');
$z = $x->copy()->binf('+');     is(ref($z), $mbi);      is($z, 'inf');
$z = $x->copy()->binf('+inf');  is(ref($z), $mbi);      is($z, 'inf');
$z = $x->copy()->binf('-');     is(ref($z), $mbi);      is($z, '-inf');
$z = $x->copy()->binf('-inf');  is(ref($z), $mbi);      is($z, '-inf');
$z = $x->copy()->bnan();        is(ref($z), $mbi);      is($z, 'NaN');

###############################################################################
# non-objects

$x = Math::BigInt::Lite::badd('1', '2'); is($x, 3);
$x = Math::BigInt::Lite::badd('1', 2);   is($x, 3);
$x = Math::BigInt::Lite::badd(1, '2');   is($x, 3);
$x = Math::BigInt::Lite::badd(1, 2);     is($x, 3);

$x = Math::BigInt::Lite->new(123456);
is($x->copy()->round(3), 123000);
is($x->copy()->bround(3), 123000);
is($x->copy()->bfround(3), 123000);

###############################################################################
# check faking of HASH-like acccess

$x = Math::BigInt::Lite->new(123);  is($x->{sign}, '+');
$x = Math::BigInt::Lite->new(0);    is($x->{sign}, '+');
$x = Math::BigInt::Lite->new(-123); is($x->{sign}, '-');

# done

1;
