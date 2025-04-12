package Geo::WebService::OpenCellID::Response::cell::getMeasures;
use warnings;
use strict;
use base qw{Geo::WebService::OpenCellID::Response::cell::get};
our $VERSION = '0.06';

=head1 NAME

Geo::WebService::OpenCellID::Response::cell::getMeasures - Perl API for the opencellid.org database

=head1 SYNOPSIS

=head1 DESCRIPTION

Perl Interface to the database at http://www.opencellid.org/

=head1 USAGE

=head1 METHODS

=head2 measure, measures

Returns a list of measures (list of hash references)

=cut

*measure=\&measures;

sub measures {
  my $self=shift;
  my $list=$self->{"data"}->{"cell"}->[0]->{"measure"};
  return wantarray ? @$list : $list;
}

=head1 COPYRIGHT

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
