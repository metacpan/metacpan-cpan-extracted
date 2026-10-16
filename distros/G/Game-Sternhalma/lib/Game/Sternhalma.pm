package Game::Sternhalma;

use 5.014;
use strict;
use warnings;

use Object::Proto::Sugar;

use Game::Sternhalma::Engine qw(:all);
use Game::Sternhalma::Error ();
use Game::Sternhalma::Layout ();
use Game::Sternhalma::Notation ();
use Game::Sternhalma::Result ();

our $VERSION = '0.01';

our %REASON = (
    bad_string       => 'that is not a move',
    no_such_hole     => 'that names a hole the star does not have',
    no_piece         => 'there is no piece there',
    not_your_piece   => 'that piece is not yours to move',
    must_pass        => 'you have no move, and must pass',
    occupied         => 'a piece is standing there',
    not_reachable    => 'that piece cannot get there this turn',
    pass_not_allowed => 'you have a move, so you may not pass',
    no_such_seat     => 'the game has no such seat',
    seat_finished    => 'that seat is home already',
    seat_resigned    => 'that seat has resigned already',
    game_over        => 'the game is over',
);

my %HOW = (BY_HOME, 'home', BY_CAP, 'cap', BY_DEADLOCK, 'deadlock', BY_RESIGN, 'resign');

has _want_seats => (is => 'ro', init_arg => 'seats', private => 1, default => 2);

has _want_pieces => (is => 'ro', init_arg => 'pieces', private => 1, default => 10);

has _want_first => (is => 'ro', init_arg => 'first', private => 1);

has _want_position => (is => 'ro', init_arg => 'position', private => 1);

has _start => (is => 'rw', private => 1);

has solo => (is => 'ro', default => 0);

has _want_cap => (is => 'ro', init_arg => 'cap', private => 1);

has _board => (is => 'rw', private => 1);

has _undo => (is => 'rw', private => 1);

has _moves => (is => 'rw', private => 1);

has _keys => (is => 'rw', private => 1);

has _movers => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    my $position = $self->_want_position;
    my $board;
    if (defined $position) {
        Game::Sternhalma::Error->throw(bad_first => 'a game from a position starts with its seat to move')
            if defined $self->_want_first;
        my ($read, $code) = Game::Sternhalma::Engine->from_string($position);
        Game::Sternhalma::Error->throw(bad_position => Game::Sternhalma::Engine->reason($code)) unless $read;
        my $why = Game::Sternhalma::Layout::why_not($read->seats, $read->pieces, $self->solo);
        Game::Sternhalma::Error->throw(bad_layout => $why) if defined $why;
        $board = $read;
        $self->_start($position);
    }
    else {
        my ($seats, $pieces) = ($self->_want_seats, $self->_want_pieces);
        my $why = Game::Sternhalma::Layout::why_not($seats, $pieces, $self->solo);
        Game::Sternhalma::Error->throw(bad_layout => $why) if defined $why;
        my $first = $self->_want_first // 0;
        Game::Sternhalma::Error->throw(bad_first => "the first seat must be 0 to " . ($seats - 1))
            unless $first =~ /\A[0-9]+\z/ && $first < $seats;
        $board = Game::Sternhalma::Engine->new(seats => $seats, pieces => $pieces);
        $board->set_to_move($first);
    }
    my $cap = $self->_want_cap;
    if (defined $cap) {
        Game::Sternhalma::Error->throw(bad_cap => 'the cap is a number of plies above 0')
            unless $cap =~ /\A[0-9]+\z/ && $cap > 0;
        $board->set_cap($cap);
    }
    $self->_board($board);
    $self->_undo([]);
    $self->_moves([]);
    $self->_keys([ map { [ $board->own_key($_) ] } 0 .. $board->seats - 1 ]);
    $self->_movers([]);
    return;
}

# ---- reading the game -------------------------------------------------------------------

sub seats         { $_[0]->_board->seats }
sub pieces        { $_[0]->_board->pieces }
sub first         { defined $_[0]->_start ? undef : $_[0]->_want_first // 0 }
sub start         { $_[0]->_start }
sub to_move       { $_[0]->_board->to_move }
sub over          { $_[0]->_board->over }
sub ply           { $_[0]->_board->ply }
sub cap           { $_[0]->_board->cap }
sub places        { $_[0]->_board->places }
sub position      { $_[0]->_board->to_string }
sub key           { $_[0]->_board->key }
sub board         { $_[0]->_board->clone }
sub distance_left { $_[0]->_board->distance_left($_[1]) }
sub at            { $_[0]->_board->at(Game::Sternhalma::Notation::hole_of($_[1]) // $_[1]) }

sub how {
    my ($self) = @_;
    return $self->over ? $HOW{ $self->_board->how } : undef;
}

sub finished {
    my ($self) = @_;
    my $bd = $self->_board;
    my @home = grep { $bd->finished($_) } 0 .. $self->seats - 1;
    return sort { $bd->place_of($a) <=> $bd->place_of($b) } @home;
}

sub result {
    my ($self) = @_;
    return undef unless $self->over;
    return Game::Sternhalma::Result->new(
        how => $self->how, places => [ $self->places ], ply => $self->ply, position => $self->position,
    );
}

sub legal {
    my ($self) = @_;
    my $bd = $self->_board;
    return () if $bd->over;
    return ({ kind => 'pass', text => 'pass' }) if $bd->can_pass;
    return map {
        my ($from, $to) = @$_;
        { kind => 'move', from => $from, to => $to, path => [ $bd->path($from, $to) ], text => $bd->move_text($from, $to) }
    } $bd->legal;
}

sub moves { @{ $_[0]->_moves } }

sub history {
    my ($self, $seat) = @_;
    $seat = $self->to_move unless defined $seat;
    my $k = $self->_keys->[$seat] or return;
    return @$k;
}

sub reason {
    my (undef, $flag) = @_;
    return defined $flag ? $REASON{$flag} : undef;
}

# ---- playing ------------------------------------------------------------------------------
#
# PLAY RETURNS A FLAG AND NEVER THROWS. Undef when the move was made; otherwise
# one name, one reason. A caller maps the names, and nothing here is a second
# opinion on the engine's.

sub play {
    my ($self, $move) = @_;
    my $flag = eval { $self->_play($move) };
    return $@ ? 'bad_string' : $flag;
}

sub _play {
    my ($self, $move) = @_;
    my $bd = $self->_board;
    return 'game_over' if $bd->over;
    my ($kind, $from, $to, $path, $seat) = _parse($move);
    return $kind if $kind ne 'move' && $kind ne 'pass' && $kind ne 'resign';
    return $self->_resign($seat) if $kind eq 'resign';
    if ($kind eq 'pass') {
        return 'pass_not_allowed' unless $bd->can_pass;
        my $mover = $bd->to_move;
        my ($why, $undo) = $bd->pass;
        return $self->_done($undo, 'pass', $mover);
    }
    my $piece = $bd->at($from);
    return 'no_piece' unless defined $piece;
    return 'not_your_piece' unless $piece == $bd->to_move;
    return 'must_pass' if $bd->can_pass;
    return 'occupied' if defined $bd->at($to);
    if ($path) {
        for my $i (1 .. $#$path) {
            return 'not_reachable' unless grep { $_ == $path->[$i] } $bd->hops($path->[ $i - 1 ], $from);
        }
    }
    my $text = $bd->move_text($from, $to);
    my $mover = $bd->to_move;
    my ($why, $undo) = $bd->play($from, $to);
    return 'not_reachable' unless $why == PLAY_OK;
    return $self->_done($undo, $text, $mover);
}

sub resign {
    my ($self, $seat) = @_;
    my $flag = eval { $self->_board->over ? 'game_over' : $self->_resign($seat) };
    return $@ ? 'no_such_seat' : $flag;
}

sub _resign {
    my ($self, $seat) = @_;
    my $bd = $self->_board;
    return 'no_such_seat' unless defined $seat && $seat =~ /\A[0-9]+\z/ && $seat < $self->seats;
    return 'seat_finished' if $bd->finished($seat);
    my ($why, $undo) = $bd->resign($seat);
    return 'seat_resigned' if $why == WHY_SEAT_DONE;
    return 'no_such_seat' unless $why == PLAY_OK;
    return $self->_done($undo, "resign $seat");
}

sub _done {
    my ($self, $undo, $text, $mover) = @_;
    push @{ $self->_undo }, $undo;
    push @{ $self->_moves }, $text;
    push @{ $self->_movers }, $mover;
    push @{ $self->_keys->[$mover] }, $self->_board->own_key($mover) if defined $mover;
    return undef;
}

# A move as text, a hash of holes or names, or a pass or resignation. Answers
# the kind and its parts, or a flag naming what is wrong with it.
sub _parse {
    my ($move) = @_;
    return ('bad_string') unless defined $move;
    if (ref $move) {
        return ('bad_string') unless ref $move eq 'HASH';
        my $kind = $move->{kind} // 'move';
        return ('pass') if $kind eq 'pass';
        return ('resign', undef, undef, undef, $move->{seat}) if $kind eq 'resign';
        return ('bad_string') unless $kind eq 'move';
        my ($from, $to) = map { _hole($_) } $move->{from}, $move->{to};
        return ('no_such_hole') unless defined $from && defined $to;
        return ('bad_string') if $from == $to;
        return ('move', $from, $to);
    }
    return ('bad_string') if length $move > 200;
    my $m = Game::Sternhalma::Notation::parse_move($move);
    unless ($m) {
        return ('bad_string') unless $move =~ /\A[a-z][0-9]+(?:[-:][a-z][0-9]+)+\z/;
        my @names = split /[-:]/, $move;
        return (grep { !defined Game::Sternhalma::Notation::hole_of($_) } @names) ? ('no_such_hole') : ('bad_string');
    }
    return ('pass') if $m->{kind} eq 'pass';
    return ('resign', undef, undef, undef, $m->{seat}) if $m->{kind} eq 'resign';
    my @h = @{ $m->{holes} };
    return ('move', $h[0], $h[-1], $m->{kind} eq 'chain' ? \@h : undef);
}

sub _hole {
    my ($h) = @_;
    return undef unless defined $h && !ref $h;
    return $h + 0 if $h =~ /\A[0-9]+\z/ && $h < HOLES;
    return Game::Sternhalma::Notation::hole_of($h);
}

sub undo {
    my ($self) = @_;
    my $undo = pop @{ $self->_undo } or return 0;
    pop @{ $self->_moves };
    my $mover = pop @{ $self->_movers };
    pop @{ $self->_keys->[$mover] } if defined $mover;
    return $self->_board->unplay($undo);
}

# ---- the log ---------------------------------------------------------------------------------

sub log {
    my ($self) = @_;
    return Game::Sternhalma::Notation::format_game({
        seats => $self->seats, pieces => $self->pieces, cap => $self->cap, first => $self->first // 0,
        (defined $self->_start ? (start => $self->_start) : ()),
        moves => [ $self->moves ],
    });
}

sub replay {
    my ($class, $text) = @_;
    my ($g, $why) = Game::Sternhalma::Notation::parse_game($text);
    Game::Sternhalma::Error->throw(bad_log => $why) unless $g;
    my $game = defined $g->{start}
        ? $class->new(position => $g->{start}, cap => $g->{cap})
        : $class->new(seats => $g->{seats}, pieces => $g->{pieces}, cap => $g->{cap}, first => $g->{first});
    my $n = 0;
    for my $move (@{ $g->{moves} }) {
        $n++;
        my $flag = $game->play($move);
        Game::Sternhalma::Error->throw(bad_log => "move $n, $move: " . $REASON{$flag}) if defined $flag;
    }
    return $game;
}

1;

__END__

=head1 NAME

Game::Sternhalma - star halma, the race across a six-pointed star known as Chinese checkers

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Sternhalma;

    my $game = Game::Sternhalma->new(seats => 3);

    until ($game->over) {
        my @moves = $game->legal;
        my $flag  = $game->play($moves[0]{text});
        die Game::Sternhalma->reason($flag) if defined $flag;
        last if $game->ply >= 6;
    }

    print $game->position, "\n";
    my $again = Game::Sternhalma->replay($game->log);
    print $again->key eq $game->key ? "the same game\n" : "a different game\n";

=head1 DESCRIPTION

Sternhalma is played on a star of 121 holes by two, three, four or six, each
with ten pieces starting in one point of the star and racing them into the
point opposite. A piece steps to a neighbouring empty hole, or hops over one
neighbouring piece, anyone's, into the empty hole straight beyond it, and may
go on hopping as long as it likes and stop when it likes. Nothing is taken.
The first seat home wins, and the others play on for second and third place.

It is the engine behind the Sternhalma at L<https://peer2peergames.com>.

=head2 WHOSE RULES THESE ARE

The board, the moves and the winner are the game's own, from the English and
German Wikipedia articles ("Chinese checkers", "Halma"). These are this
distribution's, because those say nothing:

=over 4

=item * A parked piece cannot stop you. A seat is home when every hole of its
home holds a piece and at least one of them is its own, so a rival who never
moves a piece out of your home does not keep you out, and a rival who fills
your last hole moves you home.

=item * A piece may stop in any hole, the points nobody plays from or to as
well.

=item * A seat with no move passes, and when every seat still racing has
passed in a row, the game ends.

=item * A game ends at a cap of moves and passes, 1,000 a seat unless asked
otherwise. At the cap, or when nobody can move, seats still racing are placed
by how far their pieces are from home.

=item * A seat that resigns is placed behind every seat that finished or is
still racing. Its pieces stay on the board.

=back

No game here can be shorter than George I. Bell's proofs allow ("The shortest
game of Chinese Checkers and related problems", INTEGERS 9, 2009): 27 moves
for one seat crossing alone, 30 for two seats.

=head1 CONSTRUCTOR

=head2 new

    Game::Sternhalma->new(seats => 2, pieces => 10, first => 0, cap => 2000)
    Game::Sternhalma->new(position => $string)

C<seats> is 2 (the default), 3, 4 or 6. C<pieces> is 10 (the default), or 15
for two or three seats. C<first> is the seat that moves first. C<cap> is the
ply the game ends at if it has not ended before.

With C<position>, the game starts from a position string (see
L<Game::Sternhalma::Notation>), which carries its own seats, pieces, seat to
move and game so far; C<first> cannot be given with it.

Dies with a L<Game::Sternhalma::Error> when no game can be made of what it
was given.

=head1 PLAYING

=head2 legal

    my @moves = $game->legal;

What the seat to move may do, each a hash: C<< { kind => 'move', from, to,
path, text } >>, where C<path> is every hole the move goes through and
C<text> is how it is written; or the one C<< { kind => 'pass' } >> when it has
no move. Empty when the game is over.

=head2 play

    my $flag = $game->play('e5:g5:g7');

Makes a move for the seat to move: text (a step C<e5-f5>, a chain
C<e5:g5:g7> or just its ends C<e5-g7>, C<pass>, C<resign 2>), or a hash
C<< { from, to } >> of hole numbers or names, or C<< { kind => 'pass' } >>.
Returns C<undef> when the move was made, and otherwise a flag naming why not:
C<bad_string>, C<no_such_hole>, C<no_piece>, C<not_your_piece>,
C<must_pass>, C<occupied>, C<not_reachable>, C<pass_not_allowed>,
C<no_such_seat>, C<seat_finished>, C<seat_resigned> or C<game_over>. It never
dies.

=head2 resign

    my $flag = $game->resign($seat);

A seat still racing gives up, on its turn or not. The same flags as L</play>.

=head2 undo

Takes back the last move, pass or resignation. Returns 1, or 0 when there is
nothing to take back.

=head2 reason

    Game::Sternhalma->reason($flag)

A flag in words.

=head1 THE GAME

=head2 to_move

The seat whose turn it is.

=head2 over

True when the game has ended.

=head2 how

C<home>, C<cap>, C<deadlock> or C<resign> once it has; C<undef> before.

=head2 result

A L<Game::Sternhalma::Result> once the game is over; C<undef> before.

=head2 finished

The seats home, in the order they got there.

=head2 places

Every seat's place, in seat order; 0 for a seat not yet placed.

=head2 distance_left

    $game->distance_left($seat)

How far a seat's pieces are from home: 0 when it is home.

=head2 at

    $game->at('i5')

The seat whose piece is in a hole, by name or number, or C<undef>.

=head2 ply

Moves and passes made.

=head2 cap

The ply the game ends at.

=head2 seats

=head2 pieces

=head2 first

The seat that moved first, or C<undef> for a game started from a position.

=head2 start

The position a game was started from, or C<undef> for one started from its
set-up.

=head2 solo

What the game was made with.

=head2 position

The position as a string (see L<Game::Sternhalma::Notation>).

=head2 key

Sixteen hex digits naming the position.

=head2 board

A copy of the board, a L<Game::Sternhalma::Engine>, to look at as closely as
you like.

=head1 THE LOG

=head2 moves

Every move made, as text, in order.

=head2 history

    $game->history($seat)

Every arrangement a seat's pieces have had, as L<Game::Sternhalma::Engine/own_key>s,
the start first; the seat to move's when no seat is given. The bot reads it,
so as never to put its pieces back as they were.

=head2 log

The game as text: the seats, pieces, cap and first seat (or the position it
started from), then the moves.

=head2 replay

    my $game = Game::Sternhalma->replay($text);

The game a log describes, replayed. Dies with a L<Game::Sternhalma::Error>
for a log that is not a game, or a move in it that cannot be made.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-sternhalma at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Sternhalma>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Sternhalma


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Sternhalma>

=item * Search CPAN

L<https://metacpan.org/release/Game-Sternhalma>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Game::Sternhalma
