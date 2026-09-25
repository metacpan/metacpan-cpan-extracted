#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use File::Find ();
use Test::More;

use Game::Mahjong;
use Play;

# The engine prints nothing, reads nothing, sleeps never and calls rand
# never. Two checks, because either alone is weak: the source scan proves
# the paths not taken are clean, and a whole game with both handles rigged
# to die proves the paths taken are. Terminal.pm is the one module that
# talks to a person, through the handles it is given, and is left out of
# the scan; t/32 drives it through in-memory handles.

package Dying::Handle;
	sub TIEHANDLE { return bless {}, shift }
	sub PRINT     { die 'the engine printed' }
	sub PRINTF    { die 'the engine printed' }
	sub READLINE  { die 'the engine read' }
	sub WRITE     { die 'the engine wrote' }

package main;

plan tests => 3;

subtest 'no IO, rand, time or sleep in lib' => sub {
	my @files;
	File::Find::find({ no_chdir => 1, wanted => sub { push @files, $File::Find::name if /\.pm\z/ && $File::Find::name !~ /Terminal\.pm\z/ } }, 'lib');
	cmp_ok(scalar @files, '>=', 14, 'the modules are found');
	for my $file (sort @files) {
		open my $fh, '<', $file or die "$file: $!";
		my @hits;
		while (my $line = <$fh>) {
			last if $line =~ /\A__END__/;
			next if $line =~ /\A\s*#/;
			push @hits, "$.: $line" if $line =~ /\b(?:print|printf|say|rand|srand|sleep|time|localtime|STDIN|STDOUT|STDERR)\b/
				&& $line !~ /\bprint_(?:meld|hand)\b|Notation::print\b|sub print\b|\bprint\(\@ids\)/;
		}
		close $fh;
		is_deeply(\@hits, [], "$file is clean") or diag join '', @hits;
	}
};

subtest 'a whole hand with both handles rigged to die' => sub {
	my ($error, $moves);
	tie *STDOUT, 'Dying::Handle';
	tie *STDIN,  'Dying::Handle';
	eval {
		my ($g, $bad, $census) = Play::play_game(seed => 'no-io', default => Play::eager_chooser(Play::new_rng('no-io')), stop_after => 300);
		$moves = $census->{moves};
		die join("\n", @$bad) if @$bad;
	};
	$error = $@;
	untie *STDOUT;
	untie *STDIN;
	is($error, '', 'no handle was touched');
	cmp_ok($moves, '>=', 300, 'three hundred moves were played');
};

subtest 'the terminal is not loaded by the engine' => sub {
	ok($INC{'Game/Mahjong/Rules.pm'}, 'the rules are loaded');
	ok(!$INC{'Game/Mahjong/Terminal.pm'}, 'the terminal is not');
};
