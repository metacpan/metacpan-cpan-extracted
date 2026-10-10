package Game::RoyalUr::Engine;

use 5.010;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;
use Scalar::Util ();

use Game::RoyalUr::Move;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Game::RoyalUr', $VERSION);

use constant {
    EMPTY => 0,
    LIGHT => 1,
    DARK  => 2,

    SIDE_LIGHT => 0,
    SIDE_DARK  => 1,

    ROUTE_SHORT => 0,
    ROUTE_LONG  => 1,

    FILES      => 8,
    ROWS       => 3,
    CELLS      => 20,
    PIECES_MAX => 7,
    MOVES_MAX  => 7,
    ROLL_MAX   => 4,
    WIN        => 1_000_000,
    DEPTH_MAX  => 32,
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
    POS_ROWS   => 2,
    POS_WIDTH  => 3,
    POS_LETTER => 4,
    POS_GAP    => 5,
    POS_X      => 6,
    POS_SIDE   => 7,
    POS_COUNT  => 8,
    POS_FIELD  => 9,
    POS_LONG   => 10,
};

our @EXPORT_OK = qw(
    EMPTY LIGHT DARK
    SIDE_LIGHT SIDE_DARK
    ROUTE_SHORT ROUTE_LONG
    FILES ROWS CELLS PIECES_MAX MOVES_MAX ROLL_MAX WIN DEPTH_MAX
    POS_OK POS_NULL POS_ROWS POS_WIDTH POS_LETTER POS_GAP POS_X
    POS_SIDE POS_COUNT POS_FIELD POS_LONG
    ONGOING WON DRAWN BY_HOME BY_PLY_CAP
    other piece_of
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub other { $_[0] == SIDE_LIGHT ? SIDE_DARK : SIDE_LIGHT }

sub piece_of { $_[0] == SIDE_LIGHT ? LIGHT : DARK }

has _ptr => (is => 'rw', private => 1);

has _pieces => (is => 'ro', init_arg => 'pieces', private => 1, default => 7);

has _position => (is => 'ro', init_arg => 'position', private => 1);

my %ADOPTING;

sub BUILD {
    my ($self) = @_;
    my $given = $self->_ptr;
    if ($given) {
        return if delete $ADOPTING{$given};
        $self->_ptr(0);
        Carp::croak("Game::RoyalUr::Engine: a board is made by new, of_string or clone");
    }

    my $position = $self->_position;
    if (defined $position) {
        my ($ptr, $err) = _of_string($position);
        Carp::croak("Game::RoyalUr::Engine: the position was refused, code $err")
            unless defined $ptr;
        $self->_ptr($ptr);
        return;
    }

    my $pieces = $self->_pieces;
    Carp::croak("Game::RoyalUr::Engine: pieces is a whole number from 0 to 7")
        unless defined $pieces && $pieces =~ /\A[0-7]\z/;
    $self->_ptr(_new_board($pieces));
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

sub DEMOLISH {
    my ($self) = @_;
    my $ptr = $self->_ptr;
    return unless $ptr;
    _drop_board($ptr);
    $self->_ptr(0);
    return;
}

sub at         { _at($_[0]->_ptr, $_[1]) }
sub put        { _put($_[0]->_ptr, $_[1], $_[2]); return $_[0] }
sub lift       { _lift($_[0]->_ptr, $_[1]); return $_[0] }
sub hand       { _hand($_[0]->_ptr, $_[1]) }
sub set_hand   { _set_hand($_[0]->_ptr, $_[1], $_[2]); return $_[0] }
sub home       { _home($_[0]->_ptr, $_[1]) }
sub set_home   { _set_home($_[0]->_ptr, $_[1], $_[2]); return $_[0] }
sub side       { _side($_[0]->_ptr) }
sub set_side   { _set_side($_[0]->_ptr, $_[1]); return $_[0] }
sub count      { _count($_[0]->_ptr, $_[1]) }
sub consistent { _consistent($_[0]->_ptr, $_[1]) }
sub to_string  { _to_string($_[0]->_ptr) }
sub key_hex    { _key_hex($_[0]->_ptr) }

sub cell_of    { my $c = shift; _cell_of($_[0], $_[1]) }
sub file_of    { my $c = shift; _file_of($_[0]) }
sub row_of     { my $c = shift; _row_of($_[0]) }
sub is_rosette { my $c = shift; _is_rosette($_[0]) }

sub all_cells { 0 .. CELLS - 1 }

sub route_len    { my $c = shift; _route_len($_[0]) }
sub route_cell   { my $c = shift; _route_cell($_[0], $_[1], $_[2]) }
sub route_step   { my $c = shift; _route_step($_[0], $_[1], $_[2]) }
sub route_shared { my $c = shift; _route_shared($_[0], $_[1]) }

sub chances {
    my ($class, $dice, $zero_rolls) = @_;
    return map { [ _chance($dice, $zero_rolls, $_) ] } 0 .. _chance_count($dice, $zero_rolls) - 1;
}

my (@SIDE_NAME, @ROUTE_NAME);
BEGIN {
    @SIDE_NAME  = ('light', 'dark');
    @ROUTE_NAME = ('short', 'long');
}

sub cell_name {
    my ($class, $cell) = @_;
    my $file = _file_of($cell);
    return undef if $file < 0;
    return chr(ord('a') + $file) . (_row_of($cell) + 1);
}

sub rules {
    my ($class, $rules) = @_;
    my ($route, $dice, $zero_rolls, $safe_rosettes, $pieces) = _rules($rules);
    return {
        route         => $ROUTE_NAME[$route],
        dice          => $dice,
        zero_rolls    => $zero_rolls,
        safe_rosettes => $safe_rosettes,
        pieces        => $pieces,
    };
}

sub moves {
    my ($self, $roll, $rules) = @_;
    Carp::croak('Game::RoyalUr::Engine: a roll is a whole number from 0 to 4')
        unless defined $roll && $roll =~ /\A[0-4]\z/;
    my $side = $SIDE_NAME[ _side($self->_ptr) ];
    my @moves = map {
        my ($from_step, $to_step, $from_cell, $to_cell, $captures, $rosette, $home) = @$_;
        Game::RoyalUr::Move->new(
            side      => $side,
            roll      => $roll + 0,
            from      => ($from_step == 0 ? 'hand' : $self->cell_name($from_cell)),
            to        => ($home ? 'home' : $self->cell_name($to_cell)),
            from_step => $from_step,
            to_step   => $to_step,
            from_cell => $from_cell,
            to_cell   => $to_cell,
            captures  => $captures,
            rosette   => $rosette,
            home      => $home,
        );
    } _moves($self->_ptr, $roll, $rules);
    return wantarray ? @moves : scalar @moves;
}

sub count_positions { my $c = shift; _count_positions($_[0]) }

sub ply     { _ply($_[0]->_ptr) }
sub set_ply { _set_ply($_[0]->_ptr, $_[1]); return $_[0] }
sub ply_cap { _ply_cap() }

sub apply {
    my ($self, $move, $rules) = @_;
    Carp::croak('Game::RoyalUr::Engine: apply takes a move')
        unless Scalar::Util::blessed($move) && $move->isa('Game::RoyalUr::Move');
    return _apply($self->_ptr, $rules, $move->from_step, $move->to_step,
                  $move->from_cell, $move->to_cell, $move->home);
}

sub forfeit { _forfeit($_[0]->_ptr) }
sub unapply { _unapply($_[0]->_ptr, $_[1]); return $_[0] }

sub status { _status($_[0]->_ptr, $_[1]) }
sub how    { _how($_[0]->_ptr, $_[1]) }
sub winner { _winner($_[0]->_ptr, $_[1]) }

sub walk { _walk($_[0]->_ptr, $_[1], $_[2]) }

sub evaluate { _evaluate($_[0]->_ptr, $_[2], $_[3], $_[1]) }

sub greedy { _greedy($_[0]->_ptr, $_[1], $_[2]) }

sub search {
    my ($self, $roll, %option) = @_;
    Carp::croak('Game::RoyalUr::Engine: a roll is a whole number from 0 to 4')
        unless defined $roll && $roll =~ /\A[0-4]\z/;
    for my $key (sort keys %option) {
        Carp::croak("Game::RoyalUr::Engine: search has no option called '$key'")
            unless $key =~ /\A(?:rules|weights|budget|depth)\z/;
    }
    my $budget = defined $option{budget} ? $option{budget} : 2_000_000_000;
    my $depth  = defined $option{depth}  ? $option{depth}  : 0;
    Carp::croak('Game::RoyalUr::Engine: a budget is a whole number of nodes from 0 to 2000000000')
        unless $budget =~ /\A\d{1,10}\z/ && $budget <= 2_000_000_000;
    Carp::croak('Game::RoyalUr::Engine: a depth is a whole number from 0 to 32')
        unless $depth =~ /\A\d{1,2}\z/ && $depth <= 32;
    my ($index, $nodes, $reached, $value, $stopped) =
        _search($self->_ptr, $roll, $option{rules}, $option{weights}, $budget, $depth);
    return { index => $index, nodes => $nodes, depth => $reached, value => $value, stopped => $stopped };
}

sub abi_version { _abi_version() }
sub live        { _live() }

1;

__END__

=head1 NAME

Game::RoyalUr::Engine - the board of the Royal Game of Ur: cells, pieces, hands, routes

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::RoyalUr::Engine ':all';

    my $board = Game::RoyalUr::Engine->new;
    print $board->to_string, "\n";      # 4xx2/8/4xx2 l 7 0 7 0

    my $d2 = Game::RoyalUr::Engine->cell_of(3, 1);
    print "a rosette\n" if Game::RoyalUr::Engine->is_rosette($d2);

    my $first = Game::RoyalUr::Engine->route_cell(ROUTE_SHORT, SIDE_LIGHT, 1);
    $board->put($first, LIGHT)->set_hand(SIDE_LIGHT, 6);

    my ($other, $err) = Game::RoyalUr::Engine->of_string('4xx2/3d4/4xx2 l 7 0 6 0');

=head1 DESCRIPTION

A position: twenty squares, what stands on each, how many pieces each side has
still to enter and how many it has brought home, and whose move it is. And the
two routes a piece may be made to follow round the board.

C<put>, C<lift>, C<set_hand> and C<set_home> B<judge nothing>: C<put> will
place eight light pieces on the board if asked, and C<set_hand> will give a
side a hand that does not add up. C<moves> is where the rules of movement
live, and C<apply>, C<forfeit> and C<status> are where a move is made and a
game ends.

A position holds no roll. The dice are not part of the board.

Most callers want L<Game::RoyalUr>. This class is for building positions and
asking what is on them.

=head2 The board

Three rows of eight squares with four missing, so that a block of twelve is
joined to a block of six by a bridge of two:

    3  a3 b3 c3 d3 .  .  g3 h3
    2  a2 b2 c2 d2 e2 f2 g2 h2
    1  a1 b1 c1 d1 .  .  g1 h1

Files run 0 to 7 for a to h and rows 0 to 2 for 1 to 3. Row 1 is light's row
and row 3 is dark's. Five squares are rosettes: C<a1>, C<g1>, C<a3>, C<g3> and
C<d2>.

=head2 A cell is an opaque number

A cell is a number handed out by C<cell_of> and taken apart by C<file_of> and
C<row_of>. Nothing should assume which number is which square, or any
relationship between two of them.

=head2 A route, and a step

A route is the order in which a side's pieces visit cells. A B<step> is a
place on it, counted from 1. Step 0 is the hand, where pieces wait to enter,
and the step after the last is home; neither is a cell.

There are two routes. Light's are below, and dark's are the same with rows 1
and 3 exchanged.

    ROUTE_SHORT   d1 c1 b1 a1  a2 b2 c2 d2 e2 f2 g2 h2  h1 g1
    ROUTE_LONG    d1 c1 b1 a1  a2 b2 c2 d2 e2 f2 g2  g3 h3 h2 h1 g1

On the short route the two sides share the eight squares of the middle row and
nothing else. On the long route they share twelve: each side's last five steps
run round the far end of the board through the other side's row.

B<The same cell can be a different step for each side.> On the long route
C<g3> is light's step 12 and dark's step 16. C<route_step> takes the side for
that reason.

=head2 The key is a hex string, never a number

C<key_hex> is twelve lowercase hexadecimal characters. It is a string on every
perl, because a perl built with 32-bit integers cannot hold the number it
stands for.

The key is the cells, the two homes and the side to move, exactly: two
positions have the same key if and only if they agree on all of those. The
hands are not part of it. In a position where each side's pieces add up, the
hands follow from the rest.

=head2 Every board is its own board

C<clone> returns a board that shares nothing with the one it came from. A
board is released when the last reference to it goes away.

=head1 A RULE SET

Methods that apply a rule take a rule set as their last argument. Leave it
out, or pass C<undef>, for the standard game.

A rule set is the name of one, C<'finkel'> or C<'masters'>, or a hash
reference naming what differs from C<'finkel'>:

    my @moves = $board->moves(3, { route => 'long', safe_rosettes => 0 });

=over 4

=item C<route>

C<'short'> or C<'long'>.

=item C<dice>

3 or 4.

=item C<zero_rolls>

0 or 4: what a throw with no die marked is worth.

=item C<safe_rosettes>

True when a piece standing on a rosette cannot be captured.

=item C<pieces>

How many a side has, 1 to 7.

=back

C<'finkel'> is the short route, four dice, nothing marked worth nothing, safe
rosettes and seven pieces. C<'masters'> is the long route, three dice, nothing
marked worth four, rosettes that are not safe, and seven pieces.

A key that is not one of the five, a name that is not one of the two, and a
value a field may not hold all B<croak>, so that a misspelt rule cannot quietly
play the standard game.

=head2 How a piece moves

A piece moves forward along its side's route by exactly the roll. Entering is
a move from the hand to the step the roll names, and leaving is a move from
the board to home, which needs the exact roll: a piece that would overshoot
does not move.

A piece may not land on a piece of its own side. It may land on an enemy
piece, capturing it, unless the enemy stands on a rosette and rosettes are
safe. Nothing in between matters: a piece passes over any piece of either
side.

=head1 CONSTANTS

Exported on request, or all at once with C<:all>.

=over 4

=item C<EMPTY>, C<LIGHT>, C<DARK>

What C<at> returns for a cell.

=item C<SIDE_LIGHT>, C<SIDE_DARK>

The two sides.

=item C<ROUTE_SHORT>, C<ROUTE_LONG>

The two routes, of fourteen and sixteen steps.

=item C<FILES>, C<ROWS>, C<CELLS>, C<PIECES_MAX>

8, 3, 20 and 7.

=item C<MOVES_MAX>, C<ROLL_MAX>

7, the most moves any roll allows, and 4, the most a roll is worth.

=item C<WIN>, C<DEPTH_MAX>

1,000,000, the value of a game seen to be won, and 32, the deepest a search
goes.

=item C<ONGOING>, C<WON>, C<DRAWN>

What C<status> answers.

=item C<BY_HOME>, C<BY_PLY_CAP>

What C<how> answers for a game that is over: a side brought its last piece
home, or the game ran to the ply cap.

=item C<POS_OK>, C<POS_NULL>, C<POS_ROWS>, C<POS_WIDTH>, C<POS_LETTER>, C<POS_GAP>, C<POS_X>, C<POS_SIDE>, C<POS_COUNT>, C<POS_FIELD>, C<POS_LONG>

Why a position string was refused: it was not; no string; not three rows; a
row that is not eight wide; a character that means nothing; a piece or a run
of empty squares on a square that does not exist; an C<x> on a square that
does; a side to move that is not C<l> or C<d>; a hand or a home that is not a
single digit from 0 to 7; a field missing, or something after the last one; a
string too long to be a position.

=back

=head1 FUNCTIONS

Exported on request.

=head2 other

    my $side = other(SIDE_LIGHT);    # SIDE_DARK

The other side.

=head2 piece_of

    my $piece = piece_of(SIDE_DARK);    # DARK

What C<at> returns for a cell holding that side's piece.

=head1 METHODS

=head2 new

    my $board = Game::RoyalUr::Engine->new;
    my $board = Game::RoyalUr::Engine->new(pieces => 5);
    my $board = Game::RoyalUr::Engine->new(position => '4xx2/8/4xx2 d 7 0 7 0');

An empty board with light to move and seven pieces in each hand; the same with
another number of pieces, from 0 to 7; or the position a string describes.
B<Croaks> on a string it will not take, and on a number of pieces outside that
range. Use C<of_string> to get a string's reason back instead.

=head2 of_string

    my ($board, $err) = Game::RoyalUr::Engine->of_string($string);

A board and C<POS_OK>, or C<undef> and one of the C<POS_*> codes. A string is
refused for its shape and never for its sense: nine pieces of one side, or a
hand that does not add up, both load.

=head2 to_string

    4xx2/8/4xx2 l 7 0 7 0

Three rows from row 3 down to row 1 with a C</> between them, a digit for a
run of empty squares, and an C<x> for each square that does not exist. C<l> is
a light piece and C<d> a dark one. Then, each after a space: the side to move,
C<l> or C<d>; light's hand; light's home; dark's hand; dark's home.

Every field is always written, and C<of_string> requires every one.

=head2 clone

A second board in the same position, sharing nothing with the first.

=head2 at

    my $piece = $board->at($cell);

C<EMPTY>, C<LIGHT> or C<DARK>, or -1 for a number that is not a cell.

=head2 put

    $board->put($cell, LIGHT);

Stands a piece on a cell, replacing whatever was there, and returns the board.
It asks nothing and changes neither hand. A value that is not C<EMPTY>,
C<LIGHT> or C<DARK>, or a number that is not a cell, is ignored.

=head2 lift

    $board->lift($cell);

Empties a cell and returns the board. It changes neither hand.

=head2 hand

    my $waiting = $board->hand(SIDE_LIGHT);

How many of a side's pieces have not yet entered the board.

=head2 set_hand

    $board->set_hand(SIDE_LIGHT, 6);

Sets it, and returns the board. A number outside 0 to 7 is ignored.

=head2 home

    my $finished = $board->home(SIDE_DARK);

How many of a side's pieces have left the board at the end of their route.

=head2 set_home

    $board->set_home(SIDE_DARK, 2);

Sets it, and returns the board. A number outside 0 to 7 is ignored.

=head2 side

The side to move, C<SIDE_LIGHT> or C<SIDE_DARK>.

=head2 set_side

    $board->set_side(SIDE_DARK);

Sets it, and returns the board. Anything else is ignored.

=head2 count

    my $on_board = $board->count(SIDE_LIGHT);

How many of a side's pieces stand on the board.

=head2 consistent

    $board->consistent(7) or die;

True when, for each side, the pieces in hand, on the board and at home add up
to that number.

=head2 key_hex

Twelve hexadecimal characters that stand for the position. See
L</The key is a hex string, never a number>.

=head2 cell_of

    my $cell = Game::RoyalUr::Engine->cell_of($file, $row);

The cell at a file (0 to 7) and a row (0 to 2), or -1 where there is no
square: outside the board, and at C<e1>, C<f1>, C<e3> and C<f3>.

=head2 file_of

The file of a cell, 0 to 7, or -1 for a number that is not a cell.

=head2 row_of

The row of a cell, 0 to 2, or -1 for a number that is not a cell.

=head2 is_rosette

True for the five cells that are rosettes.

=head2 all_cells

The twenty cells, as a list.

=head2 route_len

    my $steps = Game::RoyalUr::Engine->route_len(ROUTE_LONG);    # 16

How many steps a route has, or -1 for a number that is not a route.

=head2 route_cell

    my $cell = Game::RoyalUr::Engine->route_cell($route, $side, $step);

The cell at a step of a side's route, or -1 when the step is not on the
board: step 0 is the hand, and the step after the last is home.

=head2 route_step

    my $step = Game::RoyalUr::Engine->route_step($route, $side, $cell);

The step a cell is for that side, or 0 when that side's route does not visit
it.

=head2 route_shared

    my $both = Game::RoyalUr::Engine->route_shared($route, $cell);

True when the cell is on both sides' routes, which is where a piece can be
captured. Eight cells on the short route and twelve on the long.

=head2 chances

    my @chances = Game::RoyalUr::Engine->chances($dice, $zero_rolls);

The rolls that C<$dice> dice can make, when a throw with nothing marked is
worth C<$zero_rolls> steps, in ascending order. Each is a reference to
C<[$roll, $weight, $denominator]>: the roll comes up C<$weight> times in
C<$denominator> throws. With four dice and nothing marked worth nothing:

    [0, 1, 16], [1, 4, 16], [2, 6, 16], [3, 4, 16], [4, 1, 16]

An empty list when C<$dice> is not 3 or 4, or C<$zero_rolls> is not 0 or 4.

No die is thrown here. For the dice themselves see L<Game::RoyalUr::Dice>.

=head2 cell_name

    my $name = Game::RoyalUr::Engine->cell_name($cell);    # 'd2'

A cell's name, a file letter and a row digit, or C<undef> for a number that is
not a cell.

=head2 rules

    my $rules = Game::RoyalUr::Engine->rules('masters');

The rule set a value stands for, spelled out as a hash reference with all five
fields. See L</A RULE SET>.

=head2 moves

    my @moves = $board->moves($roll);
    my @moves = $board->moves($roll, 'masters');

The moves a roll allows the side to move, as L<Game::RoyalUr::Move> objects: a
piece entering from the hand first, if one can, and then the side's pieces in
the order they stand along its route. In scalar context, how many.

A roll of 0 allows none. B<Croaks> on a roll that is not a whole number from 0
to 4, and on a rule set it does not understand.

The moves are described and not made. The board is as it was.

=head2 count_positions

    my $n = Game::RoyalUr::Engine->count_positions('finkel');    # '275827872'

How many positions a rule set has: every way of standing each side's pieces on
its own route, with the rest in hand or at home, for either side to move. It
is returned as a string of digits, because on some perls the number is too
large to be anything else, and it takes about a second to count for seven
pieces.

=head2 apply

    my $undo = $board->apply($move);
    my $undo = $board->apply($move, 'masters');

Makes a move: one of the L<Game::RoyalUr::Move> objects C<moves> returned. The
piece leaves where it stood, an enemy piece on the square it lands on goes
back to its owner's hand, the count of plies goes up by one, and the turn
passes to the other side, unless the piece landed on a rosette, in which case
the same side is to move again. A piece that goes home passes the turn.

Returns something to hand to C<unapply>, or C<undef> when the move was not
made because the piece it names is not there.

B<It does not ask whether the move is legal.> Hand it a move C<moves> made for
this position and this roll.

=head2 forfeit

    my $undo = $board->forfeit;

A turn lost to the roll. The count of plies goes up by one and the turn passes
to the other side, always. Returns something to hand to C<unapply>.

=head2 unapply

    $board->unapply($undo);

Takes back what C<apply> or C<forfeit> did, exactly: the squares, both hands,
both homes, the side to move and the count of plies. Returns the board.
B<Croaks> on anything that did not come from one of those two.

Take moves back in the reverse of the order they were made.

=head2 ply

How many moves and forfeits have been made to reach this position. It is not
part of the position: a board made from a string starts at 0, and two boards
that differ only in this have the same key.

=head2 set_ply

    $board->set_ply(40);

Sets it, and returns the board. A negative number is ignored.

=head2 ply_cap

The number of plies at which a game is drawn.

=head2 status

    my $status = $board->status($rules);

C<ONGOING>, C<WON> or C<DRAWN>. A side has won when every one of its pieces is
home. A game is drawn when C<ply> reaches C<ply_cap>, which exists so that a
game cannot go on for ever and is not expected to be reached by play.

=head2 how

C<BY_HOME> or C<BY_PLY_CAP> for a game that is over, and 0 for one that is
not.

=head2 winner

C<SIDE_LIGHT> or C<SIDE_DARK>, or -1 when nobody has won.

=head2 walk

    my $n = $board->walk($depth, $rules);

Plays every roll the rule set's dice can make, and every move each allows, to
that many plies, and counts the positions at the end. A roll that allows
nothing is a forfeit and counts as one branch; a finished game is an end.
Each roll counts once, however likely it is. The board is left as it was.

The count is returned as a string of digits. It is for holding one
implementation of the rules against another.

=head2 evaluate

    my $value = $board->evaluate(SIDE_LIGHT);
    my $value = $board->evaluate(SIDE_DARK, 'masters', { exposed => 16 });

What the position is worth to a side, in sixteenths of a step, and it is
worth the opposite to the other side.

Plainly, it is progress: every step each of the side's pieces has taken, a
piece at home counting one more than the route is long and a piece in hand
counting nothing, less the same for the other side.

A third argument adds up to three more terms, as a hash reference of weights:

=over 4

=item C<exposed>

Held against a side: what it stands to lose to the other side's next roll,
which is, for each of its pieces an enemy piece could land on, the chance of
the roll that does it times the steps the piece would be sent back. The
weight is in sixteenths, so 16 holds all of it against the side.

=item C<rosette>

For each of a side's pieces standing on a rosette that both sides visit.

=item C<entry>

Against each of a side's pieces still in hand.

=back

A weight that is not one of the three B<croaks>.

=head2 greedy

    my $index = $board->greedy($roll, $rules);

The move to make without looking ahead, as an index into what C<moves>
returns for the same roll: one that captures if any does, else one that lands
on a rosette if any does, else the piece furthest along. -1 when the roll
allows nothing.

=head2 search

    my $found = $board->search($roll, depth => 3);
    my $found = $board->search($roll, rules => 'masters', budget => 50_000,
                                weights => { exposed => 16 });

Looks ahead through the dice and returns the best move for the side to move.
The board is as it was.

Every roll the dice can make is weighed by how likely it is; the side to move
is taken to choose what is best for it and the other side what is worst; and
a roll that allows nothing loses the turn like any other. A level is one roll
and one move, or one roll and a lost turn.

=over 4

=item C<depth>

How many levels to look. 0, the default, for no limit but the budget.

=item C<budget>

How many positions the search may visit. It stops when they are spent and
answers from the deepest level it finished. The first level always finishes.
B<A search is bounded in positions and never in seconds>, so the same board,
roll and options give the same answer on every machine.

=item C<rules>, C<weights>

A rule set, and the weights of the evaluation, as C<evaluate> takes them.

=back

Returns a hash reference:

    { index => 1, depth => 3, value => 812, nodes => '3391', stopped => 0 }

C<index> is the move, as an index into what C<moves> returns for the same
roll, or -1 when the roll allows nothing or the game is over. Moves of equal
value go to the last of them, the piece furthest along. C<depth> is the
deepest level that finished, C<value> what the move is worth to the side to
move in sixteenths of a step, C<nodes> how many positions were visited, as a
string of digits, and C<stopped> is true when the budget ran out part way
through a level.

A value near C<WIN> or its negative is a game seen to be won or lost.

B<Croaks> on a roll, a budget, a depth or an option it does not understand.

=head2 abi_version

The version of the C interface this build provides.

=head2 live

How many boards exist that have not yet been released. For tests.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
