package Games::ABC_Path::Generator::App;

use 5.006;
use strict;
use warnings;

use Pod::Usage qw(pod2usage);

use base 'Games::ABC_Path::Generator::Base';

use Getopt::Long qw(GetOptionsFromArray);

use Games::ABC_Path::Generator;

=head1 NAME

Games::ABC_Path::Generator::App - command line application for the ABC Path generator.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';


=head1 SYNOPSIS

    use Games::ABC_Path::Generator::App;

    my $app = Games::ABC_Path::Generator::App->new({ argv => [@ARGV], },);
    $app->run();

=head1 SUBROUTINES/METHODS

=head2 Games::ABC_Path::Generator::App->new({ argv => [@ARGV], },);

Initialize from @ARGV .

=cut

sub _argv
{
    my $self = shift;

    if (@_)
    {
        $self->{_argv} = shift;
    }

    return $self->{_argv};
}

sub _init
{
    my ($self, $args) = @_;

    $self->_argv($args->{argv});

    return;
}

=head2 $app->run()

Runs the application.

=cut

sub run
{
    my ($self) = @_;

    my $seed;
    my $mode = 'riddle';
    my $man = 0;
    my $help = 0;
    if (!GetOptionsFromArray(
            $self->_argv(),
            'seed=i' => \$seed,
            'mode=s' => \$mode,
            'help|h' => \$help,
            man => \$man,
        ))
    {
        pod2usage(2);
    }

    if ($help)
    {
        pod2usage(1);
    }
    elsif ($man)
    {
        pod2usage(-verbose => 2);
    }
    elsif (!defined($seed))
    {
        die "Seed not specified! See --help.";
    }
    else
    {
        my $gen = Games::ABC_Path::Generator->new({ seed => $seed, });

        if ($mode eq 'final')
        {
            print $gen->calc_final_layout()->as_string({});
        }
        elsif ($mode eq 'riddle')
        {
            my $riddle = $gen->calc_riddle();

            my $layout_string = $riddle->get_final_layout_as_string({});

            my $riddle_string = $riddle->get_riddle_v1_string;

            print sprintf(
                "ABC Path Solver Layout Version 1:\n%s",
                $riddle_string,
            );
        }

    }
    return;
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-abc_path-generator at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-ABC_Path-Generator>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::ABC_Path::Generator::App


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


=head1 ACKNOWLEDGEMENTS


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

1; # End of Games::ABC_Path::Generator::App
