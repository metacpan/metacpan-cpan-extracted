#!usr/bin/perl

use lib qw/t lib/;

use strict;
use warnings;

# use Games::Tournament::Swiss::Test;
use Test::Base -base;

BEGIN {
	@Games::Tournament::Swiss::Config::roles = (qw/A B/);
	$Games::Tournament::Swiss::Config::firstround = 1;
	$Games::Tournament::Swiss::Config::algorithm = 'Games::Tournament::Swiss::Procedure::FIDE';
}

plan tests => 1*blocks;

use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;
use Games::Tournament::Card;
use Games::Tournament::Swiss::Procedure;

my @t;

my $n = 3;
my ($p1,$p2,$p3)
	= map { Games::Tournament::Contestant::Swiss->new(
	id => $_, name => chr($_+64), rating => 2000-$_, title => 'Nom') }
	    (1..$n);
my @lineup =
($p1,$p2,$p3);

sub prepareTournament
{
	my $rounds = shift;
	my $lineup = @_;
	for my $player ( @lineup )
	{
		delete $player->{scores};
		delete $player->{score};
		$player->preference(
			Games::Tournament::Contestant::Swiss::Preference->new );
		delete $player->{pairingNumber};
		delete $player->{roles};
		delete $player->{floats};
	}
	my $tourney = Games::Tournament::Swiss->new( rounds => $rounds,
		entrants => \@lineup);
	$tourney->round(0);
	$tourney->assignPairingNumbers( @lineup );
	$tourney->initializePreferences;
	$tourney->initializePreferences until $p1->preference->role eq
		$Games::Tournament::Swiss::Config::roles[0];
	return $tourney;
}

sub runRound {
	my $tourney = shift;
	my $round = shift;
	my %brackets = $tourney->formBrackets;
	my $pairing  = $tourney->pairing( \%brackets )->matchPlayers;
	my $matches = $pairing->{matches};
	$tourney->{matches}->{$round} = $matches;
	my @games;
	my $results = shift;
	for my $bracket ( keys %$matches )
	{
		my $tables = $pairing->{matches}->{$bracket};
		$_->result( $results->{$bracket} ) for @$tables;
		push @games, @$tables;
	}
	local $SIG{__WARN__} = sub {};
	$tourney->collectCards( @games );
	$tourney->round($round);
};

$t[1] = prepareTournament( 3, @lineup );
runRound($t[1], 1, { 0=>	{A=>'Draw',B=>'Draw'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[1], 2, { 0.5=>	{A=>'Draw',B=>'Draw'}, '0.5Bye'=>{Bye=>'Bye'} });
runRound($t[1], 3, {});

$t[2] = prepareTournament( 3, @lineup );
runRound($t[2], 1, { 0=>	{A=>'Draw',B=>'Draw'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[2], 2, { 0.5=>	{A=>'Win',B=>'Loss'}, '0.5Bye'=>{Bye=>'Bye'} });
runRound($t[2], 3, {});

$t[3] = prepareTournament( 3, @lineup );
runRound($t[3], 1, { 0=>	{A=>'Draw',B=>'Draw'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[3], 2, { 0.5=>	{A=>'Loss',B=>'Win'}, '0.5Bye'=>{Bye=>'Bye'} });
runRound($t[3], 3, {});

$t[4] = prepareTournament( 3, @lineup );
runRound($t[4], 1, { 0=>	{A=>'Win',B=>'Loss'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[4], 2, { 1=>	{A=>'Draw',B=>'Draw'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[4], 3, {});

$t[5] = prepareTournament( 3, @lineup );
runRound($t[5], 1, { 0=>	{A=>'Win',B=>'Loss'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[5], 2, { 1=>	{A=>'Win',B=>'Loss'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[5], 3, {});

$t[6] = prepareTournament( 3, @lineup );
runRound($t[6], 1, { 0=>	{A=>'Win',B=>'Loss'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[6], 2, { 1=>	{A=>'Loss',B=>'Win'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[6], 3, {});

$t[7] = prepareTournament( 3, @lineup );
runRound($t[7], 1, { 0=>	{A=>'Loss',B=>'Win'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[7], 2, { 1=>	{A=>'Loss',B=>'Win'}, '0Bye'=>{Bye=>'Bye'} });
runRound($t[7], 3, {});

sub roundFilter
{
	my $tourney = $t[shift];
	my $round = shift;
	my $matches = $tourney->{matches}->{$round};
	my %tables;
	for my $key ( sort keys %$matches )
	{
		my $bracket = $matches->{$key};
		for my $game ( @$bracket )
		{
			my $contestants = $game->contestants;
			my @ids = map { $contestants->{$_}->id } sort keys %$contestants;
			push @{$tables{$key}}, \@ids;
		}
	}
	return \%tables;
}

run_is_deeply input => 'expected';

__DATA__

=== Tourney 1 Round 1
--- input lines chomp roundFilter
1
1
--- expected yaml
0:
 -
  - 1
  - 2
0Bye:
 -
  - 3

=== Tourney 1 Round 2
--- input lines chomp roundFilter
1
2
--- expected yaml
0.5:
 -
  - 3
  - 1
0.5Bye:
 -
  - 2

=== Tourney 1 Round 3
--- input lines chomp roundFilter
1
3
--- expected yaml
1.5:
 -
  - 2
  - 3
1Bye:
 -
  - 1

=== Tourney 2 Round 1
--- input lines chomp roundFilter
2
1
--- expected yaml
0:
 -
  - 1
  - 2
0Bye:
 -
  - 3

=== Tourney 2 Round 2
--- input lines chomp roundFilter
2
2
--- expected yaml
0.5:
 -
  - 3
  - 1
0.5Bye:
 -
  - 2

=== Tourney 2 Round 3
--- input lines chomp roundFilter
2
3
--- expected yaml
1.5:
 -
  - 2
  - 3
0.5Bye:
 -
  - 1

=== Tourney 3 Round 1
--- input lines chomp roundFilter
3
1
--- expected yaml
0:
 -
  - 1
  - 2
0Bye:
 -
  - 3

=== Tourney 3 Round 2
--- input lines chomp roundFilter
3
2
--- expected yaml
0.5:
 -
  - 3
  - 1
0.5Bye:
 -
  - 2

=== Tourney 3 Round 3
--- input lines chomp roundFilter
3
3
--- expected yaml
1:
 -
  - 2
  - 3
1Bye:
 -
  - 1

=== Tourney 4 Round 1
--- input lines chomp roundFilter
4
1
--- expected yaml
0:
 -
  - 1
  - 2
0Bye:
 -
  - 3

=== Tourney 4 Round 2
--- input lines chomp roundFilter
4
2
--- expected yaml
1:
 -
  - 3
  - 1
0Bye:
 -
  - 2

=== Tourney 4 Round 3
--- input lines chomp roundFilter
4
3
--- expected yaml
1:
 -
  - 2
  - 3
1Bye:
 -
  - 1

=== Tourney 5 Round 1
--- input lines chomp roundFilter
5
1
--- expected yaml
0:
 -
  - 1
  - 2
0Bye:
 -
  - 3

=== Tourney 5 Round 2
--- input lines chomp roundFilter
5
2
--- expected yaml
1:
 -
  - 3
  - 1
0Bye:
 -
  - 2

=== Tourney 5 Round 3
--- input lines chomp roundFilter
5
3
--- expected yaml
1:
 -
  - 2
  - 3
1Bye:
 -
  - 1

=== Tourney 6 Round 1
--- input lines chomp roundFilter
6
1
--- expected yaml
0:
 -
  - 1
  - 2
0Bye:
 -
  - 3

=== Tourney 6 Round 2
--- input lines chomp roundFilter
6
2
--- expected yaml
1:
 -
  - 3
  - 1
0Bye:
 -
  - 2

=== Tourney 6 Round 3
--- input lines chomp roundFilter
6
3
--- expected yaml
1:
 -
  - 2
  - 3
1Bye:
 -
  - 1
--- SKIP

=== Tourney 7 Round 1
--- input lines chomp roundFilter
7
1
--- expected yaml
0:
 -
  - 1
  - 2
0Bye:
 -
  - 3

=== Tourney 7 Round 2
--- input lines chomp roundFilter
7
2
--- expected yaml
1:
 -
  - 2
  - 3
0Bye:
 -
  - 1

=== Tourney 7 Round 3
--- input lines chomp roundFilter
7
3
--- expected yaml
1:
 -
  - 3
  - 1
1Bye:
 -
  - 2

