package Geo::Coder::GoogleMaps::Response;

use warnings;
use strict;
use Carp;
use Encode;
use constant {
	G_GEO_SUCCESS => 200,
	G_GEO_BAD_REQUEST => 400,
	G_GEO_SERVER_ERROR => 500,
	G_GEO_MISSING_QUERY => 601,
	G_GEO_MISSING_ADDRESS => 601,
	G_GEO_UNKNOWN_ADDRESS => 602,
	G_GEO_UNAVAILABLE_ADDRESS => 603,
	G_GEO_UNKNOWN_DIRECTIONS => 604,
	G_GEO_BAD_KEY => 610,
	G_GEO_TOO_MANY_QUERIES => 620,
};

=encoding utf-8

=head1 NAME

Geo::Coder::GoogleMaps::Response - Response object for the L<Geo::Coder::GoogleMaps> module.

=head1 VERSION

Version 0.4 (follow L<Geo::Coder::GoogleMaps> version number)

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

This module provides a convenient way to represent a response for a geocoding request to Google's servers.

=head1 CONSTANTS

Those constants are giving hints about the status of a geocoding request.

	G_GEO_SUCCESS: No errors occurred; the address was successfully parsed and its geocode has been returned. 
	G_GEO_BAD_REQUEST: A directions request could not be successfully parsed.
	G_GEO_SERVER_ERROR: A geocoding, directions or maximum zoom level request could not be successfully processed, yet the exact reason for the failure is not known. 
	G_GEO_MISSING_QUERY: The "location" parameter was either missing or had no value.
	G_GEO_MISSING_ADDRESS: Synonym for G_GEO_MISSING_QUERY. 
	G_GEO_UNKNOWN_ADDRESS: No corresponding geographic location could be found for the specified address.
	G_GEO_UNAVAILABLE_ADDRESS: The geocode for the given address or the route for the given directions query cannot be returned due to legal or contractual reasons. 
	G_GEO_BAD_KEY: The given key is either invalid or does not match the domain for which it was given. 
	G_GEO_TOO_MANY_QUERIES: The given key has gone over the requests limit in the 24 hour period or has submitted too many requests in too short a period of time.

=head1 FUNCTIONS

=head2 new

The object constructor it takes no parameters

=cut


sub new {
	my($class, %param) = @_;
	if( (exists($param{status_code}) && defined($param{status_code}) ) && (exists($param{status_request}) && defined($param{status_request}) ) ){
		bless { status => {code=>$param{status_code},request=>$param{status_request}}, placemarks => [] }, $class;
	}
	else{
		bless { status => {code=>-1,request=>""}, placemarks => [] }, $class;
	}
}

=head2 is_success

Return true if the the request was successfull and there is actually some placemarks in the list, false otherwise. 

If the exact failure reason is needed, please use Geo::Coder::GoogleMaps::Response::status_code() and check with the available constants.

	unless( $response->is_success() ){
		print "WARNING: Address is unknown by Google's server !\n" if( $response->status_code() == G_GEO_UNKNOWN_ADDRESS );
	}

=cut

sub is_success {
	my $self = shift;
	return ($self->{status}->{code} == G_GEO_SUCCESS && scalar(@{$self->{placemarks}}) >= 1) ;
}

=head2 status_code

Returns the response status code. This code can be tested against the G_GEO_* constants.

	if( $response->status_code() == Geo::Coder::GoogleMaps::Response::G_GEO_BAD_KEY )
		print "Please provide a valid Google Maps API key and try again.\n";

=cut

sub status_code {
	my $self = shift;
	return $self->{status}->{code};
}

=head2 status

Returns the complete response status. The status is a hashref which looks like that :

	status => {
			code => -1,
			request => ""
		}

=cut

sub status {
	my $self = shift;
	return $self->{status};
}

=head2 add_placemark

Adds the placemark (a L<Geo::Coder::GoogleMaps::Location> object) given in parameter to the list of placemarks.

This methods croak on errors (like if you did not give a proper object in argument).

=cut

sub add_placemark {
	my $self = shift;
	my $location = shift;
	if( defined($location) && UNIVERSAL::isa( $location, "Geo::Coder::GoogleMaps::Location") ){
		push @{$self->{placemarks}},$location;
	}
	else{
		Carp::croak("add_placemark() : takes a Geo::Coder::GoogleMaps::Location as mandatory argument.\n");
	}
}

=head2 placemarks

Return the complete list of placemarks, or an arrayref depending on the context.

In any case the array contains a list of L<Geo::Coder::GoogleMaps::Location> objects.

=cut

sub placemarks {
	my $self = shift;
	wantarray ? @{$self->{placemarks}} : [@{$self->{placemarks}}]; # I voluntarly create a new reference to prevent (at last a little...) the deletion of placemarks
}

=head2 clean_placemarks

Remove all the placemarks from the response object.

=cut

sub clean_placemarks {
	my $self = shift;
	$self->{placemarks} = [];
}

=head2 clean_status

Reset the response object's status to its initial state (undefined).

=cut

sub clean_status {
	my $self = shift;
	$self->{status} = {code=>-1,request=>""};
}

1;
__END__

=head1 AUTHOR

Arnaud Dupuis, C<< <a.dupuis at infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-geo-coder-googlemaps at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-GoogleMaps>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::GoogleMaps::Response

You can also look for information at:

=over 4

=item * Infinity Perl: 

L<http://www.infinityperl.org>

=item * Google Code repository

L<https://code.google.com/p/geo-coder-googlemaps/>

=item * Google Maps API documentation

L<http://code.google.com/apis/maps/documentation/geocoding/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-GoogleMaps>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-GoogleMaps>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-GoogleMaps>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-GoogleMaps>

=back

=head1 ACKNOWLEDGEMENTS

Slaven Rezic (L<SREZIC>) for all the patches and his useful reports on RT.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2010 Arnaud DUPUIS, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Geo::Coder::GoogleMaps
