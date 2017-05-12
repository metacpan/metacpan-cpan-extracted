package Gapp::TableMap;
{
  $Gapp::TableMap::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Gapp::TableCell;

# array of Gapp::TableCell objects
has 'cells' => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

# number of columns in table ( used when creating Gtk2::Table )
has 'col_count' => (
    is => 'rw',
    isa => 'Int',
    writer => '_set_col_count',
    default => 0,
);

# number of rows in table ( used when creating Gtk2::Table )
has 'row_count' => (
    is => 'rw',
    isa => 'Int',
    writer => '_set_row_count',
    default => 0,
);

# the ascii representation of the table
has 'string' => (
    is => 'rw',
    isa => 'Str',
    default => '',
    trigger => sub { $_[0]->clear_cells },
);

# the ascii table, cleaned up and split into an array
has '_rows' => (
    is => 'rw',
    isa => 'ArrayRef',
    lazy_build => 1,
);

# the horizontal vertices
has '_rasterx' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { { } },
);

sub _add_rasterx {
    my ( $self, $point ) = @_;
    $self->_rasterx->{$point} = 1;
}

# the vertical vertices
has '_rastery' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { { } },
);

sub _add_rastery {
    my ( $self, $point ) = @_;
    $self->_rastery->{$point} = 1;
}

# the width of the ascii table in chars
has '_xunits' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

# the height of the ascii table in chars
has '_yunits' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

sub _build_cells {
    my ( $self ) = @_;
    
    $self->_find_rasters;
    
    my @cells;
    my @rasterx = sort { $a <=> $b } keys %{ $self->_rasterx };
    my @rastery = sort { $a <=> $b } keys %{ $self->_rastery };
    
   
    
    my $ypos = 0;
    for my $r ( @{ $self->_rows } ) {
        my $row = $r;
        
        # skip rows with no fields (borders and spacers);
        $ypos++, next if $row !~ /[|^_']/; 
        
        # left_x, right_x, left_attach, right_attach
        my ( $lx, $rx, $la, $ra ) = ( 0, 0, 0, 0 );
        
        # remove leading table border character and remember it
        $row =~ s/^(.)//;
        my $lead_char = $1;
        
        # split row into field parts
        for my $field ( split /[|+'_^~]/, $row ) {
            $rx = $lx + 1 + length $field;
            
            # calculate span of this field
            my $spanx = 0;
            for my $x ( @rasterx ) {
                $spanx++ if $x >= $lx && $x < $rx;
                last if $x > $rx;
            }
            
            # calculate right attach using cell span
            $ra = $la + $spanx;
            
            # process field only if doesn't span from previous row
            my $last_row = $self->_rows->[$ypos-1];
            if ( $ypos > 0 && substr ( $last_row, $lx + 1, 1 ) =~ /[-=>%\[\]]/  ) {
                
                
                # calculate top/bottom attach by searching for bottom of field
                my ( $ta, $ba ) = ( 0, 0 );
                
                # skip first line, which defines no columns
                my $seeky;
                for ( $seeky = 1; $seeky < $self->_yunits; ++$seeky ) {
                    
                    if ( $seeky < $ypos and $self->_rastery->{$seeky} ) {
                        $ta++;
                        $ba++;
                    }
                    elsif ( $self->_rastery->{$seeky} ) {
                        $ba++;
                    }
                    
                    # out here if hit end of field
                    last if $seeky > $ypos and substr( $self->_rows->[$seeky], $lx+1, 1) =~ /[-+=\[\]\%]/;
                    $field .= "\n". substr($self->_rows->[$seeky], $lx+1, $rx-$lx-1) if $seeky > $ypos;
                    
                }
                
                # create cells ( if field not emptry )
                if ( $field =~ /\S/ ) {
                    
                    my $cell = Gapp::TableCell->new(
                        left => $la, right => $ra, top => $ta, bottom => $ba,
                        hexpand => $self->_find_xexpansion( $lx+1, $ypos, $rx ),
                        vexpand => $self->_find_yexpansion( $lx, $ypos, $seeky-1 ),
                        xalign  => $self->_find_xalign( $lx+1, $ypos, $rx ),
                        yalign  => $self->_find_yalign( $lx, $ypos, $seeky-1 ),
                    );
                    
                    push @cells, $cell;
                }
            }
            
            # setup vars for next field
            $lx = $rx,
            $la = $ra;
            
        }
            
        # move on to next row
        $ypos++;
    }
    
    # store cells and table dimensions
    $self->_set_row_count( $#rastery );
    $self->_set_col_count( $#rasterx );
    return \@cells;
}

sub _build__rows {
    my ( $self ) = @_;
    
    my @rows = split /\n/, $self->string;
    @rows = map { s/^\s*//; $_ } @rows;
    @rows = map { s/\s*$//; $_ } @rows;
    
    return \@rows;
}

# traverse the rows to dermine where the rasters occur
sub _find_rasters {
    my ( $self ) = @_;
    
    my $y = 0;
    my $row_length = 0;
    for my $r ( @{ $self->_rows } ) {
        
        # if this row has + or -, then it is a layout row
        if ( $r =~ /-+/ ) {
            
            # store raster
            $self->_add_rastery( $y ); 
        }
        
        # if row has any of | ^ _ ' ~ it is a content row
        if ( $r =~ /[|^_'~]/ ) {
            
            # split on field separating characters
            my $x = 0;
            for my $field ( split /[|^_']/, $r ) {
                
                # determine and store raster
                $x += length $field;
                $self->_add_rasterx( $x );
                $x++;
            }
            
            $row_length = $x if $x > $row_length;
        }
        
        # on to the next row
        $y++;
    }
    
    $self->_set_xunits( $row_length );
    $self->_set_yunits( $y );
}


sub _find_xexpansion {
    my ( $self, $x, $y, $max_x ) = @_;

    my $char;
    my $segment = substr $self->_rows->[$y-1], $x, $max_x + 1 - $x ;
    return [qw( fill expand )] if $segment =~ /[>^]/;
    return ["fill"];
}

sub _find_yexpansion {
    my ( $self, $x, $y, $max_y ) = @_;

    for my $row ( @{$self->_rows}[$y..$max_y] ) {
        my $segment = substr $row, $x, 1;
        return [qw( fill expand )] if $segment eq '^';
    }

    return ["fill"];
}

sub _find_xalign {
    my ( $self, $x, $y, $max_x ) = @_;
    
    my $row = $self->_rows->[$y-1];
    my $char;
    while ( $x <= $max_x ) {
        $char = substr($row, $x, 1);
        return 0   if $char eq '[';
        return 1   if $char eq ']';
        return 0.5 if $char eq '%';
        ++$x;
    }
    
    return -1;
}

sub _find_yalign {
    my ( $self, $x, $y, $max_y ) = @_;

    my $char;
    while ( $y <= $max_y ) {
        my $char = substr $self->_rows->[$y], $x, 1;
        return 0   if $char eq "'";
        return 1   if $char eq '_';
        return 0.5 if $char eq '~';
        ++$y;
    }

    return -1;
}


1;



__END__

=pod

=head1 NAME

Gapp::TableMap - Create ASCII Table Layouts

=head1 SYNOPSIS

    Gapp::TableMap->new( string => "
        +-------%------+>>>>>>>>>>>>>>>+
        |     Name     |               |
        +--------------~ Image         |
        | Keywords     |               |
        +-------+------+[--------------+
        ^       ' More | Something     |
        ^       |      +-----+--------]+
        _ Notes |      |     |     Foo |
        +-------+------+-----+---------+
        ^ Bar          | Baz           |
        +--------------+---------------+
    ");

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::TableMap>

=back

=head1 DESCRIPTION

A L<Gapp::TableMap> is used to layout widgets in a table. Generally you will only
need to know how to create a Table map and won't need to worry about the
details (unless your want to change how widgets are added to table - see
L<Gapp::Layout>).

=head2 Creating a TableMap

You may also call the L<Gapp::TableMap> constructor with a single argument,
which will be used as the C<string> attribute.

    Gapp::TableMap->new( ... );

The C<map> attribute of L<Gapp::Table> will coerce a string into a
L<Gapp::TableMap> for you.

    Gapp::Table->new (
        map => '
            ...
        ',
    )

=head2 Special Characters

This is the complete list of recognized characters and their meaning:

=over 10

=item - | + =

The widget fills the cell, but the cell doesn't resize with the
table. That's the default, because these characters belong to the set
of ASCII graphic characters used to draw the layout.

=item >

The cell expands horizontal. Recognized only in the top border of a cell.

=item ^

The cell expands vertical. Recognized only in the left border of a cell.

=item [

Widget is attached on the left and doesn't expand anymore with the cell.
Recognized only in the top border of a cell.

=item ]

Widget is attached on the right and doesn't expand anymore with the cell.
Recognized only in the top border of a cell.

=item %

Widget is attached in the middle (horizontal) and doesn't expand anymore with
the cell. Recognized only in the top border of a cell.

=item '

Widget is attached on the top and doesn't expand anymore with the cell.
Recognized only in the left border of a cell.

=item _

Widget is attached on the bottom and doesn't expand anymore with the cell.
Recognized only in the left border of a cell.

=item ~

Widget is attached in the middle (vertical) and doesn't expand anymore with the
cell. Recognized only in the left border
of a cell.

=back

=head2 Whitespace

You may have arbitrary whitespace around your table, inlcuding TAB
characters. Don't use TAB characters but true SPACE characters inside the table.

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<string>

=over 4

=item isa: Str

=back

=back

=head1 PROVIDED METHODS

=over 4

=item B<cells>

Returns an ArrayRef containing L<Gapp::TableCell> objects.

=item B<row_count>

The number of table rows in the map.

=item B<col_count>

The number of tbale columns in the map.

=back

=head1 ACKNOWLEDGMENTS

Thanks to Jörn Reder and his L<Gtk2::Ex::FormFactory::Table> package, this one
is able to exist.

=head1 AUTHORS

Jörn Reder <joern at zyn dot de>

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright 2004-2006 by Jörn Reder.

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This library is free software; you can redistribute it and/or modify
    it under the terms of the GNU Library General Public License as
    published by the Free Software Foundation; either version 2.1 of the
    License, or (at your option) any later version.
    
    This library is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.
    
    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
    USA.

=cut
