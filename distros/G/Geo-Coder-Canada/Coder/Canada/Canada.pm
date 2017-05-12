package Geo::Coder::Canada;

use strict;

use Geo::Coder::Canada::Response;
use Geo::Coder::Canada::Error;
use XML::Simple;
use LWP::UserAgent;
use HTTP::Request;
use URI;
use Data::Dumper;

our $VERSION = '0.01';

use constant DEBUG    => 0;
use constant GEO_HOST => q{http://geocoder.ca};

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  return $self;
}

sub addresst {
  my $self = shift;
  $self->{addresst} = $_[0] if $_[0];
  return $self->{addresst};
}

sub stno {
  my $self = shift;
  $self->{stno} = $_[0] if $_[0];
  return $self->{stno};
}

sub street1 {
  my $self = shift;
  $self->{street1} = $_[0] if $_[0];
  return $self->{street1};
}

sub street2 {
  my $self = shift;
  $self->{street2} = $_[0] if $_[0];
  return $self->{street2};
}

sub city {
  my $self = shift;
  $self->{city} = $_[0] if $_[0];
  return $self->{city};
}

sub prov {
  my $self = shift;
  $self->{prov} = $_[0] if $_[0];
  return $self->{prov};
}

sub locate {
  my $self = shift;
  $self->{locate} = $_[0] if $_[0];
  return $self->{locate};
}

sub decimal {
  my $self = shift;
  $self->{decimal} = $_[0] if $_[0];
  return $self->{decimal};
}

sub postal {
  my $self = shift;
  $self->{postal} = $_[0] if $_[0];
  return $self->{postal};
}

sub geoit {
  my $self = shift;
  $self->{geoit} = $_[0] if $_[0];
  return $self->{geoit};
}

sub id {
  my $self = shift;
  $self->{id} = $_[0] if $_[0];
  return $self->{id};
}

sub recompute {
  my $self = shift;
  $self->{recompute} = $_[0] if $_[0];
  return $self->{recompute};
}

sub showpostal {
  my $self = shift;
  $self->{showpostal} = $_[0] if $_[0];
  return $self->{showpostal};
}

sub latt {
  my $self = shift;
  $self->{latt} = $_[0] if $_[0];
  return $self->{latt};
}

sub longt {
  my $self = shift;
  $self->{longt} = $_[0] if $_[0];
  return $self->{longt};
}

sub range {
  my $self = shift;
  $self->{range} = $_[0] if $_[0];
  return $self->{range};
}

sub geo_result {
  my $self = shift;
  $self->{geo_result} = $_[0] if $_[0];
  return $self->{geo_result};
}

sub geodata {
  my $self = shift;
  $self->{geodata} = $_[0] if $_[0];
  return $self->{geodata};
}

sub error {
  my $self = shift;
  $self->{error} = $_[0] if $_[0];
  return $self->{error};
}

sub geocode {
  my $self    = shift;

  my %form_values;
  foreach my $param (qw(stno addresst city prov postal)) {
    $form_values{$param} = $self->$param;
  }
  foreach my $param (qw(locate decimal id recompute showpostal)) {
    $form_values{$param} = $self->$param if $self->$param;
  }
  $form_values{geoit} = 'XML';

warn Data::Dumper->Dump([\%form_values],['Form Values']) if DEBUG;

  $self->process_request(%form_values);

  if ($self->geodata->{error}) {
    $self->process_error;
  }
  else {
    my $geodata    = $self->geodata;
    my $geo_result = Geo::Coder::Canada::Response->new;
    foreach my $param (qw(latt longt id postal)) {
      $geo_result->$param($geodata->{$param});
    }
    $self->geo_result($geo_result);
  }

  return $self->geo_result;
}

sub process_request {
  my $self        = shift;
  my %form_values = @_;

  my $uri = URI->new;
  $uri->query_form(%form_values);
  my $ua  = LWP::UserAgent->new;
  my $req = HTTP::Request->new(POST => GEO_HOST);
  $req->content_type('application/x-www-form-urlencoded');
  $req->content($uri->query);

  my $res    = $ua->request($req);
  my $result = $res->as_string;
  $result    =~ s/.*(<geodata>)/$1/sm;

warn $result if DEBUG;

  my $xs      = XML::Simple->new;
  my $geodata = $xs->XMLin($result);

#  warn Data::Dumper->Dump([$geodata]);

  return $self->geodata($geodata);
}

sub process_error {
  my $self    = shift;
  my $geodata = $self->geodata; 

  my $error = Geo::Coder::Canada::Error->new;
  foreach my $param (qw(code description)) {
    $error->$param($geodata->{error}->{$param});
  }
  foreach my $suggest_param (qw(stno addresst city prov)) {
    $error->$suggest_param($geodata->{suggestion}->{$suggest_param});
  }
  return $self->error($error);
}

sub intersection_geocode {
  my $self    = shift;

  my %form_values;
  foreach my $param (qw(street1 street2 city prov decimal postal)) {
    $form_values{$param} = $self->$param;
  }
  foreach my $param (qw(locate decimal id showpostal)) {
    $form_values{$param} = $self->$param if $self->$param;
  }
  $form_values{cross} = 1;
  $form_values{geoit} = 'XML';

  $self->process_request(%form_values);

  if ($self->geodata->{error}) {
    $self->process_error;
  }
  else {
    my $geodata    = $self->geodata;
    my $geo_result = Geo::Coder::Canada::Response->new;
    foreach my $param (qw(latt longt id postal)) {
      $geo_result->$param($geodata->{$param});
    }
    $self->geo_result($geo_result);
  }

  return $self->geo_result;
}

sub reverse_geocode {
  my $self    = shift;

  my %form_values;
  foreach my $param (qw(latt longt)) {
    $form_values{$param} = $self->$param;
  }
  foreach my $param (qw(range decimal id)) {
    $form_values{$param} = $self->$param if $self->$param;
  }
  $form_values{reverse} = 1;
  $form_values{geoit}   = 'XML';

  $self->process_request(%form_values);

  if ($self->geodata->{error}) {
    $self->process_error;
  }
  else {
    my $geodata    = $self->geodata;
    my $geo_result = Geo::Coder::Canada::Response->new;
    foreach my $param (qw(latt longt city prov postal stnumber staddress inlatt inlongt distance id)) {
      $geo_result->$param($geodata->{$param});
    }
    $self->geo_result($geo_result);
  }

  return $self->geo_result;
}

1;
__END__
=head1 NAME

Geo::Coder::Canada - Perl extension for getting longitude and latitude cordinates given a Canadian address. Also, provides reverse geocoding to return the nearest shipping address given a longitude and latitude point.

=head1 SYNOPSIS

  use Geo::Coder::Canada;
  
  my $g = Geo::Coder::Canada->new;

  # Standard Geocoding...
  $g->addresst('Main St');
  $g->stno(100);
  $g->city('Toronto');
  $g->prov('ON');
  $g->postal('M4E2V8');
  if ($g->geocode) {
    my $latitude  = $g->latt;
    my $longitude = $g->long;
  }
  else {
    my $error_msg = $g->error->message;
  }

  # Intersection geocoding...
  $g->street1('Burrard Street');
  $g->street2('Robson Street');
  $g->city('Vancouver');
  $g->prov('BC');
  $g->intersection_geocode;

  # Reverse geocoding...
  $g->latt(45.44);
  $g->long(-75.7);
  $g->reverse_geocode;

=head1 DESCRIPTION

This module provides a Perl frontend for the geocoder.ca website XML API. It allows the programmer to convert from street address information to longitude and latitude coordinates as well as the reverse function. This module also provides some extra features like defining an address using a nearby cross street intersections and determining a the postal code for an address.

=head1 METHODS

=over 4

=item new()

Returns a new Geo::Coder::Canada object.

=item geocode()

Send the address information to geocoder.ca and return the Geo::Coder::Canada::Response object.
You are required to set the addresst, stno, city and prov methods or the postal method before calling geocode().

=item reverse_geocode()

Send the latt/long values to geocoder.ca and return a Geo::Coder::Canada::Response object.
You are required to enter street1, street2, city and prov methods before calling geocode().

=item intersection_geocode()

Send the intersection address information and return a Geo::Coder::Canada::Response object.
You are required to set the latt and long methods before calling intersection_geocode().

=item geo_response()

Contains a reference to the Geo::Coder::Canada::Response object (in case you missed it during the request call)

=item error()

Contains a reference to the Geo::Coder::Canada::Error object. This is only set when the original geocode request failed.

=back

=head1 ATTRIBUTES

=over 4

=item addresst(), stno(), street1(), street2(), city(), prov(), locate(), postal()

These methods contain basic get/set methods and provide no validation.

=item decimal()

An optional parameter to limit the number of decimal places in the lat and long response values.

=item id()

An optional value you can set which is returned back as sent. Used to match requests to response values?

=item recompute()

Optional value to produce better accuracy on longitude and latitude values. Although this is not assured. See the geocoder.ca site for more information.

=item showpostal()

Optional value to set if you have not given a postal address. in this case the postal address will be returned by geocoder.ca and available in the response object. Only the values 1 or 0 are valid.

=item latt()

A decimal input value representing the latitude of the address.

=item long()

A decimal input value representing the longitude of the address.

=back

=head1 REQUIREMENTS

XML::Simple,
LWP::UserAgent,
HTTP::Request,
URI

=head1 AUTHOR

Jeff Anderson, jeff@pvrcanada.com

Copyright (c) 2006 Jeff Anderson. All rights reserved.
This program is free software; you can redistribut it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Geo::Coder::Canada::Response,
Geo::Coder::Canada::Error

=cut
