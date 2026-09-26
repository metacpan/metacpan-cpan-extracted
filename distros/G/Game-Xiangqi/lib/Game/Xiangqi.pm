package Game::Xiangqi;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar -types;

use Game::Xiangqi::Engine ':all';
use Game::Xiangqi::Notation;
use Game::Xiangqi::Error;

our $VERSION = '0.01';

my $E = 'Game::Xiangqi::Engine';
my $N = 'Game::Xiangqi::Notation';
my $R = 'Game::Xiangqi::Error';

has red => (is => 'ro', isa => Str, default => 'p1');

has status => (is => 'rw', isa => Str, default => 'active');

has _held_seed => (is => 'ro', init_arg => 'seed');

has _pos => (is => 'rw', init_arg => 'position', private => 1);

has _start => (is => 'rw', private => 1);

has _log => (is => 'ro', isa => ArrayRef, default => [], private => 1);

has _played => (is => 'ro', isa => ArrayRef, default => [], private => 1);

has _result => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;

    my $seed = $self->_held_seed;
    Carp::croak('Game::Xiangqi: seed must be exactly thirty-two bytes')
        unless defined $seed && length($seed) == 32;

    my $red = $self->red;
    Carp::croak("Game::Xiangqi: red must be 'p1' or 'p2', not '$red'")
        unless $red eq 'p1' || $red eq 'p2';

    my $pos = $self->_pos ? $self->_pos->clone : $E->new;
    $self->_pos($pos);
    $self->_start($pos->clone);
    $self->_result({ winner => undef, reason => undef, rule => 0, loop => undef });

    $self->_settle;
    return;
}

sub position  { $_[0]->_pos }
sub signature { $_[0]->_pos->key_hex }
sub log       { [ @{ $_[0]->_log } ] }

sub _seat_of   { $_[1] == RED ? $_[0]->red : ($_[0]->red eq 'p1' ? 'p2' : 'p1') }
sub _colour_of { $_[1] eq $_[0]->red ? RED : BLACK }

sub turn {
    my ($self) = @_;
    return undef unless $self->status eq 'active';
    return $self->_seat_of($self->_pos->side);
}

sub legal {
    my ($self) = @_;
    return [] unless $self->status eq 'active';
    return [ map { $N->iccs_of($_) } $self->_pos->legal ];
}

sub seed {
    my ($self) = @_;
    return undef unless $self->status eq 'finished';
    return $self->_held_seed;
}

sub play {
    my ($self, $iccs) = @_;
    return $R->throw('game_over') unless $self->status eq 'active';

    my $mv = $N->move_of_iccs($iccs);
    return $R->throw('bad_move') unless defined $mv;

    my $why = $self->_refuse($mv);
    return $why if $why;

    push @{ $self->_log },    $N->iccs_of($mv);
    push @{ $self->_played }, $mv;
    $self->_pos->do_move($mv);

    $self->_settle;
    return 0;
}

sub _settle {
    my ($self) = @_;

    my ($winner, $reason) = $self->_pos->outcome;
    if ($winner) {
        $self->status('finished');
        $self->_result({
            winner => $self->_seat_of($winner),
            reason => $reason == BY_CHECKMATE ? 'checkmate' : 'stalemate',
            rule   => 0,
            loop   => undef,
        });
        return;
    }

    my $v = $self->_start->judge($self->_played);
    return unless $v->{reason} != J_ONGOING;

    my %name = (
        J_PERPETUAL_CHECK() => 'perpetual_check',
        J_PERPETUAL_CHASE() => 'perpetual_chase',
        J_MUTUAL()          => 'mutual',
        J_NO_VIOLATION()    => 'no_violation',
        J_EFFECTIVE()       => 'effective',
        J_PROGRESS()        => 'progress',
        J_MOVES()           => 'moves',
    );
    $self->status('finished');
    $self->_result({
        winner => $v->{winner} ? $self->_seat_of($v->{winner}) : undef,
        reason => $name{ $v->{reason} },
        rule   => $v->{rule},
        loop   => $v->{loop_from} >= 0
                ? [ @{ $self->_log }[ $v->{loop_from} .. $#{ $self->_log } ] ]
                : undef,
    });
}

sub _refuse {
    my ($self, $mv) = @_;
    my $p = $self->_pos;
    my ($from, $to) = ($E->move_from($mv), $E->move_to($mv));

    my $piece = $p->at($from);
    return $R->throw('no_piece')
        unless $piece && $piece != BORDER && Game::Xiangqi::Engine::kind_of($piece);
    return $R->throw('not_your_turn')
        unless Game::Xiangqi::Engine::colour_of($piece) == $p->side;

    return 0 if grep { $_ == $mv } $p->legal;

    if (grep { $_ == $mv } $p->moves) {
        my (undef, $u) = $p->do_move($mv);
        my $face = $p->generals_face;
        $p->undo_move($u);
        return $R->throw($face ? 'generals_face' : 'in_check', legal => $self->legal);
    }

    my $kind   = Game::Xiangqi::Engine::kind_of($piece);
    my $colour = Game::Xiangqi::Engine::colour_of($piece);

    return $R->throw('own_piece')
        if Game::Xiangqi::Engine::colour_of($p->at($to)) == $colour;

    if ($kind == GENERAL) {
        return $R->throw('general_leaves_palace') unless $E->in_palace($to, $colour);
    }
    elsif ($kind == ADVISOR) {
        return $R->throw('advisor_leaves_palace') unless $E->in_palace($to, $colour);
    }
    elsif ($kind == ELEPHANT) {
        return $R->throw('elephant_crosses_river') if $E->crossed_river($to, $colour);
        my $eye = $p->elephant_eye($from, $to);
        return $R->throw('elephant_eye_blocked') if $eye >= 0 && $p->at($eye) != EMPTY;
    }
    elsif ($kind == HORSE) {
        my $leg = $p->horse_leg($from, $to);
        return $R->throw('horse_leg_blocked') if $leg >= 0 && $p->at($leg) != EMPTY;
    }
    elsif ($kind == CANNON) {
        my $n = $p->cannon_screens($from, $to);
        return $R->throw('cannon_needs_one_screen') if $n >= 0;
    }
    elsif ($kind == SOLDIER) {
        my ($fr, $tr) = ($E->rank_of($from), $E->rank_of($to));
        my $back = $colour == RED ? $tr < $fr : $tr > $fr;
        return $R->throw('soldier_no_retreat') if $back;
        return $R->throw('soldier_no_sideways')
            if $fr == $tr && !$E->crossed_river($from, $colour);
    }
    return $R->throw('not_legal', legal => $self->legal);
}

sub result {
    my ($self) = @_;
    return { winner => undef, reason => undef, rule => 0, loop => undef }
        if $self->status eq 'active';
    return { %{ $self->_result } };
}

sub winner { $_[0]->result->{winner} }

sub bot { require Game::Xiangqi::Bot; 'Game::Xiangqi::Bot' }

sub replay {
    my ($proto, @rest) = @_;

    if (ref $proto) {
        my $moves = ref $rest[0] eq 'ARRAY' ? $rest[0] : [ grep { defined } @rest ];
        return $proto->_replayed($moves);
    }

    return undef if @rest % 2;
    my %o = @rest;
    my $self = $proto->new(%o);
    return $self->_walk($o{moves} || []);
}

sub _replayed {
    my ($self, $moves) = @_;
    my $fresh = (ref $self)->new(
        seed     => $self->_held_seed,
        red      => $self->red,
        position => $self->_start,
    );
    return $fresh->_walk($moves);
}

sub _walk {
    my ($self, $moves) = @_;
    for my $i (0 .. $#$moves) {
        my $why = $self->play($moves->[$i]);
        return wantarray ? ($self, $why, $i) : undef if $why;
    }
    return wantarray ? ($self, 0, scalar @$moves) : $self;
}

1;

__END__

=head1 NAME

Game::Xiangqi - xiangqi, Chinese chess

=head1 SYNOPSIS

    use Game::Xiangqi;

    my $g = Game::Xiangqi->new(seed => $thirty_two_bytes, red => 'p1');
    $g->turn;                 # 'p1'
    $g->legal;                # [ 'h2e2', ... ] in ICCS
    my $why = $g->play('h2e2');   # 0, or a refusal NAME
    $g->status;               # 'active' | 'finished'
    $g->result;               # { winner, reason, rule, loop }

    my ($replayed, $why, $at) = Game::Xiangqi->replay(
        seed => $seed, red => 'p1', moves => $g->log);

=head1 DESCRIPTION

Xiangqi, the game most of the world knows as Chinese chess: nine files, ten
ranks, pieces on the intersections, a river across the middle and a palace at
each end.

It is the engine behind the Xiangqi at L<https://peer2peergames.com>.

=head2 A refusal is returned, never thrown

C<play> hands back a L<Game::Xiangqi::Error> or C<0>. The flags are specific on
purpose: C<elephant_crosses_river> rather than C<not_legal>, because a player told
which rule they broke does not come back and argue.

B<A bad construction, on the other hand, croaks.> The two are different kinds of
wrong: a refused move is an ordinary thing for a player to do, while a seed of the
wrong length is a bug in the caller and is raised where it happens.

=head2 The Perl layer is Object::Proto::Sugar

Every attribute here is declared with C<has>, so the objects are B<arrays and not
hashes> and C<< $game->{status} >> is not a thing that works. Reach for the
accessors: C<status>, C<red>, C<position>, C<log>. The internals are named with a
leading underscore and the board itself is a private attribute, so a caller cannot
reach past the counters and the judge by accident.

=head2 Stalemate is a loss

A side with no legal move loses, in check or not. There is no draw-by-position
in this game at all: every draw it has is a property of a SEQUENCE, and those
are the Asian Rules on repetition and three counters adopted from CXQ.

=head2 The result carries a rule number

When the Asian Rules decide a game, C<result> carries the number of the rule
that did it. A ruling with no number is one a player cannot check.

=head2 The three counters

Three of the draws are counters adopted from CXQ rather than rulings from the
Asian Rules, and C<result>'s C<reason> says which one ended the game. C<progress>
is thirty moves a side with no capture and no soldier advancing over the river.
C<effective> is a hundred and twenty moves a side counting B<only> moves that are
neither a check nor a chase nor a reply to one, which is CXQ's Effective Rule.
C<moves> is three hundred moves a side outright.

All three are counted by the judge B<while it classifies the sequence>, because
only the classification knows whether a move was an effective one, and all three
come back with C<rule> C<0>: they are house counters and there is no Asian Rules
number to give.

=head2 The seed is held and never read

Xiangqi has no randomness in it. The seed is stored because the site hands every
game thirty-two bytes and publishes them when the game finishes so it can be
checked, and C<seed> returns undef until then. B<Do not remove it on the grounds
that nothing reads it.>

=head1 METHODS

=head2 new

    my $g = Game::Xiangqi->new(seed => $bytes, red => 'p1', position => $pos);

C<seed> is B<exactly thirty-two bytes> and is required; C<red> is C<'p1'> or
C<'p2'> and says which seat plays Red and therefore moves first, defaulting to
C<'p1'>. Either of them wrong B<croaks>, because a game built from a seed of the
wrong length is the caller's bug and not a thing a player did. A refused move, by
contrast, is returned: see L<Game::Xiangqi::Error>.

C<position> is an optional L<Game::Xiangqi::Engine> to start from instead of the
opening, and it is cloned, so the caller keeps theirs.

A game handed a position that is already finished B<reports itself finished
immediately>, rather than offering a turn with no moves in it.

=head2 status

C<'active'> or C<'finished'>. Read-write: setting it is how a caller that has
decided the game is over out-of-band, such as a resignation, says so.

=head2 red

The seat that plays Red, C<'p1'> or C<'p2'>. Read-only: which seat is Red is
decided once, at construction.

=head2 turn

The seat to move, C<'p1'> or C<'p2'>, or C<undef> once the game is over.

=head2 legal

An arrayref of every legal move for the side to move, in ICCS coordinates. Empty
once the game is finished.

=head2 play

    my $refusal = $g->play('h2e2');
    say $refusal->code if $refusal;      # 'elephant_crosses_river'

Plays one move given in ICCS. Returns C<0> on success or a
L<Game::Xiangqi::Error> B<object> carrying the reason; it never throws, whatever
it is handed. On success the game's counters, its ruling and its turn are all
brought up to date.

The refusal is an object rather than a name so that a caller can ask
C<< $refusal->code >> for the flag, C<< $refusal->message >> for the sentence to
show a player, and C<< $refusal->in_check >> for one specific reason, without a
table of its own. There is no C<""> overload, so a refusal used as a string is a
reference and looks like the mistake it is.

=head2 result

    { winner => 'p1' | 'p2' | undef,
      reason => 'checkmate' | 'stalemate' | 'perpetual_check' | 'perpetual_chase'
              | 'mutual' | 'no_violation' | 'effective' | 'progress' | 'moves',
      rule   => 19,
      loop   => [ 'h2e2', ... ] }

Empty while the game is on. C<rule> is the Asian Rules rule number when the judge
decided it and C<0> otherwise, and C<loop> is the repeated sequence when there was
one.

=head2 winner

The winning seat, or C<undef>. A shorthand for C<< result->{winner} >>.

=head2 log

An arrayref copy of the moves so far, in ICCS. This is the canonical
serialisation of the game: nothing else needs to be stored.

=head2 replay

    my $again = Game::Xiangqi->replay(seed => $s, red => 'p1', moves => \@log);
    my $again = $game->replay(\@log);

Rebuilds a game by B<playing the log from the start position, every time>. It
never loads a stored position, which is what makes a finished game checkable and a
forged log catchable: an altered move is refused at that move and not after it.

The class form builds a fresh game from a seed and a log. The instance form
replays this game's own moves from its own starting position, seed and seat.

In list context both return C<($game, $refusal, $index)> so a caller can see B<where>
a bad log went wrong, C<$refusal> being a L<Game::Xiangqi::Error>. In scalar context
they return the game, or C<undef> if any move was refused. A misuse, such as an
odd-sized list, returns C<undef> and does not warn; a bad seed croaks, as it does in
C<new>.

=head2 position

The live L<Game::Xiangqi::Engine> board. Reading it is fine; moving on it directly
bypasses the counters and the judge.

=head2 signature

Sixteen hex characters identifying the position, from the Zobrist key. Changes on
every move. B<A string and never a number>, because a 64-bit key does not fit in an
IV on every perl.

=head2 seed

The thirty-two bytes the game was built with, but B<only once the game is
finished>, and C<undef> before that. The engine never reads the seed: xiangqi has
no randomness in it at all. It is held because the site publishes it when a game
ends so that the game can be checked.

=head2 bot

The name of the opponent class, L<Game::Xiangqi::Bot>, loaded on demand.

=head1 SEE ALSO

L<Game::Xiangqi::Engine>, the board; L<Game::Xiangqi::Notation>, the two
spellings of a move; L<Game::Xiangqi::Error>, the refusal names.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
