package Games::LMSolve::Base;
our $AUTHORITY = 'cpan:SHLOMIF';

use strict;
use warnings;

use Getopt::Long;

our $VERSION = '0.8.6';

use Exporter;

use vars qw(@ISA @EXPORT_OK);

@ISA=qw(Exporter);

@EXPORT_OK=qw(%cell_dirs);

use vars qw(%cell_dirs);

%cell_dirs =
    (
        'N' => [0,-1],
        'NW' => [-1,-1],
        'NE' => [1,-1],
        'S' => [0,1],
        'SE' => [1,1],
        'SW' => [-1,1],
        'E' => [1,0],
        'W' => [-1,0],
    );


sub new
{
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->initialize(@_);

    return $self;
}

sub initialize
{
    my $self = shift;

    $self->{'state_collection'} = { };
    $self->{'cmd_line'} = { 'scan' => "brfs", };

    $self->{'num_iters'} = 0;

    return 0;
}


my %scan_functions =
(
    'dfs' => sub {
        my $self = shift;

        return $self->_solve_brfs_or_dfs(1, @_);
    },
    'brfs' => sub {
        my $self = shift;

        return $self->_solve_brfs_or_dfs(0, @_);
    },
);

sub main
{
    my $self = shift;

    # This is a flag that specifies whether to present the moves in Run-Length
    # Encoding.
    my $to_rle = 1;
    my $output_states = 0;
    my $scan = "brfs";
    my $run_time_states_display = 0;

    #my $p = Getopt::Long::Parser->new();
    if (! GetOptions('rle!' => \$to_rle,
        'output-states!' => \$output_states,
        'method=s' => \$scan,
        'rtd!' => \$run_time_states_display,
        ))
    {
        die "Incorrect options passed!\n"
    }

    if (!exists($scan_functions{$scan}))
    {
        die "Unknown scan \"$scan\"!\n";
    }

    $self->{'cmd_line'}->{'to_rle'} = $to_rle;
    $self->{'cmd_line'}->{'output_states'} = $output_states;
    $self->{'cmd_line'}->{'scan'} = $scan;
    $self->set_run_time_states_display($run_time_states_display && \&_default_rtd_callback);

    my $filename = shift(@ARGV) || "board.txt";

    my @ret = $self->solve_board($filename);

    $self->display_solution(@ret);
}






sub _die_on_abstract_function
{
    my ($package, $filename, $line, $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
    die ("The abstract function $subroutine() was " .
        "called, while it needs to be overrided by the derived class.\n");
}


sub input_board
{
    return _die_on_abstract_function();
}


# A function that accepts the expanded state (as an array ref)
# and returns an atom that represents it.
sub pack_state
{
    return _die_on_abstract_function();
}


# A function that accepts an atom that represents a state
# and returns an array ref that represents it.
sub unpack_state
{
    return _die_on_abstract_function();
}


# Accept an atom that represents a state and output a
# user-readable string that describes it.
sub display_state
{
    return _die_on_abstract_function();
}


sub check_if_final_state
{
    return _die_on_abstract_function();
}


# This function enumerates the moves accessible to the state.
# If it returns a move, it still does not mean that this move is a valid
# one. I.e: it is possible that it is illegal to perform it.
sub enumerate_moves
{
    return _die_on_abstract_function();
}


# This function accepts a state and a move. It tries to perform the
# move on the state. If it is succesful, it returns the new state.
#
# Else, it returns undef to indicate that the move is not possible.
sub perform_move
{
    return _die_on_abstract_function();
}


# This function checks if a state it receives as an argument is a
# dead-end one.
sub check_if_unsolvable
{
    return 0;
}


# This is a function that should be overrided in case
# rendering the move into a string is non-trivial.
sub render_move
{
    my $self = shift;

    my $move = shift;

    return defined($move)?$move:"";
}


sub _solve_brfs_or_dfs
{
    my $self = shift;
    my $state_collection = $self->{'state_collection'};
    my $is_dfs = shift;
    my %args = @_;

    my $run_time_display = $self->{'cmd_line'}->{'rt_states_display'};
    my $rtd_callback = $self->{'run_time_display_callback'};
    my $max_iters = $args{'max_iters'} || (-1);
    my $check_iters = ($max_iters >= 0);

    my (@queue, $state, $coords, $depth, @moves, $new_state);

    if (exists($args{'initial_state'}))
    {
        push @queue, $args{'initial_state'};
    }

    my @ret;

    @ret = ("unsolved", undef);

    while (scalar(@queue))
    {
        if ($check_iters && ($max_iters <= $self->{'num_iters'}))
        {
            @ret = ("interrupted", undef);
            goto Return;
        }
        if ($is_dfs)
        {
            $state = pop(@queue);
        }
        else
        {
            $state = shift(@queue);
        }
        $coords = $self->unpack_state($state);
        $depth = $state_collection->{$state}->{'d'};

        $self->{'num_iters'}++;

        # Output the current state to the screen, assuming this option
        # is set.
        if ($run_time_display)
        {
            $rtd_callback->(
                $self,
                'depth' => $depth,
                'state' => $coords,
                'move' => $state_collection->{$state}->{'m'},
            );
            # print ((" " x $depth) . join(",", @$coords) . " M=" . $self->render_move($state_collection->{$state}->{'m'}) ."\n");
        }

        if ($self->check_if_unsolvable($coords))
        {
            next;
        }

        if ($self->check_if_final_state($coords))
        {
            @ret = ("solved", $state);
            goto Return;
        }

        @moves = $self->enumerate_moves($coords);

        foreach my $m (@moves)
        {
            my $new_coords = $self->perform_move($coords, $m);
            # Check if this move leads nowhere and if so - skip to the next move.
            if (!defined($new_coords))
            {
                next;
            }

            $new_state = $self->pack_state($new_coords);
            if (! exists($state_collection->{$new_state}))
            {
                $state_collection->{$new_state} =
                    {
                        'p' => $state,
                        'm' => $m,
                        'd' => ($depth+1)
                    };
                push @queue, $new_state;
            }
        }
    }

    Return:

    return @ret;
}

sub _run_length_encoding
{
    my @moves = @_;
    my @ret = ();

    my $prev_m = shift(@moves);
    my $count = 1;
    my $m;
    while ($m = shift(@moves))
    {
        if ($m eq $prev_m)
        {
            $count++;
        }
        else
        {
            push @ret, [ $prev_m, $count];
            $prev_m = $m;
            $count = 1;
        }
    }
    push @ret, [$prev_m, $count];

    return @ret;
}


sub _solve_state
{
    my $self = shift;

    my $initial_coords = shift;

    my $state = $self->pack_state($initial_coords);
    $self->{'state_collection'}->{$state} = {'p' => undef, 'd' => 0};

    return
        $self->run_scan(
            'initial_state' => $state,
            @_
        );
}

sub solve_board
{
    my $self = shift;

    my $filename = shift;

    my $initial_coords = $self->input_board($filename);

    return $self->_solve_state($initial_coords, @_);
}


sub run_scan
{
    my $self = shift;

    my %args = @_;

    return
        $scan_functions{$self->{'cmd_line'}->{'scan'}}->(
            $self,
            %args
        );
}


sub get_num_iters
{
    my $self = shift;

    return $self->{'num_iters'};
}


sub display_solution
{
    my $self = shift;

    my @ret = @_;

    my $state_collection = $self->{'state_collection'};

    my $output_states = $self->{'cmd_line'}->{'output_states'};
    my $to_rle = $self->{'cmd_line'}->{'to_rle'};

    my $echo_state =
        sub {
            my $state = shift;
            return $output_states ?
                ($self->display_state($state) . ": Move = ") :
                "";
        };

    print $ret[0], "\n";

    if ($ret[0] eq "solved")
    {
        my $key = $ret[1];
        my $s = $state_collection->{$key};
        my @moves = ();
        my @states = ($key);

        while ($s->{'p'})
        {
            push @moves, $s->{'m'};
            $key = $s->{'p'};
            $s = $state_collection->{$key};
            push @states, $key;
        }
        @moves = reverse(@moves);
        @states = reverse(@states);
        my $num_state;
        if ($to_rle)
        {
            my @moves_rle = _run_length_encoding(@moves);
            my ($m);

            $num_state = 0;
            foreach $m (@moves_rle)
            {
                print $echo_state->($states[$num_state]) . $self->render_move($m->[0]) . " * " . $m->[1] . "\n";
                $num_state += $m->[1];
            }
        }
        else
        {
            for($num_state=0;$num_state<scalar(@moves);$num_state++)
            {
                print $echo_state->($states[$num_state]) . $self->render_move($moves[$num_state]) . "\n";
            }
        }
        if ($output_states)
        {
            print $self->display_state($states[$num_state]), "\n";
        }
    }
}

sub _default_rtd_callback
{
    my $self = shift;

    my %args = @_;
    print ((" " x $args{depth}) . join(",", @{$args{state}}) . " M=" . $self->render_move($args{move}) ."\n");
}


sub set_run_time_states_display
{
    my $self = shift;
    my $states_display = shift;

    if (! $states_display)
    {
        $self->{'cmd_line'}->{'rt_states_display'} = undef;
    }
    else
    {
        $self->{'cmd_line'}->{'rt_states_display'} = 1;
        $self->{'run_time_display_callback'} = $states_display;
    }

    return 0;
}


1;

__END__

=pod

=head1 NAME

Games::LMSolve::Base - base class for puzzle solvers.

=head1 VERSION

version 0.10.1

=head1 SYNOPSIS

    package MyPuzzle::Solver;

    use Games::LMSolve::Base;

    @ISA = qw(Games::LMSolve::Base);

    # Override these methods:

    sub input_board { ... }
    sub pack_state { ... }
    sub unpack_state { ... }
    sub display_state { ... }
    sub check_if_final_state { ... }
    sub enumerate_moves { ... }
    sub perform_move { ... }

    # Optionally:
    sub render_move { ... }
    sub check_if_unsolvable { ... }

    package main;

    my $self = MyPuzzle::Solver->new();

    $self->solve_board($filename);

=head1 DESCRIPTION

This class implements a generic solver for single player games. In order
to use it, one must inherit from it and implement some abstract methods.
Afterwards, its interface functions can be invoked to actually solve
the game.

=head1 VERSION

version 0.10.1

=head1 METHODS

=head2 new()

The constructor.

=head2 $self->initialize()

Should be inherited to implement the construction.

=head2 $self->main()

Actually solve the board based on the arguments in the command line.

=head1 METHODS TO OVERRIDE

=head2 input_board($self, $file_spec)

This method is responsible to read the "board" (the permanent parameters) of
the puzzle and its initial state. It should place the board in the object's
keys, and return the initial state. (in unpacked format).

Note that $file_spec can be either a filename (if it's a string) or a reference
to a filehandle, or a reference to the text of the board. input_board() should
handle all cases.

You can look at the Games::LMSolve::Input module for methods that facilitate
inputting a board.

=head2 pack_state($self, $state_vector)

This function accepts a state in unpacked form and should return it in packed
format. A state in unpacked form can be any perl scalar (as complex as you
like). A state in packed form must be a string.

=head2 unpack_state($self, $packed_state)

This function accepts a state in a packed form and should return it in its
expanded form.

=head2 display_state($self, $packed_state)

Accepts a packed state and should return the user-readable string
representation of the state.

=head2 check_if_final_state($self, $state_vector)

This function should return 1 if the expanded state $state_vector is
a final state, and the game is over.

=head2 enumerate_moves($self, $state_vector)

This function accepts an expanded state and should return an array of moves
that can be performed on this state.

=head2 perform_move($self, $state_vector, $move)

This method accepts an expanded state and a move. It should try to peform
the move on the state. If it is successful, it should return the new
state. Else, it should return undef, to indicate that the move cannot
be performed.

=head2 check_if_unsolvable($self, $state_vector) (optional over-riding)

This method returns the verdict if C<$state_vector> cannot be solved. This
method defaults to returning 0, and it is usually safe to keep it that way.

=head2 render_move($self, $move) (optional overriding)

This function returns the user-readable stringified represtantion of a
move.

=head1 API

=head2 $self->solve_board($file_spec, %args)

Solves the board specification specified in $file_spec. %args specifies
optional arguments. Currently there is one: 'max_iters' that specifies the
maximal iterations to run.

Returns whatever run_scan returns.

=head2 $self->run_scan(%args)

Continues the current scan. %args may contain the 'max_iters' parameter
to specify a maximal iterations limit.

Returns two values. The first is a progress indicator. "solved" means the
puzzle was solved. "unsolved" means that all the states were covered and
the puzzle was proven to be unsolvable. "interrupted" means that the
scan was interrupted in the middle, and could be proved to be either
solvable or unsolvable.

The second argument is the final state and is valid only if the progress
value is "solved".

=head2 $self->get_num_iters()

Retrieves the current number of iterations.

=head2 $self->display_solution($progress_code, $final_state)

If you input this message with the return value of run_scan() you'll get
a nice output of the moves to stdout.

=head2 $self->set_run_time_states_display(\&states_display_callback)

Sets the run time states display callback to \&states_display_callback.

This display callback accepts a reference to the solver and also the following
arguments in key => value pairs:

"state" - the expanded state.
"depth" - the depth of the state.
"move" - the move leading to this state from its parent.

=head1 SEE ALSO

L<Games::LMSolve::Input>

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
http://rt.cpan.org/Public/Dist/Display.html?Name=Games-LMSolve or by email
to bug-games-lmsolve@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Games::LMSolve

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Games-LMSolve>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Games-LMSolve>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-LMSolve>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Games-LMSolve>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Games-LMSolve>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Games-LMSolve>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-LMSolve>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Games-LMSolve>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Games-LMSolve>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Games::LMSolve>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-games-lmsolve at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Games-LMSolve>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/lm-solve-source>

  git clone https://github.com/shlomif/lm-solve-source.git

=cut
