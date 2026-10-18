package Game::Senet::Engine;

use 5.010;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;
use Scalar::Util ();

use Game::Senet::Move;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Game::Senet', $VERSION);

use constant {
    EMPTY => 0,
    LIGHT => 1,
    DARK  => 2,

    SIDE_LIGHT => 0,
    SIDE_DARK  => 1,

    HOUSES     => 30,
    ROWS       => 3,
    COLS       => 10,
    PIECES_MAX => 7,
    ROLL_MAX   => 5,
    MOVES_MAX  => 7,
    WIN        => 1_000_000,
    DEPTH_MAX  => 32,
    CHAIN_MAX  => 4,
    REBIRTH    => 15,
};

use constant {
    PROTECT_NONE => 0,
    PROTECT_RUN  => 1,
    PROTECT_ENDS => 2,

    REACH_EXACT => 0,
    REACH_ANY   => 1,

    X_END  => 0,
    X_OFF  => 31,
    X_WALK => 32,
    X_STAY => 33,

    RULES_KENDALL => 0,
    RULES_SKYRUK  => 1,
};

use constant {
    ONGOING => 0,
    WON     => 1,
    DRAWN   => 2,

    BY_HOME    => 1,
    BY_PLY_CAP => 2,
};

use constant {
    POS_OK     => 0,
    POS_NULL   => 1,
    POS_GROUPS => 2,
    POS_WIDTH  => 3,
    POS_LETTER => 4,
    POS_SIDE   => 5,
    POS_PIECES => 6,
    POS_EXCESS => 7,
    POS_FIELD  => 8,
    POS_LONG   => 9,
};

our @EXPORT_OK = qw(
    EMPTY LIGHT DARK
    SIDE_LIGHT SIDE_DARK
    HOUSES ROWS COLS PIECES_MAX ROLL_MAX MOVES_MAX CHAIN_MAX REBIRTH WIN DEPTH_MAX
    PROTECT_NONE PROTECT_RUN PROTECT_ENDS
    REACH_EXACT REACH_ANY
    X_END X_OFF X_WALK X_STAY
    RULES_KENDALL RULES_SKYRUK
    POS_OK POS_NULL POS_GROUPS POS_WIDTH POS_LETTER POS_SIDE
    POS_PIECES POS_EXCESS POS_FIELD POS_LONG
    ONGOING WON DRAWN BY_HOME BY_PLY_CAP
    other piece_of
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub other { $_[0] == SIDE_LIGHT ? SIDE_DARK : SIDE_LIGHT }

sub piece_of { $_[0] == SIDE_LIGHT ? LIGHT : DARK }

has _ptr => (is => 'rw', private => 1);

has _hold => (is => 'rw', private => 1);

has _given_pieces => (is => 'ro', init_arg => 'pieces', private => 1, default => 5);

has _position => (is => 'ro', init_arg => 'position', private => 1);

my %ADOPTING;

sub BUILD {
    my ($self) = @_;
    my $given = $self->_ptr;
    if ($given) {
        if (delete $ADOPTING{$given}) {
            $self->_hold(_hold_board($given));
            return;
        }
        $self->_ptr(0);
        Carp::croak("Game::Senet::Engine: a board is made by new, of_string or clone");
    }

    my $position = $self->_position;
    if (defined $position) {
        my ($ptr, $err) = _of_string($position);
        Carp::croak("Game::Senet::Engine: the position was refused, code $err")
            unless defined $ptr;
        $self->_ptr($ptr);
        $self->_hold(_hold_board($ptr));
        return;
    }

    my $pieces = $self->_given_pieces;
    Carp::croak("Game::Senet::Engine: pieces is a whole number from 1 to 7")
        unless defined $pieces && $pieces =~ /\A[1-7]\z/;
    $self->_ptr(_new_board($pieces));
    $self->_hold(_hold_board($self->_ptr));
    return;
}

my $adopt = sub {
    my ($class, $ptr) = @_;
    $ADOPTING{$ptr} = 1;
    return $class->new(_ptr => $ptr);
};

sub of_string {
    my ($class, $position) = @_;
    my ($ptr, $err) = _of_string(defined $position ? $position : '');
    return (undef, $err) unless defined $ptr;
    return ($adopt->($class, $ptr), POS_OK);
}

sub clone {
    my ($self) = @_;
    return $adopt->(ref($self), _copy_board($self->_ptr));
}

sub at         { _at($_[0]->_ptr, $_[1]) }
sub put        { _put($_[0]->_ptr, $_[1], $_[2]); return $_[0] }
sub lift       { _lift($_[0]->_ptr, $_[1]); return $_[0] }
sub side       { _side($_[0]->_ptr) }
sub set_side   { _set_side($_[0]->_ptr, $_[1]); return $_[0] }
sub pieces     { _pieces($_[0]->_ptr) }
sub count      { _count($_[0]->_ptr, $_[1]) }
sub home       { _home($_[0]->_ptr, $_[1]) }
sub consistent { _consistent($_[0]->_ptr) }
sub ply        { _ply($_[0]->_ptr) }
sub set_ply    { _set_ply($_[0]->_ptr, $_[1]); return $_[0] }
sub to_string  { _to_string($_[0]->_ptr) }
sub key_hex    { _key_hex($_[0]->_ptr) }

sub house_of  { my $c = shift; _house_of($_[0], $_[1]) }
sub row_of    { my $c = shift; _row_of($_[0]) }
sub col_of    { my $c = shift; _col_of($_[0]) }
sub is_marked { my $c = shift; _is_marked($_[0]) }

sub all_houses    { 1 .. HOUSES }
sub marked_houses { grep { _is_marked($_) } 1 .. HOUSES }

my (@PROTECT_NAME, @REACH_NAME, %EXIT_WORD);
BEGIN {
    @PROTECT_NAME = ('none', 'run', 'ends');
    @REACH_NAME   = ('exact', 'any');
    %EXIT_WORD    = (31 => 'off', 32 => 'walk', 33 => 'stay');
}

my $as_hash = sub {
    my ($pieces, $blockade, $protect, $backward, $reach26, $throw_on_26, $safe, @chain) = @_;
    my %exits;
    for my $h (0 .. 4) {
        for my $roll (1 .. ROLL_MAX) {
            my @entries = splice @chain, 0, CHAIN_MAX;
            $exits{ 26 + $h }{$roll} = [
                map { $EXIT_WORD{$_} // $_ } grep { $_ != X_END } @entries
            ];
        }
    }
    return {
        pieces      => $pieces,
        blockade    => $blockade,
        protect     => $PROTECT_NAME[$protect],
        backward    => $backward,
        reach26     => $REACH_NAME[$reach26],
        throw_on_26 => $throw_on_26,
        safe        => [ grep { $safe & (1 << $_) } 1 .. HOUSES ],
        exits       => \%exits,
    };
};

sub rules {
    my ($class, $rules) = @_;
    return $as_hash->(_rules($rules));
}

sub rules_named {
    my ($class, $name) = @_;
    my @flat = _rules_named($name);
    return undef unless @flat;
    return $as_hash->(@flat);
}

sub rules_id { my $c = shift; _rules_id($_[0]) }

sub chances {
    return map { [ _chance($_) ] } 0 .. _chance_count() - 1;
}

sub extra { my $c = shift; _extra($_[0]) }

my @SIDE_NAME;
BEGIN { @SIDE_NAME = ('light', 'dark') }

sub moves {
    my ($self, $roll, $rules, $only) = @_;
    Carp::croak('Game::Senet::Engine: a roll is a whole number of houses from 1 to 5')
        unless defined $roll && $roll =~ /\A[1-5]\z/;
    $only //= 0;
    Carp::croak('Game::Senet::Engine: only is a house, 1 to 30, or 0 for any')
        unless $only =~ /\A\d{1,2}\z/ && $only <= HOUSES;
    my $side = $SIDE_NAME[ _side($self->_ptr) ];
    my @moves = map {
        my ($from, $to, $r, $swap, $back, $off, $walk) = @$_;
        Game::Senet::Move->new(
            side => $side,
            roll => $r,
            from => $from,
            to   => ($off ? 'off' : $to),
            swap => $swap,
            back => $back,
            off  => $off,
            walk => $walk,
        );
    } _moves($self->_ptr, $roll, $rules, $only);
    return wantarray ? @moves : scalar @moves;
}

sub apply {
    my ($self, $move, $rules) = @_;
    Carp::croak('Game::Senet::Engine: apply takes a move')
        unless Scalar::Util::blessed($move) && $move->isa('Game::Senet::Move');
    my ($undo, $bound) = _apply($self->_ptr, $rules, $move->from,
        ($move->off ? -1 : $move->to), $move->roll, $move->off);
    return wantarray ? ($undo, $bound) : $undo;
}

sub forfeit {
    my ($self, $roll) = @_;
    Carp::croak('Game::Senet::Engine: a roll is a whole number of houses from 1 to 5')
        unless defined $roll && $roll =~ /\A[1-5]\z/;
    return _forfeit($self->_ptr, $roll);
}

sub unapply { _unapply($_[0]->_ptr, $_[1]); return $_[0] }

sub status  { _status($_[0]->_ptr) }
sub how     { _how($_[0]->_ptr) }
sub winner  { _winner($_[0]->_ptr) }
sub ply_cap { _ply_cap() }

sub walk { _walk($_[0]->_ptr, $_[1], $_[2]) }

my $check_roll = sub {
    Carp::croak('Game::Senet::Engine: a roll is a whole number of houses from 1 to 5')
        unless defined $_[0] && $_[0] =~ /\A[1-5]\z/;
};

my $check_options = sub {
    my ($what, $option, @allowed) = @_;
    my %ok = map { $_ => 1 } @allowed;
    for my $key (sort keys %$option) {
        Carp::croak("Game::Senet::Engine: $what has no option called '$key'") unless $ok{$key};
    }
};

sub evaluate {
    my ($self, $side, $rules, $weights) = @_;
    Carp::croak('Game::Senet::Engine: evaluate asks for a side')
        unless defined $side && $side =~ /\A[01]\z/;
    return _evaluate($self->_ptr, $rules, $weights, $side);
}

sub greedy {
    my ($self, $roll, $rules, $only) = @_;
    $check_roll->($roll);
    return _greedy($self->_ptr, $roll, $rules, $only // 0);
}

sub search {
    my ($self, $roll, %option) = @_;
    $check_roll->($roll);
    $check_options->('search', \%option, qw(rules weights budget depth only));
    my $budget = defined $option{budget} ? $option{budget} : 2_000_000_000;
    my $depth  = defined $option{depth}  ? $option{depth}  : 0;
    Carp::croak('Game::Senet::Engine: a budget is a whole number of nodes from 0 to 2000000000')
        unless $budget =~ /\A\d{1,10}\z/ && $budget <= 2_000_000_000;
    Carp::croak('Game::Senet::Engine: a depth is a whole number from 0 to 32')
        unless $depth =~ /\A\d{1,2}\z/ && $depth <= DEPTH_MAX;
    my ($index, $nodes, $reached, $value, $stopped) =
        _search($self->_ptr, $roll, $option{rules}, $option{weights}, $budget, $depth, $option{only} // 0);
    return { index => $index, nodes => $nodes, depth => $reached, value => $value, stopped => $stopped };
}

sub expect {
    my ($self, $depth, %option) = @_;
    $check_options->('expect', \%option, qw(rules weights only side));
    Carp::croak('Game::Senet::Engine: a depth is a whole number from 0 to 32')
        unless defined $depth && $depth =~ /\A\d{1,2}\z/ && $depth <= DEPTH_MAX;
    my $side = defined $option{side} ? $option{side} : _side($self->_ptr);
    return _expect($self->_ptr, $option{rules}, $option{weights}, $option{only} // 0, $depth, $side);
}

sub abi_version { _abi_version() }
sub live        { _live() }

1;

__END__

=head1 NAME

Game::Senet::Engine - the board of Senet: thirty houses, two sides, the named rule sets

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Senet::Engine ':all';

    my $board = Game::Senet::Engine->new;
    $board->put($_, $_ % 2 ? DARK : LIGHT) for 1 .. 10;
    print $board->to_string, "\n";      # dldldldldl/........../.......... l 5
    print $board->key_hex, "\n";        # 0000000000066666

    my $h = Game::Senet::Engine->house_of(1, 0);    # 20
    print "marked\n" if Game::Senet::Engine->is_marked(15);

    my $kendall = Game::Senet::Engine->rules('kendall');
    print "@{ $kendall->{exits}{28}{3} }\n";        # off

    my ($other, $err) = Game::Senet::Engine->of_string('.........l/........../.......... d 5');

=head1 DESCRIPTION

A position: thirty houses, what stands on each, how many pieces a side has,
and whose move it is. And the two named rule sets as data.

C<put> and C<lift> B<judge nothing>: C<put> will place nine light pieces in a
row if asked. Nothing in this class knows how a piece moves.

A position holds no throw and no roll. The sticks are not part of the board.

Most callers want L<Game::Senet>. This class is for building positions and
asking what is on them.

=head2 The houses

A house is its number, 1 to 30. The track runs from house 1 to house 30 and is
the same for both sides. The board is drawn as three rows of ten, the track a
reversed S:

     1  2  3  4  5  6  7  8  9 10
    20 19 18 17 16 15 14 13 12 11
    21 22 23 24 25 26 27 28 29 30

The grid is for drawing. Houses 10 and 11 are next to each other on the track;
houses 1 and 20 are not, though one stands above the other.

Six houses are marked: 15, and 26 to 30.

=head2 The home

A side's home is the number of its pieces that have borne off. It is never
stored: it is C<pieces> less the side's pieces on the board. A board built with
more pieces of a side than C<pieces> has a negative home and is not
C<consistent>.

=head1 CONSTRUCTORS

=head2 new

    my $board = Game::Senet::Engine->new;
    my $board = Game::Senet::Engine->new(pieces => 7);
    my $board = Game::Senet::Engine->new(position => $string);

An empty board, light to move, ply 0, with C<pieces> a side: a whole number
from 1 to 7, 5 when not given. Or the position a string describes, which
croaks if the string is refused. A board is dropped when its last reference
goes.

=head2 of_string

    my ($board, $err) = Game::Senet::Engine->of_string($string);

The board a position string describes, and C<POS_OK>; or C<undef> and the code
saying why the string was refused. It never croaks.

=head2 clone

    my $copy = $board->clone;

A board of its own with the same houses, side, C<pieces> and ply.

=head1 THE POSITION STRING

    dldldldldl/........../.......... l 5

The thirty houses in track order, three groups of ten with a slash between,
C<l> for a light piece, C<d> for a dark one and C<.> for an empty house; then
the side to move, C<l> or C<d>; then C<pieces>, one digit from 1 to 7. Every
field is required. Character I<k> of the thirty is house I<k>, so the middle
group runs from house 11 to house 20, left to right, which the board draws
right to left.

A string is refused, with one of these codes, for: C<POS_NULL> no string or an
empty one, C<POS_GROUPS> not three groups, C<POS_WIDTH> a group not ten long,
C<POS_LETTER> a character that is not C<l>, C<d> or C<.>, C<POS_SIDE> a side
that is not C<l> or C<d>, C<POS_PIECES> a C<pieces> that is not one digit from
1 to 7, C<POS_EXCESS> a side with more pieces on the board than C<pieces>,
C<POS_FIELD> a field missing or something after the last, C<POS_LONG> 48
characters or more.

=head1 METHODS

=head2 at

    my $piece = $board->at($house);

C<EMPTY>, C<LIGHT> or C<DARK>; -1 for a number that is not a house.

=head2 put

    $board->put($house, LIGHT);

Places a piece, or C<EMPTY>, on a house, judging nothing. A value that is not
one of the three, or a house that is not one, is ignored. Returns the board.

=head2 lift

    $board->lift($house);

Empties a house. Returns the board.

=head2 side

C<SIDE_LIGHT> or C<SIDE_DARK>: whose move it is.

=head2 set_side

    $board->set_side(SIDE_DARK);

Returns the board. Anything but the two sides is ignored.

=head2 pieces

How many pieces a side has, on the board and home together.

=head2 count

    my $n = $board->count(SIDE_LIGHT);

A side's pieces on the board; -1 for a side that is not one.

=head2 home

    my $n = $board->home(SIDE_DARK);

C<pieces> less C<count>: a side's pieces that have borne off.

=head2 consistent

True when neither side has more pieces on the board than C<pieces>.

=head2 ply

Moves and forfeits made to reach the position. It is not part of the key or of
the position string, and a board read from a string is at ply 0.

=head2 set_ply

    $board->set_ply(12);

A negative number is ignored. Returns the board.

=head2 moves

    my @moves = $board->moves($roll, $rules);
    my @moves = $board->moves($roll, $rules, $only);
    my $count = $board->moves($roll, $rules);

The moves a roll of 1 to 5 allows the side to move under a rule set (a name, a
hash, or C<undef> for C<kendall>; see L</rules>), as L<Game::Senet::Move>s in
ascending order of the house moved from. In scalar context, how many.

A backward move is listed only when the rule set allows one and B<no> forward
move exists, so a list is all forward or all backward. C<$only>, a house, lets
the piece on that house alone move. A piece standing on house 26 or beyond is
not moved by this method.

B<Croaks> on a roll that is not 1 to 5: a throw of nothing is a roll of 5, and
0 is never a roll.

=head2 apply

    my ($undo, $bound) = $board->apply($move, $rules);

Makes a move of the side to move: the piece leaves C<from>, an enemy standing
on C<to> goes to C<from>, and the piece lands, or bears off. The ply goes up by
one, and the side to move follows the roll: the same side after a 1, 4 or 5,
the other after a 2 or 3, and no change after the move that wins.

C<$bound> is the house the next throw is bound to, or 0: under a rule set with
C<throw_on_26>, a piece arriving on 26 is thrown for again, alone, and C<$bound>
is then 26 with the same side to move. C<$undo> is what L</unapply> takes.

It does not ask whether the move is legal, only that a piece of the side to
move stands on C<from>; when none does, it returns nothing and changes nothing.

=head2 forfeit

    my $undo = $board->forfeit($roll);

A throw that allows nothing. The ply goes up by one, and the side to move
follows the roll as it does after a move: a forfeit on a 1, 4 or 5 keeps the
turn. B<Croaks> on a roll that is not 1 to 5.

=head2 unapply

    $board->unapply($undo);

Takes back what L</apply> or L</forfeit> did, exactly: the houses, the side and
the ply. Returns the board.

=head2 status

C<ONGOING>, C<WON> when a side has no piece left on the board, C<DRAWN> at the
ply cap.

=head2 how

0 while the game goes on, C<BY_HOME> or C<BY_PLY_CAP>.

=head2 winner

C<SIDE_LIGHT> or C<SIDE_DARK>, or -1.

=head2 ply_cap

The ply at which a game is drawn: swaps and the water send pieces back, so
nothing else bounds a game.

=head2 walk

    my $leaves = $board->walk($depth, $rules);

Every roll and every move each allows, to C<$depth> plies, counting the
positions at the end, as a string of digits. A roll that allows nothing is one
branch; a finished game is an end. For comparing one generator with another.

=head2 evaluate

    my $v = $board->evaluate(SIDE_LIGHT, $rules, \%weights);

The position valued for a side, in sixteenths of a house: the houses its pieces
stand on, a piece at home counting 31, less the other side's, and the terms
whose weight is given: C<blockade>, own runs wide enough to block with an enemy
piece behind them. C<ties> chooses the earlier of two moves of equal value.

=head2 greedy

    my $index = $board->greedy($roll, $rules, $only);

The move to make without looking ahead, as an index into what L</moves>
returns: a bear-off, else a swap, else a landing on 26, else the move whose
piece ends furthest on. -1 when the roll allows nothing.

=head2 search

    my $found = $board->search($roll, rules => $rules, weights => \%w,
                               budget => $nodes, depth => $throws, only => $house);

The best move for the side to move, by expectiminimax through the sticks, as
C<< { index, nodes, depth, value, stopped } >>. The budget is in nodes and the
depth in throws; the first level always finishes. The same arguments give the
same answer every time.

=head2 expect

    my $v = $board->expect($depth, rules => $rules, side => SIDE_LIGHT);

The value of the position BEFORE its throw, for a side, a number of throws
deep. For checking the search by hand.

=head2 to_string

The position string.

=head2 key_hex

The position as sixteen lowercase hex characters: house I<h> at bits
2(I<h> - 1) and 2(I<h> - 1) + 1, and the side to move at bit 60. Equal
positions have equal keys and different positions different ones. Neither
C<pieces> nor the ply is in it.

=head1 CLASS METHODS

=head2 house_of

    my $house = Game::Senet::Engine->house_of($row, $col);

The house drawn at a row, 0 to 2 from the top, and a column, 0 to 9 from the
left; -1 for a place that is not on the board.

=head2 row_of

    my $row = Game::Senet::Engine->row_of($house);

The row a house is drawn in, or -1.

=head2 col_of

    my $col = Game::Senet::Engine->col_of($house);

The column a house is drawn in, or -1.

=head2 is_marked

    my $yes = Game::Senet::Engine->is_marked($house);

True for the six marked houses: 15 and 26 to 30.

=head2 all_houses

The thirty house numbers, 1 to 30.

=head2 marked_houses

The six marked house numbers, in order.

=head2 rules

    my $rules = Game::Senet::Engine->rules('skyruk');
    my $rules = Game::Senet::Engine->rules({ exits => 'kendall', protect => 'none' });

A rule set as a hash: C<pieces>, C<blockade>, C<protect> (C<none>, C<run> or
C<ends>), C<backward>, C<reach26> (C<exact> or C<any>), C<throw_on_26>, C<safe>
(the safe houses, as a list), and C<exits>, which maps each of houses 26 to 30
and each roll from 1 to 5 to its chain: a list of house numbers and the words
C<off>, C<walk> and C<stay>, an empty list where nothing is possible.

The argument is the name of a set, C<undef> for C<kendall>, or a hash of what
differs from a set: C<exits> names the set to start from, and each other key
sets one field. An unknown name, an unknown key, or a value a field may not
hold croaks.

=head2 rules_named

    my $rules = Game::Senet::Engine->rules_named(RULES_SKYRUK);

The same hash for a set by number, or C<undef> when there is no such set.

=head2 rules_id

    my $n = Game::Senet::Engine->rules_id('kendall');    # RULES_KENDALL

The number of the set a name stands for, or -1.

=head2 chances

    my @rows = Game::Senet::Engine->chances;    # [1, 4, 16], [2, 6, 16] ...

Each roll four sticks can make, in ascending order of ROLL, as C<[roll,
weight, denominator]>: how many of the sixteen equally likely ways the sticks
can fall make it. These are the odds a search weighs. Nothing here throws the
sticks; see L<Game::Senet::Sticks>.

=head2 extra

    my $again = Game::Senet::Engine->extra($roll);

1 when a roll gives another throw, 0 when it does not, -1 for a number that is
not a roll. L<Game::Senet::Sticks/extra_throw> answers the same question in
Perl.

=head2 abi_version

The version of the C table this build carries. A consumer of the table asks
for C<< >= >> the version it was written against, never C<==>.

=head2 live

Boards made and not yet dropped. It exists for a leak test.

=head1 FUNCTIONS

Exported on request, with the constants, or all of them with C<:all>.

=head2 other

    my $them = other(SIDE_LIGHT);    # SIDE_DARK

=head2 piece_of

    my $piece = piece_of(SIDE_DARK);    # DARK

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
