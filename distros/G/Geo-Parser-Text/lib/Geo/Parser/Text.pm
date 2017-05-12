package Geo::Parser::Text;

use 5.006;
use strict;
use warnings;

use XML::Simple;
use LWP::UserAgent;
use HTTP::Request;
use URI;
use Data::Dumper;


use constant DEBUG    => 0;
use constant GEO_HOST => q{http://geocode.xyz};

sub new {
    my $class = shift;
    my $self = {
        geo_host        => shift
    };

    bless ($self, $class);
    return $self;
}

sub geodata {
  my $self = shift;
  $self->{geodata} = $_[0] if $_[0];
  return $self->{geodata};
}

sub geocode {
  my $self    = shift;
	my %params = @_;

  my %form_values;
  foreach my $param (keys %params) {
    $form_values{$param} = $params{$param};
  }
  $form_values{geoit} = 'XML'; #default

warn Data::Dumper->Dump([\%form_values],['Form Values']) if DEBUG;

  $self->process_request(%form_values);

    my $geodata    = $self->geodata;
	my @a = split(/<geodata>/,$geodata);
	my $geod = pop @a;
	$geod = '<geodata>' . $geod;
	my %t;
	my $ref = \%t;

	eval {
	$ref = XMLin($geod);
	};
  warn Data::Dumper->Dump([$ref],['Response']) if DEBUG;

  $self->geodata($ref);

  return $self->geodata;

}

sub process_request {
  my $self        = shift;
  my %form_values = @_;
  $self->{geo_host} = GEO_HOST unless $self->{geo_host};

  my $uri = URI->new;
  $uri->query_form(%form_values);
  my $ua  = LWP::UserAgent->new;
  my $req = HTTP::Request->new(POST => $self->{geo_host});
  $req->content_type('application/x-www-form-urlencoded');
  $req->content($uri->query);

  my $res    = $ua->request($req);
  my $result = $res->as_string;

warn $result if DEBUG;

  my $geodata = $result;


  return $self->geodata($geodata);
}



=head1 NAME

Geo::Parser::Text - Perl extension for parsing, geocoding and standardizing locations from free form text. (See Geocode.xyz or Geolytica.com or addrs.xyz for coverage details)

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

	use Geo::Parser::Text;
  
	# initialize with your host
	my $g = Geo::Parser::Text->new([geo_host]);

	# Scan text in $str for locations...
 	my $hashref = $g->geocode(scantext=>$str);

        # Geocode a single location from $str...
        my $hashref = $g->geocode(locate=>$str);
        #
                     
	# Example...

	use Geo::Parser::Text;
	use Data::Dumper;
	my $g = Geo::Parser::Text->new('http://geocode.xyz');

	my $str = "The most important museums of Amsterdam are located on the Museumplein, located at the southwestern side of the Rijksmuseum.";
	my $ref = $g->geocode(scantext=>$str,strict=>1,region='NL'); #in strict mode will return top matches only using context aware parsing (which may be slower)
	print Dumper $ref;

	#expected response
	$Response = {
              'match' => [
                         {
                           'latt' => '52.35704',
                           'confidence' => '0.8',
                           'longt' => '4.88356',
                           'location' => 'MUSEUMPLEIN, AMSTERDAM, NL'
                         },
                         {
                           'confidence' => '0.8',
                           'latt' => '52.36017396823732',
                           'longt' => '4.895017880552782',
                           'location' => 'Amsterdam, NL'
                         },
                         {
                           'latt' => '52.35994',
                           'confidence' => '0.7',
                           'longt' => '4.88539',
                           'location' => 'Rijksmuseum, NL'
                         },
                         {
                           'location' => '1, MUSEUMPLEIN, RIJKSMUSEUM, NL',
                           'longt' => '4.88345',
                           'confidence' => '0.5',
                           'latt' => '52.3576'
                         },
                         {
                           'location' => 'Museumplein, NL',
                           'longt' => '4.88194',
                           'latt' => '52.35722',
                           'confidence' => '0.5'
                         },
                         {
                           'location' => 'most, NL',
                           'longt' => '6.01528',
                           'confidence' => '0.5',
                           'latt' => '51.38417'
                         }
                       ]
            };
    

    	#or

	#forward geocode and cleanup/standardize input address
	my $ref = $g->geocode(locate=>'10 Downing St, londino UK');                    
  	print Dumper $ref;

	#expected response
	$Response = {
              'longt' => '-0.1275923',
              'standard' => {
                            'prov' => 'GB',
                            'confidence' => '0.80',
                            'city' => 'London',
                            'addresst' => '10 Downing St, London SW1A 2AB, UK',
                            'stnumber' => '10'
                          },
              'latt' => '51.5034066'
            };


	#reverse geocode
	my $ref = $g->geocode(locate=>'51.5034066,-0.1275923');
        print Dumper $ref;

	#expected response
	$Response = {
              'confidence' => '0.9',
              'distance' => '0',
              'city' => 'London',
              'inlatt' => '51.50341',
              'stnumber' => '9',
              'latt' => '51.50328',
              'postal' => 'SW1A 2AG',
              'staddress' => 'Downing Street',
              'longt' => '-0.12751',
              'inlongt' => '-0.12759',
              'prov' => 'UK'
            };

	
=head1 DESCRIPTION

This module provides a Perl frontend for the geocode.xyz, geocoder.ca and addrs.xyz API. 
It allows the programmer to extract locations containing street addresses, street intersections and city names along with their geocoded latitude,longitude from bodies of text such as microblogs or wikipedia entries. (It should work with any type of text, but dumping html text or paragraphs containing over 200 words, will slow down the response considerably. If you need faster parsing grab the geocode.xyz server image on the AWS, and run it on a faster server.
If you run your own instance, make sure to pass the instance ip address or domain name at invocation eg, Geo::Parser::Text->new($server). For North American locations use geolytica.com, and for Australia and New Zealand use addrs.xyz

The api also geocodes single locations (returning the location matched with the highest probability from a string of text. If you pass a latitude,longitude pair, it will reverse geocode that point)

For explanation on the API responses see http://geocode.xyz/api
 
=head2 METHODS

=head2 new

my $geo = new ( host => 'geocode.xyz');

Initialize with the default server. geocode.xyz for Europe, geocoder.ca for North America, addrs.xyz for Australia and New Zealand.

=head2 geocode

my $ref = $geo->geocode(locate=>'Paris France');

Set the text to be scanned or string to be geocoded and return the hash reference with the response. 
Takes a hash of parameter names and values.
You are required to pass a hash to geocode with either the scantext or locate key set to the text you want to geocode/geoparse.
You may also pass other optional arguments as described in the API.

=over 1

=back 
=head1 EXPORT

None by default.


=head1 REQUIREMENTS

XML::Simple,
LWP::UserAgent,
HTTP::Request,
URI

=head1 AUTHOR

Ervin Ruci, C<< <eruci at geocoder.ca> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-parser-text at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Parser-Text>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Parser::Text


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Parser-Text>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Parser-Text>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Parser-Text>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Parser-Text/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Ervin Ruci.

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


=head1 SEE ALSO

Geo::Coder::Canada
Geo::Coder::OpenCage
Geo::Parse::OSM
Text::NLP
=cut

1; # End of Geo::Parser::Text
