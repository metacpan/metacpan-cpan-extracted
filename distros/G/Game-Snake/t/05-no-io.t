#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

# THE ENGINE PRINTS NOTHING, READS NOTHING, SLEEPS NEVER, AND CALLS NEITHER
# rand NOR time. Two checks, because either alone is weak: a whole game with
# both handles tied to something that dies and rand and time overridden to
# die proves the paths taken are clean; a source scan proves the paths not
# taken are clean too, which a tie cannot.

BEGIN {
	*CORE::GLOBAL::rand = sub { die 'the engine called rand' };
	*CORE::GLOBAL::time = sub { die 'the engine called time' };
}

use Game::Snake;
use Game::Snake::Test::Steer;

plan tests => 3;

subtest 'the engine does not pull a front end in with it' => sub {
	ok($INC{'Game/Snake.pm'}, 'the engine is loaded');
	ok($INC{'Game/Snake/Error.pm'}, 'and the error');
	ok($INC{'Game/Snake/Result.pm'}, 'and the result');
	ok(!$INC{'Game/Snake/Terminal.pm'}, 'not the terminal');
	ok(!$INC{'Game/Snake/Ticker.pm'}, 'not the ticker');
	ok(!$INC{'Game/Snake/Raylib.pm'}, 'not the window');
	ok(!$INC{'Raylib/FFI.pm'}, 'and not raylib');
};

subtest 'a whole game runs with both handles rigged to die' => sub {
	require Game::Snake::Test::Handle;

	my ($error, $cause, $ticks);

	tie *STDOUT, 'Game::Snake::Test::Handle';
	tie *STDIN,  'Game::Snake::Test::Handle';

	eval {
		my $game = Game::Snake->new(cols => 10, rows => 8, seed => 'no-io');
		Game::Snake::Test::Steer->play($game, 'greedy', 2000);
		$game->quit unless $game->status eq 'finished';
		$cause = $game->result->cause;
		$ticks = $game->ticks;
		1;
	} or $error = $@;

	untie *STDOUT;
	untie *STDIN;

	is($error, undef, 'nothing printed, nothing read, no rand, no clock');
	ok($cause, "and the game ended ($cause)");
	cmp_ok($ticks, '>', 10, 'after a real number of ticks');
};

subtest 'the engine source names no handle and no clock' => sub {
	my @modules = qw(
		Game/Snake.pm
		Game/Snake/Error.pm
		Game/Snake/Result.pm
	);

	my @caught;
	for my $module (@modules) {
		my $path = "$FindBin::Bin/../lib/$module";
		open my $fh, '<', $path or do { push @caught, "$path cannot be read"; next };
		my $source = do { local $/; <$fh> };
		close $fh;

		$source =~ s/^__END__.*\z//ms;
		$source =~ s/^\s*#.*$//mg;

		my $line = 0;
		for my $text (split /\n/, $source) {
			$line++;
			for my $bad (qw(STDIN STDOUT STDERR sleep print say)) {
				push @caught, "$path:$line names $bad" if $text =~ /\b\Q$bad\E\b/;
			}
			push @caught, "$path:$line calls rand" if $text =~ /(?<![a-z_])rand\s*[\(;]/;
			push @caught, "$path:$line reads the clock" if $text =~ /(?<![a-z_])time\s*[\(;]/;
		}
	}

	is_deeply(\@caught, [], 'no handle, no sleep, no print, no rand, no clock')
		or diag join "\n", @caught;
};
