#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Dominoes;
use Game::Dominoes::Bot;
use Game::Dominoes::Test::Handle;

plan tests => 4;

subtest 'the engine does not pull the terminal in with it' => sub {
	plan tests => 3;

	# This is the structural fix over Game::Cribbage, which is a thousand
	# lines of escape codes in its TOP LEVEL namespace module, so that only
	# Game::Cribbage::Board was ever reusable by anything.
	ok $INC{'Game/Dominoes.pm'}, 'the engine is loaded';
	ok $INC{'Game/Dominoes/Bot.pm'}, 'and so is the bot';
	ok !$INC{'Game/Dominoes/Terminal.pm'},
		'and Game::Dominoes::Terminal is not, which is the point of it being separate';
};

subtest 'a whole game runs with both handles rigged to die' => sub {
	plan tests => 1;

	# Nothing between the tie and the untie may call Test::More: it would be
	# printing through a handle that dies on purpose. So the work happens
	# first, the result is stashed, and the assertion comes after.
	#
	# Test::Builder holds a duplicate of STDOUT taken before the tie, so TAP
	# still gets out even while STDOUT is rigged.
	my ($plays, $error);

	tie *STDOUT, 'Game::Dominoes::Test::Handle';
	tie *STDIN, 'Game::Dominoes::Test::Handle';

	eval {
		my $game = Game::Dominoes->new(seed => 'a' x 32, players => 3, target => 60);
		my $bot = Game::Dominoes::Bot->new(level => 2, seed => 3);
		$plays = 0;
		while ($game->status eq 'active' && $plays < 2000) {
			my $move = $bot->choose($game, $game->turn) or last;
			my $out = $game->play($game->turn, $move);
			last if ref $out eq 'Game::Dominoes::Error';
			$plays++;
		}
		1;
	} or $error = $@;

	untie *STDOUT;
	untie *STDIN;

	is $error, undef, "played $plays moves without touching a handle"
		or diag("the engine wrote to or read from a handle: $error");
};

subtest 'the engine source names no handle and no clock' => sub {
	plan tests => 1;

	# A source scan as well as a runtime one, because a path the tests happen
	# not to reach would slip past the tie. POD and comments are stripped
	# first: this file talks about STDOUT and rand in its own prose, and so
	# does the POD of the modules being scanned.
	my @modules = qw(
		Dominoes.pm
		Dominoes/Tile.pm Dominoes/Set.pm Dominoes/Hand.pm Dominoes/Boneyard.pm
		Dominoes/Play.pm Dominoes/Layout.pm Dominoes/Rules.pm
		Dominoes/Scoring.pm Dominoes/Notation.pm Dominoes/Error.pm
		Dominoes/Result.pm Dominoes/Bot.pm
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
			# rand and time, but not srand in a comment or Time::HiRes in POD.
			push @caught, "$path:$line calls rand" if $text =~ /(?<![a-z_])rand\s*[\(;]/;
			push @caught, "$path:$line reads the clock" if $text =~ /(?<![a-z_])time\s*[\(;]/;
		}
	}

	is_deeply \@caught, [],
		'no engine module reads a handle, calls rand, or looks at the clock'
		or diag(join "\n", @caught);
};

subtest 'the same seed and bot seed replay identically' => sub {
	plan tests => 2;

	# The point of all of the above. A game is a pure function of its seed
	# and its moves, so a log that cannot be replayed is not a log, and none
	# of the sources of drift that would break that exist in the engine.
	my @runs;
	for (1 .. 2) {
		my $game = Game::Dominoes->new(seed => 'z' x 32, players => 2, target => 80);
		my $bot = Game::Dominoes::Bot->new(level => 3, seed => 9);
		my $n = 0;
		while ($game->status eq 'active' && $n++ < 2000) {
			my $move = $bot->choose($game, $game->turn) or last;
			last if ref $game->play($game->turn, $move) eq 'Game::Dominoes::Error';
		}
		push @runs, { text => $game->to_text, scores => $game->scores };
	}

	is $runs[0]{text}, $runs[1]{text}, 'two runs produced the same moves';
	is_deeply $runs[0]{scores}, $runs[1]{scores}, 'and the same scores';
};
