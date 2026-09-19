package Game::Go::Engine;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Game::Go', $VERSION);

use Game::Go::Rules;

sub new {
	my ($class, %o) = @_;
	my $size = defined $o{size} ? $o{size} : 19;
	die "Game::Go::Engine: size must be an integer from 2 to 19, not '$size'"
		unless $size =~ /\A[0-9]+\z/ && $size >= 2 && $size <= 19;

	my $self = bless { ptr => _new_board($size), size => $size }, $class;

	my $want = exists $o{history} ? $o{history} : 1;
	if ($want) {
		$self->{hist} = _new_hist($size);
		_hist_push($self->{hist}, $self->{ptr});
	}
	return $self;
}

sub clone {
	my ($self) = @_;
	my $new = bless { ptr => _copy_board($self->{ptr}), size => $self->{size} }, ref $self;
	$new->{hist} = _copy_hist($self->{hist}) if $self->{hist};
	return $new;
}

sub _hist { $_[0]{hist} || 0 }

sub size        { _size_of($_[0]{ptr}) }
sub stride      { _stride_of($_[0]{ptr}) }
sub point_of    { _point_of($_[0]{ptr}, $_[1], $_[2]) }
sub col_of      { _col_of($_[0]{ptr}, $_[1]) }
sub row_of      { _row_of($_[0]{ptr}, $_[1]) }

sub at          { _at($_[0]{ptr}, $_[1]) }
sub libs        { _libs($_[0]{ptr}, $_[1]) }
sub chain_size  { _chain_size($_[0]{ptr}, $_[1]) }
sub chain_at    { [ _chain_at($_[0]{ptr}, $_[1]) ] }
sub stones      { _stones($_[0]{ptr}, $_[1]) }
sub pack_position { _pack($_[0]{ptr}) }
sub hash_hex    { _hash_hex($_[0]{ptr}) }

sub put         { _put($_[0]{ptr}, $_[1], $_[2]); return $_[0] }
sub lift        { _lift($_[0]{ptr}, $_[1]) }

sub zobrist_hex { _zobrist_hex($_[1], $_[2]) }


sub legal       { _legal($_[0]{ptr}, $_[0]->_hist, $_[1], $_[2]) }
sub is_legal    { _legal($_[0]{ptr}, $_[0]->_hist, $_[1], $_[2]) == Game::Go::Rules::OK }
sub legal_moves { [ _legal_moves($_[0]{ptr}, $_[0]->_hist, $_[1]) ] }

sub play {
	my ($self, $pt, $colour) = @_;
	my ($code, $ko, @caps) = _play($self->{ptr}, $self->_hist, $pt, $colour);
	return {
		code     => $code,
		ok       => ($code == Game::Go::Rules::OK ? 1 : 0),
		ko_point => $ko,
		caps     => \@caps,
		($code == Game::Go::Rules::OK ? () : (message => Game::Go::Rules::refusal($code))),
	};
}

sub pass        { _pass($_[0]{ptr}, $_[1]); return $_[0] }
sub ko_point    { _ko_point($_[0]{ptr}) }
sub ko_colour   { _ko_colour($_[0]{ptr}) }

sub superko {
	my ($self, $on) = @_;
	_set_superko($self->{ptr}, $on ? 1 : 0) if defined $on;
	return _superko_on($self->{ptr});
}

sub has_history    { $_[0]{hist} ? 1 : 0 }

sub push_position  { $_[0]{hist} ? _hist_push($_[0]{hist}, $_[0]{ptr}) : 0 }

sub history_length { $_[0]{hist} ? _hist_len($_[0]{hist}) : 0 }
sub seen_position  { $_[0]{hist} ? _hist_has($_[0]{hist}, $_[0]{ptr}) : 0 }

sub hash_after_hex { _hash_after_hex($_[0]{ptr}, $_[1], $_[2]) }

sub alive { [ _alive($_[0]{ptr}, $_[1]) ] }

sub is_alive {
	my ($self, $pt) = @_;
	my $colour = $self->at($pt);
	return 0 unless Game::Go::Rules::is_colour($colour);
	my %alive = map { $_ => 1 } @{ $self->alive($colour) };
	return $alive{$pt} ? 1 : 0;
}

sub score {
	my ($self, %o) = @_;
	return { _score(
		$self->{ptr},
		$o{dead} || [],
		$o{seki} || [],
		$o{prisoners_b} || 0,
		$o{prisoners_w} || 0,
		defined $o{komi_tenths} ? $o{komi_tenths} : 0,
	) };
}

sub area_score { my ($self) = @_; return { _score_area($self->{ptr}) } }

sub territory_map {
	my ($self, %o) = @_;
	return { _territory($self->{ptr}, $o{dead} || [], $o{seki} || []) };
}


sub prng_next { _prng_next($_[-1]) }

sub playout {
	my ($self, %o) = @_;
	my ($diff, $moves) = _playout($self->{ptr}, $o{colour}, $o{seed} || 1);
	return { diff => $diff, moves => $moves, cap => 3 * $self->size * $self->size };
}

sub search {
	my ($self, %o) = @_;
	return { _search(
		$self->{ptr},
		$o{colour},
		$o{allowed} || [],
		$o{seed}     || 1,
		$o{playouts} || 100,
		defined $o{explore} ? $o{explore} : 700,
	) };
}

sub dead_guess {
	my ($self, %o) = @_;
	return [ _dead_guess($self->{ptr}, $o{seed} || 1, $o{playouts} || 50) ];
}

sub DESTROY {
	my ($self) = @_;
	_drop_board(delete $self->{ptr}) if $self->{ptr};
	_drop_hist(delete $self->{hist}) if $self->{hist};
	return;
}

1;

__END__

=encoding utf8

=head1 NAME

Game::Go::Engine - the door to the C board

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    my $board = Game::Go::Engine->new(size => 9);

    my $pt = $board->point_of(3, 3);
    $board->put($pt, Game::Go::BLACK);

    $board->libs($pt);        # 4
    $board->chain_size($pt);  # 1
    $board->lift($pt);        # 1 stone removed

=head1 DESCRIPTION

One object holding one pointer to one C board, freed in C<DESTROY>.

B<This is the only class in the distribution that is not built on
L<Object::Proto::Sugar>.> It holds a raw pointer and owns a lifetime, which is
the one thing a property system has nothing to offer: a C<clone> that did not
know what the pointer was would hand two objects the same board and then free it
twice. So it is a plain C<bless> with an explicit C<clone> that copies the board
in C.

=head2 Nothing here checks a rule

C<put> and C<lift> are the ABI's structure primitives. They maintain the chain
structure and the liberty counts exactly, and they judge nothing: C<put> does
not know whether the move was legal, does not capture, and does not know whose
turn it is; C<lift> takes a chain off and says nothing about why. An occupied or
off-board point makes C<put> a no-op rather than a corruption, because the rules
layer is what refuses those and it should be the thing reporting the reason.

They are here so that a test can build a position by hand. Playing Go is a
different layer.

=head1 METHODS

=head2 new

    Game::Go::Engine->new(size => 9)

A board. C<size> defaults to 19 and must be an integer from 2 to 19; anything
else dies, because it is programmer error rather than a rejected move.

=head2 clone

An independent copy. The C board holds no pointers, so the copy shares nothing
with its parent.

=head2 size, stride

The board's size, and the padded row stride, which is C<size + 2>.

=head2 point_of, col_of, row_of

    $board->point_of($col, $row)    # 0-based, row 0 is the TOP
    $board->col_of($pt)
    $board->row_of($pt)

C<point_of> returns -1 for a column or row off the board. A point is an opaque
padded index; see L<Game::Go/"A point is opaque">.

=head2 at

The colour at a point: C<EMPTY>, C<BLACK>, C<WHITE>, or C<BORDER> for the
sentinel ring and for any index off the array.

=head2 libs

The B<exact> number of liberties of the chain at a point, or -1 if the point
holds no stone.

Exact, and distinct: an empty point touching two stones of the same chain is one
liberty and not two. The faster way to keep this number is a running delta, and
it is famously wrong in precisely that case; the count here is recomputed for
the chains a move touched instead.

=head2 chain_size, chain_at

The number of stones in the chain at a point, and an arrayref of their points.
Both are empty for a point holding no stone.

=head2 stones

How many stones of a colour are on the board.

=head2 pack_position

The position as a byte string, one byte per real point, row by row from the top.
This is what makes a zobrist match a certainty rather than a probability: on a
hash collision the caller compares these.

=head2 hash_hex

The zobrist hash of the position, as sixteen hex characters.

A string and not a number, deliberately: on a perl with 32-bit integers a
64-bit value cannot be held in a UV, and the top half would disappear without
anything saying so.

=head2 zobrist_hex

    Game::Go::Engine->zobrist_hex($colour, $pt)

One entry of the zobrist table, as sixteen hex characters. A class method.

The table is derived from SHA-256 rather than from a generator, so that it is
identical on every platform and every build and so that a test can verify any
entry. The entry for a colour and a point is the first eight bytes, big-endian,
of the SHA-256 of the ASCII string

    go-zobrist:<colour>:<point>

with both numbers in decimal. B<That spelling is part of the ABI>, because
t/02-abi.t asserts it against L<Digest::SHA>.

=head2 score

    $board->score(
        dead        => \@chain_points,
        seki        => \@points,
        prisoners_b => $n,
        prisoners_w => $n,
        komi_tenths => 65,
    )

Japanese territory scoring, Articles 8 and 10, as a hashref. B<Scores in it are
in tenths>, because komi is fractional and there are no floats in this engine at
all.

C<dead> and C<seki> are what the players agreed in the confirmation phase;
C<prisoners_b> is what black holds from play. The dead stones are removed on a
copy, so scoring a position never changes it, and each one is added to the
prisoners of the player who did B<not> own it.

See L<Game::Go::Scoring> for the five steps and for the one place this scorer is
knowingly incomplete.

=head2 area_score

Tromp's rule 9: "A player's score is the number of points of her color, plus the
number of empty points that reach only her color." No dead set, no prisoners, no
komi, no agreement about anything.

=head2 prng_next

One step of xorshift32, which is the whole generator:

    x ^= x << 13;   x ^= x >> 17;   x ^= x << 5;

Exposed so a test can mirror it in Perl and digest the two streams against each
other. B<Not a 64-bit generator and nothing with a 32x32 multiply>: on a perl
with 32-bit integers a 64-bit product goes silently through an NV and loses its
low bits, so a generator anybody might want to mirror has to live in add, xor
and shift. A zero state is corrected rather than accepted, because zero is a
fixed point of xorshift and a zero seed would make every playout identical while
every test still passed.

=head2 playout

    $board->playout(colour => $c, seed => $n)

One playout, B<on an internal copy>, so this board is not touched. Returns the
area score C<diff> from black's side, the C<moves> played, and the C<cap>.

The move count is the only way to see the eye rule working from outside: a
playout that settles reaches two consecutive passes in well under the cap, and
one that fills its own eyes never settles and stops at it.

=head2 search

    $board->search(colour => $c, allowed => \@points, seed => $n,
                   playouts => $n, explore => 700)

Monte Carlo with a confidence bound over the root moves. C<allowed> is the root
moves the B<caller> has filtered, which is how the C never sees the superko
history; -1 in the list is a pass.

=head2 dead_guess

Which chains a run of playouts says are dead, for the confirmation phase.
Playouts and not heuristics: from the stopped position, play it out and see
whose the points end up being.

=head2 territory_map

    $board->territory_map(dead => \@points, seki => \@points)

Who owns each empty point, as a hashref of point to colour, by the B<same>
classification C<score> uses. Only the points belonging to somebody appear: dame
and agreed seki do not.

It is one classification rather than two because a second implementation of it
is a second thing to get wrong, and the way it goes wrong is subtle. Territory
is a property of a B<region>, so an empty point beside one black stone on an
otherwise open board belongs to nobody.

=head2 alive

    $board->alive($colour)      # an arrayref of points

Benson's algorithm: the points of every chain of that colour that is
B<unconditionally alive>, meaning alive even if its owner never answers another
move, whatever the opponent does.

D. B. Benson, "Life in the Game of Go", Information Sciences 10 (1976). It is
the only part of life and death that is decidable without search, and it is the
whole of what this engine claims to know about the subject.

It counts B<vital regions, not eye points>, and the difference is what it gets
right that counting eyes does not: a group around a single two-point eye has two
eye points and one vital region, and is not unconditionally alive.

Recomputed on each call. It is asked when a mark is proposed and never inside a
search, so it is allowed to be the slowest thing here, and it is.

=head2 is_alive

    $board->is_alive($pt)

Whether the chain at a point is unconditionally alive. False for an empty point
and for the sentinel ring.

=head2 put, lift

    $board->put($pt, $colour)    # chainable, returns the board
    $board->lift($pt)            # the number of stones removed

The structure primitives described above.

=head1 THE RULES OF PLAY

=head2 legal, is_legal

    $board->legal($pt, $colour)      # a Game::Go refusal code
    $board->is_legal($pt, $colour)   # a boolean

Whether a stone may be played, in five tests in one order:

    1. the point is on the board and empty     ILL_OFF / ILL_TAKEN
    2. it is not this colour's ko point        ILL_KO
    3. the capture is accounted for FIRST
    4. only then, has the played chain a liberty   ILL_SUICIDE
    5. the resulting position is new            ILL_REPEAT

B<The order of 3 and 4 is the rule, not an implementation detail.> Article 5 of
the Japanese rules puts the capture first: "the player must remove all these
opposing stones ... the move is completed when the stones have been removed."
So a move that captures is never suicide. Testing suicide before capture
refuses every capture of a surrounded group, and does it in the way hardest to
notice, because a lone captured stone leaves an empty point behind it and only
captures into a filled shape fail.

Neither mutates the board and neither allocates, so C<legal_moves> can call
C<legal> for every point of the board and a search can call C<legal_moves> for
every move of a playout.

=head2 legal_moves

    $board->legal_moves($colour)     # an arrayref of points

Every point this colour may play, which is not the same as every empty point.

=head2 play

    my $r = $board->play($pt, $colour);

    $r->{ok}         1 if it happened
    $r->{code}       the refusal code, or OK
    $r->{message}    the sentence, on a refusal only
    $r->{caps}       the points the captured stones came off
    $r->{ko_point}   the point now forbidden, or -1

Checks legality first and refuses B<without touching anything>, so a refused
play leaves the board exactly as it was and a client may show the reason and try
again. On success it places the stone, lifts the captured chains, sets the ko
point and records the new position in the history.

=head2 pass

Clears the ko point, because Article 6 forbids the recapture on the B<next> move
only: after a pass the recapture is the move after that. Records no position,
because a pass makes none.

The engine does not count passes and has no opinion about the game ending. Two
consecutive passes stopping play is a rule above this layer.

=head2 ko_point, ko_colour

The point a ko forbids, or -1, and the one colour it is forbidden to.

B<A ko restricts one player, not the board.> Article 6: "A player whose stone
has been captured in a ko cannot recapture in that ko on the next move." The
capturer is not restricted, and on a filled board sometimes wants to play the
point to connect.

A ko is created only when all three of these hold, and each is load-bearing:
the move captured exactly one stone; the chain just played is a single stone;
and that chain has exactly one liberty.

=head2 superko

    $board->superko;        # is it on
    $board->superko(0);     # turn it off, and return the new setting

Positional superko, on by default because it is the shipped rule.

B<This is the distribution's one declared departure from its source.> Article 12
of the Japanese rules ends a game with no result when a whole-board position
repeats. A rated site cannot express "no result", so the repetition is refused
as an illegal move instead, which is what AGA and New Zealand rules do, and
Article 12 becomes unreachable.

It is positional and not situational: a colouring may not recur, whatever the
move order and whoever is to play.

=head2 has_history, history_length, push_position, seen_position

Positional superko needs every colouring the game has had. That history is a
separate allocation rather than part of the board, because a board carrying its
own would make each of a search's millions of board copies 110 KB instead of
eight.

A board made with C<< history => 0 >> has none and gets simple ko and nothing
else. That is what a playout wants, and it is asked for rather than defaulted so
that nobody inherits it by accident.

C<push_position> records the current position. C<put> does not, because a
hand-built position has no history by definition; a caller that has just built
one and wants the game to start from it says so.

=head2 hash_after_hex

    $board->hash_after_hex($pt, $colour)

The zobrist hash the position B<would> have after a play, without playing it,
as sixteen hex characters. The superko filter is built on this.

It is public because a test that cannot see the filter's input cannot tell a
working filter from one that always misses. Note that a capture moves the hash
by more than the played stone: the captured stones come out of it too, and a
version of this that forgot them would predict positions that never occur and
superko would silently never fire.

=head1 SEE ALSO

L<Game::Go>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
