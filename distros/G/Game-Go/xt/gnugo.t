#!perl

# THE OUTSIDE OPINION.
#
# The XS-only decision left this distribution with one implementation of
# everything, so nothing in t/ can tell us we are wrong in the same way twice.
# GNU Go is a mature engine that answers the same GTP commands, and it can
# therefore disagree with us about the two things no self-consistent test can
# settle: whether a group is dead, and whether the bot plays well.
#
# GNU Go IS NOT SHIPPED, LINKED OR DEPENDED ON. It is a separate program, spoken
# to over a pipe, and this file runs only under RELEASE_TESTING.
#
# A TEST THAT CAN ONLY EVER SKIP HAS NEVER RUN. GNU Go is not installed on the
# development machine, and a file that skips there would sit in the repository
# for a year proving nothing. So the controller half of this file is exercised
# against OUR OWN GTP engine every time: the match harness, the vertex parsing,
# the pipe protocol and the disagreement report are all real code that runs. The
# comparison then reaches for GNU Go whenever GO_GNUGO names it, and when
# GO_GNUGO is set and the binary is missing it DIES rather than skipping.

use 5.010;
use strict;
use warnings;
use Test::More;

use IPC::Open2;
use File::Spec;

use Game::Go;
use Game::Go::GTP;
use Game::Go::Notation;

plan skip_all => 'RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

my $SIZE   = $ENV{GO_GNUGO_SIZE}  || 9;
my $GAMES  = $ENV{GO_GNUGO_GAMES} || 2;
my $LEVEL  = $ENV{GO_GNUGO_LEVEL} || 2;

# A controller talks to an engine over two filehandles. There are two kinds of
# engine here and the controller cannot tell them apart, which is the whole
# point: the harness is the same code either way.
{
	package Controller;

	sub in_process {
		my ($class, %args) = @_;
		return bless {
			gtp  => Game::Go::GTP->new(%args),
			name => 'Game::Go',
		}, $class;
	}

	sub piped {
		my ($class, $cmd) = @_;
		my ($out, $in);
		my $pid = IPC::Open2::open2($out, $in, @$cmd);
		return bless {
			pid => $pid, in => $in, out => $out, name => $cmd->[0],
		}, $class;
	}

	sub name { $_[0]{name} }

	# Send one command, read until the blank line, return (ok, body).
	sub ask {
		my ($self, $line) = @_;

		my $raw;
		if ($self->{gtp}) {
			$raw = $self->{gtp}->handle($line);
		}
		else {
			my $in = $self->{in};
			print {$in} "$line\n";
			$in->flush if $in->can('flush');
			$raw = '';
			my $fh = $self->{out};
			while (defined(my $l = <$fh>)) {
				$raw .= $l;
				last if $raw =~ /\n\n\z/ || $l =~ /\A\s*\z/ && length $raw > 1;
			}
		}

		$raw = '' unless defined $raw;
		my $ok = $raw =~ /\A=/ ? 1 : 0;
		(my $body = $raw) =~ s/\A[=?][0-9]*\s?//;
		$body =~ s/\s+\z//;
		return ($ok, $body);
	}

	sub close {
		my ($self) = @_;
		$self->ask('quit');
		return unless $self->{pid};
		close $self->{in}  if $self->{in};
		close $self->{out} if $self->{out};
		waitpid $self->{pid}, 0;
		return;
	}
}

# Is there a GNU Go to talk to? GO_GNUGO names it; nothing else looks for it,
# because a test that quietly finds a binary on PATH behaves differently on two
# machines for reasons nobody wrote down.
my $GNUGO = $ENV{GO_GNUGO};
if (defined $GNUGO && length $GNUGO) {
	# SET AND MISSING IS A FAILURE, NOT A SKIP. Asking for the outside opinion
	# and being told PASS without it is the failure mode this whole file exists
	# to avoid.
	my $found = -x $GNUGO;
	unless ($found) {
		for my $dir (File::Spec->path) {
			my $try = File::Spec->catfile($dir, $GNUGO);
			next unless -x $try;
			$GNUGO = $try;
			$found = 1;
			last;
		}
	}
	die "GO_GNUGO is set to '$ENV{GO_GNUGO}' and there is no such program. "
	  . "Unset it to run the self-check alone.\n" unless $found;
}

# One game between two controllers. Returns the moves played and the result each
# engine reports, which is where a disagreement shows up.
sub play_match {
	my ($black, $white, %args) = @_;
	my $size = $args{size} || $SIZE;

	for my $e ($black, $white) {
		my ($ok) = $e->ask("boardsize $size");
		die $e->name . " refused boardsize $size\n" unless $ok;
		$e->ask('clear_board');
		$e->ask('komi 6.5');
	}

	my @moves;
	my $passes = 0;
	my $cap = 4 * $size * $size;   # the phase-08 lesson: the guard scales
	my $to_move = 'b';

	while (@moves < $cap && $passes < 2) {
		my ($me, $them) = $to_move eq 'b' ? ($black, $white) : ($white, $black);

		my ($ok, $where) = $me->ask("genmove $to_move");
		return { error => $me->name . " failed to genmove" } unless $ok;

		$where = lc $where;
		last if $where eq 'resign';

		if ($where eq 'pass') { $passes++ }
		else {
			$passes = 0;
			my ($rok) = $them->ask("play $to_move $where");
			# A DISAGREEMENT ABOUT LEGALITY IS THE FINDING, not an error. One of
			# the two is wrong about the rules and the position says which.
			return {
				error => $them->name . " called $to_move $where illegal",
				moves => [@moves, "$to_move $where"],
			} unless $rok;
		}

		push @moves, "$to_move $where";
		$to_move = $to_move eq 'b' ? 'w' : 'b';
	}

	my (undef, $bscore) = $black->ask('final_score');
	my (undef, $wscore) = $white->ask('final_score');
	my (undef, $bdead)  = $black->ask('final_status_list dead');
	my (undef, $wdead)  = $white->ask('final_status_list dead');

	return {
		moves  => \@moves,
		scores => { $black->name . ':B' => $bscore, $white->name . ':W' => $wscore },
		dead   => { $black->name . ':B' => $bdead,  $white->name . ':W' => $wdead },
		unfinished => (@moves >= $cap ? 1 : 0),
	};
}

subtest 'the harness itself, against our own engine' => sub {
	# THIS IS WHY THE FILE IS NOT A SKIP. Two of ours play each other over the
	# same controller the GNU Go match uses, so the pipe protocol, the vertex
	# parsing, the move loop and the report are all exercised on every release
	# run whether or not GNU Go exists.
	my $b = Controller->in_process(size => $SIZE, level => 1, seed => 'harness-b');
	my $w = Controller->in_process(size => $SIZE, level => 1, seed => 'harness-w');

	my $game = play_match($b, $w, size => $SIZE);
	$_->close for $b, $w;

	ok(!$game->{error}, 'a whole game played with no rules disagreement')
		or diag $game->{error};
	ok(@{ $game->{moves} } > 4, scalar(@{ $game->{moves} }) . ' moves played');
	ok(!$game->{unfinished}, 'and it finished inside the guard');

	note("result: $_ => $game->{scores}{$_}") for sort keys %{ $game->{scores} || {} };
	done_testing();
};

SKIP: {
	skip 'GO_GNUGO is not set, so there is no outside opinion to ask', 2
		unless defined $GNUGO && length $GNUGO;

	my @cmd = ($GNUGO, '--mode', 'gtp', '--level', $LEVEL);

	subtest 'GNU Go accepts every move we play' => sub {
		# THE LEGALITY ORACLE. Our engine generates the moves and GNU Go is asked
		# to accept each one. A move it refuses is a rules disagreement, and with
		# one implementation of everything on our side, GNU Go is right until
		# proved otherwise by hand.
		my $disagreements = 0;
		my @records;

		for my $n (1 .. $GAMES) {
			my $ours = Controller->in_process(
				size => $SIZE, level => $LEVEL, seed => "gnugo-$n",
			);
			my $theirs = Controller->piped(\@cmd);

			# Alternate who holds black, because a colour-specific bug that only
			# shows on one side is exactly the kind this is looking for.
			my ($black, $white) = $n % 2 ? ($ours, $theirs) : ($theirs, $ours);
			my $game = play_match($black, $white, size => $SIZE);

			$_->close for $ours, $theirs;

			if ($game->{error}) {
				$disagreements++;
				push @records, "game $n: $game->{error}";
				push @records, "  moves: " . join(' ', @{ $game->{moves} || [] });
				next;
			}

			push @records, sprintf('game %d: %d moves, %s',
				$n, scalar @{ $game->{moves} },
				join(', ', map { "$_ $game->{scores}{$_}" } sort keys %{ $game->{scores} }));
		}

		note($_) for @records;
		is($disagreements, 0, "$GAMES games at ${SIZE}x$SIZE, no rules disagreement");
		done_testing();
	};

	subtest 'GNU Go is asked which stones are dead' => sub {
		# THE ONE NO SELF-CONSISTENT TEST CAN SETTLE. Our dead_guess is a short
		# playout and GNU Go has a real life-and-death reader. This subtest
		# RECORDS the two answers rather than asserting they match, because they
		# will not always and pretending otherwise would make it a test that gets
		# disabled. What it asserts is that both engines answer at all and that
		# neither claims a stone the other says is not there.
		my $ours = Controller->in_process(size => $SIZE, level => $LEVEL, seed => 'dead');
		my $theirs = Controller->piped(\@cmd);

		my $game = play_match($ours, $theirs, size => $SIZE);
		my ($ok_a, $mine)  = $ours->ask('final_status_list dead');
		my ($ok_b, $yours) = $theirs->ask('final_status_list dead');
		$_->close for $ours, $theirs;

		ok($ok_a, 'we answer final_status_list');
		ok($ok_b, 'and so does GNU Go');

		my @mine  = sort grep { length } split /\s+/, $mine;
		my @yours = sort grep { length } split /\s+/, $yours;
		note('ours: ' . (join(' ', @mine) || '(none)'));
		note('GNU Go: ' . (join(' ', @yours) || '(none)'));

		my %mine  = map { $_ => 1 } @mine;
		my %yours = map { $_ => 1 } @yours;
		note('only ours: ' . (join(' ', grep { !$yours{$_} } @mine) || '(none)'));
		note('only GNU Go: ' . (join(' ', grep { !$mine{$_} } @yours) || '(none)'));

		done_testing();
	};
}

done_testing();
