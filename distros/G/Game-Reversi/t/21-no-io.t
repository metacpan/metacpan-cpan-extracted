#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Reversi;
use Game::Reversi::Bot;
use Game::Reversi::Test::Handle;

# The engine prints nothing, reads nothing, sleeps never and calls rand never.
#
# This is the structural fix over Game::Cribbage, which is about a thousand lines
# of escape codes in its TOP LEVEL namespace module, so that only
# Game::Cribbage::Board was ever reusable by anything else.
#
# Two checks, because either alone is weak. The runtime one ties both handles to
# something that dies and plays a whole game, which proves the paths actually
# taken are clean. The source scan proves the paths NOT taken are clean too,
# which a tie cannot: a branch the tests happen to miss would slip straight past
# it.

plan tests => 4;

subtest 'the engine does not pull the terminal in with it' => sub {
	plan tests => 4;

	ok($INC{'Game/Reversi.pm'}, 'the engine is loaded');
	ok($INC{'Game/Reversi/Bot.pm'}, 'and so is the bot');
	ok($INC{'Game/Reversi/Scoring.pm'}, 'and the scoring, pulled in by the facade');
	ok(!$INC{'Game/Reversi/Terminal.pm'},
		'and Game::Reversi::Terminal is not, which is the point of it being separate');
};

subtest 'a whole game runs with both handles rigged to die' => sub {
	plan tests => 2;

	# Nothing between the tie and the untie may call Test::More: it would be
	# printing through a handle that dies on purpose. So the work happens first,
	# the result is stashed, and the assertions come after.
	#
	# Test::Builder holds a duplicate of STDOUT taken before the tie, so TAP
	# still gets out even while STDOUT is rigged.
	my ($moves, $score, $error);

	tie *STDOUT, 'Game::Reversi::Test::Handle';
	tie *STDIN, 'Game::Reversi::Test::Handle';

	eval {
		my $game = Game::Reversi->new(variant => 'historic', seed => 'z' x 32);
		my %bot = map { $_ => Game::Reversi::Bot->new(level => 2, seed => "io$_") }
		          qw(b w);
		$moves = 0;
		while ($game->status eq 'active' && $moves < 200) {
			my $move = $bot{ $game->turn }->choose($game, $game->turn) or last;
			my $played = $game->play($game->turn, $move->square);
			last if ref $played && $played->isa('Game::Reversi::Error');
			$moves++;
		}
		# The facade, the bot, the scoring, the result and the notation, all
		# exercised while the handles are rigged.
		$score = $game->score;
		$game->to_text;
		1;
	} or $error = $@;

	untie *STDOUT;
	untie *STDIN;

	is($error, undef, "played $moves moves without touching a handle")
		or diag("the engine wrote to or read from a handle: $error");
	is(($score->{b} // 0) + ($score->{w} // 0), 64, 'and the game scored properly');
};

subtest 'the engine source names no handle and no clock' => sub {
	plan tests => 1;

	# A source scan as well as a runtime one, because a path the tests happen not
	# to reach would slip past the tie. POD and comments are stripped first: this
	# file talks about STDOUT and rand in its own prose, and so does the POD of
	# the modules being scanned.
	my @modules = qw(
		Reversi.pm
		Reversi/Board.pm Reversi/Move.pm Reversi/Notation.pm
		Reversi/Opening.pm Reversi/Rules.pm Reversi/Scoring.pm
		Reversi/Result.pm Reversi/Error.pm Reversi/Bot.pm
	);

	my @caught;
	for my $name (@modules) {
		my $path = "lib/Game/$name";
		next unless -f $path;

		open my $fh, '<', $path or die "$path: $!";
		my $code = do { local $/; <$fh> };
		close $fh;

		$code =~ s/^__END__.*\z//ms;        # POD lives past __END__
		$code =~ s/^\s*#.*$//mg;            # and comments explain the rules

		my $line = 0;
		for my $text (split /\n/, $code) {
			$line++;
			for my $bad (qw(STDIN STDOUT STDERR sleep)) {
				push @caught, "$path:$line names $bad" if $text =~ /\b\Q$bad\E\b/;
			}
			push @caught, "$path:$line calls rand" if $text =~ /(?<![a-z_])rand\s*[\(;]/;
			push @caught, "$path:$line reads the clock" if $text =~ /(?<![a-z_])time\s*[\(;]/;
		}
	}

	is_deeply(\@caught, [],
		'no engine module reads a handle, calls rand, or looks at the clock')
		or diag(join "\n", @caught);
};

subtest 'the same seeds play the same game twice' => sub {
	plan tests => 3;

	# The point of all of the above, and of budgeting the bot in nodes rather
	# than seconds: a game is a pure function of its inputs, so a log that cannot
	# be replayed is not a log, and none of the sources of drift that would break
	# that exist in the engine.
	my @runs;
	for (1 .. 2) {
		my $game = Game::Reversi->new(variant => 'historic', seed => 'q' x 32);
		my %bot = map { $_ => Game::Reversi::Bot->new(level => 2, seed => "same$_") }
		          qw(b w);
		my $n = 0;
		while ($game->status eq 'active' && $n++ < 200) {
			my $move = $bot{ $game->turn }->choose($game, $game->turn) or last;
			last if ref($game->play($game->turn, $move->square)) =~ /Error/;
		}
		push @runs, { text => $game->to_text, score => $game->score };
	}

	is($runs[0]{text}, $runs[1]{text}, 'two runs produced the same moves');
	is_deeply($runs[0]{score}, $runs[1]{score}, 'and the same score');
	cmp_ok(length $runs[0]{text}, '>', 60, 'and it was a whole game, not two moves');
};
