package Geo::WebService::OpenCellID::Base;
use warnings;
use strict;
our $VERSION = '0.06';

=head1 NAME

Geo::WebService::OpenCellID::Base - Perl API for the opencellid.org database

=head1 SYNOPSIS

  use base qw{Geo::WebService::OpenCellID::Base};

=head1 DESCRIPTION

=head1 USAGE

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head2 initialize

=cut

sub initialize {
  my $self = shift();
  %$self=@_;
}

=head1 METHODS

=head2 parent

=cut

sub parent {
  my $self=shift;
  return $self->{"parent"};
}

=head1 COPYRIGHT

Copyright (c) 2025 Michael R. Davis

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
