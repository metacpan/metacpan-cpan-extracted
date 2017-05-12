package Games::Maze::FirstPerson;

use warnings;
use strict;
use Games::Maze;

use constant MOVE_NORTH => -2;
use constant MOVE_SOUTH => 2;
use constant MOVE_WEST  => -2;
use constant MOVE_EAST  => 2;

use constant NORTH_WALL => -1;
use constant SOUTH_WALL => 1;
use constant WEST_WALL  => -1;
use constant EAST_WALL  => 1;

=head1 NAME

Games::Maze::FirstPerson - First person viewpoint of Games::Maze

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Games::Maze::FirstPerson;

    my $maze = Games::Maze::FirstPerson->new();
    if ( $maze->south ) {
        $maze->go_south;
    }
    print $maze->to_ascii if $maze->has_won;

=head1 DESCRIPTION

This module is merely a wrapper around C<Games::Maze>.  I needed a simple maze
module which would represent a maze from a first-person viewpoint but nothing
on the CPAN did that, hence this code.

Patches welcome.

=head1 EXPORT

None.

=head1 METHODS

=head2 new

    my $maze = Games::Maze::FirstPerson->new(@arguments);

This constructor takes the same arguments as C<Games::Maze>.  Currently we only
support 2D rectangular mazes.

=cut

sub new {
    my $class = shift;

    my %attr_for = @_;
    if ( exists $attr_for{cell} && 'Quad' ne $attr_for{cell} ) {
        die "'cell' attribute must be 'Quad'";
    }
    if ( defined( my $dimensions = $attr_for{dimensions} ) ) {
        die "dimensions must be an array ref" unless 'ARRAY' eq ref $dimensions;
        die "multi-level mazes not (yet) supported"
          if @$dimensions > 2 && $dimensions->[2] > 1;
    }

    my $maze = Games::Maze->new(@_);
    $maze->make;

    # these gymnastics make maneuvering through the maze really,
    # really easy.

    my @grid =
      map {
        s/\s+$//;
        s/ /0/g;
        [ _tighten( split '', $_ ) ]
      }
      split "\n", $maze->to_ascii;

    my $east_west;

    # find the opening and close it
    foreach my $i ( 0 .. $#{ $grid[0] } ) {
        if ( $grid[0][$i] ) {
            $grid[0][$i] = 0;
            $east_west = $i;
            last;
        }
    }

    bless {
        maze    => $maze,
        grid    => \@grid,
        has_won => 0,
        facing  => 'south',

        east_west   => $east_west,    # X coordinates
        north_south => 1,             # Y coordinates

        cols => ( @grid - 1 ) / 2,
        rows => ( @{ $grid[0] } - 1 ) / 2,
    } => $class;
}

sub _tighten {
    my @list = @_;
    my @new_list;
    for ( my $i = 0 ; $i < @list ; $i += 3 ) {
        push @new_list, map { $_ ? 0 : 1 } @list[ $i, $i + 1 ];
    }
    pop @new_list;    # get rid of the undef at the end
    @new_list;
}

##############################################################################

=head2 to_ascii

  print $maze->to_ascii;

This method returns an ascii representation of the maze constructed with
periods and spaces.  It is not the same as the C<Games::Maze> representation.

=cut

my $WALLS = qr/[-:|]/;

sub to_ascii {
    my $self = shift;
    my $maze = $self->{maze};
    my ( @ascii, $ascii );
    if (wantarray) {
        @ascii = $maze->to_ascii;
        return map { s/$WALLS/./g; $_ } @ascii;
    }
    else {
        $ascii = $maze->to_ascii;
        $ascii =~ s/$WALLS/./g;
        return $ascii;
    }
}

##############################################################################

=head2 location

  $maze->location($x, $y);

Set the C<X> and C<Y> location in the maze.

=cut

sub location {
    my ( $self, $x, $y ) = @_;
    if ( grep { !defined || !/^\d+/ } ( $x, $y ) ) {
        die "Arguments to location must be positive integers";
    }
    if ( $x > $self->{cols} ) {
        die "x value out of range";
    }
    if ( $y > $self->{rows} ) {
        die "y value out of range";
    }
    $_ = ( $_ * 2 ) + 1 foreach $x, $y;
    $self->{east_west}   = $x;
    $self->{north_south} = $y;
    return $self;
}

##############################################################################

=head2 x

  my $x = $maze->x;

Returns the current C<X> location in the maze.

=cut

sub x { ( $_[0]{east_west} - 1 ) / 2 }

##############################################################################

=head2 y

  my $y = $maze->y;

Returns the current C<Y> location in the maze.

=cut

sub y { ( $_[0]{north_south} - 1 ) / 2 }

##############################################################################

=head2 rows

  my $rows = $maze->rows;

Returns the number of rows of the maze.

=cut

sub rows { $_[0]{rows} }

##############################################################################

=head2 cols

  my $columns = $maze->cols;

Returns the number of columns of the maze.

=cut

sub cols { $_[0]{cols} }

##############################################################################

=head2 columns

Same as C<< $maze->cols >>.

=cut

sub columns { $_[0]{cols} }

##############################################################################

=head2 north

  if ( $maze->north ) { ... }

Returns true if there is an opening to the north of the current position.

=cut

sub north {
    my $self = shift;
    return $self->{grid}[ $self->{north_south} + NORTH_WALL ]
      [ $self->{east_west} ];
}

##############################################################################

=head2 go_north

  $maze->go_north;

Moves one space to the north.  Returns false if you cannot go that way.

=cut

sub go_north {
    my $self = shift;
    return unless $self->north;
    $self->{facing} = 'north';
    $self->{north_south} += MOVE_NORTH;
    return $self;
}

##############################################################################

=head2 south

  if ( $maze->south ) { ... }

Returns true if there is an opening to the south of the current position.

=cut

sub south {
    my $self = shift;
    return $self->{grid}[ $self->{north_south} + SOUTH_WALL ]
      [ $self->{east_west} ];
}

##############################################################################

=head2 go_south

  $maze->go_south;

Moves one space to the south.  Returns false if you cannot go that way.

=cut

sub go_south {
    my $self = shift;
    return unless $self->south;
    $self->{facing} = 'south';
    $self->{north_south} += MOVE_SOUTH;
    $self->{has_won} = 1 if $self->{north_south} >= @{ $self->{grid} };
    return $self;
}

##############################################################################

=head2 west

  if ( $maze->west ) { ... }

Returns true if there is an opening to the west of the current position.

=cut

sub west {
    my $self = shift;
    return $self->{grid}[ $self->{north_south} ]
      [ $self->{east_west} + WEST_WALL ];
}

##############################################################################

=head2 go_west

  $maze->go_west;

Moves one space to the west.  Returns false if you cannot go that way.

=cut

sub go_west {
    my $self = shift;
    return unless $self->west;
    $self->{facing} = 'west';
    $self->{east_west} += MOVE_WEST;
    return $self;
}

##############################################################################

=head2 east

  if ( $maze->east ) { ... }

Returns true if there is an opening to the east of the current position.

=cut

sub east {
    my $self = shift;
    return $self->{grid}[ $self->{north_south} ]
      [ $self->{east_west} + EAST_WALL ];
}

##############################################################################

=head2 go_east

  $maze->go_east;

Moves one space to the east.  Returns false if you cannot go that way.

=cut

sub go_east {
    my $self = shift;
    return unless $self->east;
    $self->{facing} = 'east';
    $self->{east_west} += MOVE_EAST;
    return $self;
}

##############################################################################

=head2 surroundings

  print $maze->surroundings;

Prints an ascii representation of the immediate surroundings.  For example, if
there are exits to the north and east, it will look like this:

 . .
 .
 ...

=cut

sub surroundings {
    my $self         = shift;
    my $surroundings = '';
    for my $y ( -1 .. 1 ) {
        for my $x ( -1 .. 1 ) {
            $surroundings .= $self->{grid}[ $self->{north_south} + $y ]
              [ $self->{east_west} + $x ]
              ? ' '
              : '.';
        }
        $surroundings .= "\n";
    }
    return $surroundings;
}

##############################################################################

=head2 directions

  my @directions = $maze->directions;

Returns a list of directions in which you can currently move.  Directions are
in lower-case and in the order "north", "south", "east" and "west".

=cut

sub directions {
    my $self = shift;
    return grep { $self->$_ } qw/north south east west/;
}

##############################################################################

=head2 has_won

 if ($maze->has_won) { ... }
 
Returns true if you have reached the exit.

=cut

sub has_won { $_[0]{has_won} }

##############################################################################

=head2 facing

  my $facing = $maze->facing;
  print "You are currently facing $facing\n";

This method returns the direction you are currently facing as determined by
the last direction you have moved.  When a maze if first created, you are
facing south.

=cut

sub facing { $_[0]{facing} }

=head1 EXAMPLE

The following simple program will print out the surroundings of the location
the person is currently at and allow them to move through the maze until they
reach the end.  It is also included in the C<examples/> directory of
this distribution.

 #!/usr/bin/perl
 
 use strict;
 use warnings;
 use Term::ReadKey;
 use Games::Maze::FirstPerson;
 
 my $rows = 5;
 my $columns = 8;
 my $maze = Games::Maze::FirstPerson->new(
   dimensions => [$rows,$columns]
 );
 
 print <<"END_CONTROLS";
 q = quit
 
 w = move north
 a = move west
 s = move south
 d = move east
 
 END_CONTROLS
 
 ReadMode 'cbreak';
 
 my %move_for = (
     w => 'go_north',
     a => 'go_west',
     s => 'go_south',
     d => 'go_east'
 );
 
 while ( ! $maze->has_won ) {
     print $maze->surroundings;
     my $key = lc ReadKey(0);
     if ( 'q' eq $key ) {
         print "OK.  Quitting\n";
         exit;
     }
     if ( my $action = $move_for{$key} ) {
         unless ( $maze->$action ) {
             print "You can't go that direction\n\n";
         }
         else {
             print "\n";
         }
     }
     else {
         print "I don't understand\n\n";
     }
 }
 
 print "Congratulations!  You found the exit!\n";
 print $maze->to_ascii;

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <moc.oohay@eop_divo_sitruc> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-games-maze-firstperson@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Maze-FirstPerson>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

See John Gamble's L<Games::Maze>.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
