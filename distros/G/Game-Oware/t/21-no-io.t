#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Oware;
use Game::Oware::Bot;

# The engine prints nothing, reads nothing, sleeps never and calls rand never.
#
# This is the structural fix over Game::Cribbage, which is about a thousand
# lines of escape codes in its TOP LEVEL namespace module, so that only
# Game::Cribbage::Board was ever reusable by anything else.
#
# TWO CHECKS, BECAUSE EITHER ALONE IS WEAK. The runtime one ties both handles to
# something that dies and plays a whole game, which proves the paths actually
# taken are clean. The source scan proves the paths NOT taken are clean too,
# which a tie cannot: a branch the tests happen to miss would slip straight past
# it.

plan tests => 4;

subtest 'the engine does not pull the terminal in with it' => sub {
	ok($INC{'Game/Oware.pm'}, 'the engine is loaded');
	ok($INC{'Game/Oware/Bot.pm'}, 'and so is the bot');
	ok($INC{'Game/Oware/Scoring.pm'}, 'and the scoring, pulled in by the facade');
	ok(!$INC{'Game/Oware/Terminal.pm'},
		'and Game::Oware::Terminal is not, which is the point of it being separate');
};

subtest 'a whole game runs with both handles rigged to die' => sub {
	require Game::Oware::Test::Handle;

	my ($error, $total, $plies);

	# NOTHING BETWEEN THE TIE AND THE UNTIE MAY CALL Test::More: the handles it
	# would print through are the ones rigged to die.
	tie *STDOUT, 'Game::Oware::Test::Handle';
	tie *STDIN,  'Game::Oware::Test::Handle';

	eval {
		my $game = Game::Oware->new(seed => 'no-io');
		my %bot = map {
			$_ => Game::Oware::Bot->new(level => 2, seed => "no-io-$_")
		} qw/ p1 p2 /;

		$plies = 0;
		while ($game->status eq 'active' && $plies < 400) {
			my ($seat) = $game->waiting_on;
			my $house = $bot{$seat}->choose($game, $seat);
			last unless defined $house;
			$game->play($seat, $house);
			$plies++;
		}

		$total = 0;
		$total += $_ for @{ $game->board };
		1;
	} or $error = $@;

	untie *STDOUT;
	untie *STDIN;

	is($error, undef, 'nothing printed and nothing read');
	is($total, 48, 'and the game was played, because the seeds are still there');
	cmp_ok($plies, '>', 10, 'and it was a game rather than two moves');
};

subtest 'the engine source names no handle and no clock' => sub {
	my @modules = qw(
		Game/Oware.pm
		Game/Oware/Board.pm
		Game/Oware/Bot.pm
		Game/Oware/Error.pm
		Game/Oware/Move.pm
		Game/Oware/Notation.pm
		Game/Oware/Result.pm
		Game/Oware/Rules.pm
		Game/Oware/Scoring.pm
		Game/Oware/Variant.pm
	);

	my @caught;

	for my $module (@modules) {
		my $path = "lib/$module";
		open my $fh, '<', $path or do {
			push @caught, "$path cannot be read";
			next;
		};
		my $source = do { local $/; <$fh> };
		close $fh;

		# POD and comments are documentation and may say whatever they like.
		$source =~ s/^__END__.*\z//ms;
		$source =~ s/^\s*#.*$//mg;

		my $line = 0;
		for my $text (split /\n/, $source) {
			$line++;
			for my $bad (qw(STDIN STDOUT STDERR sleep)) {
				push @caught, "$path:$line names $bad"
					if $text =~ /\b\Q$bad\E\b/;
			}
			push @caught, "$path:$line calls rand"
				if $text =~ /(?<![a-z_])rand\s*[\(;]/;
			push @caught, "$path:$line reads the clock"
				if $text =~ /(?<![a-z_])time\s*[\(;]/;
		}
	}

	is_deeply(\@caught, [], 'no handle, no sleep, no rand, no clock')
		or diag join "\n", @caught;

	ok(scalar @modules >= 10, 'and that was every engine module but the terminal');
};

subtest 'the same seeds play the same game twice' => sub {
	my @runs;

	for (1 .. 2) {
		my $game = Game::Oware->new(seed => 'twice');
		my %bot = map {
			$_ => Game::Oware::Bot->new(level => 2, seed => "twice-$_")
		} qw/ p1 p2 /;

		my $plies = 0;
		while ($game->status eq 'active' && $plies < 400) {
			my ($seat) = $game->waiting_on;
			my $house = $bot{$seat}->choose($game, $seat);
			last unless defined $house;
			$game->play($seat, $house);
			$plies++;
		}

		push @runs, { text => $game->to_text, captured => $game->captured };
	}

	is($runs[0]{text}, $runs[1]{text}, 'the same transcript');
	is_deeply($runs[0]{captured}, $runs[1]{captured}, 'and the same score');
	cmp_ok(length $runs[0]{text}, '>', 20,
		'and it was a whole game, not two moves');
};
