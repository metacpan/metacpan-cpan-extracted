#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 34;

BEGIN {
	use_ok( 'FTN::Addr' );
}

my $a = FTN::Addr -> new('1:23/45');
ok(defined $a, 'first created');

my $b = FTN::Addr -> new('1:23/45@fidonet');
ok(defined $b, 'second created');

ok($a eq $b, "Hey! They are the same!");

ok($a != $b, 'but objects are different');

$b -> set_domain('othernet');

ok($a ne $b, 'different domains...');

ok(defined( $b = FTN::Addr -> new('44.22', $a) ), 'with second arg (class constructor)');
ok(defined( $b = $a -> new('44.22') ), 'object call instead of second arg');

is($a -> f4, "1:23/45.0", 'f4');
is($a -> f4, "1:23/45.0", 'f4');

is($a -> s4, "1:23/45", 's4');
is($a -> s4, "1:23/45", 's4');

is($a -> f5, '1:23/45.0@fidonet', 'f5');
is($a -> f5, '1:23/45.0@fidonet', 'f5');

is($a -> s5, '1:23/45@fidonet', 's5');
is($a -> s5, '1:23/45@fidonet', 's5');

is($a -> fqfa, 'fidonet#1:23/45.0', 'fqfa');
is($a -> fqfa, 'fidonet#1:23/45.0', 'fqfa');

is($a -> bs, 'fidonet.1.23.45.0', 'bs');
is($a -> bs, 'fidonet.1.23.45.0', 'bs');




my $t = FTN::Addr -> new('1:23/45');
ok(defined $t, 't');

$t = $t -> new('1:22/33.44@fidonet') or die 'something wrong!';
ok(defined $t, 'object creates object');

$t = FTN::Addr -> new('1:22/33.44@fidonet') or die 'something wrong!';
ok(defined $t, 'class creates');

my $an = FTN::Addr -> new('99', $t); # address in $an is 1:22/99.0@fidonet
ok(defined $an, 'an');

is($an -> fqfa, 'fidonet#1:22/99.0', 'fqfa');

is($an -> bs, 'fidonet.1.22.99.0', 'brake style');

$an = $t -> new('99'); # address in $an is 1:22/99.0@fidonet
ok(defined $an, 'an - two');

is($an -> fqfa, 'fidonet#1:22/99.0', 'fqfa - two');

is($an -> bs, 'fidonet.1.22.99.0', 'brake style - two');


my $first = FTN::Addr -> new('1:23/45.66@fidonet');
ok( defined $first, 'creating first' );

my $second = FTN::Addr -> new('1:23/45.66@fidonet');
ok( defined $second, 'creating first' );

ok(FTN::Addr -> equal($first, $second), 'FTN::Addr -> equal()');

ok($first eq $second, 'eq');

ok($first != $second, '==');
