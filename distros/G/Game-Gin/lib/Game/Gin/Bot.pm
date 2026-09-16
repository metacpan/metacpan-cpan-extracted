package Game::Gin::Bot;

use strict;
use warnings;

use Object::Proto::Sugar -types;

use Digest::SHA ();

use Game::Gin::Deadwood qw(deadwood);
use Game::Gin::Search qw(worth_taking best_discard knock_now LEVELS);

our $VERSION = '0.01';

has level => (is => 'ro', isa => Int);
has seed  => (is => 'ro', isa => Str);

sub choose {
    my ($self, $game, $seat) = @_;
    my $deal = $game->can('deal') ? $game->deal : $game;
    return undef unless $deal && !$deal->over;
    return undef unless ($deal->turn // '') eq $seat;

    my $legal = $deal->legal($seat);
    return undef unless @$legal;

    my $level = $self->level || LEVELS;
    my $hand  = $deal->hand_of($seat)->cards;
    my $phase = $deal->phase;

    if ($phase eq 'upcard' || $phase eq 'draw') {
        my $take = worth_taking(hand => $hand, upcard => $deal->upcard, level => $level);
        return { kind => 'take' } if $take && grep { $_->{kind} eq 'take' } @$legal;
        return { kind => 'draw' } if grep { $_->{kind} eq 'draw' } @$legal;
        return { kind => 'pass' } if grep { $_->{kind} eq 'pass' } @$legal;
        return $legal->[0];
    }
    return { kind => 'draw' } if $phase eq 'forced_draw';

    my ($big) = grep { $_->{kind} eq 'big_gin' } @$legal;
    return $big if $big;

    my $card = best_discard(
        hand           => $hand,
        level          => $level,
        just_taken     => ($deal->taken || undef),
    );
    return $legal->[0] unless defined $card;

    my $left = deadwood([ grep { $_ != $card } @$hand ]);
    my $knock = knock_now(deadwood => $left, stock_left => $deal->stock_left, level => $level);

    if ($knock) {
        my ($move) = grep { $_->{kind} eq 'discard' && $_->{card} == $card && $_->{knock} } @$legal;
        return $move if $move;
    }
    my ($move) = grep { $_->{kind} eq 'discard' && $_->{card} == $card && !$_->{knock} } @$legal;
    return $move || $legal->[0];
}

sub seed_for {
    my ($class, $game_seed, $seat) = @_;
    return unpack 'H16', Digest::SHA::sha256('gin-bot:' . ($game_seed // '') . ':' . ($seat // '?'));
}

1;

__END__

=head1 NAME

Game::Gin::Bot - an opponent that can only see what a player can see

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $bot = Game::Gin::Bot->new(level => 2);
    my $move = $bot->choose($game, 'p2');
    $game->apply('p2', $move) if $move;

=head1 DESCRIPTION

Gathers what the seat can see and hands it to L<Game::Gin::Search>, which
decides. Four things cross that boundary: the seat's own hand, the upcard, the
discard pile and how many cards are left. Search has nowhere to put anything
else, which is what stops this reading of the deal becoming a cheat.

=head2 Levels

=over

=item 1

Throws on the count alone and knocks the moment it may. A floor to measure
against rather than a serious opponent.

=item 2

Breaks ties on what a card could still become, so it stops throwing the card
that was one away from a meld, and holds a knock until the count is low enough
to survive an undercut.

=back

There is no level 3. One was written, measured against level 2 over a hundred
matches a side, and removed for losing 47-53 and for failing to finish three
matches in two hundred. L<Game::Gin::Search/knock_now> carries the numbers.

=head1 METHODS

=head2 choose

    $bot->choose($game, $seat);

A move hashref from the seat's legal moves, or undef when it is not this
seat's turn.

=head2 seed_for

    Game::Gin::Bot->seed_for($game_seed, $seat);

A per-seat seed derived from the game's. Derived, because a bot holding the
game seed could deal out the stock it is meant to be guessing at; per seat,
because two bots sharing one seed are one bot.

=head2 level, seed

What was passed in.

=head1 SEE ALSO

L<Game::Gin::Search>, L<Game::Gin>.

=head1 AUTHOR

LNATION, C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
