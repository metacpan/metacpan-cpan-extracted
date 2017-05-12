package Geo::Coder::GoogleMaps;

use warnings;
use strict;
use Carp;
use Encode;
use JSON::Syck;
use HTTP::Request;
use LWP::UserAgent;
use URI;
use XML::LibXML ;
use Geo::Coder::GoogleMaps::Location;
use Geo::Coder::GoogleMaps::Response;

=encoding utf-8

=head1 NAME

Geo::Coder::GoogleMaps - Google Maps Geocoding API

=head1 VERSION

Version 0.4

=cut

our $VERSION = '0.4';

=head1 SYNOPSIS

WARNING WARNING WARNING

	There is a huge API change between version 0.2 and 0.3 ! Please see the documentation of the geocode() method !

WARNING WARNING WARNING

This module provide Google Maps API. Please note that this module use Tatsuhiko Miyagawa's work on L<Geo::Coder::Google> as base (L<http://search.cpan.org/~miyagawa/>).

In fact it's a fork of Mr Miyagawa's module. Geo::Coder::GoogleMaps use the default JSON data type as default output but also support XML/KML.

The direct output of the geocode() method is no longer a L<Geo::Coder::GoogleMaps::Location> but a Geo::Coder::GoogleMaps::Response. This one contains a list of L<Geo::Coder::GoogleMaps::Location> objects which can be, individually, exported to any of the supported format.


	use Geo::Coder::GoogleMaps;
	
	my $gmap = Geo::Coder::GoogleMaps->new( apikey => 'abcd' , output => 'xml');
	my $response = $gmap->geocode(location => '88 rue du chateau, 92600, Asnières sur seine, France');
	if( $response->is_success() ){
		my $location = $response->placemarks()->[0];
		print $location->latitude,',',$location->longitude,"\n";
		$location->toKML()->toString(); # is absolutly equivalent to $location->toKML(1);
	}

=head1 FUNCTIONS

=head2 new

The object constructor it takes the following parameters :

	apikey : your Google API key (only parameter mandatory).
	ua : a LWP::UserAgent object. If not provided a new user agent is instanciates.
	host : the google map service url (default is: maps.google.com)
	output : the output method between xml, kml and json (csv support plan for futur release). Default is json.

Example:

	my $gmap = Geo::Coder::GoogleMaps->new( apikey => 'abcdef', host => 'maps.google.fr', output => 'xml');

=cut


sub new {
	my($class, %param) = @_;
	
	my $key = delete $param{apikey}
		or Carp::croak("Usage: new(apikey => \$apikey)");
	
	my $ua   = delete $param{ua}   || LWP::UserAgent->new(agent => "Mozilla/5.0 (compatible;Geo::Coder::GoogleMaps/$Geo::Coder::GoogleMaps::VERSION");
	my $host = delete $param{host} || 'maps.google.com';
	my $output = delete $param{output} || 'json';
	
	bless { key => $key, ua => $ua, host => $host, output => $output }, $class;
}

=head2 geocode

WARNING WARNING WARNING

	There is a huge API change between version 0.2 and 0.3 ! This method do not returns placemarks directly anymore !!

WARNING WARNING WARNING

Get a location from the Google Maps API. It return a L<Geo::Coder::GoogleMaps::Response> object.

	my $response = $gmap->geocode(location => '88 rue du chateau, 92600, Asnières sur seine, France');
	print $response->placemarks()->[0]->Serialize(1) if( $response->is_success() ) ;

Please note that for the moment the geocode methode rely on JSON::Syck to parse the Google's output and ask for result in JSON format.

In futur release the 'output' from the constructor will mainly be used to define the way you want this module get the data. 

The dependency to L<JSON::Syck> and L<XML::LibXML> will be removed to be optionnal and dynamically load.

=cut

sub geocode {
	my $self = shift;
	
	my %param;
	if (@_ % 2 == 0) {
		%param = @_;
	} else {
		$param{location} = shift;
	}
	
	my $location = $param{location}
		or Carp::croak("Usage: geocode(location => \$location)");
	
	if (Encode::is_utf8($location)) {
		$location = Encode::encode_utf8($location);
	}
	
	my $uri = URI->new("http://$self->{host}/maps/geo");
	$uri->query_form(q => $location, key => $self->{key},sensor => "false", output => "json");
# 	$uri->query_form(q => $location, output => $self->{output}, key => $self->{key});
	
	my $res = $self->{ua}->get($uri);
	
	if ($res->is_error) {
		Carp::croak("Google Maps API returned error: " . $res->status_line);
	}
	
	# Ugh, Google Maps returns so stupid HTTP header
	# Content-Type: text/javascript; charset=UTF-8; charset=Shift_JIS
	my @ctype = $res->content_type;
	my $charset = ($ctype[1] =~ /charset=([\w\-]+)$/)[0] || "utf-8";
	
	my $content = Encode::decode($charset, $res->content);
	local $JSON::Syck::ImplicitUnicode = 1;
	my $data = JSON::Syck::Load($content);
	
# 	print "[Debug] JSON::Syck::Load()-ed data:\n",Data::Dumper::Dumper( $data ),"\n";
	
	my $response = Geo::Coder::GoogleMaps::Response->new(status_code => $data->{Status}->{code}, status_request => $data->{Status}->{request} );
	my @placemark=();
	foreach my $Placemark (@{$data->{Placemark}}){
		my $loc = Geo::Coder::GoogleMaps::Location->new(output => $self->{output});
		$loc->_setData($Placemark);
# 		print "[Debug] JSON::Syck::Load()-ed data:\n",Data::Dumper::Dumper( $Placemark ),"\n";
		$response->add_placemark($loc);
		push @placemark, $loc;
	}
# 	print "[debug] new response object:\n",Data::Dumper::Dumper($response),"\n";
	return $response;
# 	wantarray ? @placemark : $placemark[0];
}

1;
__END__

=head1 AUTHOR

L<Geo::Coder::Google> (the original module) is from Tatsuhiko Miyagawa.

Arnaud Dupuis, C<< <a.dupuis at infinityperl.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-geo-coder-googlemaps at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-GoogleMaps>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::GoogleMaps

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
