package Geo::Coder::Canada::Response;

use strict;

our $VERSION = '0.01';

use constant DEBUG => 0;

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  return $self;
}

sub staddress {
  my $self = shift;
  $self->{staddress} = $_[0] if $_[0];
  return $self->{staddress};
}

sub stnumber {
  my $self = shift;
  $self->{stnumber} = $_[0] if $_[0];
  return $self->{stnumber};
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

sub postal {
  my $self = shift;
  $self->{postal} = $_[0] if $_[0];
  return $self->{postal};
}

sub id {
  my $self = shift;
  $self->{id} = $_[0] if $_[0];
  return $self->{id};
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

sub inlatt {
  my $self = shift;
  $self->{inlatt} = $_[0] if $_[0];
  return $self->{inlatt};
}

sub inlongt {
  my $self = shift;
  $self->{inlongt} = $_[0] if $_[0];
  return $self->{inlongt};
}

sub distance {
  my $self = shift;
  $self->{distance} = $_[0] if $_[0];
  return $self->{distance};
}

1;
__END__
=head1 NAME

Geo::Coder::Canada::Response - Perl extension which contains the geocoder.ca response values.

=head1 SYNOPSIS

  use Geo::Coder::Canada;
  my $g = Geo::Coder::Canada->new;
  $g->latt(45.44);
  $g->long(-75.7);

  # Get the Geo::Coder::Canada::Response object...
  my $response = $g->reverse_coder;
  my $street = $response->staddress;
  my $city   = $response->city;

=head1 DESCRIPTION

This object contains the values returned by Geo::Coder::Canada as received from geocoder.ca

=head1 ATTRIBUTES

=item latt()

The latitude. A decimal number.

=item long()

The longitude. A decimal number.

=item id()

The Transaction ID. If you supplied one before within the request phase.

=item addresst()

The name of the street address

=item city()

The city of the result.

=item prov()

The province.

=item postal()

The postal code.

=item stnumber()

The street number.

=item staddress()

The street address.

=item distance()

The distance of the rsult location from the input location.

=head1 AUTHOR

Jeff Anderson <jeff@pvrcanada.com>

Copyright (c) 2006 Jeff Anderson. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Please see geocoder.ca for more information on the Canadian geocoder API and contact information for commercial applications.

=head1 SEE ALSO

Geo::Coder::Canada

=cut
