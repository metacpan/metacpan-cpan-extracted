#!usr/bin/perl

# http://rt.cpan.org/Ticket/Display.html?id=29495
# workout for C10
# similar, but not the same (?), as 5th round of 
# http://www.lsvmv.de/turniere/erg/eon_2007a_paar.htm
# in 29682_2.t
# http://chesschat.org/showpost.php?p=172088&postcount=42
# http://chesschat.org/showpost.php?p=172097&postcount=44
# http://chesschat.org/showpost.php?p=172124&postcount=45
# http://chesschat.org/showthread.php?p=294907#post294907

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

my @members = Load(<<'...');
---
id: 1
name: Zero
rating: 1000
title: Unknown
---
id: 2
name: One
rating: 900
title: Unknown
---
id: 3
name: Two
rating: 800
title: Unknown
---
id: 4
name: Three
rating: 700
title: Unknown
---
id: 5
name: Four
rating: 600
title: Unknown
---
id: 6
name: Five
rating: 500
title: Unknown
---
id: 7
name: Six
rating: 400
title: Unknown
---
id: 8
name: Seven
rating: 300
title: Unknown
---
id: 9
name: Eight
rating: 200
title: Unknown
---
id: 10
name: Nine
rating: 100
title: Unknown
---
id: 11
name: Ten
rating: 100
title: Unknown
---
id: 12
name: Eleven
rating: 99
title: Unknown
---
id: 13
name: Twelve
rating: 95
title: Unknown
---
id: 14
name: Thirteen
rating: 90
title: Unknown
---
id: 15
name: Fourteen
rating: 85
title: Unknown
---
id: 16
name: Fifteen
rating: 80
title: Unknown
---
id: 17
name: Sixteen
rating: 75
title: Unknown
---
id: 18
name: Seventeen
rating: 70
title: Unknown
---
id: 19
name: Eighteen
rating: 65
title: Unknown
---
id: 20
name: Nineteen
rating: 60
title: Unknown
...

my @lineup
	= map { Games::Tournament::Contestant::Swiss->new(%$_) } @members;

my $tourney = Games::Tournament::Swiss->new( entrants => \@lineup);

my $round = 4;
$tourney->round($round);
$tourney->assignPairingNumbers;
$tourney->initializePreferences;
$tourney->initializePreferences until $lineup[0]->preference->role eq 'White';

my @ids = map { $_->{pairingNumber} } @lineup;
my $pairingtable = Load(<<'...');
---
floats:
  1:  [~,Up]
  10: [~,~]
  11: [~,~]
  12: [Down,Up]
  13: [~,~]
  14: [~,~]
  15: [~,~]
  16: [~,~]
  17: [Down,~]
  18: [Up,~]
  19: [Up,~]
  2:  [~,~]
  20: [~,Down]
  3:  [Up,~]
  4:  [~,~]
  5:  [~,~]
  6:  [~,~]
  7:  [~,~]
  8:  [~,Down]
  9:  [~,~]
opponents:
  1:  [11,10,6,8]
  10: [20,1,15,16]
  11: [1,12,16,3]
  12: [2,11,19,20]
  13: [3,18,5,19]
  14: [4,17,20,18]
  15: [5,20,10,6]
  16: [6,19,11,10]
  17: [7,14,18,4]
  18: [8,13,17,14]
  19: [9,16,12,13]
  2:  [12,7,9,5]
  20: [10,15,14,12]
  3:  [13,6,8,11]
  4:  [14,9,7,17]
  5:  [15,8,13,2]
  6:  [16,3,1,15]
  7:  [17,2,4,9]
  8:  [18,5,3,1]
  9:  [19,4,2,7]
roles:
  1:  [White,Black,White,Black]
  10: [Black,White,Black,White]
  11: [Black,White,Black,White]
  12: [White,Black,White,Black]
  13: [Black,White,Black,White]
  14: [White,Black,White,Black]
  15: [Black,White,White,Black]
  16: [White,Black,White,Black]
  17: [Black,White,Black,Black]
  18: [White,Black,White,White]
  19: [Black,White,Black,Black]
  2:  [Black,White,Black,White]
  20: [White,Black,Black,White]
  3:  [White,Black,White,Black]
  4:  [Black,White,Black,White]
  5:  [White,Black,White,Black]
  6:  [Black,White,Black,White]
  7:  [White,Black,White,Black]
  8:  [Black,White,Black,White]
  9:  [White,Black,White,White]
score:
  1: 3
  10: 1.5
  11: 2
  12: 1
  13: 2
  14: 0
  15: 2
  16: 2.5
  17: 2.5
  18: 1
  19: 1
  2: 2.5
  20: 1.5
  3: 2
  4: 2.5
  5: 2.5
  6: 2
  7: 2.5
  8: 3.5
  9: 2.5
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
	    contestants => { $role => $player, $opponentRole => $opponent} );
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
$tourney->round(5);

# Round 5:  8 (3.5), 1 (3), 2 4 5 7 9 16 17 (2.5), 3 6 11 13 15 (2), 10 20 (1.5), 12 18 19 (1), 14 (0),

my @tests = (
[ $m{2.5}->[0]->isa('Games::Tournament::Card'),	'$m2.5 isa'],
[ $m{2.5}->[1]->isa('Games::Tournament::Card'),	'$m2.5 isa'],
[ $m{'2.5Remainder'}->[0]->isa('Games::Tournament::Card'),	'$m2.5R isa'],
[ $m{'2.5Remainder'}->[1]->isa('Games::Tournament::Card'),	'$m2.5R isa'],
[ $m{'2'}->[0]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{'2Remainder'}->[0]->isa('Games::Tournament::Card'),	'$m2R isa'],
[ $m{'2Remainder'}->[1]->isa('Games::Tournament::Card'),	'$m2R isa'],
[ $m{1}->[0]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{1}->[1]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
);

push @tests,
[ $lineup[6],	$m{2.5}->[0]->contestants->{White},	'$m2.5 White'],
[ $lineup[7],	$m{2.5}->[0]->contestants->{Black},	'$m2.5 Black'],
[ $lineup[0],	$m{2.5}->[1]->contestants->{White},	'$m2.5 White'],
[ $lineup[1],	$m{2.5}->[1]->contestants->{Black},	'$m2.5 Black'],
[ $lineup[4],	$m{'2.5Remainder'}->[0]->contestants->{White},	'$m2.5R White'],
[ $lineup[3],	$m{'2.5Remainder'}->[0]->contestants->{Black},	'$m2.5R Black'],
[ $lineup[16],	$m{'2.5Remainder'}->[1]->contestants->{White},	'$m2.5R White'],
[ $lineup[8],	$m{'2.5Remainder'}->[1]->contestants->{Black},	'$m2.5R Black'],
[ $lineup[15],	$m{'2'}->[0]->contestants->{White},	'2 White'],
[ $lineup[12],	$m{'2'}->[0]->contestants->{Black},	'2 Black'],
[ $lineup[2],	$m{'2Remainder'}->[0]->contestants->{White},	'2R-0 White'],
[ $lineup[14],	$m{'2Remainder'}->[0]->contestants->{Black},	'2R-0 Black'],
[ $lineup[10],	$m{'2Remainder'}->[1]->contestants->{White},	'2R-1 White'],
[ $lineup[5],	$m{'2Remainder'}->[1]->contestants->{Black},	'2R-1 Black'],
[ $lineup[9],	$m{1}->[0]->contestants->{White},	'1-0 White,was id 12!'],
[ $lineup[17],	$m{1}->[0]->contestants->{Black},	'1-0 Black,was id 10!'],
[ $lineup[18],	$m{1}->[1]->contestants->{White},	'1-1 White,was id 20!'],
[ $lineup[19],	$m{1}->[1]->contestants->{Black},	'1-1 Black,was id 18!'],
[ $lineup[11],	$m{0}->[0]->contestants->{White},	'$m0 White,was id 19!'],
[ $lineup[13],	$m{0}->[0]->contestants->{Black},	'$m0 Black'],
;

plan tests => $#tests + 1;

ok( $_->[0], $_->[ 1, ], ) for @tests[0..9];
is_deeply( $_->[0], $_->[ 1, ], $_->[ 2, ], ) for @tests[10..$#tests];

# vim: set ts=8 sts=4 sw=4 noet:
