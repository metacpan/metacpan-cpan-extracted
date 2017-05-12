#!/usr/bin/perl

use strict;
use warnings;

use Games::Tournament::Swiss -base;
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Card;
use Games::Tournament::Swiss::Procedure;

use YAML qw/LoadFile DumpFile/;

my $league = LoadFile '../league.yaml';
die 'round.yaml already exists' if -e 'round.yaml';

# @Games::Tournament::roles = qw/Questioner Answerer/;
# $Games::Tournament::firstround = 3;

use File::Spec;
use File::Basename;
my $roundN = basename( File::Spec->rel2abs( '.' ) );
my $n = 0;
my $prevRound = $roundN - 1;

my $results = LoadFile( "../g$prevRound.yaml" );

my $players;
if ( -e "../$prevRound/players.yaml" )
{
	$players = LoadFile qq{../$prevRound/players.yaml};
	for my $player ( @$players )
	{
		my $id = $player->id;
		my $score = $results->{cumulative}->{$id};
		$player->score( $score );
	}
}
else
{
	for my $member ( @{$league->{member}} )
	{
		my $id = $member->{id};
		$players->[$n++] = Games::Tournament::Contestant::Swiss->new(
			id => $id, name => $member->{name},
			score => $results->{cumulative}->{$id},
			title => $member->{title},
			rating => $member->{rating},  );
	}
}

my $tourney;
if ( -e "../$prevRound/tourney.yaml" )
{
	$tourney = LoadFile "../$prevRound/tourney.yaml";
	$tourney->entrants($players);
	$tourney->round( $prevRound );
}
else
{
	$tourney = Games::Tournament::Swiss->new(
		# round => $prevRound, roles => [ qw/Questioner Answerer/ ],
		entrants => $players );
	$tourney->round( $prevRound );
	$tourney->assignPairingNumbers( @$players );
}

my $games;
if ( -e "../$prevRound/matches.yaml" )
{
	$games = LoadFile "../$prevRound/matches.yaml";
	for my $game ( @$games )
	{
		my %result;
		for my $role ( keys %{ $game->contestants } )
		{
			my $player = $game->contestants->{$role};
			my $result = $results->{$prevRound}->{$player->id};
			$result{$role} = 
				$result == 1? 'Win': 
				$result == 0.5? "Draw": 'Loss';
		}
		$game->result( \%result );
	}
	$tourney->collectCards(@$games);
	$tourney->calculateScores($prevRound);
}

my @brackets = $tourney->formBrackets;
my $round = $tourney->pairing( \@brackets );

$round->matchPlayers;
my @matches = map { @{ $_ } } @{$round->matches};

my $roundfile;
$roundfile->{Warning} = '# This file, round,yaml, was created by pair.pl on ' . localtime() . '.';
if ( -e '../assistants.yaml' )
{
	my $assistantFile = LoadFile '../assistants.yaml';
	$roundfile->{assistant} = $assistantFile->{$roundN};
}
$n = 0;
for my $game ( @matches )
{
	my %group = map { $_ => $game->{contestants}->{$_}->{name} }
						keys %{$game->{contestants}};
	$roundfile->{group}->{$n++} = \%group;
}
$roundfile->{round} = $roundN;
$roundfile->{week} = $roundN . ' perhaps. Change if wrong.';
$roundfile->{texts} = [qw/Change these values./];

DumpFile 'players.yaml', $players;
DumpFile 'tourney.yaml', $tourney;
DumpFile 'pairing.yaml', $round;
DumpFile "../$prevRound/matches.yaml", $games if $prevRound;
DumpFile 'matches.yaml', \@matches;
DumpFile 'brackets.yaml', \@brackets;
DumpFile 'round.yaml', $roundfile;
