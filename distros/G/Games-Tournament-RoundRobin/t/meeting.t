#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 19;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $t = Games::Tournament::RoundRobin->new( v => 4, league => [ 0,1,2,3 ]);
my $r = $t->meeting(0,1);
is($r, 1, 'meeting 0,1');
$r = $t->meeting(1,2);
is($r, 3, 'meeting 1,2');
$r = $t->meeting(2,3);
is($r, 1, 'meeting 2,3');
$r = $t->meeting(3,0);
is($r, 3, 'meeting 3,0');

$t = Games::Tournament::RoundRobin->new( v => 4, league => [ qw/ zero one two three / ]);
$r = $t->meeting('zero','one');
is($r, 1, 'meeting zero,one');
$r = $t->meeting('one','two');
is($r, 3, 'meeting one,two');
$r = $t->meeting('two','three');
is($r, 1, 'meeting two,three');
$r = $t->meeting(qw/three one/);
is($r, 2, 'meeting three,one');

$t = Games::Tournament::RoundRobin->new( v => 19, league => [ 0..18 ]);
$r = $t->meeting(1,11);
is($r, 6, '19/meetings 1,11');
$r = $t->meeting(2,19);
is($r, 1, '19/meetings 2,19');
$r = $t->meeting(3,5);
is($r, 4, '19/meetings 3,5');
$r = $t->meeting(17,18);
is($r, 8, '19/meetings 17,18');
$r = $t->meeting(18,12);
is($r, 15, '19/meetings 18,12');
$r = $t->meeting(19,17);
is($r, 18, '19/meetings 19,17');

is( Games::Tournament::RoundRobin->new( league =>{ Me => 'Me', You => 'You', It => 'It', Bye => 'Bye' })->meeting(qw/Me You/), 1, 'meeting: hash of scalars');

use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );

$t = Games::Tournament::RoundRobin->new( league => [ $m, $y, $i ] );
my $meeting = $t->meeting( $m, $y);
is($meeting, 1, 'meeting: array of objects');
my $bye = $t->member(3);
is($t->meeting($bye, $y), 2, 'league is [ $m, $y, $i, ($bye) ]');

$t = Games::Tournament::RoundRobin->new( v => 5, league => { Me => $m, You => $y, It => $i } );
$meeting = $t->meeting( $y, $i);
is($meeting, 3, 'meeting: hash of objects');
$bye = $t->member(3);
is($t->meeting($bye, $i), 1, 'league is { $m, $y, $i, ($bye) }');
