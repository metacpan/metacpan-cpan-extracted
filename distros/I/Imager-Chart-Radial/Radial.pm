package Radial;

use strict;
use vars qw($VERSION);

use Imager qw(init);

$VERSION = 0.1;

my %colours = (
	       black => Imager::Color->new("#000000"),
	       white => Imager::Color->new("#ffffff"),
	       grey  => Imager::Color->new("#9f9f9f"),
	       blue  => Imager::Color->new("#0707cc"),
	       red   => Imager::Color->new("#cc0707"),
	       green => Imager::Color->new("#07cc07"),
	       darkblue => Imager::Color->new("#0202bb"),
	       darkred  => Imager::Color->new("#bb0202"),
	       green    => Imager::Color->new("#02bb02"),
	      );

#-------------------------------------------------------------------------------
# set up new radial chart object

sub new {
  my $class = shift;
  my %arguments = @_;

  # instantiate Chart
  my $Chart = {};
  bless($Chart, ref($class) || $class);

  # initialise Chart
  $Chart->{_debug} = 1;
  $Chart->{PI} = 4 * atan2 1, 1;
  $Chart->{scale} = { style=>'notch', Max=>15, Divisions=>5 };

  # initialise image
  init();
  $Chart->{_image} = Imager->new(xsize=>400,ysize=>500,);
  $Chart->{_image}->box(color=>$colours{white},xmin=>0,ymin=>0,xmax=>400,ymax=>500,filled=>1);

  # use arguments if provided
  foreach my $arg (qw(axis colours fonts filename)) {
    $Chart->{$arg} = $arguments{$arg};
  }

  return $Chart;
}

sub plot_axis {
  my $self=shift;
  my $i = 0;
  my ($x_centre, $y_centre) = ( 200, 300 );
  foreach my $axis (@{$self->{axis}}) {
    my $proportion;
    my $theta;
    my $x;
    my $y;
    if ($i > 0) {
      $proportion = $i / scalar (@{$self->{axis}});
      $theta = (360 * $proportion) + 2;
      $axis->{theta} = $theta;
      $theta *= ((2 * $self->{PI}) / 360);
      $x = cos $theta - (2 * $theta);
      $y = sin $theta - (2 * $theta);
    } else {
      $x = 1;
      $y = 0;
      $axis->{theta} = 0;
    }
    my $x_outer = ($x * 100) + $x_centre;
    my $x_proportion =  ($x >= 0) ? $x : $x - (2 * $x) ;
    my $x_label = ($x_outer >= $x_centre) ?
      $x_outer + (0.9 * (14 * $x_proportion)) : $x_outer - ((length ( $axis->{Label} ) * 5) + (3 * $x_proportion));
    my $y_outer = ($y * 100) + $y_centre;
    my $y_proportion =  ($y >= 0) ? $y : $y - (2 * $y) ;
    my $y_label = ($y_outer >= $y_centre) ? $y_outer + 1.5 + (2 * $y_proportion) : $y_outer - (9 * $y_proportion);

    $axis->{X} = $x;
    $axis->{Y} = $y;

    # round down coords
    $x_outer =~ s/(\d+)\..*/$1/;
    $y_outer =~ s/(\d+)\..*/$1/;
    $x_label =~ s/(\d+)\..*/$1/;
    $y_label =~ s/(\d+)\..*/$1/;

    warn "drawing axis ..\n";
    # draw axis
    $self->{_image}->line(color=>$colours{black}, x1=>$x_outer,x2=>$x_centre,
			  y1=>$y_outer,y2=>$y_centre,antialias=>1);

    # add label for axis
    $self->{_image}->string( font  => $self->{fonts}{label}, text  => $axis->{Label},
			     x => $x_label, y => $y_label, size => 10 , color => $colours{darkblue},
			     aa => 1);
    $i++;
  }

  # loop through adding scale, and values

  my $r = 0;
  $i = 0;
  my %scale = %{$self->{scale}};
  foreach my $axis (@{$self->{axis}}) {
    my $x = $axis->{X};
    my $y = $axis->{Y};
    # draw scale
    my $theta1;
    my $theta2;
    if ($self->{scale}{style} eq "notch")  {
      $theta1 = $axis->{theta} + 90;
      $theta2 = $axis->{theta} - 90;
      # convert theta to radians
      $theta1 *= ((2 * $self->{PI}) / 360);
      $theta2 *= ((2 * $self->{PI}) / 360);
      for (my $j = 0 ; $j <= $scale{Max} ; $j+= int($scale{Max} / $scale{Divisions})) {
        next if ($j == 0);
        my $x_interval = $x_centre + ($x * (100 / $scale{Max}) * $j);
        my $y_interval = $y_centre + ($y * (100 / $scale{Max}) * $j);
        my $x1 = cos $theta1 - (2 *$theta1);
        my $y1 = sin $theta1 - (2 * $theta1);
        my $x2 = cos $theta2 - (2 *$theta2);
        my $y2 = sin $theta2 - (2 * $theta2);
        my $x1_outer = ($x1 * 3 * ($j / $scale{Max})) + $x_interval;
        my $y1_outer = ($y1 * 3 * ($j / $scale{Max})) + $y_interval;
        my $x2_outer = ($x2 * 3 * ($j / $scale{Max})) + $x_interval;
        my $y2_outer = ($y2 * 3 * ($j / $scale{Max})) + $y_interval;
	$self->{_image}->line(color=>$colours{grey}, x1=>$x1_outer,x2=>$x_interval,
			      y1=>$y1_outer,y2=>$y_interval,antialias=>1);
	$self->{_image}->line(color=>$colours{grey}, x1=>$x2_outer,x2=>$x_interval,
			      y1=>$y2_outer,y2=>$y_interval,antialias=>1);

        # Add Numbers to scale
        if ($i == 0) {
	  $self->{_image}->string( font  => $self->{fonts}{text}, text  => $j,
				   x => $x_interval , y => $y_interval , size => 10,
				   color => $colours{grey}, aa => 1);
	}
      }
    }
    if ($scale{style} eq "Polygon")  {
      for (my $j = 0 ; $j <= $scale{Max} ; $j+=($scale{Max} / $scale{Divisions})) {
        next if ($j == 0);
        my $x_interval_1 = $x_centre + ($x * (100 / $scale{Max}) * $j);
        my $y_interval_1= $y_centre + ($y * (100 / $scale{Max}) * $j);
        my $x_interval_2 = $x_centre + ($self->{axis}[$i-1]->{X} * (100 / $scale{Max}) * $j);
        my $y_interval_2= $y_centre + ($self->{axis}[$i-1]->{Y} * (100 / $scale{Max}) * $j);
        # Add Numbers to scale
        if ($i == 0) {
	  $self->{_image}->string( font  => $self->{fonts}{text}, text  => $j,
				   x => $x_interval_1 + 2, y => $y_interval_1 - 11, size => 10,
				   color => $colours{grey}, aa => 1);
        } else {
	  $self->{_image}->line(color=>$colours{grey}, x1=>$x_interval_1,x2=>$x_interval_2,
				y1=>$y_interval_1,y2=>$y_interval_2,antialias=>1);

          if ($i == scalar @{$self->{axis}} -1) {
            my $x_interval_2 = $x_centre + ($self->{axis}[0]->{X} * (100 / $scale{Max}) * $j);
            my $y_interval_2= $y_centre + ($self->{axis}[0]->{Y} * (100 / $scale{Max}) * $j);
	    $self->{_image}->line(color=>$colours{grey}, x1=>$x_interval_1,x2=>$x_interval_2,
				  y1=>$y_interval_1,y2=>$y_interval_2,antialias=>1);
          }
        }
      }
    }
    $i++;
  }
}

sub plot_values {
  my $self = shift;
  $self->{records} = shift;
  my $i = 0;
  my ($x_centre, $y_centre) = ( 200, 300 );
  my $r = 0;
  my %scale = %{$self->{scale}};
  foreach my $axis (@{$self->{axis}}) {
    my $proportion;
    my $theta;
    my $x;
    my $y;
    if ($i > 0) {
      $proportion = $i / scalar (@{$self->{axis}});
      $theta = (360 * $proportion) + 2;
      $axis->{theta} = $theta;
      $theta *= ((2 * $self->{PI}) / 360);
      $x = cos $theta - (2 * $theta);
      $y = sin $theta - (2 * $theta);
    } else {
      $axis->{theta} = 0;
      $theta = $axis->{theta};
      $x = 1;
      $y = 0;
    }
    my $x_outer = ($x * 100) + $x_centre;
    my $x_proportion =  ($x >= 0) ? $x : $x - (2 * $x) ;
    my $x_label = ($x_outer >= $x_centre) ?
      $x_outer + 3 : $x_outer - ((length ( $axis->{Label} ) * 5) + (3 * $x_proportion));
    my $y_outer = ($y * 100) + $y_centre;
    my $y_proportion =  ($y >= 0) ? $y : $y - (2 * $y) ;
    my $y_label = ($y_outer >= $y_centre) ? $y_outer + (3 * $y_proportion) : $y_outer - (9 * $y_proportion);

    $axis->{X} = $x;
    $axis->{Y} = $y;

    # round down coords
    $x_outer =~ s/(\d+)\..*/$1/;
    $y_outer =~ s/(\d+)\..*/$1/;
    $x_label =~ s/(\d+)\..*/$1/;
    $y_label =~ s/(\d+)\..*/$1/;
    # draw value
    if ($i != 0) {
      my $r = 0;
      foreach my $record (@{$self->{records}}) {
        my $value = $record->{Values}->{$axis->{Label}};
        my $last_value = $record->{Values}->{$self->{axis}[$i-1]->{Label}};
        my $colour = $colours{$record->{Colour}};
        my $x_interval_1 = $x_centre + ($x * (100 / $scale{Max}) * $value);
        my $y_interval_1= $y_centre + ($y * (100 / $scale{Max}) * $value);
        my $shape = $record->{Shape};
#        $self->draw_shape($x_interval_1,$y_interval_1,$record->{Colour}, $r);
        my $x_interval_2 = $x_centre + ($self->{axis}[$i-1]->{X} * (100 / $scale{Max}) * $last_value);
        my $y_interval_2= $y_centre + ($self->{axis}[$i-1]->{Y} * (100 / $scale{Max}) * $last_value);
	$self->{_image}->line(color=>$colour, x1=>$x_interval_1,x2=>$x_interval_2,
			      y1=>$y_interval_1,y2=>$y_interval_2,antialias=>1);

#        $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colour);
        if ($i == scalar @{$self->{axis}} -1) {
          my $first_value = $record->{Values}->{$self->{axis}[0]->{Label}};
          my $x_interval_2 = $x_centre + ($self->{axis}[0]->{X} * (100 / $scale{Max}) * $first_value);
          my $y_interval_2= $y_centre + ($self->{axis}[0]->{Y} * (100 / $scale{Max}) * $first_value);
	  $self->{_image}->line(color=>$colour, x1=>$x_interval_1,x2=>$x_interval_2,
				y1=>$y_interval_1,y2=>$y_interval_2,antialias=>1);
#          $self->{_im}->line($x_interval_1,$y_interval_1,$x_interval_2,$y_interval_2,$colour);
#          $self->draw_shape($x_interval_2,$y_interval_2,$record->{Colour}, $r);
        }
        $r++;
      }
    }
    $i++;
  }
  return;
}

sub add_title {
  my ($self,$title) = @_;
  if (length $title > 30) {
    $_ = $title;
    my ($part_a,$part_b) = m/^(.{25,35})\s+(.*)$/;
      $self->{_image}->string( font  => $self->{fonts}{header}, text  => $part_a,
			       x => 45, y => 50, color => $colours{black}, aa => 1);
      $self->{_image}->string( font  => $self->{fonts}{header}, text  => $part_b,
			       x => 45, y => 75, color => $colours{black}, aa => 1);
  } else {
    $self->{_image}->string( font  => $self->{fonts}{header}, text  => $title,
			     x => 50, y => 50, color => $colours{black}, aa => 1);
  }
  return;
}


sub add_legend {
  my $Chart = shift;
  my $starty = 490;
  my $endy = 470 - (scalar @{$Chart->{records}} * 18);
  $Chart->{_image}->box( color=>$colours{black},xmin=>45,ymin=>$endy,
			 xmax=>250,ymax=>$starty+2,filled=>0);
  $Chart->{_image}->string( font  => $Chart->{fonts}{label}, text  => "Legend :",
			    x => 50, y => $endy+19, color => $colours{black}, aa => 1);
  foreach my $record (@{$Chart->{records}}) {
    $Chart->{_image}->string( font  => $Chart->{fonts}{label}, 
			      text  => "$record->{Label} : $record->{Colour}",
			      x => 50, y => $starty, color => $colours{$record->{Colour}}, aa => 1);
    $starty-=18;
  }
}

sub print {
  my $Chart = shift;
  my $filename = shift || $Chart->{filename};
  $Chart->{_image}->write(file=>$filename)
    || warn "error: couldn't print chart ",$Chart->{_image}->{ERRSTR},"\n";
  return;
}


###########################################################################################

1;


###########################################################################################

=head1 NAME

Imager::Chart::Radial

=head1 SYNOPSIS

=item use Imager::Chart::Radial;

=item my $chart = Radial->new(axis => \@axis, fonts => \%fonts);

=item $chart->plot_axis();

=item $chart->plot_values( \@records );>

=item $chart->add_title("This is a chart, there are many like it but this is mine");>

=item $chart->add_legend();>

=item $chart->print('mychart.png');

=head1 DESCRIPTION

This module uses Imager to plot and output Radial or Radar charts.

=head1 ABOUT

I originally wrote a radial chart creator based on GD, but the GD library did not provide anti-aliasing and sufficient colours for a clean looking image until relatively recently. I wrote this version because I wanted to learn Imager and also provide some charting modules for Imager to make life easier when the GD library is not available.

=head1 USING

=head2 Creating a class

To create a new Radial object use the new method on the class

my $chart = Radial->new(axis => \@axis, fonts => \%fonts);

This requires two data structures, one for your axis and one for the fonts you wish to use:

 my %fonts = (
	     text => Imager::Font->new(file  => '/path/to/fonts/cour.ttf', size  => 8),
	     header => Imager::Font->new(file  => '/path/to/fonts/arial.ttf', size  => 18),
	     label => Imager::Font->new(file  => '/path/to/fonts/arial.ttf', size  => 14),
	    );

Fonts must be TrueType compatible fonts, for more information see Imager::Font.

 my @axis    = (
                { Label => "Reliability" },
		{ Label => "Ease of Use" },
		{ Label => "Information" },
		{ Label => "Layout" },
		{ Label => "Navigation" },
		{ Label => "Searching" },
	      );

The axis are labelled as above and provide the skeleton of the graph

=head2 Plotting the graph

$chart->plot_axis();

This plots the axis onto the chart

$chart->plot_values( \@records );

This plots the values themselves onto the chart using the records data structure as below :

 my @records = (
                     { Label => "Foo", Colour => "red", Values => {
                             "Reliability"=>5,"Ease of Use"=>3, "Response Speed"=>6,"Information"=>4,
                             "Layout"=>3,"Navigation"=>6,"Organisation"=>7,"Searching"=>8, },
                     },
                     { Label => "Bar", Colour => "blue", Values => {
                             "Reliability"=>9,"Ease of Use"=>8,"Response Speed"=>4,"Information"=>5,
                             "Layout"=>8,"Navigation"=>8,"Organisation"=>8,"Searching"=>7,
                             },
                     },
                     { Label => "Baz", Colour => "green", Values => {
                         "Reliability"=>7,"Ease of Use"=>2,"Response Speed"=>9,"Information"=>8,
                         "Layout"=>3,"Navigation"=>4,"Organisation"=>6,"Searching"=>3,
                         },
                    },
            );


=head2 Labelling the graph

You can add a title and a legend to the chart using add_title and add_legend

$chart->add_title("This is a radial chart using Imager and my own values");

The title should be short and uses the font specified as header in the fonts hash.

$chart->add_legend();

The legend is generated from the records, you must therefore plot the graph before adding the legend. The legend uses the label font.

=head2 Outputing the graph

To write out the graph just call the print method with the filename you wish to write to.

$chart->print('newchart.png');

=head1 SEE ALSO

Imager

Imager::Font

GD

GD::Graph

=head1 AUTHOR

Aaron J Trevena E<lt>F<aaron@droogs.org>E<gt>

=head1 COPYRIGHT

Copyright (C) 2003, Aaron Trevena

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.


=cut

###########################################################################################
###########################################################################################

