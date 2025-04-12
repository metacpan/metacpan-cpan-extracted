package Geo::WebService::OpenCellID::Response::cell::get;
use warnings;
use strict;
use base qw{Geo::WebService::OpenCellID::Response::cell};
our $VERSION = '0.06';

=head1 NAME

Geo::WebService::OpenCellID::Response::cell::get - Perl API for the opencellid.org database

=head1 SYNOPSIS

=head1 DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

=head1 USAGE

=head1 METHODS

=head2 lat

=cut

sub lat {
  my $self=shift;
  return $self->{"data"}->{"cell"}->[0]->{"lat"};
}

=head2 lon

=cut

sub lon {
  my $self=shift;
  return $self->{"data"}->{"cell"}->[0]->{"lon"};
}

=head2 range

=cut

sub range {
  my $self=shift;
  return $self->{"data"}->{"cell"}->[0]->{"range"};
}

=head2 nbSamples

=cut

sub nbSamples {
  my $self=shift;
  return $self->{"data"}->{"cell"}->[0]->{"nbSamples"};
}

=head1 COPYRIGHT

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
