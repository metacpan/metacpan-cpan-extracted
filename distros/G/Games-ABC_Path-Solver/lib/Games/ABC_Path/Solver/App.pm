package Games::ABC_Path::Solver::App;

use warnings;
use strict;

=head1 NAME

Games::ABC_Path::Solver::App - a class wrapping a command line app for
solving ABC Path

=head1 VERSION

Version 0.4.1

=cut

our $VERSION = '0.4.1';

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Games::ABC_Path::Solver::App;

    Games::ABC_Path::Solver::App->new({argv => [@ARGV] })->run;

=head1 FUNCTIONS

=head2 new

The constructor. Accepts a hash ref of named arguments. Currently only C<'argv'>
which should point to an array ref of command-line arguments.

=head2 run

Run the application based on the arguments in the constructor.

=cut

use base 'Games::ABC_Path::Solver::Base';

use Carp;
use Getopt::Long;
use Pod::Usage;

use Games::ABC_Path::Solver::Board;

sub _argv
{
    my $self = shift;

    if (@_) {
        $self->{_argv} = shift;
    }

    return $self->{_argv};
}

sub _init
{
    my ($self, $args) = @_;

    $self->_argv([@{$args->{argv}}]);

    return;
}

sub run
{
    my $self = shift;

    local @ARGV = @{$self->_argv};

    my $man = 0;
    my $help = 0;
    my $gen_template = 0;
    GetOptions(
        'help|h' => \$help,
        man => \$man,
        'gen-v1-template' => \$gen_template,
    )
        or pod2usage(2);

    if ($help)
    {
        pod2usage(1);
    }
    elsif ($man)
    {
        pod2usage(-verbose => 2);
    }
    elsif ($gen_template)
    {
        print <<'EOF';
ABC Path Solver Layout Version 1:
???????
?     ?
?     ?
?     ?
?   A ?
?     ?
???????
EOF
    }
    else
    {

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

        print @{$solver->get_successes_text_tables};
    }

    exit(0);
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-abc_path-solver at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-ABC_Path-Solver>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::ABC_Path::Solver::App

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

=head1 SEE ALSO

L<Games::ABC_Path::Solver> , L<Games::ABC_Path::Solver::Board> .

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

1; # End of Games::ABC_Path::Solver::App
