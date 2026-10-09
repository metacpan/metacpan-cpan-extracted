package Game::Brandubh::Engine;

use 5.010;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Game::Brandubh', $VERSION);

use constant {
    EMPTY    => 0,
    ATTACKER => 1,
    DEFENDER => 2,
    KING     => 3,
    BORDER   => 4,

    ATTACKERS => 0,
    DEFENDERS => 1,

    SIZE    => 7,
    SQUARES => 49,
};

use constant {
    POS_OK     => 0,
    POS_NULL   => 1,
    POS_ROWS   => 2,
    POS_WIDTH  => 3,
    POS_LETTER => 4,
    POS_SIDE   => 5,
    POS_LONG   => 6,
};

use constant {
    WHY_OK         => 0,
    WHY_OFF_BOARD  => 1,
    WHY_NO_PIECE   => 2,
    WHY_NOT_YOURS  => 3,
    WHY_NO_MOVE    => 4,
    WHY_NOT_A_LINE => 5,
    WHY_THRONE     => 6,
    WHY_CORNER     => 7,
    WHY_BLOCKED    => 8,
};

use constant {
    DID_CAPTURE => 1,
    KING_TAKEN  => 2,
    KING_HOME   => 4,
};

our @EXPORT_OK = qw(
    EMPTY ATTACKER DEFENDER KING BORDER
    ATTACKERS DEFENDERS SIZE SQUARES
    POS_OK POS_NULL POS_ROWS POS_WIDTH POS_LETTER POS_SIDE POS_LONG
    WHY_OK WHY_OFF_BOARD WHY_NO_PIECE WHY_NOT_YOURS WHY_NO_MOVE
    WHY_NOT_A_LINE WHY_THRONE WHY_CORNER WHY_BLOCKED
    DID_CAPTURE KING_TAKEN KING_HOME
    other
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub other { $_[0] == ATTACKERS ? DEFENDERS : ATTACKERS }

has _ptr => (is => 'rw', private => 1);

has _empty => (is => 'ro', init_arg => 'empty', private => 1, default => 0);

has _position => (is => 'ro', init_arg => 'position', private => 1);

my %ADOPTING;

sub BUILD {
    my ($self) = @_;
    my $given = $self->_ptr;
    if ($given) {
        return if delete $ADOPTING{$given};
        $self->_ptr(0);
        Carp::croak("Game::Brandubh::Engine: a board is made by new, of_string or clone");
    }

    my $position = $self->_position;
    if (defined $position) {
        my ($ptr, $err) = _of_string($position);
        Carp::croak("Game::Brandubh::Engine: the position was refused, code $err")
            unless defined $ptr;
        $self->_ptr($ptr);
        return;
    }

    $self->_ptr($self->_empty ? _new_empty() : _new_board());
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

sub at          { _at($_[0]->_ptr, $_[1]) }
sub put         { _put($_[0]->_ptr, $_[1], $_[2]); return $_[0] }
sub lift        { _lift($_[0]->_ptr, $_[1]); return $_[0] }
sub side        { _side($_[0]->_ptr) }
sub set_side    { _set_side($_[0]->_ptr, $_[1]); return $_[0] }
sub count       { _count($_[0]->_ptr, $_[1]) }
sub king_square { _king_square($_[0]->_ptr) }
sub to_string   { _to_string($_[0]->_ptr) }
sub key_hex     { _key_hex($_[0]->_ptr) }
sub key_full_hex { _key_full_hex($_[0]->_ptr) }

sub square_of     { my $c = shift; _square_of($_[0], $_[1]) }
sub file_of       { my $c = shift; _file_of($_[0]) }
sub rank_of       { my $c = shift; _rank_of($_[0]) }
sub on_board      { my $c = shift; _on_board($_[0]) }
sub is_throne     { my $c = shift; _is_throne($_[0]) }
sub is_corner     { my $c = shift; _is_corner($_[0]) }
sub beside_throne { my $c = shift; _beside_throne($_[0]) }
sub side_of       { my $c = shift; _side_of($_[0]) }
sub stride        { _stride() }

sub all_squares {
    my @squares;
    for my $rank (0 .. SIZE - 1) {
        push @squares, map { _square_of($_, $rank) } 0 .. SIZE - 1;
    }
    return @squares;
}

sub zobrist_hex      { my $c = shift; _zobrist_hex($_[0], $_[1]) }
sub zobrist_side_hex { _zobrist_side_hex() }
sub abi_version      { _abi_version() }
sub live             { _live() }

sub move      { _move_make($_[1], $_[2]) }
sub move_from { _move_from($_[1]) }
sub move_to   { _move_to($_[1]) }
sub moves_max { _moves_max() }

sub moves {
    my @m = _gen_moves($_[0]->_ptr, $_[1]);
    return wantarray ? @m : scalar @m;
}

sub is_legal { _is_legal($_[0]->_ptr, $_[1], $_[2]) }
sub why_not  { _why_not($_[0]->_ptr, $_[1], $_[2], $_[3]) }
sub relocate { _relocate($_[0]->_ptr, $_[1]); return $_[0] }

sub perft_slides { _perft_slides($_[0]->_ptr, $_[1], $_[2]) }

sub hostile_to  { _hostile_to($_[0]->_ptr, $_[1], $_[2]) }
sub captures_at { _captures_at($_[0]->_ptr, $_[1], $_[2]) }
sub do_move     { _do_move($_[0]->_ptr, $_[1], $_[2]) }
sub undo_move   { _undo_move($_[0]->_ptr, $_[1]); return $_[0] }
sub preview     { _preview($_[0]->_ptr, $_[1], $_[2]) }
sub perft       { _perft($_[0]->_ptr, $_[1], $_[2]) }

1;

__END__

=head1 NAME

Game::Brandubh::Engine - the brandubh board: squares, pieces, the side to move

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Brandubh::Engine ':all';

    my $board = Game::Brandubh::Engine->new;
    print $board->to_string, "\n";      # 3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a

    my $d4 = Game::Brandubh::Engine->square_of(3, 3);
    print "the king\n" if $board->at($d4) == KING;

    my ($other, $err) = Game::Brandubh::Engine->of_string('7/7/7/3k3/7/7/7 d');

=head1 DESCRIPTION

A position: forty-nine squares, what stands on each, and whose move it is;
where each piece of the side to move may go; and what a move captures.

C<put>, C<lift> and C<relocate> B<judge nothing>: C<put> will place two kings
on a corner if asked. C<moves>, C<is_legal> and C<why_not> are where the rules
of movement live, and C<do_move> is where the rules of capture do.

B<Nothing here knows how a game ends.> C<do_move> reports that the king was
captured, or that he reached a corner, and plays on regardless.

Most callers want L<Game::Brandubh>, which holds one of these and plays the
game. This class is for building positions and asking what is on them.

=head2 A square is an opaque number

A square is a number handed out by C<square_of> and taken apart by C<file_of>
and C<rank_of>. It is B<not> C<rank * 7 + file> and nothing should assume a
relationship between two squares except through C<stride>: the square one file
to the right is C<$sq + 1>, and the square one rank up is C<$sq + stride>.

Files run 0 to 6 for a to g and ranks 0 to 6 for 1 to 7, so C<square_of(3, 3)>
is d4, the throne.

=head2 The key is a hex string, never a number

C<key_hex> is sixteen lowercase hexadecimal characters. It is a string on every
perl, because a perl built with 32-bit integers cannot hold the number it
stands for.

Two positions with the same pieces on the same squares and the same side to
move have the same key, in every process, on every machine.

=head2 How a piece moves

A piece moves any distance along a rank or a file. It may not land on another
piece and may not jump one.

No piece may stop on the throne, the king included once he has left it. Only
the king may stop on a corner.

A piece B<may> slide across the empty throne on its way somewhere else. The
rules this distribution follows forbid landing there and forbid jumping
pieces, and say nothing of an empty square in the way, so this is the
distribution's own reading; C<throne_pass> turns it off.

=head2 How a piece is captured

A piece other than the king is captured when the enemy moves a piece so that
it stands between two enemies on opposite sides, along a rank or a file.

An empty corner, and the throne while it is empty, each count as an enemy to
both sides: a piece next to one is captured by a single enemy moving to the
other side of it. The edge of the board never counts.

B<Only the piece that moved captures.> A piece may move between two enemies
and stand there unharmed. This is the usual tafl rule and the rules this
distribution follows do not state it, so it is the distribution's reading.

One move may close on an enemy in up to three directions and takes every
piece it closes on.

The king captures as any defender does, by moving or by standing still.

=head2 How the king is captured

By attackers only, and it depends where he stands.

=over 4

=item On the throne

All four squares beside him hold attackers.

=item Beside the throne

The three squares beside him that are not the throne hold attackers.

=item Anywhere else

As any other piece: between two attackers, or between an attacker and an
empty corner.

=back

Two variant fields change this. C<king_everywhere_two> takes him as any other
piece wherever he stands, the throne included. C<king_strong> requires every
side of him closed, by an attacker or by the empty throne, wherever he stands;
the edge closes nothing, so a king on it cannot be taken.

=head2 A move is an opaque number

Build one with C<move> from two squares and take it apart with C<move_from>
and C<move_to>. What a move captures is decided by the position and is not
part of the move.

=head2 A variant is a hash reference

Every method that applies a rule takes an optional last argument naming what
differs from the default game. Leave it out, or pass C<undef>, for the
default.

    my @moves = $board->moves({ throne_pass => 0 });

=over 4

=item C<throne_pass>

True by default: a piece may slide across the empty throne.

=item C<throne_reentry>

False by default: the king may not return to the throne.

=item C<king_everywhere_two>, C<king_strong>

Both false by default. See L</How the king is captured>.

=item C<escape>

C<'corner'> by default: C<do_move> reports the king home when his move ends
on a corner. With C<'edge'>, on any square of the edge.

=item C<repeat>, C<ply_cap>

Accepted, and without effect until endings arrive.

=back

A key that is not one of these B<croaks>, so that a misspelt field cannot
quietly play the default game.

=head2 Every board is its own board

C<clone> returns a board that shares nothing with the one it came from. A
board is released when the last reference to it goes away.

=head1 CONSTANTS

Exported on request, or all at once with C<:all>.

=over 4

=item C<EMPTY>, C<ATTACKER>, C<DEFENDER>, C<KING>

What C<at> returns for a square of the board.

=item C<BORDER>

What C<at> returns for a number that is not a square of the board.

=item C<ATTACKERS>, C<DEFENDERS>

The two sides. The king is on the defenders' side.

=item C<SIZE>, C<SQUARES>

7 and 49.

=item C<POS_OK>, C<POS_NULL>, C<POS_ROWS>, C<POS_WIDTH>, C<POS_LETTER>, C<POS_SIDE>, C<POS_LONG>

Why a position string was refused: no string, not seven rows, a row that is
not seven wide, a character that names no piece, a missing or unknown side, a
string too long to be a position.

=item C<WHY_OK>, C<WHY_OFF_BOARD>, C<WHY_NO_PIECE>, C<WHY_NOT_YOURS>, C<WHY_NO_MOVE>, C<WHY_NOT_A_LINE>, C<WHY_THRONE>, C<WHY_CORNER>, C<WHY_BLOCKED>

What C<why_not> answers: the move is legal, a square is off the board, nothing
stands on the first square, the piece belongs to the side not to move, the two
squares are one square, they share neither rank nor file, the move would stop
on the throne or cross one it may not cross, only the king may stand on a
corner, a piece is in the way.

=item C<DID_CAPTURE>, C<KING_TAKEN>, C<KING_HOME>

Bits of what C<do_move> and C<preview> report: at least one piece was
captured; a king was among them; the king moved and ended where he wins.

=back

=head1 FUNCTIONS

=head2 other

    my $side = other(ATTACKERS);    # DEFENDERS

The other side. Exported on request.

=head1 METHODS

=head2 new

    my $board = Game::Brandubh::Engine->new;
    my $board = Game::Brandubh::Engine->new(empty => 1);
    my $board = Game::Brandubh::Engine->new(position => '3a3/3a3/3d3/aadkdaa/3d3/3a3/3a3 a');

The set-up, an empty board with the attackers to move, or the position a
string describes. B<Croaks> on a string it will not take; use C<of_string> to
get the reason back instead.

=head2 of_string

    my ($board, $err) = Game::Brandubh::Engine->of_string($string);

A board and C<POS_OK>, or C<undef> and one of the C<POS_*> codes. A string is
refused for its shape and never for its sense: two kings, or none, both load.

=head2 to_string

Seven rows from rank 7 down to rank 1 with a C</> between them, a digit for a
run of empty squares, then a space and the side to move. C<a> is an attacker,
C<d> a defender, C<k> the king, and the side is C<a> or C<d>.

=head2 clone

A copy that shares nothing with the original.

=head2 at

    my $piece = $board->at($square);

C<EMPTY>, C<ATTACKER>, C<DEFENDER> or C<KING>, or C<BORDER> for a number that
is not a square.

=head2 put

    $board->put($square, DEFENDER);

Places a piece, replacing whatever stood there. Judges nothing. Returns the
board.

=head2 lift

    $board->lift($square);

Empties a square. Returns the board.

=head2 side

C<ATTACKERS> or C<DEFENDERS>: whose move it is.

=head2 set_side

    $board->set_side(DEFENDERS);

Returns the board.

=head2 count

    my $n = $board->count(ATTACKER);

How many of one piece are on the board.

=head2 king_square

The king's square, or -1 when there is no king on the board.

=head2 key_hex

The position's key. See L</The key is a hex string, never a number>.

=head2 key_full_hex

The same key worked out again from the squares. It always equals C<key_hex>;
it exists so a test can show that.

=head2 square_of

    my $sq = Game::Brandubh::Engine->square_of($file, $rank);

A square, or -1 when the file or the rank is off the board.

=head2 file_of

=head2 rank_of

The file or the rank of a square, 0 to 6, or -1 for a number that is not a
square.

=head2 on_board

True for the forty-nine squares.

=head2 is_throne

True for d4 and for no other square, whether or not the king stands on it.

=head2 is_corner

True for a1, a7, g1 and g7.

=head2 beside_throne

True for d3, d5, c4 and e4: the four squares that share an edge with the
throne.

=head2 side_of

    my $side = Game::Brandubh::Engine->side_of(KING);    # DEFENDERS

The side a piece is on, or -1 for something that is not a piece.

=head2 stride

The distance between a square and the one a rank above it.

=head2 all_squares

The forty-nine squares, a1 to g1 first and a7 to g7 last.

=head2 zobrist_hex

    my $hex = Game::Brandubh::Engine->zobrist_hex(KING, $square);

The contribution of one piece on one square to a key.

=head2 zobrist_side_hex

The contribution of the defenders being the side to move.

=head2 abi_version

The version of the table of functions other compiled code may call.

=head2 live

How many boards exist in this process and have not been released.

=head2 move

    my $mv = Game::Brandubh::Engine->move($from, $to);

A move between two squares. Nothing is checked.

=head2 move_from

=head2 move_to

The square a move leaves and the square it arrives on.

=head2 moves

    my @moves = $board->moves;
    my $count = $board->moves;
    my @moves = $board->moves(\%variant);

Every move of the side to move: a list in list context, a count in scalar
context. The list is in square order, a1 first, and for each piece left, right,
down, then up, nearest square first.

=head2 moves_max

The most moves any position can have, whatever stands on the board. Along one
line an empty square can be reached by at most two pieces, the nearest on each
side, which bounds the whole board at 140.

=head2 is_legal

    if ($board->is_legal($mv)) { ... }
    if ($board->is_legal($mv, \%variant)) { ... }

True when the move is one of C<moves>.

=head2 why_not

    my $why = $board->why_not($from, $to);
    my $why = $board->why_not($from, $to, \%variant);

C<WHY_OK> for a legal move, and otherwise the first thing wrong with it, one
of the C<WHY_*> constants. It is C<WHY_OK> exactly when C<is_legal> is true.

=head2 relocate

    $board->relocate($mv);

Moves whatever stands on the first square to the second, replacing what was
there, and passes the turn. B<It asks nothing and captures nothing.> Returns
the board.

=head2 perft_slides

    my $nodes = $board->perft_slides(3);
    my $nodes = $board->perft_slides(3, \%variant);

How many sequences of that many moves there are from this position when
nothing is ever captured. B<A string of decimal digits>, because the number
outgrows a 32-bit integer within a few moves. The board is left as it was.

=head2 hostile_to

    if ($board->hostile_to($square, DEFENDERS)) { ... }

True when the square counts as an enemy of that side in a capture: it holds a
piece of the other side, or it is an empty corner, or the empty throne.

=head2 captures_at

    my @squares = $board->captures_at($square);
    my @squares = $board->captures_at($square, \%variant);

The squares whose pieces are captured by the piece standing on C<$square>, as
if it had just arrived there. Nothing is removed.

=head2 do_move

    my ($flags, $undo) = $board->do_move($mv);
    my ($flags, $undo) = $board->do_move($mv, \%variant);

Moves the piece, removes what it captured and passes the turn. C<$flags> is
C<DID_CAPTURE>, C<KING_TAKEN> and C<KING_HOME> or'd together, or 0.

B<It does not ask whether the move is legal>; ask C<is_legal> first. It asks
only that a piece stands on the first square and nothing on the second, and
otherwise does nothing and reports 0.

C<$undo> is an opaque string for C<undo_move>.

=head2 undo_move

    $board->undo_move($undo);

Takes back the move that produced C<$undo>: the piece returns, the captured
pieces return, the turn returns. Moves are taken back in the reverse of the
order they were made. Returns the board. B<Croaks> on a string that is not an
undo.

=head2 preview

    my ($flags, @squares) = $board->preview($mv);
    my ($flags, @squares) = $board->preview($mv, \%variant);

What C<do_move> would report and which squares it would empty, without
touching the board.

=head2 perft

    my $nodes = $board->perft(3);
    my $nodes = $board->perft(3, \%variant);

How many sequences of that many moves there are from this position, with
captures played. B<A string of decimal digits.> Nothing ends a sequence early:
a side whose king has been captured goes on moving what it has left. The board
is left as it was.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
