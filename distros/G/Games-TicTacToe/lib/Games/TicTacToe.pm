package Games::TicTacToe;

$Games::TicTacToe::VERSION = '0.26';
$Games::TicTacToe::AUTHOR  = 'cpan:MANWAR';

=head1 NAME

Games::TicTacToe - Interface to the TicTacToe (nxn) game.

=head1 VERSION

Version 0.26

=cut

use 5.006;
use Data::Dumper;
use Games::TicTacToe::Move;
use Games::TicTacToe::Board;
use Games::TicTacToe::Player;
use Games::TicTacToe::Params qw(Board PlayerType Players);

use Moo;
use namespace::clean;

has 'board'   => (is => 'rw', isa => Board);
has 'current' => (is => 'rw', isa => PlayerType, default => sub { return 'H'; });
has 'players' => (is => 'rw', isa => Players, predicate => 1);
has 'size'    => (is => 'ro', default   => sub { return 3 });
has 'winner'  => (is => 'rw', predicate => 1, clearer => 1);

=head1 DESCRIPTION

A console  based TicTacToe game to  play against the computer. A simple TicTacToe
layer supplied with the distribution in the script sub folder.  Board arranged as
nxn, where n>=3. Default size is 3,For example 5x5 would be something like below:

    +------------------------+
    |       TicTacToe        |
    +----+----+----+----+----+
    | 1  | 2  | 3  | 4  | 5  |
    +----+----+----+----+----+
    | 6  | 7  | 8  | 9  | 10 |
    +----+----+----+----+----+
    | 11 | 12 | 13 | 14 | 15 |
    +----+----+----+----+----+
    | 16 | 17 | 18 | 19 | 20 |
    +----+----+----+----+----+
    | 21 | 22 | 23 | 24 | 25 |
    +----+----+----+----+----+

The game script C<play-tictactoe> is supplied with the distribution and on install
is available to play with.

  USAGE: play-tictactoe [-h] [long options...]

    --size=Int       TicTacToe board size. Default is 3.
    --symbol=String  User preferred symbol. Default is X. The other possible
                     value is O.

    --usage          show a short help message
    -h               show a compact help message
    --help           show a long help message
    --man            show the manual

=cut

sub BUILD {
    my ($self) = @_;

    $self->setGameBoard($self->size);
}

=head1 METHODS

=head2 setGameBoard($size)

It sets up the game board of the given C<$size>.

=cut

sub setGameBoard {
    my ($self, $size) = @_;

    my $cell = [ map { $_ } (1..($size * $size)) ];
    $self->board(Games::TicTacToe::Board->new(cell => $cell));
}

=head2 getGameBoard()

Returns game board for TicTacToe (3x3) by default.

=cut

sub getGameBoard {
    my ($self) = @_;

    return $self->board->as_string;
}

=head2 setPlayers($symbol)

Adds a player with the given C<$symbol>. The other symbol  would  be given to the
opposite player i.e. Computer.

=cut

sub setPlayers {
    my ($self, $symbol) = @_;

    if (($self->has_players) && (scalar(@{$self->players}) == 2)) {
        warn("WARNING: We already have 2 players to play the TicTacToe game.");
        return;
    }

    die "ERROR: Missing symbol for the player.\n" unless defined $symbol;

    # Player 1
    push @{$self->{players}}, Games::TicTacToe::Player->new(type => 'H', symbol => uc($symbol));

    # Player 2
    $symbol = (uc($symbol) eq 'X')?('O'):('X');
    push @{$self->{players}}, Games::TicTacToe::Player->new(type => 'C', symbol => $symbol);
}

=head2 getPlayers()

Returns the players information with their symbol.

=cut

sub getPlayers {
    my ($self) = @_;

    if (!($self->has_players) || scalar(@{$self->players}) == 0) {
        warn("WARNING: No player found to play the TicTacToe game.");
        return;
    }

    my $players = sprintf("+-------------+\n");
    foreach (@{$self->{players}}) {
        $players .= sprintf("|%9s: %s |\n", $_->desc, $_->symbol);
    }
    $players .= sprintf("+-------------+\n");

    return $players;
}

=head2 play($move)

Makes the given C<$move>, if provided, otherwise make next best possible moves on
behalf of opponent.

=cut

sub play {
    my ($self, $move) = @_;

    die("ERROR: Please add player before you start the game.\n")
        unless (($self->has_players) && (scalar(@{$self->players}) == 2));

    my $player = $self->_getCurrentPlayer;
    my $board  = $self->board;
    if (defined $move && ($self->_getCurrentPlayer->type eq 'H')) {
        --$move;
    }
    else {
        $move = Games::TicTacToe::Move::now($player, $board);
    }

    $board->setCell($move, $player->symbol);
    $self->_resetCurrentPlayer unless ($self->isGameOver);
}

=head2 getResult()

Returns the result message.

=cut

sub getResult {
    my ($self) = @_;

    my $result;
    if ($self->has_winner) {
        $result = $self->winner->getMessage;
    }
    else {
        die "ERROR: Game is not finished yet.\n" unless $self->board->isFull;
        $result = "<cyan><bold>Game drawn, better luck next time.</bold></cyan>\n";
    }

    $self->clear_winner;
    $self->current('H');

    return Term::ANSIColor::Markup->colorize($result);
}

=head2 needNextMove()

Returns 0 or 1 depending on whether it needs to prompt for next move.

=cut

sub needNextMove {
    my ($self) = @_;

   return ($self->_getCurrentPlayer->type eq 'H');
}

=head2 isLastMove()

Returns 0 or 1 depending on whether it is the last move.

=cut

sub isLastMove {
    my ($self) = @_;

   return ($self->board->availableIndex !~ /\,/);
}

=head2 isGameOver()

Returns 0 or 1 depending whether the TicTacToe game is over or not.

=cut

sub isGameOver {
    my ($self) = @_;

    if (!($self->has_players) || scalar(@{$self->players}) == 0) {
        warn("WARNING: No player found to play the TicTacToe game.");
        return;
    }

    my $board = $self->board;
    foreach my $player (@{$self->players}) {
        if (Games::TicTacToe::Move::foundWinner($player, $board)) {
            $self->winner($player);
            return 1;
        }
    }

    return $board->isFull;
}

=head2 isValidMove($move)

Returns 0 or 1 depending on whether the given C<$move> is valid or not.

=cut

sub isValidMove {
    my ($self, $move) = @_;

    return (defined($move)
            && ($move =~ /^\d+$/)
            && ($move >= 1) && ($move <= $self->board->getSize)
            && ($self->board->isCellEmpty($move-1)));
}

=head2 isValidSymbol($symbol)

Returns 0 or 1 depending on whether the given C<$symbol> is valid or not.

=cut

sub isValidSymbol {
    my ($self, $symbol) = @_;

    return (defined $symbol && ($symbol =~ /^[X|O]$/i));
}

=head2 isValidGameBoardSize($size)

Returns 0 or 1 depending on whether the given C<$size> is valid or not.

=cut

sub isValidGameBoardSize {
    my ($self, $size) = @_;

    return (defined $size && ($size >= 3));
}

#
#
# PRIVATE METHODS

sub _getCurrentPlayer {
    my ($self) = @_;

    ($self->{players}->[0]->type eq $self->current)
    ?
    (return $self->{players}->[0])
    :
    (return $self->{players}->[1]);
}

sub _resetCurrentPlayer {
    my ($self) = @_;

    ($self->{players}->[0]->type eq $self->current)
    ?
    ($self->current($self->{players}->[1]->type))
    :
    ($self->current($self->{players}->[0]->type));
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Games-TicTacToe>

=head1 BUGS

Please report any bugs / feature requests to C<bug-games-tictactoe at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-TicTacToe>.
I will be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::TicTacToe

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-TicTacToe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-TicTacToe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-TicTacToe>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-TicTacToe/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2016 Mohammad S Anwar.

This  program  is  free software;  you can redistribute it and/or modify it under
the  terms  of the the Artistic  License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Games::TicTacToe
