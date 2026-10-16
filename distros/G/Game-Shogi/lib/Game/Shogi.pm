package Game::Shogi;

use 5.014;
use strict;
use warnings;

use Carp ();
use Object::Proto::Sugar;
use Game::Shogi::Engine ();
use Game::Shogi::Error;
use Game::Shogi::Handicap;
use Game::Shogi::Move;

our $VERSION = '0.01';

my $START = 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 1';

has handicap => (is => 'ro');

has _want_sfen => (is => 'ro', init_arg => 'sfen', private => 1);

has _want_cap => (is => 'ro', init_arg => 'cap', private => 1, default => 500);

has _board => (is => 'rw', private => 1);

has _start => (is => 'rw', private => 1);

has _moves => (is => 'rw', private => 1);

has _result => (is => 'rw', private => 1);

sub BUILD {
    my ($self) = @_;
    my ($handicap, $sfen) = ($self->handicap, $self->_want_sfen);
    Carp::croak("Game::Shogi: '$handicap' is not a handicap; the handicaps are "
        . join(', ', Game::Shogi::Handicap->names))
        if defined $handicap && !Game::Shogi::Handicap->known($handicap);
    Carp::croak("Game::Shogi: a game starts from a handicap or from a position, not both")
        if defined $handicap && defined $sfen;
    my $start = defined $handicap ? Game::Shogi::Handicap->sfen($handicap)
              : defined $sfen     ? $sfen
              :                     $START;
    my $board = Game::Shogi::Engine->new(sfen => $start, cap => $self->_want_cap);
    $self->_board($board);
    $self->_start($board->sfen);
    $self->_moves([]);
    $self->_result($board->outcome);
    return;
}

sub board        { $_[0]->_board->clone }
sub start        { $_[0]->_start }
sub sfen         { $_[0]->_board->sfen }
sub side         { $_[0]->_board->side_to_move }
sub turn         { $_[0]->_result ? undef : $_[0]->_board->side_to_move }
sub status       { $_[0]->_result ? 'finished' : 'active' }
sub move_number  { $_[0]->_board->move_number }
sub in_check     { $_[0]->_board->in_check($_[0]->_board->side_to_move) }
sub can_declare  { !$_[0]->_result && $_[0]->_board->can_declare ? 1 : 0 }
sub result       { $_[0]->_result }
sub winner       { my $r = $_[0]->_result; $r ? $r->winner : undef }
sub moves        { @{ $_[0]->_moves } }
sub history      { $_[0]->_board->history }

sub hand {
    my ($self, $side) = @_;
    return undef unless defined $side && ($side eq 'b' || $side eq 'w');
    return { %{ $self->_board->hands->{$side} } };
}

sub legal {
    my ($self) = @_;
    return () if $self->_result;
    return map { Game::Shogi::Move->new(usi => $_) } $self->_board->legal;
}

sub play {
    my ($self, $move) = @_;
    my $usi = ref $move && eval { $move->isa('Game::Shogi::Move') } ? $move->usi : $move;
    return Game::Shogi::Error->throw('game_over') if $self->_result;
    my $fault = $self->_board->move_fault($usi);
    return Game::Shogi::Error->of_fault($fault) if $fault;
    return Game::Shogi::Error->throw('bad_move') unless $self->_board->do_move($usi);
    push @{ $self->_moves }, $usi;
    $self->_result($self->_board->outcome);
    return 0;
}

sub undo {
    my ($self) = @_;
    my $r = $self->_result;
    return Game::Shogi::Error->throw('game_over') if $r && ($r->how eq 'resign' || $r->how eq 'impasse_declared');
    return Game::Shogi::Error->throw('nothing_to_undo') unless @{ $self->_moves } && $self->_board->undo_move;
    pop @{ $self->_moves };
    $self->_result($self->_board->outcome);
    return 0;
}

sub resign {
    my ($self, $side) = @_;
    return Game::Shogi::Error->throw('game_over') if $self->_result;
    my $r = $self->_board->resign($side) or return Game::Shogi::Error->throw('not_your_turn');
    $self->_result($r);
    return 0;
}

sub declare {
    my ($self) = @_;
    return Game::Shogi::Error->throw('game_over') if $self->_result;
    my $fault = $self->_board->declare_fault;
    return Game::Shogi::Error->throw('cannot_declare', Game::Shogi::Engine->declare_reason($fault)) if $fault;
    my $r = $self->_board->declare
        or return Game::Shogi::Error->throw('cannot_declare', 'the game has reached its cap');
    $self->_result($r);
    return 0;
}

sub log {
    my ($self) = @_;
    my %log = (start => $self->_start, moves => [ @{ $self->_moves } ]);
    $log{handicap} = $self->handicap if defined $self->handicap;
    return \%log;
}

sub record {
    my ($self) = @_;
    require Game::Shogi::Notation;
    return Game::Shogi::Notation->record($self->_start, @{ $self->_moves });
}

sub from_log {
    my ($class, $log, %opt) = @_;
    Carp::croak("Game::Shogi: a log is a hash reference with a start and moves")
        unless ref $log eq 'HASH' && ref($log->{moves} // []) eq 'ARRAY';
    my $game = defined $log->{handicap}
        ? $class->new(handicap => $log->{handicap}, (exists $opt{cap} ? (cap => $opt{cap}) : ()))
        : $class->new((defined $log->{start} ? (sfen => $log->{start}) : ()), (exists $opt{cap} ? (cap => $opt{cap}) : ()));
    Carp::croak("Game::Shogi: the log's start is not its handicap's")
        if defined $log->{handicap} && defined $log->{start} && $log->{start} ne $game->start;
    my $i = 0;
    for my $m (@{ $log->{moves} || [] }) {
        $i++;
        my $refusal = $game->play($m);
        Carp::croak("Game::Shogi: move $i ('" . ($m // 'undef') . "') of the log was refused: " . $refusal->message)
            if $refusal;
    }
    return $game;
}

sub to_text {
    my ($self) = @_;
    my $r = $self->_result;
    my @lines = ('shogi 1');
    push @lines, 'handicap ' . $self->handicap if defined $self->handicap;
    push @lines, 'start ' . $self->_start, 'cap ' . $self->_board->cap,
        join(' ', 'moves', @{ $self->_moves });
    push @lines, 'ending resign ' . $r->loser if $r && $r->how eq 'resign';
    push @lines, 'ending declare' if $r && $r->how eq 'impasse_declared';
    return join "\n", @lines, '';
}

sub from_text {
    my ($class, $text) = @_;
    Carp::croak('Game::Shogi: from_text needs the text to_text wrote, and was given '
        . (defined $text ? 'a reference' : 'nothing'))
        if !defined $text || ref $text;
    my @lines = split /\n/, $text;
    Carp::croak('Game::Shogi: the text is not a saved game of shogi, version 1')
        unless @lines && $lines[0] eq 'shogi 1';
    my %field;
    for my $line (@lines[1 .. $#lines]) {
        my ($name, $value) = $line =~ /\A(handicap|start|cap|moves|ending)(?: (.*))?\z/
            or Carp::croak("Game::Shogi: the saved game has a line it does not know: '$line'");
        Carp::croak("Game::Shogi: the saved game gives $name twice") if exists $field{$name};
        $field{$name} = $value // '';
    }
    for my $name (qw/start cap moves/) {
        Carp::croak("Game::Shogi: the saved game has no $name line") unless exists $field{$name};
    }
    Carp::croak("Game::Shogi: the saved cap is not a whole number: '$field{cap}'")
        unless $field{cap} =~ /\A[0-9]+\z/;
    my %log = (start => $field{start}, moves => [ split ' ', $field{moves} ]);
    $log{handicap} = $field{handicap} if exists $field{handicap};
    my $game = $class->from_log(\%log, cap => $field{cap});
    if (exists $field{ending}) {
        my $refusal = $field{ending} =~ /\Aresign ([bw])\z/ ? $game->resign($1)
                    : $field{ending} eq 'declare'           ? $game->declare
                    : Carp::croak("Game::Shogi: the saved ending is not one it knows: '$field{ending}'");
        Carp::croak("Game::Shogi: the saved ending '$field{ending}' was refused: " . $refusal->message)
            if $refusal;
    }
    return $game;
}

1;

__END__

=head1 NAME

Game::Shogi - shogi, Japanese chess, where a captured piece changes sides

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Game::Shogi;

    my $game = Game::Shogi->new;                       # an even game
    my $give = Game::Shogi->new(handicap => 'bishop'); # White without its bishop, moving first

    if (my $refusal = $game->play('7g7f')) {
        print $refusal->message, "\n";
    }
    print $_->usi, "\n" for $game->legal;

    $game->undo;
    print $game->sfen, "\n";
    if (my $r = $game->result) { print $r->how, ' ', $r->winner // 'draw', "\n" }

    my $again = Game::Shogi->from_log($game->log);

=head1 DESCRIPTION

Shogi is played by two on a board of nine by nine squares, twenty pieces a
side. A piece that is captured goes into its captor's hand and may be dropped
back onto the board as the captor's own.

This is the game: a board, the moves made on it, and how it ended. Every rule
is the board's, L<Game::Shogi::Engine>; this class keeps the game and says why
a move was refused. A refused move comes back as a L<Game::Shogi::Error> and
is never thrown.

A side is C<'b'> for Black, who moves first in an even game, and C<'w'> for
White. A move is a USI string (C<7g7f>, C<8h2b+>, C<P*5e>) or a
L<Game::Shogi::Move>.

It is the engine behind the Shogi at L<https://peer2peergames.com>.

=head1 CONSTRUCTOR

=head2 new

    Game::Shogi->new
    Game::Shogi->new(handicap => 'rook')
    Game::Shogi->new(sfen => $sfen, cap => 300)

An even game; a handicap game from L<Game::Shogi::Handicap>, White without
those pieces and to move; or a game from any position. C<cap> is the move
count at which the game is drawn (500, the Japan Shogi Association's). Croaks
for a handicap that is not one, a handicap and a position together, or a
position the board refuses.

B<A misspelt argument name is not caught>: Object::Proto::Sugar drops an
unknown name, or reads the arguments by position, so C<handicapp> would start
an even game. Check C<handicap> after construction when it matters.

=head2 from_log

    my $game = Game::Shogi->from_log($log, cap => 300);

The game a L</log> writes, replayed move by move. Croaks, naming the move,
when one is refused.

=head1 ATTRIBUTES

=head2 handicap

The handicap's name, or C<undef> for a game without one.

=head1 THE POSITION

=head2 board

A copy of the board, a L<Game::Shogi::Engine>. Changing it changes nothing
here.

=head2 start

The SFEN the game started from.

=head2 sfen

The position now, as SFEN.

=head2 side

The side to move, C<'b'> or C<'w'>.

=head2 turn

The side to move, or C<undef> once the game is over.

=head2 status

C<'active'> or C<'finished'>.

=head2 move_number

The board's move number: 1 at the start, and one more for each move by either
side.

=head2 in_check

True when the side to move is in check.

=head2 can_declare

True when the side to move may declare the impasse now.

=head2 hand

    my $hand = $game->hand('b');    # { P => 2, R => 1 }

A side's pieces in hand, only those it has.

=head2 legal

Every legal move of the side to move, as L<Game::Shogi::Move>s; none once the
game is over.

=head2 moves

The moves made, as USI strings, oldest first.

=head2 history

The keys of the positions the game has stood in before this one, oldest
first, which a search needs to see a repetition coming.

=head1 PLAYING

Each of these returns C<0> when it is done, or a L<Game::Shogi::Error> saying
why it was refused.

=head2 play

    my $refusal = $game->play('7g7f');

Makes a move. A move that breaks a rule is refused with the first rule it
breaks: C<not_your_piece>, C<not_in_hand>, C<cannot_reach>, C<occupied>,
C<promote_not_allowed>, C<promote_required>, C<dead_piece>, C<two_pawns>,
C<in_check> or C<pawn_drop_mate>; C<bad_move> for a string that is not a move;
C<game_over> once the game is over. A move that ends the game sets
L</result>.

=head2 undo

Takes back the last move, and any ending it made. Refused with
C<nothing_to_undo> before the first move, and with C<game_over> after a
resignation or a declaration, which are not moves.

=head2 resign

    $game->resign('b');

The side to move resigns, and the other wins. C<not_your_turn> for the other
side; C<game_over> once the game is over.

=head2 declare

The side to move declares the impasse and wins: its king and ten other pieces
in the enemy camp, not in check, and 28 points as Black or 27 as White.
C<cannot_declare>, with the condition that failed, otherwise.

=head1 THE END

=head2 result

A L<Game::Shogi::Result>, or C<undef> while the game is on: C<mate>,
C<no_move> and C<perpetual_check> are losses for the side they name,
C<sennichite> and C<cap> are draws, and C<resign> and C<impasse_declared> are
what a side did.

=head2 winner

The result's winner: C<'b'>, C<'w'>, or C<undef> while the game is on or for a
draw.

=head1 THE LOG

=head2 log

    { start => $sfen, moves => [ '7g7f', ... ], handicap => 'rook' }

What a game needs to be played again: the start, the moves as USI, and the
handicap when there was one.

=head2 record

The game written down by L<Game::Shogi::Notation>: each move with its side,
its Hodges and its Japanese.

=head2 to_text

    my $text = $game->to_text;

The game as a string, from which L</from_text> builds the same game again: the
handicap when there was one, the start as SFEN, the cap, every move as USI,
and a resignation or a declaration, which the moves cannot show. Two games
with the same history write the same string.

=head2 from_text

    my $again = Game::Shogi->from_text($text);

A new game built from a string L</to_text> wrote, by replaying its moves and
then its ending. A string that is not one C<to_text> writes B<croaks> with a
sentence naming what is wrong: a missing or unknown line, a cap that is not a
number, a move the replay refuses by its number, or an ending refused.

=head1 THE RULES THIS DISTRIBUTION CHOSE

Where the rules of shogi leave a choice, or differ between tournament play and
casual play, this is the choice made here.

=over 4

=item An illegal move is refused, not lost

Tournament play loses a game for an illegal move. Here L</play> refuses it and
says why, and the side to move moves again.

=item Perpetual check loses

The fourth time a position repeats, the side that gave check with every one of
its moves in the cycle loses (C<perpetual_check>). Any other fourfold
repetition is a draw (C<sennichite>), with no replay.

=item The impasse is the 27-point declaration

On its turn a side may declare when its king is in the enemy camp, ten of its
other pieces are there, it is not in check, and it has 28 points (Black) or 27
(White), counting a rook or bishop as five and every other piece as one, from
the pieces in the camp and in hand. A correct declaration wins
(C<impasse_declared>); see L</declare>.

=item A game that nobody ends is drawn at 500 moves

The JSA's rule (C<cap>). A side in check at the cap plays on until it is not.
C<cap> in L</new> changes the number.

=item Black moves first in an even game

The furigoma, the toss that decides who takes Black, is left to the caller. In
a handicap game the giver plays White and moves first.

=back

=head1 SEE ALSO

L<Game::Shogi::Engine>, the board and its rules; L<Game::Shogi::Notation>;
L<Game::Shogi::Handicap>.

L<Games::Shogi> describes the boards and pieces of shogi's large variants. It
has no move generator and no search.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-game-shogi at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Shogi>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Game::Shogi

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Game-Shogi>

=item * Search CPAN

L<https://metacpan.org/release/Game-Shogi>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
