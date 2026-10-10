package Game::RoyalUr;

use 5.010;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Object::Proto::Sugar;

use Game::RoyalUr::Engine qw(EMPTY SIDE_LIGHT SIDE_DARK ROUTE_SHORT ROUTE_LONG piece_of);
use Game::RoyalUr::Rules;
use Game::RoyalUr::Variant;
use Game::RoyalUr::Dice ();
use Game::RoyalUr::Notation ();
use Game::RoyalUr::Error;
use Game::RoyalUr::Result;

our $VERSION = '0.01';

my $E = 'Game::RoyalUr::Engine';
my $X = 'Game::RoyalUr::Error';

my (%SIDE_OF, %ROUTE_OF, %OTHER);
BEGIN {
    %SIDE_OF  = (light => SIDE_LIGHT, dark => SIDE_DARK);
    %ROUTE_OF = (short => ROUTE_SHORT, long => ROUTE_LONG);
    %OTHER    = (light => 'dark', dark => 'light');
}

has _seed => (is => 'ro', init_arg => 'seed', private => 1);

has _rules_given => (is => 'ro', init_arg => 'rules', private => 1);

has _first_given => (is => 'ro', init_arg => 'first', private => 1);

has _position_given => (is => 'ro', init_arg => 'position', private => 1);

has _script => (is => 'ro', init_arg => 'script', private => 1);

has _variant => (is => 'rw', private => 1);

has _game => (is => 'rw', private => 1);

has _first => (is => 'rw', private => 1);

has _opening => (is => 'rw', private => 1);

has _rolls => (is => 'rw', private => 1);

has _roll => (is => 'rw', private => 1);

has _faces => (is => 'rw', private => 1);

has _number => (is => 'rw', private => 1);

has _log => (is => 'rw', private => 1);

has _choices => (is => 'rw', private => 1);

has _resigned => (is => 'rw', private => 1);

has _error => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    my ($seed, $script) = ($self->_seed, $self->_script);
    Carp::croak('Game::RoyalUr: a game wants a seed: some bytes that decide every throw of its dice')
        unless (defined $seed && !ref $seed && length $seed) || ref $script eq 'ARRAY';

    my $variant = Game::RoyalUr::Variant->of($self->_rules_given);
    $self->_variant($variant);

    my $position = $self->_position_given;
    if (defined $position) {
        my $code = Game::RoyalUr::Notation::validate_position($position);
        Carp::croak("Game::RoyalUr: the position was refused, code $code") if $code;
    }

    my $first = $self->_first_given;
    Carp::croak("Game::RoyalUr: first is 'light' or 'dark'")
        if defined $first && !exists $SIDE_OF{$first};

    my @opening;
    if (!defined $first && !defined $position) {
        Carp::croak('Game::RoyalUr: a game with no seed must be told who moves first') if $script;
        my ($side, $used, $throws) = Game::RoyalUr::Dice::opening_for($seed, $variant->dice);
        $first = $side;
        @opening = map { join '', @$_ } @$throws;
    }

    my $game = Game::RoyalUr::Rules->new(
        rules => $variant->as_hash,
        (defined $position ? (position => $position) : ()),
        (defined $first    ? (first    => $first)    : ()),
    );
    my $consistent = $game->board->consistent($variant->pieces);
    undef $game unless $consistent;
    Carp::croak('Game::RoyalUr: the position does not hold ' . $variant->pieces . ' pieces a side')
        unless $consistent;

    $self->_game($game);
    $self->_first($game->side);
    $self->_opening(\@opening);
    $self->_rolls(scalar @opening);
    $self->_log([]);
    $self->_choices([]);
    $self->_settle;
    return;
}

sub _settle {
    my ($self) = @_;
    my $game = $self->_game;
    my $variant = $self->_variant;
    $self->_roll(undef);
    $self->_faces(undef);
    $self->_number(undef);

    while (!$self->is_over) {
        my $number = $self->_rolls;
        my ($roll, $faces);
        if (my $script = $self->_script) {
            my $next = $script->[ $number - @{ $self->_opening } ];
            return unless $next;
            ($roll, $faces) = ($next->{roll}, $next->{faces});
        }
        else {
            my $throw = Game::RoyalUr::Dice::throw_for($self->_seed, $number, $variant->dice);
            $faces = join '', @$throw;
            $roll  = Game::RoyalUr::Dice::roll_of(Game::RoyalUr::Dice::marked($throw), $variant);
        }
        $self->_rolls($number + 1);

        if ($game->moves($roll)) {
            $self->_roll($roll);
            $self->_faces($faces);
            $self->_number($number);
            return;
        }

        push @{ $self->_log }, {
            ply => $game->ply, side => $game->side, throw => $number,
            roll => $roll, faces => $faces, move => undef,
        };
        $game->forfeit;
    }
    return;
}

sub _refuse {
    my ($self, $code, %detail) = @_;
    $self->_error($X->of($code, %detail));
    return undef;
}

my $cell_named = sub {
    my ($name) = @_;
    return -1 unless Game::RoyalUr::Notation::square_ok($name);
    return $E->cell_of(ord(substr $name, 0, 1) - ord('a'), substr($name, 1, 1) - 1);
};

sub _why_not {
    my ($self, $from, $to) = @_;
    my $game = $self->_game;
    my $variant = $self->_variant;
    my $side = $SIDE_OF{ $game->side };
    my $route = $ROUTE_OF{ $variant->route };
    my $board = $game->board;
    my $roll = $self->_roll;

    my $from_step = 0;
    if ($from eq 'hand') {
        return 'no_piece' unless $board->hand($side) > 0;
    }
    else {
        my $piece = $board->at($cell_named->($from));
        return 'no_piece' if $piece == EMPTY;
        return 'not_your_piece' if $piece != piece_of($side);
        $from_step = $E->route_step($route, $side, $cell_named->($from));
        return 'no_piece' unless $from_step;
    }

    my $length = $E->route_len($route);
    my $lands = $from_step + $roll;
    if ($to eq 'home') {
        return 'overshoot' if $lands > $length + 1;
        return 'wrong_distance' if $lands < $length + 1;
        return 'bad_move';
    }

    my $cell = $cell_named->($to);
    return 'wrong_distance' unless $lands <= $length && $E->route_cell($route, $side, $lands) == $cell;
    my $piece = $board->at($cell);
    return 'own_piece' if $piece == piece_of($side);
    return 'safe_rosette' if $piece != EMPTY && $variant->safe_rosettes && $E->is_rosette($cell);
    return 'bad_move';
}

sub play {
    my ($self, $what) = @_;
    $self->_error(undef);
    return $self->_refuse('game_over') if $self->is_over;
    return $self->_refuse('no_roll') unless defined $self->_roll;

    my ($from, $to);
    if (Scalar::Util::blessed($what) && $what->isa('Game::RoyalUr::Move')) {
        ($from, $to) = ($what->from, $what->to);
    }
    else {
        my ($parsed, $why) = Game::RoyalUr::Notation::parse_move($what);
        return $self->_refuse('bad_move', text => $what, why => $why) unless $parsed;
        ($from, $to) = @{$parsed}{qw(from to)};
    }

    my $game = $self->_game;
    my $roll = $self->_roll;
    my ($move) = grep { $_->from eq $from && $_->to eq $to } $game->moves($roll);
    return $self->_refuse($self->_why_not($from, $to), from => $from, to => $to, roll => $roll)
        unless $move;

    push @{ $self->_choices }, {
        depth => $game->depth, log => scalar @{ $self->_log },
        rolls => $self->_rolls, roll => $roll, faces => $self->_faces, number => $self->_number,
    };
    push @{ $self->_log }, {
        ply => $game->ply, side => $game->side, throw => $self->_number,
        roll => $roll, faces => $self->_faces, move => $from . '-' . $to,
        captures => $move->captures, rosette => $move->rosette, home => $move->home,
    };
    $game->apply($move);
    $self->_settle;
    return $move;
}

sub play_or_die {
    my ($self, $what) = @_;
    my $move = $self->play($what);
    return $move if $move;
    my $error = $self->_error;
    Carp::croak('Game::RoyalUr: ' . $error->code . ': ' . $error->message);
}

sub undo {
    my ($self) = @_;
    $self->_error(undef);
    if (defined $self->_resigned) {
        $self->_resigned(undef);
        return 1;
    }
    my $choice = pop @{ $self->_choices } or return 0;
    my $game = $self->_game;
    $game->undo while $game->depth > $choice->{depth};
    splice @{ $self->_log }, $choice->{log};
    $self->_rolls($choice->{rolls});
    $self->_roll($choice->{roll});
    $self->_faces($choice->{faces});
    $self->_number($choice->{number});
    return 1;
}

sub resign {
    my ($self, $side) = @_;
    $self->_error(undef);
    return 0 if $self->is_over;
    $side = $self->_game->side unless defined $side;
    Carp::croak("Game::RoyalUr: a side is 'light' or 'dark'") unless exists $SIDE_OF{$side};
    $self->_resigned($side);
    return 1;
}

sub is_over { defined $_[0]->_resigned || $_[0]->_game->is_over ? 1 : 0 }

sub result {
    my ($self) = @_;
    return undef unless $self->is_over;
    my $game = $self->_game;
    my $resigned = $self->_resigned;
    return Game::RoyalUr::Result->new(
        winner => (defined $resigned ? $OTHER{$resigned} : $game->winner),
        how    => (defined $resigned ? 'resign' : $game->how),
        final  => $game->position,
        home   => { light => $game->home('light'), dark => $game->home('dark') },
        plies  => $game->ply,
    );
}

sub error { $_[0]->_error }

sub side { $_[0]->is_over ? undef : $_[0]->_game->side }

sub roll { $_[0]->is_over ? undef : $_[0]->_roll }

sub throw {
    my ($self) = @_;
    my $faces = $self->is_over ? undef : $self->_faces;
    return defined $faces ? [ split //, $faces ] : undef;
}

sub legal {
    my ($self) = @_;
    my $roll = $self->roll;
    return wantarray ? () : 0 unless defined $roll;
    return $self->_game->moves($roll);
}

sub variant { $_[0]->_variant }

sub first { $_[0]->_first }

sub seed { $_[0]->_seed }

sub rolls { $_[0]->_rolls }

sub opening { [ map { [ split //, $_ ] } @{ $_[0]->_opening } ] }

sub ply { $_[0]->_game->ply }

sub position { $_[0]->_game->position }

sub key { $_[0]->_game->key }

sub hand { $_[0]->_game->hand($_[1]) }

sub home { $_[0]->_game->home($_[1]) }

sub at {
    my ($self, $name) = @_;
    my $cell = $cell_named->($name);
    Carp::croak("Game::RoyalUr: there is no square called '" . ($name // 'undef') . "'") if $cell < 0;
    my $piece = $self->_game->board->at($cell);
    return $piece == EMPTY ? undef : $piece == piece_of(SIDE_LIGHT) ? 'light' : 'dark';
}

sub chances {
    my ($self) = @_;
    my $variant = $self->_variant;
    return $E->chances($variant->dice, $variant->zero_rolls);
}

sub log { [ map { { %$_ } } @{ $_[0]->_log } ] }

sub forfeits_since {
    my ($self, $ply) = @_;
    $ply = 0 unless defined $ply;
    return map { { %$_ } } grep { !defined $_->{move} && $_->{ply} >= $ply } @{ $self->_log };
}

sub to_record {
    my ($self) = @_;
    my $variant = $self->_variant;
    my %record = (
        rules => (defined $variant->name ? $variant->name : $variant->as_hash),
        first => $self->_first,
        turns => [ map { {
            side => $_->{side}, roll => $_->{roll}, move => $_->{move},
            (defined $_->{faces} ? (faces => $_->{faces}) : ()),
        } } @{ $self->_log } ],
    );
    if (defined $self->_seed) {
        $record{seed} = unpack 'H*', $self->_seed;
        $record{opening} = scalar @{ $self->_opening } if @{ $self->_opening };
    }
    if (my $result = $self->result) {
        $record{result} = { winner => (defined $result->winner ? $result->winner : 'draw'), how => $result->how };
    }
    return Game::RoyalUr::Notation::format_record(\%record);
}

sub replay {
    my ($class, $record, %option) = @_;
    my $bad = sub { return (undef, $X->of('bad_record', @_)) };

    if (!ref $record) {
        my ($parsed, $problem) = Game::RoyalUr::Notation::parse_record($record);
        return $bad->(line => $problem->{line}, why => $problem->{error}) unless $parsed;
        $record = $parsed;
    }
    my @turns = @{ $record->{turns} || [] };
    my $opening = $record->{opening} || 0;
    my $rules = exists $option{rules} ? $option{rules} : $record->{rules};

    my $game;
    if (defined $record->{seed}) {
        $game = $class->new(
            seed  => pack('H*', $record->{seed}),
            rules => $rules,
            ($opening ? () : (first => $record->{first})),
        );
        return $bad->(ply => 0, why => 'opening')
            unless $game->first eq $record->{first} && @{ $game->opening } == $opening;
    }
    else {
        $game = $class->new(
            script => [ map { { roll => $_->{roll}, faces => $_->{faces} } } @turns ],
            rules  => $rules,
            first  => $record->{first},
        );
    }

    for my $i (0 .. $#turns) {
        my $turn = $turns[$i];
        my $made = $game->_log->[$i];
        if ($made) {
            return $bad->(ply => $i, why => 'move') if defined $turn->{move} || defined $made->{move};
            return $bad->(ply => $i, why => 'side') unless $made->{side} eq $turn->{side};
            return $bad->(ply => $i, why => 'roll') unless $made->{roll} == $turn->{roll};
            next;
        }
        return $bad->(ply => $i, why => 'over') if $game->is_over;
        return $bad->(ply => $i, why => 'forfeit') unless defined $turn->{move};
        return $bad->(ply => $i, why => 'side') unless $game->side eq $turn->{side};
        return $bad->(ply => $i, why => 'roll') unless defined $game->roll && $game->roll == $turn->{roll};
        unless ($game->play($turn->{move})) {
            my $error = $game->error;
            return (undef, $X->of($error->code, %{ $error->detail }, ply => $i));
        }
    }

    if (my $result = $record->{result}) {
        if ($result->{how} eq 'resign') {
            return $bad->(ply => scalar @turns, why => 'result') if $game->is_over;
            $game->resign($OTHER{ $result->{winner} });
        }
        else {
            my $ended = $game->result;
            my $winner = $ended && defined $ended->winner ? $ended->winner : 'draw';
            return $bad->(ply => scalar @turns, why => 'result')
                unless $ended && $ended->how eq $result->{how} && $winner eq $result->{winner};
        }
    }
    return ($game, undef);
}

1;

__END__

=head1 NAME

Game::RoyalUr - the Royal Game of Ur

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::RoyalUr;

    my $game = Game::RoyalUr->new(seed => 'any bytes at all');

    until ($game->is_over) {
        my @moves = $game->legal;          # never empty while the game is on
        printf "%s rolled %d\n", $game->side, $game->roll;
        $game->play($moves[0]) or die $game->error->message;
    }

    my $result = $game->result;
    print $result->winner, ' wins by ', $result->how, "\n";

    print $game->to_record;                # the whole game, as text

=head1 DESCRIPTION

The Royal Game of Ur is a race for two players on a board of twenty squares.
Each side has seven pieces, throws a handful of two-sided dice, and moves one
piece that many squares along a route that crosses the other side's. Landing
on an enemy piece sends it back to the start; landing on one of the five
rosettes earns another roll; the first side to bring every piece home wins.

The board is about 4,600 years old. B<The rules are not known.> Every set of
rules is a modern reconstruction, and this distribution plays two of them, by
name: C<finkel>, proposed by Irving Finkel of the British Museum, and
C<masters>, proposed by James Masters. L<Game::RoyalUr::Variant> says how they
differ.

It is the engine behind the Royal Game of Ur at L<https://peer2peergames.com>.

=head2 The dice come from a seed

A game is made with a seed, some bytes, and every throw of its dice follows
from them. Two games with the same seed and the same moves are the same game,
on any machine and at any time. Nothing here reads a clock or a random number
generator.

A seed decides the dice and so it decides the game: whoever knows it knows
every roll to come. C<seed> hands it back to whoever asks. A program that
plays for stakes keeps it away from its players.

=head2 A turn is a roll and then one move

Between calls, a game that is not over always has a side to move, a roll
already thrown for it, and at least one move that roll allows. C<roll> is
that roll, C<legal> is those moves, and C<play> makes one of them.

B<A caller never has to pass.> When a roll allows no move, a throw with
nothing marked or a roll with nowhere to go, the turn is lost by the game
itself and the next side throws, and so on until somebody has a choice. Those
lost turns are in the log, and C<forfeits_since> hands them over so that they
can be shown and not silently skipped.

A side with exactly one legal move still makes it. The game does not play for
a side that has a move.

=head2 Turns do not alternate

A piece that lands on a rosette earns its side another roll. Ask C<side>
after every move.

=head2 Squares and moves

The board is three rows of eight squares with four missing:

    3  a3 b3 c3 d3 .  .  g3 h3      dark's row
    2  a2 b2 c2 d2 e2 f2 g2 h2
    1  a1 b1 c1 d1 .  .  g1 h1      light's row

A move is written as two places with a dash between them: C<a2-d2>,
C<hand-b1> for a piece entering the board, C<g1-home> for one leaving it. See
L<Game::RoyalUr::Notation>.

=head1 THE GAME

=head2 The two rule sets

                          finkel               masters
    pieces a side         7                    7
    dice                  4                    3
    a throw of nothing    moves nothing        moves four
    the route             short, 14 steps      long, 16 steps
    squares shared        the 8 of row 2       12
    a rosette gives       another roll         another roll
    a piece on a rosette  cannot be captured   can be
    leaving the board     on the exact roll    on the exact roll

Under both, a side that can move must, a capture is allowed and never
compulsory, a piece passes over any piece in its way, and two pieces never
share a square.

=head2 The routes

A piece enters on the fourth square of its own row and walks toward the
corner. These are light's steps; dark's are the same with rows 1 and 3
exchanged. A dot is a square the route does not visit.

    finkel, the short route

    3   .   .   .   .           .   .
    2   5   6   7   8   9  10  11  12
    1   4   3   2   1          14  13
        a   b   c   d   e   f   g   h

    masters, the long route

    3   .   .   .   .          12  13
    2   5   6   7   8   9  10  11  14
    1   4   3   2   1          16  15
        a   b   c   d   e   f   g   h

The rosettes are C<a1>, C<g1>, C<a3>, C<g3> and C<d2>: steps 4, 8 and 14 of
the short route, and every fourth step of the long one.

On the short route the two sides meet only in row 2. On the long route each
side's last five steps run round the far end of the board through the other
side's row, so after its first four squares a piece is never out of reach.

=head2 Words

=over 4

=item light, dark

The two sides. Light's row is row 1 and dark's is row 3.

=item hand

A side's pieces that have not yet entered the board.

=item home

A side's pieces that have left the board at the end of their route.

=item step

A place on a side's route, counted from 1. The same square can be a
different step for each side.

=item throw, roll

A throw is the dice as they fell. A roll is what that is worth in steps.
They differ only where a throw with nothing marked is worth four.

=item rosette

One of the five marked squares.

=item capture

Landing on an enemy piece, which sends it back to its owner's hand.

=item forfeit

A turn lost to the roll: a roll of nothing, or a roll that allows no move.

=back

=head2 Where the rules come from

Three texts, read on 9 October 2026:

=over 4

=item *

Wikipedia, "Royal Game of Ur", revision 1378861936.

=item *

Masters Traditional Games, "The Rules / Instructions of The Royal Game of Ur",
by James Masters, which sets out his route and his rules beside R. C. Bell's
and Irving Finkel's.

=item *

RoyalUr.net, "Rules of the Royal Game of Ur", by Padraig Lamont.

=back

They do not agree about everything, and say nothing about some things. Two
readings are this distribution's own and are worth knowing. Where a source is
silent on whether a piece may pass over another, it may. And James Masters'
own page does not say whether his rosettes protect a piece; the other two
sources say they do not, and that is what C<masters> plays.

The same sources disagree about where Irving Finkel's rules come from: one
says he translated them from a cuneiform tablet, and another says the tablet
describes a more complicated game and that his rules were made to play well
on the boards that survive. Either way they are a reconstruction, made in the
twentieth century, of a game whose own rules are lost.

The short route under four dice has 275,827,872 positions, and has been
solved: RoyalUr.net publish the chance of winning from every one. This
distribution's board counts the same number, and on every position checked
(all of the two-piece game, and twenty thousand of the full one) its rules
agree with those published values to the last digit they are stored to. Under perfect play the
side that moves first wins 51.54 games in a hundred.

=head1 METHODS

=head2 new

    my $game = Game::RoyalUr->new(seed => $bytes);
    my $game = Game::RoyalUr->new(seed => $bytes, rules => 'masters', first => 'dark');

=over 4

=item C<seed>

Any non-empty string of bytes. Required, unless C<script> is given.

=item C<rules>

C<'finkel'> or C<'masters'>, a L<Game::RoyalUr::Variant>, or a hash reference
of the fields that differ from C<finkel>. C<'finkel'> when it is left out.

=item C<first>

C<'light'> or C<'dark'>: the side that moves first. B<When it is left out the
two sides throw for it>, with the seed's own dice: the side with more dice
marked moves first, and a tie is thrown again. Those throws are the game's
first, and C<opening> returns them.

=item C<position>

A position to start from, as a string. The side to move is the position's
unless C<first> names another, and there is no opening throw.

=item C<script>

In place of a seed: the rolls themselves, in order, as a reference to an
array of C<< { roll => ..., faces => ... } >>, the faces optional. This is a
game played with real dice. It needs C<first> or C<position>, since there are
no dice to throw for it, and when the rolls run out it has no roll and no
moves until it is made again with more.

=back

B<Croaks> with neither a seed nor a script, and on rules, a side or a position it will not
take.

=head2 side

C<'light'> or C<'dark'>: the side to move. C<undef> once the game is over.

=head2 roll

What the side to move has rolled, 1 to 4. C<undef> once the game is over. It
is the same however often it is asked: the dice are thrown once a turn.

=head2 throw

The dice behind that roll, as a reference to an array with a 1 for each
marked die and a 0 for each unmarked one, so that they can be drawn.

=head2 legal

    my @moves = $game->legal;

The moves the roll allows, as L<Game::RoyalUr::Move> objects. Never empty
while the game is on; empty once it is over. In scalar context, how many.

=head2 play

    my $move = $game->play('a2-d2') or warn $game->error->message;
    my $move = $game->play($moves[0]);

Makes a move, given as text or as one of the objects C<legal> returned, and
returns it. The next roll is thrown, and any turns it loses are lost, before
C<play> returns.

A move that is not legal returns C<undef>, B<changes nothing>, not the board,
not the roll and not the dice, and leaves the reason in C<error>.

=head2 play_or_die

As C<play>, and B<croaks> with the reason where C<play> would have returned
C<undef>.

=head2 error

The L<Game::RoyalUr::Error> from the last C<play> that was refused, and
C<undef> after one that was not.

=head2 undo

Takes back the last move, and with it any turns that were lost after it, so
that the game is as it was when that move was chosen: the same side, the same
roll. True when something was taken back. A resignation is taken back first.

=head2 resign

    $game->resign;             # the side to move
    $game->resign('dark');

Ends the game in favour of the other side. True when done, false when the
game was already over.

=head2 is_over

True once the game has been won, drawn or resigned.

=head2 result

A L<Game::RoyalUr::Result> once the game is over, and C<undef> until then.

=head2 position

The position as a string. See L<Game::RoyalUr::Engine/to_string>.

=head2 key

Twelve hexadecimal characters that stand for the position.

=head2 at

    my $who = $game->at('d2');     # 'light', 'dark' or undef

What stands on a square. B<Croaks> on a name that is not a square.

=head2 hand

    my $waiting = $game->hand('light');

How many of a side's pieces have not yet entered the board.

=head2 home

    my $finished = $game->home('dark');

How many of a side's pieces have come home.

=head2 ply

How many moves and lost turns have been made.

=head2 rolls

How many times the dice have been thrown, the opening throws and the throw
for the turn in progress included.

=head2 first

C<'light'> or C<'dark'>: the side that moved first.

=head2 opening

The throws that decided who moves first, in order, light's and then dark's
and so on, each as C<throw> returns one. Empty when the game was told.

=head2 variant

The game's L<Game::RoyalUr::Variant>.

=head2 seed

The seed the game was made with.

=head2 chances

    my @chances = $game->chances;

What the game's dice can roll and how often, as
L<Game::RoyalUr::Engine/chances> returns it.

=head2 log

Everything that has happened, in order, as a reference to an array of hash
references, one a ply:

    { ply => 3, side => 'light', throw => 5, roll => 4, faces => '1111',
      move => 'a2-e2', captures => 0, rosette => 0, home => 0 }

C<throw> is the number of the throw, counted through the whole game. A turn
lost to the roll has C<< move => undef >>. The log is a copy.

=head2 forfeits_since

    my @lost = $game->forfeits_since($ply);

The log's entries for turns lost to the roll at or after a ply, so that a
caller who last looked at ply C<$ply> can say what happened in between.

=head2 to_record

The whole game as text, in the form L<Game::RoyalUr::Notation> describes: the
rules, who moved first, the seed, and every turn with its dice.

=head2 replay

    my ($game, $error) = Game::RoyalUr->replay($text);
    my ($game, $error) = Game::RoyalUr->replay($record, rules => 'masters');

A game rebuilt from a record, as text or as the structure
L<Game::RoyalUr::Notation/parse_record> returns, and C<undef>; or C<undef>
and a L<Game::RoyalUr::Error> whose detail names the ply at which the record
stopped describing a game.

Every move in the record is played, so a record the rules do not allow is
refused at the move that breaks them. With a seed, every roll is thrown again
and must be the roll the record says. Without one the record's rolls are
taken as written, which is how a game played with real dice is replayed;
such a game can be read but not played on, because nobody can say what would
have been rolled next.

C<rules> replays the record under another rule set than its own.

=head1 SEE ALSO

L<Game::RoyalUr::Variant>, the rule sets. L<Game::RoyalUr::Notation>, moves
and records as text. L<Game::RoyalUr::Rules>, a game without its dice.
L<Game::RoyalUr::Engine>, the board. L<Game::RoyalUr::Dice>, the dice.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-royalur at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-RoyalUr>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::RoyalUr

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-RoyalUr>

=item * Search CPAN

L<https://metacpan.org/release/Game-RoyalUr>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
