package Games::Solitaire::BlackHole::Solver::Golf::App;
$Games::Solitaire::BlackHole::Solver::Golf::App::VERSION = '0.16.1';
use 5.014;
use Moo;

extends('Games::Solitaire::BlackHole::Solver::App::Base');
use Games::Solitaire::BlackHole::Solver::App::Base qw/ $card_re /;


sub run
{
    my $self      = shift;
    my $RANK_KING = $self->_RANK_KING;

    # A boolean
    my $place_queens_on_kings = '';

    # A boolean
    my $wrap_ranks = '';
    $self->_process_cmd_line(
        {
            extra_flags => {
                "queens-on-kings!" => \$place_queens_on_kings,
                "wrap-ranks!"      => \$wrap_ranks,
            }
        }
    );
    if ($wrap_ranks)
    {
        $place_queens_on_kings = 1;
    }
    $self->_calc_lines( shift(@ARGV), );

    my $talon_line = shift( @{ $self->_board_lines } );
    my @talon_values;
    my $talon_ptr = 0;
    if ( my ($cards) = $talon_line =~ m{\ATalon:((?: $card_re){16})\z} )
    {
        @talon_values = map { $self->_get_rank($_) }
            @{ $self->_talon_cards( [ $cards =~ /($card_re)/g ] ) };
    }
    else
    {
        die "Could not match first talon line!";
    }

    $self->_set_up_solver( $talon_ptr,
        [ 1, ( $wrap_ranks ? ($RANK_KING) : () ) ] );

    my $positions    = $self->_positions;
    my $board_values = $self->_board_values;

    my $verdict = 0;

    $self->_next_task;

QUEUE_LOOP:
    while ( my $state = $self->_get_next_state_wrapper )
    {
        # The foundation
        my $fnd      = vec( $state, 0, 8 );
        my $no_cards = 1;
        my $tln      = vec( $state, 1, 8 );
        my @sub_queue;

        my @_pending;

        if ( $place_queens_on_kings || ( $fnd != $RANK_KING ) )
        {
            $self->_find_moves( \@sub_queue, $state, \$no_cards );
        }
        else
        {
        COL:
            foreach my $col_idx ( keys @$board_values )
            {
                my $pos = vec( $state, 4 + $col_idx, 4 );

                if ($pos)
                {
                    $no_cards = 0;
                    last COL;
                }
            }
        }

        if ($no_cards)
        {
            $self->_trace_solution( $state, );
            $verdict = 1;
            last QUEUE_LOOP;
        }

        if ( $tln < @talon_values )
        {
            my $next_s = $state;
            vec( $next_s, 0, 8 ) = $talon_values[$tln];
            ++vec( $next_s, 1, 8 );
            if ( !exists( $positions->{$next_s} ) )
            {
                $positions->{$next_s} =
                    [ $state, scalar(@$board_values), 1, 0 ];
                push @_pending, [ $next_s, 0 ];
            }
        }

        # Give preference to non-talon moves
        push @_pending, @sub_queue;
        last QUEUE_LOOP
            if not $self->_process_pending_items( \@_pending, $state );
    }

    return $self->_my_exit( $verdict, );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::BlackHole::Solver::Golf::App - a command line application
implemented as a class to solve the “Golf” variant of solitaire.

=head1 VERSION

version 0.16.1

=head1 SYNOPSIS

    use Games::Solitaire::BlackHole::Solver::Golf::App ();

    my $app = Games::Solitaire::BlackHole::Solver::Golf::App->new;

    $app->run();

And then from the command-line:

    $ golf-solitaire-solve-perl myboard.txt

=head1 DESCRIPTION

This solves deals of
L<the "Golf" variant of patience and card solitaire|https://en.wikipedia.org/wiki/Golf_(patience)> . It is not related to L<Code golf|https://en.wikipedia.org/wiki/Code_golf>.
A script that encapsulates this application accepts a filename pointing
at the file containing the board or C<"-"> for specifying the standard input.

A board looks like this and can be generated for PySol FC using L<make_pysol_freecell_board.py|https://github.com/shlomif/fc-solve/blob/master/fc-solve/source/board_gen/make_pysol_freecell_board.py>

    Talon: TD KC 8H 8S 4S 4H KS 6D 8D 7C JD 9D 2H QD 3D AS
    Foundations: JH
    4C 7S 5S KH TC
    5H 2C 6C 6S TS
    QC QH 9C 7D AD
    5D 9S 3C 8C 4D
    2D 2S 6H AC QS
    7H KD JC 9H 3H
    AH JS TH 5C 3S

(PySol FC deal No. 24).

Other flags:

=over 4

=item * --version

=item * --help

=item * --man

=item * --queens-on-kings and --no-queens-on-kings

Enable and disable the ability to put queens on kings (which is disabled by default).
This is a common variation on the solitaire rules.

=item * --wrap-ranks and --no-wrap-ranks

Wrap ranks: allow putting aces on kings or kings on aces. If enabled it also sets
C<--queens-on-kings> .

=item * -o/--output solution_file.txt

Output to a solution file.

=back

More information about Golf Solitaire can be found at:

=over 4

=item * L<https://en.wikipedia.org/wiki/Golf_(patience)>

=back

=head1 METHODS

=head2 $self->new()

Instantiates an object.

=head2 $self->run()

Runs the application.

=head1 SEE ALSO

The Black Hole Solitaire Solvers homepage is at
L<http://www.shlomifish.org/open-source/projects/black-hole-solitaire-solver/>
and one can find there an implementation of this solver as a C library (under
the same licence), which is considerably faster and consumes less memory,
and has had some other improvements.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 BUGS

Please report any bugs or feature requests to
C<games-solitaire-blackhole-solver rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Solitaire-BlackHole-Solver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 Shlomi Fish

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

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-Solitaire-BlackHole-Solver>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Solitaire-BlackHole-Solver>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/G/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Games::Solitaire::BlackHole::Solver>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-games-solitaire-blackhole-solver at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Games-Solitaire-BlackHole-Solver>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/black-hole-solitaire>

  git clone https://github.com/shlomif/black-hole-solitaire

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/black-hole-solitaire/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
