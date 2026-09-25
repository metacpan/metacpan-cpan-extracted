package Play;

use 5.010;
use strict;
use warnings;
use Digest::SHA ();

use Game::Mahjong;

# The driver the rules tests and the soak share. Every move is CHECKED
# AGAINST legal BEFORE IT IS MADE, so a chooser reaching for a tile it does
# not hold dies by name here rather than being quietly refused; a refusal
# from apply dies too; the invariants run after every move when asked.
# Nothing here calls rand: the choosers draw from SHA-256 over a seed and a
# counter, so a failing game is a seed anybody can rerun.

sub new_rng {
	my ($seed) = @_;
	my ($counter, @words) = (0);
	return sub {
		my ($n) = @_;
		unless (@words) {
			@words = unpack 'N8', Digest::SHA::sha256("$seed:" . $counter++);
		}
		return (shift @words) % $n;
	};
}

# any legal move, uniformly
sub random_chooser {
	my ($rng) = @_;
	return sub {
		my ($g, $seat, @legal) = @_;
		return $legal[ $rng->(scalar @legal) ];
	};
}

# win when it can, claim when it can (kong, pung, chow in that order),
# otherwise a random discard; passes only when nothing is claimable
sub eager_chooser {
	my ($rng) = @_;
	return sub {
		my ($g, $seat, @legal) = @_;
		for my $want (qw(win kong pung chow)) {
			my @m = grep { $_->{kind} eq $want } @legal;
			return $m[ $rng->(scalar @m) ] if @m;
		}
		my @d = grep { $_->{kind} eq 'discard' } @legal;
		return $d[ $rng->(scalar @d) ] if @d;
		return $legal[ $rng->(scalar @legal) ];
	};
}

# passes every window, discards the first legal tile: the dullest seat
sub dull_chooser {
	return sub {
		my ($g, $seat, @legal) = @_;
		my ($pass) = grep { $_->{kind} eq 'pass' } @legal;
		return $pass if $pass;
		my ($win) = grep { $_->{kind} eq 'win' } @legal;
		return $win if $win;
		my ($d) = grep { $_->{kind} eq 'discard' } @legal;
		return $d || $legal[0];
	};
}

sub move_key {
	my ($m) = @_;
	return join ':', $m->{kind}, (defined $m->{tile} ? $m->{tile} : ''), ($m->{tiles} ? join(',', @{ $m->{tiles} }) : '');
}

# play_game(seed => ..., chooser => sub | { seat => sub }, default => sub,
#   check => 1, max_moves => n, on_move => sub($g, $seat, $move), stop_after => n)
# returns ($g, \@bad, \%census)
sub play_game {
	my (%o) = @_;
	my $g = $o{rules} || Game::Mahjong::Rules->new(seed => $o{seed}, ($o{position} ? (position => $o{position}) : ()));
	my $rng = new_rng(($o{seed} // 'x') . ':choose');
	my $default = $o{default} || random_chooser($rng);
	my $chooser = $o{chooser} || {};
	$chooser = { map { $_ => $chooser } 0 .. 3 } if ref $chooser eq 'CODE';
	my $max = $o{max_moves} || 20_000;
	my @bad;
	my %census = (moves => 0, discards => 0, answers => 0, claims => 0, windows => 0, kongs => 0, robs => 0, wins => 0);
	my @events = $g->take_outcomes;
	my $n = 0;

	while ($g->is_active) {
		my @waiting = $g->waiting_on;
		unless (@waiting) { push @bad, 'active with nobody waited on'; last }
		my $seat = $waiting[0];
		my @legal = $g->legal($seat);
		unless (@legal) { push @bad, "seat $seat is waited on with nothing legal"; last }
		my $choose = $chooser->{$seat} || $default;
		my $move = $choose->($g, $seat, @legal);
		my $key = move_key($move);
		unless (grep { move_key($_) eq $key } @legal) {
			die "Play: the chooser for seat $seat picked $key, which is not legal (" . join(' ', map { move_key($_) } @legal) . ")";
		}
		my $before_phase = $g->phase;
		my $r = $g->apply($seat, $move);
		die "Play: seat $seat's $key refused: " . $r->code if ref $r && $r->can('error');
		$census{moves}++;
		$census{discards}++ if $move->{kind} eq 'discard';
		$census{answers}++ if $before_phase ne 'discard';
		$census{claims}++ if $before_phase ne 'discard' && $move->{kind} ne 'pass';
		$census{kongs}++ if $move->{kind} eq 'kong';
		my @out = $g->take_outcomes;
		push @events, @out;
		for my $e (@out) {
			$census{windows}++ if $before_phase eq 'discard' && $e->{kind} eq 'discard' && ($g->phase eq 'claim');
			$census{robs}++ if $e->{kind} eq 'kong' && $g->phase eq 'rob';
			$census{wins}++ if $e->{kind} eq 'hand_end' && defined $e->{winner};
			$census{ 'by_' . $e->{by} }++ if $e->{kind} eq 'hand_end';
		}
		$o{on_move}->($g, $seat, $move, \@out) if $o{on_move};
		if ($o{check}) {
			my @v = $g->check_invariants;
			if (@v) { push @bad, map { "after move $n ($key): $_" } @v; last }
		}
		last if ++$n >= $max;
		last if $o{stop_after} && $n >= $o{stop_after};
	}
	push @bad, "ran past $max moves" if $n >= $max && $g->is_active;
	$census{events} = \@events;
	$census{hands} = scalar @{ $g->history };
	return ($g, \@bad, \%census);
}

1;
