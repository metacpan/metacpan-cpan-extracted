#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Checkers;
use Game::Checkers::Bot;
use Game::Checkers::Test::Handle;

# The whole distribution is shaped around the engine doing no input and no
# output. This is the test that keeps it that way.

subtest 'the engine does not pull the terminal in with it' => sub {
	plan tests => 2;
	ok $INC{'Game/Checkers.pm'}, 'the engine is loaded';
	ok !$INC{'Game/Checkers/Terminal.pm'},
		'and Game::Checkers::Terminal is not, which is the point of it being separate';
};

subtest 'a game and a search with both handles taken away' => sub {
	plan tests => 2;
	my $error;
	my $plies = 0;

	{
		# nothing between here and the untie may call Test::More: it would be
		# printing through a handle that dies on purpose
		tie *STDOUT, 'Game::Checkers::Test::Handle';
		tie *STDIN, 'Game::Checkers::Test::Handle';

		eval {
			my $game = Game::Checkers->new;
			my $bot = Game::Checkers::Bot->new(level => 1, seed => 4);
			while ($game->status eq 'active' && $game->ply < 20) {
				$game->move($bot->choose($game));
			}
			$game->to_pdn;
			$game->to_fen;
			$game->undo;
			$plies = $game->ply;
			1;
		} or $error = $@;

		untie *STDOUT;
		untie *STDIN;
	}

	is $error, undef, 'twenty plies, a search, PDN and an undo, and nothing spoke';
	is $plies, 19, 'and the game really was played';
};

subtest 'nor is there any of it in the source' => sub {
	my @module = glob 'lib/Game/Checkers.pm lib/Game/Checkers/*.pm';
	plan skip_all => 'not in the distribution root' unless @module;
	plan tests => scalar @module;

	# a guard, not a parser: it reads code lines with the POD and the comments
	# taken out, and asks for the clock only where it looks like a call, since
	# "ran out of time" is a result string and not a call to time()
	my %forbidden = (
		'print' => qr/\bprint\b/,
		'printf' => qr/(?<!s)\bprintf\b/,
		STDIN => qr/\bSTDIN\b/,
		STDOUT => qr/\bSTDOUT\b/,
		rand => qr/\brand\b/,
		sleep => qr/\bsleep\b/,
		time => qr/\b(?:time|localtime|gmtime)\s*[;(]/,
		readline => qr/\breadline\b/,
	);

	for my $file (@module) {
		my @found;
		open my $handle, '<', $file or die "cannot read $file: $!";
		my $pod = 0;
		while (my $line = <$handle>) {
			$pod = 1 if $line =~ m/^=\w/;
			$pod = 0 if $line =~ m/^=cut/;
			next if $pod;
			last if $line =~ m/^__END__/;
			$line =~ s/#.*$//;
			for my $name (sort keys %forbidden) {
				push @found, "$name on line $." if $line =~ $forbidden{$name};
			}
		}
		close $handle;

		# the terminal is the one module allowed to do any of it
		if ($file =~ m/Terminal\.pm$/) {
			ok scalar @found, "$file is where the input and output lives";
			next;
		}
		is_deeply \@found, [], "$file neither reads, writes, sleeps nor guesses";
	}
};

done_testing;
