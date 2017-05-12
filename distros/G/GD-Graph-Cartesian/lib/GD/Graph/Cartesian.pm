package GD::Graph::Cartesian;
use strict;
use warnings;
use base qw{Package::New};
use GD qw{gdSmallFont};
use List::MoreUtils qw{minmax};
use List::Util qw{first};

our $VERSION = '0.11';

=head1 NAME

GD::Graph::Cartesian - Make Cartesian Graphs with GD Package

=head1 SYNOPSIS

  use GD::Graph::Cartesian;
  my $obj=GD::Graph::Cartesian->new(height=>400, width=>800);
  $obj->addPoint(50=>25);
  $obj->addLine($x0=>$y0, $x1=>$y1);
  $obj->addRectangle($x0=>$y0, $x1=>$y1);
  $obj->addString($x=>$y, 'Hello World!');
  $obj->addLabel($pxx=>$pxy, 'Title'); #for labels on image not on chart 
  $obj->font(gdSmallFont);  #sets the current font from GD exports
  $obj->color('blue');      #sets the current color from Graphics::ColorNames
  $obj->color([0,0,0]);     #sets the current color [red,green,blue]
  print $obj->draw;

=head1 DESCRIPTION

This is a wrapper around L<GD> to place points and lines on a X/Y scatter plot.  

=head1 CONSTRUCTOR

=head2 new

The new() constructor. 

  my $obj = GD::Graph::Cartesian->new(                      #default values
                  width=>640,                               #width in pixels
                  height=>480,                              #height in pixels
                  ticksx=>10,                               #number of major ticks
                  ticksy=>10,                               #number of major ticks
                  borderx=>2,                               #pixel border left and right
                  bordery=>2,                               #pixel border top and bottom
                  rgbfile=>'/usr/X11R6/lib/X11/rgb.txt'
                  minx=>{auto},                             #data minx
                  miny=>{auto},                             #data miny
                  maxx=>{auto},                             #data maxx
                  maxy=>{auto},                             #data maxy
                  points=>[[$x,$y,$color],...],             #addPoint method
                  lines=>[[$x0=>$y0,$x1=>$y1,$color],...]   #addLine method
                  strings=>[[$x0=>$y0,'String',$color],...] #addString method
                      );

=head1 METHODS

=head2 addPoint

Method to add a point to the graph.

  $obj->addPoint(50=>25);
  $obj->addPoint(50=>25, [$r,$g,$b]);
  $obj->addPoint(50=>25, [$r,$g,$b], $size);        #size default iconsize 7
  $obj->addPoint(50=>25, [$r,$g,$b], $size, $fill); #fill 0|1

=cut

sub addPoint {
  my $self = shift;
  my $x    = shift;
  my $y    = shift;
  my $c    = shift || $self->color;
  my $s    = shift || $self->iconsize;
  my $f    = shift || 0;
  my $p    = $self->points;
  push @$p, [$x=>$y, $c, $s, $f];
  return scalar(@$p);
}

=head2 addLine

Method to add a line to the graph.

  $obj->addLine(50=>25, 75=>35);
  $obj->addLine(50=>25, 75=>35, [$r,$g,$b]);

=cut

sub addLine {
  my $self = shift;
  my $x0   = shift;
  my $y0   = shift;
  my $x1   = shift;
  my $y1   = shift;
  my $c    = shift || $self->color;
  my $l    = $self->lines;
  push @$l, [$x0=>$y0, $x1=>$y1, $c];
  return scalar(@$l);
}

=head2 addString

Method to add a string to the graph.

  $obj->addString(50=>25, 'String');
  $obj->addString(50=>25, 'String', [$r,$g,$b]);
  $obj->addString(50=>25, 'String', [$r,$g,$b], $font); #$font is a gdfont

=cut

sub addString {
  my $self = shift;
  my $x    = shift;
  my $y    = shift;
  my $s    = shift;
  my $c    = shift || $self->color;
  my $f    = shift || $self->font;
  my $a    = $self->strings;
  push @$a, [$x=>$y, $s, $c, $f];
  return scalar(@$a);
}

=head2 addLabel

Method to add a label to the image (not the graph).

  $obj->addLabel(50=>25, 'Label'); #x/y pixels of the image NOT units of the chart
  $obj->addLabel(50=>25, 'Label', [$r,$g,$b]);
  $obj->addLabel(50=>25, 'Label', [$r,$g,$b], $font); #$font is a gdfont

=cut

sub addLabel {
  my $self = shift;
  my $x    = shift;
  my $y    = shift;
  my $s    = shift;
  my $c    = shift || $self->color;
  my $f    = shift || $self->font;
  my $a    = $self->labels;
  push @$a, [$x=>$y, $s, $c, $f];
  return scalar(@$a);
}

=head2 addRectangle

  $obj->addRectangle(50=>25, 75=>35);
  $obj->addRectangle(50=>25, 75=>35, [$r,$g,$b]);

=cut

sub addRectangle {
  my $self = shift;
  my $x0   = shift;
  my $y0   = shift;
  my $x1   = shift;
  my $y1   = shift;
  my $c    = shift || $self->color;
  $self->addLine($x0=>$y0, $x0=>$y1, $c);
  $self->addLine($x0=>$y1, $x1=>$y1, $c);
  $self->addLine($x1=>$y1, $x1=>$y0, $c);
  return $self->addLine($x1=>$y0, $x0=>$y0, $c);
}

=head2 points 

Returns the points array reference.

=cut

sub points {
  my $self=shift;
  $self->{'points'}=[]
    unless ref($self->{'points'}) eq "ARRAY";
  return $self->{'points'};
}

=head2 lines 

Returns the lines array reference.

=cut

sub lines {
  my $self=shift;
  $self->{'lines'}=[]
    unless ref($self->{'lines'}) eq 'ARRAY';
  return $self->{'lines'};
}

=head2 strings 

Returns the strings array reference.

=cut

sub strings {
  my $self=shift;
  $self->{'strings'}=[]
    unless ref($self->{'strings'}) eq 'ARRAY';
  return $self->{'strings'};
}

=head2 labels

Returns the labels array reference.

=cut

sub labels {
  my $self=shift;
  $self->{'labels'}=[]
    unless ref($self->{'labels'}) eq 'ARRAY';
  return $self->{'labels'};
}


=head2 color

Method to set or return the current drawing color

  my $colorobj=$obj->color('blue');     #if Graphics::ColorNames available
  my $colorobj=$obj->color([77,82,68]); #rgb=>[decimal,decimal,decimal]
  my $colorobj=$obj->color;

=cut

sub color {
  my $self=shift;
  $self->{"color"}=shift if @_;
  $self->{"color"}=[0,0,0] unless defined $self->{"color"};
  return $self->{"color"};
}

sub _color_index {
  my $self=shift;
  my $color=shift || [0,0,0]; #default is black
  if (ref($color) eq "ARRAY") {
    #initialize cache
    my ($r,$g,$b)=@$color;
    $self->{'_color_index'}||={};
    $self->{'_color_index'}->{$r}||={};
    $self->{'_color_index'}->{$r}->{$g}||={};
    return $self->{'_color_index'}->{$r}->{$g}->{$b}||=$self->gdimage->colorAllocate(@$color);
  } else {
    my @rgb=$self->gcnames->rgb($color);
    if (scalar(@rgb) == 3) {
      return $self->_color_index(\@rgb); #recursion
    } else {
      warn(qq{Warning: Color "$color" not found.});
      return $self->_color_index([0,0,0]); #recursion
    }
  }
}

=head2 font

Method to set or return the current drawing font (only needed by the very few)

  use GD qw(gdGiantFont gdLargeFont gdMediumBoldFont gdSmallFont gdTinyFont);
  $obj->font(gdSmallFont); #the default
  $obj->font;

=cut

sub font {
  my $self=shift;
  $self->{'font'}=shift if @_;
  $self->{'font'}=gdSmallFont unless defined $self->{'font'};
  return $self->{'font'};
}

=head2 iconsize

=cut

sub iconsize {
  my $self=shift;
  $self->{"iconsize"}=shift if @_;
  $self->{"iconsize"}=7 unless $self->{"iconsize"};
  return $self->{"iconsize"};
}

=head2 draw

Method returns a PNG binary blob.

  my $png_binary=$obj->draw;

=cut

sub draw {
  my $self = shift;
  my $p    = $self->points;
  foreach (@$p) {
    my $x      = $_->[0];
    my $y      = $_->[1];
    my $c      = $_->[2] || $self->color;
    my $i      = $_->[3] || $self->iconsize;
    my $filled = $_->[4] || 0;
    if ($filled) {
      $self->gdimage->filledArc($self->_imgxy_xy($x,$y),$i,$i,0,360,$self->_color_index($c));
    } else {
      $self->gdimage->arc($self->_imgxy_xy($x,$y),$i,$i,0,360,$self->_color_index($c));
    }
  }
  my $l=$self->lines;
  foreach (@$l) {
    my $x0 = $_->[0];
    my $y0 = $_->[1];
    my $x1 = $_->[2];
    my $y1 = $_->[3];
    my $c  = $_->[4] || $self->color;
    $self->gdimage->line($self->_imgxy_xy($x0, $y0), $self->_imgxy_xy($x1, $y1), $self->_color_index($c));
  }
  my $s=$self->strings;
  foreach (@$s) {
    my $x = $_->[0];
    my $y = $_->[1];
    my $s = $_->[2];
    my $c = $_->[3] || $self->color;
    my $f = $_->[4] || $self->font;
    $self->gdimage->string($f, $self->_imgxy_xy($x, $y), $s, $self->_color_index($c));
  }
  my $label=$self->labels;
  foreach (@$label) {
    my $x = $_->[0];
    my $y = $_->[1];
    my $s = $_->[2];
    my $c = $_->[3] || $self->color;
    my $f = $_->[4] || $self->font;
    $self->gdimage->string($f, $x, $y, $s, $self->_color_index($c));
  }
  return $self->gdimage->png;
}

=head1 OBJECTS

=head2 gdimage

Returns a L<GD> object

=cut

sub gdimage {
  my $self=shift;
  unless ($self->{'gdimage'}) {
    $self->{'gdimage'}=GD::Image->new($self->width, $self->height);

    # make the background transparent and interlaced
    #$self->{'gdimage'}->transparent($self->_color_index([255,255,255]));
    $self->{'gdimage'}->filledRectangle(0, 0, $self->width, $self->height, $self->_color_index([255,255,255]));
    #$self->{'gdimage'}->interlaced('true');
  
    # Put a frame around the picture
    $self->{'gdimage'}->rectangle(0, 0, $self->width-1, $self->height-1, $self->_color_index([0,0,0]));
  }
  return $self->{'gdimage'};
}

=head2 gcnames

Returns a L<Graphics::ColorNames>

=cut

sub gcnames {
  my $self=shift;
  unless (defined $self->{'gcnames'}) {
    eval 'use Graphics::ColorNames';
    if ($@) {
      die("Error: Cannot load Graphics::ColorNames");
    } else {
      my $file=$self->rgbfile; #stringify for object support
      $self->{'gcnames'}=Graphics::ColorNames->new("$file") or die("Error: Graphics::ColorNames constructor failed.");
    }
  }
  return $self->{'gcnames'};
}

=head1 PROPERTIES

=head2 width

=cut

sub width {
  my $self=shift;
  $self->{'width'}=640
    unless defined $self->{'width'};
  return $self->{'width'};
}

=head2 height

=cut

sub height {
  my $self=shift;
  $self->{'height'}=480
    unless defined $self->{'height'};
  return $self->{'height'};
}

=head2 ticksx

=cut

sub ticksx {
  my $self=shift;
  $self->{'ticksx'}=10
    unless defined $self->{'ticksx'};
  return $self->{'ticksx'};
}

=head2 ticksy

=cut

sub ticksy {
  my $self=shift;
  $self->{'ticksy'}=10
    unless defined $self->{'ticksy'};
  return $self->{'ticksy'};
}

=head2 borderx

=cut

sub borderx {
  my $self=shift;
  $self->{'borderx'}=2
    unless defined $self->{'borderx'};
  return $self->{'borderx'};
}

=head2 bordery

=cut

sub bordery {
  my $self=shift;
  $self->{'bordery'}=2
    unless defined $self->{'bordery'};
  return $self->{'bordery'};
}

=head2 rgbfile

=cut

sub rgbfile {
  my $self=shift;
  $self->{'rgbfile'}=shift if @_;
  unless (defined $self->{'rgbfile'}) {
    $self->{'rgbfile'}="rgb.txt";
    my $rgb=first {-r} (qw{/etc/X11/rgb.txt /usr/share/X11/rgb.txt /usr/X11R6/lib/X11/rgb.txt ../rgb.txt});
    $self->{'rgbfile'}=$rgb if $rgb;
  }
  return $self->{'rgbfile'};
}

=head2 minx

=cut

sub minx {
  my $self=shift;
  ($self->{'minx'}, $self->{'maxx'})=$self->_minmaxx
    unless defined $self->{'minx'};
  return $self->{'minx'};
}

=head2 maxx

=cut

sub maxx {
  my $self=shift;
  ($self->{'minx'}, $self->{'maxx'})=$self->_minmaxx
    unless defined $self->{'maxx'};
  return $self->{'maxx'};
}

=head2 miny

=cut

sub miny {
  my $self=shift;
  ($self->{'miny'}, $self->{'maxy'})=$self->_minmaxy
    unless defined $self->{'miny'};
  return $self->{'miny'};
}

=head2 maxy

=cut

sub maxy {
  my $self=shift;
  ($self->{'miny'}, $self->{'maxy'})=$self->_minmaxy
    unless defined $self->{'maxy'};
  return $self->{'maxy'};
}

=head1 INTERNAL METHODS

=cut

sub _minmaxx {
  my $self = shift;
  my $p    = $self->points;
  my $l    = $self->lines;
  my $s    = $self->strings;
  my @x    = ();
  push @x, map {$_->[0]} @$p;
  push @x, map {$_->[0], $_->[2]} @$l;
  push @x, map {$_->[0]} @$s;
  return minmax(@x);
}

sub _minmaxy {
  my $self = shift;
  my $p    = $self->points;
  my $l    = $self->lines;
  my $s    = $self->strings;
  my @x    = ();
  push @x, map {$_->[1]} @$p;
  push @x, map {$_->[1], $_->[3]} @$l;
  push @x, map {$_->[1]} @$s;
  return minmax(@x);
}

=head2 _scalex

Method returns the parameter scaled to the pixels.

=cut

sub _scalex {
  my $self = shift;
  my $x    = shift; #units
  my $max  = $self->maxx;
  my $min  = $self->minx;
  my $s    = 1;
  if (defined($max) and defined($min) and $max-$min) {
    $s=($max - $min) / ($self->width - 2 * $self->borderx); #units/pixel
  }
  return $x / $s; #pixels
}

=head2 _scaley

Method returns the parameter scaled to the pixels.

=cut

sub _scaley {
  my $self = shift;
  my $y    = shift; #units
  my $max  = $self->maxy;
  my $min  = $self->miny;
  my $s    = 1;
  if (defined($max) and defined($min) and $max-$min) {
    $s=($max - $min) / ($self->height - 2 * $self->bordery); #units/pixel
  }
  return $y / $s; #pixels
}

=head2 _imgxy_xy

Method to convert xy to imgxy coordinates

=cut

sub _imgxy_xy {
  my $self = shift;
  my $x    = shift;
  my $y    = shift;
  return ($self->_imgx_x($x), $self->_imgy_y($y));
}

sub _imgx_x {
  my $self = shift;
  my $x    = shift;
  return $self->borderx + $self->_scalex($x - $self->minx);
}

sub _imgy_y {
  my $self = shift;
  my $y    = shift;
  return $self->height - ($self->bordery + $self->_scaley($y - $self->miny));
}

=head1 TODO

I'd like to add this capability into L<Chart> as a use base qw{Chart::Base}

=head1 BUGS

Log on RT and email the author

=head1 LIMITS

There are many packages on CPAN that create graphs and plots from data.  But, each one has it's own limitations.  This is the research that I did so that hopefully you won't have to...

=head2 Similar CPAN Packages

=head3 L<Chart::Plot>

This is the second best package that I could find on CPAN that supports scatter plots of X/Y data.  However, it does not supports a zero based Y-axis for positive data.  Otherwise this is a great package.

=head3 L<Chart>

This is a great package for its support of legends, layouts and labels but it only support equally spaced x axis data.

=head3 L<GD::Graph>

This is a great package for pie charts but for X/Y scatter plots it only supports equally spaced x axis data.

=head1 AUTHOR

Michael R. Davis qw/perl michaelrdavis com/

=head1 LICENSE

Copyright (c) 2009 Michael R. Davis (mrdvt92)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<GD::Graph::Cartesian>, L<GD>, L<Chart::Plot>, L<Chart>, L<GD::Graph>

=cut

1;
