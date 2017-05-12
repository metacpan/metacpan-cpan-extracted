package Geo::Coder::GoogleMaps::Location ;

use strict;
use warnings;
use strict;
use Carp;
use JSON::Syck;
use XML::LibXML;

our $VERSION='0.4';

=encoding utf-8

=head1 NAME

Geo::Coder::GoogleMaps::Location - Geo::Coder::GoogleMaps' Location object

=head1 VERSION

Version 0.4 (follow L<Geo::Coder::GoogleMaps> version number)

=head1 SYNOPSIS

Here we have the object returned by L<Geo::Coder::GoogleMaps::Response>->placemarks().

This object can generate and manipulate the geocoding subset of KML 2.2 object (main change for the geocoding feature is the introduction of ExtendedData).

=head1 FUNCTIONS

=head2 new

The constructor can take the following arguments :

	- SubAdministrativeAreaName : a string
	- PostalCodeNumber : a postal code (err...)
	- LocalityName : yes! A locality name !
	- ThoroughfareName: same thing => a string
	- AdministrativeAreaName
	- CountryName
	- CountryNameCode
	- address
	- longitude
	- latitude
	- altitude (warning in Google Maps API altitude must be 0)

=cut

sub new {
	my($class, %param) = @_;
	my $obj = {
		'AddressDetails' => {
			'Country' => {
				'AdministrativeArea' => {
					'SubAdministrativeArea' => {
						'SubAdministrativeAreaName' => delete $param{'SubAdministrativeAreaName'} || '',
						'Locality' => {
							'PostalCode' => {
								'PostalCodeNumber' => delete $param{'PostalCodeNumber'} || ''
							},
							'LocalityName' => delete $param{'LocalityName'} || '',
							'Thoroughfare' => {
								'ThoroughfareName' => delete $param{'ThoroughfareName'} || ''
							}
						}
					},
					'AdministrativeAreaName' => delete $param{'AdministrativeAreaName'} || ''
				},
				'CountryNameCode' => delete $param{'CountryNameCode'} || '',
				'CountryName' => delete $param{'CountryName'} || ''
			}
		},
		'address' => delete $param{'address'} || '',
		'Point' => {
			'coordinates' => [
				delete $param{'longitude'} || '',
				delete $param{'latitude'} || '',
				delete $param{'altitude'} || 0
			]
		}
	};
	my $out = delete $param{'output'} || 'json';
	bless { data => $obj, output => $out }, $class;
}

=head2 SubAdministrativeAreaName

Access the SubAdministrativeAreaName parameter.

	print $location->SubAdministrativeAreaName(); # retrieve the value
	$location->SubAdministrativeAreaName("Paris"); # set the value

=cut

sub SubAdministrativeAreaName {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'SubAdministrativeArea'}->{'SubAdministrativeAreaName'}=$data : $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'SubAdministrativeArea'}->{'SubAdministrativeAreaName'} ;
}

=head2 PostalCodeNumber

Access the PostalCodeNumber parameter.

	print $location->PostalCodeNumber(); # retrieve the value
	$location->PostalCodeNumber("75000"); # set the value

=cut

sub PostalCodeNumber {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'SubAdministrativeArea'}->{'Locality'}->{'PostalCode'}->{'PostalCodeNumber'}=$data : $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'SubAdministrativeArea'}->{'Locality'}->{'PostalCode'}->{'PostalCodeNumber'} ;
}

=head2 ThoroughfareName

Access the ThoroughfareName parameter.

	print $location->ThoroughfareName(); # retrieve the value
	$location->ThoroughfareName("1 Avenue des Champs Élysées"); # set the value

=cut

sub ThoroughfareName {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'SubAdministrativeArea'}->{'Locality'}->{'Thoroughfare'}->{'ThoroughfareName'}=$data : $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'SubAdministrativeArea'}->{'Locality'}->{'Thoroughfare'}->{'ThoroughfareName'} ;
}

=head2 LocalityName

Access the LocalityName parameter.

	print $location->LocalityName(); # retrieve the value
	$location->LocalityName("Paris"); # set the value

=cut

sub LocalityName {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'SubAdministrativeArea'}->{'Locality'}->{'LocalityName'}=$data : $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'SubAdministrativeArea'}->{'Locality'}->{'LocalityName'} ;
}

=head2 AdministrativeAreaName

Access the AdministrativeAreaName parameter.

	print $location->AdministrativeAreaName(); # retrieve the value
	$location->AdministrativeAreaName("PA"); # set the value

=cut

sub AdministrativeAreaName {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'AdministrativeAreaName'}=$data : $self->{data}->{'AddressDetails'}->{'Country'}->{'AdministrativeArea'}->{'AdministrativeAreaName'} ;
}

=head2 CountryName

Access the CountryName parameter.

	print $location->CountryName(); # retrieve the value
	$location->CountryName("France"); # set the value

=cut

sub CountryName {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'AddressDetails'}->{'Country'}->{'CountryName'}=$data : $self->{data}->{'AddressDetails'}->{'Country'}->{'CountryName'} ;
}

=head2 CountryNameCode

Access the CountryNameCode parameter.

	print $location->CountryNameCode(); # retrieve the value
	$location->CountryNameCode("FR"); # set the value

=cut

sub CountryNameCode {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'AddressDetails'}->{'Country'}->{'CountryNameCode'}=$data : $self->{data}->{'AddressDetails'}->{'Country'}->{'CountryNameCode'} ;
}

=head2 Accuracy

Access the Accuracy parameter.

	print $location->Accuracy(); # retrieve the value
	$location->Accuracy(8); # set the value

=cut

sub Accuracy {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'AddressDetails'}->{'Accuracy'}=$data : $self->{data}->{'AddressDetails'}->{'Accuracy'} ;
}

=head2 address

Access the address parameter.

	print $location->address(); # retrieve the value
	$location->address("1 Avenue des Champs Élysées, 75000, Paris, FR"); # set the value

=cut

sub address {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'address'}=$data : $self->{data}->{'address'} ;
}

=head2 id

Access the id parameter.

	print $location->id(); # retrieve the value
	$location->id("point1"); # set the value

=cut

sub id {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'id'}=$data : $self->{data}->{'id'} ;
}

=head2 latitude

Access the latitude parameter.

	print $location->latitude(); # retrieve the value
	$location->latitude("-122.4558"); # set the value

=cut

sub latitude {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'Point'}->{'coordinates'}->[1]=$data : $self->{data}->{'Point'}->{'coordinates'}->[1] ;
}


=head2 longitude

Access the longitude parameter.

	print $location->longitude(); # retrieve the value
	$location->longitude("55.23465"); # set the value

=cut

sub longitude {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'Point'}->{'coordinates'}->[0]=$data : $self->{data}->{'Point'}->{'coordinates'}->[0] ;
}

=head2 altitude

Access the altitude parameter.

	print $location->altitude(); # retrieve the value
	$location->altitude(0); # set the value

Please note that it must be 0 if you use the Google Map API.

=cut

sub altitude {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'Point'}->{'coordinates'}->[2]=$data : $self->{data}->{'Point'}->{'coordinates'}->[2] ;
}

=head2 coordinates

This method is not really an accessor, it's only a getter which return longitude, latitude and altitude as a string.

	print "Placemark's coordinates: ",$location->coordinates,"\n";

=cut

sub coordinates {
	my $self = shift;
	return $self->longitude().','.$self->latitude().','.$self->altitude ;
}

=head2 LLB_north

Access the north parameter from the LatLonBox.

	print $location->LLB_north(); # retrieve the value
	$location->LLB_north(48.9157461); # set the value

=cut

sub LLB_north {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'ExtendedData'}->{'LatLonBox'}->{'north'}=$data : $self->{data}->{'ExtendedData'}->{'LatLonBox'}->{'north'} ;
}

=head2 LLB_south

Access the south parameter from the LatLonBox.

	print $location->LLB_south(); # retrieve the value
	$location->LLB_south(48.9157461); # set the value

=cut

sub LLB_south {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'ExtendedData'}->{'LatLonBox'}->{'south'}=$data : $self->{data}->{'ExtendedData'}->{'LatLonBox'}->{'south'} ;
}

=head2 LLB_east

Access the east parameter from the LatLonBox.

	print $location->LLB_east(); # retrieve the value
	$location->LLB_east(48.9157461); # set the value

=cut

sub LLB_east {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'ExtendedData'}->{'LatLonBox'}->{'east'}=$data : $self->{data}->{'ExtendedData'}->{'LatLonBox'}->{'east'} ;
}

=head2 LLB_west

Access the west parameter from the LatLonBox.

	print $location->LLB_west(); # retrieve the value
	$location->LLB_west(48.9157461); # set the value

=cut

sub LLB_west {
	my ($self,$data) = @_ ;
	return $data ? $self->{data}->{'ExtendedData'}->{'LatLonBox'}->{'west'}=$data : $self->{data}->{'ExtendedData'}->{'LatLonBox'}->{'west'} ;
}

=head2 toJSON

Return a JSON encoded object ( thanks to JSON::Syck::Dump() )

	my $json = $location->toJSON ;

=cut

sub toJSON {
	my $self = shift;
	return JSON::Syck::Dump($self->{'data'}) ;
}

=head2 toKML

Return a KML object ( thanks to XML::LibXML ).

	my $kml = $location->toXML ;

Please note that this function can take an optionnal argument (0 or 1) and if it's set to 1 this method return a XML string instead of the XML::LibXML::Document object.

=cut

sub toKML {
	sub _toKMLinternal {
		my $self = shift;
		my $document = shift;
		my $xml_element = shift;
		my $root = shift;
		return unless($root);
		return unless( ref($root) eq "HASH" );
# 		print "[debug] _toKMLinternal() \$root=$root\n";
		foreach my $key (keys(%{$root})){
			next if($key eq "Accuracy");
# 			print "[debug] _toKMLinternal() creating new element: $key\n";
			my $new_element = $document->createElement($key);
			if( $self->can($key) ){
				if(defined($self->$key)){
					$new_element->appendText($self->$key);
					$xml_element->appendChild($new_element);
				}
			}
			else{
				if($key eq 'AddressDetails'){
					$new_element->setNamespace("urn:oasis:names:tc:ciq:xsdschema:xAL:2.0", '',0);
					$new_element->setAttribute('Accuracy',$self->Accuracy);
				}
				elsif( $key eq 'LatLonBox' ){
					$new_element->setAttribute('north',$root->{$key}->{north});
					$new_element->setAttribute('south',$root->{$key}->{south});
					$new_element->setAttribute('east',$root->{$key}->{east});
					$new_element->setAttribute('west',$root->{$key}->{west});
				}
				$xml_element->appendChild($new_element);
				_toKMLinternal($self,$document,$new_element,$root->{$key}) unless($key eq 'LatLonBox');
			}
		}
	}
	
	my $self = shift;
	my $as_string = shift;
	my $document = XML::LibXML::Document->createDocument( "1.0", "UTF-8" );
	$document->setStandalone(1);
	my $kml = $document->createElement('kml');
# 	$kml->setNamespace("http://earth.google.com/kml/2.1", '',0);
	$kml->setNamespace("http://www.opengis.net/kml/2.2", '',0);
	$document->setDocumentElement($kml);
	my $placemark = $document->createElement('Placemark');
	$placemark->setAttribute('id',$self->id);
	$kml->appendChild($placemark);
	my $data = {%{$self->{data}}};
	delete($data->{id});
# 	delete($data->{AddressDetails}->{Accuracy});
	_toKMLinternal($self,$document,$placemark,$data);
	$document->setEncoding("UTF-8");
	return $document->toString(1) if($as_string);
	return $document;
}

=head2 toXML

An allias for toKML()

=cut

sub toXML {
	return shift->toKML(@_);
}

=head2 Serialize

This method simply call the good to(JSON|XML|KML) depending of the output format you selected.

You can eventually pass extra arguments, they will be relayed.

	$location->Serialize(1); # if the output is set to XML or KML you will have a stringified XML as output

=cut

sub Serialize {
	my $self = shift;
	if($self->{output}){
		return $self->toJSON if($self->{output} eq 'json');
		return $self->toKML(@_) if($self->{output} eq 'xml' or $self->{output} eq 'kml');
		return $self->toJSON ;
	}
	else {
		return $self->toJSON ;
	}
}

=head2 Serialyze (OBSOLETE)

This method is just an alias to Serialize(), it is kept for backward compatibility only.

Please use the Serialize() method, this one is meant to be removed.

=cut

sub Serialyze {
	return Serialize(@_);
}

sub _setData {
	my ($self,$data)=@_;
	$self->{data}=$data;
}

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

    perldoc Geo::Coder::GoogleMaps::Location

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

Copyright 2007 Arnaud DUPUIS and Nabla Development, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
1; # end of Geo::Coder::GoogleMaps::Location