#!usr/bin/perl

# float testing at a glance

use lib qw/t lib/;

use strict;
use warnings;
use Test::Base;
use List::MoreUtils qw/any/;

use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Card;

use Games::Tournament::Swiss::Config;
my %unabbr = Games::Tournament::Swiss::Config->abbreviation;
my %abbr = reverse %unabbr;

filters { input => [ qw/chomp floatseries/ ], expected => [ qw/chomp/ ] };

plan tests => 1 * blocks;

sub floatseries {
	my $score = shift;
	$score =~ s/^scores: (.*)$/$1/;
	my @score = split /\s/, $score;
	my @roles = qw/White Black/;
	my %contestant = map { $roles[$_] =>
		Games::Tournament::Contestant::Swiss->new(
			id => $_, score => $score[$_] ) } ( 0,1 );
	my $game = Games::Tournament::Card->new( contestants => \%contestant );
	if ( $game->isBye ) {
		$game->float( $contestant{Bye}, 'Down' );
	}
	elsif ( $game->equalScores ) {
		$game->float($contestant{$_}, 'Not') for keys %contestant;
	}
	else {
		my $highRole = $game->higherScoreRole;
		die "Scores not equal, but no score higher." unless 
			any { $highRole eq $_ } @roles;
		my $lowRole = $game->opponentRole( $highRole );
		$game->float( $contestant{ $highRole }, 'Down' );
		$game->float( $contestant{ $lowRole }, 'Up' );
	}
	my $floats = 'floats: ';
	my @float = map { $game->float( $contestant{$_} ) } @roles;
	$floats .= join ' ', map { $abbr{$_} } @float;
	return $floats;
}

run_is_deeply input => 'expected';

__DATA__

=== good
--- input
scores: 0 0
--- expected
floats: N N

=== good
--- input
scores: 6 5
--- expected
floats: D U

=== good
--- input
scores: 1 5
--- expected
floats: U D
