package Game::Fanorona::Rules;

use 5.014;
use strict;
use warnings;

use Carp ();
use Exporter 'import';
use Object::Proto::Sugar;

use Game::Fanorona::Engine ();
use Game::Fanorona::Move ();

our $VERSION = '0.01';

use constant {
    ONGOING         => 0,
    BY_STONES       => 1,
    BY_NO_MOVES     => 2,
    DRAW_REPETITION => 3,
    DRAW_QUIET      => 4,
    DRAW_PLY_CAP    => 5,
};

use constant {
    PLAY_OK      => 0,
    PLAY_OVER    => 1,
    PLAY_ILLEGAL => 2,
};

our @EXPORT_OK = qw(
    ONGOING BY_STONES BY_NO_MOVES DRAW_REPETITION DRAW_QUIET DRAW_PLY_CAP
    PLAY_OK PLAY_OVER PLAY_ILLEGAL
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my @HOW = (undef, 'stones', 'no_moves', 'repetition', 'quiet', 'ply_cap');

my %LIMIT = map { $_ => 1 } qw(quiet_limit repeat ply_cap);

has _ptr => (is => 'rw', private => 1);

has _hold => (is => 'rw', private => 1);

has _want_position => (is => 'ro', init_arg => 'position', private => 1);

has _want_board => (is => 'ro', init_arg => 'board', private => 1);

has _want_variant => (is => 'ro', init_arg => 'variant', private => 1);

has _refused => (is => 'rw', private => 1, default => 0);

has _reason => (is => 'rw', private => 1, default => 0);

my %ADOPTING;

sub BUILD {
    my ($self) = @_;
    my $given = $self->_ptr;
    if ($given) {
        if (delete $ADOPTING{$given}) {
            $self->_hold(_hold_game($given));
            return;
        }
        $self->_ptr(0);
        Carp::croak("Game::Fanorona::Rules: a game is made by new or clone");
    }

    my $position = $self->_want_position;
    my $name = $self->_want_board;
    Carp::croak("Game::Fanorona::Rules: give a position or a board, not both")
        if defined $position && defined $name;
    if (!defined $position) {
        $name = 'sivy' unless defined $name;
        my ($cols, $rows) = Game::Fanorona::Engine->size_of($name);
        Carp::croak("Game::Fanorona::Rules: no board is called '$name'") unless $cols;
        $position = Game::Fanorona::Engine->new(cols => $cols, rows => $rows)->to_string;
    }

    my $variant = $self->_want_variant;
    my %limit = (quiet_limit => -1, repeat => -1, ply_cap => -1);
    if (defined $variant) {
        Carp::croak("Game::Fanorona::Rules: a variant is a hash reference")
            unless ref $variant eq 'HASH';
        for my $key (sort keys %$variant) {
            Carp::croak("Game::Fanorona::Rules: no limit is called '$key'") unless $LIMIT{$key};
            my $value = $variant->{$key};
            Carp::croak("Game::Fanorona::Rules: $key is a whole number, 0 or more")
                unless defined $value && $value =~ /\A[0-9]+\z/;
            $limit{$key} = $value;
        }
    }

    my $ptr = _new_game($position, @limit{qw(quiet_limit repeat ply_cap)});
    Carp::croak("Game::Fanorona::Rules: the position was refused") unless $ptr;
    $self->_ptr($ptr);
    $self->_hold(_hold_game($ptr));
    return;
}

sub clone {
    my ($self) = @_;
    my $ptr = _copy_game($self->_ptr);
    $ADOPTING{$ptr} = 1;
    return ref($self)->new(_ptr => $ptr);
}

my $step = sub {
    my ($raw) = @_;
    my ($from, $to, $dir, $kind, @taken) = @$raw;
    return { from => $from, to => $to, dir => $dir, kind => $kind, taken => \@taken };
};

my $triple = sub {
    return @{ $_[0] }{qw(from dir kind)} if ref $_[0] eq 'HASH';
    return @_[0 .. 2];
};

my $board = sub { _game_board($_[0]->_ptr) };

sub position  { Game::Fanorona::Engine::_to_string($board->($_[0])) }
sub side      { Game::Fanorona::Engine::_side($board->($_[0])) }
sub at        { Game::Fanorona::Engine::_at($board->($_[0]), $_[1]) }
sub count     { Game::Fanorona::Engine::_count($board->($_[0]), $_[1]) }
sub key_hex   { Game::Fanorona::Engine::_key_hex($board->($_[0])) }
sub in_chain  { Game::Fanorona::Engine::_chain_at($board->($_[0])) >= 0 ? 1 : 0 }
sub chain_at  { Game::Fanorona::Engine::_chain_at($board->($_[0])) }

sub ply     { _game_ply($_[0]->_ptr) }
sub quiet   { _game_quiet($_[0]->_ptr) }
sub depth   { _game_depth($_[0]->_ptr) }
sub repeats { _game_repeats($_[0]->_ptr) }

sub quiet_limit { (_game_variant($_[0]->_ptr))[0] }
sub repeat      { (_game_variant($_[0]->_ptr))[1] }
sub ply_cap     { (_game_variant($_[0]->_ptr))[2] }

sub key_at {
    my ($self, $ply) = @_;
    return undef if !defined $ply || $ply !~ /\A[0-9]+\z/ || $ply > _game_ply($self->_ptr);
    return _game_key_hex($self->_ptr, $ply);
}

sub history {
    my ($self) = @_;
    my $ptr = $self->_ptr;
    return map { _game_key_hex($ptr, $_) } 0 .. _game_ply($ptr);
}

sub outcome { _game_outcome($_[0]->_ptr) }
sub over    { _game_outcome($_[0]->_ptr) != ONGOING ? 1 : 0 }
sub how     { $HOW[ _game_outcome($_[0]->_ptr) ] }
sub winner  { _game_winner($_[0]->_ptr) }

sub is_draw {
    my $outcome = _game_outcome($_[0]->_ptr);
    return $outcome >= DRAW_REPETITION ? 1 : 0;
}

sub steps {
    my ($self) = @_;
    my @raw = _game_steps($self->_ptr);
    return wantarray ? map { $step->($_) } @raw : scalar @raw;
}

sub can_stop { _game_can_stop($_[0]->_ptr) }

sub step {
    my $self = shift;
    my ($answer, $why) = _game_step($self->_ptr, $triple->(@_));
    $self->_refused($answer);
    $self->_reason($why);
    return $answer == PLAY_OK ? 1 : 0;
}

sub stop {
    my ($self) = @_;
    my $answer = _game_stop($self->_ptr);
    $self->_refused($answer);
    $self->_reason(0);
    return $answer == PLAY_OK ? 1 : 0;
}

sub refused { $_[0]->_refused }
sub why     { $_[0]->_reason }

sub undo { _game_undo($_[0]->_ptr) }

sub undo_move {
    my ($self) = @_;
    my $ptr = $self->_ptr;
    return 0 unless _game_depth($ptr);
    my $ply = _game_ply($ptr);
    my $open = Game::Fanorona::Engine::_chain_at(_game_board($ptr)) >= 0;
    my $target = $open ? $ply : $ply - 1;
    while (_game_depth($ptr)) {
        _game_undo($ptr);
        last if _game_ply($ptr) == $target
            && Game::Fanorona::Engine::_chain_at(_game_board($ptr)) < 0;
    }
    return 1;
}

sub moves {
    my ($self, $limit) = @_;
    return if $self->over || $self->in_chain;
    my ($engine) = Game::Fanorona::Engine->of_string($self->position);
    return $engine->moves($limit);
}

sub play_move {
    my ($self, $move) = @_;
    return 0 if $self->over || $self->in_chain;
    my $made = 0;
    for my $s (@{ $move->steps }) {
        if (!$self->step($s)) {
            my ($refused, $why) = ($self->_refused, $self->_reason);
            $self->undo for 1 .. $made;
            $self->_refused($refused);
            $self->_reason($why);
            return 0;
        }
        $made++;
    }
    return 0 unless $made;
    $self->stop if $self->in_chain;
    return 1;
}

sub live { _games_live() }

my @WEIGHT = qw(stone strong centre room);

sub weights {
    my %weight;
    @weight{@WEIGHT} = _weights_default();
    return \%weight;
}

my $weights = sub {
    my ($given) = @_;
    my $all = weights();
    return @{$all}{@WEIGHT} unless defined $given;
    Carp::croak('Game::Fanorona::Rules: weights are a hash reference') unless ref $given eq 'HASH';
    for my $key (sort keys %$given) {
        Carp::croak("Game::Fanorona::Rules: no weight is called '$key'") unless exists $all->{$key};
        Carp::croak("Game::Fanorona::Rules: the weight $key is a whole number")
            unless defined $given->{$key} && $given->{$key} =~ /\A-?[0-9]{1,6}\z/;
        $all->{$key} = $given->{$key};
    }
    return @{$all}{@WEIGHT};
};

sub evaluate {
    my ($self, $given) = @_;
    return _game_evaluate($self->_ptr, $weights->($given));
}

sub search {
    my ($self, %with) = @_;
    my %known = map { $_ => 1 } qw(budget seed depth weights);
    for my $key (sort keys %with) {
        Carp::croak("Game::Fanorona::Rules: search takes budget, seed, depth and weights, not '$key'")
            unless $known{$key};
    }
    my $budget = defined $with{budget} ? $with{budget} : 10_000;
    my $seed   = defined $with{seed}   ? $with{seed}   : 1;
    my $depth  = defined $with{depth}  ? $with{depth}  : 0;
    Carp::croak('Game::Fanorona::Rules: a budget is a whole number of positions, from 1 up')
        unless !ref $budget && $budget =~ /\A[0-9]{1,9}\z/ && $budget >= 1;
    Carp::croak('Game::Fanorona::Rules: a seed is a whole number below 4,294,967,296')
        unless !ref $seed && $seed =~ /\A[0-9]{1,10}\z/ && $seed <= 4_294_967_295;
    Carp::croak('Game::Fanorona::Rules: a depth is a whole number of moves, 0 for no limit')
        unless !ref $depth && $depth =~ /\A[0-9]{1,3}\z/;

    my ($found, $nodes, $done, $score, $stopped, $from, @pairs)
        = _game_search($self->_ptr, $budget, $seed, $depth, $weights->($with{weights}));
    return undef unless $found;

    my $copy = $self->clone;
    my @steps;
    while (@pairs) {
        my ($dir, $kind) = splice @pairs, 0, 2;
        my ($s) = grep { $_->{from} == $from && $_->{dir} == $dir && $_->{kind} == $kind } $copy->steps;
        Carp::croak('Game::Fanorona::Rules: the search chose a step that is not one') unless $s && $copy->step($s);
        push @steps, $s;
        $from = $s->{to};
    }
    return {
        steps   => \@steps,
        stop    => ($copy->in_chain || !@steps) ? 1 : 0,
        nodes   => $nodes,
        depth   => $done,
        score   => $score,
        stopped => $stopped ? 1 : 0,
    };
}

sub win_score { _win_score() }

1;

__END__

=head1 NAME

Game::Fanorona::Rules - a game of fanorona: a position, its history, and how it ends

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Fanorona::Rules ':all';

    my $game = Game::Fanorona::Rules->new;

    until ($game->over) {
        my @steps = $game->steps;
        $game->step($steps[0]);
        $game->stop if $game->can_stop;
    }

    print $game->how, "\n";            # stones, no_moves, repetition, quiet
    print $game->winner, "\n";         # 1 for White, 2 for Black, 0 for a draw

=head1 DESCRIPTION

A board with the moves that made it. Where L<Game::Fanorona::Engine> will
make any step it is given and plays on after the last stone is taken, a game
B<refuses> a step that is not legal and B<stops> when it has ended.

=head2 A move is complete when the turn passes

After a step that takes nothing; after C<stop>; and after a step that takes
and leaves nothing that could follow. Only then is the move counted, the
position written into the history, and the game judged. A step in the middle
of a chain changes the board and nothing else.

=head2 How a game ends

Asked in this order once a move is complete, because one move can satisfy two.

=over 4

=item stones

A side has no stones left. The other side has won.

=item no_moves

The side to move has stones and no legal move. B<It has lost.> No traditional
source says what happens here; this follows the one published analysis of the
game that had to decide, and no game in thirty thousand played while this was
being written reached it.

=item repetition

The same position, with the same side to move, has occurred for the third
time. A draw. Positions are compared between moves only: the middle of a
chain is not a position. The sources give repetition as how a draw comes
about and do not give the count; three is this distribution's.

=item quiet

Sixty moves running, both sides counted, have taken nothing. A draw. B<This
is not a traditional rule.> It is here because a game between two players who
cannot finish would otherwise not end, and the number is provisional.

=item ply_cap

Three thousand moves. A draw, and a guard only: with the quiet limit above, a
game cannot be that long.

=back

Agreeing a draw and resigning are not here. They are something two people do,
and the caller records them.

=head2 The limits

    my $game = Game::Fanorona::Rules->new(variant => { quiet_limit => 40 });

C<quiet_limit>, C<repeat> and C<ply_cap>. A C<quiet_limit> or a C<repeat> of
0 turns that draw off, which working out what a position is worth by force
needs. The cap cannot be turned off. The limits are set when the game is made
and do not change.

=head1 CONSTRUCTORS

=head2 new

    my $game = Game::Fanorona::Rules->new;
    my $game = Game::Fanorona::Rules->new(board => 'telo');
    my $game = Game::Fanorona::Rules->new(position => $string, variant => \%limits);

A game from the set-up of a board, or from a position string. The starting
position is judged at once, so a game begun with one side stoneless or stuck
is over before a step is made.

Croaks on a board that is not one, a position that will not load, a position
and a board together, or a limit that is not one.

=head2 clone

A second game with the same position, history and limits, sharing nothing
with the first.

=head1 METHODS

=head2 steps

    my @steps = $game->steps;

The steps the side to move may make, each the hash
L<Game::Fanorona::Engine/"A step"> describes. None once the game is over. In
scalar context, how many.

=head2 can_stop

True when a chain is open and the game is not over: the mover may end the
move here.

=head2 step

    $game->step($step) or warn $game->why;
    $game->step($from, $dir, $kind);

Plays a step and returns true, or refuses, changes nothing and returns false.
After a refusal C<refused> says whether the game was over or the step was
illegal, and C<why> gives the reason for an illegal one.

=head2 stop

Ends a move whose chain is open and returns true. False, with nothing
changed, when no chain is open or the game is over.

=head2 refused

C<PLAY_OK> after a step or stop that was made, C<PLAY_OVER> after one refused
because the game had ended, C<PLAY_ILLEGAL> after one refused because it was
not legal.

=head2 why

After an illegal step, the reason: one of the C<WHY_> values of
L<Game::Fanorona::Engine/play_why>. 0 otherwise.

=head2 undo

Takes back the last step or stop, with the counts and the outcome as they
were. Returns false when there is nothing to take back.

=head2 undo_move

Takes back a whole move: the steps of the move in progress if a chain is
open, and otherwise the last completed move. Returns false when there is
nothing to take back.

=head2 depth

How many steps and stops C<undo> could take back.

=head2 moves

    my @moves = $game->moves;

The whole moves of the side to move, as L<Game::Fanorona::Move> objects. None
when the game is over or a chain is open. Takes the limit
L<Game::Fanorona::Engine/moves> takes, and croaks past it as that does.

=head2 play_move

    $game->play_move($move) or warn $game->why;

Plays a whole move, each step through C<step> and then a C<stop> if the chain
is still open. Returns true. If any step is refused, the steps already made
are taken back and it returns false, with C<refused> and C<why> saying which
refusal it was.

=head2 over

True once the game has ended.

=head2 outcome

C<ONGOING>, C<BY_STONES>, C<BY_NO_MOVES>, C<DRAW_REPETITION>, C<DRAW_QUIET> or
C<DRAW_PLY_CAP>.

=head2 how

The same as a word: C<stones>, C<no_moves>, C<repetition>, C<quiet>,
C<ply_cap>; C<undef> while the game goes on.

=head2 winner

The side that won, as the engine numbers them, 1 for White and 2 for Black;
0 for a draw or a game still going.

=head2 is_draw

True when the game ended without a winner.

=head2 ply

Whole moves completed.

=head2 quiet

How many of them, running up to now, took nothing.

=head2 repeats

How many times the present position has occurred, this time included.

=head2 key_at

    my $key = $game->key_at($ply);

The key of the position after that many moves, or C<undef> for a number the
game has not reached.

=head2 history

The keys of every position between moves, the starting one first.

=head2 quiet_limit

=head2 repeat

=head2 ply_cap

The limits this game was made with.

=head2 position

The position string of the board as it stands.

=head2 side

The side to move.

=head2 at

=head2 count

=head2 key_hex

As L<Game::Fanorona::Engine>'s, of the game's board.

=head2 in_chain

True while a move is in progress.

=head2 chain_at

The point of the stone in the middle of its move, or -1.

=head2 search

    my $found = $game->search(budget => 10_000, seed => 1);

The move the side to move should make, by looking ahead. C<undef> when the
game is over. The game is not changed.

    {
        steps   => [ ... ],   # the steps to make, each as steps() gives them
        stop    => 1,         # a stop is needed after them to end the move
        nodes   => '9984',    # positions looked at
        depth   => 4,         # whole moves it looked ahead and finished
        score   => 100,       # for the side to move
        stopped => 1,         # the budget ran out part way through a deeper look
    }

From the middle of a chain it answers the rest of that move; C<steps> is then
empty when the best thing to do is stop.

=over 4

=item budget

How many positions it may look at: 10,000 unless given. It may be passed by
a few, and a budget too small for one look at every move is passed by that
much. B<It is a count and not a time>:
the same position, budget and seed give the same move on every machine.

=item seed

Settles the choice among moves of equal score, and nothing else.

=item depth

Whole moves to look ahead; 0, the default, for no limit but the budget.

=item weights

A hash of the evaluation's weights that differ from the defaults.

=back

A depth is counted in whole moves, so a chain of five steps is one. At the end
of its depth the search does not score a position in which a stone can be
taken: it plays the largest captures out, each side in turn, and scores what
is left. That is a guess at how the exchange comes out, not a search of it.

A score of C<win_score> less a little is a win that has been seen to its end.

=head2 evaluate

    my $score = $game->evaluate;
    my $score = $game->evaluate({ room => 3 });

The position scored B<for White>, with no looking ahead: positive is good for
White. A stone is worth a hundred. By default each empty point a stone could
step to is worth two more, and each step it stands nearer the centre two
more.

=head1 CLASS METHODS

=head2 weights

    my $weights = Game::Fanorona::Rules->weights;

The evaluation's weights and their defaults, as a hash reference: C<stone>,
for each stone on the board; C<strong>, for each stone on a point with
diagonals; C<centre>, for each step a stone stands nearer the middle; and
C<room>, for each empty point a stone could step to. C<strong> is 0 by
default: it helped by itself and not beside the other two.

=head2 win_score

The score of a win. A win some steps away scores that many less.

=head2 live

How many games exist that have not been destroyed.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
