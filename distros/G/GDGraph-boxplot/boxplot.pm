#==========================================================================
#			   Copyright (c) 1999 Nigel Wright - 
#        Conversion from GIFGraph to GD::Graph
#        performed by George Fitch 2001.
#--------------------------------------------------------------------------
#
#	Name:
#		GD::Graph::boxplot.pm
#
#	Description: 
#		Module that extends GD::Graph capabilities to create 
#		box-and-whisker graphs.
#	
#==========================================================================
 
package GD::Graph::boxplot;

use strict;

use Statistics::Descriptive;
use GD::Graph::axestype;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours);

@GD::Graph::boxplot::ISA = qw(GD::Graph::axestype);
$GD::Graph::boxplot::VERSION = '1.00';

my %Defaults = (
	box_spacing 	=> 10,
	x_label_position	=> 1/2,
	r_margin		=> 25,

	# do_stats default value is 1, meaning raw data is used for each box.
	# the user can set it to 0, in which case they must put all data for each 
	# box in the following form: 
	# [mean, minimum, lower-pctile, median, upper-pctile, maximum]
	do_stats		=> 1,	

	# multiplied by the box height to determine the length of the whiskers
	step_const	=> 1.5,

	# the percentage used to determing the box top and bottom
	upper_percent	=> 75,
	lower_percent	=> 25,
	
	# number of steps between the edge of the box and the point 
	# defining outliers vs far-out-values
	fov_const	=> 1,	
	
	# produces a warning in case their are not enough pixels to properly
	# draw each box
	# set to 1 to turn the possibilty for warning on, 0 to turn it off 
	spacing_warning	=> 1,
	
	# used for setting proper x,y position of symbol characters
	symbol_font		=> undef,
	font_offset		=> undef,
	
	# allows the user to turn off all warnings in case they do not want to
	# receive print statements when using the program.  default value is 1.
	# 0 disables all warnings/suggestions
	warnings		=> 1,

	# set to 0 to draw only the box outlines and symbols 
	box_fill		=> 1,

	# sets the symbol color to be used
	# dblue is used as default to match the rest of GIFgraph defaults	
	symbolc		=> 'dblue'
);

sub initialise()
{
  my $self = shift;

  $self->SUPER::initialise();

  my $Defaults = join "\n", keys %Defaults;

  my $key;
  foreach $key (keys %Defaults)
  {
     $self->set( $key => $Defaults{$key} );

  }

  1;
}

# PRIVATE
sub _has_default { 
	my $self = shift;
	my $attr = shift || return;
	exists $Defaults{$attr} || $self->SUPER::_has_default($attr);
}

sub draw_data{

my $self = shift;

# redraw the 'zero' axis
  $self->{graph}->line( 
  $self->{left}, $self->{zeropoint}, 
  $self->{right}, $self->{zeropoint}, 
  $self->{fgci} );

  # add in the boxplots
  $self->SUPER::draw_data() or return;

}

# draws the boxplots
sub draw_data_set
{
  my $self = shift;
  my $ds = shift;
  my $box_s = _round($self->{box_spacing}/2);

  # Pick a fill colour for current data set
  my $dsci = $self->set_clr($self->pick_data_clr($ds));

  # symbol colour is set to the default value   
  my $medci = $self->set_clr(_rgb($self->{fgclr}));

  my @values = $self->{_data}->y_values($ds) or
    return $self->_set_error("Impossible illegal data set: $ds",
      $self->{_data}->error);

  for (my $i = 0; $i < @values; $i++) 
  {
    my $value = $values[$i];
    next unless defined $value;

    if ( $self->{do_stats} )
    { 
      next unless (defined $value->[0]); 
    }
    else
    {
      for my $j (0..5)
      { next unless (defined $value->[$j]); }
    }

    # variable declaration
    my ($stat, $upper, $medianv, $lower, $meanv, 
      $step, $minim, $maxim, $highest, $lowest);

    if ( $self->{do_stats} )
    {
      # used for simple statistical calculations
      $stat = Statistics::Descriptive::Full->new();

      # add all the data for each box 
      my $j;	# declaration required for comparison below
      for($j=0; defined $value->[$j]; $j++)
      {
        $stat->add_data($value->[$j]);				
      }

      # check for minimum number of data points within the 
      # current data set.  4 points are required for stats.
      if ($j < 4)
      {
        if ( $self->{warnings} )
        { 
          print "\nData set ", $i+1,
            " does not contain the ",
            "minimum of 4 data points.\n",
            "It has been left blank.\n";
        }
        next;
      }
      
      # get all the values needed for making the boxplot
      $upper = $stat->percentile( $self->{upper_percent} );
      $lower = $stat->percentile( $self->{lower_percent} );
      $meanv = $stat->mean();
      $medianv = $stat->median();
      $step = $self->{step_const}*($upper-$lower);

      #find max and min data points that are within one step
      if ($stat->max() < $upper+$step)
        { $maxim = $stat->max(); }
      else	{ $maxim = $upper+$step; }
    
      if ($stat->min() > $lower-$step)
        { $minim = $stat->min(); }
      else	{ $minim = $lower-$step; }
    } 
    else	#( !$self->{do_stats} )
    {
      # collect all the stats needed for making the boxplot
      $highest = $value->[5];
      $upper = $value->[4];
      $medianv = $value->[3];
      $lower = $value->[2];
      $lowest = $value->[1];
      $meanv = $value->[0];
      $step = $self->{step_const}*($upper-$lower);
      
      if ($highest < $upper+$step)
        { $maxim = $highest; }
      else 	{ $maxim = $upper+$step; }
    
      if ($lowest > $lower-$step)
        { $minim = $lowest; }
      else 	{ $minim = $lower-$step; }
    } # end of else

    my ($xp, $t, $max, $min, $mean, $median, $b);

    # get coordinates of top of box
    ($xp, $t) = $self->val_to_pixel($i+1, $upper, $ds);

    # max
    ($xp, $max) = $self->val_to_pixel($i+1, $maxim, $ds);

    # min
    ($xp, $min) = $self->val_to_pixel($i+1, $minim, $ds);

    # mean
    ($xp, $mean) = $self->val_to_pixel($i+1, $meanv, $ds);	

    # median
    ($xp, $median) = $self->val_to_pixel($i+1, $medianv, $ds);

    # calculate left and right of box
    my $l = $xp 
      - _round($self->{x_step}/2)
      + _round(($ds - 1) * $self->{x_step}/$self->{_data}->num_sets)
      + $box_s;
    my $r = $xp 
      - _round($self->{x_step}/2)
      + _round($ds * $self->{x_step}/$self->{_data}->num_sets)
      - $box_s;

    # bottom
    ($xp, $b) = $self->val_to_pixel($i+1, $lower, $ds);

    # set the center x location
    my $c = $l - _round( ($l-$r)/2 );

    # check to make sure the boxplots have enough pixels
    # to be properly displayed (else issue a warning)
    # only do so once for the entire program, 
    # and only if the user has not turned off the warning
    if ( 	$r-$l < 2 && $self->{spacing_warning} == 1 && $self->{warnings} )
    {			
      print "\nWarning: the image size may be too ",
        "small to display the boxplots.", 
        "\nSuggested Action: increase 'gifx' ",
        "or decrease 'box_spacing'.";
      $self->{spacing_warning} = 0;
    }

    # begin all the drawing

    # the box filling
    $self->{graph}->filledRectangle( $l, $t, $r, $b, $dsci) if ($self->{box_fill});

    # box outline
    $self->{graph}->rectangle( $l, $t, $r, $b, $medci );

    # upper line and whisker
    $self->{graph}->line($c, $t, $c, $max, $medci);
    $self->{graph}->line($l, $max, $r, $max, $medci);

    # lower line and whisker
    $self->{graph}->line($c, $b, $c, $min, $medci);
    $self->{graph}->line($l, $min, $r, $min, $medci);
          
    # draw the median horizontal line
    $self->{graph}->line($l, $median, $r, $median, $medci );

    # set the font to use for the '+', 'o', and '*' chars
  
    # check and only set the font the first time through
    # this avoids the case where the box size is on the 
    # boarder between two different fonts, resulting in 
    # different data sets being given different fonts
    # because of slight differences in pixel rounding.
    # also set all of the x and y off-set for each char
    # so their best center is at the correct (x,y) location

    unless ( $self->{symbol_font} )
    {
      if ($r-$l <= 20)
      {
        $self->{symbol_font} = GD::gdTinyFont;
        $self->{font_offset} = [2,3,1,4,1,3];
      }
      elsif ($r-$l <= 35)
      {
        $self->{symbol_font} = GD::gdSmallFont;
        $self->{font_offset} = [2,6,2,7,2,6];
      }
      else
      {
        $self->{symbol_font} = GD::gdLargeFont;
        $self->{font_offset} = [3,8,3,9,3,8];
      }
    }

    # set the font 			
    my $font = $self->{symbol_font};

    # set the offsets
    my ($plusx, $plusy, $ox, $oy, $asterx, $astery) =
      @{ $self->{font_offset} };
    
    # draw the mean using a character '+'
    $self->{graph}->string($font, $c-$plusx, $mean-$plusy, "+", $medci);
    
    # draw any outliers as an 'o' character (defined as points 
    # between 1 and fov_const steps from the nearest box boundary).
    # also draw far out points as "*" character (points more than 
    # fov_const steps from the nearest box boundary)
    if ( $self->{do_stats} )
    {
      # first check all the values above the box
      if ($stat->max() > $maxim)
      {
        for(my $j; defined $value->[$j]; $j++)
        {
          if ($value->[$j] > $maxim)
          {	 
            if( $value->[$j] <= 
              $maxim + 
              $self->{fov_const}*$step )
            # it is an outlier, so draw an 'o'
            {
              my($x, $y) = 
                $self->val_to_pixel(
                  $i+1, 
                  $value->[$j], 
                  $ds
                  );

              $self->{graph}->string($font, 
                  $c-$ox, $y-$oy,
                  "o", $medci
                  );
            }
            else	# it is a far-out value '*'
            {
              my($x, $y) = 
                $self->val_to_pixel(
                  $i+1,
                  $value->[$j],
                  $ds
                  );

              $self->{graph}->string( $font, 
                  $c-$asterx,	$y-$astery,
                  "*", $medci
                  );
            }
          }
        }
      }

      # now repeat the same procedure for values below the box	
      if ($stat->min() < $minim)
      {
        for (my $j; defined $value->[$j]; $j++)
        {
          if ($value->[$j] < $minim)
          {	 
            if( $value->[$j] >= 
              $minim - 
              $self->{fov_const}*$step )
            # it is an outlier, so draw an 'o'
            {
              my($x, $y) = $self->val_to_pixel(
                    $i+1,
                    $value->[$j],
                    $ds
                    );

              $self->{graph}->string( $font,
                  $c-$ox, $y-$oy,
                  "o", $medci
                  );
            }
            else	# it is a far-out value, draw '*'
            {
              my($x, $y) = $self->val_to_pixel(
                    $i+1,
                    $value->[$j],
                    $ds
                    );

              $self->{graph}->string($font,
                  $c-$asterx, $y-$astery,
                  "*", $medci
                  );
            }
          }
        }
      }
    } 
    else	# !$self->{do_stats}
    {
      # first check if the highest value is above the upper whisker
      if ($highest > $maxim)
      {
        if ( $highest <= $maxim + $self->{fov_const}*$step )
          # outlier, so draw an 'o'
        {
          my($x, $y) = 
            $self->val_to_pixel($i+1, $highest, $ds);

          $self->{graph}->string($font, $c-$ox, $y-$oy, "o", $medci);
        }
        else
          # far out value, so draw an '*'		
        {	
          my($x, $y) = 
            $self->val_to_pixel($i+1, $highest, $ds);

          $self->{graph}->string( $font, $c-$asterx, 
              $y-$astery, "*", $medci);
        }
      }
      # now check if the lowest value is below the lower whisker
      if ($lowest < $minim)
      {
        if ( $lowest >= $minim - $self->{fov_const}*$step )
          # outlier, so draw an 'o'
        {
          my($x, $y) = 
            $self->val_to_pixel($i+1, $lowest, $ds);

          $self->{graph}->string($font, $c-$ox, $y-$oy, "o", $medci);
        }
        else
          # far out value, so draw an '*'		
        {	
          my($x, $y) = 
            $self->val_to_pixel($i+1, $lowest, $ds);

          $self->{graph}->string( $font, $c-$asterx, 
              $y-$astery, "*", $medci);
        }
      }
    } #end of else
  } # end of for

return $ds;
}

# rewrite 'get_max_min_y_all' because, unlike the other graph types,
# boxplot takes arrays as data, rather than scalars.
# the min and max y are set just as in the other graph types,
# this just looks within each array, so as to compare all the scalars 
  
sub set_max_min 
{
  my $self = shift;

  my $max = undef;
  my $min = undef;
  
  if( $self->{do_stats} )
  {
    for my $i ( 1 .. $self->{_data}->num_sets )	# 1 because x-labels are [0]
    {
      for my $j ( 0 .. $self->{_data}->num_points )
      {
        for (my $k; defined $self->{_data}->[$i][$j][$k]; $k++ )
        {
          $max = $self->{_data}->[$i][$j][$k] 
            if ($self->{_data}->[$i][$j][$k] > $max);
          $min = $self->{_data}->[$i][$j][$k]
            if ($self->{_data}->[$i][$j][$k] < $min);		
        }
      }
    }
  }
  else	# !$s->{do_stats}
  {
    for my $i ( 1 .. $self->{_data}->num_sets )
    {
      for my $j ( 0 .. $self->{_data}->num_points )
      {
        $max = $self->{_data}->[$i][$j][5]
          if (!defined $max || $self->{_data}->[$i][$j][5] > $max);
        $min = $self->{_data}->[$i][$j][1]
          if (!defined $min || $self->{_data}->[$i][$j][1] < $min);
      }
    }
  }

  # the +3 and -3 are to make sure their is room enough to draw the 
  # entirety of the symbols on the graph, as they otherwise 
  # may overlap the graph boarder		
  $max += 3; 
  $min -= 3;

  $self->{y_min}[1] = $min - 3;
  $self->{y_max}[1] = $max + 3;

  # Overwrite these with any user supplied ones
  $self->{y_min}[1] = $self->{y_min_value} if defined $self->{y_min_value};
  $self->{y_max}[1] = $self->{y_max_value} if defined $self->{y_max_value};
  
  $self->{y_min}[1] = $self->{y1_min_value} if defined $self->{y1_min_value};
  $self->{y_max}[1] = $self->{y1_max_value} if defined $self->{y1_max_value};
  
  return $self;
}	
 
# End of package GD::Graph::boxplot

$GD::Graph::boxplot::VERSION
__END__

=head1 NAME

Boxplot - Box and Whisker Graph Module for Perl 5.

=head1 SYNOPSIS

use GD::Graph::boxplot;

=head1 DESCRIPTION

B<boxplot> is a I<perl5> module that uses GD::Graph, GD, and Statistics::Descriptive
to create and display PNG output for box and whisker graphs.

=head1 EXAMPLES

See the samples directory in the distribution.

=head1 USAGE

Fill an array of arrays with the x values and array references to the 
data sets to be used.  Make sure that every array has the same number 
of data sets as there are x values, otherwise I<GD:Graph> will complain 
and refuse to compile the graph.  For example:
	

	$one = [210..275];
	$two = [180, 190, 200, 220, 235, 245];
	$three = [40, 140..150, 160..180, 250];
	$four = [100..125, 136..140];
	$five = [10..50, 100, 180];

	@data = ( 
		["1st", "2nd", "3rd", "4th", "5th"],
		[$one, $two, $three, $four, $five ],
		[ [-25, 1..15], [-45, 25..45, 100], [70, 42..125], [undef], [180..250] ],
		# as many sets of data sets as you like 	
		);

If you don't have any data for a certain dataset, you can use B<undef> as 
shown above, and I<GD::Graph> will skip that box.

Create a new I<GG::Graph> object by calling the I<new> operator on the type
I<boxplot>:

	$my_graph = new GD::Graph::boxplot( );

Set the graph options: 

	$my_graph->set( 
		x_label           => 'X Label',
 		y_label           => 'Y label',
		title             => 'Some simple graph',
		upper_percent     => 70,
		lower_percent     => 35,
		step_const        => 1.8
		);

Output the graph:

    $gd = $my_graph->plot( \@data );

    open(IMG, '>box.png') or die $!;
    binmode IMG;
    print IMG $gd->png;

=head1 METHODS AND FUNCTIONS

See GD::Graph documentation for methods for all GD::Graph graphs.

=head1 OPTIONS

=head2 Options for all graphs

See GD::Graph documentation for options for all graphs.

=head2 Options for graphs with axes

Boxplot has axes, and has all of the options available to the
other graphs with axes: I<bars>, I<lines>, I<points>, I<linespoints>
and I<area>.  See the GD::Graph documentation for all of these options.

=head2 Options specific to Boxplot graphs

=over 4

=item do_stats, upper_percent, lower_percent

If I<do_stats> is a true value, the program assumes that raw data are used
for input.  It calculates the statistics for each box's data, and draws the box,
mean, median, upper and lower whiskers, outliers, and far-out-values 
accordingly.  The top and bottom of the box are determined by the numbers given
for upper_percent and lower_percent.  For example, if you wanted to have the box
contain all the data from the 20% to 80% range, you would use:

	$my_graph->set(
		lower_percent         => 20,
		upper_percent         => 80
		);

If I<do_stats> is set to 0, the program assumes that the user has already
calculated the required statistics for every box.  The user must input these
statistics in place of the raw data:

	# data must be in this form:
	# $data = [mean, lowest, lower-percentile, median, upper-precentile, highest];
	$one = [27, -35, 14, 29, 39, 52];
	$two = [41, -140, 29, 45, 62, 125];
	$three = [100, 30, 88, 95, 115, 155];
	$four = [80, -100, 60, 100, 110, 195];

	@data = ( 
		["1st", "2nd", "3rd", "4th"],
		[ $one, $two, $three, $four],
		# as many sets as you like, all with the required statistical data
		);
	
	$my_graph = new GD::Graph::boxplot();

	$my_graph->set(
		box_spacing       => 35,
		do_stats          => 0
		);

Notice that if do_stats is set to 0, upper_percent and lower_percent are not
used, because the user is able to input the actual value for the 
lower-percentile and upper-percetile.  Also notice that outliers and 
far-out-values are not drawn, because the program does not have the data points
to use.  However, the lowest or highest values can be drawn as outliers or 
far-out-values if they fall outside of the whiskers.

Default: do_stats = 1, upper_percent = 75, lower_percent = 25.

=item box_spacing

Number of pixels to leave open between boxes. This works well in most
cases, but on some platforms, a value of 1 will be rounded off to 0.

Default: box_spacing = 10

=item warnings

If set to 1, warnings are printed to the standard out when the user sets 
parameters to questionable values.  For example, if there are not enough
pixels to draw the boxes properly because there are too many data sets for 
the given image size, or because the box_spacing is set too high, then a 
warning is printed so the user is aware of the problem.  If set to 0, all
warnings are turned off.  This option is for users who do not want anything 
to be printed to the standard output.

Default: warnings = 1

=item step_const

Sets the step size equal to step_const box-heights, where the box-height is
the distance from the top of the box to the bottom.  The whiskers are then 
drawn one step from the top/bottom of the box, or to the largest/smallest data
value, whichever is closer to the box.  If there are values further than one 
step from the box, then the whiskers are drawn to one step from the box, and 
those values further than the whiskers are drawn as either outliers or 
far-out-values as explained below.  step_cont can be any number greater than 0.  

Default: step_const = 1.5   

=item fov_const

Sets the distance that will mark the boundary between outliers 
and far-out-values.  Outliers will be drawn between the whisker and fov_const
steps from the whisker.  Far-out-values will be drawn for values that fall
farther than fov_const steps from the whisker.  fov_const can be any number 
greater than 0.

Default: fov_const = 1

=item box_fill

When set to 1, the boxes are filled with the color for that data set.  When set to
0, only the symbols and the outlines of the boxes will be drawn.

Default: box_fill = 1 

=item symbolc

The color for drawing the symbols and box outlines.

Default: symbolc = 'dblue'

=back

=head1 NOTES

This module was designed to function in the same way as other GIFgraph graph types.
It has all of the same functionality (except for mixed graphs) as the other graphs.  
This functionality includes how to set the colors that fill the boxes (same as Bars),
change the size of the margins between the plot and the edge of the GIF, etc.  Please
read the GIFgraph documentation for the full set of options avaiable.

=head1 AUTHOR

Written by:             Nigel Wright.
Converted by:           George Fitch.

Design and Funding:     Mark Landry, Client/Server Architects, Inc.

=head2 Contact info 

email: nwright@hmc.edu - Nigel
       gaf3@gaf3.com - George

=head2 Copyright

Copyright (C) 1999 Nigel Wright.
All rights reserved.  This package is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut
