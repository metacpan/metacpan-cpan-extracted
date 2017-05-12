#
#===============================================================================
#
#         FILE:  PlaceIterator.pm
#
#  DESCRIPTION: A Geo::ReadGRIB::PlaceIterator object contains a collection of
#               Geo::ReadGRIB data for a regular area and has methods to return
#               Geo::ReadGRIB::Place in sorted sequence of locations
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Frank Lyon Cox (Dr), <frank@pwizardry.com>
#      COMPANY:  Practial Wizardry
#      VERSION:  1.0
#      CREATED:  2/2/2009 12:15:57 PM Pacific Standard Time
#     REVISION:  ---
#===============================================================================

package Geo::ReadGRIB::PlaceIterator;

use strict;
use warnings;
use Geo::ReadGRIB::Place;

our $VERSION = 1.0;

#--------------------------------------------------------------------------
#  new( )
#--------------------------------------------------------------------------
sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;
    $self->_init;
    return $self;
}


#--------------------------------------------------------------------------
#  _init( )
#--------------------------------------------------------------------------
sub _init {
    my $self = shift;

    $self->{shifted_west_by}   = 0;
    $self->isSorted( undef );
    $self->{place_index}  = 0;
    $self->{place_sorted} = [];
    $self->{x_y} = [];
    $self->{count_of_places}   = 0;
    return;
}

#--------------------------------------------------------------------------
#  first( )
#--------------------------------------------------------------------------
sub first {
    my $self = shift;
    $self->_indexData() if not $self->isSorted;
    $self->_setIndex( 0 );
    return;
}


#--------------------------------------------------------------------------
#  next( )
#--------------------------------------------------------------------------
sub next {
    my $self = shift;
    $self->_indexData() if not $self->isSorted;
    if ( $self->_setIndex == $self->{count_of_places} ) {
        return;
    }
    return $self->_setIndex('+');
}

#--------------------------------------------------------------------------
#  current( )
#
#  returns a Geo::ReadGRIB::Place object
#--------------------------------------------------------------------------
sub current {
    my $self = shift;

    $self->_indexData() if not $self->isSorted;

    my $index = $self->_setIndex;

    my $p = Geo::ReadGRIB::Place->new;

    $p->thisTime( $self->{place_sorted}->[ $index ]->[0] );
    $p->lat( $self->{place_sorted}->[ $index ]->[1] );
    $p->long( $self->{place_sorted}->[ $index ]->[2] );

    if ( not defined $p->thisTime ) {
        return;
    }

    for my $type ( keys %{ $self->{data}->{$p->thisTime}->{$p->lat}->{$p->long} } ) {
        $p->types( $type );
        $p->data( $type, $self->{data}->{$p->thisTime}->{$p->lat}->{$p->long}->{$type} );
    }

    return $p;
}


#--------------------------------------------------------------------------
#  numLong( )
#--------------------------------------------------------------------------
sub numLong {
    my $self = shift;
    $self->_indexData() if not $self->isSorted;
    return $self->{x_y}->[0];
}

#--------------------------------------------------------------------------
#  numLat( )
#--------------------------------------------------------------------------
sub numLat {
    my $self = shift;
    $self->_indexData() if not $self->isSorted;
    return $self->{x_y}->[1];
}

#--------------------------------------------------------------------------
#  _setIndex( )
#--------------------------------------------------------------------------
sub _setIndex {
    my $self  = shift;
    my $index = shift;

    if ( defined $index ) {
        if ( $index eq '+' ) {
            $self->{place_index} = $self->{place_index} + 1;
        }
        else {
            $self->{place_index} = $index;
        }
    }

    if (  $self->{place_index} > $self->{count_of_places} ) {
        return;
    }

    return $self->{place_index};
}

#--------------------------------------------------------------------------
#  isSorted( )
#--------------------------------------------------------------------------
sub isSorted {
    my $self = shift;
    my $bool = shift;
    if ( $bool ) {
        $self->{is_sorted} = 1;
    }
    return $self->{is_sorted};
}

#--------------------------------------------------------------------------
#  _indexData( )
#
#  Inspect the data section and prepare a sorted list of
#  [time, lat, long] 
#
#  -- we also count the number of lats and longs
#
#  Object data is updated
#--------------------------------------------------------------------------
sub _indexData {
    my $self = shift;

    #  Inspect the data section and prepare a sorted list of
    #  [time, lat, long] and an array of times
    #  -- we also count the number of lats and longs

    my ( @tm, $these, $dataType );

    my ( $thisTime ) = keys %{ $self->{data} }; 

    my ( $laC, $loC );
    while ( my ( $time, $laf ) = each %{ $self->{data} } ) {
        $laC = 0;
        while ( my ( $la, $lof ) = each %$laf ) {
            while ( my ( $lo, $dtf ) = each %$lof ) {
                $loC++;
                push @$these, [ $time, $la, $lo ];
                ($dataType) = each %$dtf;
            }
        }
    }

    $self->{x_y} = [  $loC / scalar keys %{ $self->{data}->{$thisTime} },
                      scalar keys %{ $self->{data}->{$thisTime} } ];

    $self->{place_sorted} = $self->_sortThese($these);
    $self->{count_of_places} = $loC;
    $self->isSorted( 1 );
    $self->first;

    return;
}

#--------------------------------------------------------------------------
#  _sortThese( )
#--------------------------------------------------------------------------
sub _sortThese {
    my $self    = shift;
    my $coArray = shift;

    # sort by lat and then by long
    my @psort = sort { 
        $a->[0] <=> $b->[0] || $b->[1] <=> $a->[1] || $a->[2] <=> $b->[2] 
    } @$coArray;

    return \@psort;
}

#--------------------------------------------------------------------------
#  addData( time, la, lo, type, data )
#  
#  Add a unit of data to internal structure
#--------------------------------------------------------------------------
sub addData {
    my $self = shift;
    my $time = shift;
    my $la   = shift;
    my $lo   = shift;
    my $type = shift;
    my $data = shift;

    $self->{data}->{$time}->{$la}->{$lo}->{$type} = $data if defined $data;
    $self->{is_sorted} = undef;

    return $self->{data};
}



1;



#--------------------------------------------------------------------------- 
#  Module Documentation
#---------------------------------------------------------------------------

=head1 NAME

Geo::ReadGRIB::PlaceIterator - Provides methods to iterate through GRIB data
in geographic order and to return Geo::ReadGRIB::Place objects for each location.

=head1 VERSION

This documentation refers to Geo::ReadGRIB::PlaceIterator version 1.0

=head1 SYNOPSIS

    use Geo::ReadGRIB;

    $w = new Geo::ReadGRIB "grib-file";
    $w->getFullCatalog;

    print $w->show,"\n";
  
    $plit = $w->extractLaLo(data_type, lat1, long1, lat2, long2, time);
    die $w->getError if $w->getError;

    # $plit is a Geo::ReadGRIB::PlaceIterator

    for $y ( 0 .. $plit->numLat -1 ) {
        for $x ( 0 .. $plit->numLong -1 ) {
        
            my $place = $plit->current;
            
            # $place is a Geo::ReadGRIB::Place object

            $time       = $place->thisTime;
            $latitude   = $place->lat;
            $longitude  = $place->long;
            $data_types = $place->types; # an array ref of type names
            $data = $place->data(data_type);

            # process data for $x, $y

            $plit->next;
        }
    }


=head1 DESCRIPTION

A PlaceIterator objects let you iterate through places.

Objects of this class are returned by the extractLaLo() or extract() method of a 
Geo::ReadGRIB object. It contains data for one or more data types at one or more 
times for the area extracted. The locations are sorted first by time
then latitude and then by longitude. Methods are provided for sequential access 
to this data.

The first() method sets the iterator index to the most northwest (lat, long) 
pair. The current() method returns a Place object for the current location.
The next() method advances the current location one place in rows from west to 
east and north to south starting in the northwest corner and ending in the 
southeast. After the last item in the southeast corner of the extracted region, 
another call to next() returns B<undef>. 

The convenience methods numLat() and numLong() return the number of latitude and
longitude points respectively. This is handy to, for example, provide the x, y
dimensions for a GD::Image new() method.

=head1 METHODS

=over 4

=item $object->new;

=item $object->first;

=item $object->next;

=item $place = $object->current;

=item $y = $object->numLat;

=item $y = $object->numLong;

=item $y = $object->addData;

=item $y = $object->isSorted;

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. Please report problems through

http://rt.cpan.org

or contact Frank Cox, <frank.l.cox@gmail.com> Patches are welcome.

=head1 AUTHOR

Frank Cox, E<lt>frank.l.cox@gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

2009 by Frank Cox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut

