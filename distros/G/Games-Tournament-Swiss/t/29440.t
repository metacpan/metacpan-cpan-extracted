#!usr/bin/perl

# http://rt.cpan.org/Ticket/Display.html?id=29440
# Relative criteria cannot force a downfloat to next bracket

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
use Games::Tournament::Card;

my $n = 20;
my ($one, $two, $three, $four, $five, $six, $seven, $eight, $nine, $ten, $eleven, $twelve, $thirteen, $fourteen, $fifteen, $sixteen, $seventeen, $eighteen, $nineteen, $twenty)
	= map { Games::Tournament::Contestant::Swiss->new(
	id => 21-$n, name => $_, rating => $n--, title => 'Nom') } ('A'..'T');
my @lineup =
   ($one, $two, $three, $four, $five, $six, $seven, $eight, $nine, $ten, $eleven, $twelve, $thirteen, $fourteen, $fifteen, $sixteen, $seventeen, $eighteen, $nineteen, $twenty);

my $tourney = Games::Tournament::Swiss->new( entrants => \@lineup);

my $round = 3;
$tourney->round($round);
$tourney->assignPairingNumbers;
$tourney->initializePreferences;
$tourney->initializePreferences until $lineup[0]->preference->role eq 'White';

my @ids = map { $_->{pairingNumber} } @lineup;
my $pairingtable = Load(<<'...');
---
floats:
  1: [Up,~]
  10: [~,~]
  11: [Down,~]
  12: [~,Up]
  13: [~,~]
  14: [~,~]
  15: [~,~]
  16: [~,~]
  17: [~,Down]
  18: [~,~]
  19: [~,~]
  2: [~,~]
  20: [~,~]
  3: [~,Up]
  4: [~,~]
  5: [~,~]
  6: [~,~]
  7: [~,~]
  8: [~,Down]
  9: [~,~]
opponents:
  1: [11,10,6]
  10: [20,1,15]
  11: [1,12,16]
  12: [2,11,17]
  13: [3,18,5]
  14: [4,17,19]
  15: [5,20,10]
  16: [6,19,11]
  17: [7,14,12]
  18: [8,13,20]
  19: [9,16,14]
  2: [12,7,9]
  20: [10,15,18]
  3: [13,6,8]
  4: [14,9,7]
  5: [15,8,13]
  6: [16,3,1]
  7: [17,2,4]
  8: [18,5,3]
  9: [19,4,2]
roles:
  1: [White,Black,White]
  10: [Black,White,Black]
  11: [Black,White,Black]
  12: [White,Black,White]
  13: [Black,White,Black]
  14: [White,Black,White]
  15: [Black,White,White]
  16: [White,Black,White]
  17: [Black,White,Black]
  18: [White,Black,White]
  19: [Black,White,Black]
  2: [Black,White,Black]
  20: [White,Black,Black]
  3: [White,Black,White]
  4: [Black,White,Black]
  5: [White,Black,White]
  6: [Black,White,Black]
  7: [White,Black,White]
  8: [Black,White,Black]
  9: [White,Black,White]
score:
  1: 2.5
  10: 1.5
  11: 1.5
  12: 0.5
  13: 1
  14: 0
  15: 1.5
  16: 1.5
  17: 2
  18: 0
  19: 1
  2: 2
  20: 1
  3: 1.5
  4: 2
  5: 2
  6: 1.5
  7: 2
  8: 3
  9: 2
...

my ( $opponents, $roles, $floats, $score ) = 
    @$pairingtable{qw/opponents roles floats score/};
for my $player ( @lineup )
{
    my $id = $player->id;
    $player->score( $score->{$id} );
}
my $lastround = $round;
for my $round ( 1..$lastround )
{
   my (%games, @games);
   for my $id ( @ids )
   {
	next if $games{$id};
	my $player = $tourney->ided($id);
	my $opponentId = $opponents->{$id}->[$round-1];
	my $opponent = $tourney->ided($opponentId);
	my $role = $roles->{$id}->[$round-1];
	my $opponentRole = $roles->{$opponentId}->[$round-1];
	my $game = Games::Tournament::Card->new(
	    round => $round,
	    contestants => { $role => $player, $opponentRole => $opponent},
	    # result => { $role => 'Win', $opponentRole => 'Loss' }
	    );
        if ($round >= $lastround-1)
        {
	    my $float = $floats->{$id}->[$round-$lastround-1];
	    my $opponentFloat = $floats->{$opponent}->[$round-$lastround-1];
	    $game->float($player, $float);
	    $game->float($opponent, $opponentFloat);
        }
        $games{$id} = $game;
        $games{$opponentId} = $game;
        push @games, $game;
   }
   local $SIG{__WARN__} = sub {};
   $tourney->collectCards( @games );
}

my %b = $tourney->formBrackets;
my $pairing  = $tourney->pairing( \%b );
my $p        = $pairing->matchPlayers;
my %m = map { $_ => $p->{matches}->{$_} } keys %{ $p->{matches} };
$tourney->round($round+1);

#Round 4:  8 (3), 1 (2.5), 2 4 5 7 9 17 (2), 3 6 10 11 15 16 (1.5), 13 19 20 (1), 12 (0.5), 14 18 (0),

my @tests = (
[ $m{2.5}->[0]->isa('Games::Tournament::Card'),	'$m2.5 isa'],
[ $m{2}->[0]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{2}->[1]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{2}->[2]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{1.5}->[0]->isa('Games::Tournament::Card'),	'$m1.5 isa'],
[ $m{1.5}->[1]->isa('Games::Tournament::Card'),	'$m1.5 isa'],
[ $m{1.5}->[2]->isa('Games::Tournament::Card'),	'$m1.5 isa'],
[ $m{1}->[0]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{0.5}->[0]->isa('Games::Tournament::Card'),	'$m0.5 isa'],
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
);

push @tests,
[ $eight,	$m{2.5}->[0]->contestants->{White},	'$m2.5 White'],
[ $one,	$m{2.5}->[0]->contestants->{Black},	'$m2.5 Black'],
[ $two,	$m{2}->[0]->contestants->{White},	'$m2 White'],
[ $five,	$m{2}->[0]->contestants->{Black},	'$m2 Black'],
[ $four,	$m{2}->[1]->contestants->{White},	'$m21 White'],
[ $seventeen,	$m{2}->[1]->contestants->{Black},	'$m21 Black'],
[ $nine,	$m{2}->[2]->contestants->{White},	'$m22 White'],
[ $seven,	$m{2}->[2]->contestants->{Black},	'$m22 Black'],
[ $eleven,	$m{1.5}->[0]->contestants->{White},	'$m15 White'],
[ $three,	$m{1.5}->[0]->contestants->{Black},	'$m15 Black'],
[ $six,	$m{1.5}->[1]->contestants->{White},	'$m151 White'],
[ $fifteen,	$m{1.5}->[1]->contestants->{Black},	'$m151 Black'],
[ $ten,	$m{1.5}->[2]->contestants->{White},	'$m152 White'],
[ $sixteen,	$m{1.5}->[2]->contestants->{Black},	'$m152 Black'],
[ $thirteen,	$m{1}->[0]->contestants->{White},	'$m1 White'],
[ $nineteen,	$m{1}->[0]->contestants->{Black},	'$m1 Black'],
[ $twenty,	$m{0.5}->[0]->contestants->{White},	'$m05 White'],
[ $twelve,	$m{0.5}->[0]->contestants->{Black},	'$m05 Black'],
[ $eighteen,	$m{0}->[0]->contestants->{White},	'$m0 White'],
[ $fourteen,	$m{0}->[0]->contestants->{Black},	'$m0 Black'],
;

plan tests => $#tests + 1;

ok( $_->[0], $_->[ 1, ], ) for @tests[0..9];
is( $_->[0], $_->[ 1, ], $_->[ 2, ], ) for @tests[10..$#tests];

# vim: set ts=8 sts=4 sw=4 noet:
