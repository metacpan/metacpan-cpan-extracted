package Game::Schnapsen::Bot;

use strict;
use warnings;

use Digest::SHA ();
use Object::Proto::Sugar -types;

use Game::Schnapsen::Scoring qw(TARGET_POINTS);
use Game::Schnapsen::Search qw(best_lead best_follow best_marriage
                               should_close should_claim LEVELS);

our $VERSION = '0.01';

our @LADDER = (1, 1, 2, 2, 2);

has level => (is => 'ro', isa => Int);
has seed  => (is => 'ro', isa => Str);

sub levels { return LEVELS }

sub seed_for {
    my ($self, $seat, $ply) = @_;
    return Digest::SHA::sha256_hex(($self->seed // '') . ":$seat:$ply");
}

sub _public {
    my ($self, $game, $seat) = @_;
    my $deal = $game->deal;
    my $them = $seat eq 'p1' ? 'p2' : 'p1';

    return (
        level        => $self->level || 1,
        trump        => $deal->trump,
        phase        => $deal->phase,
        talon_left   => $deal->talon_left,
        closed       => $deal->closed,
        turn_up      => $deal->turn_up,
        my_points    => $deal->points_of($seat),
        their_points => $deal->points_of($them),
        their_tricks => $deal->tricks_won($them),
        target       => TARGET_POINTS,
    );
}

sub choose {
    my ($self, $game, $seat) = @_;
    return undef if $game->over;

    my $legal = $game->legal($seat);
    return undef unless @$legal;

    my $deal = $game->deal;
    my %o = $self->_public($game, $seat);
    my %by;
    push @{ $by{ $_->{kind} } }, $_ for @$legal;

    if ($by{exchange}) {
        return $by{exchange}[0];
    }

    if ($by{marriage}) {
        my $suit = best_marriage(%o, marriages => $by{marriage});
        my ($pick) = grep { $_->{suit} eq $suit } @{ $by{marriage} };
        return $pick if $pick;
    }

    if ($by{claim} && should_claim(%o)) {
        return $by{claim}[0];
    }

    if ($by{close}
        && should_close(%o, cards => $deal->hand_of($seat)->cards)) {
        return $by{close}[0];
    }

    if ($by{lead}) {
        my $card = best_lead(%o, cards => [ map { $_->{card} } @{ $by{lead} } ]);
        my ($pick) = grep { $_->{card} == $card } @{ $by{lead} };
        return $pick if $pick;
    }

    if ($by{follow}) {
        my $card = best_follow(%o, led => $deal->lead,
                               cards => [ map { $_->{card} } @{ $by{follow} } ]);
        my ($pick) = grep { $_->{card} == $card } @{ $by{follow} };
        return $pick if $pick;
    }

    return $by{draw}[0] if $by{draw};
    return $legal->[0];
}

1;

__END__

=head1 NAME

Game::Schnapsen::Bot - an opponent

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $bot = Game::Schnapsen::Bot->new(level => 2, seed => $game->seed);

    while (!$game->over) {
        my $seat = $game->turn;
        my $move = $bot->choose($game, $seat);
        $game->apply($seat, $move);
    }

=head1 DESCRIPTION

Picks one of the moves the game is already offering. It never constructs a move
of its own, so it cannot play an illegal one however wrong its judgement is.

=head2 It is given the game, and passes on only what a player could see

C<choose> takes the whole game, because it has to ask what is legal. What it
hands to L<Game::Schnapsen::Search> is its own hand and the public state: the
trump, the phase, the B<count> of cards left in the talon, the turn-up, its own
card points, and the opponent's card points and trick count, which are public
because both players count openly in this family.

The opponent's hand and the order of the talon are never passed on, and
C<Game::Schnapsen::Search>'s signatures cannot accept them anyway. That is the
defence; this method is the place it could be undone, so it is kept short enough
to read in one go.

=head2 The order it decides in

An exchange first, because taking the turn-up for the lowest trump is never
worse. Then a marriage, because twenty or forty is free once a trick has been
taken, and declaring before claiming can put the claim over the line. Then a
claim, then a close, then the card to play. A draw is what is left when nothing
else applies, which is Sixty-Six declining to close.

=head2 Claiming is conservative, always

The rules offer a claim on timing alone, so a bot that guessed would hand over
two or three game points and make a level ladder meaningless. This one claims
only on a real 66, at every level, and the bot gate asserts zero false claims
across every match it plays.

=head2 The ladder

C<@LADDER> is a bag rather than a list: repeats weight it, and it is sorted
weakest first because a caller wanting the strongest rung reaches for the last
element. A consumer draws one rung per match from it.

The rungs shipped are the ones that were B<measured> to differ. More search is
not automatically better, and a ladder whose rungs play alike is a ladder that
says something untrue about the opponent a player is facing.

=head1 METHODS

=head2 new

    Game::Schnapsen::Bot->new(level => 2, seed => $seed);

=head2 level, seed

The rung it plays at, and the seed its tie-breaks are drawn from.

=head2 choose

    $bot->choose($game, $seat);

One of the moves C<< $game->legal($seat) >> offered, or undef if there are none
or the match is over.

=head2 seed_for

A deterministic value per seat and ply, so that two bots in one match do not play
identically and neither calls C<rand>.

=head2 levels

How many levels the search offers.

=head1 SEE ALSO

L<Game::Schnapsen::Search>, L<Game::Schnapsen>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
