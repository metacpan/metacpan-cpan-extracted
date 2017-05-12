#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 21;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );
my $t = Games::League::Member->new( index => 3, name => 'Them' );

my $o = Games::Tournament::RoundRobin->new( v => 3, league => [ $m, $y, $i, $t ] );
is($o->size, 4, 'v=4, not 3');

is($o->index('Me'), 0, 'index($name)');
is($o->index($i), 2, 'index($object)');

is($o->index('You'), 1, 'objects index 1');
isnt($o->index(1), 1, 'objects index 2');
isnt($o->index(2), 2, 'objects index 2');
is($o->index($t), 3, 'objects index 3');

my $n = Games::Tournament::RoundRobin->new( league => [ qw/Me You It/] );
isnt($n->index(0), 0, '4/index 0');
is($n->index('You'), 1, '4/index 1');
isnt($n->index(2), 2, '4/index 2');
is($n->index('Bye'), 3, '4/index 3');

$n = Games::Tournament::RoundRobin->new( v => 3 );
is($n->index(0), 0, '4/index 0');
is($n->index(1), 1, '4/index 1');
is($n->index(2), 2, '4/index 2');
is($n->index(3), 3, '4/index 3');

$n = Games::Tournament::RoundRobin->new( v => 19, league => [ 0..18 ]);
my $r = $n->index(1);
is($r, 1, '19/round 1');
$r = $n->index(2);
is($r, 2, '19/round 2');
$r = $n->index(3);
is($r, 3, '19/round 3');
$r = $n->index(17);
is($r, 17, '19/round 17');
$r = $n->index(18);
is($r, 18, '19/round 18');
$r = $n->index(19);
is($r, 19, '19/round 19');
