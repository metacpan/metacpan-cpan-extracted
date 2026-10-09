package Game::Brandubh;

use 5.010;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

use Game::Brandubh::Engine qw(
    ATTACKERS DEFENDERS EMPTY ATTACKER DEFENDER KING
    KING_HOME KING_TAKEN
    WHY_OK WHY_NO_PIECE WHY_NOT_YOURS WHY_NO_MOVE WHY_NOT_A_LINE
    WHY_THRONE WHY_CORNER WHY_BLOCKED
);
use Game::Brandubh::Rules qw(PLAY_OK BY_CORNER outcome_name);
use Game::Brandubh::Notation qw(
    SETUP square_name square_parse move_parse move_split move_display
    position_ok game_string game_parse
);
use Game::Brandubh::Variant;
use Game::Brandubh::Error;
use Game::Brandubh::Result;
use Digest::SHA ();

our $VERSION = '0.01';

my $E = 'Game::Brandubh::Engine';
my $X = 'Game::Brandubh::Error';

my (@SIDE, @PIECE, %REFUSAL);
BEGIN {
    @SIDE  = ('attackers', 'defenders');
    @PIECE = ('', 'attacker', 'defender', 'king');
    %REFUSAL = (
        WHY_NO_PIECE()   => 'no_piece',
        WHY_NOT_YOURS()  => 'not_your_piece',
        WHY_NO_MOVE()    => 'no_move',
        WHY_NOT_A_LINE() => 'not_a_line',
        WHY_THRONE()     => 'throne_closed',
        WHY_CORNER()     => 'corner_closed',
        WHY_BLOCKED()    => 'path_blocked',
    );
}

has attackers => (is => 'ro', default => 'p1');

has _seed => (is => 'ro', init_arg => 'seed', private => 1);

has _variant_given => (is => 'ro', init_arg => 'variant', private => 1);

has _start_given => (is => 'ro', init_arg => 'position', private => 1);

has _variant => (is => 'rw', private => 1);

has _start => (is => 'rw', private => 1);

has _game => (is => 'rw', private => 1);

has _log => (is => 'ro', default => [], private => 1);

has _shown => (is => 'ro', default => [], private => 1);

has _ended => (is => 'rw', private => 1);

has _offer => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;

    my $attackers = $self->attackers;
    Carp::croak("Game::Brandubh: attackers must be 'p1' or 'p2', not '" . ($attackers // 'undef') . "'")
        unless defined $attackers && ($attackers eq 'p1' || $attackers eq 'p2');

    my $seed = $self->_seed;
    Carp::croak('Game::Brandubh: a seed, when one is given, is exactly thirty-two bytes')
        if defined $seed && (ref $seed || length($seed) != 32);

    my $given = $self->_variant_given;
    my $variant;
    if (!defined $given) {
        $variant = Game::Brandubh::Variant->named;
    }
    elsif (ref $given eq 'Game::Brandubh::Variant') {
        $variant = $given;
    }
    elsif (ref $given eq 'HASH') {
        $variant = Game::Brandubh::Variant->custom(%$given);
    }
    elsif (!ref $given) {
        $variant = Game::Brandubh::Variant->from_string($given);
        Carp::croak("Game::Brandubh: '$given' is not a rule set") unless $variant;
    }
    else {
        Carp::croak('Game::Brandubh: a variant is a name, a hash of fields or a Game::Brandubh::Variant');
    }
    $self->_variant($variant);

    my $start = $self->_start_given;
    $start = SETUP unless defined $start;
    Carp::croak("Game::Brandubh: '$start' is not a position") unless position_ok($start);
    $self->_start($start);

    $self->_game(Game::Brandubh::Rules->new(position => $start, variant => $variant->as_hash));
    return;
}

sub variant { $_[0]->_variant }
sub start   { $_[0]->_start }

sub status {
    my ($self) = @_;
    return 'finished' if $self->_ended || $self->_game->is_over;
    return 'active';
}

sub side_of {
    my ($self, $seat) = @_;
    return undef unless defined $seat && ($seat eq 'p1' || $seat eq 'p2');
    return $seat eq $self->attackers ? 'attackers' : 'defenders';
}

sub seat_of {
    my ($self, $side) = @_;
    return undef unless defined $side;
    return $self->attackers if $side eq 'attackers';
    return ($self->attackers eq 'p1' ? 'p2' : 'p1') if $side eq 'defenders';
    return undef;
}

sub side_to_move {
    my ($self) = @_;
    return undef unless $self->status eq 'active';
    return $SIDE[ $self->_game->side ];
}

sub turn {
    my ($self) = @_;
    my $side = $self->side_to_move;
    return defined $side ? $self->seat_of($side) : undef;
}

sub _names_of {
    my ($mv) = @_;
    my $from = $E->move_from($mv);
    my $to   = $E->move_to($mv);
    return (square_name($E->file_of($from), $E->rank_of($from)),
            square_name($E->file_of($to),   $E->rank_of($to)));
}

sub _square_of {
    my ($name) = @_;
    my ($file, $rank) = square_parse($name) or return undef;
    return $E->square_of($file, $rank);
}

sub _about {
    my ($self, $mv) = @_;
    my $game = $self->_game;
    my ($flags, @squares) = $game->preview($mv);
    my $piece = $game->at($E->move_from($mv));
    my @captures = sort map { square_name($E->file_of($_), $E->rank_of($_)) } @squares;

    my $wins = ($flags & (KING_HOME | KING_TAKEN)) ? 1 : 0;
    if (!$wins && $piece != ATTACKER && @squares) {
        my $attackers_taken = grep { $game->at($_) == ATTACKER } @squares;
        $wins = 1 if $attackers_taken == $game->count(ATTACKER);
    }
    return {
        piece      => $PIECE[$piece],
        king       => $piece == KING ? 1 : 0,
        captures   => \@captures,
        king_home  => ($flags & KING_HOME)  ? 1 : 0,
        king_taken => ($flags & KING_TAKEN) ? 1 : 0,
        wins       => $wins,
    };
}

sub legal {
    my ($self) = @_;
    return [] unless $self->status eq 'active';
    my @legal;
    for my $mv ($self->_game->moves) {
        my ($from, $to) = _names_of($mv);
        my $about = $self->_about($mv);
        push @legal, {
            move     => $from . $to,
            from     => $from,
            to       => $to,
            piece    => $about->{piece},
            captures => $about->{captures},
            wins     => $about->{wins},
        };
    }
    return \@legal;
}

sub _seat_refusal {
    my ($self, $seat) = @_;
    return $X->throw('not_a_seat') unless defined $seat && !ref $seat && ($seat eq 'p1' || $seat eq 'p2');
    return 0;
}

sub play {
    my ($self, $move, $seat) = @_;
    my %with = (defined $move && !ref $move ? (move => $move) : ());

    return $X->throw('game_over', %with) unless $self->status eq 'active';
    if (defined $seat) {
        my $refused = $self->_seat_refusal($seat);
        return $refused if $refused;
        return $X->throw('not_your_turn', %with) unless $seat eq $self->turn;
    }

    my $wire = move_parse($move);
    return $X->throw('bad_move', %with) unless defined $wire;
    my ($from_name, $to_name) = move_split($wire);
    my ($from, $to) = (_square_of($from_name), _square_of($to_name));

    my $game = $self->_game;
    my $why = $game->why_not($from, $to);
    return $X->throw($REFUSAL{$why} // 'bad_move', %with) unless $why == WHY_OK;

    my $mv = $E->move($from, $to);
    my $about = $self->_about($mv);
    return $X->throw('bad_move', %with) unless $game->play($mv) == PLAY_OK;

    push @{ $self->_log },   $wire;
    push @{ $self->_shown }, move_display($wire, $about);
    $self->_offer(undef);
    return 0;
}

sub play_or_die {
    my ($self, $move, $seat) = @_;
    my $refused = $self->play($move, $seat);
    Carp::croak('Game::Brandubh: ' . (defined $move ? "'$move'" : 'that') . ' was refused: ' . $refused->message)
        if $refused;
    return $self;
}

sub undo {
    my ($self) = @_;
    if ($self->_ended) {
        $self->_ended(undef);
        return 1;
    }
    return 0 unless $self->_game->undo;
    pop @{ $self->_log };
    pop @{ $self->_shown };
    $self->_offer(undef);
    return 1;
}

sub resign {
    my ($self, $seat) = @_;
    return $X->throw('game_over') unless $self->status eq 'active';
    my $refused = $self->_seat_refusal($seat);
    return $refused if $refused;

    my $winner = $self->side_of($seat) eq 'attackers' ? 'defenders' : 'attackers';
    $self->_ended(Game::Brandubh::Result->new(
        how      => 'resign',
        winner   => $winner,
        seat     => $self->seat_of($winner),
        ply      => $self->_game->ply,
        position => $self->_game->position,
    ));
    $self->_offer(undef);
    return 0;
}

sub offer_draw {
    my ($self, $seat) = @_;
    return $X->throw('game_over') unless $self->status eq 'active';
    my $refused = $self->_seat_refusal($seat);
    return $refused if $refused;
    return $X->throw('offer_standing') if defined $self->_offer;
    $self->_offer($seat);
    return 0;
}

sub _answer_refusal {
    my ($self, $seat) = @_;
    return $X->throw('game_over') unless $self->status eq 'active';
    my $refused = $self->_seat_refusal($seat);
    return $refused if $refused;
    return $X->throw('no_offer') unless defined $self->_offer;
    return $X->throw('own_offer') if $self->_offer eq $seat;
    return 0;
}

sub accept_draw {
    my ($self, $seat) = @_;
    my $refused = $self->_answer_refusal($seat);
    return $refused if $refused;
    $self->_ended(Game::Brandubh::Result->new(
        how      => 'agreed',
        ply      => $self->_game->ply,
        position => $self->_game->position,
    ));
    $self->_offer(undef);
    return 0;
}

sub decline_draw {
    my ($self, $seat) = @_;
    my $refused = $self->_answer_refusal($seat);
    return $refused if $refused;
    $self->_offer(undef);
    return 0;
}

sub draw_offered_by { $_[0]->_offer }

sub result {
    my ($self) = @_;
    return $self->_ended if $self->_ended;
    my $game = $self->_game;
    return undef unless $game->is_over;

    my $outcome = $game->outcome;
    my $how = outcome_name($outcome);
    $how = 'edge' if $outcome == BY_CORNER && $self->_variant->escape eq 'edge';

    my $side = $game->winner;
    my $winner = defined $side ? $SIDE[$side] : undef;
    return Game::Brandubh::Result->new(
        how      => $how,
        (defined $winner ? (winner => $winner, seat => $self->seat_of($winner)) : ()),
        ply      => $game->ply,
        position => $game->position,
    );
}

sub winner {
    my ($self) = @_;
    my $result = $self->result;
    return $result ? $result->seat : undef;
}

sub position  { $_[0]->_game->position }
sub signature { $_[0]->_game->key_hex }
sub repeats   { $_[0]->_game->repeats }
sub ply       { $_[0]->_game->ply }
sub log       { [ @{ $_[0]->_log } ] }
sub shown     { [ @{ $_[0]->_shown } ] }

sub seed {
    my ($self) = @_;
    return undef unless $self->status eq 'finished';
    return $self->_seed;
}

sub at {
    my ($self, $name) = @_;
    my $square = _square_of($name);
    return undef unless defined $square;
    return $PIECE[ $self->_game->at($square) ];
}

sub pieces {
    my ($self) = @_;
    my $game = $self->_game;
    my %pieces;
    for my $square ($E->all_squares) {
        my $piece = $game->at($square);
        next if $piece == EMPTY;
        $pieces{ square_name($E->file_of($square), $E->rank_of($square)) } = $PIECE[$piece];
    }
    return \%pieces;
}

sub search {
    my ($self, %with) = @_;
    return undef unless $self->status eq 'active';

    my $salt = defined $with{salt} ? $with{salt} : '';
    Carp::croak('Game::Brandubh: a search salt is a string') if ref $salt;
    my $seed = unpack 'N', Digest::SHA::sha256(join '|', $salt, $self->turn, $self->_game->ply, $self->_game->key_hex);

    my $found = $self->_game->search(
        budget => $with{budget},
        seed   => $seed || 1,
        (defined $with{depth}   ? (depth   => $with{depth})   : ()),
        (defined $with{weights} ? (weights => $with{weights}) : ()),
    );
    return undef unless $found;
    my ($from, $to) = _names_of($found->{move});
    return {
        move    => $from . $to,
        score   => $found->{score},
        depth   => $found->{depth},
        nodes   => $found->{nodes},
        stopped => $found->{stopped},
    };
}

sub bot { require Game::Brandubh::Bot; return 'Game::Brandubh::Bot' }

sub _apply_result {
    my ($self, $result) = @_;
    return 0 unless defined $result;
    return $X->throw('bad_move') unless ref $result eq 'HASH';
    my $how = $result->{how} // '';
    if ($how eq 'resign') {
        return $self->resign($self->seat_of($result->{by}));
    }
    if ($how eq 'agreed') {
        return $X->throw('game_over') unless $self->status eq 'active';
        my $first = $self->turn;
        my $refused = $self->offer_draw($first);
        return $refused if $refused;
        return $self->accept_draw($first eq 'p1' ? 'p2' : 'p1');
    }
    return $X->throw('bad_move');
}

sub _walk {
    my ($self, $moves, $result) = @_;
    for my $i (0 .. $#$moves) {
        my $refused = $self->play($moves->[$i]);
        return wantarray ? ($self, $refused, $i) : undef if $refused;
    }
    my $refused = $self->_apply_result($result);
    return wantarray ? ($self, $refused, scalar @$moves) : undef if $refused;
    return wantarray ? ($self, 0, scalar @$moves) : $self;
}

sub replay {
    my ($proto, @rest) = @_;

    if (ref $proto) {
        my $moves = ref $rest[0] eq 'ARRAY' ? $rest[0] : [ grep { defined } @rest ];
        my $fresh = (ref $proto)->new(
            attackers => $proto->attackers,
            variant   => $proto->_variant,
            position  => $proto->_start,
            (defined $proto->_seed ? (seed => $proto->_seed) : ()),
        );
        return $fresh->_walk($moves);
    }

    Carp::croak('Game::Brandubh: replay takes name => value pairs') if @rest % 2;
    my %given = @rest;
    my $moves  = delete $given{moves};
    my $result = delete $given{result};
    Carp::croak('Game::Brandubh: moves is an array reference') if defined $moves && ref $moves ne 'ARRAY';
    my $fresh = $proto->new(%given);
    return $fresh->_walk($moves || [], $result);
}

sub as_text {
    my ($self) = @_;
    my $ended = $self->_ended;
    my $result;
    if ($ended) {
        $result = $ended->how eq 'resign' ? { how => 'resign', by => $ended->loser }
                                          : { how => 'agreed' };
    }
    return game_string({
        variant => $self->_variant->as_string,
        start   => $self->_start,
        moves   => $self->_log,
        result  => $result,
    });
}

sub from_text {
    my ($class, $text, @rest) = @_;
    Carp::croak('Game::Brandubh: from_text takes the text and then name => value pairs') if @rest % 2;
    my $record = game_parse($text);
    return wantarray ? (undef, $X->throw('bad_move'), 0) : undef unless $record;
    my $variant = Game::Brandubh::Variant->from_string($record->{variant});
    return wantarray ? (undef, $X->throw('bad_move'), 0) : undef unless $variant;
    return $class->replay(
        @rest,
        variant  => $variant,
        position => $record->{start},
        moves    => $record->{moves},
        result   => $record->{result},
    );
}

1;

__END__

=head1 NAME

Game::Brandubh - the Irish 7 by 7 tafl game: a king, four defenders, eight attackers

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Brandubh;

    my $game = Game::Brandubh->new;

    print $game->turn, "\n";                 # p1, who has the attackers
    for my $move (@{ $game->legal }) {
        print "$move->{move} takes @{ $move->{captures} }\n" if @{ $move->{captures} };
    }

    my $refused = $game->play('d1c1');
    print $refused->message, "\n" if $refused;

    if ($game->status eq 'finished') {
        my $result = $game->result;
        print $result->how, ': ', $result->winner // 'a draw', "\n";
    }

    my $saved = $game->as_text;
    my $again = Game::Brandubh->from_text($saved);

=head1 DESCRIPTION

Brandubh is the smallest of the tafl games, the one played in Ireland. A king
and his four defenders start in the middle of a board of seven squares by
seven, and eight attackers stand round them in a cross. Every piece moves like
a rook. The king wins by reaching a corner; the attackers win by capturing
him.

The two players do not have the same pieces or the same aim. That is the game.

This class is a whole game: it knows whose move it is, which moves are legal
and what each would capture, why a move was refused, and when and how the game
has ended. It keeps a log that a game can be played again from.

It is the engine behind the brandubh at L<https://peer2peergames.com>.

=head2 The rules

No rules for brandubh survive. What survives is a handful of boards and a few
lines of verse, which give the number of pieces and the king's corners. Every
set of rules in use is a reconstruction.

This distribution follows the reconstruction by Aage Nielsen, as published in
twelve numbered rules at L<http://tafl.cyningstan.com/page/171/brandub>.

=over 4

=item *

The attackers move first.

=item *

A piece moves any distance along a rank or a file. It may not land on another
piece and may not jump one.

=item *

No piece may stop on the central square, the throne, not even the king once
he has left it. Only the king may stop on a corner.

=item *

A piece other than the king is captured when the enemy moves so that it
stands between two enemy pieces on opposite sides. An empty corner, and the
throne while it is empty, each count as an enemy to both sides.

=item *

The king is captured by attackers: four of them round him when he is on the
throne, three when he stands beside it, and two, as for any piece, anywhere
else.

=item *

The king wins on reaching a corner. The attackers win by capturing him.

=item *

The game is drawn when a position is repeated and when a side cannot move.

=back

=head2 Where this distribution reads between the lines

Twelve rules leave some things unsaid. Each of these is this distribution's
own reading, and each is a field of L<Game::Brandubh::Variant> or is described
there.

=over 4

=item *

Only the piece that moved captures. A piece may move between two enemies and
stand there unharmed.

=item *

One move captures every enemy it closes on, up to three.

=item *

A piece may slide across the empty throne on its way elsewhere.

=item *

The king captures as any defender does.

=item *

Nothing is captured against the edge of the board.

=item *

"Repeated" is taken as the third occurrence of a position, not the second.

=item *

Attackers with no piece left have lost. Read to the letter, the rule about a
side that cannot move would call that a draw.

=item *

A game that will not end is drawn after 400 moves.

=item *

A finished game is shown with C<++> after the move that took the king to a
corner and C<#> after the move that captured him.

=back

=head2 Seats and sides

A B<side> is C<attackers> or C<defenders>. A B<seat> is C<p1> or C<p2>, the two
people at the table. C<attackers> says which seat has the attackers, and so
moves first; C<side_of> and C<seat_of> go between the two.

=head2 A refusal is returned, never thrown

C<play>, C<resign> and the three draw methods hand back C<0>, or a
L<Game::Brandubh::Error> saying what was wrong. Nothing was changed.

B<A bad construction, on the other hand, croaks.> A refused move is an ordinary
thing for a player to do; a seat called C<p3> in C<new> is a mistake in the
program.

B<An argument to C<new> whose name is misspelt is not noticed.> C<new> takes
the four names below and ignores any other.

=head1 METHODS

=head2 new

    my $game = Game::Brandubh->new(
        attackers => 'p2',
        variant   => { repeat => 2 },
        position  => '7/7/7/3k3/7/7/a6 d',
        seed      => $thirty_two_bytes,
    );

Every argument is optional.

=over 4

=item C<attackers>

The seat that has the attackers, C<p1> by default.

=item C<variant>

A L<Game::Brandubh::Variant>, or a hash reference of its fields, or the string
its C<as_string> writes. The default rule set when left out.

=item C<position>

Where the game starts, as a position string. The set-up when left out.

=item C<seed>

Exactly thirty-two bytes. The rules never read it: brandubh has no chance in
it. It is held for whoever plays the game against a program, so that the
program's choices can be made the same way twice.

=back

B<Croaks> when any of them is not what it should be.

=head2 attackers

The seat that has the attackers.

=head2 variant

The rule set, a L<Game::Brandubh::Variant>.

=head2 start

The position the game started from.

=head2 status

C<active> or C<finished>.

=head2 turn

The seat whose move it is, or C<undef> when the game is finished.

=head2 side_to_move

C<attackers> or C<defenders>, or C<undef> when the game is finished.

=head2 side_of

    my $side = $game->side_of('p1');

The side a seat has, or C<undef> for something that is not a seat.

=head2 seat_of

    my $seat = $game->seat_of('defenders');

The seat a side belongs to, or C<undef> for something that is not a side.

=head2 legal

    my $moves = $game->legal;

An array reference of the moves of the side to move, empty when the game is
finished. Each is a hash reference:

=over 4

=item C<move>

The move as it is stored, C<d1d3>.

=item C<from>, C<to>

The two squares.

=item C<piece>

C<attacker>, C<defender> or C<king>.

=item C<captures>

An array reference of the squares whose pieces the move would capture.

=item C<wins>

True when the move wins the game.

=back

=head2 play

    my $refused = $game->play('d1c1');
    my $refused = $game->play('d1-c1', 'p1');

Plays a move for the side to move. The move may be written as it is stored or
as it is shown. Naming the seat is optional; when it is named, it must be that
seat's turn. Returns C<0>, or a L<Game::Brandubh::Error>.

=head2 play_or_die

    $game->play_or_die('d1c1')->play_or_die('d3c3');

The same, for a caller who would sooner have an exception. Returns the game.
B<Croaks> with the refusal's sentence.

=head2 undo

Takes back the last thing that happened: a resignation or an agreed draw if
that is how the game ended, and otherwise the last move. Any draw offer is
withdrawn. Returns true, or false when there is nothing to take back.

=head2 resign

    my $refused = $game->resign('p2');

The seat gives the game to the other side. Returns C<0>, or a refusal.

=head2 offer_draw

    my $refused = $game->offer_draw('p1');

Either seat may offer a draw at any time, when no offer is waiting. An offer
stands until it is answered or until a move is made.

=head2 accept_draw

=head2 decline_draw

    my $refused = $game->accept_draw('p2');

The other seat answers. Accepting ends the game. A seat cannot answer its own
offer.

=head2 draw_offered_by

The seat whose offer is waiting, or C<undef>.

=head2 result

A L<Game::Brandubh::Result>, or C<undef> while the game is active.

=head2 winner

The seat that won, or C<undef> while the game is active or when it was drawn.

=head2 position

The position on the board, as a string.

=head2 signature

A key for the position on the board: sixteen hexadecimal characters, the same
for the same pieces on the same squares with the same side to move.

=head2 repeats

How many times the position on the board has occurred in this game, this time
included.

=head2 ply

How many moves have been made, counting both sides'.

=head2 at

    my $piece = $game->at('d4');

C<attacker>, C<defender>, C<king>, or the empty string for an empty square.
C<undef> for something that is not the name of a square.

=head2 pieces

A hash reference from the name of every occupied square to what stands on it.

=head2 log

A copy of the moves made, as they are stored.

=head2 shown

A copy of the moves made, as they are shown: C<d1-d3xc3>, C<Kg2-g1++>.

=head2 seed

The seed the game was given, once the game is finished. C<undef> before then,
so that what a program will choose cannot be read off a game in progress.

=head2 search

    my $found = $game->search(budget => 20_000);
    my $found = $game->search(budget => 20_000, salt => $bytes, depth => 4);

    $game->play($found->{move}) if $found;

The move a search of that many positions thinks best for the side to move, or
C<undef> when the game is finished. The game is not changed.

The search B<never reads a clock>: its only limit is C<budget>, a count of
positions. The same game, budget and salt give the same move every time, on
any machine.

C<salt> is any string. It decides which move is chosen when the search scores
several alike, so that two programs given different salts do not play the same
game, and a program given the same salt plays the same game twice. C<depth>
stops the search after it has looked that many moves ahead. C<weights> changes
how a position is scored: see L<Game::Brandubh::Rules/weights>.

What comes back is a hash reference: C<move>, as it is stored; C<score>, for
the side to move; C<depth>, how far ahead the search finished looking;
C<nodes>, how many positions it looked at; and C<stopped>, true when the
budget ran out part way through looking one move further.

L<Game::Brandubh::Bot> is this with levels of play on top.

=head2 bot

    my $class = $game->bot;         # 'Game::Brandubh::Bot'

The class that plays this game.

=head2 replay

    my $game = Game::Brandubh->replay(attackers => 'p1', moves => \@moves);
    my ($game, $refused, $at) = Game::Brandubh->replay(moves => \@moves);

    my $again = $game->replay($game->log);

Builds a game and plays the moves into it. As a class method it takes what
C<new> takes, with C<moves> and, optionally, C<result>: C<< { how => 'resign',
by => 'attackers' } >> or C<< { how => 'agreed' } >>. As an object method it
starts from the same seats, rule set and position as the game it is called on.

In list context it returns the game, C<0> or the refusal that stopped it, and
how many moves were played. In scalar context it returns the game, or C<undef>
when a move was refused.

=head2 as_text

The game as text: its rule set, where it started when that was not the set-up,
its moves, and its ending when the players ended it. See
L<Game::Brandubh::Notation/A game>.

=head2 from_text

    my $game = Game::Brandubh->from_text($text, attackers => 'p2');

A game from that text. The seats are not part of the text and may be given
after it. Returns as C<replay> does.

=head1 SEE ALSO

L<Game::Brandubh::Variant>, L<Game::Brandubh::Result>, L<Game::Brandubh::Error>,
L<Game::Brandubh::Notation>.

L<Game::Brandubh::Rules> and L<Game::Brandubh::Engine> are what this class is
built on: a game and a position, in the numbers the compiled code uses.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-brandubh at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Brandubh>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Brandubh

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Brandubh>

=item * Search CPAN

L<https://metacpan.org/release/Game-Brandubh>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
