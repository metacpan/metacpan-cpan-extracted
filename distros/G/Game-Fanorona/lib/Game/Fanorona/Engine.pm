package Game::Fanorona::Engine;

use 5.014;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;

use Game::Fanorona::Move ();

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Game::Fanorona', $VERSION);

use constant {
    EMPTY  => 0,
    WHITE  => 1,
    BLACK  => 2,
    BORDER => 3,
};

use constant {
    N  => 0,
    NE => 1,
    E  => 2,
    SE => 3,
    S  => 4,
    SW => 5,
    W  => 6,
    NW => 7,
};

use constant {
    POS_OK     => 0,
    POS_NULL   => 1,
    POS_LONG   => 2,
    POS_LETTER => 3,
    POS_ROWS   => 4,
    POS_WIDTH  => 5,
    POS_SIDE   => 6,
};

use constant {
    PAIKA      => 0,
    APPROACH   => 1,
    WITHDRAWAL => 2,
};

use constant {
    WHY_OK            => 0,
    WHY_OFF_BOARD     => 1,
    WHY_BAD_STEP      => 2,
    WHY_NO_STONE      => 3,
    WHY_NOT_YOURS     => 4,
    WHY_NO_LINE       => 5,
    WHY_OCCUPIED      => 6,
    WHY_TAKES_NOTHING => 7,
    WHY_NOT_A_PAIKA   => 8,
    WHY_MUST_CAPTURE  => 9,
    WHY_NOT_THE_STONE  => 10,
    WHY_SAME_DIRECTION => 11,
    WHY_REVISIT        => 12,
    WHY_PAIKA_IN_CHAIN => 13,
};

our @EXPORT_OK = qw(
    EMPTY WHITE BLACK BORDER
    N NE E SE S SW W NW
    POS_OK POS_NULL POS_LONG POS_LETTER POS_ROWS POS_WIDTH POS_SIDE
    PAIKA APPROACH WITHDRAWAL
    WHY_OK WHY_OFF_BOARD WHY_BAD_STEP WHY_NO_STONE WHY_NOT_YOURS WHY_NO_LINE
    WHY_OCCUPIED WHY_TAKES_NOTHING WHY_NOT_A_PAIKA WHY_MUST_CAPTURE
    WHY_NOT_THE_STONE WHY_SAME_DIRECTION WHY_REVISIT WHY_PAIKA_IN_CHAIN
    other
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub other { $_[0] == WHITE ? BLACK : WHITE }

my %SIZE = (
    sivy => [ 9, 5 ],
    dimy => [ 5, 5 ],
    telo => [ 3, 3 ],
);

has _ptr => (is => 'rw', private => 1);

has _hold => (is => 'rw', private => 1);

has _want_empty => (is => 'ro', init_arg => 'empty', private => 1, default => 0);

has _want_position => (is => 'ro', init_arg => 'position', private => 1);

has _want_board => (is => 'ro', init_arg => 'board', private => 1);

has _want_cols => (is => 'ro', init_arg => 'cols', private => 1);

has _want_rows => (is => 'ro', init_arg => 'rows', private => 1);

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
        Carp::croak("Game::Fanorona::Engine: a board is made by new, of_string or clone");
    }

    my $position = $self->_want_position;
    if (defined $position) {
        my ($ptr, $err) = _of_string($position);
        Carp::croak("Game::Fanorona::Engine: the position was refused, code $err")
            unless defined $ptr;
        $self->_ptr($ptr);
        $self->_hold(_hold_board($ptr));
        return;
    }

    my ($cols, $rows) = ($self->_want_cols, $self->_want_rows);
    my $name = $self->_want_board;
    if (defined $name) {
        Carp::croak("Game::Fanorona::Engine: give a board by name or by cols and rows, not both")
            if defined $cols || defined $rows;
        my $size = $SIZE{$name}
            or Carp::croak("Game::Fanorona::Engine: no board is called '$name'");
        ($cols, $rows) = @$size;
    }
    elsif (defined $cols || defined $rows) {
        Carp::croak("Game::Fanorona::Engine: a size is both cols and rows")
            unless defined $cols && defined $rows;
    }
    else {
        ($cols, $rows) = @{ $SIZE{sivy} };
    }
    Carp::croak("Game::Fanorona::Engine: no board is $cols by $rows")
        unless $cols =~ /\A[0-9]+\z/ && $rows =~ /\A[0-9]+\z/ && _size_ok($cols, $rows);

    $self->_ptr($self->_want_empty ? _new_empty($cols, $rows) : _new_board($cols, $rows));
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

sub at           { _at($_[0]->_ptr, $_[1]) }
sub put          { _put($_[0]->_ptr, $_[1], $_[2]); return $_[0] }
sub lift         { _lift($_[0]->_ptr, $_[1]); return $_[0] }
sub side         { _side($_[0]->_ptr) }
sub set_side     { _set_side($_[0]->_ptr, $_[1]); return $_[0] }
sub count        { _count($_[0]->_ptr, $_[1]) }
sub to_string    { _to_string($_[0]->_ptr) }
sub key_hex      { _key_hex($_[0]->_ptr) }
sub key_full_hex { _key_full_hex($_[0]->_ptr) }

sub cols     { _board_cols($_[0]->_ptr) }
sub rows     { _board_rows($_[0]->_ptr) }
sub points   { _board_points($_[0]->_ptr) }
sub centre   { _board_centre($_[0]->_ptr) }
sub on_board { _on_board($_[0]->_ptr, $_[1]) }
sub next_to  { _next($_[0]->_ptr, $_[1], $_[2]) }
sub degree   { _degree($_[0]->_ptr, $_[1]) }

sub neighbours {
    my ($self, $sq) = @_;
    my $ptr = $self->_ptr;
    return grep { $_ >= 0 } map { _next($ptr, $sq, $_) } N .. NW;
}

sub segments {
    my ($self) = @_;
    my @flat = _segments($self->_ptr);
    my @pairs;
    push @pairs, [ splice @flat, 0, 2 ] while @flat;
    return @pairs;
}

sub all_squares {
    my ($self) = @_;
    my ($cols, $rows) = ($self->cols, $self->rows);
    my @squares;
    for my $rank (0 .. $rows - 1) {
        push @squares, map { _square_of($_, $rank) } 0 .. $cols - 1;
    }
    return @squares;
}

sub square_of   { my $c = shift; _square_of($_[0], $_[1]) }
sub file_of     { my $c = shift; _file_of($_[0]) }
sub rank_of     { my $c = shift; _rank_of($_[0]) }
sub is_strong   { my $c = shift; _is_strong($_[0]) }
sub opposite    { my $c = shift; _dir_opposite($_[0]) }
sub is_diagonal { my $c = shift; _dir_is_diagonal($_[0]) }
sub size_ok     { my $c = shift; _size_ok($_[0], $_[1]) }
sub stride      { _stride() }

sub size_of {
    my ($class, $name) = @_;
    my $size = defined $name ? $SIZE{$name} : undef;
    return $size ? @$size : ();
}

sub zobrist_hex      { my $c = shift; _zobrist_hex($_[0], $_[1]) }
sub zobrist_side_hex { _zobrist_side_hex() }
sub zobrist_size_hex { my $c = shift; _zobrist_size_hex($_[0], $_[1]) }
sub abi_version      { _abi_version() }
sub live             { _live() }

my $step = sub {
    my ($raw) = @_;
    my ($from, $to, $dir, $kind, @taken) = @$raw;
    return { from => $from, to => $to, dir => $dir, kind => $kind, taken => \@taken };
};

my $triple = sub {
    return @{ $_[0] }{qw(from dir kind)} if ref $_[0] eq 'HASH';
    return @_[0 .. 2];
};

sub steps {
    my ($self) = @_;
    my @raw = _gen_steps($self->_ptr);
    return wantarray ? map { $step->($_) } @raw : scalar @raw;
}

sub steps_of {
    my ($self, $sq) = @_;
    return map { $step->($_) } _steps_of($self->_ptr, $sq);
}

sub can_capture {
    my ($self, $side) = @_;
    return _can_capture($self->_ptr, defined $side ? $side : _side($self->_ptr));
}

sub step_why {
    my $self = shift;
    return _step_why($self->_ptr, $triple->(@_));
}

sub step {
    my $self = shift;
    my ($raw) = _step_build($self->_ptr, $triple->(@_));
    return $raw ? $step->($raw) : undef;
}

sub do_step {
    my $self = shift;
    my ($removed, $token) = _do_step($self->_ptr, $triple->(@_));
    return unless defined $token;
    return wantarray ? ($token, $removed) : $token;
}

sub undo_step { _undo_step($_[0]->_ptr, $_[1]); return $_[0] }

sub perft_steps { _perft_steps($_[0]->_ptr, $_[1]) }

sub steps_max { _steps_max() }
sub line_max  { _line_max() }
sub chain_max { _chain_max() }

sub in_chain  { _chain_at($_[0]->_ptr) >= 0 ? 1 : 0 }
sub chain_at  { _chain_at($_[0]->_ptr) }
sub chain_dir { _chain_dir($_[0]->_ptr) }

sub chain_seen {
    my ($self) = @_;
    my $ptr = $self->_ptr;
    return grep { _chain_seen($ptr, $_) } $self->all_squares;
}

sub play_steps {
    my ($self) = @_;
    my @raw = _play_steps($self->_ptr);
    return wantarray ? map { $step->($_) } @raw : scalar @raw;
}

sub can_stop { _can_stop($_[0]->_ptr) }

sub play_why {
    my $self = shift;
    return _play_why($self->_ptr, $triple->(@_));
}

sub play {
    my $self = shift;
    my ($removed, $token) = _play_step($self->_ptr, $triple->(@_));
    return unless defined $token;
    return wantarray ? ($token, $removed) : $token;
}

sub stop {
    my ($self) = @_;
    my ($token) = _play_stop($self->_ptr);
    return $token;
}

sub unplay { _play_undo($_[0]->_ptr, $_[1]); return $_[0] }

sub count_moves {
    my ($self, $cap) = @_;
    return _count_moves($self->_ptr, defined $cap ? $cap : 0);
}

sub moves {
    my ($self, $limit) = @_;
    my @raw = _gen_moves($self->_ptr, defined $limit ? $limit : 100_000);
    return map {
        my @steps = map { $step->($_) } @$_;
        Game::Fanorona::Move->new(from => $steps[0]{from}, steps => \@steps);
    } @raw;
}

sub play_move {
    my ($self, $move) = @_;
    return if $self->in_chain;
    my @tokens;
    for my $s (@{ $move->steps }) {
        my $ok = $self->play_why($s) == WHY_OK;
        my $token = $ok ? $self->play($s) : undef;
        if (!defined $token) {
            $self->unplay($_) for reverse @tokens;
            return;
        }
        push @tokens, $token;
    }
    return unless @tokens;
    push @tokens, $self->stop if $self->in_chain;
    return \@tokens;
}

sub unplay_move {
    my ($self, $tokens) = @_;
    $self->unplay($_) for reverse @$tokens;
    return $self;
}

sub perft_moves { _perft_moves($_[0]->_ptr, $_[1]) }

1;

__END__

=head1 NAME

Game::Fanorona::Engine - the fanorona board: points, lines, stones, steps and whole moves

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Fanorona::Engine ':all';

    my $board = Game::Fanorona::Engine->new;
    print $board->to_string, "\n";
    # bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w

    my $e3 = Game::Fanorona::Engine->square_of(4, 2);
    print "the centre is empty\n" if $board->at($e3) == EMPTY;
    print "and eight lines meet there\n" if $board->degree($e3) == 8;

    my ($other, $err) = Game::Fanorona::Engine->of_string('bbb/w1b/www w');

=head1 DESCRIPTION

A position: the points of a board, what stands on each, and whose move it is;
and the lines that join one point to the next.

C<put> and C<lift> B<judge nothing>: C<put> will fill the board with white
stones if asked. C<steps> and C<step_why> are where the rules of a step live.

A B<step> is one stone going to one adjacent point. A B<move> is everything
one side does before the other plays: a single step that takes nothing, or a
chain of steps by one stone, each of which takes. C<play>, C<stop> and
C<moves> are the game's; C<do_step> and C<steps> are the single step on its
own, which always passes the turn, and are kept beside them for checking one
against the other.

B<Nothing here knows how a game ends.>

=head2 The board

The game is played on forty-five points, nine files by five ranks. Files are
0 to 8 for a to i and ranks 0 to 4 for 1 to 5, White on the two lower ranks.

Every point is joined to the points beside it along its rank and its file.
Half the points are also joined diagonally. Those are the B<strong> points,
the ones whose file and rank add to an even number; the rest are B<weak>.
The corner a1 is strong and so is the centre.

A diagonal always runs from a strong point to a strong point.

=head2 Other sizes

C<new> also builds any board of odd width 3 to 9 and of height 3 or 5. Three
have names: C<sivy> is the nine by five, C<dimy> the five by five and C<telo>
the three by three.

On every size the two lower ranks (one, on a board three high) are White's,
the upper ones Black's, and the centre is empty. The middle rank alternates
outward from the centre, with a white stone directly left of it and a black
stone directly right. For the nine by five that is the traditional set-up.
B<For the smaller boards it is this distribution's reading of the same
pattern>, not a set-up taken from a source.

=head2 A point is an opaque number

A point is a number handed out by C<square_of> and taken apart by C<file_of>
and C<rank_of>. It is B<not> C<rank * 9 + file>, and it is the same number on
every size of board: a1 on the three by three is a1 on the nine by five.
Ask C<on_board> whether a point belongs to a particular board, and C<next_to>
for the point one step along a line.

=head2 A direction

Eight of them, numbered clockwise from north and exported as C<N>, C<NE>,
C<E>, C<SE>, C<S>, C<SW>, C<W> and C<NW>. North is towards Black's side.

=head2 The key is a hex string, never a number

C<key_hex> is sixteen lowercase hexadecimal characters. It is a string on every
perl, because a perl built with 32-bit integers cannot hold the number it
stands for.

Two positions on the same size of board with the same stones on the same
points and the same side to move have the same key, in every process, on
every machine. The same stones on two different sizes of board do not.

=head2 A step

A stone steps along a line to the next point, which must be empty. A step that
takes nothing is a B<paika>.

A step takes by B<approach> when the point beyond the one it moves to, further
along the same line, holds an enemy stone; and by B<withdrawal> when the point
behind the one it leaves does. Either way that stone goes, and with it every
enemy stone in an unbroken line behind it, up to the first empty point, the
first stone of the mover's own, or the edge of the board. Only stones on the
line of the step are taken.

When a step could take both ways it takes one, and the other line stands. It
is listed twice, once as each.

B<Taking is compulsory.> If any stone of the side to move can take, none of
its stones may make a paika. Which capture to make is the mover's choice: a
larger one has no priority over a smaller.

B<A step that could take, takes.> There is no moving to a point and declining
the capture there, so a step is a paika only when it takes nothing either way.
The sources this distribution follows say that capture is obligatory and do
not spell this case out; it is the distribution's reading.

A step is a hash reference:

    {
        from  => $sq,
        to    => $sq,
        dir   => NE,
        kind  => APPROACH,            # or WITHDRAWAL, or PAIKA
        taken => [ $sq, $sq ],        # nearest first; empty for a paika
    }

and wherever a method takes a step it takes either that hash or the three
values C<$from, $dir, $kind>.

=head2 A whole move, and the chain

A stone that has taken may step again in the same move, and again, so long as
every step takes. This is a B<chain>. Three things limit it:

=over 4

=item *

It is the same stone throughout.

=item *

It may not step in the direction of the step directly before. The rule looks
back one step only: north, east, north is allowed.

=item *

It may not arrive on a point it has already stood on in this chain, and the
point it started from counts.

=back

B<The mover may stop after any step of a chain.> Taking is compulsory to
begin with, and going on is not. So where a stone could take three times
running there are three moves: take once, take twice, take three times.

B<Nothing of a chain carries into the next move.> A stone may begin its next
move in the direction its last one ended in.

While a chain is in progress the board remembers it: C<in_chain>, C<chain_at>,
C<chain_dir> and C<chain_seen>. The turn stays with the mover until the chain
ends, which it does when C<stop> is called or, B<by itself>, when no step
could follow. So a board with a chain open always has a step to make.

A chain is not part of the position. The key and the position string describe
the stones and the side to move and nothing else; a string written in the
middle of a chain reads back with no chain open.

=head2 How many whole moves there can be

Usually about ten. But each beginning of each chain is a move, so a stone in
the middle of many enemies can have thousands: a position is known with four
white stones and 15,898 moves. C<moves> therefore takes a limit and croaks
past it, and C<count_moves> takes a cap. B<To offer a person a move, do not
list the moves>: offer C<play_steps>, the handful of steps that may come
next, and C<stop> where C<can_stop> says so.

=head2 The position string

    bbbbbbbbb/bbbbbbbbb/bwbw1bwbw/wwwwwwwww/wwwwwwwww w

Ranks from the top down, C<w> and C<b> for stones, a digit for a run of empty
points, C</> between ranks, a space, and the side to move. The size of the
board is read from the string.

A string is refused for its shape and never for its sense: a board of
forty-five white stones loads.

=head1 CONSTRUCTORS

=head2 new

    my $board = Game::Fanorona::Engine->new;                    # the game
    my $small = Game::Fanorona::Engine->new(board => 'telo');
    my $other = Game::Fanorona::Engine->new(cols => 5, rows => 3);
    my $bare  = Game::Fanorona::Engine->new(empty => 1);
    my $from  = Game::Fanorona::Engine->new(position => $string);

The set-up of a board, White to move. C<board> names a size, or C<cols> and
C<rows> give one. C<empty> leaves every point empty. C<position> loads a
position string and takes its size from it.

Croaks on a name that is not a board, a size that cannot be built, a name
given together with a size, or a position string that will not load.

=head2 of_string

    my ($board, $err) = Game::Fanorona::Engine->of_string($string);

A board from a position string, and C<POS_OK>; or C<undef> and the reason:

=over 4

=item C<POS_NULL>

No string, or an empty one.

=item C<POS_LONG>

Longer than any position string can be.

=item C<POS_LETTER>

A character in the board that is not C<w>, C<b>, C</> or a digit 1 to 9.

=item C<POS_ROWS>

Neither three ranks nor five.

=item C<POS_WIDTH>

Ranks of different widths, or a width that is not 3, 5, 7 or 9.

=item C<POS_SIDE>

The side to move is missing, is not C<w> or C<b>, or is followed by something.

=back

When a string has more than one fault, the first in that order is reported.

=head2 clone

A second board with the same stones, side and size, sharing nothing with the
first.

=head1 METHODS

=head2 at

    my $stone = $board->at($sq);

C<EMPTY>, C<WHITE> or C<BLACK>, and C<BORDER> for a number that is not a
point of this board.

=head2 put

    $board->put($sq, WHITE);

Places a stone, replacing whatever stood there. C<put($sq, EMPTY)> is
C<lift>. A point off the board, or anything that is not a stone, is ignored.
Returns the board.

=head2 lift

Empties a point. Returns the board.

=head2 side

The side to move: C<WHITE> or C<BLACK>.

=head2 set_side

    $board->set_side(BLACK);

Returns the board.

=head2 count

    my $n = $board->count(BLACK);

The stones of one colour on the board.

=head2 to_string

The position string.

=head2 key_hex

The key of the position, sixteen hex characters.

=head2 key_full_hex

The same key worked out again from the stones on the board. It always equals
C<key_hex>; it is here so that a test can hold the two together.

=head2 cols

=head2 rows

The size of this board.

=head2 points

How many points it has.

=head2 centre

The point in the middle.

=head2 on_board

    $board->on_board($sq)

True when the number is a point of this board.

=head2 next_to

    my $to = $board->next_to($sq, NE);

The point one step from C<$sq> in a direction, or -1 when no line of this
board goes that way from there: off the edge, or a diagonal asked of a weak
point.

=head2 neighbours

    my @points = $board->neighbours($sq);

Every point joined to C<$sq>, clockwise from north.

=head2 degree

How many lines meet at a point: three at a corner, eight at a strong point in
the open.

=head2 segments

    for my $pair ($board->segments) { my ($from, $to) = @$pair; ... }

Every joined pair of points, once each, the lower point first. The nine by
five has 108.

=head2 all_squares

The points of this board, a1 first, along each rank in turn.

=head2 steps

    my @steps = $board->steps;

The steps of the side to move, with the obligation applied: if any of them
takes, none of them is a paika. In point order, a1 first; for each stone
clockwise from north; an approach before a withdrawal. In scalar context,
how many there are.

A side with no stones has none.

=head2 steps_of

    my @steps = $board->steps_of($sq);

Every step the stone on a point could make, B<whoever is to move and with no
obligation applied>: its paikas are listed even when another stone could
take. Its enemy is the other colour from its own.

=head2 can_capture

    $board->can_capture          # the side to move
    $board->can_capture(BLACK)

True when some stone of a side has a step that takes.

=head2 step_why

    my $why = $board->step_why($from, $dir, $kind);

C<WHY_OK> when that is a step of the side to move, and otherwise the first of
these that applies:

=over 4

=item C<WHY_OFF_BOARD>

C<$from> is not a point of this board.

=item C<WHY_BAD_STEP>

Not a direction, or not a kind.

=item C<WHY_NO_STONE>

Nothing stands there.

=item C<WHY_NOT_YOURS>

The stone belongs to the side that is not to move.

=item C<WHY_NO_LINE>

No line goes that way from there: the edge, or a diagonal from a weak point.

=item C<WHY_OCCUPIED>

A stone stands where the step would go.

=item C<WHY_TAKES_NOTHING>

Asked to take by approach or by withdrawal, and no enemy stone is there.

=item C<WHY_NOT_A_PAIKA>

Asked as a paika, and the step takes.

=item C<WHY_MUST_CAPTURE>

A paika, while some stone of the mover's can take.

=back

C<step_why> answers C<WHY_OK> for exactly the steps C<steps> lists.

=head2 step

    my $step = $board->step($from, $dir, $kind);

The step as a hash, or C<undef> when there is none to build. B<This judges
only the geometry>: a stone on C<$from>, a line that way to an empty point,
and, for an approach or a withdrawal, an enemy line to take. It does not ask
whose turn it is or what else could take, and a C<PAIKA> is built with nothing
taken even where the step would take.

=head2 do_step

    my $token = $board->do_step($step);
    my ($token, $removed) = $board->do_step($from, $dir, $kind);

Moves the stone, removes what the step takes, and B<always> passes the turn:
this is the step on its own, and C<play> is the game's. Returns a
token for C<undo_step>, and in list context the number of stones removed as
well. B<It does not ask whether the step is legal>; ask C<step_why>. When
there is no such step to build it does nothing and returns nothing.

=head2 undo_step

    $board->undo_step($token);

Puts the position back exactly as it was before the step the token came from,
key included. Steps are undone in the reverse of the order they were made.
Returns the board. Croaks on something that is not a token.

=head2 perft_steps

    my $count = $board->perft_steps($depth);

How many sequences of C<$depth> single steps there are from here, B<each step
passing the turn>. A string of digits, because the number outgrows a small integer
within a few steps. From the set-up: 5, 17, 100, 647, 4404.

This is a check on the list of steps and not a count of games: in the game a
stone that has taken may step again, and C<perft_moves> counts that.

=head2 play_steps

    my @steps = $board->play_steps;

The steps the game allows next. With no chain open they are C<steps>. With
one open they are the steps of that stone alone that take, that do not go the
way it last went, and that do not arrive where it has stood. Stopping is not
in the list: ask C<can_stop>. In scalar context, how many there are.

=head2 can_stop

True while a chain is open: the mover may end the move here.

=head2 play_why

    my $why = $board->play_why($from, $dir, $kind);

C<step_why> for the game. With no chain open it is C<step_why>. With one open
it answers, in the order asked, C<WHY_OFF_BOARD>, C<WHY_BAD_STEP>,
C<WHY_NO_STONE>, C<WHY_NOT_YOURS>, then:

=over 4

=item C<WHY_NOT_THE_STONE>

A chain is open and this is another stone.

=back

then C<WHY_NO_LINE> and C<WHY_OCCUPIED>, then:

=over 4

=item C<WHY_SAME_DIRECTION>

The direction of the step directly before.

=item C<WHY_REVISIT>

A point the chain has already stood on.

=item C<WHY_PAIKA_IN_CHAIN>

A step that takes nothing, after one that took.

=back

and C<WHY_NOT_A_PAIKA> or C<WHY_TAKES_NOTHING> as C<step_why> would.
C<play_why> answers C<WHY_OK> for exactly the steps C<play_steps> lists.

=head2 play

    my $token = $board->play($step);
    my ($token, $removed) = $board->play($from, $dir, $kind);

The game's step. Moves the stone and removes what it takes. A step that took
nothing passes the turn. A step that took leaves the turn with the mover and
the chain open on that stone, unless nothing could follow, in which case the
chain is closed and the turn passed there and then.

B<It does not ask whether the step is legal>; ask C<play_why>. Returns a token
for C<unplay>, with the number of stones removed in list context, and nothing
when there is no such step to build.

=head2 stop

    my $token = $board->stop;

Ends the move: closes the chain and passes the turn. Returns a token for
C<unplay>, or C<undef> when no chain was open.

=head2 unplay

    $board->unplay($token);

Takes back one C<play> or one C<stop>, the chain included. Returns the board.

=head2 in_chain

True while a stone is in the middle of its move.

=head2 chain_at

The point of that stone, or -1.

=head2 chain_dir

The direction of its last step, or -1.

=head2 chain_seen

    my @points = $board->chain_seen;

Every point the chain has stood on, the start included; none when no chain is
open.

=head2 moves

    my @moves = $board->moves;
    my @moves = $board->moves($limit);

The whole moves of the side to move, as L<Game::Fanorona::Move> objects, each
chain's shorter beginnings before its longer ones. None while a chain is
open. B<Croaks when there are more than C<$limit>>, which is 100,000 unless
given, without listing any.

=head2 count_moves

    my $n = $board->count_moves;
    my $n = $board->count_moves($cap);

How many whole moves there are, as a string of digits. With a cap the count
stops there, for a caller who only wants to know whether there are too many.

=head2 play_move

    my $tokens = $board->play_move($move);

Plays a whole move: each of its steps, and then a stop if the chain is still
open, which it is whenever the move is the shorter beginning of a longer one.
Each step is asked of C<play_why> first, so a move that does not belong to
this position is not played: the board is left as it was and C<undef> is
returned. Returns an array reference of tokens for C<unplay_move>.

=head2 unplay_move

    $board->unplay_move($tokens);

Takes a whole move back. Returns the board.

=head2 perft_moves

    my $count = $board->perft_moves($depth);

How many sequences of C<$depth> whole moves there are from here, as a string
of digits. From the set-up: 5, 39, 724, 18026. A side with no move ends its
line: nothing here rules on how a game is won.

=head1 CLASS METHODS

=head2 chain_max

The most steps one move can have: 44. A chain never stands on a point twice,
and there are forty-five points.

=head2 steps_max

The most steps any position can have: 216. A step runs along a segment from
the end with a stone to the end without, there are 108 segments, and a step
is at most two entries.

=head2 line_max

The most stones one step can take: seven.

=head2 square_of

    my $sq = Game::Fanorona::Engine->square_of($file, $rank);

The point at a file and rank, or -1 outside the nine by five.

=head2 file_of

=head2 rank_of

The file and the rank of a point, or -1.

=head2 is_strong

True for a point with diagonal lines.

=head2 opposite

    Game::Fanorona::Engine->opposite(NE)    # SW

=head2 is_diagonal

True for C<NE>, C<SE>, C<SW> and C<NW>.

=head2 size_ok

    Game::Fanorona::Engine->size_ok($cols, $rows)

True for a size C<new> will build.

=head2 size_of

    my ($cols, $rows) = Game::Fanorona::Engine->size_of('dimy');

The size a name stands for, or an empty list.

=head2 stride

The difference between a point and the point one rank above it. The point one
file to the right is always one more.

=head2 zobrist_hex

    Game::Fanorona::Engine->zobrist_hex(WHITE, $sq)

What one stone on one point contributes to a key.

=head2 zobrist_side_hex

What Black to move contributes.

=head2 zobrist_size_hex

    Game::Fanorona::Engine->zobrist_size_hex($cols, $rows)

What the size of the board contributes.

=head2 abi_version

The version of the table of functions this distribution publishes to other
compiled code.

=head2 live

How many boards exist that have not been destroyed.

=head1 FUNCTIONS

=head2 other

    other(WHITE)    # BLACK

Exported on request, with the constants, by C<:all>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
