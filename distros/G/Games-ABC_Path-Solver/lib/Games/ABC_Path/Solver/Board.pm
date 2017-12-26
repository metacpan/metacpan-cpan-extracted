package Games::ABC_Path::Solver::Board;

use warnings;
use strict;

use 5.008;

=head1 NAME

Games::ABC_Path::Solver::Board - handles an ABC Path board.

=head1 VERSION

Version 0.4.1

=cut

our $VERSION = '0.4.1';

=head1 SYNOPSIS

    use strict;
    use warnings;

    my $board_fn = shift(@ARGV);

    if (!defined ($board_fn))
    {
        die "Filename not specified - usage: abc-path-solver.pl [filename]!";
    }

    my $solver = Games::ABC_Path::Solver::Board->input_from_file($board_fn);
    # Now let's do a neighbourhood inferring of the board.

    $solver->solve;

    foreach my $move (@{$solver->get_moves})
    {
        print +(' => ' x $move->get_depth()), $move->get_text(), "\n";
    }

=head1 FUNCTIONS

=head2 new

The constructor.

=cut

use Carp;

use base 'Games::ABC_Path::Solver::Base';

use Games::ABC_Path::Solver::Constants;
use Games::ABC_Path::Solver::Move::LastRemainingCellForLetter;
use Games::ABC_Path::Solver::Move::LastRemainingLetterForCell;
use Games::ABC_Path::Solver::Move::LettersNotInVicinity;
use Games::ABC_Path::Solver::Move::ResultsInAnError;
use Games::ABC_Path::Solver::Move::ResultsInASuccess;
use Games::ABC_Path::Solver::Move::TryingLetterForCell;

use Games::ABC_Path::Solver::Coord;

use Scalar::Util qw(blessed);

my $ABCP_VERDICT_NO = 0;
my $ABCP_VERDICT_MAYBE = 1;
my $ABCP_VERDICT_YES = 2;

my %letters_map = (map { $letters[$_] => $_ } (0 .. $ABCP_MAX_LETTER));

sub _get_letter_numeric
{
    my ($self, $letter_ascii) = @_;

    my $index = $letters_map{$letter_ascii};

    if (!defined ($index))
    {
        confess "Unknown letter '$letter_ascii'";
    }

    return $index;
}

sub _iter_changed {
    my $self = shift;

    if (@_) {
        $self->{_iter_changed} = shift;
    }

    return $self->{_iter_changed};
}

sub _moves {
    my $self = shift;

    if (@_) {
        $self->{_moves} = shift;
    }

    return $self->{_moves};
}

sub _error {
    my $self = shift;

    if (@_) {
        $self->{_error} = shift;
    }

    return $self->{_error};
}


sub _inc_changed {
    my ($self) = @_;

    $self->_iter_changed($self->_iter_changed+1);

    return;
}

sub _flush_changed {
    my ($self) = @_;

    my $ret = $self->_iter_changed;

    $self->_iter_changed(0);

    return $ret;
}

sub _add_move {
    my ($self, $move) = @_;

    push @{$self->_moves()}, $move;

    $self->_inc_changed;

    return;
}

=head2 get_successful_layouts()

Returns a copy of the successful layouts. Each one of them is a completed
L<Games::ABC_Path::Solver::Board> object.

=cut

sub get_successful_layouts {
    my ($self) = @_;

    return [@{$self->_successful_layouts}];
}

sub _successful_layouts {
    my $self = shift;

    if (@_) {
        $self->{_successful_layouts} = shift;
    }

    return $self->{_successful_layouts};
}


sub _layout {
    my $self = shift;

    if (@_) {
        $self->{_layout} = shift;
    }

    return $self->{_layout};
}

# The letter indexes.
sub _l_indexes
{
    return (0 .. $ABCP_MAX_LETTER);
}

sub _init
{
    my ($self, $args) = @_;

    my $layout_string = $args->{layout};

    if (!defined($layout_string))
    {
        $layout_string = '';
    }

    $self->_layout(\$layout_string);
    $self->_successful_layouts([]);
    $self->_moves([]);
    $self->_iter_changed(0);

    return;
}

sub _calc_offset
{
    my ($self, $letter, $xy) = @_;

    if (($letter < 0) or ($letter >= 25))
    {
        confess "Letter $letter out of range.";
    }

    return $letter * $BOARD_SIZE + $self->_xy_to_int([$xy->y, $xy->x]);
}

sub _get_verdict
{
    my ($self, $letter, $xy) = @_;

    return vec(
        ${$self->_layout},
        $self->_calc_offset($letter, $xy,),
        2
    );
}

sub _set_verdict
{
    my ($self, $letter, $xy, $verdict) = @_;

    # Temporary - remove later.
    if (@_ != 4)
    {
        confess "_set_verdict has wrong number of args.";
    }

    if (not
        (($verdict == $ABCP_VERDICT_NO)
        || ($verdict == $ABCP_VERDICT_MAYBE)
        || ($verdict == $ABCP_VERDICT_YES))
    )
    {
        confess "Invalid verdict $verdict .";
    }

    vec(${$self->_layout}, $self->_calc_offset($letter, $xy), 2)
        = $verdict;

    return;
}

sub _xy_loop
{
    my ($self, $sub_ref) = (@_);

    foreach my $y ($self->_y_indexes)
    {
        if ($self->_error())
        {
            return;
        }
        foreach my $x ($self->_x_indexes)
        {
            if ($self->_error())
            {
                return;
            }
            $sub_ref->(Games::ABC_Path::Solver::Coord->new({x => $x, y => $y}));
        }
    }
    return;
}


sub _set_verdicts_for_letter_sets
{
    my ($self, $letter_list, $maybe_list) = @_;

    my %cell_is_maybe = (map { $_->_to_s() => 1 } @$maybe_list);

    foreach my $letter_ascii (@$letter_list)
    {
        my $letter = $self->_get_letter_numeric($letter_ascii);

        $self->_xy_loop(
            sub {
                my ($xy) = @_;

                $self->_set_verdict($letter, $xy,
                    ((exists $cell_is_maybe{$xy->_to_s()})
                        ? $ABCP_VERDICT_MAYBE
                        : $ABCP_VERDICT_NO
                    )
                );
            }
        );
    }

    return;
}

sub _set_conclusive_verdict_for_letter
{
    my ($self, $letter, $l_xy) = @_;

    $self->_xy_loop(sub {
            my ($xy) = @_;

            $self->_set_verdict($letter, $xy,
                ($l_xy->_equal($xy)
                    ? $ABCP_VERDICT_YES
                    : $ABCP_VERDICT_NO
                )
            );
        }
    );

    OTHER_LETTER:
    foreach my $other_letter ($self->_l_indexes)
    {
        if ($other_letter == $letter)
        {
            next OTHER_LETTER;
        }
        $self->_set_verdict($other_letter, $l_xy, $ABCP_VERDICT_NO);
    }

    return;
}

sub _get_possible_letter_indexes
{
    my ($self, $xy) = @_;

    return
    [
        grep { $self->_get_verdict($_, $xy) != $ABCP_VERDICT_NO }
        $self->_l_indexes()
    ];
}

=head2 $board->get_possible_letters_for_cell($x,$y)

Returns an array reference of the possible letters for the cell ($x,$y) where
$x and $y are in the range 0..4 and the letters are their letter names.

=cut

sub get_possible_letters_for_cell
{
    my ($self, $x, $y) = @_;

    return [@letters[@{$self->_get_possible_letter_indexes(Games::ABC_Path::Solver::Coord->new({x => $x, y => $y}))}]];
}

sub _get_possible_letters_string
{
    my ($self, $xy) = @_;

    return join(',', @{$self->get_possible_letters_for_cell($xy->x, $xy->y)});
}


sub _infer_letters
{
    my ($self) = @_;

    foreach my $letter ($self->_l_indexes)
    {
        my @true_cells;

        $self->_xy_loop(sub {
            my ($xy) = @_;

            my $ver = $self->_get_verdict($letter, $xy);
            if (    ($ver == $ABCP_VERDICT_YES)
                || ($ver == $ABCP_VERDICT_MAYBE))
            {
                push @true_cells, $xy;
            }
        });

        if (! @true_cells)
        {
            $self->_error(['letter', $letter]);
            return;
        }
        elsif (@true_cells == 1)
        {
            my $xy = $true_cells[0];
            if ($self->_get_verdict($letter, $xy) ==
                $ABCP_VERDICT_MAYBE)
            {
                $self->_set_conclusive_verdict_for_letter($letter, $xy);
                $self->_add_move(
                    Games::ABC_Path::Solver::Move::LastRemainingCellForLetter->new(
                        {
                            vars =>
                            {
                                letter => $letter,
                                coords => $xy,
                            },
                        }
                    )
                );
            }
        }

        my @neighbourhood = (map { [(0) x $LEN] } ($self->_y_indexes));

        foreach my $true (@true_cells)
        {
            foreach my $coords
            (
                grep {
                    $self->_x_in_range($_->[0]) and $self->_y_in_range($_->[1])
                }
                map { [$true->x + $_->[0], $true->y + $_->[1]] }
                map { my $d = $_; map { [$_, $d] } (-1 .. 1) }
                (-1 .. 1)
            )
            {
                $neighbourhood[$coords->[1]][$coords->[0]] = 1;
            }
        }

        foreach my $neighbour_letter (
            (($letter > 0) ? ($letter-1) : ()),
            (($letter < $ABCP_MAX_LETTER) ? ($letter+1) : ()),
        )
        {
            $self->_xy_loop(sub {
                my ($xy) = @_;

                if ($neighbourhood[$xy->y][$xy->x])
                {
                    return;
                }

                my $existing_verdict =
                    $self->_get_verdict($neighbour_letter, $xy);

                if ($existing_verdict == $ABCP_VERDICT_YES)
                {
                    $self->_error(['mismatched_verdict', $xy]);
                    return;
                }

                if ($existing_verdict == $ABCP_VERDICT_MAYBE)
                {
                    $self->_set_verdict($neighbour_letter, $xy, $ABCP_VERDICT_NO);
                    $self->_add_move(
                        Games::ABC_Path::Solver::Move::LettersNotInVicinity->new(
                            {
                                vars =>
                                {
                                    target => $neighbour_letter,
                                    coords => $xy,
                                    source => $letter,
                                },
                            }
                        )
                    );
                }
            });
        }
    }

    return;
}

sub _infer_cells
{
    my ($self) = @_;

    $self->_xy_loop(sub {
        my ($xy) = @_;

        my $letters_aref = $self->_get_possible_letter_indexes($xy);

        if (! @$letters_aref)
        {
            $self->_error(['cell', $xy]);
            return;
        }
        elsif (@$letters_aref == 1)
        {
            my $letter = $letters_aref->[0];

            if ($self->_get_verdict($letter, $xy) == $ABCP_VERDICT_MAYBE)
            {
                $self->_set_conclusive_verdict_for_letter($letter, $xy);
                $self->_add_move(
                    Games::ABC_Path::Solver::Move::LastRemainingLetterForCell->new(
                        {
                            vars =>
                            {
                                coords => $xy,
                                letter => $letter,
                            },
                        },
                    )
                );
            }
        }
    });

    return;
}


sub _inference_iteration
{
    my ($self) = @_;

    $self->_infer_letters;

    $self->_infer_cells;

    return $self->_flush_changed;
}

sub _neighbourhood_and_individuality_inferring
{
    my ($self) = @_;

    my $num_changed = 0;

    while (my $iter_changed = $self->_inference_iteration())
    {
        if ($self->_error())
        {
            return;
        }
        $num_changed += $iter_changed;
    }

    return $num_changed;
}

sub _clone
{
    my ($self) = @_;

    return
        ref($self)->new(
            {
                layout => ${$self->_layout()},
            }
        );
}

=head2 $board->solve()

Performs the actual solution. Should be called after input.

=cut

sub solve
{
    my ($self) = @_;

    my $error = $self->_solve_wrapper;

    return [map {
        my $obj = $_;
        (blessed($obj) && $obj->isa('Games::ABC_Path::Solver::Coord'))
            ? ($obj->x, $obj->y)
            : ($obj)
        } @$error];
}

sub _solve_wrapper
{
    my ($self) = @_;

    $self->_neighbourhood_and_individuality_inferring;

    if ($self->_error)
    {
        return $self->_error;
    }

    my @min_coords;
    my @min_options;

    $self->_xy_loop(sub {
        my ($xy) = @_;

        my $letters_aref = $self->_get_possible_letter_indexes($xy);

        if (! @$letters_aref)
        {
            $self->_error(['cell', $xy]);
        }
        elsif (@$letters_aref > 1)
        {
            if ((!@min_coords) or (@$letters_aref < @min_options))
            {
                @min_options = @$letters_aref;
                @min_coords = ($xy);
            }
        }

        return;
    });

    if ($self->_error)
    {
        return $self->_error;
    }

    if (@min_coords)
    {
        my ($xy) = @min_coords;
        # We have at least one multiple rank cell. Let's recurse there:
        foreach my $letter (@min_options)
        {
            my $recurse_solver = $self->_clone;

            $self->_add_move(
                Games::ABC_Path::Solver::Move::TryingLetterForCell->new(
                    {
                        vars => { letter => $letter, coords => $xy, },
                    }
                ),
            );

            $recurse_solver->_set_conclusive_verdict_for_letter(
                $letter, $xy
            );

            $recurse_solver->_solve_wrapper;

            foreach my $move (@{ $recurse_solver->get_moves })
            {
                $self->_add_move($move->bump());
            }

            if ($recurse_solver->_error())
            {
                $self->_add_move(
                    Games::ABC_Path::Solver::Move::ResultsInAnError->new(
                    {
                        vars =>
                        {
                            letter => $letter,
                            coords => $xy,
                        },
                    }
                    )
                );
            }
            else
            {
                $self->_add_move(
                    Games::ABC_Path::Solver::Move::ResultsInASuccess->new(
                        {
                            vars => { letter => $letter, coords => $xy,},
                        }
                    )
                );
                push @{$self->_successful_layouts},
                    @{$recurse_solver->get_successful_layouts()};
            }
        }

        my $count = @{$self->_successful_layouts()};
        if (! $count)
        {
            return ['all_options_bad'];
        }
        elsif ($count == 1)
        {
            return ['success'];
        }
        else
        {
            return ['success_multiple'];
        }
    }
    else
    {
        $self->_successful_layouts([$self->_clone()]);
        return ['success'];
    }
}

my $letter_re_s = join('', map { quotemeta($_) } @letters);
my $letter_re = qr{[$letter_re_s]};
my $letter_and_space_re = qr{[ $letter_re_s]};
my $top_bottom_re = qr/^${letter_re}{7}\n/ms;
my $inner_re = qr/^${letter_re}${letter_and_space_re}{5}${letter_re}\n/ms;

sub _assert_letters_appear_once
{
    my ($self, $layout_string) = @_;

    my %count_letters = (map { $_ => 0 } @letters);
    foreach my $letter ($layout_string =~ m{($letter_re)}g)
    {
        if ($count_letters{$letter}++)
        {
            confess "Letter '$letter' encountered twice in the layout.";
        }
    }

    return;
}

sub _process_major_diagonal
{
    my ($self, $args) = @_;

    my @major_diagonal_letters;

    $args->{top} =~ m{\A($letter_re)};

    push @major_diagonal_letters, $1;

    $args->{bottom} =~ m{($letter_re)\z};

    push @major_diagonal_letters, $1;

    $self->_set_verdicts_for_letter_sets(
        \@major_diagonal_letters,
        [map
            { Games::ABC_Path::Solver::Coord->new({x => $_, y => $_}) }
            $self->_y_indexes
        ],
    );

    return;
}

sub _process_minor_diagonal
{
    my ($self, $args) = @_;

    my @minor_diagonal_letters;

    $args->{top} =~ m{($letter_re)\z};

    push @minor_diagonal_letters, $1;

    $args->{bottom} =~ m{\A($letter_re)};

    push @minor_diagonal_letters, $1;

    $self->_set_verdicts_for_letter_sets(
        \@minor_diagonal_letters,
        [map { Games::ABC_Path::Solver::Coord->new({x => $_, y => 4-$_}) } ($self->_y_indexes)]
    );

    return;
}

sub _process_input_columns
{
    my ($self, $args) = @_;

    my $top_row = $args->{top};
    my $bottom_row = $args->{bottom};

    foreach my $x ($self->_x_indexes)
    {
        $self->_set_verdicts_for_letter_sets(
            [substr($top_row, $x+1, 1), substr($bottom_row, $x+1, 1),],
            [map { Games::ABC_Path::Solver::Coord->new({x =>$x, y => $_}) } $self->_y_indexes],
        );
    }

    return;
}

sub _process_input_rows_and_initial_letter_clue
{
    my ($self, $args) = @_;

    my $rows = $args->{rows};

    my ($clue_x, $clue_y, $clue_letter);

    foreach my $y ($self->_y_indexes)
    {
        my $row = $rows->[$y];
        $self->_set_verdicts_for_letter_sets(
            [substr($row, 0, 1), substr($row, -1),],
            [map { Games::ABC_Path::Solver::Coord->new({x => $_,y => $y}) } $self->_x_indexes],
        );

        my $s = substr($row, 1, -1);
        if ($s =~ m{($letter_re)}g)
        {
            my ($l, $x_plus_1) = ($1, pos($s));
            if (defined($clue_letter))
            {
                confess "Found more than one clue letter in the layout!";
            }
            ($clue_x, $clue_y, $clue_letter) = ($x_plus_1-1, $y, $l);
        }
    }

    if (!defined ($clue_letter))
    {
        confess "Did not find any clue letters inside the layout.";
    }

    $self->_set_conclusive_verdict_for_letter(
        $self->_get_letter_numeric($clue_letter),
        Games::ABC_Path::Solver::Coord->new({x => $clue_x, y => $clue_y}),
    );

    return;
}

sub _input
{
    my ($self, $args) = @_;

    if ($args->{version} ne 1)
    {
        die "Can only handle version 1";
    }

    my $layout_string = $args->{layout};
    if ($layout_string !~ m/\A${top_bottom_re}${inner_re}{5}${top_bottom_re}\z/ms)
    {
        die "Invalid format. Should be Letter{7}\n(Letter{spaces or one letter}{5}Letter){5}\nLetter{7}";
    }

    my @rows = split(/\n/, $layout_string);

    my $top_row = shift(@rows);
    my $bottom_row = pop(@rows);

    # Now let's process the layout string and populate the verdicts table.
    $self->_assert_letters_appear_once($layout_string);

    my $parse_context =
        { top => $top_row, bottom => $bottom_row, rows => \@rows, }
        ;

    $self->_process_major_diagonal($parse_context);

    $self->_process_minor_diagonal($parse_context);

    $self->_process_input_columns($parse_context);

    $self->_process_input_rows_and_initial_letter_clue($parse_context);


    return;
}

sub _get_results_text_table
{
    my ($self) = @_;

    my $render_row = sub {
        my $cols = shift;

        return
            "| " .
            join(
                " | ",
                map { length($_) == 1 ? "  $_  " : $_ } @$cols
            ) . " |\n";
    };

    return join('',
        map { $render_row->($_) }
        (
        [map { sprintf("X = %d", $_+1) } $self->_x_indexes ],
        map { my $y = $_;
            [
                map
                { $self->_get_possible_letters_string(Games::ABC_Path::Solver::Coord->new({x => $_, y => $y})) }
                $self->_x_indexes
            ]
            }
            $self->_y_indexes
        )
    );
}

=head2 $self->get_successes_text_tables()

This returns a textual representation of the successful layouts.

=cut

sub get_successes_text_tables
{
    my ($self) = @_;

    return [map { $_->_get_results_text_table() } @{$self->get_successful_layouts()}];
}

=head2 my $board = Games::ABC_Path::Solver::Board->input_from_file($filename)

Inputs the board from the C<$filename> file path containing a representation
of the initial board.

Sample boards can be found in the distribution under C<t/layouts/> .

Here is the description of their formats. The first line should be the
magic string C<ABC Path Solver Layout Version 1:> , and the next line should
be a row of 7 letters, the first being a hint for the top-left-to-bottom-right
perpendicular, the last being a hint for the top-right-to-bottom-left
perpendicular and the rest of the letters being vertical hints.

After that, there are 5 rows of horizontal hints being a letter, 5 spaces
and another letter. On one of the squares one can put a letter instead of a
space, to indicate it must be there.

The last row is another row of vertical hints and perpendicular hints.

=cut

sub input_from_file
{
    my ($class, $board_fn) = @_;

    open my $in_fh, "<", $board_fn
        or die "Cannot open '$board_fn' - $!";

    my $first_line = <$in_fh>;
    chomp($first_line);

    my $magic = 'ABC Path Solver Layout Version 1:';
    if ($first_line !~ m{\A\Q$magic\E\s*\z})
    {
        die "Can only process files whose first line is '$magic'!";
    }

    my $layout_string = '';
    foreach my $line_idx (1 .. 7)
    {
        chomp(my $line = <$in_fh>);
        $layout_string .= "$line\n";
    }
    close($in_fh);

    return $class->input_from_v1_string($layout_string);
}

=head2 my $board = Games::ABC_Path::Solver::Board->input_from_v1_string($layout_string)

This is a class method that inputs a version 1 string (as specified in
L<input_from_file> only without the opening magic line.)

=cut

sub input_from_v1_string
{
    my ($class, $layout_string) = @_;

    my $self = $class->new;

    $self->_input({ layout => $layout_string, version => 1});

    return $self;
}

=head2 $board->get_moves()

Returns the moves performed by the board. Each move is an
object of a L<Games::ABC_Path::Solver::Move> sub-class.

=cut

sub get_moves
{
    my ($self) = @_;

    return [@{ $self->_moves }];
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-abc_path-solver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-ABC_Path-Solver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::ABC_Path::Solver::Board


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-ABC_Path-Solver>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-ABC_Path-Solver>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-ABC_Path-Solver>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-ABC_Path-Solver/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Shlomi Fish.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1; # End of Games::ABC_Path::Solver::Board
