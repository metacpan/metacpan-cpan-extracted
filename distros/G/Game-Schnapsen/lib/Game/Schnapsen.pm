package Game::Schnapsen;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Game::Schnapsen::Card ();
use Game::Schnapsen::Deck ();
use Game::Schnapsen::Deal ();
use Game::Schnapsen::Error ();
use Game::Schnapsen::Variant ();

our $VERSION = '0.01';

has variant => (is => 'ro', isa => Str);
has seed    => (is => 'ro', isa => Str);
has dealer  => (is => 'rw', isa => Str);
has deal    => (is => 'rw', isa => Object);
has number  => (is => 'rw', isa => Int);
has scores  => (is => 'rw', isa => HashRef);
has deals   => (is => 'rw', isa => ArrayRef);
has result  => (is => 'rw', isa => HashRef);

sub variants { return Game::Schnapsen::Variant::variants() }

sub other { return $_[0] eq 'p1' ? 'p2' : 'p1' }

sub build {
    my ($class, %o) = @_;

    my $bad = Game::Schnapsen::Variant::check_variant($o{variant});
    return $bad if $bad;

    my $seed = $o{seed};
    return Game::Schnapsen::Error->new_code('no_seed')
        unless defined $seed && length $seed == 32;

    my $dealer = $o{dealer} || 'p1';
    my $start  = Game::Schnapsen::Variant::match_start($o{variant});

    my $deal = Game::Schnapsen::Deal->build(
        variant => $o{variant}, seed => $seed, number => 1, dealer => $dealer);
    return $deal if ref $deal eq 'Game::Schnapsen::Error';

    return $class->new(
        variant => $o{variant},
        seed    => $seed,
        dealer  => $dealer,
        number  => 1,
        deal    => $deal,
        scores  => { p1 => $start, p2 => $start },
        deals   => [],
        result  => undef,
    );
}

sub over   { return $_[0]->result ? 1 : 0 }
sub winner { return $_[0]->result ? $_[0]->result->{winner} : undef }

sub turn  { my $s = $_[0]; return undef if $s->over; return $s->deal->turn }
sub legal { my ($s, $seat) = @_; return [] if $s->over; return $s->deal->legal($seat) }

sub to_win {
    my ($self, $seat) = @_;
    my $v = $self->variant;
    my $target = Game::Schnapsen::Variant::match_target($v);
    my $score  = $self->scores->{$seat};
    my $left = Game::Schnapsen::Variant::match_direction($v) > 0
             ? $target - $score
             : $score - $target;
    return $left > 0 ? $left : 0;
}

sub apply {
    my ($self, $seat, $move) = @_;
    return Game::Schnapsen::Error->new_code('game_over') if $self->over;

    my @out = $self->deal->apply($seat, $move);
    return $out[0] if @out == 1 && ref $out[0] eq 'Game::Schnapsen::Error';

    return @out unless $self->deal->over;
    return (@out, $self->_settle);
}

sub _next_dealer {
    my ($self, $r) = @_;
    return other($self->dealer)
        if Game::Schnapsen::Variant::next_dealer($self->variant) eq 'alternate';
    return $r->{winner} || $self->dealer;
}

sub _settle {
    my ($self) = @_;
    my $v = $self->variant;
    my $r = $self->deal->result;

    $self->deals([ @{ $self->deals }, { %$r, number => $self->number } ]);

    if ($r->{winner}) {
        my $s = { %{ $self->scores } };
        $s->{ $r->{winner} } +=
            Game::Schnapsen::Variant::match_direction($v) * $r->{game_points};
        $self->scores($s);

        if (Game::Schnapsen::Variant::match_over($v, $s->{ $r->{winner} })) {
            my $m = {
                winner => $r->{winner},
                loser  => other($r->{winner}),
                scores => { %$s },
                deals  => scalar @{ $self->deals },
            };
            $self->result($m);
            return { kind => 'game_end', %$m };
        }
    }

    $self->dealer($self->_next_dealer($r));
    $self->number($self->number + 1);

    my $d = Game::Schnapsen::Deal->build(
        variant => $v, seed => $self->seed,
        number => $self->number, dealer => $self->dealer);
    $self->deal($d);

    return { kind => 'deal', number => $self->number, dealer => $self->dealer,
             trump => $d->trump, turn_up => $d->turn_up };
}

1;

__END__

=head1 NAME

Game::Schnapsen - Schnapsen and Sixty-Six, two games and one engine

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Schnapsen;

    my $game = Game::Schnapsen->build(
        variant => 'schnapsen',
        seed    => $thirty_two_bytes,
        dealer  => 'p1',
    );

    $game->turn;                 # 'p2', the non-dealer leads
    $game->legal('p2');          # what they may do

    my @out = $game->apply('p2', { kind => 'lead', card => $id });

    $game->scores;               # { p1 => 7, p2 => 5 }
    $game->to_win('p2');         # 5
    $game->over;                 # 1 once somebody reaches the target
    $game->winner;

=head1 DESCRIPTION

Schnapsen is the Austrian two-player point-trick game, and Sixty-Six is its
German parent. They share a pack, a card point table and the whole shape of a
deal, and differ in thirteen places that L<Game::Schnapsen::Variant> enumerates.
Both are implemented here, and C<variant> decides which is being played.

It is the engine behind the two games at L<https://peer2peergames.com>.

The engine does no input and no output: it never prints, never reads a handle
and never calls C<rand>. A match is a pure function of its seed and its moves, so
a finished match can be replayed and checked by anybody once the seed is
published. L<Game::Schnapsen::Terminal> is the only part of this distribution
that touches a handle.

=head2 The score runs the way its game runs

B<Sixty-Six> counts up from nothing: "The first player whose cumulative score
reaches 7 or more game points wins the game."

B<Schnapsen> counts down: "Both players start with 7 game points, and subtract
the game points they win. The overall winner is the first player whose score
reaches or passes zero."

C<scores> is one number per player in that game's own direction, and it is not
normalised. A Schnapsen player's score really is 7, then 5, then 2, then 0, which
is what a scoreboard shows and what a rules page says. Storing points won and
presenting a direction would give the engine and its consumer two numbers that
can drift apart, so L<Game::Schnapsen::Variant/match_over> is a predicate on the
game's own number instead.

B<That makes zero a winning score in Schnapsen rather than a starting one.> A
consumer guarding a score with a plain truth test finds it false at exactly the
moment it matters. C<to_win> exists so that nothing downstream has to do this
arithmetic, and so that no template has to do arithmetic at all.

=head2 Who deals next

Schnapsen alternates. Sixty-Six gives the deal to the winner of the deal.

A drawn Sixty-Six deal has no winner, so there is nobody to give it to and the
dealer deals again. Neither page says so, because neither page raises the
question; it is an inference, and it is recorded here as one rather than
presented as sourced.

=head2 A drawn deal has to travel

Only Sixty-Six can draw a deal, and when it does the deal pays nobody, ends
nothing and is played again. Four separate things have to be right: it must not
move the score, must not end the match, must not rotate the dealer, and must
still advance the deal number. Nothing else on this engine's roster has a drawn
deal inside a match, so it is the result most likely to be dropped on the way
through.

=head1 METHODS

=head2 build

    Game::Schnapsen->build(variant => ..., seed => ..., dealer => ...);

A new match, or a L<Game::Schnapsen::Error> for a variant this engine does not
play or a seed that is not 32 bytes. C<dealer> is who deals the first deal and
defaults to C<p1>; the other seat leads to the first trick.

=head2 variant, seed, dealer, number, deal

What the match was built with, who is dealing now, which deal this is, and the
L<Game::Schnapsen::Deal> in progress.

=head2 turn, legal, apply

Delegated to the current deal, and empty or refused once the match is over.

C<apply> returns the deal's outcomes, and when a deal ends it appends the
C<deal_end> the deal produced and then either a C<deal> for the next one or a
C<game_end>. So a caller never has to ask whether a deal has finished.

=head2 scores, to_win

The running score for each seat, in its game's direction, and how much each still
needs. C<to_win> never goes below zero, because a Schnapsen score can pass the
target rather than land on it.

Note for a consumer whose interface wants richer scores: this is a plain number
per seat. Anything with a shape to it is the consumer's to build.

=head2 deals

Every finished deal's result, in order, each with the C<number> it was.

=head2 over, winner, result

Whether the match has finished, who won, and the whole verdict as
C<{ winner, loser, scores, deals }>.

=head2 variants

The variant names this engine plays, sorted.

=head2 other

    Game::Schnapsen::other('p1');   # 'p2'

The other seat.

=head1 SEE ALSO

L<Game::Schnapsen::Variant> for the thirteen differences between the two games,
L<Game::Schnapsen::Deal>, L<Game::Schnapsen::Scoring>.

L<Game::Gin>, L<Game::Dominoes> and L<Game::Cribbage> are built the same way.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-schnapsen at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Schnapsen>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
