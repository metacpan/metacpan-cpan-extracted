package Game::Senet::Rules;

use 5.010;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Object::Proto::Sugar;

use Game::Senet::Engine qw(SIDE_LIGHT SIDE_DARK LIGHT DARK WON DRAWN BY_HOME BY_PLY_CAP);

our $VERSION = '0.02';

my $E = 'Game::Senet::Engine';

my (@SIDE_NAME, %SIDE_OF);
BEGIN {
    @SIDE_NAME = ('light', 'dark');
    %SIDE_OF   = (light => SIDE_LIGHT, dark => SIDE_DARK);
}

has _given => (is => 'ro', init_arg => 'rules', private => 1);

has _position => (is => 'ro', init_arg => 'position', private => 1);

has _first => (is => 'ro', init_arg => 'first', private => 1, default => 'light');

has _engine => (is => 'rw', private => 1);

has _spelled => (is => 'rw', private => 1);

has _stack => (is => 'rw', private => 1);

has _bound => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    my $spelled = $E->rules($self->_given);
    $self->_spelled($spelled);
    $self->_stack([]);
    $self->_bound(0);

    my $position = $self->_position;
    my $engine;
    if (defined $position) {
        $engine = $E->new(position => $position);
        Carp::croak('Game::Senet::Rules: the position has ' . $engine->pieces
                  . ' pieces a side and the rule set ' . $spelled->{pieces})
            unless $engine->pieces == $spelled->{pieces};
    }
    else {
        my $first = $self->_first;
        Carp::croak("Game::Senet::Rules: first is 'light' or 'dark'")
            unless defined $first && exists $SIDE_OF{$first};
        $engine = $E->new(pieces => $spelled->{pieces});
        $engine->put($_, $_ % 2 ? DARK : LIGHT) for 1 .. 2 * $spelled->{pieces};
        $engine->set_side($SIDE_OF{$first});
    }
    $self->_engine($engine);
    return;
}

sub rules { return { %{ $_[0]->_spelled } } }

sub side { $SIDE_NAME[ $_[0]->_engine->side ] }

sub only { $_[0]->_bound }

sub ply { $_[0]->_engine->ply }

sub position { $_[0]->_engine->to_string }

sub key { $_[0]->_engine->key_hex }

sub board { $_[0]->_engine->clone }

sub home {
    my ($self, $side) = @_;
    Carp::croak("Game::Senet::Rules: a side is 'light' or 'dark'") unless exists $SIDE_OF{ $side // '' };
    return $self->_engine->home($SIDE_OF{$side});
}

sub protected { $_[0]->_engine->protected($_[1], $_[0]->_given) }

sub in_blockade { $_[0]->_engine->in_blockade($_[1], $_[0]->_given) }

sub status {
    my ($self) = @_;
    my $status = $self->_engine->status;
    return $status == WON ? 'won' : $status == DRAWN ? 'drawn' : 'ongoing';
}

sub how {
    my ($self) = @_;
    my $how = $self->_engine->how;
    return $how == BY_HOME ? 'home' : $how == BY_PLY_CAP ? 'ply_cap' : undef;
}

sub winner {
    my ($self) = @_;
    my $winner = $self->_engine->winner;
    return $winner < 0 ? undef : $SIDE_NAME[$winner];
}

sub is_over { $_[0]->status ne 'ongoing' }

sub moves {
    my ($self, $roll) = @_;
    return wantarray ? () : 0 if $self->is_over;
    return $self->_engine->moves($roll, $self->_given, $self->_bound);
}

sub apply {
    my ($self, $move) = @_;
    Carp::croak('Game::Senet::Rules: apply takes a move')
        unless Scalar::Util::blessed($move) && $move->isa('Game::Senet::Move');
    return undef if $self->is_over;
    return undef if $move->side ne $self->side;
    return undef if $self->_bound && $move->from != $self->_bound;
    my ($undo, $bound) = $self->_engine->apply($move, $self->_given);
    return undef unless defined $undo;
    push @{ $self->_stack }, [ $undo, $self->_bound ];
    $self->_bound($bound);
    return $move;
}

sub forfeit {
    my ($self, $roll) = @_;
    return 0 if $self->is_over;
    my $undo = $self->_engine->forfeit($roll);
    push @{ $self->_stack }, [ $undo, $self->_bound ];
    $self->_bound(0);
    return 1;
}

sub undo {
    my ($self) = @_;
    my $top = pop @{ $self->_stack };
    return 0 unless defined $top;
    $self->_engine->unapply($top->[0]);
    $self->_bound($top->[1]);
    return 1;
}

sub depth { scalar @{ $_[0]->_stack } }

1;

__END__

=head1 NAME

Game::Senet::Rules - a game of Senet as a position and how it changes, given rolls

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Senet::Rules;

    my $game = Game::Senet::Rules->new(rules => 'kendall');
    my @moves = $game->moves(3);
    @moves ? $game->apply($moves[0]) : $game->forfeit(3);
    print $game->side, " to move\n";
    $game->undo;

=head1 DESCRIPTION

A position and the rules it is played under, and what a move or a forfeit does
to it. The rolls come from outside: this class holds no seed and throws no
sticks, and it does not ask whether a move it is handed is one C<moves> listed.
L<Game::Senet> is the game a player plays; this is what it plays it on.

Whose turn it is afterwards is the engine's to say and is read, never worked
out here: a roll of 1, 4 or 5 keeps the side to move whatever was done with it,
and a 2 or 3 passes it.

=head1 CONSTRUCTOR

=head2 new

    my $game = Game::Senet::Rules->new(rules => 'skyruk');
    my $game = Game::Senet::Rules->new(rules => 'kendall', first => 'dark');
    my $game = Game::Senet::Rules->new(rules => 'kendall', position => $string);

C<rules> is a rule set as L<Game::Senet::Engine/rules> takes one, C<kendall>
when not given. Without a C<position> the game starts with the pieces
interleaved on the first houses, dark on the odd and light on the even, and
C<first>, C<light> or C<dark>, to move: light unless told. A C<position>, a
position string, B<croaks> when its number of pieces a side is not the rule
set's.

=head1 METHODS

=head2 rules

The rule set as a hash, a copy.

=head2 side

C<light> or C<dark>: whose throw it is.

=head2 only

The house whose piece alone the next throw may move, or 0. Under C<skyruk> a
piece that arrives on house 26 is thrown for again, and that throw is its own.

=head2 ply

Moves and forfeits made, the starting position's included.

=head2 position

The position string.

=head2 key

The position's key, sixteen hex characters.

=head2 board

A copy of the board, a L<Game::Senet::Engine>.

=head2 home

    my $n = $game->home('light');

How many of a side's pieces have borne off.

=head2 protected

=head2 in_blockade

    print "protected\n" if $game->protected(12);

Whether the piece on a house cannot be swapped, and whether it is part of a
blockade, under this game's rules. See L<Game::Senet::Engine/protected>.

=head2 status

C<ongoing>, C<won> or C<drawn>.

=head2 how

C<home> when a side has borne off every piece, C<ply_cap> for the draw at the
ply cap, C<undef> while the game goes on.

=head2 winner

C<light>, C<dark>, or C<undef>.

=head2 is_over

True when the game has ended.

=head2 moves

    my @moves = $game->moves($roll);

What a roll allows the side to move, as L<Game::Senet::Move>s, honouring
C<only>. None once the game is over.

=head2 apply

    $game->apply($move) or die "not applied";

Makes a move and returns it, or returns C<undef> without changing anything
when the game is over, the move is the other side's, or C<only> names another
house.

=head2 forfeit

    $game->forfeit($roll);

A throw that allows nothing. The roll is needed, because a forfeit on a 1, 4 or
5 keeps the turn. Returns 0 once the game is over.

=head2 undo

Takes back the last move or forfeit, C<only> with it. 0 when there is nothing
to take back.

=head2 depth

How many moves and forfeits there are to take back.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
