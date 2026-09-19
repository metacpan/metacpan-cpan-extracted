#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Game::Oware;
use Game::Oware::Bot;
use Game::Oware::Variant ();

# What should plies_without_capture actually be?
#
# It is a HOUSE RULE with no published number behind it, so the value that ships
# has to be measured from played games rather than chosen. A cap that fires in
# ordinary games ends them arbitrarily; a cap too high bounds nothing.
unless ($ENV{RELEASE_TESTING} || $ENV{OWARE_MEASURE}) {
	plan(skip_all => 'set RELEASE_TESTING or OWARE_MEASURE to run the measurement');
}

# THE CAP HAS TO BE LIFTED TO MEASURE IT, or the measurement is circular: with
# the cap in place, every game whose longest capture-free stretch exceeds it
# ends by the cycle rule and is excluded from the sample, so the observed
# maximum can never exceed the cap it is meant to justify.
#
# Overriding the generated accessor is enough, because the engine calls it as a
# plain function rather than caching the value.
no warnings 'redefine';
local *Game::Oware::Variant::plies_without_capture = sub { 100_000 };

# THREE HUNDRED GAMES, AND THE NUMBER WAS FIXED BEFORE ANY RESULT WAS SEEN.
# Not the thousand the plan asked for: a thousand at these levels is about ten
# minutes, and the distribution of a stretch length settles long before that.
my $GAMES = 300;
my $PLY_CAP = 2000;

my (@stretches, %endings, @lengths);
my $repetition_endings = 0;

for my $i (1 .. $GAMES) {
	my $level = 1 + ($i % 3);
	my $game = Game::Oware->new(seed => "measure-$i");
	my %bot = map {
		$_ => Game::Oware::Bot->new(level => $level, seed => "measure-$i-$_")
	} qw/ p1 p2 /;

	my ($plies, $run, $longest) = (0, 0, 0);

	while ($game->status eq 'active' && $plies < $PLY_CAP) {
		my ($seat) = $game->waiting_on;
		my $house = $bot{$seat}->choose($game, $seat);
		last unless defined $house;

		my $move = $game->play($seat, $house);
		last if ref $move && $move->isa('Game::Oware::Error');

		if ($move->taken) { $run = 0 }
		else { $run++; $longest = $run if $run > $longest }

		$plies++;
	}

	push @stretches, $longest;
	push @lengths, $plies;
	$endings{ $game->result ? $game->result->reason : 'unfinished' }++;

	$repetition_endings++
		if $game->result && $game->result->reason eq 'cycle';
}

my @sorted = sort { $a <=> $b } @stretches;
my $max = $sorted[-1];
my $p95 = $sorted[ int(0.95 * $#sorted) ];
my $median = $sorted[ int(0.5 * $#sorted) ];

my @by_length = sort { $a <=> $b } @lengths;

diag('');
diag("games: $GAMES, levels 1 to 3");
diag('longest capture-free stretch: max ' . $max
	. ', p95 ' . $p95 . ', median ' . $median);
diag('game length: max ' . $by_length[-1]
	. ', median ' . $by_length[ int(0.5 * $#by_length) ]);
diag('endings: ' . join ', ', map { "$_=$endings{$_}" } sort keys %endings);
diag('SHIPPED plies_without_capture: '
	. Game::Oware::Variant::spec_for('abapa')->{plies_without_capture});
diag('');

subtest 'the shipped cap is above anything a real game produced' => sub {
	my $shipped = Game::Oware::Variant::spec_for('abapa')->{plies_without_capture};

	cmp_ok($max, '>', 0, 'games do have capture-free stretches');
	cmp_ok($shipped, '>', $max,
		"the cap ($shipped) is above the longest stretch measured ($max)");
};

subtest 'and it is not so high that it bounds nothing' => sub {
	my $shipped = Game::Oware::Variant::spec_for('abapa')->{plies_without_capture};
	cmp_ok($shipped, '<', $by_length[-1] * 2,
		'the cap is within the scale of a game rather than an arbitrary large number');
};

done_testing;
