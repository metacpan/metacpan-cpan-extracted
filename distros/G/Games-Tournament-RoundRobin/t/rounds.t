#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 4;

use Games::Tournament::RoundRobin;

my $t = Games::Tournament::RoundRobin->new( v => 5, league => [ 0 .. 3 ] );
is($t->rounds, 3, 'rounds=3, not 4 or 5');
$t = Games::Tournament::RoundRobin->new( league => [ 0 .. 13 ] );
is($t->rounds, 13, 'no v, but rounds = 13');
$t = Games::Tournament::RoundRobin->new( league => [ 0 .. 18 ] );
is($t->rounds, 19, 'league is [0..18], but rounds = 19');

use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );

$t = Games::Tournament::RoundRobin->new( v => 5, league => [ $m, $y, $i ] );
is($t->rounds, 3, 'v=4, not 5');

