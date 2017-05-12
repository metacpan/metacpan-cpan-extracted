#==========================================================================
#			   Copyright (c) 1999 Nigel Wright
#--------------------------------------------------------------------------
#
#	Name:
#		GIFgraph::boxplot.pm
#
#	Description: 
#		Module that extends GIFgraph capabilities to create 
#		box-and-whisker graphs.
#	
#==========================================================================
 
package GIFgraph::boxplot;

use strict qw(vars refs subs);
use Statistics::Descriptive;
use GIFgraph::axestype;
use GIFgraph::utils qw(:all);

die "\nERROR: GIFgraph must be version 1.10 or greater.\n" 
	unless ($GIFgraph::VERSION ge '1.10');

@GIFgraph::boxplot::ISA = qw( GIFgraph::axestype );
$GIFgraph::boxplot::VERSION = '1.00';

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
	symbolc		=> 'dblue',
);

{
	sub initialise()
	{
		my $self = shift;

		$self->SUPER::initialise();

		my $key;
		foreach $key (keys %Defaults)
		{
			$self->set( $key => $Defaults{$key} );
		}
	}
	
	# PRIVATE
	sub draw_data{

		my $s = shift;
		my $g = shift;
		my $d = shift;

		# draw the 'zero' axis
		$g->line( 
			$s->{left}, $s->{zeropoint}, 
			$s->{right}, $s->{zeropoint}, 
			$s->{fgci} );

		# add in the boxplots
		$s->SUPER::draw_data($g, $d);
	}
 
	# draws the boxplots
	sub draw_data_set($$$)
	{
		my $s = shift;
		my $g = shift;
		my $d = shift;
		my $ds = shift;
		my $box_s = _round($s->{box_spacing}/2);

		# Pick a fill colour for current data set
		my $dsci = $s->set_clr( $g, $s->pick_data_clr($ds) );

		# symbol colour is set to the default value   
		my $medci =  $s->set_clr( $g, GIFgraph::_rgb($s->{symbolc}) );

		for my $i (0 .. $s->{numpoints}) 
		{			
			if ( $s->{do_stats} )
			{ 
				next unless (defined $d->[$i][0]); 
			}
			else
			{
				for my $j (0..5)
				{ next unless (defined $d->[$i][$j]); }
			}

			# variable declaration
			my ($stat, $upper, $medianv, $lower, $meanv, 
				$step, $minim, $maxim, $highest, $lowest);
	
			if ( $s->{do_stats} )
			{
				# used for simple statistical calculations
				$stat = Statistics::Descriptive::Full->new();

				# add all the data for each box 
				my $j;	# declaration required for comparison below
				for($j=0; defined $d->[$i][$j]; $j++)
				{
					$stat->add_data($d->[$i][$j]);				
				}
	
				# check for minimum number of data points within the 
				# current data set.  4 points are required for stats.
				if ($j < 4)
				{
					if ( $s->{warnings} )
					{ 
						print "\nData set ", $i+1,
							" does not contain the ",
							"minimum of 4 data points.\n",
							"It has been left blank.\n";
					}
					next;
				}
				
				# get all the values needed for making the boxplot
				$upper = $stat->percentile( $s->{upper_percent} );
				$lower = $stat->percentile( $s->{lower_percent} );
				$meanv = $stat->mean();
				$medianv = $stat->median();
				$step = $s->{step_const}*($upper-$lower);

				#find max and min data points that are within one step
				if ($stat->max() < $upper+$step)
					{ $maxim = $stat->max(); }
				else	{ $maxim = $upper+$step; }
			
				if ($stat->min() > $lower-$step)
					{ $minim = $stat->min(); }
				else	{ $minim = $lower-$step; }
			} 
			else	#( !$s->{do_stats} )
			{
				# collect all the stats needed for making the boxplot
				$highest = $d->[$i][5];
				$upper = $d->[$i][4];
				$medianv = $d->[$i][3];
				$lower = $d->[$i][2];
				$lowest = $d->[$i][1];
				$meanv = $d->[$i][0];
				$step = $s->{step_const}*($upper-$lower);
				
				if ($highest < $upper+$step)
					{ $maxim = $highest; }
				else 	{ $maxim = $upper+$step; }
			
				if ($lowest > $lower-$step)
					{ $minim = $lowest; }
				else 	{ $minim = $lower-$step; }
			} # end of else

			my ($xp, $t, $max, $min, $mean, $median, $b);

			# get coordinates of top of box
			($xp, $t) = $s->val_to_pixel($i+1, $upper, $ds);

			# max
			($xp, $max) = $s->val_to_pixel($i+1, $maxim, $ds);

			# min
			($xp, $min) = $s->val_to_pixel($i+1, $minim, $ds);

			# mean
			($xp, $mean) = $s->val_to_pixel($i+1, $meanv, $ds);	

			# median
			($xp, $median) = $s->val_to_pixel($i+1, $medianv, $ds);

			# calculate left and right of box
			my $l = $xp 
				- _round($s->{x_step}/2)
				+ _round(($ds - 1) * $s->{x_step}/$s->{numsets})
				+ $box_s;
			my $r = $xp 
				- _round($s->{x_step}/2)
				+ _round($ds * $s->{x_step}/$s->{numsets})
				- $box_s;

			# bottom
			($xp, $b) = $s->val_to_pixel($i+1, $lower, $ds);
	
			# set the center x location
			my $c = $l - _round( ($l-$r)/2 );

			# check to make sure the boxplots have enough pixels
			# to be properly displayed (else issue a warning)
			# only do so once for the entire program, 
			# and only if the user has not turned off the warning
			if ( 	$r-$l < 2 && $s->{spacing_warning} == 1 && $s->{warnings} )
			{			
				print "\nWarning: the image size may be too ",
					"small to display the boxplots.", 
					"\nSuggested Action: increase 'gifx' ",
					"or decrease 'box_spacing'.";
				$s->{spacing_warning} = 0;
			}

			# begin all the drawing

			# the box filling
			$g->filledRectangle( $l, $t, $r, $b, $dsci) if ($s->{box_fill});

			# box outline
			$g->rectangle( $l, $t, $r, $b, $medci );

			# upper line and whisker
			$g->line($c, $t, $c, $max, $medci);
			$g->line($l, $max, $r, $max, $medci);

			# lower line and whisker
			$g->line($c, $b, $c, $min, $medci);
			$g->line($l, $min, $r, $min, $medci);
						
			# draw the median horizontal line
			$g->line($l, $median, $r, $median, $medci );

			# set the font to use for the '+', 'o', and '*' chars
		
			# check and only set the font the first time through
			# this avoids the case where the box size is on the 
			# boarder between two different fonts, resulting in 
			# different data sets being given different fonts
			# because of slight differences in pixel rounding.
			# also set all of the x and y off-set for each char
			# so their best center is at the correct (x,y) location

			unless ( $s->{symbol_font} )
			{
				if ($r-$l <= 20)
				{
					$s->{symbol_font} = GD::gdTinyFont;
					$s->{font_offset} = [2,3,1,4,1,3];
				}
				elsif ($r-$l <= 35)
				{
					$s->{symbol_font} = GD::gdSmallFont;
					$s->{font_offset} = [2,6,2,7,2,6];
				}
				else
				{
					$s->{symbol_font} = GD::gdLargeFont;
					$s->{font_offset} = [3,8,3,9,3,8];
				}
			}

			# set the font 			
			my $font = $s->{symbol_font};

			# set the offsets
			my ($plusx, $plusy, $ox, $oy, $asterx, $astery) =
				@{ $s->{font_offset} };
			
			# draw the mean using a character '+'
			$g->string($font, $c-$plusx, $mean-$plusy, "+", $medci);
			
			# draw any outliers as an 'o' character (defined as points 
			# between 1 and fov_const steps from the nearest box boundary).
			# also draw far out points as "*" character (points more than 
			# fov_const steps from the nearest box boundary)
			if ( $s->{do_stats} )
			{
				# first check all the values above the box
				if ($stat->max() > $maxim)
				{
					for(my $j; defined $d->[$i][$j]; $j++)
					{
						if ($d->[$i][$j] > $maxim)
						{	 
							if( $d->[$i][$j] <= 
								$maxim + 
								$s->{fov_const}*$step )
							# it is an outlier, so draw an 'o'
							{
								my($x, $y) = 
									$s->val_to_pixel(
										$i+1, 
										$d->[$i][$j], 
										$ds
										);
	
								$g->string($font, 
										$c-$ox, $y-$oy,
										"o", $medci
										);
							}
							else	# it is a far-out value '*'
							{
								my($x, $y) = 
									$s->val_to_pixel(
										$i+1,
										$d->[$i][$j],
										$ds
										);

								$g->string( $font, 
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
					for (my $j; defined $d->[$i][$j]; $j++)
					{
						if ($d->[$i][$j] < $minim)
						{	 
							if( $d->[$i][$j] >= 
								$minim - 
								$s->{fov_const}*$step )
							# it is an outlier, so draw an 'o'
							{
								my($x, $y) = $s->val_to_pixel(
											$i+1,
											$d->[$i][$j],
											$ds
											);

								$g->string( $font,
										$c-$ox, $y-$oy,
										"o", $medci
										);
							}
							else	# it is a far-out value, draw '*'
							{
								my($x, $y) = $s->val_to_pixel(
											$i+1,
											$d->[$i][$j],
											$ds
											);
	
								$g->string($font,
										$c-$asterx, $y-$astery,
										"*", $medci
										);
							}
						}
					}
				}
			} 
			else	# !$s->{do_stats}
			{
				# first check if the highest value is above the upper whisker
				if ($highest > $maxim)
				{
					if ( $highest <= $maxim + $s->{fov_const}*$step )
						# outlier, so draw an 'o'
					{
						my($x, $y) = 
							$s->val_to_pixel($i+1, $highest, $ds);
	
						$g->string($font, $c-$ox, $y-$oy, "o", $medci);
					}
					else
						# far out value, so draw an '*'		
					{	
						my($x, $y) = 
							$s->val_to_pixel($i+1, $highest, $ds);

						$g->string( $font, $c-$asterx, 
								$y-$astery, "*", $medci);
					}
				}
				# now check if the lowest value is below the lower whisker
				if ($lowest < $minim)
				{
					if ( $lowest >= $minim - $s->{fov_const}*$step )
						# outlier, so draw an 'o'
					{
						my($x, $y) = 
							$s->val_to_pixel($i+1, $lowest, $ds);
	
						$g->string($font, $c-$ox, $y-$oy, "o", $medci);
					}
					else
						# far out value, so draw an '*'		
					{	
						my($x, $y) = 
							$s->val_to_pixel($i+1, $lowest, $ds);

						$g->string( $font, $c-$asterx, 
								$y-$astery, "*", $medci);
					}
				}
			} #end of else
		} # end of for
	}

	# rewrite 'get_max_min_y_all' because, unlike the other graph types,
	# boxplot takes arrays as data, rather than scalars.
	# the min and max y are set just as in the other graph types,
	# this just looks within each array, so as to compare all the scalars 
		
	sub get_max_min_y_all($) # \@data
	{
		my $s = shift;
		my $d = shift;

		my $max = undef;
		my $min = undef;
		
		if( $s->{do_stats} )
		{
			for my $i ( 1 .. $s->{numsets} )	# 1 because x-labels are [0]
			{
				for my $j ( 0 .. $s->{numpoints} )
				{
					for (my $k; defined $d->[$i][$j][$k]; $k++ )
					{
						$max = $d->[$i][$j][$k] 
							if ($d->[$i][$j][$k] > $max);
						$min = $d->[$i][$j][$k]
							if ($d->[$i][$j][$k] < $min);		
					}
				}
			}
		}
		else	# !$s->{do_stats}
		{
			for my $i ( 1 .. $s->{numsets} )
			{
				for my $j ( 0 .. $s->{numpoints} )
				{
					$max = $d->[$i][$j][5]
						if (!defined $max || $d->[$i][$j][5] > $max);
					$min = $d->[$i][$j][1]
						if (!defined $min || $d->[$i][$j][1] < $min);
				}
			}
		}

		# the +3 and -3 are to make sure their is room enough to draw the 
		# entirety of the symbols on the graph, as they otherwise 
		# may overlap the graph boarder		
		return ($max+3, $min-3);
	}	
 
} # End of package GIFgraph::boxplot
1;		

__END__

=head1 NAME

Boxplot - Box and Whisker Graph Module for Perl 5.

=head1 SYNOPSIS

use GIFgraph::boxplot;

=head1 DESCRIPTION

B<boxplot> is a I<perl5> module that uses GIFgraph, GD, and Statistics::Descriptive
to create and display GIF output for box and whisker graphs.

=head1 EXAMPLES

See the samples directory in the distribution.

=head1 USAGE

Fill an array of arrays with the x values and array references to the 
data sets to be used.  Make sure that every array has the same number 
of data sets as there are x values, otherwise I<GIFgraph> will complain 
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
shown above, and I<GIFgraph> will skip that box.

Create a new I<GIFgraph> object by calling the I<new> operator on the type
I<boxplot>:

	$my_graph = new GIFgraph::boxplot( );

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

    $my_graph->plot_to_gif( "sample01.gif", \@data );

=head1 METHODS AND FUNCTIONS

See GIFgraph documentation for methods for all GIFgraph graphs.

=head1 OPTIONS

=head2 Options for all graphs

See GIFgraph documentation for options for all graphs.

=head2 Options for graphs with axes

Boxplot has axes, and has all of the options available to the
other graphs with axes: I<bars>, I<lines>, I<points>, I<linespoints>
and I<area>.  See the GIFgraph documentation for all of these options.

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
	
	$my_graph = new GIFgraph::boxplot();

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

Design and Funding:     Mark Landry, Client/Server Architects, Inc.

=head2 Contact info 

email: nwright@hmc.edu

=head2 Copyright

Copyright (C) 1999 Nigel Wright.
All rights reserved.  This package is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself.

=cut
