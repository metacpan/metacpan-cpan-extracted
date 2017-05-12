#!/usr/bin/perl 

# Last Edit: 2006  2月 07, 18時16分49秒
# $Id$

use lib qw/t lib/;
use strict;
use warnings;
use Test::More tests => 4;

use Games::Tournament::RoundRobin;
use Games::League::Member;

my $m = Games::League::Member->new( index => 0, name => 'Me' );
my $y = Games::League::Member->new( index => 1, name => 'You' );
my $i = Games::League::Member->new( index => 2, name => 'It' );
my $u = Games::League::Member->new( index => 3, name => 'Us' );
my $yy = Games::League::Member->new( index => 4, name => 'Youall' );
my $t = Games::League::Member->new( index => 5, name => 'Them' );

my $o = Games::Tournament::RoundRobin->new( v => 6, league => [ qw/Me You It Us Youall Them/ ] );
is_deeply($o->membersInRound(1), {Me => 'You', You => 'Me', It => 'Them', Us => 'Youall', Youall => 'Us', Them => 'It'}, 'stringleague no dupes: membersInRound 1');

$o = Games::Tournament::RoundRobin->new( v => 6, league => [ qw/Me You It Us You Them/ ] );
is_deeply($o->membersInRound(1), {Me => 'You', You1 => 'Me', It => 'Them', Us => 'You', You2 => 'Us', Them => 'It'}, 'stringleague, dupes: membersInRound 1');

$o = Games::Tournament::RoundRobin->new( v => 6, league => [ $m, $y, $i, $u, $yy, $t ] );
is_deeply($o->membersInRound(1), {Me => $y, You => $m, It => $t, Us => $yy, Youall => $u, Them => $i}, 'object league, no dupes: membersInRound 1');

$yy = Games::League::Member->new( index => 4, name => 'You' );
$o = Games::Tournament::RoundRobin->new( v => 6, league => [ $m, $y, $i, $u, $yy, $t ] );
is_deeply($o->membersInRound(1), {Me => $y, You1 => $m, It => $t, Us => $yy, You2 => $u, Them => $i}, 'objectleague, dupes: membersInRound 1');
