#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 21;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $t = Games::Tournament::RoundRobin->new( v => 4, league => [ 0,1,2,3 ]);

is_deeply($t->partners(0), [1,2,3], 'partners 0');
is_deeply($t->partners(1), [0,2,3], 'partners 0');
is_deeply($t->partners(2), [0,1,3], 'partners 0');
is_deeply($t->partners(3), [0,1,2], 'partners 0');

$t = Games::Tournament::RoundRobin->new( v => 19, league => [ 0..18 ]);

is_deeply($t->partners(0), [1..18,19], 'partners 0');
is_deeply($t->partners(1), [0,2..18,19], 'partners 1');
is_deeply($t->partners(2), [0,1,3..18,19], 'partners 2');
is_deeply($t->partners(10), [0..9,11..18,19], 'partners 10');
is_deeply($t->partners(17), [0..16,18,19], 'partners 17');
is_deeply($t->partners(18), [0..17,19], 'partners 18');
is_deeply($t->partners(19), [0..18], 'partners 19');

is_deeply(Games::Tournament::RoundRobin->new( v => 3, league => [qw/It Me You/])->partners('2'), [qw/It Me Bye/], 'partners($index), with league array of strings');
is_deeply(Games::Tournament::RoundRobin->new( v => 3, league => [qw/It Me You/])->partners('Bye'), [qw/It Me You/], 'partners($name), with league array of strings');

is_deeply(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 0, You => 1, It => 2 } )->partners(1), [2,1,3], 'partners($index): hash with numerical values');
TODO: { local $TODO = 'Discarded key, no way to find member($name)';
is_deeply(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 0, You => 1, It => 2 } )->partners('Me'), [2,1,'Bye'], 'partners($name): hash with numerical values');
}

is_deeply(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 'Me', You => 'You', It => 'It' } )->partners(3), [qw/It Me You/], 'partners($index): hash with string values');
is_deeply(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 'Me', You => 'You', It => 'It' } )->partners('Me'), [qw/It You Bye/], 'partners($name): hash with string values');

use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );

$t = Games::Tournament::RoundRobin->new( league => [ $m, $y, $i ] );
my $bye = $t->member(3);
is_deeply($t->partners(1), [$m,$i,$bye], 'partners($index): array of objects');
is_deeply($t->partners('Bye'),[$m,$y,$i], 'partners($name): array of objects');

my $u = Games::League::Member->new( index => 3, name => 'Us' );
my $a = Games::League::Member->new( index => 4, name => 'All' );
$t = Games::Tournament::RoundRobin->new( v => 5, league => { Me => $m, You => $y, It => $i, Us => $u, All => $a } );
is_deeply( $t->partners(5), [$m,$y,$i,$u,$a], 'partners($index): hash of objects');
$bye = $t->member(5);
is_deeply($t->partners('Bye'), [$m,$y,$i,$u,$a], 'partners($name): hash of objects');
