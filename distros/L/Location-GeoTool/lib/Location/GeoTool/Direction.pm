package Location::GeoTool::Direction;

################################################################
#
#  Geometric Functions 
#  Location::GeoTool::Direction
#  

use 5.008;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = 0.97;

use Location::GeoTool;
use Carp;

__PACKAGE__->_make_accessors(
    qw(from_point to_point direction distance)
);

# Constructor -- set Startpoint
sub new
{
  my $class = shift;
  $class = ref($class) if (ref($class));
  my $arg = $_[0];
  my $self = {};

  if (UNIVERSAL::isa($arg, 'Location::GeoTool'))
  {
    $self->{'from_point'} = $arg->_clone;
  }
  else
  {
    $self->{'from_point'} = Location::GeoTool->create_coord(@_);
  }
  bless $self, $class;
}

# Set direction/distance and create Endpoint
sub set_vector
{
  my $self = shift;
  my ($dir,$dist) = @_[0..1];
 
  $self->{'direction'} = $dir;
  $self->{'distance'} = $dist;

  $dir = _regular_dir($dir);

  my $fp = $self->from_point;
  my ($flat,$flong) = $fp->format_degree->array;
  my $fdatum = $fp->out_datum;
  my $fformat = $fp->out_format;

  my ($tlat,$tlong) = Location::GeoTool::vector2point_degree($flat,$flong,$dir,$dist,$fdatum);
  
  my $to_point = Location::GeoTool->create_coord($tlat,$tlong,$fdatum,'degree');
  my $meth = "format_$fformat";
  $self->{'to_point'} = ($fdatum eq 'degree') ? $to_point : $to_point->$meth;

  return $self;
}

# Set Endpoint and calcurate direction/distance
sub set_topoint
{
  my $self = shift;
  my $arg = $_[0];

  if (UNIVERSAL::isa($arg, 'Location::GeoTool'))
  {
    $self->{'to_point'} = $arg->_clone;
  }
  else
  {
    $self->{'to_point'} = Location::GeoTool->create_coord(@_);
  }

  my $fp = $self->from_point;
  my ($flat,$flong) = $fp->format_degree->array;
  my $fdatum = $fp->out_datum;

  my $meth = "datum_$fdatum";
  my ($tlat,$tlong) = $self->{'to_point'}->$meth->format_degree->array;

  my ($dir,$dist) = Location::GeoTool::point2vector_degree($flat,$flong,$tlat,$tlong,$fdatum);

  $dir = _regular_dir($dir);

  $self->{'direction'} = $dir;
  $self->{'distance'} = $dist;

  return $self;
}

# Return a new Location::GeoTool::Direction object
# rotate around Startpoint and extend distance
sub pivot
{
  my $self = shift;
  croak "Please set End-point before call this method!!" unless ($self->to_point);
  my ($rot,$pow) = @_;

  my $dir = $self->direction + $rot;
  my $dist = $self->distance * $pow;
  
  if ($dist < 0)
  {
    $dir += 180;
    $dist = abs($dist);
  }

  return $self->new($self->from_point)->set_vector(_regular_dir($dir),$dist);
}

# Return a new Location::GeoTool::Direction object
# reverse between Startpoint and Endpoint
sub reverse
{
  my $self = shift;
  croak "Please set End-point before call this method!!" unless ($self->to_point);

  return $self->new($self->to_point)->set_topoint($self->from_point);
}

# Return the name of direction
sub dir_string
{
  return Location::GeoTool::direction_string(_regular_dir($_[0]->direction),$_[1] || 16,$_[2]);
}

# Normalize direction 0-360
sub _regular_dir
{
  my $dir = $_[0];
  while ($dir < 0 || $dir >= 360)
  {
    $dir += $dir < 0 ? 360 : -360;
  }
  return $dir;
}

sub _make_accessors 
{
  my($class, @attr) = @_;
  for my $attr (@attr) {
    no strict 'refs';
    *{"$class\::$attr"} = sub { shift->{$attr} };
  }
}

1;
__END__

=head1 NAME

Location::GeoTool::Direction - Perl extention to handle direction/distance

=head1 SYNOPSIS

  use Location::GeoTool;

  # Create
  $locobj = Location::GeoTool->create_coord('353924.491','1394010.478','wgs84','dmsn');
  $dirobj = $locobj->direction_point('403614.307','1410133.022','wgs84','dmsn');

  # Fields
  $dir = $dirobj->direction;        # 11.8035750... [°]
  $dist = $dirobj->distance;        # 561836.65713... [m]
  $start = $dirobj->from_point;     # '353924.491','1394010.478','wgs84','dmsn'の
                                      Location::GeoToolオブジェクト
  $end = $dirobj->to_point;         # '403614.307','1410133.022','wgs84','dmsn'の...

  # Methods
  $revobj = $dirobj->reverse;       # 始点 <-> 終点
  $midpoint = $dirobj->pivot(0,0.5);# 中点
  $dirstr = $dirobj->dir_string(4,'jp');
                                    # 「北」

=head1 DESCRIPTION

=head2 Create

Created by methods of Location::GeoTool.

  $dirobj = $locobj->direction_point('403614.307','1410133.022','wgs84','dmsn');
  $dirobj = $locobj->direction_point($another_locobj);
  $dirobj = $locobj->direction_vector(120,500);

=head2 Fields

Startpoint, Endpoint, diretion, distance is the fields of this object.

=head3 from_point

Return the Startpoint as Location::GeoTool object.

=head3 to_point

Return the Endpoint as Location::GeoTool object.

=head3 direction

Return the direction from Standpoint to Endpoint by degree between 0 and 360.
Start from North (0) and East is positive.

=head3 distance

Return the distance between Startpoint to Endpoint, by [m].

=head2 Methods

=head3 reverse

Return a new Location::GeoTool::Direction object which reverse Startpoint
to Endpoint, Endpoint ... and so on.

=head3 pivot 

  $newobj = $dirobj->pivot($rot,$pow);

Return a new Location::GeoTool::Direction object, which is rotate around
Startpoint and extend distance $pow times powered.

=head3 dir_string

  $dirstr = $dirobj->dir_string($denom,$lang);

Return the direction name of direction.
$denom specifies the all number of direction names. (4,8,16,32)
$lang is the language of name. ('jp','en')

Example of $denom:

  In case $dirobj->direction => 241

  $dirobj->dir_string(4,'en')  => 'W'
  $dirobj->dir_string(8,'en')  => 'SW'
  $dirobj->dir_string(16,'en') => 'WSW'
  $dirobj->dir_string(32,'en') => 'SWbW'

Character code of Japanese is EUC.

=head1 DEPENDENCIES

Math::Trig

=head1 SEE ALSO

Support this module in Kokogiko web site : http://kokogiko.net/

=head1 AUTHOR

OHTSUKA Ko-hei, E<lt>nene@kokogiko.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by Kokogiko!,

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut