#  SVG maze output
#  Performs transformation, cleanup, and printing of output of Games::Maze

package Games::Maze::SVG::Rect;

use base Games::Maze::SVG;

use Carp;
use Games::Maze;
use strict;
use warnings;

=head1 NAME

Games::Maze::SVG::Rect - Build rectangular mazes in SVG.

=head1 VERSION

Version 0.90

=cut

our $VERSION = 0.90;

=head1 SYNOPSIS

Games::Maze::SVG::Rect uses the Games::Maze module to create mazes in SVG.

    use Games::Maze::SVG;

    my $foo = Games::Maze::SVG->new( 'Rect' );
    ...

=cut

use constant DELTA_X => 10;
use constant DELTA_Y => 10;

# ----------------
#  Shape transformation tables
my %Blocks = (
    ': - |' => 'ul',
    ':-  |' => 'ur',
    ': -| ' => 'll',
    ':- | ' => 'lr',
    ':--  ' => 'h',
    '-::  ' => 'h',
    ':  ||' => 'v',
    '|  ::' => 'v',
    ':-   ' => 'l',
    ': -  ' => 'r',
    ':  | ' => 't',
    ':   |' => 'd',
    ': -||' => 'tr',
    ':- ||' => 'tl',
    ':--| ' => 'tu',
    ':-- |' => 'td',
    ':--||' => 'cross',
    ':.- |' => 'oul',
    ':- .|' => 'our',
    ': -.|' => 'oul',
    ':-. |' => 'our',
    ':.-.|' => 'oul',
    ':-..|' => 'our',
    ':.-| ' => 'oll',
    ':-.| ' => 'olr',
    ': -|.' => 'oll',
    ':- |.' => 'olr',
    ':.-|.' => 'oll',
    ':-.|.' => 'olr',
    ':--. ' => 'oh',
    '-::. ' => 'oh',
    ':-- .' => 'oh',
    '-:: .' => 'oh',
    ':. ||' => 'ov',
    '|. ::' => 'ov',
    ': .||' => 'ov',
    '| .::' => 'ov',
    ':- . ' => 'ol',
    ': -. ' => 'or',
    ':-.  ' => 'ol',
    ':.-  ' => 'or',
    ':-  .' => 'ol',
    ': - .' => 'or',
    ':. | ' => 'ot',
    ':.  |' => 'od',
    ': .| ' => 'ot',
    ': . |' => 'od',
    ':  |.' => 'ot',
    ':  .|' => 'od',
    ':. |.' => 'ot',
    ':. .|' => 'od',
    ': .|.' => 'ot',
    ': ..|' => 'od',
    ':.-||' => 'otr',
    ':-.||' => 'otl',
    ':--|.' => 'otu',
    ':--.|' => 'otd',
);

my %Walls = _get_wall_forms();

=head1 FUNCTIONS

=cut

# ----------------------------------------------
#  Subroutines

=over 4

=item new

Create a new Games::Maze::SVG::Rect object. Supports the following named
parameters:

=over 4

=item wallform

String naming the wall format. Legal values are bevel, round, roundcorners,
and straight.

=item crumb

String describing the breadcrumb design. Legal values are dash,
dot, line, and none

=item dir

Directory in which to find the ecmascript for the maze interactivity. Should
either be relative, or in URL form.

=back

=cut

sub new
{
    my $class = shift;

    my $obj = { Games::Maze::SVG::init_object( @_ ), @_, };

    if( !exists $Walls{ $obj->{wallform} } )
    {
        my $forms = join( ", ", sort keys %Walls );
        croak "\n'$obj->{wallform}' is not a valid wall form.\nTry one of: $forms\n\n";
    }

    $obj->{mazeparms}->{cell} = 'Quad';
    $obj->{mazeparms}->{form} = 'Rectangle';
    $obj->{scriptname}        = "rectmaze.es";
    $obj->{dx}                = DELTA_X;
    $obj->{dy}                = DELTA_Y;

    return bless $obj, $class;
}

=item is_hex

Method always returns false.

=cut

sub is_hex
{
    return;
}

=item is_hex_shaped

Method always returns false.

=cut

sub is_hex_shaped
{
    return;
}

=item set_wall_form

Set the wall format for the current maze.

=over 4

=item $form

String specifying a wall format.

=back

Returns a reference to self for chaining.

=cut

sub set_wall_form
{
    my $self = shift;
    my $form = shift;

    if( exists $Walls{$form} )
    {
        $self->{wallform} = $form;
    }
    else
    {
        my $forms = join( ", ", sort keys %Walls );
        croak "\n'$form' is not a valid wall form.\nTry one of: $forms\n\n";
    }
    return $self;
}

=item transform_grid

Convert the rectangular grid from ascii format to SVG definition
   references.

=over 4

=item $rows

Reference to an array of rows

=item $walls

String specifying wall format.

=back

=cut

sub transform_grid
{
    my $self  = shift;
    my $rows  = shift;
    my $walls = shift;
    my @out   = ();

    my $sp = 'bevel' eq ( $walls || q{} ) ? q{.} : q{ };
    remove_horiz_padding( $rows );

    # transform the printout into block commands
    my $height = @{$rows};
    my $width  = @{ $rows->[0] };
    for ( my $r = 0; $r < $height; ++$r )
    {
        for ( my $c = 0; $c < $width; ++$c )
        {
            if( $rows->[$r]->[$c] eq q{ } )
            {
                $out[$r]->[$c] = 0;
            }
            else
            {

                # convert the cell and its neighbors into a signature
                my $sig = $rows->[$r]->[$c]    # cell
                    . ( $c == 0 ? $sp : $rows->[$r]->[ $c - 1 ] )    # left neighbor
                    . ( $rows->[$r]->[ $c + 1 ] || $sp )             # right neighbor
                    . ( $r == 0 ? $sp : $rows->[ $r - 1 ]->[$c] )    # up neighbor
                    . ( $rows->[ $r + 1 ] ? $rows->[ $r + 1 ]->[$c] : $sp );    # down neighbor
                      # convert the signature into the block name
                croak "Missing block for '$sig'.\n" unless exists $Blocks{$sig};
                $out[$r]->[$c] = $Blocks{$sig};
            }
        }
    }

    return @{$rows} = @out;
}

=item remove_horiz_padding

Remove the extra horizontal space inserted to regularize the look
 of the rectangular maze

=over 4

=item $rows

Reference to an array of rows

=back

=cut

sub remove_horiz_padding
{
    my $rows = shift;

    for ( my $i = $#{ $rows->[0] }; $i > 0; $i -= 3 )
    {
        splice( @{$_}, $i - 1, 1 ) foreach ( @{$rows} );
    }

    # apparently trailing spaces that I wasn't aware of.
    foreach my $r ( @{$rows} )
    {
        pop @{$r} if $r->[-1] eq q{ };
    }

    return;
}

=item wall_definitions

Method that returns the definition for the shapes used to build the walls.

=cut

sub wall_definitions
{
    my $self = shift;

    return $Walls{ $self->{wallform} };
}

# _get_wall_forms
#
#Extract the wall forms from the DATA file handle.
#
#Returns a hash of wall forms.

sub _get_wall_forms
{
    local $/ = "\n===\n";
    chomp( my @list = <DATA> );

    $/ = "\n";
    chomp( @list );

    return @list;
}

=item convert_start_position

Convert the supplied x and y coordinates into the appropriate real coordinates
for a start position on this map.

=over 4

=item $x x coord from the maze

=item $y y coord from the maze

=back

returns a two element list containing (x, y).

=cut

sub convert_start_position
{
    my $self = shift;
    my ( $x, $y ) = @_;

    $x = 2 * ( $x - 1 ) + 1;
    $y = 2 * ( $y - 1 );

    return ( $x, $y );
}

=item convert_end_position

Convert the supplied x and y coordinates into the appropriate real coordinates
for a end position on this map.

=over 4

=item $x x coord from the maze

=item $y y coord from the maze

=back

returns a two element list containing (x, y).

=cut

sub convert_end_position
{
    my $self = shift;
    my ( $x, $y ) = @_;

    $x = 2 * ( $x - 1 ) + 1;
    $y = 2 * ( $y - 1 ) + 2;

    return ( $x, $y );
}

=item convert_sign_position

Convert the supplied x and y coordinates into the appropriate real coordinates
for a the position of the exit sign.

=over 4

=item $x x coord from the maze

=item $y y coord from the maze

=back

returns a two element list containing (x, y).

=cut

sub convert_sign_position
{
    my $self = shift;
    my ( $x, $y ) = @_;

    $x *= $self->dx();
    $y *= $self->dy();

    $x += 0.5 * $self->dx();

    # adjust bottom
    if( $y > $self->{height} / 2 )
    {
        $y += 2 * $self->dy();
    }
    else
    {
        $y -= $self->dy();
    }

    return ( $x, $y );
}

=back

=head1 AUTHOR

G. Wade Johnson, C<< <wade@anomaly.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-game-maze-svg@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-Maze-SVG>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks go to Valen Johnson and Jason Wood for extensive test play of the
mazes.

=head1 COPYRIGHT & LICENSE

Copyright 2004-2006 G. Wade Johnson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__
straight
===
      <path id="ul" d="M5,10 v-5 h5"/>
      <path id="ur" d="M0,5  h5  v5"/>
      <path id="ll" d="M5,0  v5  h5"/>
      <path id="lr" d="M0,5  h5  v-5"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <path id="tr" d="M5,0  v10 M5,5 h5"/>
      <path id="tl" d="M5,0  v10 M0,5 h5"/>
      <path id="tu" d="M0,5  h10 M5,0 v5"/>
      <path id="td" d="M0,5  h10 M5,5 v5"/>
      <path id="cross" d="M0,5 h10 M5,0 v10"/>
===
roundcorners
===
      <path id="ul" d="M5,10 Q5,5 10,5"/>
      <path id="ur" d="M0,5  Q5,5 5,10"/>
      <path id="ll" d="M5,0  Q5,5 10,5"/>
      <path id="lr" d="M0,5  Q5,5 5,0"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <path id="tr" d="M5,0  v10 M5,5 h5"/>
      <path id="tl" d="M5,0  v10 M0,5 h5"/>
      <path id="tu" d="M0,5  h10 M5,0 v5"/>
      <path id="td" d="M0,5  h10 M5,5 v5"/>
      <path id="cross" d="M0,5 h10 M5,0 v10"/>
===
round
===
      <path id="ul" d="M5,10 Q5,5 10,5"/>
      <path id="ur" d="M0,5  Q5,5 5,10"/>
      <path id="ll" d="M5,0  Q5,5 10,5"/>
      <path id="lr" d="M0,5  Q5,5 5,0"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <path id="tr" d="M5,0  Q5,5 10,5 Q5,5 5,10"/>
      <path id="tl" d="M5,0  Q5,5 0,5  Q5,5 5,10"/>
      <path id="tu" d="M0,5  Q5,5 5,0  Q5,5 10,5"/>
      <path id="td" d="M0,5  Q5,5 5,10 Q5,5 10,5"/>
      <path id="cross"
                    d="M0,5 Q5,5 5,0  Q5,5 10,5 Q5,5 5,10 Q5,5 0,5"/>
===
bevel
===
      <path id="ul" d="M5,10.1 v-.1 l5,-5 h.1"/>
      <path id="ur" d="M-.1,5 h.1 l5,5 v.1"/>
      <path id="ll" d="M5,-.1 v.1 l5,5 h.1"/>
      <path id="lr" d="M-.1,5 h.1 l5,-5 v-.1"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <polygon id="tr" points="5,0 5,10 10,5"/>
      <polygon id="tl" points="5,0 5,10 0,5"/>
      <polygon id="tu" points="0,5 10,5 5,0"/>
      <polygon id="td" points="0,5 10,5 5,10"/>
      <polygon id="cross" points="0,5 5,10 10,5 5,0"/>
      <path id="oul" d="M5,10.1 v-.1 l5,-5 h.1"/>
      <path id="our" d="M-.1,5 h.1 l5,5 v.1"/>
      <path id="oll" d="M5,-.1 v.1 l5,5 h.1"/>
      <path id="olr" d="M-.1,5 h.1 l5,-5 v-.1"/>
      <path id="oh"  d="M0,5  h10"/>
      <path id="ov"  d="M5,0  v10"/>
      <path id="ol"  d="M0,5  h5"/>
      <path id="or"  d="M5,5  h5"/>
      <path id="ot"  d="M5,0  v5"/>
      <path id="od"  d="M5,5  v5"/>
      <path id="otr" d="M5,0 l5,5 l-5,5"/>
      <path id="otl" d="M5,0 l-5,5 l5,5"/>
      <path id="otu" d="M0,5 l5,-5 l5,5"/>
      <path id="otd" d="M0,5 l5,5 l5,-5"/>
