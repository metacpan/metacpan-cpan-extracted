package Geo::WebService::OpenCellID::Response::cell;
use warnings;
use strict;
use base qw{Geo::WebService::OpenCellID::Response};
our $VERSION = '0.06';

=head1 NAME

Geo::WebService::OpenCellID::Response::cell - Perl API for the opencellid.org database

=head1 SYNOPSIS

=head1 DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

=head1 USAGE

=head1 METHODS

=head2 mnc

=cut

sub mnc {
  my $self=shift;
  return $self->{"data"}->{"cell"}->[0]->{"mnc"};
}

=head2 mcc

=cut

sub mcc {
  my $self=shift;
  return $self->{"data"}->{"cell"}->[0]->{"mcc"};
}

=head2 lac

=cut

sub lac {
  my $self=shift;
  return $self->{"data"}->{"cell"}->[0]->{"lac"};
}

=head2 cellid, cellId

=cut

*cellId=\&cellid;

sub cellid {
  my $self=shift;
  return $self->{"data"}->{"cell"}->[0]->{"cellid"} || $self->{"data"}->{"cell"}->[0]->{"cellId"};
}

=head1 COPYRIGHT

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
