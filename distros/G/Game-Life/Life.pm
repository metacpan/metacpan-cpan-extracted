#!/usr/bin/perl -w

package Game::Life;

#=============================================================================
#
# $Id: Life.pm,v 0.06 2013/05/16 08:55:32 ltp Exp $
# $Revision: 0.06 $
# $Author: ltp $
# $Date: 2013/05/16 08:55:32 $
# $Log: Life.pm,v $
#
# Revision 0.06  2013/05/16 08:55:32  ltp
#
# Improved test coverage.
#
# Revision 0.05  2013/05/15 21:18:29  ltp
#
# Modified constructor to allow arbitrary sized game board.
#
# Revision 0.04  2001/07/04 02:49:29  mneylon
#
# Fixed distribution problem
#
# Revision 0.03  2001/07/04 02:27:55  mneylon
#
# Updated README for distribution
#
# Revision 0.02  2001/07/04 02:23:13  mneylon
#
# Added test cases
# Added set_text_points, get_text_grid
# Added set_rules, get_breeding_rules, get_living_rules, and set default
#       values for these as Conway's rules
# Modifications from code as posted on Perlmonks.org
#
#
#=============================================================================

use strict;
use Exporter;
use Clone qw( clone );

BEGIN {
    use Exporter   ();
    use vars       qw($VERSION @ISA @EXPORT %EXPORT_TAGS);
    $VERSION     = sprintf( "%d.%02d", q($Revision: 0.06 $) =~ /\s(\d+)\.(\d+)/ );
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    %EXPORT_TAGS = ( );
}


my $default_size = 100;

sub new {
    my $class = shift;
    my $self = {} ;
    
    # No args, set up a blank one
    $self->{ size } = shift || $default_size;
    if ( ref( $self->{ size } ) ) {
      ( $self->{ size_y }, $self->{ size_x } ) = @{ $self->{ size } };
    }
    else {
      $self->{ size_y } = $self->{ size_x } = $self->{ size }
    }

    $self->{ grid } = [ map 
			{ [ map { 0 } (1..$self->{ size_y } ) ] } 
			(1..$self->{ size_x } ) ];

    bless $self, $class;
    
    my ( $breedlife, $keeplife ) = @_;
    # Default values for Conway's game
    $breedlife ||= [ 3 ];   
    $keeplife  ||= [ 2,3 ];

    $self->set_rules( $breedlife, $keeplife );

    return $self;
}

sub set_rules {
    my $self = shift;
    my ( $breedlife, $keeplife ) = @_;

    die "Life rules must be arrayrefs if used" 
	unless ( defined ( $breedlife ) && ref( $breedlife ) eq "ARRAY" && 
		 defined ( $keeplife  ) && ref( $keeplife ) eq "ARRAY" );
    
    # Force a duplication so we don't rely on the passed version
    my @temp1 = @$breedlife;
    my @temp2 = @$keeplife;

    $self->{ breed_criteria } = \@temp1;
    $self->{ keep_criteria } = \@temp2;
}

sub get_breeding_rules {
    my $self = shift;
    return @{ $self->{ breed_criteria } };
}

sub get_living_rules {
    my $self = shift;
    return @{ $self->{ keep_criteria } };
}

sub toggle_point {
    my ( $self, $x, $y ) = @_;
    return ( $self->{ grid }->[$x]->[$y] = !$self->{ grid }->[$x]->[$y] );
}

sub set_point {
    my ( $self, $x, $y ) = @_;
    $self->{ grid }->[$x]->[$y] = 1;
}

sub unset_point {
    my ( $self, $x, $y ) = @_;
    $self->{ grid }->[$x]->[$y] = 0;
}

sub place_points {
    my ( $self, $x, $y, $array ) = @_;
    return if ( $x < 0 || $x >= $self->{ size_x } || 
		$y < 0 || $y >= $self->{ size_y } );
    my ($i, $j);
    my $array_x = @$array;
    my $array_y = @{$$array[0]};
    for ( $i = 0 ; $i < $array_x && $i+$x < $self->{ size_x }; $i++ ) {
	for ( $j = 0 ; $j < $array_y && $j+$y < $self->{ size_y }; $j++ ) {
	    $self->{ grid }->[ $x + $i ]->[ $y + $j ] = 
		($array->[ $i ]->[ $j ] > 0) ? 1 : 0;
	}
    }
    return 1;
}

sub place_text_points {
    my ( $self, $x, $y, $living, @array ) = @_;
    return if ( $x < 0 || $x >= $self->{ size_x } || 
		$y < 0 || $y >= $self->{ size_y } );
    my ($i, $j);
    my $array_x = @array;
    my $array_y = length $array[0];
    for ( $i = 0 ; $i < $array_x && $i+$x < $self->{ size_x }; $i++ ) {
	for ( $j = 0 ; $j < $array_y && $j+$y < $self->{ size_y }; $j++ ) {
	    $self->{ grid }->[ $x + $i ]->[ $y + $j ] = 
		(substr($array[ $i ], $j, 1 ) eq $living) ? 1 : 0;
	}
    }
    return 1;
}
    

sub get_grid { 
    my ( $self ) = @_;
    return clone( $self->{ grid } );
}

sub get_text_grid { 
    my ( $self, $filled, $empty ) = @_;
    $filled ||= 'X';
    $empty ||= '.';

    my @array;
    for	my $i ( 0..$self->{ size_x }-1 ) {
	my $string = '';
	for my $j ( 0..$self->{ size_y }-1 ) {
	    $string .= $self->{ grid }->[ $i ]->[ $j ] ? $filled : $empty;
	}
	push @array, $string;
    }
    return @array;
}

sub process {
    my $self = shift;
    my $times = shift || 1;
    
    for (1..$times) {
	my $new_grid = clone( $self->{ grid } );
	use Data::Dumper;
	
	for my $i ( 0..$self->{ size_x }-1 ) {
	    for	my $j ( 0..$self->{ size_y }-1 ) {
		$new_grid->[$i]->[$j] = 
		    $self->_determine_life_status( $i, $j );
	    }
	}
	$self->{ grid } = $new_grid;
    }
}

sub _determine_life_status {
    my ( $self, $x , $y ) = @_;
    my $n = 0;
    for my $i ( $x-1, $x, $x+1 ) {
	for my $j ( $y-1, $y, $y+1 ) {
	    $n++ if ( $i >= 0 && $i < $self->{ size_x } &&
		      $j >= 0 && $j < $self->{ size_y } ) && 
			  ( $self->{ grid }->[ $i ]->[ $j ] );
	}
    }
    # here's the deterministic part; force return of 0 or 1.
    $n-- if $self->{ grid }->[ $x ]->[ $y ];
    return ( 0 != grep { $_ == $n } @{ $self->{ 
	$self->{ grid }->[ $x ]->[ $y ] 
	    ? 'keep_criteria' : 'breed_criteria' } } );
}

42;

__END__

=pod 

=head1 NAME
    
Game::Life - Plays Conway's Game of Life

=head1 SYNOPSIS

	use Game::Life;
	my $game = new Game::Life( 20 );
	my $starting = [
			 [ 1, 1, 1 ],
			 [ 1, 0, 0 ],
			 [ 0, 1, 0 ]
		       ];

	$game->place_points( 10, 10, $starting );
	for (1..20) {
	    my $grid = $game->get_grid();
	    foreach ( @$grid ) {
		print map { $_ ? 'X' : '.' } @$_;
		print "\n";
	    }
	    print "\n\n";
	    $game->process();
	}

=head1 DESCRIPTION

Conway's Game of Life is a basic example of finding 'living' patterns
in rather basic rulesets (see B<NOTES>).  The Game of Life takes
place on a 2-D rectangular grid, with each grid point being either
alive or dead.  If a living grid point has 2 or 3 neighbors within the
surrounding 8 points, the point will remain alive in the next
generation; any fewer or more will kill it.  A dead grid point will
become alive if there are exactly 3 living neighbors to it.  With
these simple rules, fascinating structures such as gliders that move
across the grid, glider guns that generate these gliders, XOR gates,
and others have been found.

This module simply provides a way to simulate the Game of Life in Perl.

In terms of coordinate systems as used in C<place_points>, C<toggle_point>
and other functions, the first coodinate is the vertical direction, 0
being the top of the board, and the second is the horizontal direaction,
0 being the left side of the board.  Thus, toggling the point of (3,2) 
will switch the state of the point in the 4th row and 3rd column.

The edges of the board are currently set as "flat"; cells on the edge
do not have any neighbors, and thus will 'fall' off the board.  Future
versions may allow for 'warp' edges (if a cell moves off the left side it 
reappears on the right side).

=over

=item C<new>

Creates a new Life game board; if passed a scalar, the game board will
be a square of that size, if passed an array reference, the game board
will be created as a rectangle with the width and height set to the
first and second values in the array reference respectively, otherwise, 
the board will be created using the default size of 100x100 units.  
Two optional array references may be passed to set the breeding and 
living rules for the Life game, respectively.  The arrays should be 
made of the values for the number of nearest neighbors that should 
trigger the associated event.  By default, Conway's game of life 
uses [ 3 ] and [ 2,3 ] for these arrays, respectively, but you can play 
around with these to get other types of automata.

=item C<set_rules>

Takes two array references and uses them to set the rules of the Life game
as described in C<new> above, namely for breeding and living rules
in that order.

=item C<get_breeding_rules>, C<get_living_rules>

Returns arrays that are associated with the breeding or living rules
above.

=item C<place_points>

Takes two scalars (indicating the position on the grid) and a
reference to an array of arrays; this array is placed into the Life
grid at the specified position, overwriting any data already there.
Within the array of arrays, any non-zero values will be considered as
a living square.

=item C<place_text_points>

Takes two scalars (indicated the position on the grid), a character,
and an array of strings; as with C<place_points>, this array will
be placed into the grid at the specified position.  The character indicates
what cells are to be considered as alive; any other character in the 
string will be considered dead.  Thus, the example given in the B<SYNOPSIS>
can be writen optionally as

	my @starting = qw( XXX
                           X..
                           .X. );

	$game->place_text_points( 10, 10, 'X', @starting );

Note that a implicit method of serialization can be used in conjunction with
C<get_text_grid>.

=item C<toggle_point>, C<set_point>, C<unset_point>

Take two scalars that indiciate a specific grid position.  These
functions toggle, sets, or unsets the life status of the grid point
passed, respectively.

=item C<process>

If passed a number, runs the Life simulation that many times, else
runs the simulation once.

=item C<get_grid>

Returns a B<copy> of the Life grid as a reference to an array of
arrays.

=item C<get_text_grid>

Returns an array of strings that represent the game board.  Two optional
parameters may be passed as symbols to represent the living and dead states
on the board, in that order.  If these are not supplied, they will be
represented by 'X' and '.', respectively.  It's very easy to use this via:

	print "$_\n" foreach ( $game->get_text_grid( ) );

to follow the progress of the Life simulation, and should be faster than
rolling your own based on get_grid.  

=back

=head1 NOTES

Conway here is not Damien Conway of Perl fame, but John Horton Conway of
mathematics and computer science fame.  The 'game' was original designed
in the late 60s - early 70s, and became popular due to the interest that
Martin Gardner (puzzle editor for I<Scientific American>) had for it.

=head1 HISTORY

    Revision 0.06  2013/05/16 08:55:32  ltp

    Improved test coverage.

    Revision 0.05  2013/05/15 21:18:26  ltp

    Updated constructor to allow arbitrary sized game board.

    Revision 0.04  2001/07/04 02:49:29  mneylon

    Fixed distribution problem

    Revision 0.03  2001/07/04 02:27:55  mneylon

    Updated README for distribution

    Revision 0.02  2001/07/04 02:23:13  mneylon

    Added test cases
    Added set_text_points, get_text_grid
    Added set_rules, get_breeding_rules, get_living_rules, and set default
          values for these as Conway's rules
    Modifications from code as posted on Perlmonks.org


=head1 AUTHOR

This package was written by Michael K. Neylon

=head1 COPYRIGHT

Copyright 2001 by Michael K. Neylon

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
