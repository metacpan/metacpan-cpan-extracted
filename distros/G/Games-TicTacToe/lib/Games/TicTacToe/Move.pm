package Games::TicTacToe::Move;

$Games::TicTacToe::Move::VERSION = '0.24';
$Games::TicTacToe::Move::AUTHOR  = 'cpan:MANWAR';

=head1 NAME

Games::TicTacToe::Move - Interface to the TicTacToe game's move.

=head1 VERSION

Version 0.24

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

=head1 DESCRIPTION

It is used internally by L<Games::TicTacToe>.

=head1 METHODS

=head2 foundWinner($player, $board)

Return 1 or 0 depending wether we have a winner or not.

=cut

sub foundWinner {
    my ($player, $board) = @_;

    die("ERROR: Player not defined.\n") unless defined $player;
    die("ERROR: Board not defined.\n")  unless defined $board;

    my $size = sqrt($board->getSize);
    my $winning_moves = ___winningMoves($size);
    foreach my $move (@$winning_moves) {
        return 1 if $board->belongsToPlayer($move, $player);
    }

    return 0;
}

=head2 now($player, $board)

Make a move now for computer.

=cut

sub now {
    my ($player, $board) = @_;

    die("ERROR: Player not defined.\n") unless defined $player;
    die("ERROR: Board not defined.\n")  unless defined $board;

    my $move = _getBestMove($board, $player);
    return $move unless ($move == -1);

    my $size = $board->getSize;
    my $best_moves = ___bestMoves(sqrt($size));
    foreach my $i (@$best_moves) {
        return $i if $board->isCellEmpty($i);
    }

    foreach my $i (0..($size-1)) {
        return $i if $board->isCellEmpty($i);
    }
}

#
#
# PRIVATE METHODS

sub _getBestMove {
    my ($board, $player) = @_;

    my $move = _isWinningMove($board, $player->symbol);
    return $move unless ($move == -1);
    return _isWinningMove($board, $player->otherSymbol());
}

sub _isWinningMove {
    my ($board, $symbol) = @_;

    my $size = sqrt($board->getSize);
    my $winning_moves = ___winningMoves($size);
    foreach my $m (@{$winning_moves}) {
        foreach my $i (0..($size-1)) {
            if ($board->isCellEmpty($m->[$i])) {
                my $matched = 1;
                foreach my $j (0..($size-1)) {
                    next if ($i == $j);
                    $matched = 0 unless ($board->cellContains($m->[$j], $symbol));
                }
                return $m->[$i] if ($matched);
            }
        }
    }

    return -1;
}

sub ___bestMoves {
    my ($size) = @_;

    my $moves = [];
    if ($size % 2 == 0) {
        # Around the center
        foreach my $i (1..($size-2)) {
            push @$moves, (($i*$size)+($i+1)-1);
        }
        foreach my $i (1..($size-2)) {
            push @$moves, ((($i+1)*$size)-$i)-1;
        }
        # All edge corners
        push @$moves, (0,
                       $size-1,
                       (($size*($size-1)+1))-1,
                       ($size*$size)-1);
    }
    elsif ($size % 2 == 1) {
        my $c = int($size / 2) + 1;
        my $k = ($size*$c)-($c-1);

        # Center point
        push @$moves, ($k-1);
        # All edge corners
        push @$moves, (0,
                       $size-1,
                       (($size*$size)-($size-1))-1,
                       ($size*$size)-1);

        if ($size > 3) {
            # Diagonal (left to right) around the center
            foreach my $i (1..($c-2)) {
                push @$moves, ($k-(($i*$size)+$i))-1;
                push @$moves, ($k-(($i*$size)-$i))-1;
            }
            # Diagonal (right to left) around the center
            my $j = 1;
            foreach my $i (($c+1)..($size-1)) {
                push @$moves, ($k+(($j*$size)+$j))-1;
                push @$moves, ($k+(($j*$size)-$j))-1;
                $j++;
            }
        }
    }

    return $moves;
}

sub ___winningMoves {
    my ($size) = @_;

    my $moves = [];

    # Horizontal
    my $_moves = [];
    my $k = 0;
    foreach my $i (1..$size) {
        $_moves = [];
        foreach my $j (1..$size) {
            push @$_moves, $k++;
        }
        push @$moves, $_moves;
    }

    # Vertical
    foreach my $i (1..$size) {
        $_moves = [];
        $k = 0;
        foreach my $j (1..$size) {
            push @$_moves, ($i+($size*$k))-1;
            $k++;
        }
        push @$moves, $_moves;
    }

    # Diagonal (left to right)
    $_moves = [];
    my $j = 1;
    foreach my $i (0..$size-1) {
        push @$_moves, ($j+($i*$size))-1;
        $j++;
    }
    push @$moves, $_moves;

    # Diagonal (right to left)
    $_moves = [];
    $j = 0;
    foreach my $i (1..$size) {
        push @$_moves, (($i*$size)-$j)-1;
        $j++;
    }
    push @$moves, $_moves;

    return $moves;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Games-TicTacToe>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-tictactoe at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-TicTacToe>.
I will  be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::TicTacToe::Move

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

1; # End of Games::TicTacToe::Move
