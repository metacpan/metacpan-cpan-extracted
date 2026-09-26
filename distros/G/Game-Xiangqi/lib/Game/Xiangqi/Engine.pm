package Game::Xiangqi::Engine;

use 5.010;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Game::Xiangqi', $VERSION);

use constant {
    EMPTY    => 0,
    GENERAL  => 1,
    ADVISOR  => 2,
    ELEPHANT => 3,
    CHARIOT  => 4,
    HORSE    => 5,
    CANNON   => 6,
    SOLDIER  => 7,
    RED      => 8,
    BLACK    => 16,
    BORDER   => 32,

    FILES    => 9,
    RANKS    => 10,
    POINTS   => 90,
};

use constant {
    FEN_OK     => 0,
    FEN_NULL   => 1,
    FEN_ROWS   => 2,
    FEN_WIDTH  => 3,
    FEN_LETTER => 4,
    FEN_SIDE   => 5,
    FEN_LONG   => 6,

    ONGOING       => 0,
    BY_CHECKMATE  => 1,
    BY_STALEMATE  => 2,

    J_ONGOING         => 0,
    J_PERPETUAL_CHECK => 1,
    J_PERPETUAL_CHASE => 2,
    J_MUTUAL          => 3,
    J_NO_VIOLATION    => 4,
    J_EFFECTIVE       => 5,
    J_PROGRESS        => 6,
    J_MOVES           => 7,

    BEH_NONE      => 0,
    BEH_CHECK     => 1,
    BEH_CHASE     => 2,
    BEH_TTC       => 3,
    BEH_BLOCK     => 4,
    BEH_EXCHANGE  => 5,
    BEH_SACRIFICE => 6,
    BEH_IDLE      => 7,
};

our @EXPORT_OK = qw(
    EMPTY GENERAL ADVISOR ELEPHANT CHARIOT HORSE CANNON SOLDIER
    RED BLACK BORDER FILES RANKS POINTS
    FEN_OK FEN_NULL FEN_ROWS FEN_WIDTH FEN_LETTER FEN_SIDE FEN_LONG
    ONGOING BY_CHECKMATE BY_STALEMATE
    J_ONGOING J_PERPETUAL_CHECK J_PERPETUAL_CHASE J_MUTUAL J_NO_VIOLATION
    J_EFFECTIVE J_PROGRESS J_MOVES
    BEH_NONE BEH_CHECK BEH_CHASE BEH_TTC BEH_BLOCK BEH_EXCHANGE BEH_SACRIFICE BEH_IDLE
    kind_of colour_of other
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub kind_of   { $_[0] & 7 }
sub colour_of { $_[0] & (RED | BLACK) }
sub other     { $_[0] == RED ? BLACK : RED }

has _ptr => (is => 'rw', private => 1);

has _empty => (is => 'ro', init_arg => 'empty', private => 1, default => 0);

has _fen => (is => 'ro', init_arg => 'fen', private => 1);

sub BUILD {
    my ($self) = @_;
    return if $self->_ptr;

    my $fen = $self->_fen;
    if (defined $fen) {
        my ($ptr, $err) = _of_fen($fen);
        Carp::croak("Game::Xiangqi::Engine: the FEN was refused, code $err")
            unless defined $ptr;
        $self->_ptr($ptr);
        return;
    }

    $self->_ptr($self->_empty ? _new_empty() : _new_board());
    return;
}

sub of_fen {
    my ($class, $fen) = @_;
    my ($ptr, $err) = _of_fen(defined $fen ? $fen : '');
    return (undef, $err) unless defined $ptr;
    return ($class->new(_ptr => $ptr), FEN_OK);
}

sub clone {
    my ($self) = @_;
    return ref($self)->new(_ptr => _copy_board($self->_ptr));
}

sub DEMOLISH {
    my ($self) = @_;
    my $ptr = $self->_ptr;
    return unless $ptr;
    _drop_board($ptr);
    $self->_ptr(0);
    return;
}

sub at        { _at($_[0]->_ptr, $_[1]) }
sub put       { _put($_[0]->_ptr, $_[1], $_[2]); return $_[0] }
sub lift      { _lift($_[0]->_ptr, $_[1]); return $_[0] }
sub side      { _side($_[0]->_ptr) }
sub set_side  { _set_side($_[0]->_ptr, $_[1]); return $_[0] }
sub count     { _count($_[0]->_ptr, $_[1]) }
sub find      { _find($_[0]->_ptr, $_[1]) }
sub to_fen    { _to_fen($_[0]->_ptr) }
sub key_hex   { _key_hex($_[0]->_ptr) }

sub move      { _move_make($_[1], $_[2]) }
sub move_from { _move_from($_[1]) }
sub move_to   { _move_to($_[1]) }

sub play {
    my ($self, $iccs) = @_;
    require Game::Xiangqi::Notation;
    my $mv = Game::Xiangqi::Notation->move_of_iccs($iccs);
    return 'bad_move' unless defined $mv;
    return 'not_legal' unless grep { $_ == $mv } $self->legal;
    my (undef, $undo) = $self->do_move($mv);
    return 0;
}

sub do_move   { _do_move($_[0]->_ptr, $_[1]) }
sub undo_move { _undo_move($_[0]->_ptr, $_[1]); return $_[0] }

sub point_of      { my $c = shift; _point_of($_[0], $_[1]) }
sub file_of       { my $c = shift; _file_of($_[0]) }
sub rank_of       { my $c = shift; _rank_of($_[0]) }
sub on_board      { my $c = shift; _on_board($_[0]) }
sub in_palace     { my $c = shift; _in_palace($_[0], $_[1]) }
sub crossed_river { my $c = shift; _crossed_river($_[0], $_[1]) }
sub stride        { _stride() }

sub zobrist_hex   { my $c = shift; _zobrist_hex($_[0], $_[1]) }
sub abi_version   { _abi_version() }

sub moves {
    my @m = _gen_moves($_[0]->_ptr);
    return wantarray ? @m : scalar @m;
}

sub legal {
    my @m = _gen_legal($_[0]->_ptr);
    return wantarray ? @m : scalar @m;
}
sub attacked  { _attacked($_[0]->_ptr, $_[1], $_[2]) }
sub in_check  { _in_check($_[0]->_ptr, $_[1]) }
sub generals_face { _generals_face($_[0]->_ptr) }

sub horse_leg      { _horse_leg($_[0]->_ptr, $_[1], $_[2]) }
sub elephant_eye   { _elephant_eye($_[0]->_ptr, $_[1], $_[2]) }
sub cannon_screens { _cannon_screens($_[0]->_ptr, $_[1], $_[2]) }
sub soldier_may    { _soldier_may($_[0]->_ptr, $_[1], $_[2]) }

sub perft { _perft($_[0]->_ptr, $_[1]) }

sub outcome { _outcome($_[0]->_ptr) }

sub winner  { (_outcome($_[0]->_ptr))[0] }
sub reason  { (_outcome($_[0]->_ptr))[1] }
sub is_over { (_outcome($_[0]->_ptr))[0] != 0 }

sub mate_in { _mate_in($_[0]->_ptr, $_[1]) }

sub is_check     { _is_check($_[0]->_ptr, $_[1]) }
sub is_mate      { _is_mate($_[0]->_ptr, $_[1]) }
sub is_ttc       { _is_ttc($_[0]->_ptr, $_[1]) }
sub is_exchange  { _is_exchange($_[0]->_ptr, $_[1]) }
sub is_block     { _is_block($_[0]->_ptr, $_[1]) }
sub is_sacrifice { _is_sacrifice($_[0]->_ptr, $_[1]) }
sub is_idle      { _is_idle($_[0]->_ptr, $_[1]) }

sub is_chase {
    my @r = _is_chase($_[0]->_ptr, $_[1]);
    return wantarray ? @r : $r[0];
}

sub protected_at {
    my @r = _protected_at($_[0]->_ptr, $_[1]);
    return wantarray ? @r : $r[0];
}

sub value_of { my $c = shift; _value_of($_[0]) }

sub evaluate { _evaluate($_[0]->_ptr) }

sub search {
    my ($self, $budget, $seed) = @_;
    my @r = _search($self->_ptr, $budget || 1, $seed || 0);
    return wantarray ? @r : $r[0];
}

sub search_to_depth {
    my ($self, $max_depth, $budget, $seed) = @_;
    my @r = _search_to_depth($self->_ptr, $max_depth || 1, $budget || 1, $seed || 0);
    return wantarray ? @r : $r[0];
}

sub judge {
    my ($self, $moves) = @_;
    return { _judge($self->_ptr, $moves) };
}

sub rule_count { _rule_count() }
sub rule_at {
    my $c = shift;
    my @r = _rule_at($_[0]);
    return unless @r;
    my %h;
    @h{qw(number chaser victim protectedness chasers victims verdict text)} = @r;
    return \%h;
}

sub rules_implemented {
    my ($class) = @_;
    my %n;
    for my $i (0 .. _rule_count() - 1) {
        my $r = $class->rule_at($i);
        $n{ $r->{number} } = 1;
    }
    return sort { $a <=> $b } keys %n;
}

sub perft_divide {
    my ($self, $depth) = @_;
    my %out;
    return %out if $depth < 1;
    for my $mv ($self->legal) {
        my (undef, $u) = $self->do_move($mv);
        $out{$mv} = $depth == 1 ? 1 : ($self->perft($depth - 1))[0];
        $self->undo_move($u);
    }
    return %out;
}

sub all_points {
    my @p;
    for my $r (0 .. RANKS - 1) {
        for my $f (0 .. FILES - 1) {
            push @p, _point_of($f, $r);
        }
    }
    return @p;
}

1;

__END__

=head1 NAME

Game::Xiangqi::Engine - the xiangqi board, in C, with nothing that judges a move

=head1 SYNOPSIS

    use Game::Xiangqi::Engine ':all';

    my $b = Game::Xiangqi::Engine->new;              # the opening position
    my $e = Game::Xiangqi::Engine->new(empty => 1);
    my ($p, $err) = Game::Xiangqi::Engine->of_fen($fen);

    my $pt = Game::Xiangqi::Engine->point_of(4, 0);  # file e, rank 0
    $b->at($pt) == (RED | GENERAL);

    my $mv = Game::Xiangqi::Engine->move($from, $to);
    my ($captured, $undo) = $b->do_move($mv);
    $b->undo_move($undo);

=head1 DESCRIPTION

The board and nothing else. C<put>, C<lift> and C<do_move> are B<structure
primitives and judge nothing>: a caller may stack three generals on one point or
leave a side without one. Legality, check and mate arrive in later phases and
append to the C ABI rather than changing it.

=head2 A point is an opaque padded index

The board is 11 by 12 cells with a sentinel ring, so a neighbour walk needs no
bounds test. B<A point is not C<< rank * 9 + file >>> and nothing outside this
module may assume it is: build one with C<point_of> and take it apart with
C<file_of> and C<rank_of>.

Rank 0 is Red's back rank, which is ICCS's numbering and therefore the move
log's. A FEN's first row is rank 9.

=head2 The key is a hex string, never a number

C<key_hex> returns sixteen hex characters. On a perl with 32-bit IVs a UV cannot
hold a 64-bit key and the top half would vanish silently, which means a test
that passes while comparing half a number.

=head2 Every board is its own board

A board is a C allocation held in a B<private> attribute and dropped by C<DEMOLISH>
when the object goes. Nothing outside this module can read the pointer, let alone
overwrite it. C<clone> allocates a new board, so B<two Perl objects never share
one> and a move on either is invisible to the other.

C<< new(fen => ... ) >> B<croaks> on a FEN it will not take, because a FEN that
does not parse is a bug in the caller. C<of_fen> is the route for a FEN that came
from outside: it returns the board and the refusal code, or C<undef> and the code,
and never dies. That is what C<bin/xiangqi> and the UCCI mode use.

C<do_move> hands back the captured piece and an opaque undo token for
C<undo_move>. The token is a string of bytes rather than a pointer, so a caller
who never undoes leaks nothing.

=head2 A list in list context, a count in scalar context

C<moves> and C<legal> return the moves in list context and B<how many there are>
in scalar context. C<is_chase>, C<protected_at>, C<search> and C<search_to_depth>
return their first value in scalar context.

That is a guard rather than a convenience. The XSUBs underneath push their
results onto the stack, and such an XSUB in scalar context returns B<the last
value pushed>: without these wrappers C<scalar $b-E<gt>legal> would be a packed
move integer where a count was asked for, and C<scalar $b-E<gt>search(...)> would
be C<stopped>, a 0 or a 1 that looks like a move number. Both look like answers.
C<scalar($b-E<gt>legal)> read 16437 from the opening position, where the count is
44.

=head2 Nothing about a position is a draw

C<outcome> returns C<(winner, reason)>, and a side with B<no legal move loses>
whether it is in check or not. There is deliberately no draw value: every draw
this game has is a property of a sequence, so it comes from C<judge> and can
never come from a position.

C<mate_in> answers about B<checkmate specifically>, because its caller is the
Asian Rules' "threatening to checkmate". A forced stalemate is also a win here and
C<mate_in> says nothing about one; a search wanting terminal values uses
C<outcome>.

=head2 perft counts are strings, and mates are counted a ply early

C<perft> returns C<(nodes, checks, captures, mates)>, each as a decimal string,
because depth 6 is 5,392,831,844 and a 32-bit IV would quietly keep the low half
of it.

A mate is counted B<at the node whose side to move is mated>, one ply earlier
than the move that delivered it. That is the published table's convention, and
reading it the other way disagrees with every ladder there is to check against.

=head2 The vocabulary rules on nothing

C<is_check>, C<is_mate>, C<is_ttc>, C<is_exchange>, C<is_block>, C<is_sacrifice>,
C<is_idle>, C<is_chase> and C<protected_at> are the words the Asian Rules' Section
1 defines, each taking a move against the position as it stands. B<None of them
decides anything>: they exist so that the repetition rules can be a table of
sentences over predicates instead of forty hand-rolled position tests, and
C<judge> is what rules.

C<protected_at> returns C<(protected, real)>, and the second value is the source's
own distinction: rule 34 turns on nothing else, because a protector that cannot
actually recapture is a B<false> protector. C<value_of> is in centi-soldiers and
is declared in the C so that C<is_exchange> and the evaluation cannot drift apart.

=head2 The search is bounded in nodes and never in seconds

    my ($mv, $nodes, $depth, $score, $stopped) = $b->search($budget, $seed);

C<$budget> is a node count. It is not a number of seconds and there is no way to
ask for one, because the site plays its bot inside the move transaction: a search
bounded by time would make the same position answer differently on a loaded
machine than on an idle one, and a bot game would stop replaying. Nothing here
sets an alarm or handles a signal.

Spent through iterative deepening, so a budget that runs out always leaves a
B<complete> search one ply shallower rather than half of a deeper one. C<$nodes>
comes back as a string, because it is a 64-bit count. C<$depth> is the last
depth completed. C<$stopped> says the budget ran out, which is the normal case
and not an error.

C<$seed> separates root moves that score exactly the same, and the caller must
mix the B<seat> into it. L<Game::Xiangqi::Bot> does; anything else that calls
C<search> directly for two sides of one game and forgets will find both sides
playing the same opening every time.

=head2 A depth, when a budget will not do

    my ($mv, $nodes, $depth) = $b->search_to_depth(4, 2_000_000, $seed);

The same search, stopped after that many plies rather than after that many nodes.
It exists for UCCI's C<go depth>, which is how an external engine becomes an
oracle: two engines can only be compared at B<equal depth>, and a node budget
cannot promise one. C<search> is this function at its depth ceiling, so there is
one search and not two.

The budget is still required and a generous one is the caller's job, because
quiescence is bounded by the budget and by nothing else.

=head2 The evaluation is four terms, in centi-soldiers

C<evaluate> answers from the point of view of B<the side to move>, positive for
good, with a soldier worth 100 so nothing needs a float.

B<Material alone plays a bad opening in this game>, which is the mistake to know
about before reading the other three terms: a cannon's value is positional from
the first move, and a horse with its legs blocked is not worth what the table
says it is.

=head3 Material

    chariot   900
    cannon    450
    horse     400
    advisor   200
    elephant  200
    soldier   100, and 200 once it has crossed the river

Flat, and a phase-tapered table is the obvious later improvement: a cannon is
stronger early, while screens are plentiful and horses are still blocked, and a
horse is stronger late.

=head3 Mobility

The difference in the number of moves available, which does more work in xiangqi
than the same term does in chess. A horse hobbled at three of its four legs is
close to worthless and the material term cannot see that at all.

=head3 The general's safety

The palace's own term: the advisors and elephants still at home, and a penalty
for the general's own file standing open. B<The open file is the one that
matters>, because of the flying general: an open file between the two of them is
not a weakness, it is a move.

=head3 Soldier advance

The march by rank, counted only B<beyond> the river, because the crossing itself
is already paid for in the material term and counting it twice would send every
soldier forward at once.

=head1 SEE ALSO

C<include/xq_abi.h>, which is the contract this module is a thin Perl skin over.

=cut
