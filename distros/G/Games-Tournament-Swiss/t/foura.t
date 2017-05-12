#!usr/bin/perl

# White-winning, 4 players, all 3 rounds

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;
use YAML;

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    @Games::Tournament::Swiss::Config::roles      = qw/White Black/;
    %Games::Tournament::Swiss::Config::scores      = (
    Win => 1, Draw => 0.5, Loss => 0, Absence => 0, Bye => 1 );
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::FIDE';
}
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;
use Games::Tournament::Swiss::Bracket;

my @members = Load(<<'...');
---
id: 1
name: A
rating: 12
title: Unknown
---
id: 2
name: B
rating: 8
title: Unknown
---
id: 3
name: C
rating: 4
title: Unknown
---
id: 4
name: D
rating: 1
title: Unknown
...

my ($a, $b, $c, $d)
	= map { Games::Tournament::Contestant::Swiss->new(%$_) } @members;

my $t = Games::Tournament::Swiss->new(
    rounds   => 3,
    entrants => [ $a, $b, $c, $d ]
);

my $bracket = Games::Tournament::Swiss::Bracket->new( score => 1,
			members => [ $a, $b, $c, $d ]);

$t->round(0);
$t->assignPairingNumbers;
$t->initializePreferences;
$t->initializePreferences until $a->preference->role eq 'White';

my %b = $t->formBrackets;
my $pairing  = $t->pairing( \%b );
my $p        = $pairing->matchPlayers;
my %m = map { $_ => $p->{matches}->{$_} } keys %{ $p->{matches} };
$t->round(1);

# Round 1:  1 2 3 4 (0),

my @tests = (
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
[ $m{0}->[1]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $a == $m{0}->[0]->contestants->{White},	'$m0 White'],
[ $c == $m{0}->[0]->contestants->{Black},	'$m0 Black'],
[ $b == $m{0}->[1]->contestants->{Black},	'$m1 Black'],
[ $d == $m{0}->[1]->contestants->{White},	'$m1 White'],
);

$m{0}->[0]->result({Black => 'Loss', White => 'Win' });
$m{0}->[1]->result({Black => 'Loss', White => 'Win' });

$t->collectCards( map {@$_} values %m );
my %b2 = $t->formBrackets;
my $pair2  = $t->pairing( \%b2 );
my $p2        = $pair2->matchPlayers;
my %m2 = map { $_ => $p2->{matches}->{$_} } keys %{ $p2->{matches} };
$t->round(2);

# Round 2:  1 4 (1), 2 3 (0),

push @tests, (
[ $m2{1}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $m2{0}->[0]->isa('Games::Tournament::Card'),	'@m2 isa'],
[ $d == $m2{1}->[0]->contestants->{White},	'@m2 White1'],
[ $a == $m2{1}->[0]->contestants->{Black},	'@m2 Black1'],
[ $b == $m2{0}->[0]->contestants->{White},	'@m2 White0'],
[ $c == $m2{0}->[0]->contestants->{Black},	'@m2 Black0'],
);

$m2{1}->[0]->result({Black => 'Loss', White => 'Win' });
$m2{0}->[0]->result({Black => 'Loss', White => 'Win' });

$t->collectCards( map {@$_} values %m2 );

my %b3 = $t->formBrackets;
my $pair3 = $t->pairing( \%b3 );
my $p3 = $pair3->matchPlayers;
my %m3 = map { $_ => $p3->{matches}->{$_} } keys %{ $p3->{matches} };
$t->round(3);

# Round 3:  4 (2), 1 2 (1), 3 (0),

push @tests, (
[ $m3{1}->[0]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $m3{0}->[0]->isa('Games::Tournament::Card'),	'@m3 isa'],
[ $a == $m3{1}->[0]->contestants->{White},	'@m3 White0'],
[ $b == $m3{1}->[0]->contestants->{Black},	'@m3 Black0'],
[ $c == $m3{0}->[0]->contestants->{White},	'@m3 White1'],
[ $d == $m3{0}->[0]->contestants->{Black},	'@m3 Black1'],
);

plan tests => $#tests + 1;

ok( $_->[0], $_->[ 1, ], ) for @tests;
