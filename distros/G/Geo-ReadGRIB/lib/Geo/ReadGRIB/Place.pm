#
#===============================================================================
#
#         FILE:  Place.pm
#
#  DESCRIPTION:  creates Geo::ReadGRIB::Place objects
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Frank Lyon Cox (Dr), <frank@pwizardry.com>
#      COMPANY:  Practial Wizardry
#      VERSION:  1.0
#      CREATED:  2/3/2009 10:42:57 PM Pacific Standard Time
#     REVISION:  ---
#===============================================================================

package Geo::ReadGRIB::Place;

use strict;
use warnings;

our $VERSION = 1.0;

#--------------------------------------------------------------------------
#  new( )
#--------------------------------------------------------------------------
sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

#--------------------------------------------------------------------------
#  thisTime( )
#--------------------------------------------------------------------------
sub thisTime {
    my $self = shift;
    my $arg  = shift;
    $self->{time} = $arg if defined $arg;
    return $self->{time};
}

#--------------------------------------------------------------------------
#  lat( )
#--------------------------------------------------------------------------
sub lat {
    my $self = shift;
    my $arg  = shift;
    $self->{lat} = $arg if defined $arg;
    return $self->{lat};
}

#--------------------------------------------------------------------------
#  long( )
#--------------------------------------------------------------------------
sub long {
    my $self = shift;
    my $arg  = shift;
    $self->{long} = $arg if defined $arg;
    return $self->{long};
}

#--------------------------------------------------------------------------
#  types( )
#
#  returns an array ref of type names
#--------------------------------------------------------------------------
sub types {
    my $self = shift;
    my $arg  = shift;
    push @{$self->{types}}, $arg if defined $arg;
    return $self->{types};
}

#--------------------------------------------------------------------------
#  data( type_name )
#
#  takes a type_name and returns the associated data
#--------------------------------------------------------------------------
sub data {
    my $self = shift;
    my $type = shift;
    my $data = shift;

    $self->{data}->{$type} = $data if defined $data;

    if ( not defined $self->{data}->{$type} ) {
        warn "Place: Not a valid type: $type\n";
    }

    return $self->{data}->{$type};
}


=head1 NAME

Geo::ReadGRIB::Place - Contains the value of a one or more data type at a given 
time and geographic location.

=head1 VERSION

This documentation refers to Geo::ReadGRIB::Place version 1.0 as returned by 
a call to Geo::ReadGRIB::PlaceIterator::Current()


=head1 SYNOPSIS

    use Geo::ReadGRIB;

    $w = new Geo::ReadGRIB "grib-file";
    $w->getFullCatalog;

    print $w->show,"\n";
  
    $plit = $w->extractLaLo(data_type, lat1, long1, lat2, long2, time);
    die $w->getError if $w->getError;

    # $plit is a Geo::ReadGRIB::PlaceIterator

    while ( $place = $plit->current() and $plit->next ) {

        # $place is a Geo::ReadGRIB::Place object

        $time       = $place->thisTime;
        $latitude   = $place->lat;
        $longitude  = $place->long;
        $data_types = $place->types; # an array ref of type names

        $data       = $place->data( data_type );

        # process data...
    }


=head1 DESCRIPTION

Objects of this class are returned by the current() method of a 
PlaceIterator object which itself has been returned by the 
extractLaLo() or extract() methods of a Geo::ReadGRIB object. A place 
object has a unique latitude and longitude for one time and has data 
for one or more data types. 

=head1 METHODS

Objects of this class are read only and all parameters may be
accessed by the following methods.

=over 4

=item $object->new;

=item $object->thisTime;

=item $object->lat;

=item $object->long;

=item $object->types;

=item $object->data(type);

=back

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. Please report problems through

http://rt.cpan.org

or contact Frank Cox, <frank.l.cox@gmail.com> Patches are welcome.

=head1 AUTHOR

Frank Cox, E<lt>frank.l.cox@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Frank Cox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.



=cut



1;


