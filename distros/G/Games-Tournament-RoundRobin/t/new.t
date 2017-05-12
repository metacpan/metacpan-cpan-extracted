#!/usr/bin/perl 

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 17;

use Games::Tournament::RoundRobin;

my $t = Games::Tournament::RoundRobin->new( v => 3 );
is($t->size, 4, 'v=3->4, no league');
$t = Games::Tournament::RoundRobin->new( v => 5, league => [ 0 .. 3 ] );
is($t->size, 4, 'v=4, not 5');
is_deeply($t->{league}, [ 0 .. 3 ], 'no league, v=3->4, league -> [0..3]');
$t = Games::Tournament::RoundRobin->new( league => [ 0 .. 3 ] );
is($t->size, 4, 'no v, v=4');
is_deeply($t->{league}, [ 0 .. 3 ], 'league is [0..3]');

is(Games::Tournament::RoundRobin->new( v => 3, league => [qw/Me You It/])->size, 4, 'v=3->4, with league array of strings');
is_deeply(Games::Tournament::RoundRobin->new( v => 3, league => [qw/Me You It/])->{league}, [qw/Me You It Bye/], 'members, with league array of strings');
is(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 0, You => 1, It => 2 } )->size, 4, 'members: hash with numerical values');
is_deeply (Games::Tournament::RoundRobin->new( v => 5, league => { Me => 0, You => 1, It => 2 } )->{league}, [ 2, 0, 1, 3], 'hash with numerical values');
is(Games::Tournament::RoundRobin->new( v => 5, league => { Me => 'Me', You => 'You', It => 'It' } )->size, 4, 'size: hash with string values');
is_deeply (Games::Tournament::RoundRobin->new( v => 5, league => { Me => 'Me', You => 'You', It => 'It' } )->{league}, [qw/It Me You Bye/], 'hash with string values');

$t = Games::Tournament::RoundRobin->new( v => 7, league => [ qw/I You He Me It She They/] );
is($t->size, 8, 'v=7->8');
is_deeply($t->{league}, [ qw/I You He Me It She They Bye/], 'league is I,You..They scalarlist');

use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );

$t = Games::Tournament::RoundRobin->new( v => 5, league => [ $m, $y, $i ] );
is($t->size, 4, 'v=4, not 5');
# is_deeply($t->{league}, [ $m, $y, $i ], 'league is [ $m, $y, $i ]');
# is_deeply($t->{league}, [ qw/Me You It/ ], 'league is [ $m, $y, $i ]');
is_deeply($t->{league}, [ qw/Me You It Bye/ ], 'league is [ $m, $y, $i, (Bye) ]');

$t = Games::Tournament::RoundRobin->new( v => 5, league => { Me => $m, You => $y, It => $i } );
is($t->size, 4, 'v=4, not 5');
# is_deeply($t->{league}, [ $m, $y, $i ], 'league is [ $m, $y, $i ]');
# is_deeply($t->{league}, [ qw/Me You It/ ], 'league is [ $m, $y, $i ]');
is_deeply($t->{league}, [ qw/Me You It Bye/ ], 
					'league is { $m, $y, $i, (Bye) }');

