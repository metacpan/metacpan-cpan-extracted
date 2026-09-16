package Game::Dominoes::Bot;

use strict;
use warnings;

use Digest::SHA ();
use Object::Proto::Sugar -types;

use Game::Dominoes::Hand;
use Game::Dominoes::Rules;
use Game::Dominoes::Scoring;
use Game::Dominoes::Set;

our $VERSION = '0.01';

our %LEVEL = (
	1 => { worlds => 0,  depth => 0,  shape => 0 },
	2 => { worlds => 0,  depth => 0,  shape => 1 },
	3 => { worlds => 24, depth => 8,  shape => 1 },
	4 => { worlds => 40, depth => 12, shape => 1 },
	5 => { worlds => 64, depth => 16, shape => 1 },
);

our $SAMPLE_TRIES = 40;

has level => (is => 'ro', isa => Int, default => 3);
has seed => (is => 'ro', isa => Int, default => 0);
has last_search => (is => 'rw', isa => HashRef, default => {});

sub BUILD {
	my ($self) = @_;
	die 'Game::Dominoes::Bot: level must be 1 to 5' unless $LEVEL{ $self->level };
	return $self;
}

sub levels { return { %LEVEL } }

sub _stream {
	my ($self, $key) = @_;
	my ($counter, @words) = (0);
	return sub {
		unless (@words) {
			@words = unpack 'N8',
				Digest::SHA::sha256($self->seed . '|' . $key . '|' . $counter++);
		}
		return shift @words;
	};
}

sub _public_key {
	my ($self, $view) = @_;
	my @parts = (
		$view->{seat}, $view->{players}, $view->{hand_number},
		$view->{turn} // '-', $view->{boneyard},
		join(',', map { $_ . ':' . $view->{counts}{$_} } sort keys %{ $view->{counts} }),
		join(',', map { $_ . ':' . $view->{scores}{$_} } sort keys %{ $view->{scores} }),
		join(',', map { $_->stringify } @{ $view->{layout}->tiles }),
		join(',', @{ $view->{ends} }),
		join(',', map { $_->stringify } @{ $view->{hand} || [] }),
	);
	return join '|', @parts;
}

sub _shuffle {
	my ($list, $next) = @_;
	for (my $i = $#$list; $i > 0; $i--) {
		my $n = $i + 1;
		my $limit = int(4294967296 / $n) * $n;
		my $word;
		do { $word = $next->() } while $word >= $limit;
		my $j = $word % $n;
		@{$list}[ $i, $j ] = @{$list}[ $j, $i ];
	}
	return $list;
}

sub _unseen {
	my ($self, $view) = @_;
	my %seen;
	$seen{ $_->id } = 1 for @{ $view->{layout}->tiles };
	$seen{ $_->id } = 1 for @{ $view->{hand} || [] };
	return [ grep { !$seen{ $_->id } } @{ Game::Dominoes::Set::tiles() } ];
}

sub _sample {
	my ($self, $view, $next) = @_;

	my $unseen = $self->_unseen($view);
	my @others = grep { $_ ne $view->{seat} } sort keys %{ $view->{counts} };
	my $deductions = $view->{deductions} || {};

	my $best;
	for my $try (1 .. $SAMPLE_TRIES) {
		my @pool = @$unseen;
		_shuffle(\@pool, $next);

		my (%hands, $bad);
		for my $seat (@others) {
			my $want = $view->{counts}{$seat};
			my @take = splice @pool, 0, $want;
			$hands{$seat} = \@take;
			next unless $deductions->{$seat} && keys %{ $deductions->{$seat} };
			for my $tile (@take) {
				next unless $deductions->{$seat}{ $tile->high }
					|| $deductions->{$seat}{ $tile->low };
				$bad = 1;
				last;
			}
			last if $bad;
		}

		my $world = { hands => \%hands, boneyard => [@pool] };
		$best = $world unless $best;
		return $world unless $bad;
	}

	return $best;
}

sub _rollout {
	my ($self, $view, $world, $first, $depth) = @_;

	my $seat = $view->{seat};
	my $layout = $view->{layout}->clone;
	my %hand = (
		$seat => Game::Dominoes::Hand->new(tiles => [ @{ $view->{hand} || [] } ]),
		map { $_ => Game::Dominoes::Hand->new(tiles => [ @{ $world->{hands}{$_} } ]) }
			keys %{ $world->{hands} },
	);
	my @yard = @{ $world->{boneyard} };

	$hand{$seat}->remove($first->{tile});
	$layout->place($first->{tile}, $first->{arm});
	my $score = Game::Dominoes::Scoring::score_for(
		Game::Dominoes::Scoring::count($layout), $view->{scale}
	);
	return $score + _out_bonus($view, \%hand, $seat) if $hand{$seat}->is_empty;

	my @seats = sort { $a <=> $b } keys %hand;
	my $at = 0;
	$at++ while $at < $#seats && $seats[$at] != $seat;

	for my $ply (1 .. $depth) {
		$at = ($at + 1) % @seats;
		my $who = $seats[$at];
		my $moves = Game::Dominoes::Rules::candidates($layout, $hand{$who});

		unless (@$moves) {
			while (@yard) {
				$hand{$who}->add(shift @yard);
				$moves = Game::Dominoes::Rules::candidates($layout, $hand{$who});
				last if @$moves;
			}
			next unless @$moves;
		}

		my $best = $moves->[0];
		my $best_points = -1;
		for my $move (@$moves) {
			my $points = Game::Dominoes::Rules::score_of(
				$layout, $move->{tile}, $move->{arm}, $view->{scale}
			);
			next unless $points > $best_points;
			($best, $best_points) = ($move, $points);
		}

		$hand{$who}->remove($best->{tile});
		$layout->place($best->{tile}, $best->{arm});
		my $points = Game::Dominoes::Scoring::score_for(
			Game::Dominoes::Scoring::count($layout), $view->{scale}
		);
		$score += $who eq $seat ? $points : -$points;
		return $score + ($who eq $seat ? 1 : -1) * _out_bonus($view, \%hand, $who)
			if $hand{$who}->is_empty;
	}

	return $score - $hand{$seat}->pips / 5;
}

sub _out_bonus {
	my ($view, $hands, $who) = @_;
	my $pips = 0;
	$pips += $hands->{$_}->pips for grep { $_ ne $who } keys %$hands;
	return Game::Dominoes::Scoring::bonus($pips, $view->{scale});
}

sub _shape {
	my ($self, $view, $move) = @_;
	my $tile = $move->{tile};
	return $tile->pips / 100 + ($tile->is_double ? 0.05 : 0);
}

sub choose {
	my ($self, $game, $seat) = @_;

	my $view = (ref $game eq 'HASH') ? $game : $game->view($seat);
	return undef unless $view->{hand} && @{ $view->{hand} };

	my $hand = Game::Dominoes::Hand->new(tiles => [ @{ $view->{hand} } ]);
	my $moves = Game::Dominoes::Rules::candidates($view->{layout}, $hand);
	if (my $forced = $view->{forced}) {
		$moves = [ grep { $_->{tile}->id == $forced->id } @$moves ];
	}
	return undef unless @$moves;

	my $level = $LEVEL{ $self->level };
	my $key = $self->_public_key($view);

	my @scored;
	for my $move (@$moves) {
		my $points = Game::Dominoes::Rules::score_of(
			$view->{layout}, $move->{tile}, $move->{arm}, $view->{scale}
		);
		push @scored, {
			move => $move,
			score => $points + ($level->{shape} ? $self->_shape($view, $move) : 0),
			points => $points,
		};
	}

	my $worlds = 0;
	if ($level->{worlds}) {
		my $next = $self->_stream($key);
		my @sampled = map { $self->_sample($view, $next) } 1 .. $level->{worlds};
		$worlds = scalar @sampled;

		for my $candidate (@scored) {
			my $total = 0;
			$total += $self->_rollout($view, $_, $candidate->{move}, $level->{depth})
				for @sampled;
			$candidate->{score} = $total / $worlds;
		}
	}

	my @order = sort {
		$b->{score} <=> $a->{score}
		  || $b->{move}{tile}->pips <=> $a->{move}{tile}->pips
		  || $a->{move}{tile}->id <=> $b->{move}{tile}->id
		  || $a->{move}{arm} cmp $b->{move}{arm}
	} @scored;

	$self->last_search({
		level => $self->level,
		worlds => $worlds,
		depth => $level->{depth},
		considered => scalar @scored,
		score => $order[0]{score},
		points => $order[0]{points},
		play => $order[0]{move},
	});

	return $order[0]{move};
}

1;

__END__

=head1 NAME

Game::Dominoes::Bot - a determinised search that plays without peeking

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

	use Game::Dominoes;
	use Game::Dominoes::Bot;

	my $game = Game::Dominoes->new(seed => $bytes, players => 2);
	my $bot = Game::Dominoes::Bot->new(level => 3, seed => 12345);

	while ($game->status eq 'active') {
	    my $move = $bot->choose($game, $game->turn);
	    $game->play($game->turn, $move);
	}

	$bot->last_search->{worlds};   # what the last move cost

=head1 DESCRIPTION

Dominoes hides the other hands and the boneyard, so this bot is built the way
cribbage's is and not the way checkers' is: B<it is handed one seat's view and
reads nothing else>. Not C<hand($other)>, not the boneyard's tiles, not the
seed. C<t/19-bot-blind.t> proves that rather than trusting it.

=head2 How it plays

Levels 1 and 2 are greedy: take the highest scoring play, with a small term at
level 2 for keeping a useful hand shape.

Levels 3 and up B<determinise>. Sample a number of complete worlds consistent
with what the seat can see, play each one out greedily, and average. This is
the standard approach for trick and tile games.

=head2 Its weakness, named so nobody rediscovers it as a bug

A determinised search assumes it will know the hidden tiles from the next move
onward. So B<it never plays to gain information>, and it overvalues plays whose
payoff depends on a tile falling a particular way. It will occasionally make a
move a good human can see is optimistic.

That is the algorithm and not a defect. The fix, if one is ever wanted, is a
different algorithm and a different plan, not a tweak here.

It also models every opponent as greedy inside a rollout, which is cheap and
wrong in the same direction for everybody.

=head2 Sampling, which is where the strength comes from

A uniform guess at the hidden tiles is legal and weak. These constraints are
what make the bot worth playing, and every one is public:

=over

=item *

Hand sizes are public, so each sampled hand gets exactly its known count.

=item *

Tiles on the table and in our own hand are excluded.

=item *

B<A seat that passed holds nothing matching the ends that were open then.>
This is the deduction a good human player is making. It is a hard rejection
rather than a weight, because a world that violates it is impossible.

=back

The pass deduction is sound for the rest of the hand, not just the moment it
was made: a pass only happens once the boneyard is exhausted, so no tile ever
enters that hand afterwards and the hand only shrinks.

B<A draw is deliberately not used as a constraint.> A seat that drew was short
of the ends open at that moment, but the tiles it held then are mixed in with
what it drew, and nothing public says which are which. Applying it as though
the whole current hand were constrained would be unsound, so it is recorded in
the log and not used.

If the constraints make a world hard to find, the sampler gives up after
C<$SAMPLE_TRIES> attempts and takes the loosest consistent sample. A bot that
hangs inside a database transaction is worse than a bot that plays weakly.

=head2 This class cannot be subclassed, and the failure is silent

L<Object::Proto::Sugar> installs C<new> so that it blesses into the class that
declared the attributes, B<not> into the invocant. So this:

	package My::Bot;
	our @ISA = ('Game::Dominoes::Bot');
	sub choose { ... }              # never runs

hands back a plain C<Game::Dominoes::Bot>, and the override is never reached.
Nothing warns. C<ref $bot> is the only thing that gives it away.

To wrap this bot, B<compose it> rather than inherit from it: hold one as an
attribute and call through to it. The site adapter does exactly that, and
C<t/19-bot-blind.t> builds its deliberately cheating bot as a standalone
package for the same reason, having first been written as a subclass and
having silently passed for the wrong reason.

=head2 Budgets are in worlds and plies, never in seconds

A loaded smoker must return the same play as an idle laptop, because a game log
that cannot be replayed is not a game log. Nothing here reads a clock and no
test asserts a duration.

The randomness comes from the bot's own seed and the public state, B<never from
the game's seed>. The game seed generates the shuffle the bot is trying to
estimate, so a sampler that reached for it would reconstruct the hands it is
guessing at, and the bot would become a cheat through a line that looks like
plumbing.

=head1 PROPERTIES

=head2 level

	$bot->level;   # 1 to 5

How hard it plays. Levels 1 and 2 do not sample. See C<levels>.

=head2 seed

	$bot->seed;

The bot's own seed, which together with the public state decides every sample.
Two bots with the same seed and level choose identically from the same view.

=head2 last_search

	$bot->last_search;
	# { level, worlds, depth, considered, score, points, play }

What the last call to C<choose> cost and decided.

=head1 FUNCTIONS

=head2 choose

	my $move = $bot->choose($game, $seat);
	my $move = $bot->choose($view);

The play to make, as one of the C<< { tile, arm } >> hashrefs
L<Game::Dominoes::Rules> generates, or undef when there is nothing to play.

Accepts a L<Game::Dominoes> and a seat, or a view on its own. Either way only
the view is read.

Equal scores are broken by the heavier tile, then the canonical tile id, then
the arm order, so the choice is total and the same on every machine and every
perl.

=head2 levels

	Game::Dominoes::Bot->levels;

The level table as a hashref, for a caller that wants to show what a level
means.

=head1 SEE ALSO

L<Game::Dominoes>, whose C<view> this reads;
L<Game::Dominoes::Rules>, which generates the moves.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-dominoes at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Dominoes>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Game::Dominoes::Bot

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
