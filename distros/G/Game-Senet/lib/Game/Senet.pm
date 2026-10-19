package Game::Senet;

use 5.010;
use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Object::Proto::Sugar;

use Game::Senet::Engine qw(EMPTY LIGHT DARK SIDE_LIGHT SIDE_DARK piece_of);
use Game::Senet::Rules;
use Game::Senet::Variant;
use Game::Senet::Sticks ();
use Game::Senet::Notation ();
use Game::Senet::Error;
use Game::Senet::Result;

our $VERSION = '0.02';

my $E = 'Game::Senet::Engine';
my $X = 'Game::Senet::Error';

my (%SIDE_OF, %OTHER, %SEATS);
BEGIN {
    %SIDE_OF = (light => SIDE_LIGHT, dark => SIDE_DARK);
    %OTHER   = (light => 'dark', dark => 'light', p1 => 'p2', p2 => 'p1');
    %SEATS   = (p1 => 1, p2 => 1);
}

has _light_seat => (is => 'ro', init_arg => 'light', private => 1, default => 'p1');

has _seed => (is => 'ro', init_arg => 'seed', private => 1);

has _rules_given => (is => 'ro', init_arg => 'rules', private => 1);

has _first_given => (is => 'ro', init_arg => 'first', private => 1);

has _position_given => (is => 'ro', init_arg => 'position', private => 1);

has _start => (is => 'rw', private => 1);

has _script => (is => 'ro', init_arg => 'script', private => 1);

has _variant => (is => 'rw', private => 1);

has _game => (is => 'rw', private => 1);

has _first => (is => 'rw', private => 1);

has _throws => (is => 'rw', private => 1);

has _roll => (is => 'rw', private => 1);

has _sticks => (is => 'rw', private => 1);

has _legal => (is => 'rw', private => 1);

has _number => (is => 'rw', private => 1);

has _log => (is => 'rw', private => 1);

has _choices => (is => 'rw', private => 1);

has _resigned => (is => 'rw', private => 1);

has _error => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    my ($seed, $script) = ($self->_seed, $self->_script);
    Carp::croak('Game::Senet: a game wants a seed: some bytes that decide every throw of its sticks')
        unless (defined $seed && !ref $seed && length $seed) || ref $script eq 'ARRAY';
    Carp::croak("Game::Senet: light is played by seat 'p1' or 'p2'")
        unless defined $self->_light_seat && $SEATS{ $self->_light_seat };

    my $variant = Game::Senet::Variant->of($self->_rules_given);
    $self->_variant($variant);

    my $first = $self->_first_given;
    Carp::croak("Game::Senet: first is 'light' or 'dark'")
        if defined $first && !exists $SIDE_OF{$first};

    my $position = $self->_position_given;
    if (defined $position) {
        my $code = Game::Senet::Notation::validate_position($position);
        Carp::croak("Game::Senet: the position was refused, code $code") if $code;
        my ($pieces) = $position =~ / (\d)\z/;
        Carp::croak("Game::Senet: the position has $pieces pieces a side and the rules " . $variant->pieces)
            unless $pieces == $variant->pieces;
        $position =~ s/ [ld] (\d)\z/' ' . substr($first, 0, 1) . " $1"/e if defined $first;
    }
    $self->_start($position);

    my $game = Game::Senet::Rules->new(
        rules => $variant->as_hash,
        (defined $position ? (position => $position) : (first => $first // 'light')),
    );
    $self->_game($game);
    $self->_first($game->side);
    $self->_throws(0);
    $self->_log([]);
    $self->_choices([]);
    $self->_settle;
    return;
}

sub _next_throw {
    my ($self, $number) = @_;
    if (my $script = $self->_script) {
        my $next = $script->[$number];
        return unless defined $next;
        return (ref $next ? $next->{roll} : $next, ref $next ? $next->{sticks} : undef);
    }
    my $sticks = Game::Senet::Sticks::throw_for($self->_seed, $number);
    return (Game::Senet::Sticks::roll_of(Game::Senet::Sticks::light_of($sticks)), join '', @$sticks);
}

sub _settle {
    my ($self) = @_;
    my $game = $self->_game;
    $self->_roll(undef);
    $self->_sticks(undef);
    $self->_number(undef);
    $self->_legal([]);

    while (!$self->is_over) {
        my $number = $self->_throws;
        my ($roll, $sticks) = $self->_next_throw($number);
        return unless defined $roll;
        $self->_throws($number + 1);

        my @moves = $game->moves($roll);
        if (@moves) {
            $self->_legal(\@moves);
            $self->_roll($roll);
            $self->_sticks($sticks);
            $self->_number($number);
            return;
        }

        my $side = $game->side;
        my $ply = $game->ply;
        $game->forfeit($roll);
        push @{ $self->_log }, {
            ply => $ply, side => $side, throw => $number, roll => $roll, sticks => $sticks,
            move => undef, again => ($game->side eq $side ? 1 : 0),
        };
    }
    return;
}

sub _refuse {
    my ($self, $code, %detail) = @_;
    $self->_error($X->of($code, %detail));
    return undef;
}

sub _why_not {
    my ($self, $from, $to) = @_;
    my $game = $self->_game;
    my $variant = $self->_variant;
    my $board = $game->board;
    my $roll = $self->_roll;
    my $side = $SIDE_OF{ $game->side };
    my $me = piece_of($side);
    my $enemy = piece_of($side == SIDE_LIGHT ? SIDE_DARK : SIDE_LIGHT);
    my $rules = $E->rules($variant->as_hash);
    my @legal = $game->moves($roll);

    my $piece = $board->at($from);
    return 'no_piece' if $piece == EMPTY;
    return 'not_your_piece' if $piece != $me;
    return 'bound_piece' if $game->only && $from != $game->only;

    if ($from >= 26) {
        my @chain = @{ $rules->{exits}{$from}{$roll} };
        return 'no_back' if $to ne 'off' && $to == $from - $roll;
        return 'no_exit' if !@chain || $chain[0] eq 'stay';
        my %target;
        for my $entry (@chain) {
            if    ($entry eq 'off')  { $target{off} = 1 }
            elsif ($entry eq 'walk') { $target{$_} = 1 for 1 .. 15 }
            elsif ($entry ne 'stay') { $target{$entry} = 1 }
        }
        return 'wrong_distance' unless $target{$to};
        return 'no_exit' unless grep { $_->from == $from } @legal;
        return 'own_piece' if $to ne 'off' && $board->at($to) == $me;
        return 'safe_house' if $to ne 'off' && $board->at($to) == $enemy;
        return 'wrong_distance';
    }

    my $any = $variant->reach26 eq 'any' && $from == 25;
    my $forward = $from + $roll;
    my $back = $from - $roll;
    return 'wrong_distance' if $to eq 'off';
    my $is_back = $to == $back;
    return 'wrong_distance' unless $to == $forward || $is_back || ($any && $to == 26);

    if ($is_back) {
        return 'forward_first' if grep { !$_->back } @legal;
        return 'no_back' unless $variant->backward;
    }
    elsif ($to > 26) {
        return 'must_land_26';
    }

    my ($lo, $hi) = $from < $to ? ($from, $to) : ($to, $from);
    if ($variant->blockade) {
        for my $x ($lo + 1 .. $hi - 1) {
            next unless $board->at($x) == $enemy;
            my ($first, $last) = ($x, $x);
            $first-- while $first > 1 && $board->at($first - 1) == $enemy;
            $last++ while $last < 30 && $board->at($last + 1) == $enemy;
            return 'blockade' if $last - $first + 1 >= $variant->blockade;
        }
    }
    my $there = $board->at($to);
    return 'own_piece' if $there == $me;
    if ($there == $enemy) {
        return 'safe_house' if grep { $_ == $to } @{ $rules->{safe} };
        return 'protected';
    }
    return 'bad_move';
}

sub play {
    my ($self, $what) = @_;
    $self->_error(undef);
    return $self->_refuse('game_over') if $self->is_over;

    my ($from, $to);
    my $object = Scalar::Util::blessed($what) && $what->isa('Game::Senet::Move');
    if ($object) {
        ($from, $to) = ($what->from, $what->off ? 'off' : $what->to);
    }
    else {
        my ($parsed, $why) = Game::Senet::Notation::parse_move($what);
        return $self->_refuse('bad_move', text => $what, why => $why) unless $parsed;
        ($from, $to) = @{$parsed}{qw(from to)};
    }
    return $self->_refuse('no_roll') unless defined $self->_roll;

    my $game = $self->_game;
    my $roll = $self->_roll;
    my $wire = $from . '-' . $to;
    my ($move) = grep { Game::Senet::Notation::format_move($_) eq $wire } @{ $self->_legal };
    $move = undef if $move && $object && ($what->roll != $roll || $what->side ne $game->side);
    return $self->_refuse($self->_why_not($from, $to), from => $from, to => $to, roll => $roll)
        unless $move;

    push @{ $self->_choices }, {
        depth => $game->depth, log => scalar @{ $self->_log },
        throws => $self->_throws, roll => $roll, sticks => $self->_sticks, number => $self->_number,
    };
    my $side = $game->side;
    my $ply = $game->ply;
    $game->apply($move);
    push @{ $self->_log }, {
        ply => $ply, side => $side, throw => $self->_number, roll => $roll, sticks => $self->_sticks,
        move => $wire, back => $move->back, swap => $move->swap, off => $move->off, walk => $move->walk,
        again => (!$game->is_over && $game->side eq $side ? 1 : 0),
    };
    $self->_settle;
    return $move;
}

sub play_or_die {
    my ($self, $what) = @_;
    my $move = $self->play($what);
    return $move if $move;
    my $error = $self->_error;
    Carp::croak('Game::Senet: ' . $error->code . ': ' . $error->message);
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
    $self->_throws($choice->{throws});
    $self->_roll($choice->{roll});
    $self->_sticks($choice->{sticks});
    $self->_number($choice->{number});
    $self->_legal([ $game->moves($choice->{roll}) ]);
    return 1;
}

sub resign {
    my ($self, $side) = @_;
    $self->_error(undef);
    return 0 if $self->is_over;
    $side = $self->_game->side unless defined $side;
    Carp::croak("Game::Senet: a side is 'light' or 'dark'") unless exists $SIDE_OF{$side};
    $self->_resigned($side);
    return 1;
}

sub is_over { defined $_[0]->_resigned || $_[0]->_game->is_over ? 1 : 0 }

sub result {
    my ($self) = @_;
    return undef unless $self->is_over;
    my $game = $self->_game;
    my $resigned = $self->_resigned;
    return Game::Senet::Result->new(
        winner => (defined $resigned ? $OTHER{$resigned} : $game->winner),
        how    => (defined $resigned ? 'resign' : $game->how),
        final  => $game->position,
        home   => { light => $game->home('light'), dark => $game->home('dark') },
        plies  => $game->ply,
        throws => $self->_throws,
    );
}

sub error { $_[0]->_error }

sub side { $_[0]->is_over ? undef : $_[0]->_game->side }

sub roll { $_[0]->is_over ? undef : $_[0]->_roll }

sub sticks {
    my ($self) = @_;
    my $sticks = $self->is_over ? undef : $self->_sticks;
    return defined $sticks ? [ split //, $sticks ] : undef;
}

sub throw {
    my ($self) = @_;
    my $roll = $self->roll;
    return undef unless defined $roll;
    return $roll == 5 ? 0 : $roll;
}

sub legal {
    my ($self) = @_;
    return wantarray ? () : 0 unless defined $self->roll;
    my @legal = @{ $self->_legal };
    return wantarray ? @legal : scalar @legal;
}

sub turn {
    my ($self) = @_;
    return undef if $self->is_over;
    my $side = $self->_game->side;
    my $segment = 1;
    for my $entry (reverse @{ $self->_log }) {
        last unless $entry->{side} eq $side && $entry->{again};
        $segment++;
    }
    my $roll = $self->_roll;
    return {
        side    => $side,
        segment => $segment,
        bound   => ($self->_game->only || undef),
        extra   => (defined $roll ? Game::Senet::Sticks::extra_throw($roll) : undef),
    };
}

sub side_of {
    my ($self, $seat) = @_;
    Carp::croak("Game::Senet: a seat is 'p1' or 'p2'") unless defined $seat && $SEATS{$seat};
    return $seat eq $self->_light_seat ? 'light' : 'dark';
}

sub seat_of {
    my ($self, $side) = @_;
    Carp::croak("Game::Senet: a side is 'light' or 'dark'") unless defined $side && exists $SIDE_OF{$side};
    return $side eq 'light' ? $self->_light_seat : $OTHER{ $self->_light_seat };
}

sub variant { $_[0]->_variant }

sub first { $_[0]->_first }

sub seed { $_[0]->_seed }

sub throws { $_[0]->_throws }

sub ply { $_[0]->_game->ply }

sub position { $_[0]->_game->position }

sub key { $_[0]->_game->key }

sub home { $_[0]->_game->home($_[1]) }

sub at {
    my ($self, $house) = @_;
    Carp::croak("Game::Senet: there is no house " . ($house // 'undef'))
        unless Game::Senet::Notation::house_ok($house);
    my $piece = $self->_game->board->at($house);
    return $piece == EMPTY ? undef : $piece == LIGHT ? 'light' : 'dark';
}

sub protected {
    my ($self, $house) = @_;
    Carp::croak("Game::Senet: there is no house " . ($house // 'undef'))
        unless Game::Senet::Notation::house_ok($house);
    return $self->_game->protected($house);
}

sub in_blockade {
    my ($self, $house) = @_;
    Carp::croak("Game::Senet: there is no house " . ($house // 'undef'))
        unless Game::Senet::Notation::house_ok($house);
    return $self->_game->in_blockade($house);
}

sub rules_revision { 1 }

sub chances {
    return map {
        my ($roll, $weight, $denominator) = @$_;
        { roll => $roll, throw => ($roll == 5 ? 0 : $roll), weight => $weight,
          denominator => $denominator, extra => Game::Senet::Sticks::extra_throw($roll) }
    } $E->chances;
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
        variant => { name => $variant->exits, map { $_ => $variant->$_ } grep { $_ ne 'exits' } $variant->fields },
        first   => $self->_first,
        plies   => [ map { {
            side => $_->{side}, roll => $_->{roll}, move => $_->{move},
            (defined $_->{sticks} ? (sticks => $_->{sticks}) : ()),
        } } @{ $self->_log } ],
    );
    $record{position} = $self->_start if defined $self->_start;
    $record{seed} = unpack 'H*', $self->_seed if defined $self->_seed;
    if (my $result = $self->result) {
        $record{result} = { winner => ($result->is_draw ? 'draw' : $result->winner), how => $result->how };
    }
    return Game::Senet::Notation::format_record(\%record);
}

sub replay {
    my ($class, $record, %option) = @_;
    my $bad = sub { return (undef, $X->of('bad_record', @_)) };

    if (!ref $record) {
        my ($parsed, $problem) = Game::Senet::Notation::parse_record($record);
        return $bad->(line => $problem->{line}, why => $problem->{error}) unless $parsed;
        $record = $parsed;
    }
    my @plies = @{ $record->{plies} || [] };
    my %fields = %{ $record->{variant} };
    my $exits = delete $fields{name};
    my $rules = $option{rules};
    unless (defined $rules) {
        return $bad->(ply => 0, why => 'variant') unless grep { $_ eq $exits } Game::Senet::Variant->names;
        $rules = Game::Senet::Variant->custom(exits => $exits, %fields);
    }

    my $game = defined $record->{seed}
        ? $class->new(seed => pack('H*', $record->{seed}), rules => $rules, first => $record->{first}, (defined $record->{position} ? (position => $record->{position}) : ()))
        : $class->new(script => [ map { { roll => $_->{roll}, sticks => $_->{sticks} } } @plies ],
                      rules => $rules, first => $record->{first}, (defined $record->{position} ? (position => $record->{position}) : ()));

    for my $i (0 .. $#plies) {
        my $ply = $plies[$i];
        if (my $made = $game->_log->[$i]) {
            return $bad->(ply => $i, why => 'forfeit') if defined $ply->{move} || defined $made->{move};
            return $bad->(ply => $i, why => 'side') unless $made->{side} eq $ply->{side};
            return $bad->(ply => $i, why => 'roll') unless $made->{roll} == $ply->{roll};
            next;
        }
        return $bad->(ply => $i, why => 'over') if $game->is_over;
        return $bad->(ply => $i, why => 'forfeit') unless defined $ply->{move};
        return $bad->(ply => $i, why => 'side') unless $game->side eq $ply->{side};
        return $bad->(ply => $i, why => 'roll') unless defined $game->roll && $game->roll == $ply->{roll};
        unless ($game->play($ply->{move})) {
            my $error = $game->error;
            return (undef, $X->of($error->code, %{ $error->detail }, ply => $i));
        }
    }
    return $bad->(ply => scalar @plies, why => 'length') if @{ $game->_log } > @plies;

    if (my $result = $record->{result}) {
        if ($result->{how} eq 'resign') {
            return $bad->(ply => scalar @plies, why => 'result') if $game->is_over;
            $game->resign($OTHER{ $result->{winner} });
        }
        else {
            my $ended = $game->result;
            my $winner = $ended ? ($ended->is_draw ? 'draw' : $ended->winner) : '';
            return $bad->(ply => scalar @plies, why => 'result')
                unless $ended && $ended->how eq $result->{how} && $winner eq $result->{winner};
        }
    }
    return ($game, undef);
}

sub to_text { $_[0]->to_record }

sub from_text {
    my ($class, $text) = @_;
    Carp::croak('Game::Senet: from_text wants the text to_text wrote, and was given '
        . (defined $text ? 'a reference' : 'nothing'))
        if !defined $text || ref $text;
    my ($game, $error) = $class->replay($text);
    return $game if $game;
    my $detail = $error->detail;
    my $where = $detail->{line} ? " at line $detail->{line}" : ' at ply ' . (($detail->{ply} // 0) + 1);
    Carp::croak('Game::Senet: the text was refused' . $where . ': ' . $error->message
        . (defined $detail->{why} ? " ($detail->{why})" : ''));
}

1;

__END__

=head1 NAME

Game::Senet - Senet, the Egyptian game of passing

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Game::Senet;

    my $game = Game::Senet->new(seed => 'any bytes at all');
    while (!$game->is_over) {
        printf "%s threw %s, worth %d\n", $game->side, join('', @{ $game->sticks }), $game->roll;
        my @moves = $game->legal;
        $game->play($moves[0]);
    }
    print $game->result->winner, " won\n";

    my $skyruk = Game::Senet->new(seed => 'other bytes', rules => 'skyruk');
    $skyruk->play('10-12') or print $skyruk->error->message, "\n";

=head1 DESCRIPTION

A game of Senet: thirty houses in three rows of ten, five pieces a side, four
throwing sticks, and one S-shaped track both sides share from the first throw.
Light stands on the even houses of the first row and dark on the odd, and light
throws first.

The sticks are thrown from a seed: the same seed gives the same game of throws
every time, and a game can be recorded and replayed exactly. Nothing here reads
a clock or a random number generator.

The rules are after Timothy Kendall's reconstruction of 1978, as modern sets
play it (C<kendall>, the default), or the reconstruction published with an
open-source implementation of the game (C<skyruk>). Nobody knows the original
rules. See L<Game::Senet::Variant>.

It is the engine behind the Senet at L<https://peer2peergames.com>.

=head2 A throw is not a roll

The four sticks land light or dark face up. The B<throw> is how many show
light, 0 to 4; the B<roll> is what that is worth in houses, 1 to 5: a throw of
none is a roll of 5. C<sticks> gives the sticks, C<throw> the count, C<roll> the
houses.

=head2 A turn is one throw or several

A roll of 1, 4 or 5 gives the side another throw, whatever was done with it,
even nothing. A 2 or 3 passes the sticks. Under C<skyruk> a piece that reaches
house 26 is thrown for again, alone. So turns do not alternate, and C<side>
says whose throw it is.

=head2 The game moves on by itself when it must

When a throw allows no move at all, the game records a forfeit and throws
again for whoever is next. A caller never sees a throw with nothing to play:
between calls the game is either over or C<legal> holds at least one move. A
throw with one legal move waits for C<play> like any other.

=head2 The board

The houses are numbered along the track, which runs as an S: left to right
along the top row, right to left along the middle, left to right along the
bottom, and off the board after house 30.

     1   2   3   4   5   6   7   8   9  10   >--.
                                                |
    20  19  18  17  16  15  14  13  12  11   <--'
    |                    +
    '-> 21  22  23  24  25  26  27  28  29  30   >  off
                             X   ~ III  II   I

The marked houses, with the sign the terminal draws for each:

    15  +    the House of Rebirth, where a piece from the water comes back
    26  X    the House of Happiness, which every piece must stand on
    27  ~    the House of Water
    28  III  the House of Three Truths, left on a roll of exactly 3
    29  II   the House of Re-Atoum, left on a roll of exactly 2
    30  I    the House of Horus

=head2 The sticks

    light faces up (the throw)    0    1    2    3    4
    houses moved (the roll)       5    1    2    3    4
    chance, in sixteenths         1    4    6    4    1
    throws again                 yes  yes   no   no  yes

=head2 Moving

A piece moves forward by the roll. It may not land on a piece of its own side.
Landing on a piece of the other side is a B<swap>: the two pieces exchange
houses. Wikipedia's account of Kendall's rules sends the piece landed on
backward to the first empty house instead; the sets played here swap, as the
other accounts do. A piece is B<protected>, and cannot be swapped, when it
stands in a run of its own side, and a run long enough is a B<blockade> no
piece of the other side may pass. When no piece can move forward, a piece must
move backward if one can. No piece passes house 26 without standing on it.

=head2 The two rule sets

                         kendall                  skyruk
    protected            every piece of a run     the first and the last
                         of two or more           of a run of two or more
    blockade             three in a row           two in a row
    reaching 26          on the exact roll        from 25, on any roll
    on reaching 26       nothing more             one more throw, for that
                                                  piece alone
    27, the water        back to 15 at once       stood on, and left by a
                                                  throw: 1 to 3 back to 15,
                                                  4 off, 5 stays
    30                   off on a roll of 1       off on any roll

Both start with five pieces a side, and C<pieces =E<gt> 7> gives seven.
L<Game::Senet::Variant> has every field.

C<kendall> is after Timothy Kendall's reconstruction (1978), as modern sets
play it. Kendall's own text is not quoted anywhere these rules were taken
from, and the accounts of it differ; where they do, the set follows the one
complete account. C<skyruk> is a reconstruction published with an open-source
implementation. A third account, called C<masters> after the site that gives
it, was not chosen as the second set, because it leaves out what happens
backward, in a run, and beyond house 26.

=head2 The words

A B<piece> stands on a B<house>. The two sides are B<light> and B<dark>.
The B<sticks> are thrown; the B<throw> is how many fell light face up and the
B<roll> what it is worth. A B<swap> exchanges two pieces; a B<run> is houses
held next to each other by one side; a piece leaving the board B<bears off>
and is B<home>. A throw that allows no move is a B<forfeit>.

=head2 Sources

The rules were taken on 17 Oct 2026 from: Wikipedia's article "Senet"
(revision 1375538342); the rules page of Masters Traditional Games; Catherine
Soubeyrand's page at The Game Cabinet, which gives Kendall's rules as Lhote
summarised them (1994); the README of the gym-senet project, which gives both
sets as a specification; and a Tabletop Simulator workshop item based on
Kendall's rules. Nobody knows how Senet was played when it was played.

=head1 CONSTRUCTOR

=head2 new

    my $game = Game::Senet->new(seed => $bytes, %options);

C<seed> is any non-empty string of bytes. The options:

=over 4

=item rules

A rule set: a name (C<kendall> or C<skyruk>), a hash of fields, or a
L<Game::Senet::Variant>. C<kendall> when not given.

=item first

C<light> (the default) or C<dark>: which side throws first. No source has dark
first; it is there for a caller who wants it.

=item light

C<p1> (the default) or C<p2>: the seat that plays light. See L</side_of>.

=item position

A position string to start from instead of the start, with as many pieces a
side as the rules. Its side to move is the one who throws first unless C<first>
is given.

=item script

The throws themselves, in place of a seed: a reference to an array of rolls,
or of C<< { roll, sticks } >>. For replaying a record with no seed.

=back

B<A key that is not one of these is ignored in silence>: C<rulez> plays
C<kendall>. A game with no seed and no script croaks.

=head1 METHODS

=head2 side

C<light> or C<dark>: whose throw it is. C<undef> once the game is over.

=head2 sticks

The four sticks in hand, each 1 for a light face, as an array reference.

=head2 throw

How many sticks show light, 0 to 4.

=head2 roll

What the throw is worth in houses, 1 to 5.

=head2 legal

The moves the throw allows, as L<Game::Senet::Move>s. Never empty while the game
goes on.

=head2 play

    $game->play('12-15') or die $game->error->message;
    $game->play($move);

Plays a move: a wire string (see L<Game::Senet::Notation>) or a move C<legal>
returned. A move is played if and only if C<legal> holds it. Returns the move,
or C<undef> with C<error> saying why not, having changed nothing.

=head2 play_or_die

As C<play>, croaking with the reason.

=head2 error

The L<Game::Senet::Error> of the last refusal, or C<undef>.

=head2 undo

Takes back the last move, and every forfeit the game made after it, to the
throw the move was made with. Or takes back a resignation. 0 when there is
nothing to take back.

=head2 resign

    $game->resign('dark');

Ends the game for a side, the side to move by default.

=head2 is_over

=head2 result

A L<Game::Senet::Result> once the game is over, C<undef> before.

=head2 turn

    my $turn = $game->turn;    # { side, segment, bound, extra }

Whose turn it is, which throw of the turn this is (1 for the first), the house
whose piece alone this throw may move or C<undef>, and whether this throw gives
another.

=head2 side_of

    my $side = $game->side_of('p2');

The side a seat plays.

=head2 seat_of

    my $seat = $game->seat_of('light');

The seat that plays a side.

=head2 variant

The rule set, a L<Game::Senet::Variant>.

=head2 first

The side that threw first.

=head2 seed

The seed, as given.

=head2 throws

How many throws have been made, the one in hand included.

=head2 ply

Moves and forfeits made.

=head2 position

The position string.

=head2 key

The position's key: sixteen hex characters.

=head2 home

    my $n = $game->home('light');

=head2 at

    my $who = $game->at(15);    # 'light', 'dark' or undef

=head2 protected

=head2 in_blockade

    print "safe from a swap\n"  if $game->protected(12);
    print "nobody passes it\n"  if $game->in_blockade(12);

Whether the piece on a house cannot be swapped, because it stands in a run of
its own side the rules protect, and whether it is part of a run the other side
may not pass. Each is 0 for an empty house, so a page can draw both and know
no rule. A house that is not 1 to 30 croaks.

=head2 rules_revision

    my $rev = Game::Senet->rules_revision;    # 1

A number that goes up when a release changes what a game does: a different
move allowed, refused or made, from the same seed. A game stored under one
revision is a different game under another. A release that changes nothing a
game does keeps the number, whatever its version.

=head2 chances

Each roll the sticks can make, with its throw, how many of the sixteen ways
four sticks fall make it, and whether it gives another throw.

=head2 log

Every move and forfeit, in order, each a hash: C<ply>, C<side>, C<throw> (its
number), C<roll>, C<sticks>, C<move> (the wire form, or C<undef> for a forfeit),
and C<again>, whether the same side threw next.

=head2 forfeits_since

    my @forfeits = $game->forfeits_since($ply);

The forfeits at or after a ply, from the log, so that a caller can say that a
side threw and could not move.

=head2 to_record

The game as a record (see L<Game::Senet::Notation>).

=head2 to_text

The same.

=head2 from_text

    my $game = Game::Senet->from_text($text);

The game a record describes, or a croak saying where it disagreed.

=head2 replay

    my ($game, $error) = Game::Senet->replay($record_or_text);
    my ($game, $error) = Game::Senet->replay($record, rules => 'skyruk');

Plays a record again through C<play>, throw by throw. Answers the game, or
C<undef> and an error naming the ply. With a seed every throw is thrown again
and checked; a record the rules no longer accept is refused where they part.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-senet at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Senet>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Senet

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Senet>

=item * Search CPAN

L<https://metacpan.org/release/Game-Senet>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
