package Games::TicTacToe::Board;

$Games::TicTacToe::Board::VERSION   = '0.24';
$Games::TicTacToe::Board::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Games::TicTacToe::Board - Interface to the TicTacToe game's board.

=head1 VERSION

Version 0.24

=cut

use 5.006;
use Data::Dumper;
use Term::ANSIColor::Markup;

use Moo;
use namespace::clean;

our $EMPTY = '\d';

=head1 DESCRIPTION

It is used internally by L<Games::TicTacToe>.

=cut

has 'cell' => (is => 'rw', default => sub { return ['1','2','3','4','5','6','7','8','9']; });

=head1 METHODS

=head2 getSize()

Returns the board size i.e for 3x3 board, the size would be 9.

=cut

sub getSize {
    my ($self) = @_;

    return scalar(@{$self->cell});
}

=head2 isFull()

Return 1 or 0 depending whether the game board is full or not.

=cut

sub isFull {
    my ($self) = @_;

    my $size = $self->getSize;
    foreach my $i (0..($size-1)) {
        return 0 if $self->isCellEmpty($i);
    }

    return 1;
}

=head2 setCell($index, $symbol)

Set the cell C<$index> with the player C<$symbol>.

=cut

sub setCell {
    my ($self, $index, $symbol) = @_;

    die("ERROR: Missing cell index for TicTacToe Board.\n") unless defined $index;
    die("ERROR: Missing symbol for TicTacToe Board.\n")     unless defined $symbol;
    die("ERROR: Invalid symbol for TicTacToe Board.\n")     unless ($symbol =~ /^[X|O]$/i);

    my $size = $self->getSize;
    if (($index =~ /^\d*$/) && ($index >= 0) && ($index < $size)) {
        $self->{cell}->[$index] = $symbol;
    }
    else {
        die("ERROR: Invalid cell index value for TicTacToe Board.\n");
    }
}

=head2 getCell($index)

Get the cell symbol in the given C<$index>.

=cut

sub getCell {
    my ($self, $index) = @_;

    die("ERROR: Missing cell index for TicTacToe Board.\n")  unless defined($index);

    my $size = $self->getSize;
    if (($index =~ /^\d*$/) && ($index >= 0) && ($index < $size)) {
        return $self->{cell}->[$index];
    }
    else {
        die("ERROR: Invalid index value for TicTacToe Board.\n");
    }
}

=head2 availableIndex()

Returns comma seperated empty cell indexes.

=cut

sub availableIndex {
    my ($self) = @_;

    my $index = '';
    my $size = $self->getSize;
    foreach my $i (1..$size) {
        $index .= $i . "," if $self->isCellEmpty($i-1);
    }
    $index =~ s/\,$//g;

    return $index;
}

=head2 isCellEmpty($index)

Returns 1 or 0 depending on if the cell C<$index> is empty.

=cut

sub isCellEmpty {
    my ($self, $index) = @_;

    return ($self->getCell($index) =~ /$EMPTY/);
}

=head2 cellContains($index, $symbol)

Returns 0 or 1 depending on if the cell C<$index> contains the C<$symbol>.

=cut

sub cellContains {
    my ($self, $index, $symbol) = @_;

    return ($self->getCell($index) eq $symbol);
}

=head2 belongsToPlayer($cells, $player)

Returns 0 or 1 depending on if the C<$cells> belong to C<$player>.

=cut

sub belongsToPlayer {
    my ($self, $cells, $player) = @_;

    my $symbol = $player->symbol;
    my $size   = sqrt($self->getSize);
    foreach my $i (0..($size-1)) {
        return 0 unless ($self->cellContains($cells->[$i], $symbol));
    }

    return 1;
}

=head2 as_string()

Returns the current game board.

=cut

sub as_string {
    my ($self) = @_;

    my $size          = sqrt($self->getSize);
    my $cell_width    = _cell_width($size);
    my $table_width   = _table_width($size);
    my $board_color_s = "<blue><bold>";
    my $board_color_e = "</bold></blue>";
    my $board         = sprintf("+%s%s+\n", $board_color_s, '-'x($table_width-2));
    $board .= _table_header($size);

    foreach my $col (1..$size) {
        $board .= sprintf("+%s", '-'x$cell_width);
    }
    $board .= sprintf("+%s\n", $board_color_e);

    my $i = 0;
    foreach my $row (1..$size) {
        foreach my $col (1..$size) {
            $board .= sprintf("$board_color_s|$board_color_e %-".($cell_width-2)."s ",
                              _color_code($cell_width, $self->{cell}->[$i++]));
        }
        $board .= "$board_color_s|\n";
        foreach my $col (1..$size) {
            $board .= sprintf("+%s", '-'x$cell_width);
        }
        $board .= "+$board_color_e\n";
    }

    return Term::ANSIColor::Markup->colorize($board);
}

=head2 reset()

Resets the game board back to original state.

=cut

sub reset {
    my ($self) = @_;

    my $size = $self->getSize;
    foreach my $i (1..$size) {
        $self->{cell}->[$i-1] = $i;
    }
}

#
#
# PRIVATE METHODS

sub _cell_width {
    my ($size) = @_;

    my $len = length($size*$size);
    return ($len+2);
}

sub _table_width {
    my ($size) = @_;

    my $cell_width = _cell_width($size);
    return ( 1 + ($cell_width * $size) + ($size-1) + 1);
}

sub _table_header {
    my ($size) = @_;

    my $table_width = _table_width($size);
    my $pad_size = $table_width - 9;

    my ($left, $right);
    if ($pad_size % 2 == 0) {
        $left = $right = $pad_size / 2;
    }
    else {
        $left = int($pad_size / 2);
        $right = $left + 1;
    }

    my $format = "%-".$left."s%s%".$right."s\n";

    return sprintf($format, '|', 'TicTacToe', '|');
}

sub _color_code {
    my ($width, $text) = @_;

    if ($text =~ /^\d+$/) {
        return $text;
    }
    elsif ($text eq 'X') {
        return "<red><bold>" . sprintf("%-".($width-2)."s", $text) . "</bold></red>";
    }
    elsif ($text eq 'O') {
        return "<green><bold>" . sprintf("%-".($width-2)."s", $text) . "</bold></green>";
    }
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

    perldoc Games::TicTacToe::Board

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

1; # End of Games::TicTacToe::Board
