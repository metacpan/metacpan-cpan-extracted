package Game::Sternhalma::Engine;

use 5.014;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;

use Game::Sternhalma::Notation ();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Game::Sternhalma', $VERSION);

use constant {
    E  => 0,
    NE => 1,
    NW => 2,
    W  => 3,
    SW => 4,
    SE => 5,
};

use constant {
    HOLES      => 121,
    ROWS       => 17,
    POINTS     => 6,
    CENTRE     => 6,
    SEATS_MAX  => 6,
    PIECES     => 10,
    PIECES_MAX => 15,
    PAIRS      => 312,
    STEPS_MAX  => 6,
    HOPS_MAX   => 6,
    REACH_MAX  => 120,
    PATH_MAX   => 37,
    LEGAL_MAX  => 1800,
};

use constant {
    POS_OK     => 0,
    POS_NULL   => 1,
    POS_LONG   => 2,
    POS_LETTER => 3,
    POS_ROWS   => 4,
    POS_WIDTH  => 5,
    POS_FIELDS => 6,
    POS_SEAT   => 7,
    POS_COUNT  => 8,
    POS_GAME   => 9,
};

use constant {
    ONGOING          => 0,
    BY_HOME          => 1,
    BY_CAP           => 2,
    BY_DEADLOCK      => 3,
    BY_RESIGN        => 4,
    PLY_CAP_PER_SEAT => 1000,
};

use constant {
    WIN_SCORE       => 100000,
    SEARCH_AUTO     => 0,
    SEARCH_PARANOID => 1,
    SEARCH_MAXN     => 2,
};

use constant {
    PLAY_OK         => 0,
    WHY_OVER        => 1,
    WHY_NOT_A_HOLE  => 2,
    WHY_NO_PIECE    => 3,
    WHY_NOT_YOURS   => 4,
    WHY_UNREACHABLE => 5,
    WHY_HAS_MOVE    => 6,
    WHY_NOT_A_SEAT  => 7,
    WHY_SEAT_DONE   => 8,
};

our @EXPORT_OK = qw(
    E NE NW W SW SE
    HOLES ROWS POINTS CENTRE SEATS_MAX PIECES PIECES_MAX PAIRS STEPS_MAX HOPS_MAX
    REACH_MAX PATH_MAX LEGAL_MAX
    ONGOING BY_HOME BY_CAP BY_DEADLOCK BY_RESIGN PLY_CAP_PER_SEAT
    PLAY_OK WHY_OVER WHY_NOT_A_HOLE WHY_NO_PIECE WHY_NOT_YOURS WHY_UNREACHABLE
    WHY_HAS_MOVE WHY_NOT_A_SEAT WHY_SEAT_DONE
    WIN_SCORE SEARCH_AUTO SEARCH_PARANOID SEARCH_MAXN
    POS_OK POS_NULL POS_LONG POS_LETTER POS_ROWS POS_WIDTH POS_FIELDS POS_SEAT POS_COUNT POS_GAME
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my @REASON = (
    'the position is fine',
    'there is no position',
    'the position is too long',
    'the position has a character that is not a seat, a run of empty holes or a /',
    'the position does not have seventeen rows',
    'a row of the position is not as long as that row of the star',
    'the seat to move, the seat count or the piece count is missing or wrong',
    'the position has a piece of a seat the game does not have',
    'a seat does not have exactly its pieces',
    'the game after the ; is malformed, out of order, or does not agree with itself',
);

has _ptr => (is => 'rw', private => 1);

has _hold => (is => 'rw', private => 1);

has _want_empty => (is => 'ro', init_arg => 'empty', private => 1, default => 0);

has _want_position => (is => 'ro', init_arg => 'position', private => 1);

has _want_seats => (is => 'ro', init_arg => 'seats', private => 1, default => 2);

has _want_pieces => (is => 'ro', init_arg => 'pieces', private => 1, default => PIECES);

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
        Carp::croak("Game::Sternhalma::Engine: a board is made by new, from_string or clone");
    }

    my $position = $self->_want_position;
    if (defined $position) {
        my ($ptr, $err) = _of_string($position);
        Carp::croak("Game::Sternhalma::Engine: the position was refused: $REASON[$err]")
            unless defined $ptr;
        $self->_ptr($ptr);
        $self->_hold(_hold_board($ptr));
        return;
    }

    my ($seats, $pieces) = ($self->_want_seats, $self->_want_pieces);
    Carp::croak("Game::Sternhalma::Engine: no game is $seats seats of $pieces pieces")
        unless defined $seats && defined $pieces
            && $seats =~ /\A[0-9]+\z/ && $pieces =~ /\A[0-9]+\z/
            && _layout_ok($seats, $pieces);

    $self->_ptr($self->_want_empty ? _new_empty($seats, $pieces) : _new_board($seats, $pieces));
    Carp::croak("Game::Sternhalma::Engine: the board was not built") unless $self->_ptr;
    $self->_hold(_hold_board($self->_ptr));
    return;
}

my $adopt = sub {
    my ($class, $ptr) = @_;
    $ADOPTING{$ptr} = 1;
    return $class->new(_ptr => $ptr);
};

sub from_string {
    my ($class, $position) = @_;
    my ($ptr, $err) = _of_string(defined $position ? $position : '');
    return (undef, $err) unless defined $ptr;
    return ($adopt->(ref($class) || $class, $ptr), POS_OK);
}

sub reason {
    my ($class, $code) = @_;
    return defined $code && $code =~ /\A[0-9]+\z/ ? $REASON[$code] : undef;
}

sub clone {
    my ($self) = @_;
    return $adopt->(ref($self), _copy_board($self->_ptr));
}

sub at {
    my ($self, $hole) = @_;
    return undef unless _is_hole($hole);
    my $seat = _at($self->_ptr, $hole);
    return $seat < SEATS_MAX ? $seat : undef;
}

sub put {
    my ($self, $hole, $seat) = @_;
    _put($self->_ptr, $hole, $seat) if _is_hole($hole) && defined $seat && $seat =~ /\A[0-9]+\z/;
    return $self;
}

sub lift {
    my ($self, $hole) = @_;
    _lift($self->_ptr, $hole) if _is_hole($hole);
    return $self;
}

sub set_to_move {
    my ($self, $seat) = @_;
    _set_to_move($self->_ptr, $seat) if defined $seat && $seat =~ /\A[0-9]+\z/;
    return $self;
}

sub to_move   { _to_move($_[0]->_ptr) }
sub seats     { _board_seats($_[0]->_ptr) }
sub pieces    { _board_pieces($_[0]->_ptr) }
sub count     { _count($_[0]->_ptr, $_[1]) }
sub to_string { _to_string($_[0]->_ptr) }
sub key       { _key_hex($_[0]->_ptr) }

sub seat_point {
    my ($self, $seat) = @_;
    my $point = _layout_point($self->seats, $seat);
    return $point < 0 ? undef : $point;
}

sub steps {
    my ($self, $hole) = @_;
    return unless _is_hole($hole);
    return _steps($self->_ptr, $hole);
}

sub hops {
    my ($self, $hole, $from) = @_;
    return unless _is_hole($hole);
    $from = $hole unless defined $from;
    return unless $from eq '-1' || _is_hole($from);
    return _hops($self->_ptr, $hole, $from);
}

sub do_move {
    my ($self, $from, $to) = @_;
    return 0 unless _is_hole($from) && _is_hole($to);
    return _do_move($self->_ptr, $from, $to) ? 1 : 0;
}

sub undo_move {
    my ($self, $from, $to) = @_;
    return 0 unless _is_hole($from) && _is_hole($to);
    return _undo_move($self->_ptr, $from, $to) ? 1 : 0;
}

sub reach {
    my ($self, $from) = @_;
    return unless _is_hole($from);
    return _reach($self->_ptr, $from);
}

sub path {
    my ($self, $from, $to) = @_;
    return unless _is_hole($from) && _is_hole($to);
    return _path($self->_ptr, $from, $to);
}

sub legal {
    my ($self) = @_;
    my @flat = _legal($self->_ptr);
    my @pairs;
    push @pairs, [ splice @flat, 0, 2 ] while @flat;
    return @pairs;
}

sub _is_seat { defined $_[1] && $_[1] =~ /\A[0-9]+\z/ && $_[1] < $_[0]->seats }

sub home_complete { $_[0]->_is_seat($_[1]) ? _home_complete($_[0]->_ptr, $_[1]) : 0 }
sub finished      { $_[0]->_is_seat($_[1]) ? _finished($_[0]->_ptr, $_[1]) : 0 }
sub place_of      { $_[0]->_is_seat($_[1]) ? _place_of($_[0]->_ptr, $_[1]) : 0 }
sub distance_left { $_[0]->_is_seat($_[1]) ? _distance_left($_[0]->_ptr, $_[1]) : undef }
sub places        { my ($self) = @_; map { _place_of($self->_ptr, $_) } 0 .. $self->seats - 1 }
sub can_pass      { _can_pass($_[0]->_ptr) ? 1 : 0 }
sub over          { _game_over($_[0]->_ptr) ? 1 : 0 }
sub how           { _game_how($_[0]->_ptr) }
sub ply           { _ply($_[0]->_ptr) }
sub cap           { _cap($_[0]->_ptr) }

sub set_cap {
    my ($self, $cap) = @_;
    _set_cap($self->_ptr, $cap) if defined $cap && $cap =~ /\A[0-9]+\z/;
    return $self;
}

sub play {
    my ($self, $from, $to) = @_;
    return (WHY_NOT_A_HOLE) unless _is_hole($from) && _is_hole($to);
    return _play($self->_ptr, $from, $to);
}

sub pass { _pass($_[0]->_ptr) }

sub resign {
    my ($self, $seat) = @_;
    return (WHY_NOT_A_SEAT) unless $self->_is_seat($seat);
    return _resign($self->_ptr, $seat);
}

sub unplay {
    my ($self, $token) = @_;
    return 0 unless defined $token;
    return _unplay($self->_ptr, $token) ? 1 : 0;
}

sub name      { Game::Sternhalma::Notation::name_of($_[1]) }
sub hole_named { Game::Sternhalma::Notation::hole_of($_[1]) }

sub _neighbour {
    my ($p, $q) = @_;
    return scalar grep { $_ == $q } __PACKAGE__->neighbours($p);
}

sub move_text {
    my ($self, $from, $to) = @_;
    my @p = $self->path($from, $to);
    return undef unless @p;
    my $kind = @p == 2 && _neighbour(@p) ? 'step' : 'chain';
    return Game::Sternhalma::Notation::format_move({ kind => $kind, holes => \@p });
}

sub read_move {
    my ($self, $text) = @_;
    my $m = Game::Sternhalma::Notation::parse_move($text)
        or return (undef, 'not a move: ' . (defined $text ? $text : 'nothing'));
    return ($m) if $m->{kind} eq 'pass' || $m->{kind} eq 'resign';
    my @h = @{ $m->{holes} };
    my ($from, $to) = ($h[0], $h[-1]);
    my $seat = $self->at($from);
    return (undef, $self->name($from) . ' holds no piece') unless defined $seat;
    if ($m->{kind} eq 'chain') {
        for my $i (1 .. $#h) {
            next if grep { $_ == $h[$i] } $self->hops($h[ $i - 1 ], $from);
            return (undef, "hop $i: " . $self->name($h[$i]) . ' is not a hop from ' . $self->name($h[ $i - 1 ]));
        }
    }
    return (undef, $self->name($to) . ' is not where ' . $self->name($from) . ' can go')
        unless grep { $_ == $to } $self->reach($from);
    return ({ kind => 'move', from => $from, to => $to, path => [ $self->path($from, $to) ] });
}

my @WEIGHT = qw(distance straggler classes blocking);

sub weights_default {
    my @w = _weights_default();
    return { map { $WEIGHT[$_] => $w[$_] } 0 .. $#WEIGHT };
}

my $weights = sub {
    my ($given) = @_;
    my $w = __PACKAGE__->weights_default;
    if ($given) {
        for my $k (keys %$given) {
            Carp::croak("Game::Sternhalma::Engine: no weight is called '$k'") unless exists $w->{$k};
            Carp::croak("Game::Sternhalma::Engine: the weight $k is a whole number")
                unless defined $given->{$k} && $given->{$k} =~ /\A-?[0-9]{1,6}\z/;
            $w->{$k} = $given->{$k};
        }
    }
    return map { $w->{$_} } @WEIGHT;
};

sub evaluate {
    my ($self, $seat, %with) = @_;
    return undef unless $self->_is_seat($seat);
    return _evaluate($self->_ptr, $seat, $weights->($with{weights}));
}

sub search {
    my ($self, %with) = @_;
    my $budget = defined $with{budget} ? $with{budget} : 100_000;
    my $seed   = defined $with{seed}   ? $with{seed}   : 1;
    my $depth  = defined $with{depth}  ? $with{depth}  : 0;
    my $mode   = defined $with{mode}   ? $with{mode}   : SEARCH_AUTO;
    for ([ budget => $budget ], [ seed => $seed ], [ depth => $depth ], [ mode => $mode ]) {
        Carp::croak("Game::Sternhalma::Engine: $_->[0] is a whole number") unless $_->[1] =~ /\A[0-9]{1,15}\z/;
    }
    my $avoid = $with{avoid};
    Carp::croak('Game::Sternhalma::Engine: avoid is a list of keys')
        if defined $avoid && (ref $avoid ne 'ARRAY' || grep { !defined || !/\A[0-9a-f]{16}\z/ } @$avoid);
    my @r = _search($self->_ptr, $budget, $seed, $depth, $mode, $weights->($with{weights}), $avoid);
    return undef unless @r;
    return { from => $r[0], to => $r[1], pass => ($r[0] < 0 ? 1 : 0), nodes => $r[2], depth => $r[3],
             score => $r[4], stopped => $r[5] };
}

sub own_key {
    my ($self, $seat) = @_;
    return undef unless $self->_is_seat($seat);
    return _own_key_hex($self->_ptr, $seat);
}

sub random_forward {
    my ($self, $seed) = @_;
    $seed = 1 unless defined $seed && $seed =~ /\A[0-9]{1,15}\z/;
    my @r = _random_forward($self->_ptr, $seed);
    return undef unless @r;
    return { from => $r[0], to => $r[1], pass => ($r[0] < 0 ? 1 : 0) };
}

sub _is_hole { defined $_[0] && $_[0] =~ /\A[0-9]+\z/ && $_[0] < HOLES }

sub abi_version { _abi_version() }
sub live        { _live() }
sub tables_ok   { _tables_ok() }
sub holes       { HOLES }

sub layout_ok {
    my (undef, $seats, $pieces) = @_;
    return 0 unless defined $seats && defined $pieces
        && $seats =~ /\A[0-9]+\z/ && $pieces =~ /\A[0-9]+\z/;
    return _layout_ok($seats, $pieces) ? 1 : 0;
}

sub layout_point {
    my (undef, $seats, $seat) = @_;
    my $point = _layout_point($seats, $seat);
    return $point < 0 ? undef : $point;
}

sub hole_at {
    my (undef, $x, $y) = @_;
    my $hole = _hole_of($x, $y);
    return $hole < 0 ? undef : $hole;
}

sub xy {
    my (undef, $hole) = @_;
    return unless _is_hole($hole);
    my ($x, $y) = (_hole_x($hole), _hole_y($hole));
    return ($x, $y, -$x - $y);
}

sub row_of    { _is_hole($_[1]) ? _row_of($_[1]) : undef }
sub col_of    { _is_hole($_[1]) ? _col_of($_[1]) : undef }
sub row_len   { _row_len($_[1]) }
sub row_start { my $s = _row_start($_[1]); $s < 0 ? undef : $s }

sub next_to {
    my (undef, $hole, $dir) = @_;
    return undef unless _is_hole($hole);
    my $to = _next($hole, $dir);
    return $to < 0 ? undef : $to;
}

sub neighbours {
    my (undef, $hole) = @_;
    return unless _is_hole($hole);
    return grep { $_ >= 0 } map { _next($hole, $_) } E .. SE;
}

sub degree       { _is_hole($_[1]) ? _degree($_[1]) : 0 }
sub dir_opposite { my $d = _dir_opposite($_[1]); $d < 0 ? undef : $d }
sub point_of     { _is_hole($_[1]) ? _point_of($_[1]) : undef }
sub on_ring      { _is_hole($_[1]) ? _on_ring($_[1]) : 0 }
sub class_of     { _is_hole($_[1]) ? _class_of($_[1]) : undef }
sub point_holes  { _point_holes($_[1]) }
sub front        { _front($_[1]) }

sub pairs {
    my @flat = _pairs();
    my @pairs;
    push @pairs, [ splice @flat, 0, 2 ] while @flat;
    return @pairs;
}

sub zobrist       { _zobrist_hex($_[1], $_[2]) }
sub zobrist_move  { _zobrist_move_hex($_[1]) }
sub zobrist_seats { _zobrist_seats_hex($_[1]) }

1;

__END__

=head1 NAME

Game::Sternhalma::Engine - the sternhalma board: holes, points, seats and the key

=head1 SYNOPSIS

    use Game::Sternhalma::Engine qw(:all);

    my $board = Game::Sternhalma::Engine->new(seats => 3);
    print $board->to_string, "\n";
    print $board->key, "\n";

    my $top = 0;
    my @beside = Game::Sternhalma::Engine->neighbours($top);

    my ($copy, $code) = Game::Sternhalma::Engine->from_string($board->to_string);

=head1 DESCRIPTION

The board of star halma and nothing that judges a move: the 121 holes, which
are neighbours, the six points, the hexagon and its ring, the four hop
classes, which points a seat count starts in, whose turn it is, a key that
names the position, and the position written as a string.

Holes are numbered 0 to 120 in reading order, the top tip first and then each
row from the top, left to right. A hole also has cube coordinates C<(x, y, z)>
with C<x + y + z == 0>: C<y> is the row, from -8 at the top, and C<x> grows to
the right along a row.

The six points are numbered 0 to 5 clockwise from the top: top, top right,
bottom right, bottom, bottom left, top left. A point's opposite is three
round. A hole in the middle hexagon is in C<CENTRE>.

The six directions are C<E>, C<NE>, C<NW>, C<W>, C<SW> and C<SE>, numbered 0
to 5, and a direction's opposite is three round.

Seats are numbered from 0, and seat 0 moves first. Two seats start at the top
and the bottom; three at the top, the bottom right and the bottom left; four
at the top, the top right, the bottom and the bottom left; six everywhere.

=head1 CONSTRUCTORS

=head2 new

    Game::Sternhalma::Engine->new(seats => 2, pieces => 10)
    Game::Sternhalma::Engine->new(seats => 4, empty => 1)
    Game::Sternhalma::Engine->new(position => $string)

A board with every seat in its start and seat 0 to move. C<seats> is 2, 3, 4
or 6 (default 2), or 1 for one seat crossing alone. C<pieces> is 10 (the
default), or 15 for one, two or three seats, where no two starting points
are neighbours. With C<empty>, every hole is empty. With C<position>, the
board that string writes. Croaks when it cannot build what it was asked for.

=head2 from_string

    my ($board, $code) = Game::Sternhalma::Engine->from_string($string);

The board a position string writes, and C<POS_OK>; or C<undef> and the code
that says why the string was refused (see L</reason>).

=head2 clone

A board of its own with the same position.

=head1 THE POSITION

=head2 to_string

The position as a string: the seventeen rows from the top, C</> between them;
in a row, a digit 0 to 5 is that seat's piece and C<[n]> is a run of C<n>
empty holes. Then a space, the seat to move, a space, the seat count, a space,
the piece count, and once the game has moved on, a C<;> and the game (see
L<Game::Sternhalma::Notation/Positions>). The two-seat set-up is

    0/00/000/0000/[13]/[12]/[11]/[10]/[9]/[10]/[11]/[12]/[13]/1111/111/11/1 0 2 10

=head2 reason

    Game::Sternhalma::Engine->reason($code)

The refusal code from L</from_string> in words. The codes, which are
exportable, are C<POS_OK>, C<POS_NULL>, C<POS_LONG>, C<POS_LETTER>,
C<POS_ROWS>, C<POS_WIDTH>, C<POS_FIELDS>, C<POS_SEAT>, C<POS_COUNT> and
C<POS_GAME>, and a string is checked in that order.

=head2 key

The position's key as sixteen hex digits. It names the pieces, the seat to
move and the seat count, and two boards with the same key are the same
position.

=head2 at

The seat whose piece is in a hole, or C<undef> for an empty hole or a number
that is not a hole.

=head2 put

    $board->put($hole, $seat)

Puts a piece of C<$seat> in C<$hole>, replacing what was there. It judges
nothing: the counts and the key follow, and a hole or seat the board does not
have is ignored. Returns the board.

=head2 lift

    $board->lift($hole)

Empties a hole. Returns the board.

=head2 to_move

The seat whose turn it is.

=head2 set_to_move

Makes it a seat's turn, and is ignored for a seat the board does not have.
Returns the board.

=head2 seats

How many seats the board has.

=head2 pieces

How many pieces each seat has.

=head2 count

    $board->count($seat)

How many of a seat's pieces are on the board.

=head2 seat_point

    $board->seat_point($seat)

The point that seat starts in.

=head1 ONE STEP AND ONE HOP

These are the atoms a move is made of. None of them asks whose turn it is.

=head2 steps

    my @to = $board->steps($hole);

The empty holes next to a hole, in direction order.

=head2 hops

    my @to = $board->hops($hole);
    my @to = $board->hops($hole, $from);

Where one hop from a hole lands: over one neighbouring piece, of any seat,
into the empty hole straight beyond it, in direction order. Nothing is taken.

C<$from> is the hole the moving piece left, for a piece in the middle of a
chain of hops: it counts as empty, so a hop may land on it and cannot go over
it, even while the board still shows the piece there. It defaults to C<$hole>;
-1 means the piece came from nowhere on the board.

=head2 do_move

    $board->do_move($from, $to)

Moves the piece on C<$from> to the empty hole C<$to>, wherever that is, and
keeps the key. Returns 1, or 0 and does nothing when C<$from> holds no piece
or C<$to> is not an empty hole. The seat to move stays as it was.

=head2 undo_move

    $board->undo_move($from, $to)

Takes back the move from C<$from> to C<$to>: the piece on C<$to> goes back
to C<$from>. Returns 1, or 0 and does nothing.

=head1 A MOVE

A move is a step, or a chain of hops by one piece that may stop after any
hop. A step and a hop never go in the same move. Nothing is captured, so a
move is no more than where it started and where it stopped.

=head2 reach

    my @to = $board->reach($from);

Every hole the piece on C<$from> can end its move on, in hole order: its
steps, and every hole a chain of hops lands on, wherever the chain stops.
Never C<$from> itself. Empty when C<$from> holds no piece.

=head2 path

    my @holes = $board->path($from, $to);

The move from C<$from> to C<$to> as the holes it goes through, C<$from>
first and C<$to> last: two holes for a step, and for a chain every hole it
lands on. A hole a step reaches is always shown as the step. A chain is a
shortest one, and among those always the same one. Empty when C<$to> is not
in the reach.

=head2 legal

    for my $move ($board->legal) { my ($from, $to) = @$move; ... }

The moves of the seat to move, as array references of C<[$from, $to]>: for
each of its pieces in hole order, its reach in hole order.

=head1 A GAME

The board also keeps a game: whose turn it is, who is home, and how it ended.
Only "every piece home" is the rule of the game. The rest are this
distribution's own rules, because the rules as written say nothing:

=over 4

=item * B<A parked piece cannot stop you.> A seat is home when every hole of
its home holds a piece and at least one of those pieces is its own, so a rival
who never moves a piece out of your home does not keep you from finishing.

=item * B<A seat with no move passes>, and when every seat still racing has
passed in a row the game ends.

=item * B<A game ends at its cap>, a number of plies (moves and passes), set
for now at 1,000 a seat.

=item * B<A seat that resigns> is placed behind every seat that finishes or is
still racing, and its pieces stay on the board.

=back

When a seat gets home it takes the next place and the others play on; with
two seats the first home wins. A seat can be made home by a rival's move,
when the rival's piece fills the last hole of its home. At the cap, or when
nobody can move, the seats still racing are placed by L</distance_left>,
equal distances sharing a place.

=head2 play

    my ($why, $undo) = $board->play($from, $to);

The seat to move moves its piece from C<$from> to C<$to>, which must be in the
piece's reach. C<$why> is C<PLAY_OK>, and then C<$undo> takes it back with
L</unplay>; or it says why not, and nothing changed: C<WHY_OVER>,
C<WHY_NOT_A_HOLE>, C<WHY_NO_PIECE>, C<WHY_NOT_YOURS> or C<WHY_UNREACHABLE>.

=head2 pass

    my ($why, $undo) = $board->pass;

The seat to move passes. Refused with C<WHY_HAS_MOVE> unless it has no move.

=head2 resign

    my ($why, $undo) = $board->resign($seat);

A seat still racing resigns, on its turn or not. Refused with
C<WHY_NOT_A_SEAT> or C<WHY_SEAT_DONE> (home already, or resigned).

=head2 unplay

    $board->unplay($undo)

Takes back a play, pass or resign. Undo them last first. Returns 1, or 0 when
it cannot.

=head2 can_pass

True when the seat to move has no move and the game is not over.

=head2 home_complete

    $board->home_complete($seat)

The seat's home is full, at least one piece in it its own.

=head2 finished

    $board->finished($seat)

The seat has been counted home in this game.

=head2 place_of

    $board->place_of($seat)

The seat's place, 1 the best; 0 while the game runs and the seat is not home.

=head2 places

The place of every seat, in seat order.

=head2 distance_left

    $board->distance_left($seat)

How far the seat's pieces are from home: 0 for a home full of its own pieces,
more for every piece out of place.

=head2 over

True when the game has ended.

=head2 how

How it ended: C<ONGOING>, C<BY_HOME>, C<BY_CAP>, C<BY_DEADLOCK> or
C<BY_RESIGN>.

=head2 ply

Moves and passes made.

=head2 cap

The ply the game stops at.

=head2 set_cap

    $board->set_cap($plies)

Sets the cap. Returns the board.

=head1 NAMES AND MOVES AS TEXT

The notation is L<Game::Sternhalma::Notation>'s.

=head2 name

    $board->name($hole)

A hole's name, C<a1> to C<q1>.

=head2 hole_named

    $board->hole_named('i5')

The hole a name names.

=head2 move_text

    $board->move_text($from, $to)

The move as text, by the path it is shown with: C<e5-f5> for a step,
C<e5:g5:g7> for a chain. C<undef> when it is not a move.

=head2 read_move

    my ($move, $why) = $board->read_move('e5-g7');

A move read from text against this board. C<from-to> is accepted for any
move, a chain included; a chain written out is accepted by any legal path
between the same two holes, since it is the same move. The answer is
C<< { kind => 'move', from, to, path } >> with the path the move is shown by,
or the pass or resignation as L<Game::Sternhalma::Notation/parse_move> gives
it; or C<undef> and why not, naming the hop that failed.

=head1 CHOOSING A MOVE

=head2 weights_default

A hash of the four weights the evaluation adds: C<distance>, C<straggler>,
C<classes> and C<blocking>.

=head2 evaluate

    $board->evaluate($seat, weights => { classes => 0 })

How good the position is for a seat, higher better: a large constant
(C<WIN_SCORE>) for a seat home, otherwise minus the weighted sum of how far
its pieces are from home, how far behind its rearmost piece is, how far its
pieces' hop classes are from its home's, and how many of its pieces sit in
the home in front of an empty hole deeper in.

=head2 search

    my $r = $board->search(budget => 100_000, seed => 7, depth => 0, mode => SEARCH_AUTO, avoid => \@keys);

The move the seat to move should make: C<< { from, to, pass, nodes, depth,
score, stopped } >>, or C<undef> when the game is over. C<budget> is
positions looked at, never seconds; the first ply is always looked at whole,
and after that a search that runs out plays the best move of the last depth
it finished. C<seed> settles ties and nothing else. C<depth> is the most
plies to look ahead, 0 for as deep as the budget goes. C<mode> is
C<SEARCH_AUTO> or C<SEARCH_PARANOID> (every rival against the seat to move,
which for two seats is the plain game) or C<SEARCH_MAXN> (every seat for
itself). C<weights> replaces any of the defaults. C<avoid> is the L</own_key>s
the seat to move's pieces have already had: a move that puts them back as
they were is not made while there is another, without which searching seats
can shuffle in their homes for ever.

=head2 own_key

    $board->own_key($seat)

A key over one seat's pieces alone, sixteen hex digits: where they stand, and
nothing of anyone else's.

=head2 random_forward

    my $r = $board->random_forward($seed);

The weakest player: a seeded random choice among the moves that take a piece
nearer home, or among all of them when none does.

=head1 THE STAR

These are the same for every board, and may be called on the class.

=head2 holes

121.

=head2 xy

    my ($x, $y, $z) = Game::Sternhalma::Engine->xy($hole);

A hole's cube coordinates.

=head2 hole_at

    Game::Sternhalma::Engine->hole_at($x, $y)

The hole at those coordinates, or C<undef>.

=head2 row_of

The row of a hole, 0 at the top to 16 at the bottom.

=head2 col_of

Where a hole is in its row, from 0 at the left.

=head2 row_len

How many holes a row has.

=head2 row_start

The first hole of a row.

=head2 next_to

    Game::Sternhalma::Engine->next_to($hole, $dir)

The neighbour of a hole in a direction, or C<undef>.

=head2 neighbours

Every neighbour of a hole.

=head2 degree

How many neighbours a hole has: 6, 5, 4, or 2 at a tip.

=head2 dir_opposite

The opposite of a direction.

=head2 point_of

The point a hole belongs to, 0 to 5, or C<CENTRE>.

=head2 on_ring

True for the 24 holes round the edge of the hexagon.

=head2 class_of

A hole's hop class, 0 to 3. A move of two holes in a line stays in its class.

=head2 point_holes

    my @holes = Game::Sternhalma::Engine->point_holes($point);

The ten holes of a point, in hole order.

=head2 front

The five ring holes in front of a point, which a fifteen-piece start also
fills.

=head2 pairs

Every pair of neighbouring holes once, as array references, the lower hole
first. There are 312.

=head2 layout_ok

    Game::Sternhalma::Engine->layout_ok($seats, $pieces)

True when the engine builds that many seats with that many pieces.

=head2 layout_point

    Game::Sternhalma::Engine->layout_point($seats, $seat)

The point a seat starts in, for that many seats.

=head2 zobrist

=head2 zobrist_move

=head2 zobrist_seats

The numbers the key is made of, as hex: one for each seat's piece in each
hole, one for each seat to move, and one for each seat count.

=head1 FOR TESTS

=head2 abi_version

The version of the board's C interface.

=head2 tables_ok

True when the star was built and every count agreed with what it should be.

=head2 live

How many boards exist and have not been let go.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
