#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 18;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $t = Games::Tournament::RoundRobin->new( v => 4, league => [ 0,1,2,3 ]);
my $r = $t->meetings(0,[1,2,3]);
is_deeply($r, [1,2,3], 'meetings 0,[1,2,3]');
$r = $t->meetings(1,[0,2,3]);
is_deeply($r, [1,3,2], 'meetings 1,[0,2,3]');
$r = $t->meetings(2,[0,1,3]);
is_deeply($r, [2,3,1], 'meetings 2,[0,1,3]');
$r = $t->meetings(3,[0,1,2]);
is_deeply($r, [3,2,1], 'meetings 3,[0,1,2]');

$t = Games::Tournament::RoundRobin->new( v => 4, league => [ qw/ zero one two three / ]);
$r = $t->meetings('zero',[qw/one two three/]);
is_deeply($r, [1,2,3], 'meetings zero,[qw/one two three/]');
$r = $t->meetings('one',[qw/zero two three/]);
is_deeply($r, [1,3,2], 'meetings one,[qw/zero two three/]');
$r = $t->meetings('two',[qw/zero one three/]);
is_deeply($r, [2,3,1], 'meetings two,[qw/zero one three/]');
$r = $t->meetings('three',[qw/zero one two/]);
is_deeply($r, [3,2,1], 'meetings three,[qw/zero one two/]');

$t = Games::Tournament::RoundRobin->new( v => 19, league => [ 0..18 ]);
$r = $t->meetings(1,[0,11]);
is_deeply($r, [1,6], '19/meetings 1,[0,11]');
$r = $t->meetings(2,[19,10]);
is_deeply($r, [1,6], '19/meetings 2,[19,10]');
$r = $t->meetings(3,[5,9]);
is_deeply($r, [4,6], '19/meetings 3,[5,9]');
$r = $t->meetings(17,[18,16]);
is_deeply($r, [8,7], '19/meetings 17,[18,16]');
$r = $t->meetings(18,[12,15]);
is_deeply($r, [15,7], '19/meetings 18,[12,15]');
$r = $t->meetings(19,[4,14]);
is_deeply($r, [2,7], '19/meetings 19,[4,14]');

use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );

$t = Games::Tournament::RoundRobin->new( league => [ $m, $y, $i ] );
my $meetings = $t->meetings( $m, [$y, $i]);
is_deeply($meetings, [1,2], 'meeting: array of objects');
my $bye = $t->member(3);
is_deeply($t->meetings($bye,[$m,$y,$i]), [3,2,1], 'league is [ $m, $y, $i, ($bye) ]');

$t = Games::Tournament::RoundRobin->new( v => 5, league => { Me => $m, You => $y, It => $i } );
$meetings = $t->meetings( $m, [$y, $i]);
is_deeply($meetings, [1,2], 'meeting: hash of objects');
$bye = $t->member(3);
is_deeply($t->meetings($bye,[$m,$y,$i]), [3,2,1], 'league is { $m, $y, $i, ($bye) }');
# # is_deeply($t->{league}, [ $m, $y, $i ], 'league is [ $m, $y, $i ]');
# # is_deeply($t->{league}, [ qw/Me You It/ ], 'league is [ $m, $y, $i ]');
# is_deeply($t->{league}, { Me => 'Me', You => 'You', It => 'It', Bye => 'Bye' }, 
# 					'league is { $m, $y, $i, (Bye) }');
# 
