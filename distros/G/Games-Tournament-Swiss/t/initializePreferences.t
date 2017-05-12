#!usr/bin/perl

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;

BEGIN {
	@Games::Tournament::Swiss::Config::roles = (qw/A B/);
	$Games::Tournament::Swiss::Config::firstround = 1;
	$Games::Tournament::Swiss::Config::algorithm = 'Games::Tournament::Swiss::Procedure::FIDE';
}

my $tests = 53;

plan tests => $tests;

use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;

my @t;

my @tworole = @Games::Tournament::Swiss::Config::roles;

sub prepareTournament
{
	my $n = shift;
	my @players = map { Games::Tournament::Contestant::Swiss->new(
		id => $_, name => chr($_+64), rating => 2000-$_,
		title => 'Nom') }
		    (1..$n);
	my $tourney = Games::Tournament::Swiss->new( rounds => 1,
		entrants => \@players);
	$tourney->round(0);
	$tourney->assignPairingNumbers( @players );
	$tourney->initializePreferences;
	$tourney->initializePreferences while
		defined $players[0]->preference->role
			and $players[0]->preference->role ne $tworole[0];
	return $tourney;
}

sub checkPreferences {
	my $tourney = shift;
	my $players = $tourney->entrants;
	my $p = int ( @$players/2 );
	my @preferences = map {
		$_%2 && $_ <= $p-1 ? $tworole[1]:
			$_ <= $p-1 ? $tworole[0]: undef 
		} 0 .. $#$players;
	return \@preferences;
}

sub runTests {
	my $times = shift;
	for my $n ( 1 .. $times ) {
		my $tourney = prepareTournament( $n );
		my @preferences = checkPreferences( $tourney );
		is_deeply(
			[map { $_->preference->role } @{ $tourney->entrants }],
			checkPreferences( $tourney ),
			"for $n players" );
	}
}

runTests( $tests );
