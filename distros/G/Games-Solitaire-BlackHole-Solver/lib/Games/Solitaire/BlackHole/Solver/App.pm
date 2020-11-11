package Games::Solitaire::BlackHole::Solver::App;
$Games::Solitaire::BlackHole::Solver::App::VERSION = '0.6.0';
use 5.014;
use Moo;

extends('Games::Solitaire::BlackHole::Solver::App::Base');


sub run
{
    my $self      = shift;
    my $RANK_KING = $self->_RANK_KING;

    $self->_process_cmd_line(
        {
            extra_flags => {}
        }
    );

    $self->_set_up_solver( 0, [ 1, $RANK_KING ] );

    my $verdict = 0;

    $self->_next_task;

QUEUE_LOOP:
    while ( my $state = $self->_get_next_state_wrapper )
    {
        # The foundation
        my $no_cards = 1;

        my @_pending;

        if (1)
        {
            $self->_find_moves( \@_pending, $state, \$no_cards );
        }

        if ($no_cards)
        {
            $self->_trace_solution( $state, );
            $verdict = 1;
            last QUEUE_LOOP;
        }
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

Games::Solitaire::BlackHole::Solver::App - a command line application
implemented as a class to solve the Black Hole solitaire.

=head1 VERSION

version 0.6.0

=head1 SYNOPSIS

    use Games::Solitaire::BlackHole::Solver::App ();

    my $app = Games::Solitaire::BlackHole::Solver::App->new;

    $app->run();

And then from the command-line:

    $ black-hole-solve myboard.txt

=head1 DESCRIPTION

A script that encapsulates this application accepts a filename pointing
at the file containing the board or C<"-"> for specifying the standard input.

A board looks like this and can be generated for PySol using the
make_pysol_board.py in the contrib/ .

    Foundations: AS
    KD JH JS
    8H 4C 7D
    7H TD 4H
    JD 9S 5S
    AH 3S 6H
    9C 9D 8S
    7S 2H 6S
    AC JC QH
    QD 4S TS
    6C QS QC
    8D 3D KH
    5H 5C 8C
    4D KC TC
    6D 3C 3H
    2C KS TH
    AD 5D 7C
    9H 2S 2D

Other flags:

=over 4

=item * --version

=item * --help

=item * --man

=item * -o/--output solution_file.txt

Output to a solution file.

=item * --quiet

Do not emit the solution.

=item * --next-task

Add a new task (see L<https://en.wikipedia.org/wiki/Context_switch> ).

=item * --task-name [name]

Name the task.

=item * --seed [index]

Set the PRNG seed for the task.

=item * --prelude [num-iters]@[task-name],[num-iters2]@[task-name2]

Start from running the iters counts for each task IDs. Similar
to L<https://fc-solve.shlomifish.org/docs/distro/USAGE.html#prelude_flag> .

=back

More information about Black Hole Solitaire can be found at:

=over 4

=item * L<http://en.wikipedia.org/wiki/Black_Hole_%28solitaire%29>

=item * L<http://pysolfc.sourceforge.net/doc/rules/blackhole.html>

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
L<https://github.com/shlomif/games-solitaire-blackhole-solver/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
