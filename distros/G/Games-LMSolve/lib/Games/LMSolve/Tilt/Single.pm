package Games::LMSolve::Tilt::Single;
$Games::LMSolve::Tilt::Single::VERSION = '0.14.0';
use strict;
use warnings;

use Games::LMSolve::Tilt::Base;

use Games::LMSolve::Input;

use vars qw(@ISA);

@ISA = qw(Games::LMSolve::Tilt::Base);

sub input_board
{
    my $self     = shift;
    my $filename = shift;

    my $spec = {
        'dims'   => { 'type' => "xy(integer)", 'required' => 1 },
        'start'  => { 'type' => "xy(integer)", 'required' => 1 },
        'goal'   => { 'type' => "xy(integer)", 'required' => 1 },
        'layout' => { 'type' => "layout",      'required' => 1 },
    };

    my $input_obj = Games::LMSolve::Input->new();

    my $input_fields = $input_obj->input_board( $filename, $spec );

    my ( $width, $height ) =
        @{ $input_fields->{'dims'}->{'value'} }{ 'x', 'y' };
    my ( $start_x, $start_y ) =
        @{ $input_fields->{'start'}->{'value'} }{ 'x', 'y' };
    my ( $goal_x, $goal_y ) =
        @{ $input_fields->{'goal'}->{'value'} }{ 'x', 'y' };

    if ( ( $start_x >= $width ) || ( $start_y >= $height ) )
    {
        die
"The starting position is out of bounds of the board in file \"$filename\"!\n";
    }

    if ( ( $goal_x >= $width ) || ( $goal_y >= $height ) )
    {
        die
"The goal position is out of bounds of the board in file \"$filename\"!\n";
    }

    my ( $horiz_walls, $vert_walls ) =
        $input_obj->input_horiz_vert_walls_layout( $width, $height,
        $input_fields->{'layout'} );

    $self->{'width'}       = $width;
    $self->{'height'}      = $height;
    $self->{'goal_x'}      = $goal_x;
    $self->{'goal_y'}      = $goal_y;
    $self->{'horiz_walls'} = $horiz_walls;
    $self->{'vert_walls'}  = $vert_walls;

    return [ $start_x, $start_y ];
}

sub pack_state
{
    my $self         = shift;
    my $state_vector = shift;

    return pack( "cc", @$state_vector );
}

sub unpack_state
{
    my $self  = shift;
    my $state = shift;
    return [ unpack( "cc", $state ) ];
}

sub display_state
{
    my $self  = shift;
    my $state = shift;
    my ( $x, $y ) = ( map { $_ + 1 } @{ $self->unpack_state($state) } );
    return sprintf("($x,$y)");
}

sub check_if_final_state
{
    my $self = shift;

    my $coords = shift;

    return (   ( $coords->[0] == $self->{'goal_x'} )
            && ( $coords->[1] == $self->{'goal_y'} ) );
}

sub enumerate_moves
{
    my $self   = shift;
    my $coords = shift;

    return (qw(u d l r));
}

sub perform_move
{
    my $self = shift;

    my $coords = shift;
    my $move   = shift;

    my ( $new_coords, $intermediate_states ) =
        $self->move_ball_to_end( $coords, $move );

    return $new_coords;
}

1;

__END__

=pod

=head1 NAME

Games::LMSolve::Tilt::Single - driver for solving the single-goal tilt mazes

=head1 VERSION

version 0.14.0

=head1 SYNOPSIS

NA - should not be used directly.

=head1 METHODS

=head2 $self->input_board()

Overrided.

=head2 $self->pack_state()

Overrided.

=head2 $self->unpack_state()

Overrided.

=head2 $self->display_state()

Overrided.

=head2 $self->check_if_unsolvable()

Overrided.

=head2 $self->check_if_final_state()

Overrided.

=head2 $self->enumerate_moves()

Overrided.

=head2 $self->perform_move()

Overrided.

=head1 SEE ALSO

L<Games::LMSolve::Base>.

For more about single-goal tilt mazes see:

L<http://www.clickmazes.com/newtilt/ixtilt2d.htm>

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

  perldoc Games::LMSolve::Tilt::Single

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
