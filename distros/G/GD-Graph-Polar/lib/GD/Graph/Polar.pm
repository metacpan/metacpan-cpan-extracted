package GD::Graph::Polar;
use strict;
use warnings;
use base qw{Package::New};
use Cwd qw{};
use Geo::Constants qw{PI};
use Geo::Functions qw{rad_deg};
use GD qw{gdSmallFont};

our $VERSION = '0.22';

=head1 NAME

GD::Graph::Polar - Perl package to create polar graphs using GD package

=head1 SYNOPSIS

  use GD::Graph::Polar;
  my $obj = GD::Graph::Polar->new(size=>480, radius=>100);
  $obj->addPoint(50=>25);                                  #radius => angle (e.g. polar form of complex number notation)
  $obj->addPoint_rad(50=>3.1415);
  $obj->addGeoPoint(75=>25);
  $obj->addGeoPoint_rad(75=>3.1415);
  $obj->addLine($radius0=>$theta0, $radius1=>$theta1);
  $obj->addLine_rad($radius0=>$theta0, $radius1=>$theta1);
  $obj->addGeoLine($radius0=>$theta0, $radius1=>$theta1);
  $obj->addGeoLine_rad($radius0=>$theta0, $radius1=>$theta1);
  $obj->addArc($radius0=>$theta0, $radius1=>$theta1);
  $obj->addArc_rad($radius0=>$theta0, $radius1=>$theta1);
  $obj->addGeoArc($radius0=>$theta0, $radius1=>$theta1);
  $obj->addGeoArc_rad($radius0=>$theta0, $radius1=>$theta1);
  $obj->addString($radius=>$theta, "Hello World!");
  $obj->addString_rad($radius=>$theta, "Hello World!");
  $obj->addGeoString($radius=>$theta, "Hello World!");
  $obj->addGeoString_rad($radius=>$theta, "Hello World!");
  $obj->font(gdSmallFont);  #sets the current font from GD exports
  $obj->color("blue");      #sets the current color from Graphics::ColorNames
  $obj->color([0,0,0]);     #sets the current color [red,green,blue]
  print $obj->draw; #PNG image

=head1 DESCRIPTION

This package is a wrapper around GD to produce polar graphs with an easy interface.  I use this package to plot antenna patterns on a graph with data from the L<RF::Antenna::Planet::MSI::Format> package.

=head1 CONSTRUCTOR

=head2 new

The new constructor. 

  my $obj = GD::Graph::Polar->new(           #default values
                                  size          => 480,    #width and height in pixels
                                  radius        => 1,      #max value of the radius
                                  radius_origin => 0,      #value at the origin
                                  ticks         => 10,     #number of major ticks
                                  border        => 2,      #pixel border around graph
                                  rgbfile       => "/usr/X11R6/lib/X11/rgb.txt"
                                 );

=head1 METHODS

=head2 addPoint

Method to add a point to the graph.

  $obj->addPoint(50=>25);

=cut

sub addPoint {
  my $self   = shift;
  my $radius = shift;
  my $theta  = rad_deg(shift());
  return $self->addPoint_rad($radius,$theta);
}

=head2 addPoint_rad

Method to add a point to the graph.

  $obj->addPoint_rad(50=>3.1415);

=cut

sub addPoint_rad {
  my $self    = shift;
  my $radius  = shift;
  my $theta   = shift;
  my ($x, $y) = $self->_imgxy_rt_rad($radius,$theta);
  my $icon    = 7;
  return $self->gdimage->arc($x,$y,$icon,$icon,0,360,$self->color);
}

=head2 addGeoPoint

Method to add a point to the graph.

  $obj->addGeoPoint(75=>25);

=cut

sub addGeoPoint {
  my $self   = shift;
  my $radius = shift;
  my $theta  = rad_deg(shift());
  return $self->addGeoPoint_rad($radius,$theta);
}

=head2 addGeoPoint_rad

Method to add a point to the graph.

  $obj->addGeoPoint_rad(75=>3.1415);

=cut

sub addGeoPoint_rad {
  my $self   = shift;
  my $radius = shift;
  my $theta  = PI()/2-shift();
  return $self->addPoint_rad($radius,$theta);
}

=head2 addLine

Method to add a line to the graph.

  $obj->addLine(50=>25, 75=>35);

=cut

sub addLine {
  my $self    = shift;
  my $radius0 = shift;
  my $theta0  = rad_deg(shift());
  my $radius1 = shift;
  my $theta1  = rad_deg(shift());
  return $self->addLine_rad($radius0=>$theta0, $radius1=>$theta1);
}

=head2 addLine_rad

Method to add a line to the graph.

  $obj->addLine_rad(50=>3.14, 75=>3.45);

=cut

sub addLine_rad {
  my $self      = shift;
  my $radius0   = shift;
  my $theta0    = shift;
  my $radius1   = shift;
  my $theta1    = shift;
  my ($x0=>$y0) = $self->_imgxy_rt_rad($radius0=>$theta0);
  my ($x1=>$y1) = $self->_imgxy_rt_rad($radius1=>$theta1);
  return $self->gdimage->line($x0, $y0, $x1, $y1, $self->color);
}

=head2 addGeoLine

Method to add a line to the graph.

  $obj->addGeoLine(50=>25, 75=>35);

=cut

sub addGeoLine {
  my $self    = shift;
  my $radius0 = shift;
  my $theta0  = rad_deg(shift());
  my $radius1 = shift;
  my $theta1  = rad_deg(shift());
  return $self->addGeoLine_rad($radius0=>$theta0, $radius1=>$theta1);
}

=head2 addGeoLine_rad

Method to add a line to the graph.

  $obj->addGeoLine_rad(50=>3.14, 75=>3.45);

=cut

sub addGeoLine_rad {
  my $self    = shift;
  my $radius0 = shift;
  my $theta0  = PI()/2-shift();
  my $radius1 = shift;
  my $theta1  = PI()/2-shift();
  return $self->addLine_rad($radius0=>$theta0, $radius1=>$theta1);
}

=head2 addArc

Method to add an arc to the graph.

  $obj->addArc(50=>25, 75=>35);

=cut

sub addArc {
  my $self    = shift;
  my $radius0 = shift;
  my $theta0  = rad_deg(shift());
  my $radius1 = shift;
  my $theta1  = rad_deg(shift());
  return $self->addArc_rad($radius0=>$theta0, $radius1=>$theta1);
}

=head2 addArc_rad

Method to add an arc to the graph.

  $obj->addArc_rad(50=>3.14, 75=>3.45);

=cut

sub addArc_rad {
  my $self    = shift;
  my $radius0 = shift;
  my $theta0  = shift;
  my $radius1 = shift;
  my $theta1  = shift;
  my $m       = ($radius1-$radius0) / ($theta1-$theta0);
  my $inc     = 0.02; #is this good?
  my $steps   = int(($theta1-$theta0) / $inc);
  my @array   = ();
  foreach my $step (0 .. $steps) {
    my $theta  = $step / $steps * ($theta1-$theta0) + $theta0;
    my $radius = $radius0 + $m * ($theta-$theta0);
    push @array, [$radius=>$theta];
  } 
  my @return = ();
  foreach my $step (1 .. $steps) {
    push @return, $self->addLine_rad(@{$array[$step-1]}, @{$array[$step]});
  }
  return \@return;
}

=head2 addGeoArc

Method to add an arc to the graph.

  $obj->addGeoArc(50=>25, 75=>35);

=cut

sub addGeoArc {
  my $self    = shift;
  my $radius0 = shift;
  my $theta0  = rad_deg(shift());
  my $radius1 = shift;
  my $theta1  = rad_deg(shift());
  return $self->addGeoArc_rad($radius0=>$theta0, $radius1=>$theta1);
}

=head2 addGeoArc_rad

Method to add an arc to the graph.

  $obj->addGeoArc_rad(50=>25, 75=>35);

=cut

sub addGeoArc_rad {
  my $self    = shift;
  my $radius0 = shift;
  my $theta0  = PI()/2-shift();
  my $radius1 = shift;
  my $theta1  = PI()/2-shift();
  return $self->addArc_rad($radius0=>$theta0, $radius1=>$theta1);
}

=head2 addString

Method to add a string to the graph.

=cut

sub addString {
  my $self   = shift;
  my $radius = shift;
  my $theta  = rad_deg(shift());
  my $string = shift;
  return $self->addString_rad($radius=>$theta, $string);
}

=head2 addString_rad

Method to add a string to the graph.

=cut

sub addString_rad {
  my $self    = shift;
  my $radius  = shift;
  my $theta   = shift;
  my $string  = shift;
  my ($x=>$y) = $self->_imgxy_rt_rad($radius=>$theta);
  return $self->gdimage->string($self->font, $x, $y, $string, $self->color);
}

=head2 addGeoString

Method to add a string to the graph.

=cut

sub addGeoString {
  my $self   = shift;
  my $radius = shift;
  my $theta  = rad_deg(shift());
  my $string = shift;
  return $self->addGeoString_rad($radius=>$theta, $string);
}

=head2 addGeoString_rad

Method to add a string to the graph.

=cut

sub addGeoString_rad {
  my $self   = shift;
  my $radius = shift;
  my $theta  = PI()/2-shift();
  my $string = shift;
  return $self->addString_rad($radius=>$theta, $string);
}

=head1 Objects

=head2 gdimage

Returns a L<GD> object

=cut

sub gdimage {
  my $self           = shift;
  $self->{'gdimage'} = shift if @_; #set a base chart or watermark
  unless ($self->{'gdimage'}) {
    $self->{'gdimage'} = GD::Image->new($self->size, $self->size);

    # make the background transparent and interlaced
    $self->gdimage->transparent($self->color([255,255,255]));
    $self->gdimage->interlaced('true');
    
    # Put a frame around the picture
    $self->gdimage->rectangle(0, 0, $self->size - 1, $self->size - 1, $self->color([0,0,0]));
  
    #Add concentric circles around origin ticks is number of circles
    if ($self->ticks > 0) {
      $self->color([192,192,192]);
      foreach my $tick (1 .. $self->ticks) {
        my $c = $self->size / 2;
        my $r = $self->_width * $tick / $self->ticks;
        $self->gdimage->arc($c,$c,$r,$r,0,360,$self->color);
      }
    }
  
    #Add radiating lines around origin axes is number of lines
    if ($self->axes > 0) {
      $self->color([192,192,192]);
      my $delta = 360 / $self->axes;
      my $angle = 0;
      while ($angle < 360) {
        $self->addLine($self->radius_origin, $angle, $self->radius, $angle);
        $angle += $delta;
      }
    }

    #default to black pen color
    $self->color([0,0,0]);
  }
  return $self->{'gdimage'};
}

=head2 gcnames

Returns a L<Graphics::ColorNames> object.

=cut

sub gcnames {
  my $self = shift;
  unless (defined $self->{'gcnames'}) {
    eval 'use Graphics::ColorNames';
    if ($@) {
      die('Error: Cannot load Graphics::ColorNames');
    } else {
      my $file           = $self->rgbfile; #stringify for object support
      $self->{'gcnames'} = Graphics::ColorNames->new("$file"); #file path must be true per File::Spec::Unix::file_name_is_absolute
    }
  }
  return $self->{'gcnames'};
}

=head1 Properties

=head2 color

Method to set or return the current drawing color

  my $colorobj = $obj->color("blue");     #if Graphics::ColorNames available
  my $colorobj = $obj->color([77,82,68]); #rgb=>[decimal,decimal,decimal]
  my $colorobj = $obj->color;

Default: [0,0,0] (i.e., black)

=cut

sub color {
  my $self = shift;
  if (@_) {
    my $color = shift;
    if (ref($color) eq 'ARRAY') {
      my ($r, $g, $b) = @$color;
      $self->{'color'} = $self->{'colors'}->{$r}->{$g}->{$b}||=$self->gdimage->colorAllocate(@$color);
    } else {
      if ($self->gcnames) {
        my @rgb          = $self->gcnames->rgb($color);
        @rgb             = (0,0,0) unless scalar(@rgb) == 3;
        $self->{'color'} = $self->color(\@rgb);
      } else {
        $self->{'color'} = $self->color([0,0,0]);
      }
    }
  }
  return $self->{'color'};
}

=head2 font

Method to set or return the current drawing font (only needed by the very few)

  use GD qw(gdGiantFont gdLargeFont gdMediumBoldFont gdSmallFont gdTinyFont);
  $obj->font(gdSmallFont); #the default
  $obj->font;

Default: gdSmallFont

=cut

sub font {
  my $self        = shift;
  $self->{'font'} = shift if @_;
  $self->{'font'} = gdSmallFont unless $self->{'font'};
  return $self->{'font'};
}

=head2 size

Sets or returns the width and height of the image in pixels.

Default: 480

=cut

sub size {
  my $self        = shift;
  $self->{'size'} = shift if @_;
  $self->{'size'} = 480 unless $self->{'size'};
  return $self->{'size'};
}

=head2 radius

Sets or returns the radius of the graph which sets the scale of the maximum value of the graph.

Default: 1

=cut

sub radius {
  my $self          = shift;
  $self->{'radius'} = shift if @_;
  $self->{'radius'} = 1 unless defined $self->{'radius'};
  return $self->{'radius'};
}

=head2 radius_origin

Sets or returns the radius origin of the graph which sets the value scale at the origin of the graph.

Default: 0

=cut

sub radius_origin {
  my $self                 = shift;
  $self->{'radius_origin'} = shift if @_;
  $self->{'radius_origin'} = 0 unless defined $self->{'radius_origin'};
  return $self->{'radius_origin'};
}

=head2 border

Sets and returns the number of pixels that border the graph on the image.

Default: 2

=cut

sub border {
  my $self          = shift;
  $self->{'border'} = shift if @_;
  $self->{'border'} = 2 unless defined($self->{'border'});
  return $self->{'border'};
}

=head2 ticks

Sets and returns the number of ticks on the graph.

Default: 10

=cut

sub ticks {
  my $self         = shift;
  $self->{'ticks'} = shift if @_;
  $self->{'ticks'} = 10
    unless defined($self->{'ticks'});
  return $self->{'ticks'};
}

=head2 axes

Sets and returns the number of axes (plural of axis) on the graph.

Default: 4

=cut

sub axes {
  my $self        = shift;
  $self->{'axes'} = shift if @_;
  $self->{'axes'} = 4 unless defined $self->{'axes'};
  return $self->{'axes'};
}


=head2 rgbfile

Sets or returns an RGB file.

Note: This method will search in a few locations for a file.

=cut

sub rgbfile {
  my $self           = shift;
  $self->{'rgbfile'} = shift if @_;
  unless (defined $self->{'rgbfile'}) {
    my $cwd = Cwd::getcwd();
    foreach my $dir ('/etc/X11/rgb.txt', '/usr/share/X11/rgb.txt', '/usr/X11R6/lib/X11/rgb.txt', "$cwd/rgb.txt", "$cwd/../rgb.txt") {
      next unless -r $dir; 
      $self->{'rgbfile'} = $dir;
      last;
    }
  }
  return $self->{'rgbfile'};
}

=head2 draw

Method returns a PNG binary blob.

  my $png_binary = $obj->draw;

=cut

sub draw {
  my $self = shift;
  return $self->gdimage->png;
}

#=head2 _scale
#
#Method returns the parameter scaled to the image.
#
#=cut

sub _scale {
  my $self   = shift;
  my $radius = shift;
  $radius    = $self->radius_origin if $radius < $self->radius_origin; #polar graphs do not support negative values
  return $self->_width / 2 * ($radius - $self->radius_origin)/($self->radius - $self->radius_origin);
}

#=head2 _width
#
#Method returns the width of the graph.
#
#=cut

sub _width {
  my $self = shift;
  return $self->size - $self->border * 2;
}

#=head2 _imgxy_xy
#
#Method to convert xy to imgxy cordinates
#
#  $obj->addPoint_rad(50=>3.1415);
#
#=cut

sub _imgxy_xy {
  my $self = shift;
  my $x    = shift();
  my $y    = shift();
  my $sz   = $self->_width;
  $x       = $sz/2 + $x + $self->border;
  $y       = $sz/2 - $y + $self->border;
  return ($x, $y);
}

#=head2 _xy_rt_rad
#
#Method to convert polar cordinate to Cartesian cordinates.
#
#=cut

sub _xy_rt_rad {
  my $self   = shift;
  my $radius = shift;
  my $theta  = shift;
  my $x      = $radius*cos($theta);
  my $y      = $radius*sin($theta);
  return ($x, $y);
}

#=head2 _imgxy_rt_rad
#
#Method to convert polar cordinate to Cartesian cordinates.
#
#=cut

sub _imgxy_rt_rad {
  my $self   = shift;
  my $radius = shift;
  my $theta  = shift;
  my ($x,$y) = $self->_xy_rt_rad($self->_scale($radius), $theta);
  return $self->_imgxy_xy($x, $y);
}

=head1 LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

=head1 SEE ALSO

L<GD>, L<Geo::Constants>, L<Geo::Functions>, L<Graphics::ColorNames>

=cut

1;
