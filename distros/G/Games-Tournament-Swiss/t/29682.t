#!usr/bin/perl

# http://rt.cpan.org/Ticket/Display.html?id=29682
# floating pairing checks failed in 0.09

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

my $round = 2;
$tourney->round($round);
$tourney->assignPairingNumbers;
$tourney->initializePreferences;
$tourney->initializePreferences until $lineup[0]->preference->role eq 'White';

my @ids = map { $_->{pairingNumber} } @lineup;
my $pairingtable = Load(<<'...');
---
floats:
  1: [ ~, Up ]
  10: [ ~, Down ]
  11: [ ~, Down ]
  12: [ ~, Up ]
  13: [ ~, ~ ]
  14: [ ~, ~ ]
  15: [ ~, ~ ]
  16: [ ~, ~ ]
  17: [ ~, ~ ]
  18: [ ~, ~ ]
  19: [ ~, ~ ]
  2: [ ~, ~ ]
  20: [ ~, ~ ]
  3: [ ~, ~ ]
  4: [ ~, ~ ]
  5: [ ~, ~ ]
  6: [ ~, ~ ]
  7: [ ~, ~ ]
  8: [ ~, ~ ]
  9: [ ~, ~ ]
opponents:
  1: [ 11, 10 ]
  10: [ 20, 1 ]
  11: [ 1, 12 ]
  12: [ 2, 11 ]
  13: [ 3, 18 ]
  14: [ 4, 17 ]
  15: [ 5, 20 ]
  16: [ 6, 19 ]
  17: [ 7, 14 ]
  18: [ 8, 13 ]
  19: [ 9, 16 ]
  2: [ 12, 7 ]
  20: [ 10, 15 ]
  3: [ 13, 6 ]
  4: [ 14, 9 ]
  5: [ 15, 8 ]
  6: [ 16, 3 ]
  7: [ 17, 2 ]
  8: [ 18, 5 ]
  9: [ 19, 4 ]
roles:
  1: [ White, Black ]
  10: [ Black, White ]
  11: [ Black, White ]
  12: [ White, Black ]
  13: [ Black, White ]
  14: [ White, Black ]
  15: [ Black, White ]
  16: [ White, Black ]
  17: [ Black, White ]
  18: [ White, Black ]
  19: [ Black, White ]
  2: [ Black, White ]
  20: [ White, Black ]
  3: [ White, Black ]
  4: [ Black, White ]
  5: [ White, Black ]
  6: [ Black, White ]
  7: [ White, Black ]
  8: [ Black, White ]
  9: [ White, Black ]
score:
  1: 1.5
  10: 1
  11: 1
  12: 0.5
  13: 1
  14: 0
  15: 1
  16: 1
  17: 1
  18: 0
  19: 0
  2: 1.5
  20: 0
  3: 1.5
  4: 1.5
  5: 1
  6: 1.5
  7: 1.5
  8: 2
  9: 1.5
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
    my %opponents = map { $_ => $opponents->{$_}->[$round-1] } @ids;
    my %roles = map { $_ => $roles->{$_}->[$round-1] } @ids;
    my %floats = ($round >= $lastround-1)?
	map { $_ => $floats->{$_}->[$round-$lastround-1] } @ids:
	undef;
    my @games = $tourney->recreateCards( {
       round => $round, opponents => \%opponents,
	roles => \%roles, floats => \%floats } );
   local $SIG{__WARN__} = sub {};
   $tourney->collectCards( @games );
}

my %b = $tourney->formBrackets;
my $pairing  = $tourney->pairing( \%b );
$pairing->loggingAll;
my $p        = $pairing->matchPlayers;
my %m = map { $_ => $p->{matches}->{$_} } keys %{ $p->{matches} };
$tourney->round(5);

my @tests = (
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
);

push @tests,
[ $p8,	$m{1.5}->[0]->contestants->{Black},	'$m1.5 Black'],
[ $p3,	$m{1.5}->[0]->contestants->{White},	'$m1.5 White'],
[ $p6,	$m{'1.5Remainder'}->[0]->contestants->{Black},	'$m1.5R Black'],
[ $p1,	$m{'1.5Remainder'}->[0]->contestants->{White},	'$m1.5R White'],
[ $p2,	$m{'1.5Remainder'}->[1]->contestants->{Black},	'$m1.5R Black'],
[ $p9,	$m{'1.5Remainder'}->[1]->contestants->{White},	'$m1.5R White'],
[ $p4,	$m{'1.5Remainder'}->[2]->contestants->{Black},	'$m1.5R Black'],
[ $p7,	$m{'1.5Remainder'}->[2]->contestants->{White},	'$m1.5R White'],
[ $p13,	$m{1}->[0]->contestants->{Black},	'$m1 Black'],
[ $p5,	$m{1}->[0]->contestants->{White},	'$m1 White'],
[ $p10,	$m{1}->[1]->contestants->{Black},	'$m1 Black'],
[ $p15,	$m{1}->[1]->contestants->{White},	'$m1 White'],
[ $p11,	$m{1}->[2]->contestants->{Black},	'$m1 Black'],
[ $p16,	$m{1}->[2]->contestants->{White},	'$m1 White'],
[ $p17,	$m{0.5}->[0]->contestants->{Black},	'$m0.5 Black'],
[ $p12,	$m{0.5}->[0]->contestants->{White},	'$m0.5 White'],
[ $p19,	$m{0}->[0]->contestants->{Black},	'$m0 Black'],
[ $p14,	$m{0}->[0]->contestants->{White},	'$m0 White'],
[ $p20,	$m{0}->[1]->contestants->{Black},	'$m0 Black'],
[ $p18,	$m{0}->[1]->contestants->{White},	'$m0 White'],
;

plan tests => $#tests + 1;

ok( $_->[0], $_->[ 1, ], ) for @tests[0..9];
is_deeply( $_->[0], $_->[ 1, ], $_->[ 2, ], ) for @tests[10..$#tests];

# vim: set ts=8 sts=4 sw=4 noet:
