#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 3;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );
my $t = Games::League::Member->new( index => 3, name => 'Them' );

my $o = Games::Tournament::RoundRobin->new( v => 3, league => [ $m, $y, $i, $t ] );
is_deeply($o->roundsInTournament, [ [1,0,3,2],[2,3,0,1],[3,2,1,0] ], 'roundsInTournament with hash of objects');

$o = Games::Tournament::RoundRobin->new( v => 4, league => [ 0,1,2,3 ]);
is_deeply($o->roundsInTournament, [ [1,0,3,2],[2,3,0,1],[3,2,1,0] ], 'roundsInTournament with array of numbers');

$o = Games::Tournament::RoundRobin->new( v => 19, league => [ 0..18 ]);
my $r = $o->roundsInTournament;
is_deeply($r, [
[1,0,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2],
[2,3,0,1,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4],
[3,5,4,0,2,1,19,18,17,16,15,14,13,12,11,10,9,8,7,6],
[4,7,6,5,0,3,2,1,19,18,17,16,15,14,13,12,11,10,9,8],
[5,9,8,7,6,0,4,3,2,1,19,18,17,16,15,14,13,12,11,10],
[6,11,10,9,8,7,0,5,4,3,2,1,19,18,17,16,15,14,13,12],
[7,13,12,11,10,9,8,0,6,5,4,3,2,1,19,18,17,16,15,14],
[8,15,14,13,12,11,10,9,0,7,6,5,4,3,2,1,19,18,17,16],
[9,17,16,15,14,13,12,11,10,0,8,7,6,5,4,3,2,1,19,18],
[10,19,18,17,16,15,14,13,12,11,0,9,8,7,6,5,4,3,2,1],
[11,2,1,19,18,17,16,15,14,13,12,0,10,9,8,7,6,5,4,3],
[12,4,3,2,1,19,18,17,16,15,14,13,0,11,10,9,8,7,6,5],
[13,6,5,4,3,2,1,19,18,17,16,15,14,0,12,11,10,9,8,7],
[14,8,7,6,5,4,3,2,1,19,18,17,16,15,0,13,12,11,10,9],
[15,10,9,8,7,6,5,4,3,2,1,19,18,17,16,0,14,13,12,11],
[16,12,11,10,9,8,7,6,5,4,3,2,1,19,18,17,0,15,14,13],
[17,14,13,12,11,10,9,8,7,6,5,4,3,2,1,19,18,0,16,15],
[18,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,19,0,17],
[19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0],
],
'roundsInTournament with v = 19, array of numbers');
