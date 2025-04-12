package Geo::WebService::OpenCellID::measure;
use warnings;
use strict;
use base qw{Geo::WebService::OpenCellID::Base};
use Geo::WebService::OpenCellID::Response::measure::add;
our $VERSION = '0.06';

=head1 NAME

Geo::WebService::OpenCellID::measure - Perl API for the opencellid.org database

=head1 SYNOPSIS

  use Geo::WebService::OpenCellID;
  my $gwo=Geo::WebService::OpenCellID->new(key=>$apikey);
  my $point=$gwo->measure->get(mcc=>$country,
                            mnc=>$network,
                            lac=>$locale,
                            cellid=>$cellid);
  printf "Lat:%s, Lon:%s\n", $point->latlon;

=head1 DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

=head1 USAGE

=head1 METHODS

=head2 add

Returns a response object L<Geo::WebService::OpenCellID::Response::measure::add>.

  my $response=$gwo->cell->add(key=>$myapikey,
                               lat=>$lat,
                               lon=>$lon,
                               mnc=>$mnc,
                               mcc=>$mcc,
                               lac=>$lac,
                               cellid=>$cellid,
                               measured_at=>$dt, #time format is not well defined
                                                 #use is optional
                                                 #suggest W3C e.g. 2009-02-28T07:25Z
                              );

  <?xml version="1.0" encoding="UTF-8" ?> 
  <rsp cellid="126694" id="6121024" stat="ok">
    <res>Measure added, id:6121024</res> 
  </rsp>

=cut

sub add {
  my $self=shift;
  return $self->parent->call("measure/add",
                             "Geo::WebService::OpenCellID::Response::measure::add",
                             @_);
}

=head1 COPYRIGHT

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
