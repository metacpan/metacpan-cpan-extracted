#!perl

# THE ENGINE DOES NO INPUT OR OUTPUT AT ALL, and never calls rand or reads a
# clock.
#
# Three of those four are house rules. The `rand` one is this distribution's own
# and it matters more here than anywhere else: the bot is built out of random
# playouts, and it has to produce them from a seed the site publishes rather
# than from a source nobody can reproduce. A single rand() in the engine would
# make every bot game unreplayable and no other test would notice.

use 5.010;
use strict;
use warnings;
use Test::More;

# THIS FILE MUST NOT LOAD Game::Go::Terminal OR Game::Go::GTP. Both do input and
# output by design; they are consumers of the engine and not part of it. Loading
# either here would make the tied-handle assertion below meaningless.
use Game::Go;
use Game::Go::Bot;
use Game::Go::SGF;

my $B = Game::Go::BLACK;
my $W = Game::Go::WHITE;

subtest 'the C sources, with comments stripped' => sub {
	plan skip_all => 'not run from the distribution root'
		unless -e 'go_engine.c' && -e 'go_search.c';

	# COMMENTS ARE STRIPPED FIRST, because both files TALK about stdio.h and
	# rand at length, explaining why they do not use them. A scan that did not
	# strip would fail on the explanation.
	for my $file (qw(go_engine.c go_search.c)) {
		my $src = do { open my $fh, '<', $file or die "$file: $!"; local $/; <$fh> };
		$src =~ s{/\*.*?\*/}{}gs;
		$src =~ s{//[^\n]*}{}g;

		for my $banned (qw(stdio.h time.h printf sprintf fprintf rand srand sleep fopen)) {
			my $n = () = $src =~ /\Q$banned\E/g;
			is($n, 0, "$file: no $banned");
		}
	}
	done_testing();
};

subtest 'the Perl, less the two consumers that are meant to' => sub {
	plan skip_all => 'not run from the distribution root' unless -d 'lib';

	# Terminal and GTP are EXCLUDED BY NAME rather than by a pattern, so a new
	# module that does IO has to be added here deliberately rather than sliding
	# in under a wildcard.
	my %allowed = map { $_ => 1 } qw(
		lib/Game/Go/Terminal.pm
		lib/Game/Go/GTP.pm
	);

	my @files;
	my $walk;
	$walk = sub {
		my ($dir) = @_;
		opendir my $dh, $dir or return;
		for my $e (sort readdir $dh) {
			next if $e =~ /\A\./;
			my $path = "$dir/$e";
			if (-d $path) { $walk->($path); next }
			push @files, $path if $path =~ /\.pm\z/;
		}
		closedir $dh;
	};
	$walk->('lib');

	ok(scalar @files, 'found modules to scan');
	my $scanned = 0;

	for my $file (@files) {
		next if $allowed{$file};
		my $src = do { open my $fh, '<', $file or die "$file: $!"; local $/; <$fh> };

		# Strip POD and comments: every one of these words appears in the prose
		# explaining why it is not used.
		$src =~ s/^=\w.*?^=cut//gms;
		$src =~ s/^\s*#.*$//gm;

		$scanned++;
		unlike($src, qr/\brand\s*\(/,   "$file: no rand()");
		unlike($src, qr/\bsrand\b/,     "$file: no srand");
		unlike($src, qr/\bsleep\s*\(/,  "$file: no sleep()");
		unlike($src, qr/\bprint\s/,     "$file: no print");
		unlike($src, qr/\bopen\s*\(/,   "$file: no open()");
		unlike($src, qr/\btime\s*\(\)/, "$file: no time()");
	}

	cmp_ok($scanned, '>=', 8, "scanned $scanned modules, rather than none");
	done_testing();
};

subtest 'a whole game against a handle that dies if it is touched' => sub {
	# The scan above is a source check and could be fooled. This is the
	# behavioural one: STDOUT is tied to a handle whose every method dies, and
	# a full game plus a full bot search runs through it.
	my $old = select;
	{
		package Game::Go::Test::Deaf;
		sub TIEHANDLE { bless {}, shift }
		sub PRINT     { die "the engine printed\n" }
		sub PRINTF    { die "the engine printed\n" }
		sub WRITE     { die "the engine wrote\n" }
		sub READLINE  { die "the engine read\n" }
		sub GETC      { die "the engine read\n" }
		sub CLOSE     { 1 }
	}

	tie *DEAF, 'Game::Go::Test::Deaf';
	my $saved = select(*DEAF);

	my $ok = eval {
		my $g = Game::Go->new(size => 9, seed => 'q' x 32);
		my %bot = (
			$B => Game::Go::Bot->new(level => 1, seed => 'b'),
			$W => Game::Go::Bot->new(level => 1, seed => 'w'),
		);
		my $n = 0;
		while ($g->status eq 'active' && $n++ < 400) {
			my ($who) = $g->waiting_on;
			last unless defined $who;
			my $m = $bot{$who}->choose($g, $who) or last;
			my $out =
				  $m->kind eq 'play'    ? $g->play($who, $m->point)
				: $m->kind eq 'pass'    ? $g->pass($who)
				: $m->kind eq 'mark'    ? $g->mark($who, $m->point)
				: $m->kind eq 'done'    ? $g->done($who)
				: $m->kind eq 'accept'  ? $g->accept($who)
				: $m->kind eq 'dispute' ? $g->dispute($who)
				: undef;
			last if ref $out eq 'Game::Go::Error';
		}

		# and the SGF writer, which builds a string rather than printing one
		Game::Go::SGF::write($g);
		1;
	};
	my $why = $@;

	select($saved);
	untie *DEAF;

	ok($ok, 'a whole bot game and an SGF write, with output tied to a dying handle')
		or diag $why;
	done_testing();
};

subtest 'the two consumers are not loaded' => sub {
	# If either had been pulled in by something above, the tied-handle subtest
	# would have been testing a process that already had IO code in it.
	ok(!$INC{'Game/Go/Terminal.pm'}, 'Game::Go::Terminal was not loaded');
	ok(!$INC{'Game/Go/GTP.pm'}, 'and neither was Game::Go::GTP');
	done_testing();
};

done_testing();
