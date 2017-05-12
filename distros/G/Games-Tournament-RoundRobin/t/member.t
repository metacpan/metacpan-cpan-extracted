#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 21;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $t = Games::Tournament::RoundRobin->new( v => 4, league => [ 0,1,2,3 ]);
is($t->member(0), 0, 'member 0');
is($t->member(1), 1, 'member 1');
is($t->member(2), 2, 'member 2');
is($t->member(3), 3, 'member 3');

$t = Games::Tournament::RoundRobin->new( v => 19, league => [ 0..18 ]);
is($t->member(0), 0, 'member 0');
is($t->member(1), 1, 'member 1');
is($t->member(2), 2, 'member 2');
is($t->member(10), 10, 'member 10');
is($t->member(17), 17, 'member 17');
is($t->member(18), 18, 'member 18');
is($t->member(19), 19, 'member 19');

is(Games::Tournament::RoundRobin->new( v => 3, league => [qw/Me You It/])->member(0), 'Me', 'member($index) with league array of strings');
is(Games::Tournament::RoundRobin->new( v => 3, league => [qw/Me You It/])->member('You'), 'You', 'member($name), with league array of strings');

is(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 0, You => 1, It => 2 } )->member(1), 0, 'member($index): hash with numerical values');
TODO: { local $TODO = 'Discarded key, no way to find member($name)';
is(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 0, You => 1, It => 2 } )->member('Me'), 0, 'member($name): hash with numerical values');
}

is(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 'Me', You => 'You', It => 'It' } )->member(3), 'Bye', 'member($index): hash with string values');
is (Games::Tournament::RoundRobin->new( v => 5, league => { Me => 'Me', You => 'You', It => 'It' } )->member('Me'), 'Me', 'member($name): hash with string values');

use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );

$t = Games::Tournament::RoundRobin->new( league => [ $m, $y, $i ] );
is( $t->member(2), $i, 'member($index): array of objects');
my $bye = $t->member(3);
is($t->member('Bye'), $bye, 'member($name): array of objects');

my $u = Games::League::Member->new( index => 3, name => 'Us' );
my $a = Games::League::Member->new( index => 4, name => 'All' );
$t = Games::Tournament::RoundRobin->new( v => 5, league => { Me => $m, You => $y, It => $i, Us => $u, All => $a } );
is( $t->member(4), $a, 'member($index): hash of objects');
$bye = $t->member(5);
is($t->member('Bye'), $bye, 'member($name): hash of objects');
