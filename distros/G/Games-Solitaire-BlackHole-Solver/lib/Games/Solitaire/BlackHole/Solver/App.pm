package Games::Solitaire::BlackHole::Solver::App;
$Games::Solitaire::BlackHole::Solver::App::VERSION = '0.0.4';
use strict;
use warnings;

use 5.008;

use Getopt::Long;
use Pod::Usage;


sub new
{
    my $class = shift;
    return bless {}, $class;
}

my @ranks = ("A", 2 .. 9, qw(T J Q K));
my %ranks_to_n = (map { $ranks[$_] => $_ } 0 .. $#ranks);

my $card_re_str = '[' . join("", @ranks) . '][HSCD]';
my $card_re = qr{$card_re_str};

sub _get_rank
{
    return $ranks_to_n{substr(shift(), 0, 1)};
}

sub _calc_lines
{
    my $filename = shift;

    if ($filename eq "-")
    {
        return [<STDIN>];
    }
    else
    {
        open my $in, "<", $filename
            or die "Could not open $filename for inputting the board lines - $!";
        my @lines = <$in>;
        close($in);
        return \@lines;
    }
}

sub run
{
    my $output_fn;

    my ($help, $man, $version);

    GetOptions(
        "o|output=s" => \$output_fn,
        'help|h|?' => \$help,
        'man' => \$man,
        'version' => \$version,
    ) or pod2usage(2);

    pod2usage(1) if $help;
    pod2usage(-exitstatus => 0, -verbose => 2) if $man;

    if ($version)
    {
        print "black-hole-solve version $Games::Solitaire::BlackHole::Solver::App::VERSION\n";
        exit(0);
    }

    my $filename = shift(@ARGV);

    my $output_handle;

    if (defined($output_fn))
    {
        open ($output_handle, ">", $output_fn)
            or die "Could not open '$output_fn' for writing";
    }
    else
    {
        open ($output_handle, ">&STDOUT");
    }

    my @lines = @{_calc_lines($filename)};
    chomp(@lines);

    my $found_line = shift(@lines);

    my $init_foundation;
    if (my ($card) = $found_line =~ m{\AFoundations: ($card_re)\z})
    {
        $init_foundation = _get_rank($card);
    }
    else
    {
        die "Could not match first foundation line!";
    }

    my @board_cards = map { [split/\s+/, $_]} @lines;
    my @board_values = map { [map { _get_rank($_) } @$_ ] } @board_cards;

    my $init_state = "";

    vec($init_state, 0, 8) = $init_foundation;

    foreach my $col_idx (0 .. $#board_values)
    {
        vec($init_state, 4+$col_idx, 2) = scalar(@{$board_values[$col_idx]});
    }

    # The values of %positions is an array reference with the 0th key being the
    # previous state, and the 1th key being the column of the move.
    my %positions = ($init_state => []);

    my @queue = ($init_state);

    my %is_good_diff = (map { $_ => 1 } (1, $#ranks));

    my $verdict = 0;

    my $trace_solution = sub {
        my $final_state = shift;

        my $state = $final_state;
        my ($prev_state, $col_idx);

        my @moves;
        while (($prev_state, $col_idx) = @{$positions{$state}})
        {
            push @moves,
                $board_cards[$col_idx][vec($prev_state, 4+$col_idx, 2)-1]
                ;
        }
        continue
        {
            $state = $prev_state;
        }
        print {$output_handle} map { "$_\n" } reverse(@moves);
    };

    QUEUE_LOOP:
    while (my $state = pop(@queue))
    {
        # The foundation
        my $fnd = vec($state, 0, 8);
        my $no_cards = 1;

        # my @debug_pos;
        foreach my $col_idx (0 .. $#board_values)
        {
            my $pos = vec($state, 4+$col_idx, 2);
            # push @debug_pos, $pos;
            if ($pos)
            {
                $no_cards = 0;

                my $card = $board_values[$col_idx][$pos-1];
                if (exists($is_good_diff{
                    ($card - $fnd) % scalar(@ranks)
                }))
                {
                    my $next_s = $state;
                    vec($next_s, 0, 8) = $card;
                    vec($next_s, 4+$col_idx, 2)--;
                    if (! exists($positions{$next_s}))
                    {
                        $positions{$next_s} = [$state, $col_idx];
                        push(@queue, $next_s);
                    }
                }
            }
        }
        # print "Checking ", join(",", @debug_pos), "\n";
        if ($no_cards)
        {
            print {$output_handle} "Solved!\n";
            $trace_solution->($state);
            $verdict = 1;
            last QUEUE_LOOP;
        }
    }

    if (! $verdict)
    {
        print {$output_handle} "Unsolved!\n";
    }

    if (defined($output_fn))
    {
        close($output_handle);
    }

    exit(! $verdict);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Solitaire::BlackHole::Solver::App - a command line application
implemented as a class to solve the Black Hole solitaire.

=head1 VERSION

version 0.0.4

=head1 SYNOPSIS

    use Games::Solitaire::BlackHole::Solver::App;

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

=back

More information about Black Hole Solitaire can be found at:

=over 4

=item * L<http://en.wikipedia.org/wiki/Black_Hole_%28solitaire%29>

=item * L<http://pysolfc.sourceforge.net/doc/rules/blackhole.html>

=back

=head1 VERSION

version 0.0.4

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
and has had some otehr impovements.

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

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/games-solitaire-blackhole-solver/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Games::Solitaire::BlackHole::Solver

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Games-Solitaire-BlackHole-Solver>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Games-Solitaire-BlackHole-Solver>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Games-Solitaire-BlackHole-Solver>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Games-Solitaire-BlackHole-Solver>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-Solitaire-BlackHole-Solver>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

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

=cut
