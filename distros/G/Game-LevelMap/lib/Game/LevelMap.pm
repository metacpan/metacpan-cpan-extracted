# -*- Perl -*-
#
# a small level map implementation that uses characters (or strings
# consisting of escape sequences or combining characters, or objects
# that ideally stringify themselves properly) in an array of arrays
# representing a level map as might be used in a game

package Game::LevelMap;

use 5.24.0;
use warnings;
use Carp qw(croak);
use Moo;
use namespace::clean;

our $VERSION = '0.02';

has level => (
    is      => 'rw',
    default => sub { [ [] ] },
    isa     => sub {
        my ($lm) = @_;
        croak "LevelMap must be an AoA"
          if !defined $lm
          or ref $lm ne 'ARRAY'
          or ref $lm->[0] ne 'ARRAY';
        my $cols = $lm->[0]->$#*;
        for my $row ( 1 .. $lm->$#* ) {
            if ( $cols != $lm->[$row]->$#* ) {
                croak 'unequal column length at row index ' . $row;
            }
        }
    },
    trigger => sub {
        my ( $self, $lm ) = @_;
        $self->_set_rows( $lm->$#* );
        $self->_set_cols( $lm->[0]->$#* );
    }
);
has rows => ( is => 'rwp' );
has cols => ( is => 'rwp' );

sub BUILD {
    my ( $self, $args ) = @_;
    croak "level and from_string both may not be set"
      if exists $args->{level} and exists $args->{from_string};
    $self->from_string( $args->{from_string} ) if exists $args->{from_string};
}

sub clone {
    my ($self) = @_;
    my $lm = $self->level;
    my @map;
    for my $rown ( 0 .. $lm->$#* ) {
        for my $coln ( 0 .. $lm->$#* ) {
            $map[$rown][$coln] = $lm->[$rown][$coln];
        }
    }
    return __PACKAGE__->new( level => \@map );
}

sub from_string {
    my ( $self, $s ) = @_;
    my @map;
    my $cols;
    for my $row ( split $/, $s ) {
        push @map, [ split '', $row ];
        my $newcols = $map[-1]->$#*;
        if ( defined $cols ) {
            if ( $cols != $newcols ) {
                croak 'unequal column length at row index ' . $#map;
            }
        } else {
            $cols = $newcols;
        }
    }
    $self->level( \@map );
    return $self;
}

# TODO this might buffer and only print what differs across successive
# calls (for less bandwidth over an SSH connection)
sub to_panel {
    my $self = shift;
    my ( $col, $row, $width, $height, $x, $y ) = map int, @_[ 0 .. 5 ];
    my $oobfn    = $_[6] // sub { return ' ' };
    my $lm       = $self->level;
    my $map_cols = $lm->$#*;
    my $map_rows = $lm->[0]->$#*;
    croak "x must be within the level map" if $x < 0 or $x > $map_cols;
    croak "y must be within the level map" if $y < 0 or $y > $map_rows;
    my $scol = $x - int( $width / 2 );
    my $srow = $y - int( $height / 2 );
    my $s    = '';

    for my $r ( $srow .. $srow + $height - 1 ) {
        $s .= "\e[" . $row++ . ';' . $col . 'H';
        for my $c ( $scol .. $scol + $width - 1 ) {
            if ( $c < 0 or $c > $map_cols or $r < 0 or $r > $map_rows ) {
                $s .= $oobfn->( $lm, $c, $r, $map_cols, $map_rows );
            } else {
                $s .= $lm->[$r][$c];
            }
        }
    }
    print $s;
    return $self;
}

sub to_string {
    my ($self) = @_;
    my $lm     = $self->level;
    my $s      = '';
    for my $rowref ( $lm->@* ) { $s .= join( '', $rowref->@* ) . $/ }
    return $s;
}

sub to_terminal {
    my $self = shift;
    my ( $col, $row ) = map int, @_;
    my $lm = $self->level;
    my $s  = '';
    for my $rowref ( $lm->@* ) {
        $s .= "\e[" . $row++ . ';' . $col . 'H' . join( '', $rowref->@* );
    }
    print $s;
    return $self;
}

sub update_terminal {
    my $self = $_[0];
    my ( $col, $row ) = map int, @_[ 1 .. 2 ];
    my $lm = $self->level;
    my $s  = '';
    for my $point ( @_[ 3 .. $#_ ] ) {
        $s .= "\e["
          . ( $row + $point->[1] ) . ';'
          . ( $col + $point->[0] ) . 'H'
          . $lm->[ $point->[1] ][ $point->[0] ];
    }
    print $s;
    return $self;
}

1;
__END__

=head1 NAME

Game::LevelMap - level map representation

=head1 SYNOPSIS

  use Game::LevelMap;

  my $lm = Game::LevelMap->new( from_string => <<'EOF' );
  .....
  .@.>.
  .....
  EOF

  print $lm->to_string;

  # the following methods may require buffering disabled
  STDOUT->autoflush(1);

  $lm->to_terminal( 1, 1 );

  # maybe instead there's a static border, indent
  $lm->to_terminal( 2, 2 );
  ...
  # several points on the map changed, update them
  $lm->update_terminal( 2, 2, [ 5, 2 ], [ 4, 2 ] );

  # complicated, see docs tests eg/panel-viewer
  $lm->to_panel( ... );

=head1 DESCRIPTION

A small level map implementation that uses characters (or strings
consisting of escape sequences or combining characters, or objects that
hopefully stringify themselves properly) in an array of arrays
representing a level map as might be used in a game.

  x cols
  y rows

Points use the geometric form (x,y) col,row which is backwards from what
terminal escape sequences use.

=head1 CONSTRUCTORS

These return new objects. If something goes wrong an exception
will be thrown.

=over 4

=item B<clone>

Returns a new object from an existing one with the current state of the
B<level> attribute. The copy is shallow; a level map of objects when
cloned will have the same objects as the other object.

=item B<new> level => ...

Constructor. Either the B<level> attribute should be specified or
B<from_string> to build the level from a string representation.

=back

=head1 ATTRIBUTES

=over 4

=item B<level>

Where the level map (an array of arrays) lives. Can be set and accessed
directly, or set via the B<from_string> method.

=item B<cols>

Number of columns (x) in the level map. Cannot be changed directly.

=item B<rows>

Number of rows (y) in the level map. Cannot be changed directly.

=back

=head1 METHODS

=over 4

=item B<from_string> I<string>

Constructs the level map from the given string. Throws an error if
that fails.

=item B<to_panel> I<col> I<row> I<width> I<height> I<x> I<y> [ I<oobfn> ]

Displays possibly a portion of the level map within the given I<width>
by I<height> panel that is drawn at the offset I<coL> I<row> on the
terminal. I<x> and I<y> specify where on the map the panel should center
on. The I<width> and I<height> must be odd values for the map to center
itself properly.

  my @offset = ( 1, 1 );
  my @size   = ( 79, 23 );
  $lm->to_panel( @offset, @size, $player_col, $player_row );

The optional I<oobfn> function handles how to draw points that are out
of bounds due to how the map is centered; by default this function
returns the space character, though might instead use modulus math to
make the level map wrap around:

  $lm->to_panel(
      @offset, @size, 0, 0,
      sub {
          my ( $lm, $col, $row, $mcols, $mrows ) = @_;
          return $lm->[ $row % $mrows ][ $col % $mcols ];
      }
  );

Use the far less complicated B<to_terminal> method if the level map is
not larger than the terminal window.

Buffering should likely be disabled on the STDOUT filehandle before
using this method.

=item B<to_string>

Converts the level map to string form and returns it.

=item B<to_terminal> I<col> I<row>

Prints the entire level map to standard output (assumed connected to a
terminal that supports ANSI or XTerm control sequences) with the upper
left corner of the map appearing at the given I<row> and I<col> (which
must be integers greater than zero). The level map should not be larger
than the terminal, though no checks are made regarding this.

Use the more complicated B<to_panel> if the level map is larger than
the terminal window, or B<to_string> and then view that output with a
pager program.

Buffering should likely be disabled on the STDOUT filehandle before
using this method.

=item B<update_terminal> I<col> I<row> I<points ..>

Updates specific points of the level map, presumably after
B<to_terminal> has already printed the entire level map. Must use the
same I<col> and I<row> map display offset as used in B<to_terminal>. The
points should be a list of array references.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-game-levelmap at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-LevelMap>.

Patches might best be applied towards:

L<https://github.com/thrig/Game-LevelMap>

=head2 Known Issues

There is either too much or too little error checking.

An actual game may want to adapt code from this module and make it less
generic, as usually things like the map panel size will be fixed, etc.

B<to_panel> redraws the whole thing each time. With a buffer and change
checks this might only update points that have changed, which would save
on display bandwidth (which may be a concern over SSH connections).

=head1 SEE ALSO

=over 4

=item *

L<Game::DijkstraMap> can path-find across text patterns (not very well;
L<Game::PlatformsOfPeril> includes better graph-building and A* (A
star) search within its guts though that implementation is specific to
that game).

=item *

L<Game::TextPatterns> allows the generation and manipulation of
level maps.

=item *

L<Games::Board> is similar but different.

=item *

L<https://github.com/thrig/ministry-of-silly-vaults/>

=item *

L<IO::Termios> or L<Term::ReadKey> can put the terminal into raw mode
which will likely be useful with the B<to_panel> or B<to_terminal>
methods. See L<Game::PlatformsOfPeril> for other useful ANSI and XTerm
control sequences.

=back

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
