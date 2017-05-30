package Games::TicTacToe::Player;

$Games::TicTacToe::Player::VERSION = '0.25';
$Games::TicTacToe::Player::AUTHOR  = 'cpan:MANWAR';

=head1 NAME

Games::TicTacToe::Player - Interface to the TicTacToe game's player.

=head1 VERSION

Version 0.25

=cut

use 5.006;
use Data::Dumper;
use Games::TicTacToe::Params qw(Symbol PlayerType);

use Moo;
use namespace::clean;

has 'type'   => (is => 'ro', isa => PlayerType, default => sub { return 'H' }, required => 1);
has 'symbol' => (is => 'ro', isa => Symbol,     default => sub { return 'X' }, required => 1);

=head1 DESCRIPTION

It is used internally by L<Games::TicTacToe>.

=head1 METHODS

=head2 otherSymbol()

Returns opposition player's symbol.

=cut

sub otherSymbol {
    my ($self) = @_;

    return (uc($self->symbol) eq 'X')?('O'):('X');
}

=head2 desc()

Returns the description of the player.

=cut

sub desc {
    my ($self) = @_;

    return ($self->{type} eq 'H')?('Human'):('Computer');
}

=head2 getMessage()

Returns the winning message for the player.

=cut

sub getMessage {
    my ($self) = @_;

    if ($self->type eq 'H') {
        return "<green><bold>Congratulation, you won the game.</bold></green>\n";
    }
    else {
        return "<red><bold>Computer beat you this time. Better luck next time.</bold></red>\n";
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

    perldoc Games::TicTacToe::Player

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

1; # End of Games::TicTacToe::Player
