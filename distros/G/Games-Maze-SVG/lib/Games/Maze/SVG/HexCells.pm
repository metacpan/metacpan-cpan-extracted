#  SVG maze output
#  Handles the common code between Hex and RectHex mazes.

package Games::Maze::SVG::HexCells;

use base Games::Maze::SVG;

use Carp;
use Games::Maze;
use strict;
use warnings;

=head1 NAME

Games::Maze::SVG::HexCells - Base class for Hex and RectHex mazes.

=head1 VERSION

Version 0.90

=cut

our $VERSION = 0.90;

=head1 SYNOPSIS

The class is intended to only be used as a base class. It should not
instatiated directly.

=cut

use constant DELTA_X => 10;
use constant DELTA_Y => 10;

# ----------------
#  Shape transformation tables

# in-line
# l r dl dr
my %Blocks = (
    ' _/ '  => 'tl',
    '_  \\' => 'tr',
    '\\_  ' => 'bl',
    '_/  '  => 'br',
    ' / \\' => 'cl',
    '\\ / ' => 'cr',
    '__  '  => 'hz',
    '_   '  => 'hzl',
    ' _  '  => 'hzr',
    '\\_/ ' => 'yr',
    '_/ \\' => 'yl',
    '\\   ' => 'slb',
    '   \\' => 'slt',
    ' /  '  => 'srb',
    '  / '  => 'srt',
    '   /'  => 0,
    '  \\ ' => 0,
    '/ \\_' => 0,
    '  __'  => 0,
    ' \\_/' => 0,
    ' \\  ' => 0,
    '/   '  => 0,
    '  \\_' => 0,
    '  _/'  => 0,
    '    '  => 0,
    '/ \\ ' => 0,
    ' \\ /' => 0,
    '/  _'  => 0,
    ' \\_ ' => 0,
    '   _'  => 0,
    '  _ '  => 0,
    '/   '  => 0,
);

# Between lines
# l r dl dr
my %BlocksBetween = (
    '   /'  => 'sr',
    ' \\_/' => 'sr',
    '  _/'  => 'sr',
    ' \\ /' => 'sr',
    '_  \\' => 'sl',
    ' / \\' => 'sl',
    '   \\' => 'sl',
    '_/ \\' => 'sl',
    ' _/ '  => q{$},
    '  \\ ' => q{$},
    '/ \\_' => q{$},
    '\\ / ' => q{$},
    '  \\_' => q{$},
    '/ \\ ' => q{$},
    '\\_/ ' => q{$},
    '__  '  => 0,
    '  __'  => 0,
    '    '  => 0,
    '_/  '  => 0,
    '/  _'  => 0,
    ' \\_ ' => 0,
    '\\   ' => 0,
    '_   '  => 0,
    '   _'  => 0,
    '  _ '  => 0,
    ' _  '  => 0,
    '\\_  ' => 0,
    ' \\  ' => 0,
    '  / '  => 0,
    '/   '  => 0,
    ' /  '  => 0,
);

my %Walls = _get_wall_forms();

=head1 FUNCTIONS

=cut

# ----------------------------------------------
#  Subroutines

=over 4

=item new

Create a new Games::Maze::SVG object. Supports the following named parameters:

Takes one positional parameter that is the maze type: Rect, RectHex, or Hex

=over 4

=item wallform

String naming the wall format. Legal values are bevel, round, roundcorners,
and straight.

=item crumb

String describing the breadcrumb design. Legal values are dash,
dot, line, and none

=item dx

The size of the tiles in the X direction.

=item dy

The size of the tiles in the Y direction.

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

    $obj->{mazeparms}->{cell} = 'Hex';
    $obj->{scriptname}        = "hexmaze.es";
    $obj->{dx}                = DELTA_X;
    $obj->{dy}                = DELTA_Y;

    return bless $obj, $class;
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

Convert the hexagonal grid from ascii format to SVG definition
 references.

=over 4

=item $rows

Reference to an array of rows

=item $walls

String specifying wall format. (Unused at present.)

=back

=cut

sub transform_grid
{
    my $self  = shift;
    my $rows  = shift;
    my $walls = shift;
    my @out   = ();

    # transform the printout into block commands
    my $height = @{$rows};
    my $width  = @{ $rows->[0] } + 2;

    for ( my $r = 0; $r < $height - 1; ++$r )
    {

        # on line
        push @out, _calc_on_line( $rows, $r, $width );

        # between
        push @out, _calc_between_line( $rows, $r, $width );
    }
    push @out, _calc_on_line( $rows, $height - 1, $width );

    return @{$rows} = @out;
}

sub _calc_between_line
{
    my $rows  = shift;
    my $index = shift;
    my $width = shift;
    my @out   = ();

    for ( my $c = 0; $c < $width; ++$c )
    {
        my $sig =
              ( $c ? $rows->[$index][ $c - 1 ] || q{ } : q{ } )
            . ( $rows->[$index][$c] || q{ } )
            . ( $c ? $rows->[ $index + 1 ][ $c - 1 ] || q{ } : q{ } )
            . ( $rows->[ $index + 1 ][$c] || q{ } );

        croak "Missing between block for '$sig'.\n" unless exists $BlocksBetween{$sig};

        push @out, $BlocksBetween{$sig};
    }

    return \@out;
}

sub _calc_on_line
{
    my $rows  = shift;
    my $index = shift;
    my $width = shift;
    my @out   = ();

    for ( my $c = 0; $c < $width; ++$c )
    {
        my $sig =
              ( $c ? $rows->[$index][ $c - 1 ] || q{ } : q{ } )
            . ( $rows->[$index][$c] || q{ } )
            . ( $c ? $rows->[ $index + 1 ][ $c - 1 ] || q{ } : q{ } )
            . ( $rows->[ $index + 1 ][$c] || q{ } );

        croak "Missing block for '$sig'.\n" unless exists $Blocks{$sig};

        push @out, $Blocks{$sig};
    }

    return \@out;
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

    $x = 3 * ( $x - 1 ) + 2;
    $y = 4 * ( $y - 1 );

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

    $x = 3 * ( $x - 1 ) + 2;
    $y = 4 * ( $y ) + 2;

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
      <path id="hz" d="M0,5 h10"/>
      <path id="hzr" d="M5,5 h5"/>
      <path id="hzl" d="M0,5 h5"/>
      <path id="tl" d="M10,5 h-5 L2.5,10"/>
      <path id="tr" d="M0,5 h5 L7.5,10"/>
      <path id="br" d="M0,5 h5 L7.5,0"/>
      <path id="bl" d="M10,5 h-5 L2.5,0"/>
      <path id="sl" d="M7.5,0 L12.5,10"/>
      <path id="sr" d="M12.5,0 L7.5,10"/>
      <path id="slt" d="M5,5 L7.5,10"/>
      <path id="slb" d="M5,5 L2.5,0"/>
      <path id="srt" d="M5,5 L2.5,10"/>
      <path id="srb" d="M5,5 L7.5,0"/>
      <path id="cr" d="M2.5,0 L5,5 L2.5,10"/>
      <path id="cl" d="M7.5,0 L5,5 L7.5,10"/>
      <path id="yr" d="M2.5,0 L5,5 L2.5,10 M5,5 h5"/>
      <path id="yl" d="M7.5,0 L5,5 L7.5,10 M5,5 h-5"/>
===
roundcorners
===
      <path id="hz" d="M0,5 h10"/>
      <path id="hzr" d="M5,5 h5"/>
      <path id="hzl" d="M0,5 h5"/>
      <path id="tl" d="M10,5 Q6,6 2.5,10"/>
      <path id="tr" d="M0,5 Q4,6 7.5,10"/>
      <path id="br" d="M0,5 Q5,5 7.5,0"/>
      <path id="bl" d="M10,5 Q6,4 2.5,0"/>
      <path id="sl" d="M7.5,0 L12.5,10"/>
      <path id="sr" d="M12.5,0 L7.5,10"/>
      <path id="slt" d="M5,5 L7.5,10"/>
      <path id="slb" d="M5,5 L2.5,0"/>
      <path id="srt" d="M5,5 L2.5,10"/>
      <path id="srb" d="M5,5 L7.5,0"/>
      <path id="cr" d="M2.5,0 Q4,5 2.5,10"/>
      <path id="cl" d="M7.5,0 Q6,5 7.5,10"/>
      <path id="yr" d="M2.5,0 L5,5 L2.5,10 M5,5 h5"/>
      <path id="yl" d="M7.5,0 L5,5 L7.5,10 M5,5 h-5"/>
===
round
===
      <path id="hz" d="M0,5 h10"/>
      <path id="hzr" d="M5,5 h5"/>
      <path id="hzl" d="M0,5 h5"/>
      <path id="tl" d="M10,5 Q6,6 2.5,10"/>
      <path id="tr" d="M0,5 Q4,6 7.5,10"/>
      <path id="br" d="M0,5 Q5,5 7.5,0"/>
      <path id="bl" d="M10,5 Q6,4 2.5,0"/>
      <path id="sl" d="M7.5,0 L12.5,10"/>
      <path id="sr" d="M12.5,0 L7.5,10"/>
      <path id="slt" d="M5,5 L7.5,10"/>
      <path id="slb" d="M5,5 L2.5,0"/>
      <path id="srt" d="M5,5 L2.5,10"/>
      <path id="srb" d="M5,5 L7.5,0"/>
      <path id="cr" d="M2.5,0 Q4,5 2.5,10"/>
      <path id="cl" d="M7.5,0 Q6,5 7.5,10"/>
      <path id="yr" d="M2.5,0 Q4,5 2.5,10 Q6,5 10,5 Q5,4 2.5,0"/>
      <path id="yl" d="M7.5,0 Q6,5 7.5,10 Q4,6 0,5 Q4,4 7.5,0"/>
