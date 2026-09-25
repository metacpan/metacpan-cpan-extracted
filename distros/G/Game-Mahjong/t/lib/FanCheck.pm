package FanCheck;

use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Mahjong;

# The helpers the twelve grade tests share. A vector is a notation string
# (fourteen tiles' worth, checked) plus a context; `found` decomposes it on
# the winning tile (or with no placement), runs every checker on every
# split, and returns the union: fan key => the most instances any split had.
# A fan is "in" a hand if some split shows it, which is what the scorer's
# choose-the-highest makes true.

sub hand { return Game::Mahjong::Hand->from_notation($_[0]) }

sub found {
	my ($notation, %ctx) = @_;
	my $h = hand($notation);
	die "$notation is " . $h->total . " tiles, not 14" unless $h->total == 14;
	my $winning = $ctx{winning} ? Game::Mahjong::Tiles::id_of($ctx{winning}) : 0;
	$ctx{winning} = $winning if $winning;
	$ctx{waits} = [ map { Game::Mahjong::Tiles::id_of($_) } @{ $ctx{waits} } ] if $ctx{waits};
	my @splits = Game::Mahjong::Decompose::decompose($h, $winning);
	die "$notation is not complete" unless @splits;
	my %union;
	for my $split (@splits) {
		my $f = Game::Mahjong::Fans::check_all($split, \%ctx);
		for my $k (keys %$f) {
			my $n = scalar @{ $f->{$k} };
			$union{$k} = $n if !$union{$k} || $n > $union{$k};
		}
	}
	return \%union;
}

sub has_fan {
	my ($notation, $key, $why, %ctx) = @_;
	my $f = found($notation, %ctx);
	ok($f->{$key}, "$key: $why") or diag "found: " . join(', ', sort keys %$f);
	return $f;
}

sub lacks_fan {
	my ($notation, $key, $why, %ctx) = @_;
	my $f = found($notation, %ctx);
	ok(!$f->{$key}, "$key absent: $why") or diag "found: " . join(', ', sort keys %$f);
	return $f;
}

sub times_of {
	my ($notation, $key, $want, $why, %ctx) = @_;
	my $f = found($notation, %ctx);
	is($f->{$key} || 0, $want, "$key x$want: $why") or diag "found: " . join(', ', map { "$_=$f->{$_}" } sort keys %$f);
	return $f;
}

1;
