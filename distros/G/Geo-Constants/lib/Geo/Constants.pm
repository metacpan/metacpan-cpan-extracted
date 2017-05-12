require Exporter;
package Geo::Constants;

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

=cut

use strict;
#use vars qw($VERSION $PACKAGE @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use vars qw($VERSION @ISA @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT_OK = (qw{PI DEG RAD KNOTS});
$VERSION = sprintf("%d.%02d", q{Revision: 0.06} =~ /(\d+)\.(\d+)/);

=head1 CONSTRUCTOR

=head2 new

The new() constructor

  my $obj = Geo::Constants->new();

=cut

sub new {
  my $this = shift();
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  $self->initialize(@_);
  return $self;
}

=head1 METHODS

=cut

sub initialize {
  my $self = shift();
}

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

=cut

sub DEG {
  return 180 / PI(); #Degrees per radian
}

=head2 RAD

  my $radians_per_degree = $obj->RAD;

  use Geo::Constants qw{DEG};
  my $radians_per_degree = RAD();

=cut

sub RAD {
  return PI() / 180; #Radians per degree
}

=head2 KNOTS

1 nautical mile per hour = (1852/3600) m/s - United States Department of Commerce, National Institute of Standards and Technology, NIST Special Publication 330, 2001 Edition

Returns 1852/3600

=cut

sub KNOTS {
  return 1852/3600; #1 nautical mile per hour = (1852/3600) m/s
}

1;

__END__

=head1 TODO

Add more constants

=head1 BUGS

Please send to the geo-perl email list.

=head1 LIMITS

=head1 AUTHOR

Michael R. Davis qw/perl michaelrdavis com/

=head1 LICENSE

Copyright (c) 2006 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Geo::Functions
Geo::Ellipsoids
