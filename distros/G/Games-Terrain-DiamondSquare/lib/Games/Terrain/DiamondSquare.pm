package Games::Terrain::DiamondSquare;
{
  $Games::Terrain::DiamondSquare::VERSION = '0.02';
}

## ABSTRACT: Random terrain generation via the Diamond Square algorithm

use strict;
use warnings;
use List::Util 'sum';
use POSIX 'floor';
use base 'Exporter';
our @EXPORT_OK = 'create_terrain';

my ( $FULL_SIZE, $ROUGHNESS );
use constant NW => 0;
use constant NE => 1;
use constant SW => 2;
use constant SE => 3;

sub create_terrain {
    my ( $height, $width, $roughness ) = @_;
    $roughness ||= .5;

    # seed the four corners of the grid with random color values
    my @corners = map {rand} 1 .. 4;

    $ROUGHNESS = $roughness;
    $FULL_SIZE = $height + $width;
    my @points;
    subdivide( \@points, 0, 0, $height, $width, \@corners );
    return \@points;
}

sub subdivide {
    my ( $points, $x, $y, $height, $width, $corners ) = @_;

    if ( $height > 1 || $width > 1 ) {
        my $new_height  = floor( $height / 2 );
        my $new_width = floor( $width / 2 );

        my $middle
          = sum(@$corners) / 4 + displace( $new_height + $new_width );
        my $edge_1 = ( $corners->[NW] + $corners->[NE] ) / 2;
        my $edge_2 = ( $corners->[NE] + $corners->[SW] ) / 2;
        my $edge_3 = ( $corners->[SW] + $corners->[SE] ) / 2;
        my $edge_4 = ( $corners->[SE] + $corners->[NW] ) / 2;

        $_ = constrain($_)
          foreach $middle, $edge_1, $edge_2, $edge_3, $edge_4;

        # do it again for each of the four new grids.
        subdivide(
            $points, $x, $y, $new_height, $new_width,
            [ $corners->[NW], $edge_1, $middle, $edge_4 ]
        );
        subdivide(
            $points, $x + $new_height, $y, $height - $new_height, $new_width,
            [ $edge_1, $corners->[NE], $edge_2, $middle ]
        );
        subdivide(
            $points, $x + $new_height, $y + $new_width, $height - $new_height,
            $width - $new_width,
            [ $middle, $edge_2, $corners->[SW], $edge_3 ]
        );
        subdivide(
            $points, $x, $y + $new_width, $new_height, $width - $new_width,
            [ $edge_4, $middle, $edge_3, $corners->[SE] ]
        );
    }
    else # this is the "base case," where each grid piece is less than the size of a pixel.
    {

 # the corners of the grid piece will be averaged and drawn as a single pixel.
        my $c = sum(@$corners) / 4;

        $points->[$x][$y] = $c;
        if ( $height == 2 ) {
            $points->[ $x + 1 ][$y] = $c;
        }
        if ( $width == 2 ) {
            $points->[$x][ $y + 1 ] = $c;
        }
        if ( $height == 2 and $width == 2 ) {
            $points->[ $x + 1 ][ $y + 1 ] = $c;
        }
    }
    return;
}

sub constrain {
    my $num = shift;
    return
        $num < 0 ? 0
      : $num > 1 ? 1
      :            $num;
}

sub displace {
    my $curr_size = shift;

    my $max = $curr_size / $FULL_SIZE * $ROUGHNESS;
    return ( rand() - 0.5 ) * $max;
}

1;

__END__

=pod

=head1 NAME

Games::Terrain::DiamondSquare - Random terrain generation via the Diamond Square algorithm

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Games::Terrain::DiamondSquare 'create_terrain';
 my $terrain = create_terrain( $height, $width, $roughness );

 foreach my $row (@$terrain) {
     foreach my $square (@$row) {
         # $square is a "height" value from 0.0 to 1.0. Do with it as you will
     }
 }

=head1 DESCRIPTION

From Wikipedia: The diamond-square algorithm is a method for generating highly
realistic heightmaps for computer graphics. It's a fractal method of
generating random terrain "heights" which is reasonably fast (though this
being Perl, it's not fast enough for, say, real-time rendering).  A proper C
implementation would be nice here.

There is a C<tohtml.pl> example in the C<examples> directory of this
distribution.

=head1 EXPORT

=head2 C<create_terrain>

 my $terrain = create_terrain( $height, $width );
 # or
 my $terrain = create_terrain( $height, $width, $roughness );

This function accepts integer C<$height> and C<$width> arguments and an
optional C<$roughness> parameter. The latter is a float from 0.0 to 1.0
indicating how "rough" the map should be. Lower numbers generate smoother
maps. Defaults to C<0.5>.

=head1 EXAMPLE

Here's an example terrain generated from a test script:

  $$$$$$$$$$$$$$$$$$$$$$$####################*********************!**!!!!!!!!!!!!!
  $$$$$$$$$$$$$$$$$$$$$$#####################****************************!!!!!!!!!
  $$$$$$$$$$$$$$$$$$$$$$###########################*#*##*#*####************!!!!!!!
  ####$####$#$#$$$$$$$$$##########################################**********!!!!!!
  ################$$$$$$$$##########################################**********!!!!
  #################$$$$$$$$$##########################################**********!!
  *###############$$$$$$$$$$$#########################$##$#$$$$########**********!
  ****#*############$$#$##$##########################$$$$$$$$$$$########**********
  ********#############################################$$$$$$$$#########**********
  *************#########################################$#$##$########************
  !*!*************###################################################*************
  !!!!!!*!**********####*##*#*#######################################*************
  !!!!!!!!!!!*****************############$##########################*************
  =!!!!!!!!!!!!***************###########$$$##########################**#*#*******
  ====!!!!!!!!!!!!***********############$$$$$#############################*******
  ;=======!!=!!!!!!!**********##**#######$##############################**********
  ;;;;;;========!!!!!!!***************###############################*************
  ;;;;;;;;========!!!!!!!!*!*!**********############*##############************###
  ;;;;;;;;;;;=====!!!!!!!!!!!!!!!********#*#**************######*************#####
  :;;;;;;;;;;======!!!!!!!!!!!!!!!***************************#*#*********#########
  :::;;;;;;;;;======!!!!!!!!!!!!!!!*************************************##########
  ::::::;;;;;;=======!!!!!!!!!!!!!!!*!*******************************#############
  ~:::::;;;;;;;;=========!!=!!!!!!!!!!!!!*!***************************############
  ~~::::::;;;;;;;;=;===========!=!=!!!!!!!!!!!!!!!*********************#*#########
  ~~~~:::::::;;;;;;;;=;===============!!!!!!!!!!!!!!!*********************########
  ~~~~~~:::::::;;;;;;;;;;;;;=;==========!!!!!!!!!!!!!*!*******************########
  -~~~~~~~::::::::::;;;;;;;;;;;;;==========!=!!!!!!!!!!!!*****************########
  ----~~~~~~~::::::::::;;;;;;;;;;;;=============!!!!!!!!!***************##########
  ------~~~~~~~~:~:::::::;;;;;;;;;;;;;============!!!!!!!!**************#######$$$
  ,--------~-~~~~~~~:::::::::::;;;;;;;;;==========!!!!!!!!!***********#########$$$

=head1 SEE ALSO

You can read about the algorithm at
L<http://www.gameprogrammer.com/fractal.html#diamond>

This implementation is based off of
L<http://www.smokycogs.com/blog/plasma-fractals/>.

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
