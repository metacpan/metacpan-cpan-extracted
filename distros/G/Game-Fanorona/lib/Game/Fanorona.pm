package Game::Fanorona;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;

use Game::Fanorona::Engine qw(
    WHITE BLACK PAIKA APPROACH WITHDRAWAL
    WHY_OFF_BOARD WHY_BAD_STEP WHY_NO_STONE WHY_NOT_YOURS WHY_NO_LINE WHY_OCCUPIED
    WHY_TAKES_NOTHING WHY_NOT_A_PAIKA WHY_MUST_CAPTURE
    WHY_NOT_THE_STONE WHY_SAME_DIRECTION WHY_REVISIT WHY_PAIKA_IN_CHAIN
);
use Game::Fanorona::Rules qw(PLAY_OVER);
use Game::Fanorona::Move ();
use Game::Fanorona::Variant ();
use Game::Fanorona::Error ();
use Game::Fanorona::Result ();
use Game::Fanorona::Notation qw(
    parse_point parse_move format_move name_of square_of
    format_position format_game parse_game
);

our $VERSION = '0.01';

my @WORD = (undef, 'white', 'black');
my %SIDE = (white => WHITE, black => BLACK);
my %HOW  = (PAIKA, 'paika', APPROACH, 'approach', WITHDRAWAL, 'withdrawal');
my %LETTER = (PAIKA, '', APPROACH, 'A', WITHDRAWAL, 'W');

my %FROM_WHY = (
    WHY_OFF_BOARD,      'off_board',
    WHY_BAD_STEP,       'bad_move',
    WHY_NO_STONE,       'no_stone',
    WHY_NOT_YOURS,      'not_your_stone',
    WHY_NO_LINE,        'no_line',
    WHY_OCCUPIED,       'point_taken',
    WHY_TAKES_NOTHING,  'takes_nothing',
    WHY_NOT_A_PAIKA,    'bad_move',
    WHY_MUST_CAPTURE,   'must_capture',
    WHY_NOT_THE_STONE,  'not_the_stone',
    WHY_SAME_DIRECTION, 'same_direction',
    WHY_REVISIT,        'point_revisited',
    WHY_PAIKA_IN_CHAIN, 'paika_in_chain',
);

my %FROM_NOTATION = map { $_ => $_ } qw(off_board not_adjacent no_line paika_in_chain);

has _variant_given => (is => 'ro', init_arg => 'variant', private => 1);

has _start_given => (is => 'ro', init_arg => 'position', private => 1);

has _first_given => (is => 'ro', init_arg => 'first', private => 1);

has _script_given => (is => 'ro', init_arg => 'script', private => 1);

has _variant => (is => 'rw', private => 1);

has _rules => (is => 'rw', private => 1);

has _log => (is => 'ro', default => sub { [] }, private => 1);

has _pending => (is => 'rw', private => 1);

has _ended => (is => 'rw', private => 1);

has _offer => (is => 'rw', private => 1);

has _error => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;

    my $first = $self->_first_given;
    Carp::croak("Game::Fanorona: White moves first; first => '$first' is not a game of fanorona")
        if defined $first && $first ne 'white';

    my $given = $self->_variant_given;
    my $variant;
    if (!defined $given) {
        $variant = Game::Fanorona::Variant->named;
    }
    elsif (ref $given eq 'Game::Fanorona::Variant') {
        $variant = $given;
    }
    elsif (ref $given eq 'HASH') {
        $variant = Game::Fanorona::Variant->custom(%$given);
    }
    elsif (!ref $given) {
        $variant = Game::Fanorona::Variant->from_string($given);
        Carp::croak("Game::Fanorona: '$given' is not a variant") unless $variant;
    }
    else {
        Carp::croak('Game::Fanorona: a variant is a name, a hash of fields or a Game::Fanorona::Variant');
    }

    my $start = $self->_start_given;
    if (defined $start) {
        $variant = Game::Fanorona::Variant->custom(
            cols => $variant->cols, rows => $variant->rows, %{ $variant->limits }, start => $start,
        );
    }
    $self->_variant($variant);
    $self->_rules(Game::Fanorona::Rules->new(position => $variant->start, variant => $variant->limits));
    $self->_pending([]);

    my $script = $self->_script_given;
    if (defined $script) {
        Carp::croak('Game::Fanorona: a script is a list of moves') unless ref $script eq 'ARRAY';
        my $n = 0;
        for my $move (@$script) {
            $n++;
            next if $self->play($move);
            Carp::croak("Game::Fanorona: move $n of the script, '" . ($move // 'undef') . "', was refused: "
                . $self->error->message);
        }
    }
    return;
}

my $refuse = sub {
    my ($self, $code, $move) = @_;
    $self->_error(Game::Fanorona::Error->of($code, (defined $move ? (move => $move) : ())));
    return;
};

my $describe = sub {
    my ($s) = @_;
    my ($from, $to) = (name_of($s->{from}), name_of($s->{to}));
    return {
        from   => $from,
        to     => $to,
        how    => $HOW{ $s->{kind} },
        takes  => [ map { name_of($_) } @{ $s->{taken} } ],
        string => "$from-$to$LETTER{ $s->{kind} }",
    };
};

my $read = sub {
    my ($self, $move) = @_;
    my $text = ref $move ? format_move($move) : $move;
    my $variant = $self->_variant;
    my ($parsed, $why) = parse_move($text, cols => $variant->cols, rows => $variant->rows);
    return ($parsed, $text) if $parsed;
    $refuse->($self, $FROM_NOTATION{ $why // '' } // 'bad_move', $text);
    return;
};

my $take = sub {
    my ($self, $rules, $wanted, $text) = @_;
    my ($from, $dir, $kind) = @{$wanted}{qw(from dir kind)};
    my @there = grep { $_->{from} == $from && $_->{dir} == $dir } $rules->steps;
    if ($kind == PAIKA) {
        my @takes = grep { $_->{kind} != PAIKA } @there;
        return $refuse->($self, 'choose_capture', $text) if @takes > 1;
        $kind = $takes[0]{kind} if @takes == 1;
    }
    my ($step) = grep { $_->{kind} == $kind } @there;
    return $step if $step && $rules->step($from, $dir, $kind);
    $rules->step($from, $dir, $kind) unless $step;
    my $code = $rules->refused == PLAY_OVER ? 'game_over' : ($FROM_WHY{ $rules->why } // 'bad_move');
    return $refuse->($self, $code, $text);
};

my $run = sub {
    my ($self, $rules, $parsed, $text) = @_;
    my @made;
    for my $wanted (@{ $parsed->{steps} }) {
        my $step = $take->($self, $rules, $wanted, $text);
        if (!$step) {
            $rules->undo for @made;
            return;
        }
        push @made, $step;
    }
    $rules->stop if $rules->in_chain;
    return @made;
};

my $finish = sub {
    my ($self) = @_;
    my $steps = $self->_pending;
    my $mover = $WORD[ $steps->[0] ? $self->_rules->at($steps->[-1]{to}) : 0 ];
    push @{ $self->_log }, format_move({ from => $steps->[0]{from}, steps => $steps });
    $self->_pending([]);
    my $offer = $self->_offer;
    $self->_offer(undef) if defined $offer && defined $mover && $offer eq $mover;
    return;
};

sub variant { $_[0]->_variant }

sub over { ($_[0]->_ended || $_[0]->_rules->over) ? 1 : 0 }

sub turn {
    my ($self) = @_;
    return undef if $self->over;
    return $WORD[ $self->_rules->side ];
}

sub result {
    my ($self) = @_;
    my $ended = $self->_ended;
    return $ended if $ended;
    my $rules = $self->_rules;
    return undef unless $rules->over;
    return Game::Fanorona::Result->new(
        how      => $rules->how,
        winner   => $WORD[ $rules->winner ],
        position => $rules->position,
        moves    => $rules->ply,
    );
}

sub winner {
    my ($self) = @_;
    my $result = $self->result or return undef;
    return $result->winner;
}

sub error { $_[0]->_error }

sub position { $_[0]->_rules->position }

sub position_counted {
    my ($self) = @_;
    my $rules = $self->_rules;
    return format_position($rules->position, $rules->quiet, $rules->ply + 1);
}

sub signature   { $_[0]->_rules->key_hex }
sub ply         { $_[0]->_rules->ply }
sub quiet       { $_[0]->_rules->quiet }
sub quiet_limit { $_[0]->_rules->quiet_limit }
sub repeats     { $_[0]->_rules->repeats }
sub in_chain    { $_[0]->_rules->in_chain }

sub chain_at {
    my ($self) = @_;
    my $at = $self->_rules->chain_at;
    return $at < 0 ? undef : name_of($at);
}

sub at {
    my ($self, $name) = @_;
    my $variant = $self->_variant;
    my @point = parse_point($name, cols => $variant->cols, rows => $variant->rows);
    return undef unless @point;
    return $WORD[ $self->_rules->at(square_of($name)) ];
}

sub stones {
    my ($self, $side) = @_;
    return undef unless defined $side && $SIDE{$side};
    return $self->_rules->count($SIDE{$side});
}

sub moves { @{ $_[0]->_log } }

sub in_progress {
    my ($self) = @_;
    my $steps = $self->_pending;
    return undef unless @$steps;
    return format_move({ from => $steps->[0]{from}, steps => $steps });
}

sub steps {
    my ($self) = @_;
    return if $self->over;
    return map { $describe->($_) } $self->_rules->steps;
}

sub can_stop {
    my ($self) = @_;
    return 0 if $self->over;
    return $self->_rules->can_stop ? 1 : 0;
}

sub starts {
    my ($self) = @_;
    my %seen;
    return grep { !$seen{$_}++ } map { $_->{from} } $self->steps;
}

sub legal {
    my ($self, $limit) = @_;
    return if $self->over;
    return $self->_rules->moves($limit);
}

sub legal_strings {
    my ($self, $limit) = @_;
    return sort map { format_move($_) } $self->legal($limit);
}

sub step {
    my ($self, $string) = @_;
    $self->_error(undef);
    return $refuse->($self, 'game_over', $string) if $self->over;
    my ($parsed, $text) = $read->($self, $string) or return;
    return $refuse->($self, 'bad_move', $text) unless @{ $parsed->{steps} } == 1;
    my $step = $take->($self, $self->_rules, $parsed->{steps}[0], $text) or return;
    push @{ $self->_pending }, $step;
    $finish->($self) unless $self->_rules->in_chain;
    return $describe->($step);
}

sub stop {
    my ($self) = @_;
    $self->_error(undef);
    return $refuse->($self, 'game_over') if $self->over;
    return $refuse->($self, 'nothing_to_stop') unless $self->_rules->in_chain;
    $self->_rules->stop;
    $finish->($self);
    return 1;
}

sub play {
    my ($self, $move) = @_;
    $self->_error(undef);
    my $shown = ref $move ? format_move($move) : $move;
    return $refuse->($self, 'game_over', $shown) if $self->over;
    return $refuse->($self, 'chain_open', $shown) if $self->_rules->in_chain;
    my ($parsed, $text) = $read->($self, $move) or return;
    my @made = $run->($self, $self->_rules, $parsed, $text) or return;
    $self->_pending(\@made);
    $finish->($self);
    return Game::Fanorona::Move->new(from => $made[0]{from}, steps => [ @made ]);
}

sub preview {
    my ($self, $move) = @_;
    $self->_error(undef);
    my $shown = ref $move ? format_move($move) : $move;
    return $refuse->($self, 'game_over', $shown) if $self->over;
    return $refuse->($self, 'chain_open', $shown) if $self->_rules->in_chain;
    my ($parsed, $text) = $read->($self, $move) or return;
    my $rules = $self->_rules->clone;
    $run->($self, $rules, $parsed, $text) or return;
    return $rules->position;
}

sub continuations {
    my ($self, $prefix) = @_;
    $self->_error(undef);
    return $refuse->($self, 'game_over', $prefix) if $self->over;
    my $rules = $self->_rules->clone;
    my $complete = 0;
    if (defined $prefix && length $prefix) {
        my ($parsed, $text) = $read->($self, $prefix) or return;
        for my $wanted (@{ $parsed->{steps} }) {
            return $refuse->($self, 'bad_move', $text) if $complete;
            $take->($self, $rules, $wanted, $text) or return;
            $complete = 1 unless $rules->in_chain;
        }
    }
    return {
        complete => $complete,
        stop     => (!$complete && $rules->can_stop) ? 1 : 0,
        steps    => [ $complete ? () : map { $describe->($_) } $rules->steps ],
    };
}

my $end = sub {
    my ($self, $how, $winner) = @_;
    my $rules = $self->_rules;
    $self->_ended(Game::Fanorona::Result->new(
        how      => $how,
        (defined $winner ? (winner => $winner) : ()),
        position => $rules->position,
        moves    => $rules->ply,
    ));
    $self->_offer(undef);
    return 1;
};

my $other = sub { $_[0] eq 'white' ? 'black' : 'white' };

sub resign {
    my ($self, $side) = @_;
    $self->_error(undef);
    return $refuse->($self, 'game_over') if $self->over;
    return $refuse->($self, 'not_a_side') unless defined $side && $SIDE{$side};
    return $end->($self, 'resign', $other->($side));
}

sub offer_draw {
    my ($self, $side) = @_;
    $self->_error(undef);
    return $refuse->($self, 'game_over') if $self->over;
    return $refuse->($self, 'not_a_side') unless defined $side && $SIDE{$side};
    return $refuse->($self, 'offer_standing') if defined $self->_offer;
    $self->_offer($side);
    return 1;
}

my $answer = sub {
    my ($self, $side) = @_;
    $self->_error(undef);
    return $refuse->($self, 'game_over') if $self->over;
    return $refuse->($self, 'not_a_side') unless defined $side && $SIDE{$side};
    return $refuse->($self, 'no_offer') unless defined $self->_offer;
    return $refuse->($self, 'own_offer') if $self->_offer eq $side;
    return 1;
};

sub accept_draw {
    my ($self, $side) = @_;
    $answer->($self, $side) or return;
    return $end->($self, 'agreement');
}

sub decline_draw {
    my ($self, $side) = @_;
    $answer->($self, $side) or return;
    $self->_offer(undef);
    return 1;
}

sub draw_offered_by { $_[0]->_offer }

sub search {
    my ($self, %with) = @_;
    return undef if $self->over;
    my $found = $self->_rules->search(%with) or return undef;
    my $steps = delete $found->{steps};
    $found->{steps} = [ map { $describe->($_) } @$steps ];
    $found->{move} = @$steps ? format_move({ from => $steps->[0]{from}, steps => $steps }) : '';
    return $found;
}

sub evaluate {
    my ($self, $weights) = @_;
    return $self->_rules->evaluate($weights);
}

sub replay {
    my ($class, $moves, %arg) = @_;
    Carp::croak('Game::Fanorona: replay takes a list of moves') unless ref $moves eq 'ARRAY';
    my $game = $class->new(%arg);
    my $n = 0;
    for my $move (@$moves) {
        $n++;
        return ($game, $game->error, $n) unless $game->play($move);
    }
    return ($game, undef, undef);
}

sub as_text {
    my ($self, %extra) = @_;
    my $variant = $self->_variant;
    my $default = Game::Fanorona::Variant->named('telo')->limits;
    my %game = (variant => $variant->name, moves => [ $self->moves ]);
    $game{start} = $variant->start unless $variant->is_setup;
    for my $limit (qw(quiet_limit repeat ply_cap)) {
        $game{$limit} = $variant->$limit unless $variant->$limit == $default->{$limit};
    }
    for my $name (qw(white black)) {
        $game{$name} = $extra{$name} if defined $extra{$name};
    }
    my $result = $self->result;
    $game{result} = $result->how . (defined $result->winner ? ' ' . $result->winner : '') if $result;
    return format_game(\%game);
}

sub from_text {
    my ($class, $text) = @_;
    my ($parsed, $why, $line) = parse_game($text);
    return (undef, $why, $line) unless $parsed;
    my $variant = eval {
        Game::Fanorona::Variant->custom(
            cols => $parsed->{cols}, rows => $parsed->{rows},
            map { $_ => $parsed->{$_} } grep { defined $parsed->{$_} } qw(quiet_limit repeat ply_cap start),
        );
    };
    return (undef, 'bad_variant', 2) unless $variant;
    my ($game, $error, $n) = $class->replay($parsed->{moves}, variant => $variant);
    return (undef, $error->code, $parsed->{moves_at} + $n - 1) if $error;
    return ($game, undef, undef);
}

1;

__END__

=head1 NAME

Game::Fanorona - the board game of Madagascar: play it, and play it again

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Fanorona;

    my $game = Game::Fanorona->new;

    $game->play('d3-e3A') or die $game->error->message;
    print $game->turn, "\n";                     # black
    print join(' ', $game->legal_strings), "\n"; # c3-d3A c3-d3W d4-d3A f4-f3A

    # or a step at a time, which is how to offer a person a move
    for my $step ($game->steps) {
        print "$step->{string} takes @{ $step->{takes} }\n";
    }
    $game->step('c3-d3A');
    $game->stop if $game->can_stop;

    if (my $result = $game->result) {
        print $result->is_draw ? 'a draw' : $result->winner . ' won', "\n";
    }

=head1 DESCRIPTION

Fanorona is played on forty-five points joined by lines, nine across and five
up, with twenty-two stones a side and the centre empty. A stone steps along a
line to the next point. If that brings it up against an enemy stone straight
ahead, or takes it away from one straight behind, that stone and every enemy
stone in an unbroken line beyond it are taken. Taking is compulsory. A stone
that has taken may go on taking in the same move, never twice running in the
same direction and never back to a point it has stood on, and may stop when
it likes. The side that takes every stone wins.

This class is the game as a person or a program holds it: it speaks in point
names and move strings, refuses what is not legal without dying, knows when
the game has ended, keeps the moves so the game can be played again, and
handles the two things that are not moves, resigning and agreeing a draw.

Under it are L<Game::Fanorona::Rules>, L<Game::Fanorona::Engine> and
L<Game::Fanorona::Notation>, which say exactly what the rules are, which of
them are traditional and which are this distribution's own, and how a move is
written.

=head2 Sides and points

The sides are C<white> and C<black>. White moves first and starts on the two
ranks nearest it. A point is a file letter C<a> to C<i> and a rank digit C<1>
to C<5>.

=head2 A move and a step

A B<step> is one stone going to one adjacent point: C<b2-c2A>. A B<move> is
everything one side does before the other plays: C<b2-c2A-c3A>. The letter
after a point says the step that arrived there took, C<A> by approach and
C<W> by withdrawal.

C<play> makes a whole move. C<step> and C<stop> make it a step at a time. A
game can be driven either way, or both.

Reading B<a move of one step>, a step that takes may be written without its
letter where only one way of taking is possible there. Where both are, the
letter is needed, and the step is refused as C<choose_capture>. In a move of
two steps or more every step takes and every step must carry its letter.
Moves this class writes always carry the letter.

=head2 Offering a person a move

B<Do not list the moves.> There are usually about ten and can be thousands,
because a stone that could take four times running makes four moves, one for
each place it might stop. Offer C<steps> instead: the handful of single steps
that may come next. When one is taken, offer C<steps> again, and C<stop> where
C<can_stop> says so. C<starts> is the stones that can begin a move, and
C<continuations> answers the same question for a move that has not been made
yet.

=head2 Refusals

Nothing here dies because a move was not legal. C<play>, C<step>, C<stop>,
C<preview>, C<continuations>, C<resign> and the three draw calls return
nothing when they refuse, and leave an L<Game::Fanorona::Error> in C<error>.
A call that succeeds clears it.

=head1 CONSTRUCTORS

=head2 new

    my $game = Game::Fanorona->new;
    my $game = Game::Fanorona->new(variant => 'telo');
    my $game = Game::Fanorona->new(variant => { board => 'sivy', quiet_limit => 40 });
    my $game = Game::Fanorona->new(position => '9/9/2bw1b3/9/9 w');
    my $game = Game::Fanorona->new(script => [ 'd3-e3A', 'c3-d3W' ]);

=over 4

=item variant

A name, the one-line form L<Game::Fanorona::Variant/as_string> writes, a hash
of fields for L<Game::Fanorona::Variant/custom>, or a variant object. The
nine by five from its set-up when absent.

=item position

A position to begin from in place of the variant's own. It must be a position
of a board that size.

=item script

Moves to play at once. Croaks if one is refused.

=item first

May be given as C<white>, which is the only side that ever moves first.
Anything else croaks.

=back

Croaks on a variant that is not one or a position that will not load.

B<An argument name it does not know is not reliably noticed.> If it comes
first, every argument is read by position instead of by name and the call
usually croaks, complaining about something else. If it comes after a name
that is known, it is dropped in silence. Check the spelling of C<variant>,
C<position>, C<script> and C<first>.

=head2 replay

    my ($game, $error, $n) = Game::Fanorona->replay(\@moves, variant => 'telo');

A game with the moves played, through the same door C<play> uses. If one is
refused the game is returned as far as it got, with the refusal and the
number of the move, counting from 1. Takes the arguments C<new> takes.

=head2 from_text

    my ($game, $why, $line) = Game::Fanorona->from_text($text);

A game from the text C<as_text> writes. On failure the game is C<undef>, and
C<$why> is a word: one of L<Game::Fanorona::Notation/parse_game>'s if the
text is malformed, or an L<Game::Fanorona::Error> code if a move in it was
refused; C<$line> is the line at fault.

The C<result> line of a text is a record and is not replayed: a game that
ended by resignation or agreement comes back as its moves left it.

=head1 METHODS

=head2 play

    my $move = $game->play('b2-c2A-c3A') or warn $game->error->message;

Plays a whole move, given as a string or as a L<Game::Fanorona::Move>, and
returns it as a L<Game::Fanorona::Move>. If the move ends where its stone
could have gone on, that is a stop and is part of the move.

If any step of it is refused, nothing is played.

=head2 step

    my $step = $game->step('b2-c2A') or warn $game->error->message;

Plays one step and returns it described, as C<steps> describes one. The move
is complete if the step took nothing, or took and left nothing that could
follow; otherwise the same side is still to move and C<can_stop> is true.

=head2 stop

Ends a move in progress. True, or nothing with C<nothing_to_stop> in C<error>.

=head2 steps

    for my $step ($game->steps) { ... }

The steps that may be made next, each a hash:

    {
        from   => 'b2',
        to     => 'c2',
        how    => 'approach',          # or 'withdrawal', or 'paika'
        takes  => [ 'd2', 'e2' ],      # nearest first; empty for a paika
        string => 'b2-c2A',            # what step() takes
    }

None once the game is over. A step that could take two ways is listed twice.

=head2 can_stop

True while a move is in progress and the game is not over.

=head2 starts

    my @points = $game->starts;

The points whose stones have a step to make.

=head2 continuations

    my $next = $game->continuations('b2-c2A');

What could follow a move so far, without making it:

    {
        steps    => [ ... ],     # as steps() gives them
        stop     => 1,           # the move so far could end here by choice
        complete => 0,           # the move so far ends here of itself
    }

With no argument it describes the game as it stands. A move so far is a legal
move exactly when C<complete> or C<stop> is true. Nothing, with C<error> set,
when the move so far cannot be made.

=head2 legal

    my @moves = $game->legal;
    my @moves = $game->legal($limit);

The whole legal moves, as L<Game::Fanorona::Move> objects. None once the game
is over or while a move is in progress. B<Croaks when there are more than the
limit>, which is 100,000 unless given: see "Offering a person a move".

=head2 legal_strings

The same as strings, sorted.

=head2 preview

    my $position = $game->preview('b2-c2A-c3A');

The position a whole move would leave, without playing it. Nothing, with
C<error> set, for a move that would be refused.

=head2 turn

C<white> or C<black>, the side to move; C<undef> once the game is over.

=head2 over

True once the game has ended, however it ended.

=head2 result

An L<Game::Fanorona::Result> once the game is over, and C<undef> before.

=head2 winner

C<white>, C<black>, or C<undef> for a draw or a game still going.

=head2 error

The last refusal, an L<Game::Fanorona::Error>, or C<undef> if the last call
that could refuse did not.

=head2 resign

    $game->resign('black');

Ends the game in favour of the other side. Either side may resign at any
time, its own move or not.

=head2 offer_draw

    $game->offer_draw('white');

Puts a draw on the table. Either side may, at any time, while no offer is
standing. An offer lapses when the side that made it completes a move.

=head2 accept_draw

    $game->accept_draw('black');

Ends the game as a draw by agreement. Only the side the offer was made to may
answer it.

=head2 decline_draw

Takes the offer off the table.

=head2 draw_offered_by

The side whose offer is standing, or C<undef>.

=head2 search

    my $found = $game->search(budget => 10_000);
    print "$found->{move}\n";

The move the side to move should make, by looking ahead; C<undef> once the
game is over. It is L<Game::Fanorona::Rules/search> with its steps described
as C<steps> describes them, and with C<move>, the steps as one string: a whole
move from between moves, the rest of the move from the middle of one, and the
empty string when the thing to do is stop. L<Game::Fanorona::Bot> is the
player built on this.

=head2 evaluate

The position scored for White with no looking ahead. See
L<Game::Fanorona::Rules/evaluate>.

=head2 moves

    my @strings = $game->moves;

Every whole move made, in order, as strings.

=head2 in_progress

The move being made, as far as it has got, as a string; C<undef> between
moves.

=head2 as_text

    my $text = $game->as_text(white => 'Rakoto', black => 'Rasoa');

The game as text: the variant, anything about it that is not the default, the
names if given, the result if there is one, and the moves. See
L<Game::Fanorona::Notation/"A game">.

=head2 position

The position as it stands, as L<Game::Fanorona::Engine> writes it.

=head2 position_counted

The same with the two counts of a game in progress after it: the quiet moves
running, and the number of the move about to be made.

=head2 at

    $game->at('e3')

C<white>, C<black>, or C<undef> for an empty point or a name that is not a
point of this board.

=head2 stones

    $game->stones('black')

How many stones a side has.

=head2 ply

Whole moves completed.

=head2 quiet

How many of them, running up to now, took nothing.

=head2 quiet_limit

How many that may be before the game is drawn.

=head2 repeats

How many times the present position has occurred.

=head2 in_chain

True while a move is in progress.

=head2 chain_at

The point of the stone in the middle of its move, or C<undef>.

=head2 signature

Sixteen hex characters that are the same for the same stones on the same
points with the same side to move, and different otherwise.

=head2 variant

The L<Game::Fanorona::Variant> this game is played under.

=head1 WHOSE RULES THESE ARE

Fanorona has no governing body and no single rule book. The rules played here
were taken from two texts, read in October 2026:

=over 4

=item *

the article "Fanorona" in the English Wikipedia, revision 1375518715 of 18
September 2026;

=item *

Schadd, Winands, Uiterwijk, van den Herik and Bergsma, "Best Play in Fanorona
Leads to Draw", New Mathematics and Natural Computation 4(3), 2008, the paper
that solved the game.

=back

Both give the board, the set-up of the nine by five, the step, the two ways
of taking, that taking is compulsory, that a step which could take both ways
takes one of them at the mover's choice, and the chain with its two limits.
Where they are silent, or where a program needs a number they do not give,
this distribution chose, and says so:

=over 4

=item A side that cannot move has lost

No traditional source says what happens. The paper had to decide and decided
this, and so does this distribution. A game ended this way reports
C<no_moves>.

=item The third time a position occurs, the game is drawn

The paper gives repetition as how a draw comes about and gives no count.
Three is the count here, the position compared between moves and with the
same side to move. It can be changed, or turned off, in a
L<Game::Fanorona::Variant>.

=item Sixty moves running that take nothing, and the game is drawn

B<This is not a traditional rule.> Without it a game between two players who
cannot finish does not end. Sixty counts the moves of both sides, was chosen
by playing games and not derived from anything, and may change in a later
version. It too belongs to the variant.

=item The set-ups of the two smaller boards are derived

The texts read give the set-up of the nine by five only. The five by five and
the three by three are set up here by carrying its pattern down:
L<Game::Fanorona::Variant> draws them. The three by three set up this way is
a win for White with best play, which is what the paper reports for that
board.

=back

Two things some descriptions of the game have are not here. No rule limits
the first move: neither text has one. And the I<vela>, the handicap game that
the loser of a game is given before the next, is not played.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-fanorona at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Fanorona>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
