#!/usr/bin/perl 

# Last Edit: 2006  2月 10, 20時19分34秒
# $Id$

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 8;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );
my $u = Games::League::Member->new( index => 3, name => 'Us' );
my $yy = Games::League::Member->new( index => 4, name => 'Youall' );
my $t = Games::League::Member->new( index => 5, name => 'Them' );

my $o = Games::Tournament::RoundRobin->new( v => 6, league => [ qw/Me You It Us Youall Them/ ] );
is($o->partner($m,3), $u, 'stringleague no dupes: partner Me, 3');
is($o->partner($yy,4), $m, 'stringleague no dupes: partner Youall, 5');

$o = Games::Tournament::RoundRobin->new( v => 5 );
is($o->partner(1,3), 5, 'numberleague no dupes: partner 1, 3');

$o = Games::Tournament::RoundRobin->new( v => 6, league => [ qw/Me You It Us You Them/ ] );
is($o->partner('Them',1), 'It', 'stringleague, dupes: partner 1');
is($o->partner('Me',2), 'It', 'stringleague, dupes: partner 1');
is($o->partner('Us',2), 'You', 'stringleague, dupes: partner 1');

$o = Games::Tournament::RoundRobin->new( v => 6, league => [ $m, $y, $i, $u, $yy, $t ] );
is($o->partner($yy,5), $y, 'object league, no dupes: partner 1');

$yy = Games::League::Member->new( index => 4, name => 'You' );
$o = Games::Tournament::RoundRobin->new( v => 6, league => [ $m, $y, $i, $u, $yy, $t ] );
is($o->partner($m,1), $y, 'objectleague, dupes: partner 1');
