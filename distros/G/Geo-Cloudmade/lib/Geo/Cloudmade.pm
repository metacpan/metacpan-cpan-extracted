package Geo::Cloudmade;

use 5.006000;
our $VERSION = '0.9';

=head1 NAME

Geo::Cloudmade - An extended interface to Cloudmade's Geo API (geocoding, routing, drawing tiles)

=head1 DESCRIPTION
  
  Cloudmade ( http://cloudmade.com ) is a provider of services based on OSM (OpenStreetMaps) data.

  Unfortunatelly only "enterprise" customers may use this API since 1st of May 2014.

  This module implements an OO wrapper around Cloudmade's Geo API.

  The following capabilities were implemented:
   - geocoding and geosearching
   - routing
   - obtaining tiles

=head1 SYNOPSIS

  use Geo::Cloudmade;
  
  #use api key for access to service
  my $geo = Geo::Cloudmade->new('BC9A493B41014CAABB98F0471D759707');
  
  #find coordinates of geo object
  my @arr = $geo->find("Potsdamer Platz,Berlin,Germany", {results=>5, skip=>0});

  print $geo->error(), "\n" unless @arr;

  print "Number of results: ", scalar (@arr), "\n";
  foreach (@arr) {
    print $_->name,":\n", $_->centroid->lat, "/", $_->centroid->long, "\n"
  }

  # finding closest POI (Point of Interest)
  # for list all available objects please look at http://developers.cloudmade.com/projects/show/geocoding-http-api
  @arr = $geo->find_closest('library', [59.12, 81.1]);
  print "No closest variants\n" unless @arr;

  # reverse geocoding
  my ($reverse)  = $geo->find_closest('address', [52.4870,13.4248]);
  if (defined $reverse) {
    print join ' ', $reverse->properties('addr:housenumber', 'addr:street', 'addr:postcode', 'addr:city'), "\n";
  } else { print "No results, sorry\n" }

  #calculate route
  my $route = $geo->get_route([47.25976, 9.58423], [47.66117, 9.99882], { type=>'car', method=>'shortest' } );
  print "Distance: ", $route->total_distance, "\n";
  print "Start: ", $route->start, "\n";
  print "End: ", $route->end, "\n";

  print "Route instructions:\n";
  print join (',', @$_), "\n" foreach (@{$route->instructions});

  #get tile
  my $tile = $geo->get_tile([47.26117, 9.59882], {zoom=>10, tile_size=>256});
  open (my $fh, '>', 'test.png') or die "Cannot open file $!\n";
  binmode $fh;
  print $fh $tile;

=cut

use strict;
use warnings;
use LWP::UserAgent;
use URI;
use JSON;
use Math::Trig;

use constant HOST => 'cloudmade.com';
use constant DEBUG => $ENV{GEO_CLOUDMADE_DEBUG};

=head1 CONSTRUCTOR

=head2 new API-KEY

 Usage		      :   my $geo = Geo::Cloudmade->new('your-ip-key');
 Function       :   Constructs and returns a new Geo::Cloudmade object
 Returns        :   a Geo::Cloudmade object
 API-KEY        :   api key provided by Cloudmade. For request api key please visit http://developers.cloudmade.com/projects>

=cut
sub new {
  my ($class, $key) = @_;
  bless {
      key => $key,
      ua => LWP::UserAgent->new( keep_alive => 2 ),
      error => '',
      http_status => 0,
  }, $class
}

# internal method 
# TODO - add comment
sub call_service {
  my ($self, $path, $params, $subdomain) = @_;
    my $host = defined $subdomain ? "$subdomain.".HOST : HOST;
    my $uri = URI->new;
    $uri->scheme('http');
    $uri->host($host);
    $uri->path("$self->{key}/$path");
    $uri->query_form($params);

    print "uri=", $uri->as_string, "\n" if DEBUG;
    my $request = new HTTP::Request(GET => $uri->as_string);
    my $response = $self->{ua}->request($request);

    $self->{http_status} = $response->code;
    if ($response->is_success) {
        $self->{error} = '';
        return $response->content;
    }
    else {
        $self->{error} = "HTTP request error: ".$response->status_line."\n";
        return undef;
    }
}

=head1 OBJECT METHODS

=head2 find QUERY, PARAMS

 Usage	 :    my @arr = $geo->find("Potsdamer Platz,Berlin,Germany", {results=>5, skip=>0});
 Function:    Returns geo objects (bound box and\or location) by query or nothing
 Returns :    Array of Geo::Cloudmade::Result objects or one Geo::Cloudmade::Results if scalar value was expected
 QUERY	 :    Query in format POI, House Number, Street, City, County like "Potsdamer Platz, Berlin, Germany".
              Also near is supported in queries, e.g. "hotel near Potsdamer Platz, Berlin, Germany"
 PARAMS  :   Hash for control ouptut. Valid elements are bbox, results, skip, bbox_only, return_geometry, return_location
             For more info about parameters please look at http://developers.cloudmade.com/wiki/geocoding-http-api/Documentation

=cut

sub find {
  my ($self, $name, $opt) = @_;
  my %params = ( query=>$name, return_geometry => 'true', %$opt );
  my $content =  $self->call_service("geocoding/v2/find.js", [%params], 'geocoding');

  return unless $content;
  my $ref = from_json($content, {utf8 => 1});
  my @objs;
  push @objs, bless $_, 'Geo::Cloudmade::Result' foreach (@{$ref->{features}});
  return @objs if wantarray;
  return bless  [ objs=>\@objs ], 'Geo::Cloudmade::Results'
}

=head2 find_closest OBJECT POINT PARAMS 

  Usage: @arr = $geo->find_closest('library', [59.12, 81.1]);
  Function: Find closest object(s).
  Returns array of Geo::Cloudmade::Result objects like find method
  OBJECT - point of interest, list of supported objects located at http://developers.cloudmade.com/projects/show/geocoding-http-api
  POINT  - reference of array of [$lattitude, $longtitude]
  PARAMS - optional parameters like return_geometry and return_location
=cut

sub find_closest {
  my ($self, $objType, $point, $opt) = @_;
  $opt = {} unless defined $opt;
  my %params = ( return_geometry => 'true', return_location=>'true', 
                 around => $point->[0].','.$point->[1], 
                 object_type => $objType,
                 distance => 'closest',
                 %$opt );
  my $content =  $self->call_service("geocoding/v2/find.js", [%params], 'geocoding');

  return unless $content;
  my $ref = from_json($content, {utf8 => 1});
  my @objs;
  push @objs, bless $_, 'Geo::Cloudmade::Result' foreach (@{$ref->{features}});
  return @objs if wantarray;
  return bless  [ objs=>\@objs ], 'Geo::Cloudmade::Results'
}

=head2 get_route START_POINT END_POINT PARAMS
  
  Allowed parameters:
     type => 'car' // 'foot' // 'bicycle'
     method => 'shortest' // fastest' - only for route type 'car', default is 'shortest'
     lang => iso 2 characters code for language for the route instructions, default is en.
             Possible values are: de, en, es, fr, hu, it, nl, ro, ru, se, vi, zh.
     units => (measure units for distance calculation) 'km' // 'miles' (default 'km')

  Usage:
           my $route = $geo->get_route(
                  [47.25976, 9.58423], [47.66117, 9.99882],
                  { type=>'car', method=>'shortest' } );

  Returns:   Geo::Cloudmade::Route object from server or undef if communication with server was unsuccessful.
  Function:  Calculates route from START to END and returns Geo::Cloudmade::Route object
  See also:  Cloudmade's documentation about API for routing.
             http://developers.cloudmade.com/wiki/routing-http-api/Documentation
=cut

sub get_route {
  my ($self, $start, $end, $opt) = @_;
  my %params = ( type => 'car', method=>'shortest', lang=>'en', units=>'km', %$opt );
  my ($type, $method) = delete @params{qw/type method/};
  warn "Unexpected type $type" unless ($type eq 'car' or $type eq 'foot' or $type eq 'bicycle');

  my $content =  $self->call_service("api/0.3/".$start->[0].','.$start->[1].','.$end->[0].','.$end->[1]. 
                                    ($type eq 'car' ? "/$type/$method.js" : "/$type.js") , [%params], 'routes');
  return unless $content;
  my $ref = from_json($content, {utf8 => 1});
  return bless $ref, 'Geo::Cloudmade::Route';
}

=head2 get_tile CENTER PARAMS
  
  Returns raw png data of specified map point
  CENTER  array reference to latitude and longtitude
  PARAMS  optional parameters. Allowed parameters are zoom, stile, size
          For more info please look at official documentation from Cloudmade

=cut

sub get_tile {
  my ($self, $center, $opt) = @_;
  my %params = ( zoom=>10, style=>1, size=>256, %$opt );

  my ($lat, $long) = @$center;
  #get xytile
  my $factor = 2 ** ($params{zoom} - 1 );
  $_ = deg2rad($_) foreach ($lat, $long);

  my $xtile = 1 + $long / pi;
  my $ytile = 1 - log(tan($lat) + 1 / cos ($lat)) / pi;

  $_ = int (.5 + $_ * $factor) foreach ($xtile, $ytile);
  my $content = $self->call_service(join('/', (@params{qw{style size zoom}}, $xtile, $ytile)).'.png', undef, 'tile');

  return $content;
}

sub error { $_[0]->{error} }
sub http_status { $_[0]->{http_status} }

package Geo::Cloudmade::Route;
=head1 Geo::Cloudmade::Route

  Geo::Cloudmade::Route represents responce of routing request in decoded JSON.
  More details available here http://developers.cloudmade.com/wiki/routing-http-api/Response_structure .

  The following helper functions were added:
    - total_distance - distance in meters. (Probably it should be in requested units, see parameters of get_route)
    - start          - name of the start point of the route,
    - end            - name of the end point of the route,
    - valid          - returns 1 if status is 0 (OK)
    - status_message - text description in case of error
    - instructions   - array of detailed instructions, 
                       see more details in http://developers.cloudmade.com/wiki/routing-http-api/Response_structure 

=cut

sub total_distance { $_[0]->{route_summary}{total_distance} } 
sub start { $_[0]->{route_summary}{start_point} } 
sub end { $_[0]->{route_summary}{end_point} } 
sub valid { $_[0]->{status} ? 0 : 1 }
sub status_message { $_[0]->{status_message} }
sub instructions { $_[0]->{route_instructions} }

package Geo::Cloudmade::Results;
sub objs { $_[0]->{objs} }

package Geo::Cloudmade::Result;
sub name {
  $_[0]->{properties}{name}
}
sub properties {
  my ($this, @names) = @_;
  @{$this->{properties}}{@names};
}
sub centroid {
  return undef unless $_[0]->{centroid}{type} eq 'POINT';
  bless $_[0]->{centroid}{coordinates}, 'Geo::Cloudmade::Point'
}
package Geo::Cloudmade::Point;
sub lat {
  $_[0]->[0]
}
sub long {
  $_[0]->[1]
}

1;

=head1 SEE ALSO

 Official CloudMade's blog http://blog.cloudmade.com .

=head1 AUTHOR

Dmytro Gorbunov, E<lt>dmitro.gorbunov@gmail.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Dmytro Gorbunov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut


