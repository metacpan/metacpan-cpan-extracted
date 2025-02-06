package Games::Sudoku::DLX;

use strict;
use warnings;

our $VERSION = 0.02;

use Algorithm::DLX;

use Exporter        qw( import );
our @EXPORT_OK  =   qw( solve_sudoku );  # symbols to export on request

sub sudoku_to_dlx {
    my %params = @_;
    my $puzzle  = $params{puzzle};
    my $regions = $params{regions};
    my $dlx = Algorithm::DLX->new();

    my $order = @$puzzle;
    my $number_of_regions = @$regions;

    my @cols;
    # Each cell can only have one symbol
    for my $r (0..$order - 1) {
        for my $c (0..$order - 1) {
            push @cols, $dlx->add_column("cell_$r$c");
        }
    }

    # Each symbol can only appear once in each row, column, and region
    for my $r (1..$order) {
        for my $c (0..$order - 1) {
            for my $region (@$regions) {
                my ($a, $b) = @$region;
                my $block = (int($r/$a) * $a) + int($c/$b);
                push @cols, $dlx->add_column("r#$r c#$c R#$a,$b B#$block");
            }
        }
    }

    for my $r (0..$order - 1) {
        for my $c (0..$order - 1) {
            if ($puzzle->[$r][$c]) {
                my $n = $puzzle->[$r][$c];
                my @columns;
                for my $region (0..@$regions - 1) {
                    my ($a, $b) = @{$regions->[$region]};
                    my $block = (int($r/$a) * $a) + int($c/$b);

                    push @columns, $cols[(($region+1) * $order**2) + ($block*$order)+($n-1)];
                }

                # Add the cell column
                push @columns, $cols[$r*$order+$c];
                $dlx->add_row("$r $c $n", @columns);
            } else {
                for my $n (1..$order) {
                    my @columns;
                    for my $region (0..scalar @$regions - 1) {
                        my ($a, $b) = @{$regions->[$region]};
                        my $block = (int($r/$a) * $a) + int($c/$b);

                        push @columns, $cols[(($region+1) * $order**2) + ($block*$order)+($n-1)];
                    }

                    # Add the cell column
                    push @columns, $cols[$r*$order+$c];
                    $dlx->add_row("$r $c $n",  @columns);
                }
            }
        }
    }

    return $dlx;
}

# When we me this a module, this is what we will export
sub solve_sudoku {
    my %params              = @_;

    my $puzzle              = $params{puzzle};
    my $regions             = $params{regions};
    my $number_of_solutions = $params{number_of_solutions} || 0;

    # validate the regions
    my $puzzle_size = scalar @$puzzle;
    for my $region (@$regions) {
        my ($a, $b) = @$region;
        die "Invalid region size: $a x $b for puzzle of size $puzzle_size\n" if $a * $b != @$puzzle;
    }

    # validate the puzzle size
    for my $row (@$puzzle) {
        die "Invalid row size: @$row should have size $puzzle_size\n" if @$row != $puzzle_size;

        # validate the cell values
        for my $cell (@$row) {
            die "Invalid cell value: $cell should be between 0 and $puzzle_size\n" if $cell < 0 || $cell > $puzzle_size;
        }
    }

    my $dlx = sudoku_to_dlx(
        regions => $regions,
        puzzle  => $puzzle,
    );
    my $solutions = $dlx->solve(
        number_of_solutions => $number_of_solutions
    );

    return $solutions;
}

1

__END__

=head1 NAME

DLX - Dancing Links Algorithm for Exact Cover Problems Extended to Solve
Sudoku Puzzles (and generalizations of Sudoku)

=head1 SYNOPSIS

    my $puzzle = [
        [0, 2, 0, 0, 7, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 8, 4, 0],
        [0, 0, 0, 5, 0, 0, 1, 0, 0],
        [9, 0, 0, 0, 1, 0, 7, 6, 4],
        [5, 0, 0, 0, 6, 0, 0, 0, 0],
        [4, 0, 0, 0, 9, 0, 0, 3, 0],
        [0, 0, 7, 9, 0, 0, 0, 0, 0],
        [0, 3, 0, 4, 0, 0, 0, 5, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 8],
    ];

    my $solutions = solve_sudoku(
        puzzle  => $puzzle,
        regions => [ [1,9], [9,1], [3,3] ],
    );

    print "No solutions found\n" unless @$solutions;

    my $solution_count = 0;
    for my $solution (@$solutions) {
        $solution_count++;
        print "\n" unless $solution_count == 1;
        print "Solution $solution_count:\n";
        my $puzzle_solution = [];
        for my $cell (@$solution) {
            my ($r, $c, $n) = $cell =~ /(\d) (\d) (\d)/;
            $puzzle_solution->[$r][$c] = $n;
        }
        for my $row (@$puzzle_solution) {
            print join(" ", @$row), "\n";
        }
    }

=head1 DESCRIPTION

This module implements the Dancing Links (DLX) algorithm for solving exact
cover problems and extends it to solve generalizations Sudoku. These puzzles
include Sudoku Pair Latin Squares as well as Factor Pair Latin Squares

=head1 METHODS

=cut

=head2 solve_sudoku

takes a puzzle and a list of regions and returns a list of solutions.

=over

=item puzzle

A reference to a 2D array representing the puzzle. Each cell should contain
a number between 0 and the size of the puzzle.

=item regions

A reference to a list of regions. Each region is a reference to a 2-element
array representing the dimensions of the region. The product of the
dimensions of each region should be equal to the size of the puzzle.

=back

=head1 AUTHOR

James Hammer <james.hammer3@gmail.com>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut
