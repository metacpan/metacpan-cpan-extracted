#
#===============================================================================
#
#         FILE:  Solver.pm
#
#  DESCRIPTION:  Solve 9x9-Sudokus recursively.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Dr.-Ing. Fritz Mehner (Mn), <mehner@fh-swf.de>
#      COMPANY:  Fachhochschule Suedwestfalen, Iserlohn
#      VERSION:  see $VERSION below
#      CREATED:  04.05.2006
#     REVISION:  $Id: Solver.pm,v 1.5 2007/12/14 16:44:06 mehner Exp $
#===============================================================================

package Games::Sudoku::Solver;

use strict;
use warnings;

#===============================================================================
#  MODULE INTERFACE
#===============================================================================
our $VERSION = '1.1.0';

use Carp;                                       # warn/die of errors
use Clone;                                      # recursively copy Perl datatypes

use base qw(Exporter);

# Symbols to be exported on request
our @EXPORT_OK = qw(
    count_occupied_cells
    get_solution_max
    set_solution_max
    sudoku_check
    sudoku_print
    sudoku_read
    sudoku_set
    sudoku_solve
    );

# Define names for sets of symbols
our %EXPORT_TAGS    = (
  Minimal => [ qw( sudoku_set sudoku_solve sudoku_print ) ],
  All     => [ @EXPORT_OK ],
  );

#===============================================================================
#  MODULE IMPLEMENTATION
#===============================================================================
{                                               # CLOSURE
    my $solution_number = 0;                    # solution counter
    my @col_empty;                              # stack of free cells (column number)
    my @row_empty;                              # stack of free cells (row number)
    my $index_last;                             # last index in these stacks
    my $index_empty;                            # actual index in these stacks
    my  %restriction    =
    (
        solution_max    => 10,                  # maximal number of solutions (0=unbound)
        diagonal_ul_lr  =>  0,                  #
        diagonal_ll_ur  =>  0,                  #
    );

    #===  FUNCTION  ================================================================
    #         NAME:  sudoku_solve
    #      PURPOSE:  solve a Sudoku
    #  DESCRIPTION:  solve a Sudoku by recursion
    #   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
    #                (2) reference to a solution array (array of arrays of arrays)
    #                (3) restrictions (optional)
    #      RETURNS:  number of solutions found
    #===============================================================================
    sub sudoku_solve {
        my ( $sudoku_ref, $solution_ref, %option ) = @_;


        if ( %option ) {
            _check_options( %option );
        }

        #---------------------------------------------------------------------------
        #  initialize the stacks
        #---------------------------------------------------------------------------
        @row_empty = ();
        @col_empty = ();
        foreach my $i ( 0 .. 8 ) {
            foreach my $j ( 0 .. 8 ) {
                if ( $sudoku_ref->[$i][$j] == 0 ) {
                    push @row_empty, $i;
                    push @col_empty, $j;
                }
            }
        }
        $index_empty     = -1;
        $index_last      = $#row_empty;
        $solution_number = 0;

        return _sudoku_recurse( $sudoku_ref, $solution_ref );
    }    # ----------  end of subroutine sudoku_solve  ----------

    #===  FUNCTION  ================================================================
    #         NAME:  _check_options
    #      PURPOSE:  check for restrictions
    #   PARAMETERS:  hash with restrictions
    #      RETURNS:  ---
    #===============================================================================
    sub _check_options {
        my  ( %ref )    = @_;
        while ( my ( $key, $value ) = each %ref ) {
                $restriction{$key}  = $value;
        }

        set_solution_max( $restriction{solution_max} );

        if ( $restriction{diagonal_ul_lr} !~ m/^[01]$/xm ) {
            $restriction{diagonal_ul_lr}    = 0;
        }

        if ( $restriction{diagonal_ll_ur} !~ m/^[01]$/xm ) {
            $restriction{diagonal_ll_ur}    = 0;
        }
        return ;
    }   # ----------  end of subroutine _check_options  ----------

    #===  FUNCTION  ================================================================
    #         NAME:  _sudoku_recurse
    #      PURPOSE:  organize the recursion
    #   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
    #                (2) reference to a solution array (array of arrays of arrays)
    #      RETURNS:  number of solutions found so far
    #===============================================================================
    sub _sudoku_recurse {
        my ( $sudoku_ref, $solution_ref ) = @_;

        #---------------------------------------------------------------------------
        #  check if maximal number of solutions are reached
        #---------------------------------------------------------------------------
        if ( $solution_number > 0 && $solution_number == $restriction{solution_max} ) {
            return $solution_number;
        }

        #---------------------------------------------------------------------------
        #  check for a complete solution
        #---------------------------------------------------------------------------
        $index_empty++;                         # index of next empty position
        if ( $index_empty > $index_last ) {     # Sudoku solved ?
            push @{$solution_ref}, \@{ Clone::clone($sudoku_ref) };
            $index_empty--;                     # free last position
            return ++$solution_number;
        }

        #---------------------------------------------------------------------------
        #  recurse over the free cells
        #---------------------------------------------------------------------------
        my $row = $row_empty[$index_empty];
        my $col = $col_empty[$index_empty];
        foreach my $i ( _find_missing_values( $sudoku_ref, $row, $col ) ) {
            $sudoku_ref->[$row][$col] = $i;                 # set cell
            _sudoku_recurse( $sudoku_ref, $solution_ref );  # recurse
        }
        $sudoku_ref->[$row][$col] = 0;                      # empty cell
        $index_empty--;                                     # free cell

        return $solution_number;
    }    # ----------  end of subroutine _sudoku_recurse  ----------

    #===  FUNCTION  ================================================================
    #         NAME:  _find_missing_values
    #      PURPOSE:  find possible values for a free cell
    #   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
    #                (2) row index of the cell
    #                (3) column index of the cell
    #      RETURNS:  array with possible values
    #===============================================================================
    sub _find_missing_values {
        my ( $sudoku_ref, $row, $col ) = @_;
        my @found = ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        my @not_used;

        #---------------------------------------------------------------------------
        #  check row and column
        #---------------------------------------------------------------------------
        foreach my $i ( 0 .. 8 ) {
            $found[ $sudoku_ref->[$row][$i] ]++;
            $found[ $sudoku_ref->[$i][$col] ]++;
        }

        #---------------------------------------------------------------------------
        #  check submatrix
        #---------------------------------------------------------------------------
        my $smi = $row - $row % 3;
        my $smj = $col - $col % 3;
        foreach my $i ( $smi .. ( $smi + 2 ) ) {
            foreach my $j ( $smj .. ( $smj + 2 ) ) {
                $found[ $sudoku_ref->[$i][$j] ]++;
            }
        }

        #---------------------------------------------------------------------------
        #  RESTRICTIONS
        #  check 1. diagonal (if requested)
        #---------------------------------------------------------------------------
        if ( $restriction{diagonal_ul_lr} == 1 && $row == $col ) {
            foreach my $i ( 0 .. 8 ) {
                $found[ $sudoku_ref->[$i][$i] ]++;
            }
        }

        #---------------------------------------------------------------------------
        #  RESTRICTIONS
        #  check 2. diagonal (if requested)
        #---------------------------------------------------------------------------
        if ( $restriction{diagonal_ll_ur} == 1 && ($row + $col) == 8 ) {
            foreach my $i ( 0 .. 8 ) {
                $found[ $sudoku_ref->[$i][8-$i] ]++;
            }
        }

        #---------------------------------------------------------------------------
        #  identify the missing values
        #---------------------------------------------------------------------------
        foreach my $i ( 1 .. 9 ) {
            if ( $found[$i] == 0 ) {
                push @not_used, $i;
            }
        }

        return (@not_used);
    }    # ----------  end of subroutine _find_missing_values  ----------

    #===  FUNCTION  ================================================================
    #         NAME:  set_solution_max
    #      PURPOSE:  set maximal number of solutions to search for
    #   PARAMETERS:  positive number (positive sign allowed)
    #      RETURNS:  ---
    #===============================================================================
    sub set_solution_max {
        my  ( $limit )  = @_;
        if ( $limit =~ m/^[+]?\d+$/xm && $limit > 0 ) {
            $restriction{solution_max} = $limit;
        }
        return;
    }    # ----------  end of subroutine set_solution_max  ----------

    #===  FUNCTION  ================================================================
    #         NAME:  get_solution_max
    #      PURPOSE:  get maximal number of solutions to search for
    #   PARAMETERS:  ---
    #      RETURNS:  maximal number of solutions to search for
    #===============================================================================
    sub get_solution_max {
        return $restriction{solution_max};
    }    # ----------  end of subroutine get_solution_max  ----------

}                                               # end CLOSURE

#===  FUNCTION  ================================================================
#         NAME:  sudoku_check
#      PURPOSE:  Check Sudoku for correctness
#  DESCRIPTION:  - check rows,  columns
#                - check submatrices; numbering:
#                      +---+---+---+
#                      | 1 | 2 | 3 |
#                      +---+---+---+
#                      | 4 | 5 | 6 |
#                      +---+---+---+
#                      | 7 | 8 | 9 |
#                      +---+---+---+
#                Die of error (croak) if Sudoku is not correct.
#   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
#      RETURNS:  ---
#===============================================================================
sub sudoku_check {
    my $sudoku_ref = shift;
    my $key;

    #---------------------------------------------------------------------------
    #  check for doubled values in rows
    #---------------------------------------------------------------------------
    foreach my $i ( 0 .. 8 ) {
        my %count;
        foreach my $j ( 0 .. 8 ) {
            $key = $sudoku_ref->[$i][$j];
            $count{$key}++;
            if ( $key > 0 && $count{$key} > 1 ) {
                $i++;
                croak "value repeated in line ${i} \n";
            }
        }
    }

    #---------------------------------------------------------------------------
    #  check for doubled values in columns
    #---------------------------------------------------------------------------
    foreach my $i ( 0 .. 8 ) {
        my %count;
        foreach my $j ( 0 .. 8 ) {
            $key = $sudoku_ref->[$j][$i];
            $count{$key}++;
            if ( $key > 0 && $count{$key} > 1 ) {
                $i++;
                croak "value repeated in column ${i} \n";
            }
        }
    }

    #---------------------------------------------------------------------------
    #  check submatrices
    #---------------------------------------------------------------------------
    foreach my $ii ( 0, 3, 6 ) {
        foreach my $jj ( 0, 3, 6 ) {
            my %count;
            foreach my $i ( $ii .. $ii + 2 ) {
                foreach my $j ( $jj .. $jj + 2 ) {
                    $key = $sudoku_ref->[$j][$i];
                    $count{$key}++;
                    if ( $key > 0 && $count{$key} > 1 ) {
                        my $submat = $ii + $jj / 3 + 1;
                        croak "value repeated in submatrix $submat \n";
                    }
                }
            }
        }
    }
    return;
}    # ----------  end of subroutine sudoku_check  ----------

#===  FUNCTION  ================================================================
#         NAME:  sudoku_print
#      PURPOSE:  print Sudoku
#  DESCRIPTION:  Simple text output
#   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
#      RETURNS:  ---
#===============================================================================
sub sudoku_print {
    my $sudoku_ref = shift;
    foreach my $i ( 0 .. 8 ) {
        print " @{$sudoku_ref->[$i]}\n";
    }
    return;
}    # ----------  end of subroutine sudoku_print  ----------

#===  FUNCTION  ================================================================
#         NAME:  sudoku_read
#      PURPOSE:  read a Sudoku from a file; check format
#   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
#                (2) name of the input file (scalar)
#      RETURNS:  ---
#===============================================================================
sub sudoku_read {
    my ( $sdk_ref, $filename ) = @_;

    open my $INFILE, '<', $filename
        or die "$0 : failed to open  input file $filename : $!\n";

    while (<$INFILE>) {
        if (
            m{ ^                                # start of line
            \s*                                 # leading whitespaces
            (?:\d\s+){8}                        # 8 digits separated by whitespaces
            \d                                  # 9. digit
            \s*                                 # trailing whitespaces
            $                                   # end of line
            }xm
        )
        {
            push @{$sdk_ref}, [split];          # array of arrays
        }
        else
        {
            if (
                m{  ^                           # start of line
                \s*                             # leading whitespaces
                [.\d]{9}                        # 9 digits or points
                \s*                             # trailing whitespaces
                $                               # end of line
                }xm
            )
            {
                $_ =~ s/[.]/0/gxm;
                $_ =~ s/(\d)/ $1/gxm;
                push @{$sdk_ref}, [split];      # array of arrays
            }
            else
            {
                if (
                    m{ ^                        # start of line
                    \s*                         # leading whitespaces
                    #                           # start of comment
                    }xm
                )
                {
                    next;
                }
                else
                {
                    die "error in file '$filename', line ${.}.\n";
                }
            }
        }
    }

    close $INFILE
        or warn "$0 : failed to close input file $filename : $!\n";

    sudoku_check($sdk_ref);

    return;
}    # ----------  end of subroutine sudoku_read  ----------

#===  FUNCTION  ================================================================
#         NAME:  count_occupied_cells
#      PURPOSE:  count actually occupied cells
#   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
#      RETURNS:  number of occupied cells
#===============================================================================
sub count_occupied_cells {
    my ($sdk_ref) = @_;
    my $cells_occupied = 0;
    foreach my $i ( 0 .. 8 ) {
        foreach my $j ( 0 .. 8 ) {
            if ( $sdk_ref->[$i][$j] != 0 ) {
                $cells_occupied++;
            }
        }
    }
    return $cells_occupied;
}    # ----------  end of subroutine count_occupied_cells  ----------

#===  FUNCTION  ================================================================
#         NAME:  sudoku_set
#      PURPOSE:  store the 81 values of a Sudoku from a flat array into
#                the internal representation (array of arrays)
#   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
#                (2) reference to flat array of 81 values (digits)
#      RETURNS:  ---
#     COMMENTS:  The Sudoku will be checked for correctness.
#===============================================================================
sub sudoku_set {
    my ( $sdk_ref, $linarray_ref ) = @_;
    foreach my $n ( 0 .. 8 ) {
        ${$sdk_ref}[$n] = [ @{$linarray_ref}[ ( $n * 9 ) .. ( $n * 9 + 8 ) ] ];
    }
    sudoku_check($sdk_ref);
    return;
}    # ----------  end of subroutine sudoku_set  ----------

1;   # Magic true value required at end of module

__END__

#===============================================================================
#  MODULE DOCUMENTATION
#===============================================================================

=head1 NAME

Games::Sudoku::Solver - Solve 9x9-Sudokus recursively.

=head1 VERSION

This document describes Games::Sudoku::Solver version 1.0.0

=head1 SYNOPSIS

    use Games::Sudoku::Solver qw(:Minimal set_solution_max count_occupied_cells);

    # specify a Sudoku as flat array (this one has 10 solutions)

    my @sudoku_raw = qw(
        0 4 0 0 2 0 9 0 0
        0 0 0 0 0 0 0 1 0
        0 0 0 0 0 6 8 5 0
        5 8 2 3 0 0 7 0 0
        0 0 0 8 0 7 0 0 0
        0 0 9 0 0 5 1 3 8
        0 9 7 1 0 0 0 0 0
        0 2 0 0 0 0 0 0 0
        0 0 4 0 3 0 0 0 0
    );

    my @sudoku;                                     # the Sudoku data structure
    my @solution;                                   # the solution data structure

    sudoku_set( \@sudoku, \@sudoku_raw );           # convert raw to internal representation

    print "\n===== Sudoku =====\n";
    sudoku_print( \@sudoku );                       # print the Sudoku


    my  $cells_occupied = count_occupied_cells( \@sudoku ); # some statistics
    print "\n", $cells_occupied, " cells occupied, ",
             81-$cells_occupied, " cells free\n";

    set_solution_max(4);                            # stop having 4 solutions found

    my $solutions = sudoku_solve( \@sudoku, \@solution);    # solve the Sudoku

    foreach my $n ( 1..$solutions ) {               # print the solutions
        print "\n--- solution $n ---\n";
        sudoku_print( $solution[$n-1] );
    }


=head1 DESCRIPTION

This module solves 9x9-Sudoku puzzles by recursion.
There is no restriction to the difficulty and the number of solutions.

The puzzle can be stored in a single dimension array or in a file,
where unknown cells are presented by zeros or points.

=head2 Algorithm

Solving Sudokus is perfectly suited for the application of a recursive
algorithm.  The basic idea: Find the first free cell, insert an allowed value
and get a new Sudoku with one free cell less or a solution if it is complete.
In more details:

=over 2

=item 1

Build the list of free cells starting from the upper left corner.  Set an index
on the first free cell.

=item 2

Build the set of allowed (and until now unused) values for the actual cell by
inspecting the according row, column and submatrix.

=over 2

=item *

If there exists an  allowed values and the Sudoku is complete a solution is found.
Discard this value for this cell from the set of allowed values. Go to step 2.

=item *

If there exists an  allowed values and the Sudoku is not complete go ahead to the
next free cell in the list of free cells.   Go to step 2.

=item *

If there exists no allowed value free the actual cell and go back one position
in the list of free cells.  Go to step 2.

=back

=back

The algorithm walks through a tree of mostly incomplete Sudokus. The leaves
which are complete are solutions (if any).

=head1 SUBROUTINES/METHODS

There are two export tags.
C<Minimal> exports C<sudoku_set>, C<sudoku_solve>, and C<sudoku_print>.
C<All> exports all subroutines described below.


=head2 C<count_occupied_cells>

      PURPOSE:  count actually occupied cells
   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
      RETURNS:  number of occupied cells

=head2 C<get_solution_max>

      PURPOSE:  get maximal number of solutions to search for
   PARAMETERS:  ---
      RETURNS:  maximal number of solutions to search for

=head2 C<set_solution_max>

      PURPOSE:  set maximal number of solutions to search for
   PARAMETERS:  postive number (postive sign allowed)
      RETURNS:  ---

=head2 C<sudoku_check>

      PURPOSE:  Check Sudoku for correctness
  DESCRIPTION:  - check rows,  columns
                - check submatrices; numbering:
                      +---+---+---+
                      | 1 | 2 | 3 |
                      +---+---+---+
                      | 4 | 5 | 6 |
                      +---+---+---+
                      | 7 | 8 | 9 |
                      +---+---+---+
                Die of error (croak) if Sudoku is not correct.
   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
      RETURNS:  ---

=head2 C<sudoku_print>

      PURPOSE:  print Sudoku
  DESCRIPTION:  Simple text output
   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
      RETURNS:  ---

=head2 C<sudoku_read>

      PURPOSE:  read a Sudoku from a file; check format
   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
                (2) name of the input file (scalar)
      RETURNS:  ---

    There a two file formats. Format 1 specifies empty cells with 0.
    The cells are separated by whitespaces. Perl comments are allowed
    on separate lines:

        # 1 solution
         0 3 0 2 6 7 0 4 0
         1 0 0 0 0 0 0 0 5
         7 4 0 5 0 1 0 9 2
         9 0 5 0 0 0 1 0 3
         6 0 0 0 5 0 0 0 8
         8 0 4 0 0 0 7 0 9
         2 9 0 7 0 4 0 8 6
         3 0 0 0 0 0 0 0 4
         0 5 0 6 1 2 0 3 0

    The second format uses points for the empty cells. Separating whitespaces
    are not allowed:

         # 1 solution
         3.4...6.2
         9..627..4
         6..1.4..7
         249...731
         16.....85
         .83...46.
         7..8.5..3
         ...263...
         8.5...9.6

    There is no restriction on the number of empty cells.
    A completely empty Sudokus would generate all possible solutions:

         # 6.670.903.752.021.072.936.960 solutions
         #
         0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0
         0 0 0 0 0 0 0 0 0

=head2 C<sudoku_set>

      PURPOSE:  store the 81 values of a Sudoku from a flat array into
                the internal representation (array of arrays)
   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
                (2) reference to flat array of 81 values (digits)
      RETURNS:  ---
     COMMENTS:  The Sudoku will be checked for correctness.

=head2 C<sudoku_solve>

  DESCRIPTION:  solve a Sudoku by recursion
   PARAMETERS:  (1) reference to a Sudoku (array of arrays)
                (2) reference to a solution array (array of arrays of arrays)
                (3) restrictions (hash; optional)
      RETURNS:  number of solutions found

Possible restrictions are:

=over

=item Maximal number of solutions (0=unbound)

    solution_max    => 10

=item Unique digits on the 1. diagonal (upper-left to lower-right)

    diagonal_ul_lr  =>  0                       # not unique
    diagonal_ul_lr  =>  1                       # unique

=item Unique digits on the 2. diagonal (lower-left to upper-right)

    diagonal_ll_ur  =>  0                       # not unique
    diagonal_ll_ur  =>  1                       # unique

=back

=head1 DIAGNOSTICS

=over

=item error C<"$0 : failed to open  input file $filename : $!\n">

Subroutine C<sudoku_read> could not open the specified file.

=item error C<"error in file '$filename', line ${.}.\n">

Subroutine C<sudoku_read> found a format error when reading the specified file.

=item croak C<"value repeated in line ${i} \n">

Subroutine C<sudoku_check> found a format error when checking a Sudoku
(may be after reading it with C<sudoku_read>).

=item croak C<"value repeated in column ${i} \n">

Subroutine C<sudoku_check> found a format error when checking a Sudoku
(may be after reading it with C<sudoku_read>).

=item croak C<"value repeated in submatrix ${i} \n">

Subroutine C<sudoku_check> found a format error when checking a Sudoku
(may be after reading it with C<sudoku_read>).

=item warning C<"$0 : failed to close input file $filename : $!\n";>

Subroutine C<sudoku_read> could not close the specified file.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Games::Sudoku::Solver requires no configuration files or environment variables.


=head1 DEPENDENCIES

    Carp  - warn of errors
    Clone - recursively copy Perl datatypes

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

This module can only solve 9x9-Sudokus.
No bugs have been reported.

Please report any bugs or feature requests to
C<bug-games-sudoku-solver@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Dr.-Ing. Fritz Mehner  C<< <mehner@fh-swf.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2007, Dr.-Ing. Fritz Mehner C<< <mehner@fh-swf.de> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
