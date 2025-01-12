package Geo::Constants;
use strict;
use warnings;
use base qw{Exporter};

our $VERSION   = '0.07';
our @EXPORT_OK = qw{PI DEG RAD KNOTS};

=head1 NAME

Geo::Constants - Package for standard Geo:: constants.

=head1 SYNOPSIS

  use Geo::Constants qw{PI DEG RAD}; #import into namespace
  print "PI:  ", PI(), "\n";
  print "d/r: ", DEG(), "\n";
  print "r/d: ", RAD(), "\n";

  use Geo::Constants;                #Perl OO
  my $obj = Geo::Constants->new();
  print "PI:  ", $obj->PI, "\n";
  print "d/r: ", $obj->DEG, "\n";
  print "r/d: ", $obj->RAD, "\n";

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

The new() constructor

  my $obj = Geo::Constants->new();

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) ? ref($this) : $this;
  my $self  = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head2 initialize

=cut

sub initialize {
  my $self=shift;
  %$self=@_;
}

=head1 FUNCTIONS

=head2 PI

  my $pi = $obj->PI;

  use Geo::Constants qw{PI};
  my $pi = PI();

=cut

sub PI {
  return 4 * atan2(1,1); #Perl should complile this as a constant
}

=head2 DEG

  my $degrees_per_radian = $obj->DEG;

  use Geo::Constants qw{DEG};
  my $degrees_per_radian = DEG();

UOM: degrees/radian

=cut

sub DEG {
  return 180 / PI(); #Degrees per radian
}

=head2 RAD

  my $radians_per_degree = $obj->RAD;

  use Geo::Constants qw{DEG};
  my $radians_per_degree = RAD();

UOM: radians/degree

=cut

sub RAD {
  return PI() / 180; #Radians per degree
}

=head2 KNOTS

1 nautical mile per hour = (1852/3600) m/s - United States Department of Commerce, National Institute of Standards and Technology, NIST Special Publication 330, 2001 Edition

Returns 1852/3600 m/s/knot

UOM: meters/second per knot

=cut

sub KNOTS {
  return 1852/3600; #1 nautical mile per hour = (1852/3600) m/s
}

=head1 AUTHOR

Michael R. Davis

=head1 LICENSE

Copyright (c) 2006-2025 Michael R. Davis

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Geo::Functions>, L<Geo::Ellipsoids>, L<Astro::Constants>

=cut

1;
