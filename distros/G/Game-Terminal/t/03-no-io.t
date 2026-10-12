#!perl
use 5.014;
use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Game::Terminal;
use Game::Terminal::Test::Handle;

subtest 'the roster does not pull the menu or a game in with it' => sub {
	plan tests => 3;
	ok $INC{'Game/Terminal.pm'}, 'the roster is loaded';
	ok !$INC{'Game/Terminal/Menu.pm'}, 'the menu is not';
	is_deeply [ grep { m{^(?:Game/(?!Terminal)|Term/Maze)} } sort keys %INC ], [],
		'and no game class is';
};

subtest 'the roster with both handles taken away' => sub {
	plan tests => 2;
	my $error;
	my $found = 0;
	{
		tie *STDOUT, 'Game::Terminal::Test::Handle';
		tie *STDIN, 'Game::Terminal::Test::Handle';
		eval {
			my @rows = Game::Terminal::games();
			my $row = Game::Terminal::find('draughts');
			my @near = Game::Terminal::nearest('chekers');
			my $path = Game::Terminal::installed($row, 't/lib');
			my @flags = Game::Terminal::flags_for($row, { ascii => 1, pick => 0 });
			$found = @rows && $row && @near && $path && @flags == 2;
			1;
		} or $error = $@;
		untie *STDOUT;
		untie *STDIN;
	}
	is $error, undef, 'nothing spoke';
	ok $found, 'and every function answered';
};

subtest 'nor is there any of it in the source, outside launch' => sub {
	my $file = 'lib/Game/Terminal.pm';
	plan skip_all => 'not in the distribution root' unless -f $file;
	plan tests => 1;
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
	my @found;
	open my $handle, '<', $file or die "cannot read $file: $!";
	my ($pod, $launch) = (0, 0);
	while (my $line = <$handle>) {
		$pod = 1 if $line =~ m/^=\w/;
		$pod = 0 if $line =~ m/^=cut/;
		next if $pod;
		last if $line =~ m/^__END__/;
		$launch = 1 if $line =~ m/^sub launch\b/;
		if ($launch) {
			$launch = 0 if $line =~ m/^\}/;
			next;
		}
		for my $name (sort keys %forbidden) {
			push @found, "$name on line $." if $line =~ $forbidden{$name};
		}
	}
	close $handle;
	is_deeply \@found, [], "$file neither reads, writes, sleeps nor guesses";
};

done_testing;
