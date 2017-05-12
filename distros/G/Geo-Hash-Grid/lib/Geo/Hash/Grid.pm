package Geo::Hash::Grid;

use Moo;
use namespace::clean;

extends 'Geo::Hash::XS';

use strict;
use warnings;

use Carp qw( croak );

use Geo::Hash::XS qw( ADJ_RIGHT ADJ_TOP );
use Scalar::Util qw( looks_like_number );


=head1 NAME

Geo::Hash::Grid - Make a grid based off of GeoHashes

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';


=head1 SYNOPSIS

Sometimes you need a simple grid to cover a geographic area.  This is a pretty
easy way to get one that covers a geographic box and with a little spillover.

This module inherits from Geo::Hash::XS and subclasses all it's methods.

    use Geo::Hash::Grid;
	
    my $grid = Geo::Hash::Grid->new(
        sw_lat    => $south_west_latitude,
        sw_lon    => $south_west_longidude,
        ne_lat    => $north_east_latitude,
        ne_lon    => $north_east_longitude,
        precision => 8,
    );
	
    my $hash_count   = $grid->count;
	
    my $geohash_list = $grid->hashes;
	
    my $origin_list  = $grid->origins;
	

=head1 METHODS

=head2 new

Create the geohash grid that fits in a bounding box and specify the grid size.

=over 4

=item * sw_lat => $decimal_degrees

Latitude of the southwest corner of bounding box 

=item * sw_lon => $decimal_degrees

Longitude of the southwest corner of bounding box 

=item * ne_lat => $decimal_degrees

Latitude of the northeast corner of bounding box 

=item * ne_lon => $decimal_degrees

Longitude of the northeast corner of bounding box 

=item * precision => $integer

Geohash precision

=back

=cut

has 'sw_lat'    => ( is => 'ro', required => 1 );
has 'sw_lon'    => ( is => 'ro', required => 1 );
has 'ne_lat'    => ( is => 'ro', required => 1 );
has 'ne_lon'    => ( is => 'ro', required => 1 );
has 'precision' => ( is => 'ro', required => 1 );

sub BUILD {

	my $self = shift;
	
	
	croak "sw_lat attribute missing or malformed"    if not defined $self->sw_lat or not looks_like_number $self->sw_lat;
	croak "sw_lon attribute missing or malformed"    if not defined $self->sw_lon or not looks_like_number $self->sw_lon;
	croak "ne_lat attribute missing or malformed"    if not defined $self->ne_lat or not looks_like_number $self->ne_lat;
	croak "ne_lon attribute missing or malformed"    if not defined $self->ne_lon or not looks_like_number $self->ne_lon;	
	croak "precision attribute missing or malformed" if not defined $self->precision or not $self->precision =~ m/^\d+$/;	
	
	my $gh = Geo::Hash::XS->new();
	
	
	#  place to store the hashes
	my @coverage;
	
	
	#  convert the southwest corner into the start hash
	my $current_hash = $gh->encode( $self->sw_lat, $self->sw_lon, $self->precision );
		
		
	#  let's find our start lat/lon 
	my ( $current_lat, $current_lon ) = $gh->decode( $current_hash );
	
	my $row_start_hash = $current_hash;
	
	#  while both our current lat/longs are still within the bounding box
    my $over_bounds_detected = 0;
	do {
	
		#  if our longitude hasn't over run our bounding box, then we need the next to the right
		#  if our longitude has run over the bounding box, then we need the next one on the top
		my $next_hash;
		if ( $current_lon <= $self->ne_lon ) {
        
			$next_hash = $gh->adjacent( $current_hash, ADJ_RIGHT );
            
            push @coverage, $current_hash;
            
		} else {
        
			$current_hash = $row_start_hash;
			$next_hash = $gh->adjacent( $current_hash, ADJ_TOP );
			$row_start_hash = $next_hash;
            
            #  check to see if the next row is out of bounds
            my ( $lat ) = $gh->decode( $row_start_hash );
            
            $over_bounds_detected = 1 if $lat > $self->ne_lat;
            
		}
		
		#  get ready to evaluate the next hash
		$current_hash = $next_hash;
		( $current_lat, $current_lon ) = $gh->decode( $current_hash );
	
	} while ( ( $current_lat <= $self->ne_lat or $current_lon <= $self->ne_lon ) and not $over_bounds_detected );
	
	#  store data
	$self->{'coverage'} = [ @coverage ];
	
}

=head2 count

Get count of GeoHash's in bounding box

=cut

sub count {
	my $self = shift;
	return scalar @{$self->{'coverage'}};
}

=head2 hashes

Get array reference of GeoHash's in bounding box

=cut

sub hashes {
	my $self = shift;
	return $self->{'coverage'};
}

=head2 origins

Get list of hash references of GeoHash lat/long origins in bounding box

=cut

sub origins {
	my $self = shift;
	
	my $gh = Geo::Hash::XS->new();
	
	if ( not defined $self->{'origins'} ) {
		my $origins;
		foreach my $hash ( @{$self->{'coverage'}} ) {
			my ( $lat, $lon ) = $gh->decode( $hash );
			push @$origins, {
				lat => $lat,
				lon => $lon,
			};
		}
		$self->{'origins'} = $origins;
	}
	
	return $self->{'origins'};
	
}

=head2 bboxes

Get a list of bounding boxes for each hash in the grid

=cut

sub bboxes {
    my $self = shift;
    
    my @bboxes;
    foreach my $hash ( @{$self->{'coverage'}} ) {
    
        my $bbox = $self->_get_bbox( $hash );
        push @bboxes, $bbox;
    
    }
    
    return [ @bboxes ];

} 


sub _get_bbox {
    my $self = shift;
    my $hash = shift;
    
	my $gh = Geo::Hash::XS->new();

    my ( $lat_range, $lon_range ) = $gh->decode_to_interval( $hash );
    
    return {
        sw => {
            lat => $lat_range->[1],
            lon => $lon_range->[1],
        },
        ne => {
            lat => $lat_range->[0],
            lon => $lon_range->[0],
        },
    };
    
}

=head1 AUTHOR

Adam Wohld, <adam at spatialsystems.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-hash-grid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Hash-Grid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Hash::Grid


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Hash-Grid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Hash-Grid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Hash-Grid>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Hash-Grid/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Adam Wohld.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
