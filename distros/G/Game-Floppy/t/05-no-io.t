#!perl
use 5.014;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

# THE ENGINE PRINTS NOTHING, READS NOTHING, SLEEPS NEVER, AND CALLS NEITHER
# rand NOR time. A whole game under dying tied handles with rand and time
# overridden proves the paths taken; a source scan proves the paths not taken.

BEGIN {
	*CORE::GLOBAL::rand = sub { die 'the engine called rand' };
	*CORE::GLOBAL::time = sub { die 'the engine called time' };
}

use Game::Floppy;
use Game::Floppy::Test::Fly;

plan tests => 3;

subtest 'the engine does not pull a front end in with it' => sub {
	ok($INC{'Game/Floppy.pm'}, 'the engine is loaded');
	ok($INC{'Game/Floppy/Error.pm'}, 'and the error');
	ok($INC{'Game/Floppy/Result.pm'}, 'and the result');
	ok(!$INC{'Game/Floppy/Terminal.pm'}, 'not the terminal');
	ok(!$INC{'Game/Terminal/Kit/Ticker.pm'}, 'not the ticker');
	ok(!$INC{'Game/Floppy/Raylib.pm'}, 'not the window');
	ok(!$INC{'Game/Floppy/Bot.pm'}, 'not the bot');
	ok(!$INC{'Raylib/FFI.pm'}, 'and not raylib');
};

subtest 'a whole game runs with both handles rigged to die' => sub {
	require Game::Terminal::Kit::Test::Handle;

	my ($error, $cause, $ticks);

	tie *STDOUT, 'Game::Terminal::Kit::Test::Handle';
	tie *STDIN,  'Game::Terminal::Kit::Test::Handle';

	eval {
		my $game = Game::Floppy->new(seed => 'no-io');
		Game::Floppy::Test::Fly->play($game, Game::Floppy::Test::Fly->every(10), 3000);
		$game->quit unless $game->status eq 'finished';
		$cause = $game->result->cause;
		$ticks = $game->ticks;
		1;
	} or $error = $@;

	untie *STDOUT;
	untie *STDIN;

	is($error, undef, 'nothing printed, nothing read, no rand, no clock');
	ok($cause, "and the game ended ($cause)");
	cmp_ok($ticks, '>', 100, 'after a real number of ticks');
};

subtest 'the engine source names no handle, no clock and no raylib' => sub {
	my @modules = qw(
		Game/Floppy.pm
		Game/Floppy/Error.pm
		Game/Floppy/Result.pm
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
			for my $bad (qw(STDIN STDOUT STDERR sleep print say Raylib)) {
				push @caught, "$path:$line names $bad" if $text =~ /\b\Q$bad\E\b/;
			}
			push @caught, "$path:$line calls rand" if $text =~ /(?<![a-z_])rand\s*[\(;]/;
			push @caught, "$path:$line reads the clock" if $text =~ /(?<![a-z_])time\s*[\(;]/;
		}
	}

	is_deeply(\@caught, [], 'no handle, no sleep, no print, no rand, no clock, no raylib')
		or diag join "\n", @caught;
};
