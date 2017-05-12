package Games::YASudoku;

use strict;
use warnings;

our $VERSION = '0.01';
our $REPORT  = "YASudoku/$VERSION";


1;
__END__

=head1 NAME

YASudoku -  Yet Another Sudoku Solver

=head1 SYNOPSIS

sudoku file_name

where file_name contains a description of the board

=head1 DESCRIPTION

This module can be used to solve sudoku number problems.  A file
needs to be created with a description of the sudoku problem to solve.

The data file contains a list of square numbers and the values for those
squares. The squares on the board are numbered 0 through 80 starting with
the top left square and moving across the board to the right.  So the
top left square is 0, the first square on the second row is number 9,
and the last square, bottom right, is number 80.

A typical data file might look something like this:

 5  3
 6  6
 8  2
 11 1
 12 7
 20 6
 23 2
 26 4
 29 5
 31 1
 34 7
 36 8
 37 1
 43 9
 44 5
 46 7
 49 5
 51 2
 54 2
 57 9
 60 3
 68 8
 69 9
 72 6
 74 8
 75 3

Unsolved squares are not included in the data file.

=head1 TODO

=over

=item B<o> Should include more test cases as well as tests for the I<sudoku>
script

=item B<o> would be nice to have a simpler format for the data file

=back

=head1 AUTHOR

Andrew Wyllie <wyllie@dilex.net>

=head1 BUGS

Please send any bugs to the author

=head1 COPYRIGHT

The Games::YASudoku moudule is free software and can be redistributed
and/or modified under the same terms as Perl itself.

=cut
