package Game::RoyalUr::Rules;

use 5.010;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Object::Proto::Sugar;

use Game::RoyalUr::Engine qw(SIDE_LIGHT SIDE_DARK WON DRAWN BY_HOME BY_PLY_CAP);

our $VERSION = '0.01';

my $E = 'Game::RoyalUr::Engine';

my (@SIDE_NAME, %SIDE_OF);
BEGIN {
    @SIDE_NAME = ('light', 'dark');
    %SIDE_OF   = (light => SIDE_LIGHT, dark => SIDE_DARK);
}

has _given => (is => 'ro', init_arg => 'rules', private => 1);

has _position => (is => 'ro', init_arg => 'position', private => 1);

has _first => (is => 'ro', init_arg => 'first', private => 1);

has _start_ply => (is => 'ro', init_arg => 'ply', private => 1);

has _engine => (is => 'rw', private => 1);

has _spelled => (is => 'rw', private => 1);

has _stack => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    my $spelled = $E->rules($self->_given);
    $self->_spelled($spelled);
    $self->_stack([]);

    my $position = $self->_position;
    my $engine = defined $position
        ? $E->new(position => $position)
        : $E->new(pieces => $spelled->{pieces});

    my $first = $self->_first;
    if (defined $first) {
        Carp::croak("Game::RoyalUr::Rules: first is 'light' or 'dark'")
            unless exists $SIDE_OF{$first};
        $engine->set_side($SIDE_OF{$first});
    }

    my $ply = $self->_start_ply;
    if (defined $ply) {
        Carp::croak('Game::RoyalUr::Rules: ply is a whole number from 0 up')
            unless $ply =~ /\A\d+\z/;
        $engine->set_ply($ply);
    }

    $self->_engine($engine);
    return;
}

sub rules { return { %{ $_[0]->_spelled } } }

sub side { $SIDE_NAME[ $_[0]->_engine->side ] }

sub ply { $_[0]->_engine->ply }

sub position { $_[0]->_engine->to_string }

sub key { $_[0]->_engine->key_hex }

sub board { $_[0]->_engine->clone }

sub hand {
    my ($self, $side) = @_;
    Carp::croak("Game::RoyalUr::Rules: a side is 'light' or 'dark'") unless exists $SIDE_OF{ $side // '' };
    return $self->_engine->hand($SIDE_OF{$side});
}

sub home {
    my ($self, $side) = @_;
    Carp::croak("Game::RoyalUr::Rules: a side is 'light' or 'dark'") unless exists $SIDE_OF{ $side // '' };
    return $self->_engine->home($SIDE_OF{$side});
}

sub status {
    my ($self) = @_;
    my $status = $self->_engine->status($self->_spelled);
    return $status == WON ? 'won' : $status == DRAWN ? 'drawn' : 'ongoing';
}

sub how {
    my ($self) = @_;
    my $how = $self->_engine->how($self->_spelled);
    return $how == BY_HOME ? 'home' : $how == BY_PLY_CAP ? 'ply_cap' : undef;
}

sub winner {
    my ($self) = @_;
    my $winner = $self->_engine->winner($self->_spelled);
    return $winner < 0 ? undef : $SIDE_NAME[$winner];
}

sub is_over { $_[0]->status ne 'ongoing' }

sub moves {
    my ($self, $roll) = @_;
    return wantarray ? () : 0 if $self->is_over;
    return $self->_engine->moves($roll, $self->_spelled);
}

sub apply {
    my ($self, $move) = @_;
    Carp::croak('Game::RoyalUr::Rules: apply takes a move')
        unless Scalar::Util::blessed($move) && $move->isa('Game::RoyalUr::Move');
    return undef if $self->is_over;
    return undef if $move->side ne $self->side;
    my $undo = $self->_engine->apply($move, $self->_spelled);
    return undef unless defined $undo;
    push @{ $self->_stack }, $undo;
    return $move;
}

sub forfeit {
    my ($self) = @_;
    return 0 if $self->is_over;
    push @{ $self->_stack }, $self->_engine->forfeit;
    return 1;
}

sub undo {
    my ($self) = @_;
    my $undo = pop @{ $self->_stack };
    return 0 unless defined $undo;
    $self->_engine->unapply($undo);
    return 1;
}

sub depth { scalar @{ $_[0]->_stack } }

1;

__END__

=head1 NAME

Game::RoyalUr::Rules - a position of the Royal Game of Ur, and how it changes

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::RoyalUr::Rules;

    my $game = Game::RoyalUr::Rules->new(rules => 'finkel');

    my @moves = $game->moves(3);          # what a roll of 3 allows
    if (@moves) { $game->apply($moves[0]) }
    else        { $game->forfeit }

    print $game->side, " to move\n";      # asked, never assumed
    print $game->winner, " wins\n" if $game->status eq 'won';

    $game->undo;

=head1 DESCRIPTION

A game without its dice. This class holds a position under a rule set and
changes it one move at a time: it says what a roll allows, makes a move, loses
a turn, takes either back, says whose turn it is and whether the game is over.

B<It is handed every roll.> It holds no seed and throws nothing, which is what
lets a game be scripted from a list of rolls. L<Game::RoyalUr> joins this to
the dice, and is what most callers want.

=head2 Whose turn it is

Turns do not alternate. A piece that lands on a rosette earns its side another
roll, so the same side is to move again; a move anywhere else, a move that
takes a piece home, and a turn lost to the roll all pass the turn. C<side> is
the only place to find out. Ask it after every C<apply> and every C<forfeit>.

=head2 A captured piece

A piece that lands on an enemy piece sends it back to its owner's hand, to
start again from the beginning.

=head2 How a game ends

A side wins the moment its last piece comes home, on the move that brings it,
whatever the other side has left.

A game is drawn when the count of plies reaches a cap. A move is a ply and so
is a lost turn. The cap exists because a capture sends a piece back to the
start, so nothing else guarantees that a game ends; it is set far above the
length of any game play produces.

Once a game is over, C<moves> answers nothing and C<apply> and C<forfeit>
refuse.

=head1 METHODS

=head2 new

    my $game = Game::RoyalUr::Rules->new;
    my $game = Game::RoyalUr::Rules->new(rules => 'masters', first => 'dark');
    my $game = Game::RoyalUr::Rules->new(position => '4xx2/3l4/4xx2 d 6 0 7 0');

=over 4

=item C<rules>

A rule set: a name or a hash reference, as L<Game::RoyalUr::Engine/A RULE SET>
describes. C<'finkel'> when it is left out.

=item C<position>

A position string to start from. Without one the board is empty and every
piece is in hand.

=item C<first>

C<'light'> or C<'dark'>: the side to move, overriding the position's.

=item C<ply>

The count of plies to start from, 0 when it is left out.

=back

B<Croaks> on a rule set, a position, a side or a count it will not take.

=head2 rules

The rule set, spelled out as a hash reference with all five fields. A copy:
changing it changes nothing.

=head2 side

C<'light'> or C<'dark'>: the side to move.

=head2 moves

    my @moves = $game->moves($roll);

The L<Game::RoyalUr::Move> objects a roll allows the side to move, a piece
entering from the hand first and then the pieces in the order they stand along
the route. In scalar context, how many. None for a roll of 0, and none once
the game is over.

=head2 apply

    $game->apply($move) or die;

Makes one of the moves C<moves> returned, and returns it. Returns C<undef>,
and changes nothing, when the game is over, when the move belongs to the side
not to move, or when the piece it names is not there.

It does not check the move against a roll. That is for whoever holds the dice.

=head2 forfeit

    $game->forfeit;

Loses the turn: the other side is to move. True when done, false when the game
is over.

=head2 undo

    $game->undo;

Takes back the last C<apply> or C<forfeit>, exactly. True when something was
taken back, false when there was nothing left to take.

=head2 depth

How many moves and forfeits C<undo> could still take back.

=head2 status

C<'ongoing'>, C<'won'> or C<'drawn'>.

=head2 is_over

True when C<status> is not C<'ongoing'>.

=head2 how

C<'home'> when a side has brought its last piece home, C<'ply_cap'> when the
game ran to the cap, and C<undef> while it is still being played.

=head2 winner

C<'light'> or C<'dark'>, or C<undef> when nobody has won.

=head2 ply

How many moves and forfeits have been made.

=head2 position

The position as a string. See L<Game::RoyalUr::Engine/to_string>.

=head2 key

Twelve hexadecimal characters that stand for the position. See
L<Game::RoyalUr::Engine/The key is a hex string, never a number>.

=head2 hand

    my $waiting = $game->hand('light');

How many of a side's pieces have not yet entered the board.

=head2 home

    my $finished = $game->home('dark');

How many of a side's pieces have come home.

=head2 board

A L<Game::RoyalUr::Engine> in the same position. It is a copy: changing it
does not change the game.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
