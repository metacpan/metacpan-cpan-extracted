package Games::ABC_Path::Generator;

use 5.006;

use strict;
use warnings;

use integer;

use base 'Games::ABC_Path::Generator::Base';

use Games::ABC_Path::Solver::Constants;

use Games::ABC_Path::Solver::Board '0.1.0';

use Games::ABC_Path::MicrosoftRand;

use Games::ABC_Path::Generator::RiddleObj;
use Games::ABC_Path::Generator::FinalLayoutObj;
use Games::ABC_Path::Generator::Coord;

=head1 NAME

Games::ABC_Path::Generator - a generator for ABC Path puzzle games.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';


=head1 SYNOPSIS

    use Games::ABC_Path::Generator;

    my $gen = Games::ABC_Path::Generator->new({seed => 1});

    # Returns a Games::ABC_Path::Generator::RiddleObj object.
    my $riddle = $gen->calc_riddle();

=head1 DESCRIPTION

ABC Path puzzle games are puzzle games where one is given a 5*5 grid which
should contain a consecutive path of the letters from 'A' to 'Y' (with vertical,
horizontal, diagonal, or anti-diagonal steps). The position of the letter 'A'
is given, and two letters are given for each of the columns, rows, main
diagonal and main anti-diagonal, which can appear anywhere there.

ABC Path can be played online at L<http://www.brainbashers.com/abcpath.asp> .

This package is a generator for ABC Path games, and it generates a different
layout with different clues for every random number generator seed.

=head1 SUBROUTINES/METHODS

=head2 my $gen = Games::ABC_Path::Generator->new({seed => $seed});

Initialised a new generator with the random number generator seed $seed .

=cut

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->{seed} = $args->{seed};

    $self->{rand} = Games::ABC_Path::MicrosoftRand->new(seed => $self->{seed});

    return;
}


sub _shuffle {
    my ($self, $deck) = @_;

    return $self->{'rand'}->shuffle($deck);
}

{
my @get_next_cells_lookup =
(
    map {
        my $start = Games::ABC_Path::Generator::Coord->_from_int($_);
        [ map {
            my ($y,$x) = ($start->y() + $_->[$Y], $start->x() + $_->[$X]);
            (
                (__PACKAGE__->_x_in_range($x) && __PACKAGE__->_y_in_range($y))
                ? (__PACKAGE__->_xy_to_int([$y,$x])) : ()
            )
            }
            ([-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1])
        ]
    } (0 .. $BOARD_SIZE - 1)
);

sub _get_next_cells
{
    my ($self, $l, $init_idx) = @_;

    return [ grep { vec($l, $_, 8) == 0 }
        @{$get_next_cells_lookup[$init_idx]}
    ];
}
}


sub _add_next_state
{
    my ($self, $stack, $l, $cell_int) = @_;

    vec($l, $cell_int, 8) = 1+@$stack;

    push @$stack, [$l, $self->_shuffle($self->_get_next_cells($l, $cell_int))];

    return;
}

sub _get_num_connected
{
    my ($self, $l) = @_;

    my @connectivity_stack = (index($l, "\0"));

    my %connected;
    while (@connectivity_stack)
    {
        my $int = pop(@connectivity_stack);
        if (!$connected{$int}++)
        {
            push @connectivity_stack,
            (grep { !exists($connected{$_}) }
                @{ $self->_get_next_cells($l, $int) }
            );
        }
    }

    return scalar keys %connected;
}

=head2 $gen->calc_final_layout()

Calculates the final, solved, layout of the board based on the current
random seed.

Returns the layout as a L<Games::ABC_Path::Generator::FinalLayoutObj>
object.

=cut

sub calc_final_layout
{
    my $self = shift;

    my @dfs_stack;
    $self->_add_next_state(\@dfs_stack, '', $self->{rand}->max_rand($BOARD_SIZE));

    DFS:
    while (@dfs_stack)
    {
        my ($l, $last_cells) = @{$dfs_stack[-1]};

        if (@dfs_stack == $BOARD_SIZE)
        {
            return Games::ABC_Path::Generator::FinalLayoutObj->new(
                {layout_string => $l, },
            );
        }

        # print "Depth = " . scalar(@dfs_stack) . "\n";
        # print "Last state = " . Dumper($last_state) . "\n";
        # print "Layout = \n" . $self->get_layout_as_string($last_state->{layout}) . "\n";

        my $next_idx = shift(@$last_cells);

        if ( ( ! defined($next_idx) )
                or
            ($self->_get_num_connected($l) !=
                ($BOARD_SIZE - scalar(@dfs_stack))
            )
        )
        {
            pop(@dfs_stack);
        }
        else
        {
            $self->_add_next_state(\@dfs_stack, $l, $next_idx);
        }
    }

    die "Not found!";
}

=head2 $gen->calc_riddle()

Calculates the riddle (final state + initial hints) and returns it as an object.

=cut

sub _gen_clue_positions {
    my ($self, $cb) = @_;
    return [map { $cb->($_) } $self->_x_indexes()];
};

sub _calc_clue_positions {
    my $self = shift;
    return
    [
        map {
        [map { $self->_xy_to_int($_) } @{$self->_gen_clue_positions($_)}]
        }
        (
            sub { [$_,$_];   },
            sub { [$_,4-$_]; },
            (map { my $y = $_; sub { [$y,$_] }; } $self->_y_indexes()),
            (map { my $x = $_; sub { [$_,$x] }; } $self->_x_indexes()),
        )
    ]
}

my @_clues_positions = @{__PACKAGE__->_calc_clue_positions()};

sub calc_riddle
{
    my ($self) = @_;

    my $layout = $self->calc_final_layout();

    my $A_pos = $layout->get_A_pos;

    my %init_state = (pos_taken => '',
        clues =>
        [
            map { +{ num_remaining => 5, } }
            (1 .. $NUM_CLUES),
        ]
    );

    my $mark = sub {
        my ($state, $pos) = @_;

        vec($state->{pos_taken}, $pos, 1) = 1;

        my $coord = Games::ABC_Path::Generator::Coord->_from_int($pos);

        foreach my $clue (
            (($coord->y == $coord->x) ? 0 : ()),
            (($coord->y == (5-1)-$coord->x) ? 1 : ()),
            (2+$coord->y),
            ((2+5)+$coord->x),
        )
        {
            $state->{clues}->[$clue]->{num_remaining}--;
        }
    };

    $mark->(\%init_state, $A_pos);

    my @dfs_stack = (\%init_state);

    DFS:
    while (@dfs_stack)
    {
        my $last_state = $dfs_stack[-1];

        if (! exists($last_state->{chosen_clue}))
        {
            my @clues =
            (
                sort {
                    ($a->[1]->{num_remaining} <=> $b->[1]->{num_remaining})
                        or
                    ($a->[0] <=> $b->[0])
                }
                grep { !exists($_->[1]->{cells}) }
                map { [$_, $last_state->{clues}->[$_]] }
                (0 .. $NUM_CLUES-1)
            );

            if (!@clues)
            {
                # Yay! We found a configuration.
                my $handle_clue = sub {
                    my @cells = @{shift->{cells}};
                    return
                    [
                        map { $layout->get_cell_contents($_) }
                        @{$self->_shuffle(\@cells)}
                    ];
                };
                my $riddle =
                Games::ABC_Path::Generator::RiddleObj->new(
                    {
                        solution => $layout,
                        clues =>
                        [
                            map { $handle_clue->($_) } @{$last_state->{clues}}
                        ],
                        A_pos => Games::ABC_Path::Generator::Coord->_from_int($A_pos),
                    }
                );

                my $riddle_string = $riddle->get_riddle_v1_string();

                my $solver =
                    Games::ABC_Path::Solver::Board->input_from_v1_string(
                        $riddle_string
                    );

                $solver->solve();

                if (@{$solver->get_successes_text_tables()} != 1)
                {
                    # The solution is ambiguous
                    pop(@dfs_stack);
                    next DFS;
                }
                else
                {
                    return $riddle;
                }
            }

            # Not enough for the clues there.
            if ($clues[0][1]->{num_remaining} < 2)
            {
                pop(@dfs_stack);
                next DFS;
            }

            my $clue_idx = $clues[0][0];

            $last_state->{chosen_clue} = $clue_idx;

            my @positions =
            (
                grep { !vec($last_state->{pos_taken}, $_, 1) }
                @{$_clues_positions[$clue_idx]}
            );

            my @pairs;

            foreach my $first_idx (0 .. $#positions-1)
            {
                foreach my $second_idx ($first_idx+1 .. $#positions)
                {
                    push @pairs, [@positions[$first_idx, $second_idx]];
                }
            }

            $last_state->{pos_pairs} = $self->_shuffle(\@pairs);
        }

        my $chosen_clue = $last_state->{chosen_clue};
        my $next_pair = shift(@{$last_state->{pos_pairs}});

        if (!defined($next_pair))
        {
            pop(@dfs_stack);
            next DFS;
        }

        my %new_state;
        $new_state{pos_taken} = $last_state->{pos_taken};
        $new_state{clues} = [map { +{ %{$_} } } @{$last_state->{clues}}];
        foreach my $pos (@$next_pair)
        {
            $mark->(\%new_state, $pos);
        }
        $new_state{clues}->[$chosen_clue]->{cells} = [@$next_pair];

        push @dfs_stack, (\%new_state);
    }
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-abc_path-generator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-ABC_Path-Generator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::ABC_Path::Generator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-ABC_Path-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-ABC_Path-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-ABC_Path-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-ABC_Path-Generator/>

=back

=head1 SEE ALSO

L<Games::ABC_Path::Solver> - a solver for ABC Path games which this
generator uses.

L<http://www.shlomifish.org/open-source/projects/japanese-puzzle-games/abc-path/> - the homepage of Shlomi Fish's ABC Path work.

L<http://www.brainbashers.com/abcpath.asp> - play ABC Path online on
brainbashers.com .

L<http://www.janko.at/> - Otto Janko, the creator of ABC Path.

=head1 ACKNOWLEDGEMENTS

Otto Janko (L<http://www.janko.at/>) for creating ABC Path.

L<http://www.brainbashers.com/> for introducing them to me.

Altreus ( L<http://search.cpan.org/~altreus/> ) for suggesting an improvement
to the documentation.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Shlomi Fish.

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

1; # End of Games::ABC_Path::Generator
