package Games::Sudoku::Kubedoku;

our $VERSION = 1.00;

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    # Create the Object Data
    my $game = {};
    my $sudoku = shift;
    if ($sudoku) {
        get_data_struc($game, get_size($sudoku));
        set_game($game, $sudoku);
    }
    else {
        # Defult Game is 9x9
        get_data_struc($game, 9);
    }
    bless($game, $class);
    return $game;
}



###############################################################################
# Kubedoku Public Functions
###############################################################################



#################################################
# Set the Sudoku Values
#################################################
sub set_game {
    my $game   = shift;
    my $sudoku = lc(shift);
    $sudoku =~ s/\s+//g;
    $sudoku =~ s/\./0/g;
    if (length($sudoku) != ($game->{'size'} * $game->{'size'})) {
        print STDERR "ERROR: Sudoku game has ".length($sudoku)." values when it should have ".($game->{'size'} * $game->{'size'})." !!!\n";
        return 0;
    }
    my @sudoku = split(//, $sudoku);
    for (my $n=0; $n<scalar(@sudoku); $n++) {
        my $x = ($n % $game->{'size'}) + 1;
        my $y = int($n / $game->{'size'}) + 1;
        if ($sudoku[$n]) {
            if ($sudoku[$n] =~ m/[a-z]/) {
                $sudoku[$n] = (ord($sudoku[$n]) - 87);
            }
            set_value($game, $x, $y, $sudoku[$n]);
        }
    }
    return 1;
}

#################################################
# Get the Sudoku Values
#################################################
sub get_game {
    my $game   = shift;
    my $size   = $game->{'size'};
    my $result = $game->{'result'};
    my $string = "";
    foreach my $y (1..$size) {
        foreach my $x (1..$size) {
            $string .= dec_to_alpha($result->[$x][$y]);
        }
    }
    return $string;
}

#################################################
# Solve the Sudoku (Recursive Function)
#################################################
sub solve {
    my $game   = shift;
    my $kube   = $game->{'kube'};
    my $result = $game->{'result'};
    while () {
        my $kube000 = $kube->[0][0][0];
        get_value($game);
        get_value_square($game);
        return 1 if $result->[0][0] == ($game->{'size'} * $game->{'size'});
        if ($kube000 == $kube->[0][0][0]) {
            return 0 unless $kube->[0][0][0];
            my $options = get_options($game);
            if (scalar(@{$options})) {
                foreach my $option (@{$options}) {
                    my $game2 = clone_data_struc($game);
                    set_value($game2, $option->[0], $option->[1], $option->[2]);
                    if (solve($game2)) {
                        update_data_struc($game, $game2);
                        return 1;
                    }
                }
            }
            return 0;
        }
    }
}

#################################################
# Print the Sudoku Board with the Values
#################################################
sub print_board {
    my $game   = shift;
    my $size   = $game->{'size'};
    my $dim    = $game->{'dim'};
    my $result = $game->{'result'};
    foreach my $i (1..$size) {
        print '+'. join('', map { $_ % $dim ? '-' : '-+' } (1..$size))."\n" unless (($i-1) % $dim);
        print '|'. join('', map { $_ % $dim ? dec_to_alpha($result->[$_][$i]) : dec_to_alpha($result->[$_][$i]).'|' } (1..$size))."\n";
    }
    print '+'. join('', map { $_ % $dim ? '-' : '-+' } (1..$size))."\n";
    return 1;
}



###############################################################################
# Kubedoku Private Functions
###############################################################################



#################################################
# Get the Board Size
#################################################
sub get_size {
    my $sudoku = shift;
    my $nums   = length($sudoku);
    my $size   = int(sqrt($nums));
    if ($nums != ($size * $size)) {
        print STDERR "ERROR: Sudoku game doesn't have a right number of values !!!\n";
        return 0;
    }
    return $size;
}

#################################################
# Create the Game Data Structures
#################################################
sub get_data_struc {
    my $game   = shift;
    my $size   = shift;
    my $dim    = int(sqrt($size));
    my @matrix = ();
    my @kube   = ();
    foreach my $x (0..$size) {
        $matrix[$x] = ();
        $kube[$x] = ();
        my $valx = ($x ? 1 : $size);
        foreach my $y (0..$size) {
            $matrix[$x][$y] = 0;
            $kube[$x][$y] = ();
            my $valy = ($y ? 1 : $size);
            foreach my $z (0..$size) {
                my $valz = ($z ? 1 : $size);
                $kube[$x][$y][$z] = $valx * $valy * $valz;
            }
        }
    }
    my @square = ();
    foreach my $x (1..$dim) {
        $square[$x] = ();
        foreach my $y (1..$dim) {
            $square[$x][$y] = ();
            foreach my $z (1..$size) {
                $square[$x][$y][$z] = $size;
            }
        }
    }
    $game->{'size'}   = $size;
    $game->{'dim'}    = $dim;
    $game->{'result'} = \@matrix;
    $game->{'kube'}   = \@kube;
    $game->{'square'} = \@square;
    $game->{'level'}  = 0;
}

#################################################
# Clone the Game Data Structures
#################################################
sub clone_data_struc {
    my $old    = shift;
    my $size   = $old->{'size'};
    my $dim    = $old->{'dim'};
    my $matrix = $old->{'result'};
    my $kube   = $old->{'kube'};
    my @matrix = ();
    my @kube   = ();
    foreach my $x (0..$size) {
        $matrix[$x] = ();
        $kube[$x] = ();
        foreach my $y (0..$size) {
            $matrix[$x][$y] = $matrix->[$x][$y];
            $kube[$x][$y] = ();
            foreach my $z (0..$size) {
                $kube[$x][$y][$z] = $kube->[$x][$y][$z];
            }
        }
    }
    my $square = $old->{'square'};
    my @square = ();
    foreach my $x (1..$dim) {
        $square[$x] = ();
        foreach my $y (1..$dim) {
            $square[$x][$y] = ();
            foreach my $z (1..$size) {
                $square[$x][$y][$z] = $square->[$x][$y][$z];
            }
        }
    }
    my $new = {};
    $new->{'size'}   = $size;
    $new->{'dim'}    = $dim;
    $new->{'result'} = \@matrix;
    $new->{'kube'}   = \@kube;
    $new->{'square'} = \@square;
    $new->{'level'}  = $old->{'level'} + 1;
    return $new;
}

#################################################
# Update the Game Data Structures
#################################################
sub update_data_struc {
    my $self = shift;
    my $game = shift;
    $self->{'result'} = $game->{'result'};
    $self->{'kube'}   = $game->{'kube'};
    $self->{'square'} = $game->{'square'};
    $self->{'level'}  = $game->{'level'};
}

#################################################
# Set value and clean axis and square
#################################################
sub set_value {
    my $game = shift;
    my $x    = shift;
    my $y    = shift;
    my $z    = shift;
    my $size = $game->{'size'};
    my $dim  = $game->{'dim'};
    my $kube = $game->{'kube'};
    set_result($game, $x, $y, $z);
    foreach my $i (1..$size) {
        # Clean "X" axis
        if ($kube->[$i][$y][$z]) {
            $kube->[$i][$y][$z] = 0;
            set_counts($game, $i, $y, $z);
        }
        # Clean "Y" axis
        if ($kube->[$x][$i][$z]) {
            $kube->[$x][$i][$z] = 0;
            set_counts($game, $x, $i, $z);
        }
        # Clean "Z" axis
        if ($kube->[$x][$y][$i]) {
            $kube->[$x][$y][$i] = 0;
            set_counts($game, $x, $y, $i);
        }
    }
    # Clean Squares
    my $xs = (int(($x -1)/$dim)*$dim);
    my $ys = (int(($y -1)/$dim)*$dim);
    foreach my $i (($xs+1)..($xs+$dim)) {
        foreach my $j (($ys+1)..($ys+$dim)) {
            if ($kube->[$i][$j][$z]) {
                $kube->[$i][$j][$z] = 0;
                set_counts($game, $i, $j, $z);
            }
        }
    }
}

#################################################
# Update the Results Matrix
#################################################
sub set_result {
    my $game   = shift;
    my $x      = shift;
    my $y      = shift;
    my $z      = shift;
    my $result = $game->{'result'};
    $result->[$x][$y] = $z;
    $result->[$x][0]++;
    $result->[0][$y]++;
    $result->[0][0]++;
}

#################################################
# Update the Counters in the Matrix & Square
#################################################
sub set_counts {
    my $game   = shift;
    my $x      = shift;
    my $y      = shift;
    my $z      = shift;
    my $dim    = $game->{'dim'};
    my $kube   = $game->{'kube'};
    my $square = $game->{'square'};
    # Planes
    $kube->[0][$y][$z]--;
    $kube->[$x][0][$z]--;
    $kube->[$x][$y][0]--;
    $kube->[0][0][0]--;
    # Squares
    $x = int(($x -1)/$dim)+1;
    $y = int(($y -1)/$dim)+1;
    $square->[$x][$y][$z]--;
}

#################################################
# Get Values from the Cube Matrix
#################################################
sub get_value {
    my $game = shift;
    my $size = $game->{'size'};
    my $kube = $game->{'kube'};
    foreach my $i (0..$size) {
        foreach my $j (0..$size) {
            # Plane xy
            if ($kube->[$i][$j][0] == 1) {
                foreach my $k (1..$size) {
                    if ($kube->[$i][$j][$k] == 1) {
                        set_value($game, $i, $j, $k);
                    }
                }
            }
            # Plane xz
            if ($kube->[$i][0][$j] == 1) {
                foreach my $k (1..$size) {
                    if ($kube->[$i][$k][$j] == 1) {
                        set_value($game, $i, $k, $j);
                    }
                }
            }
            # Plane yz
            if ($kube->[0][$i][$j] == 1) {
                foreach my $k (1..$size) {
                    if ($kube->[$k][$i][$j] == 1) {
                        set_value($game, $k, $i, $j);
                    }
                }
            }
        }
    }
}

#################################################
# Get Values from the Squares
#################################################
sub get_value_square {
    my $game   = shift;
    my $dim    = $game->{'dim'};
    my $size   = $game->{'size'};
    my $kube   = $game->{'kube'};
    my $square = $game->{'square'};
    foreach my $x (1..$dim) {
        foreach my $y (1..$dim) {
            Z: foreach my $z (1..$size) {
                if ($square->[$x][$y][$z] == 1) {
                     foreach my $i ((($x-1)*$dim+1)..($x*$dim)) {
                        foreach my $j ((($y-1)*$dim+1)..($y*$dim)) {
                            if ($kube->[$i][$j][$z] == 1) {
                                set_value($game, $i, $j, $z);
                                next Z;
                            }
                        }
                    }
                }
            }
        }
    }
}

#################################################
# Get Optional Values from the Line Counters
#################################################
sub get_options {
    my $game = shift;
    my $size = $game->{'size'};
    my $kube = $game->{'kube'};
    my $options = [];
    $options->[$_] = [] foreach (3..$size);
    foreach my $i (1..$size) {
        foreach my $j (1..$size) {
            # Plane xy
            if ($kube->[$i][$j][0]) {
                my $count = $kube->[$i][$j][0];
                if (($count == 2) || (!@{$options->[$count]})) {
                    my $values = [];
                    foreach my $k (1..$size) {
                        if ($kube->[$i][$j][$k] == 1) {
                            push(@{$values}, [$i, $j, $k]);
                        }
                    }
                    return $values if $count == 2;
                    push(@{$options->[$count]}, $values);
                }
            }
            # Plane xz
            if ($kube->[$i][0][$j]) {
                my $count = $kube->[$i][0][$j];
                if (($count == 2) || (!@{$options->[$count]})) {
                    my $values = [];
                    foreach my $k (1..$size) {
                        if ($kube->[$i][$k][$j] == 1) {
                            push(@{$values}, [$i, $k, $j]);
                        }
                    }
                    return $values if $count == 2;
                    push(@{$options->[$count]}, $values);
                }
            }
            # Plane yz
            if ($kube->[0][$i][$j]) {
                my $count = $kube->[0][$i][$j];
                if (($count == 2) || (!@{$options->[$count]})) {
                    my $values = [];
                    foreach my $k (1..$size) {
                        if ($kube->[$k][$i][$j] == 1) {
                            push(@{$values}, [$k, $i, $j]);
                        }
                    }
                    return $values if $count == 2;
                    push(@{$options->[$count]}, $values);
                }
            }
        }
    }
    foreach (3..$size) {
        return $options->[$_]->[0] if scalar($options->[$_]);
    }
    return [];
}

#################################################
# Convert digits higher than 9 to letters
#################################################
sub dec_to_alpha {
    my $val = shift;
    return ($val > 9 ? chr($val + 87) : $val) if ($val);
    return ".";
}



###############################################################################
# Debug Functions
###############################################################################
sub print_kube {
    my $game   = shift;
    my $size   = $game->{'size'};
    my $dim    = $game->{'dim'};
    my $kube   = $game->{'kube'};
    print "-" x ($size*$size) ."\n";
    foreach my $y (1..$size) {
        print "Y".$y;
        print join(" ", map { (" " x $dim).$_ .(" " x ($dim - 1)) } (1..$size));
        print "\n";
        foreach my $z (1..$size) {
            print "Z".$z.(" " x $z);
            foreach my $x (1..$size) {
                print $kube->[$x][$y][$z].(" " x $size);
            }
            print "\n";
        }
        print "\n";
    }
    print "-" x ($size*$size) ."\n";
}

sub kube_to_string {
    my $game = shift;
    my $size = $game->{'size'};
    my $kube = $game->{'kube'};
    my $string = "";
    foreach my $x (1..$size) {
        foreach my $y (1..$size) {
            foreach my $z (1..$size) {
                $string .= $kube->[$x][$y][$z];
            }
        }
    }
    return $string;
}

sub print_square {
    my $game   = shift;
    my $size   = $game->{'size'};
    my $dim    = $game->{'dim'};
    my $square = $game->{'square'};
    print "-" x ($size*$size) ."\n";
    foreach my $y (1..$dim) {
        print "Y".$y;
        print join(" ", map { (" " x $dim).$_ .(" " x ($dim - 1)) } (1..$dim));
        print "\n";
        foreach my $z (1..$size) {
            print "Z".$z.(" " x $z);
            foreach my $x (1..$dim) {
                print $square->[$x][$y][$z].(" " x $size);
            }
            print "\n";
        }
        print "\n";
    }
    print "-" x ($size*$size) ."\n";
}



=head1 NAME

Games::Sudoku::Kubedoku - Sudoku Solver for any NxN puzzles

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use Games::Sudoku::Kubedoku;
    my $sudoku = Games::Sudoku::Kubedoku->new('.4...7.35..5...8.7.78.65.9.9..2..3....364.7.9.6..3.2..5.....1...9.7.......235...4');
    $sudoku->solve();
    my $solution = $sudoku->get_game();
    print "$solution\n";
    $sudoku->print_board();

Or:

    use Games::Sudoku::Kubedoku;
    my $sudoku = Games::Sudoku::Kubedoku->new();
    $sudoku->set_game('.4...7.35..5...8.7.78.65.9.9..2..3....364.7.9.6..3.2..5.....1...9.7.......235...4');
    $sudoku->solve();
    my $solution = $sudoku->get_game();
    print "$solution\n";
    $sudoku->print_board();

=head1 DESCRIPTION

Kubedoku is a Sudoku Solver. It uses a cube(Kube) to solve the game.
The rows, columns and values will become the axes (x,y,z).
The kube has one property, once a value is set in the board, then all the axes (x,y,z) will become empties.
The software will try to get all the unknown values checking axes with the sum of 1.
If there is a sum higher than one, then It will execute recursive to get the right solution.
The code is not the fastest but It is not too complex.
The solver accept the written games with "." or "0" for the unknown values.
The code support Sudokus with 4, 9, 16 or higher size.
The games with more than 9 values has to use letters.

=head1 FUNCTIONS

=over 3

=item *

B<new()> I<Create an sudoku solver instance>

=item *

B<set_game($sudoku_string)> I<Set the sudoku's values (known & unknown)>

=item *

B<get_game()> I<Return the sudoku's values (known & unknown)>

=item *

B<solve()> I<Try to get a solution (recursive function)>

=item *

B<print_board()> I<Print the sudoku board>

=back

=head1 EXAMPLES

    use Games::Sudoku::Kubedoku;
    my $sudoku = Games::Sudoku::Kubedoku->new('1.34....432.21.3');
    print $sudoku->get_game()."\n";
    $sudoku->print_board();
    $sudoku->solve();
    print $sudoku->get_game()."\n";
    $sudoku->print_board();

    1.34....432.21.3
    1234341243212143

    +--+--+    +--+--+
    |1.|34|    |12|34|
    |..|..|    |34|12|
    +--+--+    +--+--+
    |43|2.|    |43|21|
    |21|.3|    |21|43|
    +--+--+    +--+--+


    use Games::Sudoku::Kubedoku;
    my $sudoku = Games::Sudoku::Kubedoku->new('.4...7.35..5...8.7.78.65.9.9..2..3....364.7.9.6..3.2..5.....1...9.7.......235...4');
    print $sudoku->get_game()."\n";
    $sudoku->print_board();
    $sudoku->solve();
    print $sudoku->get_game()."\n";
    $sudoku->print_board();

    .4...7.35..5...8.7.78.65.9.9..2..3....364.7.9.6..3.2..5.....1...9.7.......235...4
    149827635625493817378165492954278361283641759761539248537984126496712583812356974

    +---+---+---+    +---+---+---+
    |.4.|..7|.35|    |149|827|635|
    |..5|...|8.7|    |625|493|817|
    |.78|.65|.9.|    |378|165|492|
    +---+---+---+    +---+---+---+
    |9..|2..|3..|    |954|278|361|
    |..3|64.|7.9|    |283|641|759|
    |.6.|.3.|2..|    |761|539|248|
    +---+---+---+    +---+---+---+
    |5..|...|1..|    |537|984|126|
    |.9.|7..|...|    |496|712|583|
    |..2|35.|..4|    |812|356|974|
    +---+---+---+    +---+---+---+


    use Games::Sudoku::Kubedoku;
    my $sudoku = Games::Sudoku::Kubedoku->new('ad4...67..3b.c.....c9a.2.1..........5...g46..2.d....c.319...g.7.....a758..b..e....1...........9..g.d....e6f.c.1537b6.e2.5........e....1.7....5...f.7..c..b9........3e..4fg...6a.g4.8.b7...e3.9..4a....b6.e.f7...25f.......1.3..a.c3...g..a5.4d.b.6.128.3........');
    print $sudoku->get_game()."\n";
    $sudoku->print_board();
    $sudoku->solve();
    print $sudoku->get_game()."\n";
    $sudoku->print_board();

    ad4...67..3b.c.....c9a.2.1..........5...g46..2.d....c.319...g.7.....a758..b..e....1...........9..g.d....e6f.c.1537b6.e2.5........e....1.7....5...f.7..c..b9........3e..4fg...6a.g4.8.b7...e3.9..4a....b6.e.f7...25f.......1.3..a.c3...g..a5.4d.b.6.128.3........
    ad4f8g67253b9ce16bgc9ad2817e534f13795febg46ca28d58e2c4319fdagb76f9c4a75813bd6eg2e215g6fdc8a7b4938gadb349e6f2c71537b61e2c59g4daf8ce2a391g7d86f5b4df5762ca4b918g3eb193ed84fgc526a7g468fb75a2e319dc4a8gd5b63e2f71c925fb4c9ed71g386a9c3e71gf6a584d2b76d128a3bc49ef5g

    +----+----+----+----+    +----+----+----+----+
    |ad4.|..67|..3b|.c..|    |ad4f|8g67|253b|9ce1|
    |...c|9a.2|.1..|....|    |6bgc|9ad2|817e|534f|
    |....|5...|g46.|.2.d|    |1379|5feb|g46c|a28d|
    |....|c.31|9...|g.7.|    |58e2|c431|9fda|gb76|
    +----+----+----+----+    +----+----+----+----+
    |....|a758|..b.|.e..|    |f9c4|a758|13bd|6eg2|
    |..1.|....|....|..9.|    |e215|g6fd|c8a7|b493|
    |.g.d|....|e6f.|c.15|    |8gad|b349|e6f2|c715|
    |37b6|.e2.|5...|....|    |37b6|1e2c|59g4|daf8|
    +----+----+----+----+    +----+----+----+----+
    |.e..|..1.|7...|.5..|    |ce2a|391g|7d86|f5b4|
    |.f.7|..c.|.b9.|....|    |df57|62ca|4b91|8g3e|
    |...3|e..4|fg..|.6a.|    |b193|ed84|fgc5|26a7|
    |g4.8|.b7.|..e3|.9..|    |g468|fb75|a2e3|19dc|
    +----+----+----+----+    +----+----+----+----+
    |4a..|..b6|.e.f|7...|    |4a8g|d5b6|3e2f|71c9|
    |25f.|....|..1.|3..a|    |25fb|4c9e|d71g|386a|
    |.c3.|..g.|.a5.|4d.b|    |9c3e|71gf|6a58|4d2b|
    |.6.1|28.3|....|....|    |76d1|28a3|bc49|ef5g|
    +----+----+----+----+    +----+----+----+----+

=head1 AUTHOR

Sebastian Isaac Velasco, C<< <velascosebastian at gmail.com> >>.

=head1 COPYRIGHT

    Copyright 2013, Sebastian Isaac Velasco

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN as well as:

    https://github.com/velascosebastian/kubedoku/perl

=cut

1;
