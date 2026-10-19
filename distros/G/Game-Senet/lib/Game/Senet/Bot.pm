package Game::Senet::Bot;

use 5.010;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Object::Proto::Sugar;

use Game::Senet::Engine ();
use Game::Senet::Variant;

our $VERSION = '0.02';

my %LADDER;
BEGIN {
    %LADDER = (
        kendall => [
            { name => 'greedy' },
            { name => 'depth 1', depth => 1 },
            { name => 'depth 2', depth => 2 },
            { name => 'depth 3', depth => 3 },
        ],
        skyruk => [
            { name => 'greedy' },
            { name => 'depth 2', depth => 2, weights => { blockade => 64 } },
            { name => 'depth 3', depth => 3, weights => { blockade => 64 } },
        ],
    );
}

has _level => (is => 'ro', init_arg => 'level', private => 1);

has _budget => (is => 'ro', init_arg => 'budget', private => 1, default => 2_000_000);

sub BUILD {
    my ($self) = @_;
    my $level = $self->_level;
    Carp::croak('Game::Senet::Bot: a level is a whole number from 1')
        unless defined $level && !ref $level && $level =~ /\A[1-9][0-9]*\z/;
    my $budget = $self->_budget;
    Carp::croak('Game::Senet::Bot: a budget is a whole number of nodes from 1 to 2000000000')
        unless defined $budget && $budget =~ /\A[1-9][0-9]{0,9}\z/ && $budget <= 2_000_000_000;
    return;
}

my $ladder_of = sub {
    my ($variant) = @_;
    my $v = Game::Senet::Variant->of($variant);
    return $LADDER{ $v->exits };
};

sub levels {
    my ($class, $variant) = @_;
    my $count = scalar @{ $ladder_of->($variant) };
    return 1 .. $count;
}

sub rung {
    my ($class, $level, $variant) = @_;
    my $ladder = $ladder_of->($variant);
    Carp::croak('Game::Senet::Bot: there is no level ' . ($level // 'undef') . ' under these rules; the levels are 1 to '
        . scalar @$ladder)
        unless defined $level && $level =~ /\A[1-9][0-9]*\z/ && $level <= @$ladder;
    return { %{ $ladder->[ $level - 1 ] } };
}

sub level { $_[0]->_level }

sub budget { $_[0]->_budget }

sub think {
    my ($self, $game) = @_;
    Carp::croak('Game::Senet::Bot: think is asked of a Game::Senet')
        unless Scalar::Util::blessed($game) && $game->isa('Game::Senet');
    return undef if $game->is_over;
    my @legal = $game->legal;
    return undef unless @legal;
    my $variant = $game->variant;
    my $rung = $self->rung($self->_level, $variant);
    my $board = Game::Senet::Engine->new(position => $game->position);
    my $only = $game->turn->{bound} // 0;
    my $rules = $variant->as_hash;

    unless ($rung->{depth}) {
        my $index = $board->greedy($game->roll, $rules, $only);
        return { move => $legal[$index], depth => 0, value => undef, nodes => 0, stopped => 0 };
    }
    my $found = $board->search($game->roll, rules => $rules, weights => $rung->{weights},
        budget => $self->_budget, depth => $rung->{depth}, only => $only);
    return { move => $legal[ $found->{index} ], depth => $found->{depth}, value => $found->{value},
             nodes => $found->{nodes}, stopped => $found->{stopped} };
}

sub choose {
    my ($self, $game) = @_;
    my $thought = $self->think($game);
    return $thought ? $thought->{move} : undef;
}

1;

__END__

=head1 NAME

Game::Senet::Bot - an opponent for Senet, in levels

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Senet;
    use Game::Senet::Bot;

    my $game = Game::Senet->new(seed => 'any bytes at all');
    my $bot  = Game::Senet::Bot->new(level => 3);
    $game->play($bot->choose($game)) until $game->is_over;

    my @levels = Game::Senet::Bot->levels('skyruk');

=head1 DESCRIPTION

A player that chooses a move for whichever side is to throw. Level 1 is a rule
of thumb that looks no further than the throw in hand; the levels above it
search through the sticks, expecting each throw at its chance, a number of
throws deep. Each level is the strongest the measurements could tell apart
from the one below it, under that rule set; the ladder is a rule set's, and the
two named sets may have different numbers of levels.

Nothing here reads a clock: a search is bounded in nodes, so the same game and
level give the same move every time.

=head1 CONSTRUCTOR

=head2 new

    my $bot = Game::Senet::Bot->new(level => $n);
    my $bot = Game::Senet::Bot->new(level => $n, budget => $nodes);

C<level> is a whole number from 1; whether a game's rule set has that many
levels is asked when the bot plays it. C<budget> is a ceiling on the nodes one
search may visit, far above what any level needs.

=head1 METHODS

=head2 choose

    my $move = $bot->choose($game);

One of C<< $game->legal >>, the L<Game::Senet::Move> itself, or C<undef> when
the game is over. B<Croaks> when the game's rule set has no such level.

=head2 think

    my $thought = $bot->think($game);

The move with how it was found: C<< { move, depth, value, nodes, stopped } >>.

=head2 level

=head2 budget

=head2 levels

    my @levels = Game::Senet::Bot->levels($rules);

The levels a rule set has, from 1.

=head2 rung

    my $rung = Game::Senet::Bot->rung($level, $rules);

What a level is under a rule set: C<name>, and C<depth> and C<weights> for a
level that searches. B<Croaks> on a level the rule set does not have.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
