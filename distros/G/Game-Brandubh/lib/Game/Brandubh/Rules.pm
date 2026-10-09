package Game::Brandubh::Rules;

use 5.010;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;

use Game::Brandubh::Engine ();

our $VERSION = '0.01';

use constant {
    ONGOING         => 0,
    BY_CORNER       => 1,
    BY_CAPTURE      => 2,
    BY_NO_PIECES    => 3,
    DRAW_REPETITION => 4,
    DRAW_NO_MOVE    => 5,
    DRAW_PLY_CAP    => 6,
};

use constant {
    PLAY_OK      => 0,
    PLAY_OVER    => 1,
    PLAY_ILLEGAL => 2,
};

our @EXPORT_OK = qw(
    ONGOING BY_CORNER BY_CAPTURE BY_NO_PIECES
    DRAW_REPETITION DRAW_NO_MOVE DRAW_PLY_CAP
    PLAY_OK PLAY_OVER PLAY_ILLEGAL
    outcome_name
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my @NAME;
BEGIN { @NAME = qw(ongoing corner capture no_pieces repetition no_move ply_cap) }

sub outcome_name {
    my ($outcome) = @_;
    return undef unless defined $outcome && $outcome =~ /\A[0-9]+\z/ && $outcome < @NAME;
    return $NAME[$outcome];
}

has _ptr => (is => 'rw', private => 1);

has _start => (is => 'ro', init_arg => 'position', private => 1);

has _rules => (is => 'ro', init_arg => 'variant', private => 1);

my %ADOPTING;

sub BUILD {
    my ($self) = @_;
    my $given = $self->_ptr;
    if ($given) {
        return if delete $ADOPTING{$given};
        $self->_ptr(0);
        Carp::croak("Game::Brandubh::Rules: a game is made by new or clone");
    }

    my ($ptr, $err) = _new_game($self->_start, $self->_rules);
    Carp::croak("Game::Brandubh::Rules: the position was refused, code $err")
        unless defined $ptr;
    $self->_ptr($ptr);
    return;
}

my $adopt = sub {
    my ($class, $ptr) = @_;
    $ADOPTING{$ptr} = 1;
    return $class->new(_ptr => $ptr);
};

sub clone {
    my ($self) = @_;
    return $adopt->(ref($self), _copy_game($self->_ptr));
}

sub DEMOLISH {
    my ($self) = @_;
    my $ptr = $self->_ptr;
    return unless $ptr;
    _drop_game($ptr);
    $self->_ptr(0);
    return;
}

sub position { _position($_[0]->_ptr) }
sub key_hex  { _key_hex($_[0]->_ptr) }
sub key_at   { _key_at_hex($_[0]->_ptr, $_[1]) }
sub side     { _side($_[0]->_ptr) }
sub at       { _at($_[0]->_ptr, $_[1]) }
sub count    { _count($_[0]->_ptr, $_[1]) }
sub ply      { _ply($_[0]->_ptr) }
sub ply_cap  { _cap($_[0]->_ptr) }
sub variant  { _variant($_[0]->_ptr) }

sub board {
    my ($self) = @_;
    return Game::Brandubh::Engine->new(position => _position($self->_ptr));
}

sub outcome { _outcome($_[0]->_ptr) }
sub is_over { _outcome($_[0]->_ptr) != ONGOING }
sub is_draw { _outcome($_[0]->_ptr) >= DRAW_REPETITION }
sub repeats { _repeats($_[0]->_ptr) }

sub winner {
    my $side = _winner($_[0]->_ptr);
    return $side < 0 ? undef : $side;
}

sub winner_of {
    my $side = _winner_of($_[1]);
    return $side < 0 ? undef : $side;
}

sub moves {
    my @m = _moves($_[0]->_ptr);
    return wantarray ? @m : scalar @m;
}

sub play {
    my ($answer, $flags) = _play($_[0]->_ptr, $_[1]);
    return wantarray ? ($answer, $flags) : $answer;
}

sub undo    { _undo($_[0]->_ptr) }
sub preview { _preview($_[0]->_ptr, $_[1]) }
sub why_not { _why_not($_[0]->_ptr, $_[1], $_[2]) }

sub live { _games_live() }

sub search {
    my ($self, %with) = @_;
    my $budget = $with{budget};
    Carp::croak('Game::Brandubh::Rules: search needs a budget, a whole number of nodes from 1 up')
        unless defined $budget && !ref $budget && $budget =~ /\A[0-9]{1,9}\z/ && $budget >= 1;
    my $seed = defined $with{seed} ? $with{seed} : 1;
    Carp::croak('Game::Brandubh::Rules: a search seed is a whole number below 4294967296')
        unless !ref $seed && $seed =~ /\A[0-9]{1,10}\z/ && $seed < 4294967296;
    my $depth = defined $with{depth} ? $with{depth} : 0;
    Carp::croak('Game::Brandubh::Rules: a search depth is a whole number')
        unless !ref $depth && $depth =~ /\A[0-9]{1,3}\z/;

    my ($mv, $nodes, $reached, $score, $stopped) = _search($self->_ptr, $budget, $seed, $depth, $with{weights});
    return undef unless $mv;
    return { move => $mv, nodes => $nodes, depth => $reached, score => $score, stopped => $stopped };
}

sub evaluate { _evaluate($_[0]->_ptr, $_[1]) }

sub weights { _weights() }

1;

__END__

=head1 NAME

Game::Brandubh::Rules - a game of brandubh: the moves made, and how it ends

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Brandubh::Rules ':all';
    use Game::Brandubh::Engine;

    my $game = Game::Brandubh::Rules->new;

    until ($game->is_over) {
        my @moves = $game->moves;
        $game->play($moves[0]);
    }

    print outcome_name($game->outcome), "\n";      # corner, capture, repetition...

    my $from_here = Game::Brandubh::Rules->new(
        position => '7/7/7/3k3/7/7/a6 d',
        variant  => { repeat => 2 },
    );

=head1 DESCRIPTION

A position together with the moves that led to it. This is the class that
knows when a game is over, and the only one here that refuses a move.

L<Game::Brandubh::Engine> holds a position and will play any move asked of it,
past the capture of the king if need be. A C<Game::Brandubh::Rules> stops.

Squares and moves are the numbers L<Game::Brandubh::Engine> hands out.

=head2 How a game ends

Six ways: two wins for the defenders, one for the attackers, three draws.

=over 4

=item C<BY_CORNER>

The king's move ended on a corner. The defenders win.

=item C<BY_CAPTURE>

An attacker's move captured the king. The attackers win.

=item C<BY_NO_PIECES>

The attackers have no piece left. The defenders win.

=item C<DRAW_REPETITION>

The position on the board, with the same side to move, has occurred for the
third time.

=item C<DRAW_NO_MOVE>

The side to move has pieces and none of them can move.

=item C<DRAW_PLY_CAP>

The game reached its limit of moves without ending any other way.

=back

They are asked in that order, because one move can satisfy two. A king who
reaches a corner on the move that also repeats a position has won.

Resignation and a draw by agreement are not among them. They are something
two people do, and the caller records them.

=head2 Where these rules come from, and where they are this distribution's own

The win by a corner, the win by capture, and the draws by repetition and by a
side that cannot move are from the reconstruction of brandubh by Aage Nielsen:
"The game is drawn if a position is repeated, if a player cannot move, or if
the players otherwise agree it."

Three points are this distribution's reading of it.

=over 4

=item The third time

"If a position is repeated" says twice. This distribution draws at the third
occurrence, as draughts and chess do, so that a player has seen the position
come round once before the game is taken away. C<< repeat => 2 >> gives the
sentence as written.

=item No pieces is not "cannot move"

Read literally the sentence draws a game in which the defenders have captured
all eight attackers, because the attackers then cannot move. It is for a side
that is blocked. Attackers with no piece left have lost.

=item The limit

The attackers can close all four corners, and then nothing above ends the
game. It is drawn at C<ply_cap> moves, counting both sides' moves.

=back

=head2 A position that was set up, not played into

A game may start from any position. When that position is already an ending
there is no move to read it from, so: a board with no king on it is a win by
capture, and a board with a king standing where he wins is a win by a corner.
Otherwise it is judged like any other.

=head2 The rule set is fixed when the game is made

C<variant> takes the fields L<Game::Brandubh::Engine/A variant is a hash reference>
describes, and they hold for the whole game. Two of them belong to this class:

=over 4

=item C<repeat>

3 by default. Which occurrence of a position draws the game. A value below 2
would end every game at its first position and is taken as 2.

=item C<ply_cap>

400 by default. A value of 0 or less, or above 4096, is taken as the default.

=back

=head1 CONSTANTS

Exported on request, or all at once with C<:all>.

=over 4

=item C<ONGOING>, C<BY_CORNER>, C<BY_CAPTURE>, C<BY_NO_PIECES>, C<DRAW_REPETITION>, C<DRAW_NO_MOVE>, C<DRAW_PLY_CAP>

What C<outcome> returns. C<ONGOING> is 0, so an outcome is true exactly when
the game is over.

=item C<PLAY_OK>, C<PLAY_OVER>, C<PLAY_ILLEGAL>

What C<play> answers. C<PLAY_OK> is 0.

=back

=head1 FUNCTIONS

=head2 outcome_name

    my $word = outcome_name(BY_CORNER);     # 'corner'

C<ongoing>, C<corner>, C<capture>, C<no_pieces>, C<repetition>, C<no_move> or
C<ply_cap>; C<undef> for anything that is not an outcome. Exported on request.

=head1 METHODS

=head2 new

    my $game = Game::Brandubh::Rules->new;
    my $game = Game::Brandubh::Rules->new(position => $string, variant => \%fields);

A game from the set-up, or from a position string. B<Croaks> on a string that
is not a position and on a variant field that does not exist.

=head2 clone

A copy with the whole history, sharing nothing with the original.

=head2 play

    my $answer = $game->play($mv);
    my ($answer, $flags) = $game->play($mv);

Plays a move for the side to move. C<PLAY_OK> when it was played;
C<PLAY_OVER> when the game had already ended; C<PLAY_ILLEGAL> when the move is
not one of C<moves>. On either refusal B<the game is exactly as it was>.

C<$flags> is what L<Game::Brandubh::Engine/do_move> reports for the move.

=head2 undo

Takes the last move back, and with it whatever ending that move brought.
Returns true, or false when no move has been made.

=head2 moves

    my @moves = $game->moves;
    my $count = $game->moves;

The moves of the side to move: a list in list context, a count in scalar
context. B<Empty once the game is over>, whatever the pieces could do.

=head2 outcome

One of the outcome constants.

=head2 is_over

True when C<outcome> is not C<ONGOING>.

=head2 is_draw

True for the three draws.

=head2 winner

C<Game::Brandubh::Engine::ATTACKERS> or C<DEFENDERS>, or C<undef> when the
game is drawn or not over.

=head2 winner_of

    my $side = Game::Brandubh::Rules->winner_of(BY_CAPTURE);

The side an outcome is a win for, or C<undef>.

=head2 repeats

How many times the position on the board has occurred in this game, the
present time included. 1 for a position seen for the first time.

=head2 ply

How many moves have been made, counting both sides'.

=head2 ply_cap

The limit this game is playing to.

=head2 variant

A hash reference of the rule set this game is playing, every field, as the
game took them.

=head2 position

The position as a string. See L<Game::Brandubh::Engine/to_string>.

=head2 board

A L<Game::Brandubh::Engine> holding the same position. It is a copy: nothing
done to it reaches the game.

=head2 side

Whose move it is.

=head2 at

    my $piece = $game->at($square);

What stands on a square.

=head2 count

    my $n = $game->count(Game::Brandubh::Engine::ATTACKER);

How many of one piece are on the board.

=head2 key_hex

The key of the position on the board. See
L<Game::Brandubh::Engine/The key is a hex string, never a number>.

=head2 key_at

    my $hex = $game->key_at($ply);

The key of the position after that many moves, 0 being where the game began.
C<undef> for a ply the game has not reached.

=head2 preview

    my ($flags, @squares) = $game->preview($mv);

What a move would report and which squares it would empty, under this game's
rule set, without playing it.

=head2 why_not

    my $why = $game->why_not($from, $to);

One of the C<WHY_*> constants of L<Game::Brandubh::Engine>, under this game's
rule set. It answers for the position and does not know the game is over.

=head2 live

How many games exist in this process and have not been released.

=head2 search

    my $found = $game->search(budget => 20_000);
    my $found = $game->search(budget => 20_000, seed => 7, depth => 4, weights => \%weights);

    $game->play($found->{move}) if $found;

The best move for the side to move that a search of that many positions
finds, or C<undef> when the game is over. The game is not changed.

=over 4

=item C<budget>

How many positions the search may look at. It is the only limit: B<the search
never reads a clock>, so the same game, budget and seed give the same move on
a busy machine as on an idle one. The count is checked every 1,024 positions
and may be passed by that many.

=item C<seed>

A whole number below 4,294,967,296 that settles the choice among moves the
search scores alike, and nothing else. 1 when left out.

=item C<depth>

Stop after looking this many moves ahead, even with budget left. No limit
when left out.

=item C<weights>

A hash reference changing some of what C<weights> returns.

=back

What comes back is a hash reference: C<move>, in the engine's numbers;
C<depth>, how many moves ahead the search finished looking; C<score>, for the
side to move, where anything above 29,000 is a win found and anything below
-29,000 a loss; C<nodes>, how many positions it looked at, as a string of
digits; and C<stopped>, true when the budget ran out part way through looking
one move further, in which case that unfinished look is discarded.

B<Croaks> on a budget, seed or depth that is not a whole number, and on a
weight that does not exist.

=head2 evaluate

    my $score = $game->evaluate;
    my $score = $game->evaluate(\%weights);

The position as the search scores it when it looks no further: a whole number,
B<positive when it favours the attackers>.

=head2 weights

    my $weights = Game::Brandubh::Rules->weights;

A hash reference of the seven numbers the evaluation is made of: C<attacker>
and C<defender> for each piece on the board; C<lane_one> for each winning
square the king can reach in one move and C<lane_two> for each he can reach in
two; C<freedom> for each square the king can move to; C<corner_guard> for each
attacker on one of the three squares that close a corner; C<ring> for each
attacker next to the king.


=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
