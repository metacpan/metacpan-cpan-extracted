#!usr/bin/perl

# http://rt.cpan.org/Ticket/Display.html?id=29682
# the real pairings
# http://www.lsvmv.de/turniere/erg/eon_2007a_paar.htm
# http://chesschat.org/showpost.php?p=172088&postcount=42
# http://chesschat.org/showpost.php?p=172097&postcount=44
# http://chesschat.org/showpost.php?p=172124&postcount=45
 
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
my ($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14,$p15,$p16,$p17,$p18,$p19,$p20)
	= map { Games::Tournament::Contestant::Swiss->new(
	id => $_, name => chr($_+64), rating => 2000-$_, title => 'Nom') }
	    (1..20);
my @lineup =
($p1,$p2,$p3,$p4,$p5,$p6,$p7,$p8,$p9,$p10,$p11,$p12,$p13,$p14,$p15,$p16,$p17,$p18,$p19,$p20);

my $tourney = Games::Tournament::Swiss->new( entrants => \@lineup);

my $round = 0;
$tourney->round($round);
$tourney->assignPairingNumbers;
$tourney->initializePreferences;
$tourney->initializePreferences until $lineup[0]->preference->role eq 'White';

my @ids = map { $_->{pairingNumber} } @lineup;
my $pairingtable = Load(<<'...');
---
floats:
  1:  [~,Up,~,Up]
  10: [~,Down,~,~]
  11: [~,Down,~,~]
  12: [~,Up,Up,Up]
  13: [~,~,~,~]
  14: [~,~,~,~]
  15: [~,~,~,~]
  16: [~,~,~,~]
  17: [~,~,Down,~]
  18: [~,~,~,~]
  19: [~,~,~,~]
  2:  [~,~,~,~]
  20: [~,~,~,Down]
  3:  [~,~,Up,~]
  4:  [~,~,~,~]
  5:  [~,~,~,~]
  6:  [~,~,~,~]
  7:  [~,~,~,~]
  8:  [~,~,~,Down]
  9:  [~,~,~,~]
opponents:
  1: [11,10,6,8]
  10: [20,1,15,16]
  11: [1,12,16,3]
  12: [2,11,17,20]
  13: [3,18,5,19]
  14: [4,17,19,18]
  15: [5,20,10,6]
  16: [6,19,11,10]
  17: [7,14,12,4]
  18: [8,13,20,14]
  19: [9,16,14,13]
  2: [12,7,9,5]
  20: [10,15,18,12]
  3: [13,6,8,11]
  4: [14,9,7,17]
  5: [15,8,13,2]
  6: [16,3,1,15]
  7: [17,2,4,9]
  8: [18,5,3,1]
  9: [19,4,2,7]
roles:
  1: [White,Black,White,Black]
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
  2: [Black,White,Black,White]
  20: [White,Black,Black,White]
  3: [White,Black,White,Black]
  4: [Black,White,Black,White]
  5: [White,Black,White,Black]
  6: [Black,White,Black,White]
  7: [White,Black,White,Black]
  8: [Black,White,Black,White]
  9: [White,Black,White,White]
score:
  1: [0.5,1.5,2.5,3]
  10: [1,1,1.5,1.5]
  11: [0.5,1,1.5,2]
  12: [0,0.5,0.5,1]
  13: [0,1,1,2]
  14: [0,0,0,0]
  15: [0,1,1.5,2]
  16: [0,1,1.5,2.5]
  17: [0,1,2,2.5]
  18: [0,0,0,1]
  19: [0,0,1,1]
  2: [1,1.5,2,2.5]
  20: [0,0,1,1.5]
  3: [1,1.5,1.5,2]
  4: [1,1.5,2,2.5]
  5: [1,1,2,2.5]
  6: [1,1.5,1.5,2]
  7: [1,1.5,2,2.5]
  8: [1,2,3,3.5]
  9: [1,1.5,2,2.5]
...

my ( $opponents, $roles, $floats, $score ) = 
    @$pairingtable{qw/opponents roles floats score/};

my %m;
my $runRound = sub {
    undef %m;
    my %opponents = map { $_ => $opponents->{$_}->[$round-1] } @ids;
    my %roles = map { $_ => $roles->{$_}->[$round-1] } @ids;
    my %floats = map { $_ => $floats->{$_}->[$round-1] } @ids;
    for my $player ( @lineup )
    {
	my $id = $player->id;
	$player->score( $score->{$id}->[$round-1] );
    }
    my @games = $tourney->recreateCards( {
       round => $round, opponents => \%opponents,
	roles => \%roles, floats => \%floats } );
    local $SIG{__WARN__} = sub {};
    $tourney->collectCards( @games );
    my %b = $tourney->formBrackets;
    my $pairing  = $tourney->pairing( \%b );
    my $p        = $pairing->matchPlayers;
    %m = map { $_ => $p->{matches}->{$_} } keys %{ $p->{matches} };
    $tourney->round($round+1);
};

my ( @okTests, @isTests );

$round = 1;

&$runRound; 
$round = 2;

push @okTests,
[ $m{1}->[0]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{1}->[1]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{1}->[2]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{1}->[3]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{0.5}->[0]->isa('Games::Tournament::Card'),	'$m05 isa'],
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
[ $m{'0Remainder'}->[0]->isa('Games::Tournament::Card'),	'$m0R isa'],
[ $m{'0Remainder'}->[1]->isa('Games::Tournament::Card'),	'$m0R isa'],
[ $m{'0Remainder'}->[2]->isa('Games::Tournament::Card'),	'$m0R isa'],
[ $m{'0Remainder'}->[3]->isa('Games::Tournament::Card'),	'$m0R isa'],
;


push @isTests,
[ $p2,	$m{1}->[0]->contestants->{White},	'$m1 White'],
[ $p7,	$m{1}->[0]->contestants->{Black},	'$m1 Black'],
[ $p6,	$m{1}->[1]->contestants->{White},	'$m1 White'],
[ $p3,	$m{1}->[1]->contestants->{Black},	'$m1 Black'],
[ $p4,	$m{1}->[2]->contestants->{White},	'$m1 White'],
[ $p9,	$m{1}->[2]->contestants->{Black},	'$m1 Black'],
[ $p8,	$m{1}->[3]->contestants->{White},	'$m1 White'],
[ $p5,	$m{1}->[3]->contestants->{Black},	'$m1 Black'],
[ $p10,	$m{0.5}->[0]->contestants->{White},	'$m05 White'],
[ $p1,	$m{0.5}->[0]->contestants->{Black},	'$m05 Black'],
[ $p11,	$m{0}->[0]->contestants->{White},	'$m0 White'],
[ $p12,	$m{0}->[0]->contestants->{Black},	'$m1 Black'],
[ $p13,	$m{'0Remainder'}->[0]->contestants->{White},	'$m0R White'],
[ $p18,	$m{'0Remainder'}->[0]->contestants->{Black},	'$m0R Black'],
[ $p17,	$m{'0Remainder'}->[1]->contestants->{White},	'$m0R White'],
[ $p14,	$m{'0Remainder'}->[1]->contestants->{Black},	'$m0R Black'],
[ $p15,	$m{'0Remainder'}->[2]->contestants->{White},	'$m0R White'],
[ $p20,	$m{'0Remainder'}->[2]->contestants->{Black},	'$m0R Black'],
[ $p19,	$m{'0Remainder'}->[3]->contestants->{White},	'$m0R White'],
[ $p16,	$m{'0Remainder'}->[3]->contestants->{Black},	'$m0R Black'],
;

&$runRound; 
$round = 3;

push @okTests,
[ $m{1.5}->[0]->isa('Games::Tournament::Card'),	'$m1.5 isa'],
[ $m{'1.5Remainder'}->[0]->isa('Games::Tournament::Card'),	'$m1.5 isa'],
[ $m{'1.5Remainder'}->[1]->isa('Games::Tournament::Card'),	'$m1.5R isa'],
[ $m{'1.5Remainder'}->[2]->isa('Games::Tournament::Card'),	'$m1.5R isa'],
[ $m{1}->[0]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{1}->[1]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{1}->[2]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{0.5}->[0]->isa('Games::Tournament::Card'),	'$m0.5 isa'],
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
[ $m{0}->[1]->isa('Games::Tournament::Card'),	'$m0 isa'],
;

push @isTests,
[ $lineup[2],	$m{1.5}->[0]->contestants->{White},	'$m1.5 White'],
[ $lineup[7],	$m{1.5}->[0]->contestants->{Black},	'$m1.5 Black'],
[ $lineup[0],	$m{'1.5Remainder'}->[0]->contestants->{White},	'$m1.5R White'],
[ $lineup[5],	$m{'1.5Remainder'}->[0]->contestants->{Black},	'$m1.5R Black'],
[ $lineup[8],	$m{'1.5Remainder'}->[1]->contestants->{White},	'$m1.5R White'],
[ $lineup[1],	$m{'1.5Remainder'}->[1]->contestants->{Black},	'$m1.5R Black'],
[ $lineup[6],	$m{'1.5Remainder'}->[2]->contestants->{White},	'$m1.5R White'],
[ $lineup[3],	$m{'1.5Remainder'}->[2]->contestants->{Black},	'$m1.5R Black'],
[ $lineup[4],	$m{1}->[0]->contestants->{White},	'$m1 White'],
[ $lineup[12],	$m{1}->[0]->contestants->{Black},	'$m1 Black'],
[ $lineup[14],	$m{1}->[1]->contestants->{White},	'$m1 White'],
[ $lineup[9],	$m{1}->[1]->contestants->{Black},	'$m1 Black'],
[ $lineup[15],	$m{1}->[2]->contestants->{White},	'$m1 White'],
[ $lineup[10],	$m{1}->[2]->contestants->{Black},	'$m1 Black'],
[ $lineup[11],	$m{0.5}->[0]->contestants->{White},	'$m0.5 White'],
[ $lineup[16],	$m{0.5}->[0]->contestants->{Black},	'$m0.5 Black'],
[ $lineup[13],	$m{0}->[0]->contestants->{White},	'$m0 White'],
[ $lineup[18],	$m{0}->[0]->contestants->{Black},	'$m0 Black'],
[ $lineup[17],	$m{0}->[1]->contestants->{White},	'$m0 White'],
[ $lineup[19],	$m{0}->[1]->contestants->{Black},	'$m0 Black'],
;

&$runRound; 
$round = 4;

push @okTests,
[ $m{2.5}->[0]->isa('Games::Tournament::Card'),	'$m25 isa'],
[ $m{2}->[0]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{2}->[1]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{2}->[2]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{1.5}->[0]->isa('Games::Tournament::Card'),	'$m15 isa'],
[ $m{1.5}->[1]->isa('Games::Tournament::Card'),	'$m15 isa'],
[ $m{1.5}->[2]->isa('Games::Tournament::Card'),	'$m15 isa'],
[ $m{1}->[0]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{0.5}->[0]->isa('Games::Tournament::Card'),	'$m0.5 isa'],
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
;

push @isTests,
[ $p8,	$m{2.5}->[0]->contestants->{White},	'$m25 White'],
[ $p1,	$m{2.5}->[0]->contestants->{Black},	'$m25 Black'],
[ $p2,	$m{2}->[0]->contestants->{White},	'$m2 White'],
[ $p5,	$m{2}->[0]->contestants->{Black},	'$m2 Black'],
[ $p4,	$m{2}->[1]->contestants->{White},	'$m2 White'],
[ $p17,	$m{2}->[1]->contestants->{Black},	'$m2 Black'],
[ $p9,	$m{2}->[2]->contestants->{White},	'$m2 White'],
[ $p7,	$m{2}->[2]->contestants->{Black},	'$m2 Black'],
[ $p11,	$m{1.5}->[0]->contestants->{White},	'$m15 White'],
[ $p3,	$m{1.5}->[0]->contestants->{Black},	'$m15 Black'],
[ $p6,	$m{1.5}->[1]->contestants->{White},	'$m15 White'],
[ $p15,	$m{1.5}->[1]->contestants->{Black},	'$m15 Black'],
[ $p10,	$m{1.5}->[2]->contestants->{White},	'$m15 White'],
[ $p16,	$m{1.5}->[2]->contestants->{Black},	'$m15 Black'],
[ $p13,	$m{1}->[0]->contestants->{White},	'$m1 White'],
[ $p19,	$m{1}->[0]->contestants->{Black},	'$m1 Black'],
[ $p20,	$m{0.5}->[0]->contestants->{White},	'$m05 White'],
[ $p12,	$m{0.5}->[0]->contestants->{Black},	'$m05 Black'],
[ $p18,	$m{0}->[0]->contestants->{White},	'$m0 White'],
[ $p14,	$m{0}->[0]->contestants->{Black},	'$m0 Black'],
;

&$runRound; 
$round = 5;

# Round 5:  8 (3.5), 1 (3), 2 4 5 7 9 16 17 (2.5), 3 6 11 13 15 (2), 10 20 (1.5), 12 18 19 (1), 14 (0),

push @okTests,
[ $m{2.5}->[0]->isa('Games::Tournament::Card'),	'$m25 isa'],
[ $m{2.5}->[1]->isa('Games::Tournament::Card'),	'$m25 isa'],
[ $m{'2.5Remainder'}->[0]->isa('Games::Tournament::Card'),	'$m25R isa'],
[ $m{'2.5Remainder'}->[1]->isa('Games::Tournament::Card'),	'$m25R isa'],
[ $m{'2'}->[0]->isa('Games::Tournament::Card'),	'$m2 isa'],
[ $m{'2Remainder'}->[0]->isa('Games::Tournament::Card'), '$m2R isa'],
[ $m{'2Remainder'}->[1]->isa('Games::Tournament::Card'), '$m2R isa'],
[ $m{1}->[0]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{1}->[1]->isa('Games::Tournament::Card'),	'$m1 isa'],
[ $m{0}->[0]->isa('Games::Tournament::Card'),	'$m0 isa'],
;

push @isTests,
[ $p7,	$m{2.5}->[0]->contestants->{White},	'$m25 White'],
[ $p8,	$m{2.5}->[0]->contestants->{Black},	'$m25 Black'],
[ $p1,	$m{2.5}->[1]->contestants->{White},	'$m25 White'],
[ $p2,	$m{2.5}->[1]->contestants->{Black},	'$m25 Black'],
[ $p5,	$m{'2.5Remainder'}->[0]->contestants->{White},	'$m25R White'],
[ $p4,	$m{'2.5Remainder'}->[0]->contestants->{Black},	'$m25R Black'],
[ $p17,	$m{'2.5Remainder'}->[1]->contestants->{White},	'$m25R White'],
[ $p9,	$m{'2.5Remainder'}->[1]->contestants->{Black},	'$m25R Black'],
[ $p16,	$m{'2'}->[0]->contestants->{White},	'2 White'],
[ $p13,	$m{'2'}->[0]->contestants->{Black},	'2 Black'],
[ $p3,	$m{'2Remainder'}->[0]->contestants->{White}, '2R-0 White'],
[ $p15,	$m{'2Remainder'}->[0]->contestants->{Black}, '2R-0 Black'],
[ $p11,	$m{'2Remainder'}->[1]->contestants->{White}, '2R-1 White'],
[ $p6,	$m{'2Remainder'}->[1]->contestants->{Black}, '2R-1 Black'],
[ $p10,	$m{1}->[0]->contestants->{White},	'$m15 White'],
[ $p18,	$m{1}->[0]->contestants->{Black},	'$m15 Black'],
[ $p19,	$m{1}->[1]->contestants->{White},	'$m1 White'],
[ $p20,	$m{1}->[1]->contestants->{Black},	'$m1 Black'],
[ $p12,	$m{0}->[0]->contestants->{White},	'$m0 White'],
[ $p14,	$m{0}->[0]->contestants->{Black},	'$m0 Black'],
;

plan tests => $#okTests + $#isTests + 2;

ok( $_->[0], $_->[ 1, ], ) for @okTests;
is_deeply( $_->[0], $_->[ 1, ], $_->[ 2, ], ) for @isTests;

# vim: set ts=8 sts=4 sw=4 noet:
