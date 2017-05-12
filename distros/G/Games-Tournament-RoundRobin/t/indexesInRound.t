#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 13;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );
my $t = Games::League::Member->new( index => 3, name => 'Them' );

my $o = Games::Tournament::RoundRobin->new( v => 3, league => [ $m, $y, $i, $t ] );
is($o->size, 4, 'v=4, not 5');
is_deeply($o->indexesInRound(1), [ $y->index, $m->index, $t->index, $i->index ], 'leaguesize indexesInRound 1');
is_deeply($o->indexesInRound(2), [ $i->index, $t->index, $m->index, $y->index ], 'leaguesize indexesInRound 2');
is_deeply($o->indexesInRound(3), [ $t->index, $i->index, $y->index, $m->index ], 'leaguesize indexesInRound 3');

my $n = Games::Tournament::RoundRobin->new( v => 4, league => [ 0,1,2,3 ]);
is_deeply($n->indexesInRound(1), [1,0,3,2], '4/indexesInRound 1');
is_deeply($n->indexesInRound(2), [2,3,0,1], '4/indexesInRound 2');
is_deeply($n->indexesInRound(3), [3,2,1,0], '4/indexesInRound 3');

$n = Games::Tournament::RoundRobin->new( v => 19, league => [ 0..18 ]);
my $r = $n->indexesInRound(1);
is_deeply($r, [1,0,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2], '19/IndexesInRound 1');
$r = $n->indexesInRound(2);
is_deeply($r, [2,3,0,1,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4], '19/indexesInRound 2');
$r = $n->indexesInRound(3);
is_deeply($r, [3,5,4,0,2,1,19,18,17,16,15,14,13,12,11,10,9,8,7,6], '19/indexesInRound 3');
$r = $n->indexesInRound(17);
is_deeply($r, [17,14,13,12,11,10,9,8,7,6,5,4,3,2,1,19,18,0,16,15], '19/indexesInRound 17');
$r = $n->indexesInRound(18);
is_deeply($r, [18,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,19,0,17], '19/indexesInRound 18');
$r = $n->indexesInRound(19);
is_deeply($r, [19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0], '19/indexesInRound 19');
