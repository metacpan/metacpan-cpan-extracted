package Games::Bingo::Constants;

use strict;
use warnings;
require Exporter;

use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = '0.18';
@ISA = qw(Exporter);
@EXPORT_OK = qw(
	NUMBER_OF_NUMBERS
	NUMBER_OF_ROWS_IN_CARD
	NUMBER_OF_COLUMNS_IN_CARD
	NUMBER_OF_NUMBERS_IN_CARD
	NUMBER_OF_NUMBERS_IN_ROW
);

use constant NUMBER_OF_NUMBERS => 90;

use constant NUMBER_OF_NUMBERS_IN_ROW  => 5;

use constant NUMBER_OF_ROWS_IN_CARD    => 3;
use constant NUMBER_OF_COLUMNS_IN_CARD => 9;
use constant NUMBER_OF_NUMBERS_IN_CARD =>
	(NUMBER_OF_NUMBERS_IN_ROW * NUMBER_OF_ROWS_IN_CARD);


1;

__END__

=head1 NAME

Games::Bingo::Constants - constants used in the many Games::Bingo modules

=head1 SYNOPSIS

use Games::Bingo::Constants qw(NUMBER_OF_NUMBERS);

=head1 DESCRIPTION

=head2 NUMBER_OF_NUMBERS

This is a constant defining the number of 90 in the game.

Range: 1-90

=head2 NUMBER_OF_ROWS_IN_CARD

This is a constant defining the number of rows in a card.

Definition: 3

=head2 NUMBER_OF_NUMBERS_IN_ROW

This is a constant defining the number of numbers is a row.

Definition: 5

=head2 NUMBER_OF_NUMBERS_IN_CARD

This is a constant defining the number of numbers in a card

Definition: NUMBER_OF_NUMBERS_IN_ROW * NUMBER_OF_ROWS_IN_CARD

=head2 NUMBER_OF_NUMBERS_IN_CARD

This is a constant defining the number of columns in a card

Definition: 9

=head1 SEE ALSO

=over 4

=item Games::Bingo

=item Games::Bingo::Bot

=item Games::Bingo::Card

=item Games::Bingo::Column

=item Games::Bingo::Column::Collection

=item Games::Bingo::Print

=back

=head1 TODO

The TODO file contains a complete list for the whole Games::Bingo
project.

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Games-Bingo is (C) by Jonas B. Nielsen, (jonasbn) 2003-2015

Games-Bingo is released under the artistic license 2.0

=cut
