#####################################################################
# Radial - A module to generate radial charts as JPG and PNG images #
# (c) Copyright 2002,2004-2007 Aaron J  Trevena                     #
# (c) Copyright 2007-2013 Barbie                                    #
#####################################################################
package GD::Chart::Radial;

use strict;
use warnings;

use Data::Dumper;
use GD;

our $VERSION = '0.09';

=head1 NAME

GD::Chart::Radial - plot and output Radial or Radar charts using the GD library.

=head1 SYNOPSIS

  use GD::Chart::Radial;

  my $chart = GD::Chart::Radial->new($width, $height);
  $chart->set(title=>"This is a chart");
  $chart->plot(\@data);
  print OUTFILE $chart->png;

=head1 DESCRIPTION

This module allows you to plot and output Radial or Radar charts
using the GD library. The module is based on GD::Graph in how it
can be used where possible.

A radial chart has multiple axis spread out from the centre, like
spokes on a wheel. Each axis represents a particular measurement.
Values are plotted by marking the value for what is being measured
on each axis and optionally joining these points. The result can
look like a spiderweb or a radar depending on how you plot the
values.

=cut

my %COLOURS = (
    white      => [255,255,255],
    black      => [0,0,0],
    red        => [255,0,0],
    blue       => [0,0,255],
    purple     => [230,0,230],
    green      => [0,255,0],
    grey       => [128,128,128],
    light_grey => [170,170,170],
    dark_grey  => [75,75,75],
    cream      => [200,200,240],
    yellow     => [255,255,0],
    orange     => [255,128,0],
);

my %FONT = (
    1 => [5, gdSmallFont, gdTinyFont, gdTinyFont],
    2 => [10, gdMediumBoldFont, gdSmallFont, gdTinyFont],
    3 => [15, gdLargeFont, gdMediumBoldFont, gdSmallFont],
    4 => [20, gdGiantFont, gdLargeFont, gdMediumBoldFont],
    5 => [20, gdGiantFont, gdGiantFont, gdLargeFont],
    6 => [20, gdGiantFont, gdGiantFont, gdGiantFont],
);

my @FONT = sort keys %FONT;

=head1 METHODS

=head2 new

This constructor method creates a new chart object.

  my $chart = GD::Chart::Radial->new($width,$height);

=cut

sub new {
  my ($class, $width, $height, $debug) = (@_,0);

  # instantiate Chart
  my $chart = {};
  bless($chart, ref($class) || $class);

  # initialise Chart
  $chart->{width}  = $width;
  $chart->{height} = $height;
  $chart->{debug}  = $debug;
  $chart->{PI}     = 4 * atan2 1, 1;
  return $chart;
}

=head2 set

This accessor sets attributes of the graph such as the Title

  $chart->set(title=>"This is a chart");

or

  $chart->set(
        legend            => [qw/april may/],
        title             => 'Some simple graph',
        y_max_value       => $max,
        y_tick_number     => 5,
        style             => 'Notch',
        colours           => [qw/white black red blue green/],
       );

Style can be Notch, Circle, Polygon or Fill. The default style is Notch. Where
style is set to Fill, the data sets are also filled, as opposed to lines drawn
for all other styles

Colours can be any of the following: white, black, red, blue, purple, green,
grey, light_grey, dark_grey, cream, yellow, orange. The first colour is used
for the background colour, the second is used for the scale markings, while
the remaining colours represent the different data sets. If there are less
colours than data sets, colours will be taken from the unused set of defined
colours.

The default list of colours are white, black, red, blue and green, i.e. white
background, black scale markings and data sets in red blue and green.

Both legend and title can be undefined. If this is the case then the relavent
entry will not appear on the graph. This is useful if you plan to use other
forms of labelling along with the graph, and only require the image.

=cut

sub set {
  my $self = shift;
  my %attributes = @_;
  foreach my $attribute (%attributes) {
    next unless ($attributes{$attribute});
    $self->{$attribute} = $attributes{$attribute};
  }
}

=head2 plot

This method plots the chart based on the data provided and the attributes of
the graph.

  my @data = ([qw/A B C D E F G/],
              [12,21,23,30,23,22,5],
              [10,20,21,24,28,15,9]);
  $chart->plot(\@data);

=cut

sub plot {
  my $self = shift;
  return    unless(@_);

  my @values = @{shift()};
  my @labels = @{shift(@values)};
  my @records;

  if($self->{colours}) {
      for(@{$self->{colours}}) {
          next  unless(/^\#[a-f0-9]{3}([a-f0-9]{3})?$/i);
          my ($r,$g,$b);
          if(length($_) == 7) {
            my ($r,$g,$b) = (/^\#(..)(..)(..)$/);
            $COLOURS{$_} = [hex($r),hex($g),hex($b)];
          } else {
            my ($r,$g,$b) = (/^\#(.)(.)(.)$/);
            $COLOURS{$_} = [hex("$r$r"),hex("$g$g"),hex("$b$b")];
          }
      }

      # ensure we only have valid colours
      my @c = grep {$COLOURS{$_}} @{$self->{colours}};
      $self->{colours} = \@c;
  }

  my $BGColour  = $self->{colours} ? shift @{$self->{colours}} : 'white';
  my $FGColour  = $self->{colours} ? shift @{$self->{colours}} : 'black';
  my @DSColours = $self->{colours} ? @{$self->{colours}} : qw/red blue green yellow orange/;

  # try and avoid running out of colours
  my %AllColours = map {$_ => 1} keys %COLOURS;
  delete $AllColours{$_}   for($BGColour,$FGColour,@DSColours);
  push @DSColours, keys %AllColours;
  while(scalar(@labels) > scalar(@DSColours) || scalar(@values) > scalar(@DSColours)) {
    push @DSColours, @DSColours;
  }

#print STDERR "\n#Colours:";
#print STDERR "\n#Background=$BGColour";
#print STDERR "\n#Markings  =$FGColour";
#print STDERR "\n#Labels    =".(join(",",@DSColours));
#print STDERR "\n#Legends   =".(join(",",@{$self->{legend}}));
#print STDERR "\n";

#print STDERR "\n#Data:";
#print STDERR "\n#Labels=".(join(",",@labels));
#print STDERR "\n#Points=[".(join("][", map{join(",",@$_)} @values))."]";
#print STDERR "\n";

  my $Max = 0;
  my $r = 0;
  foreach my $values (@values) {
    my $record = { Colour => $DSColours[$r] };
    $record->{Label} = $self->{legend}->[$r]    if($self->{legend});
    my $v = 0;
    foreach my $value (@$values) {
      $record->{Values}->{$labels[$v]} = $value;
      $Max = $value if($Max < $value);
      $v++;
    }
    push(@records,$record);
    $r++;
  }

  $self->{records} = \@records;
  $self->{y_max_value}   ||= $Max;
  $self->{y_tick_number} ||= $Max;

  my $PI = $self->{PI};

  # style can be Fill, Circle, Polygon or Notch
  my %scale = (
           Max       => $self->{y_max_value},
           Divisions => $self->{y_tick_number},
           Style     => $self->{style} || "Notch",
           Colour    => $FGColour
          );

  # calculate image dimensions
  my (@axis, %axis_lookup);
  my $longest_axis_label = 0;
  my $a = 0;
  foreach my $key (@labels) {
    push (@axis, { Label => "$key" });
    $axis_lookup{$key} = $a;
    $longest_axis_label = length $key
      if (length $key > $longest_axis_label);
    $a++;
  }

  my $number_of_axis = scalar @axis;
  my $legend_height = 0;

  if($self->{legend}) {
      $legend_height = 8 + (15 * scalar @{$self->{records}});
  }

  my $left_space    = 15 + $longest_axis_label * 6;
  my $right_space   = 15 + $longest_axis_label * 6;
  my $top_space     = $self->{title} ? 50 : 15;
  my $bottom_space  = $self->{legend} ? 30 + $legend_height : 15;

  unless($self->{width})  { $self->{width}  = 200 + $left_space + $right_space; }
  unless($self->{height}) { $self->{height} = 200 + $top_space + $bottom_space; }

  my $x_radius = int(($self->{width}  - $left_space - $right_space) / 2);
  my $y_radius = int(($self->{height} - $top_space - $bottom_space) / 2);
  my $min_radius = 100;

  $x_radius = $min_radius   if($x_radius < $min_radius);
  $y_radius = $min_radius   if($y_radius < $min_radius);
  $x_radius = $y_radius     if($x_radius > $y_radius);
  $y_radius = $x_radius     if($y_radius > $x_radius);

  $top_space += _font_offset($x_radius);

  my $x_centre  = $left_space + $x_radius;
  my $y_centre  = $top_space + $y_radius;
  my $height    = (2 * $y_radius) + $bottom_space + $top_space;
  my $width     = (2 * $x_radius) + $left_space + $right_space;

#print STDERR "\n#width=$width, height=$height\n"  if($self->{debug});
  $self->{_im} = GD::Image->new($width,$height);

  # define the colours and fonts
  my %colours = map {$_ => $self->{_im}->colorAllocate(@{$COLOURS{$_}})} ($BGColour,$FGColour,@DSColours);
  $self->{fonts}   = {
      Title  => _font_size(1,$x_radius),
      Label  => _font_size(2,$x_radius),
      Legend => _font_size(3,$x_radius)
  };

  my (@Axis,@Label,@Notch);
  my $Theta = 90;
  my $i = $number_of_axis;
  foreach my $axis (@axis) {
    my ($proportion,$theta,$x,$y);

    if ($i > 0) {
      $proportion = $i / $number_of_axis;
      $theta = ((360 * $proportion) + $Theta) % 360;
      $axis->{theta} = $theta;
      $theta *= ((2 * $PI) / 360);
    } else {
      $axis->{theta} = $Theta;
      $theta = $Theta;
    }
    $x = cos $theta - (2 * $theta);
    $y = sin $theta - (2 * $theta);

    my $x_outer = ($x * $x_radius) + $x_centre;
    my $x_proportion =  ($x >= 0) ? $x : $x - (2 * $x) ;
    my $x_label = ($x_outer >= $x_centre)
                    ? $x_outer + 3
                    : $x_outer - ((length ( $axis->{Label} ) * 5) + (3 * $x_proportion));
    my $y_outer = ($y * $y_radius) + $y_centre;
    my $y_proportion =  ($y >= 0) ? $y : $y - (2 * $y) ;
    my $y_label = ($y_outer >= $y_centre)
                    ? $y_outer + (3 * $y_proportion)
                    : $y_outer - (9 * $y_proportion);

    $axis->{X} = $x;
    $axis->{Y} = $y;

    # round down coords
    $x_outer =~ s/(\d+)\..*/$1/;
    $y_outer =~ s/(\d+)\..*/$1/;
    $x_label =~ s/(\d+)\..*/$1/;
    $y_label =~ s/(\d+)\..*/$1/;

    # top label needs to be slightly offset to avoid the scale marking
    $y_label -= _font_offset($x_radius)  if($i == $number_of_axis);

    # draw axis and label
    if ($scale{Style} eq "Fill")  {
        push @Axis, [$x_outer, $y_outer, $x_centre, $y_centre, $colours{$scale{Colour}}];
        push @Label, [$x_label, $y_label, $axis->{Label}, $colours{$scale{Colour}}];
    } else {
        $self->{_im}->line($x_outer, $y_outer, $x_centre, $y_centre, $colours{$scale{Colour}});
        $self->{_im}->string($self->{fonts}->{Label}, $x_label, $y_label, $axis->{Label}, $colours{$scale{Colour}});
    }
    $i--;
  }

  # loop through adding scale, and values
  $r = 0;
  $i = 0;
  foreach my $axis (@axis) {
    my $x = $axis->{X};
    my $y = $axis->{Y};
    # draw scale
    my $theta1;
    my $theta2;
    if ($scale{Style} eq "Notch" || $scale{Style} eq "Fill")  {
      $theta1 = $axis->{theta} + 90;
      $theta2 = $axis->{theta} - 90;
      # convert theta to radians
      $theta1 *= ((2 * $PI) / 360);
      $theta2 *= ((2 * $PI) / 360);
      for (my $j = 0 ; $j <= $scale{Max} ; $j+=int($scale{Max} / $scale{Divisions})) {
        my $x_interval = $x_centre + ($x * ($x_radius / $scale{Max}) * $j);
        my $y_interval = $y_centre + ($y * ($y_radius / $scale{Max}) * $j);
        my $x1 = cos $theta1 - (2 * $theta1);
        my $y1 = sin $theta1 - (2 * $theta1);
        my $x2 = cos $theta2 - (2 * $theta2);
        my $y2 = sin $theta2 - (2 * $theta2);
        my $x1_outer = ($x1 * 3 * ($j / $scale{Max})) + $x_interval;
        my $y1_outer = ($y1 * 3 * ($j / $scale{Max})) + $y_interval;
        my $x2_outer = ($x2 * 3 * ($j / $scale{Max})) + $x_interval;
        my $y2_outer = ($y2 * 3 * ($j / $scale{Max})) + $y_interval;

        if($scale{Style} eq "Fill") {
          push @Notch, [$x1_outer,$y1_outer,$x_interval,$y_interval,$colours{$scale{Colour}}];
          push @Notch, [$x2_outer,$y2_outer,$x_interval,$y_interval,$colours{$scale{Colour}}];
        } else {
          $self->{_im}->line($x1_outer,$y1_outer,$x_interval,$y_interval,$colours{$scale{Colour}});
          $self->{_im}->line($x2_outer,$y2_outer,$x_interval,$y_interval,$colours{$scale{Colour}});
        }
      }
    }

    if ($scale{Style} eq "Polygon" || $scale{Style} eq "Fill")  {
      for (my $j = 0 ; $j <= $scale{Max} ; $j+=int($scale{Max} / $scale{Divisions})) {
        my $x_interval_1 = $x_centre + ($x * ($x_radius / $scale{Max}) * $j);
        my $y_interval_1 = $y_centre + ($y * ($y_radius / $scale{Max}) * $j);
        my $x_interval_2 = $x_centre + ($axis[$i-1]->{X} * ($x_radius / $scale{Max}) * $j);
        my $y_interval_2 = $y_centre + ($axis[$i-1]->{Y} * ($y_radius / $scale{Max}) * $j);

        if ($i > 0) {
          next if ($j == 0);
          $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colours{$scale{Colour}});
          if ($i == $number_of_axis -1) {
            my $x_interval_2 = $x_centre + ($axis[0]->{X} * ($x_radius / $scale{Max}) * $j);
            my $y_interval_2 = $y_centre + ($axis[0]->{Y} * ($y_radius / $scale{Max}) * $j);
            $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colours{$scale{Colour}});
          }
        }
      }
    }

    if ($scale{Style} eq "Circle")  {
      for (my $j = 0 ; $j <= $scale{Max} ; $j+=int($scale{Max} / $scale{Divisions})) {
        if ($i > 0) {
          next if ($j == 0);
          my $radius = (($y_radius * 2) / $scale{Max}) * $j;
          $self->{_im}->arc($x_centre,$y_centre,$radius,$radius,$axis[0]->{theta}-2,$axis[$i-1]->{theta}-2,$colours{$scale{Colour}});
          $self->{_im}->arc($x_centre,$y_centre,$radius,$radius,$axis[$i]->{theta}-2,$axis[0]->{theta}-2,$colours{$scale{Colour}});
        }
      }
    }

    # draw graph points
    if ($i != 0) {
      my $r = 0;
      foreach my $record (@{$self->{records}}) {
        my $value = $record->{Values}->{$axis->{Label}};
        my $colour = $colours{$record->{Colour}};
        $value ||= 0;
#print STDERR "Max=[$scale{Max}], value=[$value]"    if($self->{debug});
        my $x_interval_1 = $x_centre + ($x * ($x_radius / $scale{Max}) * $value);
        my $y_interval_1 = $y_centre + ($y * ($y_radius / $scale{Max}) * $value);

        if ($scale{Style} eq "Fill")  {
          push @{$record->{Points}}, [$x_interval_1,$y_interval_1];
          if ($i == $number_of_axis -1) {
            my $first_value  = $record->{Values}->{$axis[0]->{Label}};
            my $x_interval_2 = $x_centre + ($axis[0]->{X} * ($x_radius / $scale{Max}) * $first_value);
            my $y_interval_2 = $y_centre + ($axis[0]->{Y} * ($y_radius / $scale{Max}) * $first_value);
            push @{$record->{Points}}, [$x_interval_2,$y_interval_2];
          }
        } else {
          $self->draw_shape($x_interval_1,$y_interval_1,$colours{$record->{Colour}}, $r);

          my $last_value = $record->{Values}->{$axis[$i-1]->{Label}};
          my $x_interval_2 = $x_centre + ($axis[$i-1]->{X} * ($x_radius / $scale{Max}) * $last_value);
          my $y_interval_2 = $y_centre + ($axis[$i-1]->{Y} * ($y_radius / $scale{Max}) * $last_value);
          $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colour);

          if ($i == $number_of_axis -1) {
            my $first_value  = $record->{Values}->{$axis[0]->{Label}};
            my $x_interval_2 = $x_centre + ($axis[0]->{X} * ($x_radius / $scale{Max}) * $first_value);
            my $y_interval_2 = $y_centre + ($axis[0]->{Y} * ($y_radius / $scale{Max}) * $first_value);
            $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colour);
            $self->draw_shape($x_interval_2,$y_interval_2,$colours{$record->{Colour}}, $r);
          }
          $r++;
        }
      }
    }
    $i++;
  }

  # Fill is a filled polgon
  if ($scale{Style} eq "Fill")  {
    foreach my $record (@{$self->{records}}) {
      my $poly = GD::Polygon->new();
      $poly->addPt($_->[0],$_->[1]) for(@{$record->{Points}});
      $self->{_im}->filledPolygon($poly,$colours{$record->{Colour}});
    }

    $self->{_im}->line(@$_)                             for(@Axis,@Notch);
    $self->{_im}->string($self->{fonts}->{Label},@$_)   for(@Label);
  }

  # draw scale values
  my $x = $axis[0]->{X};
  my $y = $axis[0]->{Y};
  for (my $j = 0 ; $j <= $scale{Max} ; $j+=int($scale{Max} / $scale{Divisions})) {
    my $x_interval_1 = $x_centre + ($x * ($x_radius / $scale{Max}) * $j);
    my $y_interval_1= $y_centre + ($y * ($y_radius / $scale{Max}) * $j);
    $self->{_im}->string($self->{fonts}->{Legend}, $x_interval_1 + 2,$y_interval_1 - 4,$j,$colours{$scale{Colour}});
  }

  # draw Legend
  if($self->{legend}) {
    my $longest_legend = 0;
    foreach my $record (@{$self->{records}}) {
      $longest_legend = length $record->{Label}
        if ( $record->{Label} && length $record->{Label} > $longest_legend );
    }
    my ($legendX, $legendY) = (
           ($width / 2) - (6 * (length "Legend") / 2) - ($x_radius * 0.75),
           ($height - ($legend_height + 20))
    );
    $self->{_im}->string($self->{fonts}->{Legend},$legendX,$legendY,"Legend",$colours{$scale{Colour}});
    my $legendX2 = $legendX - (($longest_legend * 5) + 2);
    $legendY += 15;
    $r = 0;

    foreach my $record (@{$self->{records}}) {
      $self->{_im}->string($self->{fonts}->{Label},$legendX2,$legendY,$record->{Label},$colours{$record->{Colour}})  if($record->{Label});
      $self->{_im}->line($legendX+10,$legendY+4,$legendX + 35,$legendY+4,$colours{$record->{Colour}});
      $self->draw_shape($legendX+22,$legendY+4,$colours{$record->{Colour}},$r);
      $legendY += 15;
      $r++;
    }
  }

  # draw title
  if($self->{title}) {
      my ($titleX, $titleY) = ( ($width / 2) - (6 * (length $self->{title}) / 2),20);
      $self->{_im}->string($self->{fonts}->{Title},$titleX,$titleY,$self->{title},$colours{$scale{Colour}});
  }
  return 1;
}

=head2 png

returns a PNG image for output to a file or wherever.

  open(IMG, '>test.png') or die $!;
  binmode IMG;
  print IMG $chart->png;
  close IMG

=cut

sub png {
  my $self = shift;
  return    unless($self->{_im}->can('png'));
  return $self->{_im}->png();
}

=head2 jpg

returns a JPEG image for output to a file or elsewhere, see png.

=cut

sub jpg {
  my $self = shift;
  return    unless($self->{_im}->can('jpeg'));
  return $self->{_im}->jpeg(95);
}

=head2 gif

returns a GIF image for output to a file or elsewhere, see png.

=cut

sub gif {
  my $self = shift;
  return    unless($self->{_im}->can('gif'));
  return $self->{_im}->gif();
}

=head2 gd

returns a GD image for output to a file or elsewhere, see png.

=cut

sub gd {
  my $self = shift;
  return    unless($self->{_im}->can('gd'));
  return $self->{_im}->gd();
}

##########################################################

=head2 Internal Methods

In order to draw the points on the chart, the following 6 shape drawing
functions are used:

=over 4

=item draw_shape

=item draw_diamond

=item draw_square

=item draw_circle

=item draw_triangle

=item draw_cross

=back

=cut

sub draw_shape {
    my ($self,$x,$y,$colour,$i) = @_;
    my $shape;
    if (exists $self->{records}->[$i]->{Shape} ) {
        $shape = $self->{records}->[$i]->{Shape};
    } else {
        $shape = ($i > 4) ? int ($i % 5)  : $i ;
        $self->{records}->[$i]->{Shape} = $shape;
    }

    if ($shape == 0) {
        $self->draw_diamond($x,$y,$colour);
        return 1;
    }
    if ($shape == 1) {
        $self->draw_square($x,$y,$colour);
        return 1;
    }
    if ($shape == 2) {
        $self->draw_circle($x,$y,$colour);
        return 1;
    }
    if ($shape == 3) {
        $self->draw_triangle($x,$y,$colour);
        return 1;
    }
    if ($shape == 4) {
        $self->draw_cross($x,$y,$colour);
        return 1;
    }
}

sub draw_diamond {
    my ($self,$x,$y,$colour) = @_;
    $x-=3;
    my $poly = new GD::Polygon;
    $poly->addPt($x,$y);
    $poly->addPt($x+3,$y-3);
    $poly->addPt($x+6,$y);
    $poly->addPt($x+3,$y+3);
    $poly->addPt($x,$y);
    $self->{_im}->filledPolygon($poly,$colour);
    return 1;
}

sub draw_square {
    my ($self,$x,$y,$colour) = @_;
    $x-=3;
    $y-=3;
    my $poly = new GD::Polygon;
    $poly->addPt($x,$y);
    $poly->addPt($x+6,$y);
    $poly->addPt($x+6,$y+6);
    $poly->addPt($x,$y+6);
    $poly->addPt($x,$y);
    $self->{_im}->filledPolygon($poly,$colour);
    return 1;
}

sub draw_circle {
    my ($self,$x,$y,$colour) = @_;
    $self->{_im}->arc($x,$y,7,7,0,360,$colour);
    $self->{_im}->fillToBorder($x,$y,$colour,$colour);
    return 1;
}

sub draw_triangle {
    my ($self,$x,$y,$colour) = @_;
    $x-=3;
    $y+=3;
    my $poly = new GD::Polygon;
    $poly->addPt($x,$y);
    $poly->addPt($x+3,$y-6);
    $poly->addPt($x+6,$y);
    $poly->addPt($x,$y);
    $self->{_im}->filledPolygon($poly,$colour);
    return 1;
}

sub draw_cross {
    my ($self,$x,$y,$colour) = @_;
    $self->{_im}->line($x-3,$y,$x+3,$y,$colour);
    $self->{_im}->line($x,$y-3,$x,$y+3,$colour);
    return 1;
}

sub _font_size {
    my $scale  = shift || 1;
    my $radius = int((shift || $FONT[0]) / 100 );
    $radius = $FONT[0]  if($radius < $FONT[0]);
    $radius = $FONT[-1] if($radius > $FONT[-1]);

    return $FONT{$radius}->[$scale];
}

sub _font_offset {
    my $radius = int((shift || $FONT[0]) / 100 );

    return $FONT{$radius}->[0];
}

1;
__END__

=head1 TODO

=over 4

=item * Allow long labels to run on multiple lines.

=back

=head1 SEE ALSO

L<GD>,
L<GD::Graph>,
L<Imager::Chart::Radial>

=head1 AUTHOR

  Original Author: Aaron J Trevena <aaron@droogs.org>
  Current Maintainer: Barbie <barbie@missbarbell.co.uk>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002,2004-2007 Aaron Trevena
  Copyright (C) 2007-2014 Barbie

  This distribution is free software; you can redistribute it or modify it
  under the same terms as Perl itself.

=cut
