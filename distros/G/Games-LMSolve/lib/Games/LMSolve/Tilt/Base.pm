package Games::LMSolve::Tilt::Base;
$Games::LMSolve::Tilt::Base::VERSION = '0.12.0';
use strict;
use warnings;

use vars qw(@ISA);

use Games::LMSolve::Base;

@ISA=qw(Games::LMSolve::Base);

# x - the x step
# y - the y step
# w - which wall
my %moves_specs =
(
    'u' => { 'x' => 0, 'y' => -1, 'w' => 'h'},
    'd' => { 'x' => 0, 'y' => 1, 'w' => 'h'},
    'l' => { 'x' => -1, 'y' => 0, 'w' => 'v'},
    'r' => { 'x' => 1, 'y' => 0, 'w' => 'v'},
);

# This function moves the ball to the end.
# It returns the new position as well as all the intermediate positions.
sub move_ball_to_end
{
    my $self = shift;

    my $coords = shift;
    my $move = shift;

    my ($x,$y) = @$coords;
    my @intermediate_coords = ();

    if (!exists($moves_specs{$move}))
    {
        die "Unknown move \"$move\"!";
    }

    my $horiz_walls = $self->{'horiz_walls'};
    my $vert_walls = $self->{'vert_walls'};

    my ($x_dir, $y_dir, $which_wall) = @{$moves_specs{$move}}{'x','y','w'};

    push @intermediate_coords, [$x, $y];
    while (! (($which_wall eq 'v') ?
        ($vert_walls->[$y]->[$x+(($x_dir<0)?0:1)]) :
        ($horiz_walls->[$y + (($y_dir<0)?0:1)]->[$x])
        ))
    {
        $x += $x_dir;
        $y += $y_dir;
        push @intermediate_coords, [$x, $y];
    }

    return ([$x,$y], \@intermediate_coords);
}

1;

__END__

=pod

=head1 NAME

Games::LMSolve::Tilt::Base - base class for the tilt mazes' drivers.

=head1 VERSION

version 0.12.0

=head1 SYNOPSIS

NA - should not be used directly.

=head1 VERSION

version 0.12.0

=head1 METHODS

=head2 $self->move_ball_to_end()

Moves the ball to the end.

=head1 SEE ALSO

L<Games::LMSolve::Base>.

For more about tilt mazes see:

http://www.clickmazes.com/indext.htm

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org/>

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2007 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/lm-solve-source/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Games::LMSolve::Tilt::Base

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Games-LMSolve>

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

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Games-LMSolve>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

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

  git clone git://github.com/shlomif/lm-solve-source.git

=cut
