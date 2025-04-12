package Geo::WebService::OpenCellID::Response::measure::add;
use warnings;
use strict;
use base qw{Geo::WebService::OpenCellID::Response::measure};
our $VERSION = '0.06';

=head1 NAME

Geo::WebService::OpenCellID::Response::measure::add - Perl API for the opencellid.org database

=head1 SYNOPSIS

=head1 DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

=head1 USAGE

=head1 METHODS

=head2 id

=cut

sub id {
  my $self=shift;
  return $self->{"data"}->{"id"};
}

=head2 cellid

=cut

sub cellid {
  my $self=shift;
  return $self->{"data"}->{"cellid"};
}

=head2 res

=cut

sub res {
  my $self=shift;
  return $self->{"data"}->{"res"}->[0];
}

=head1 COPYRIGHT

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
