#==========================================================================
#			   Copyright (c) 1995-1998 Martien Verbruggen
#        Modified for XY by George Fitch
#--------------------------------------------------------------------------
#
#	Name:
#		GD::Graph::xylines.pm
#
# $Id: points.pm,v 1.9 2000/04/30 08:32:38 mgjv Exp $
#
#==========================================================================

package GD::Graph::xylines;

$GD::Graph::xylines::VERSION = '$Revision: 1.10 $' =~ /\s([\d.]+)/;

use strict;
 
use GD;
use GD::Graph::axestype;
use GD::Graph::utils qw(:all);

@GD::Graph::xylines::ISA = qw( GD::Graph::axestype );

use constant PI => 4 * atan2(1,1);

my %Defaults = (
 
  #Pad things a bit to make them look nicer
	b_margin      => 5,
	r_margin      => 5,

  # We want long ticks by default
	x_long_ticks			=> 1,
	y_long_ticks			=> 1,
 
	# Number of ticks for the y axis
	y_tick_number		=> 10,
	x_tick_number		=> 13,		
	x_precision  		=> undef,	
 
	# Skip every nth label. if 1 will print every label on the axes,
	# if 2 will print every second, etc..
	x_label_skip		=> 1,
	y_label_skip		=> 1,

	# Do we want ticks on the x axis?
	x_ticks				=> 1,
	x_all_ticks			=> 0,

	# Where to place the x and y labels
	x_label_position	=> 1/2,
	y_label_position	=> 1/2,

	# vertical printing of x labels
	x_labels_vertical	=> 1,

	# Draw axes as a box? (otherwise just left and bottom)
	box_axis			=> 1,
 
);

sub initialise
{
	my $self = shift;

	$self->SUPER::initialise();

	while (my($key, $val) = each %Defaults) 
		{ $self->{$key} = $val }

	$self->set_x_label_font(GD::gdSmallFont);
	$self->set_y_label_font(GD::gdSmallFont);
	$self->set_x_axis_font(GD::gdTinyFont);
	$self->set_y_axis_font(GD::gdTinyFont);
	$self->set_legend_font(GD::gdTinyFont);
	$self->set_values_font(GD::gdTinyFont);
}

# PRIVATE
sub set_max_min 
{
  my $self = shift;

  my $x_max = undef;
  my $x_min = undef;
  my $y_max = undef;
  my $y_min = undef;
  
  for my $i ( 1 .. $self->{_data}->num_sets )	# 1 because x-labels are [0]
  {
    # Contributed by Andrew Crabb - ahc@sol.jhoc1.jhmi.edu
    my $num_points_limit = $self->{_data}->num_points - 1;
    for my $j ( 0 .. $num_points_limit )
    {
      my $val = $self->{_data}->[$i][$j];
      $y_max = $val if ((not defined($y_max)) or ($val > $y_max));
      $y_min = $val if ((not defined($y_min)) or ($val < $y_min));
    }
  }

  # Contributed by Andrew Crabb - ahc@sol.jhoc1.jhmi.edu
  my $num_points_limit = $self->{_data}->num_points - 1;
  for my $k ( 0 .. $num_points_limit ) # x-values are at [0]
  {
    my $val = $self->{_data}->[0][$k];
    $x_max = $val if ((not defined($x_max)) or ($val > $x_max));
    $x_min = $val if ((not defined($x_min)) or ($val < $x_min));
  }

  # Set the min and max's
	$self->{y_min}[1] = $y_min;
	$self->{y_max}[1] = $y_max;

	$self->{y_min}[2] = $y_min;
	$self->{y_max}[2] = $y_max;

	$self->{x_min} = $x_min;
	$self->{x_max} = $x_max;

  # Calculate the needed precision. 

  my $x_pre =  int(log(abs(($self->{x_max} - $self->{x_min}) / ($self->{x_tick_number} - 1) + $self->{x_min}))) + 1;

  $x_pre = $x_pre < 0 ? 0 : $x_pre;

	# Overwrite these with any user supplied ones
	$self->{y_min}[1] = $self->{y_min_value}  if defined $self->{y_min_value};
	$self->{y_max}[1] = $self->{y_max_value}  if defined $self->{y_max_value};

	$self->{y_min}[1] = $self->{y1_min_value} if defined $self->{y1_min_value};
	$self->{y_max}[1] = $self->{y1_max_value} if defined $self->{y1_max_value};

	$self->{y_min}[2] = $self->{y2_min_value} if defined $self->{y2_min_value};
	$self->{y_max}[2] = $self->{y2_max_value} if defined $self->{y2_max_value};

	$self->{x_min} = $self->{x_min_value}  if defined $self->{x_min_value};
	$self->{x_max} = $self->{x_max_value}  if defined $self->{x_max_value};

  $self->{true_x_min} = $self->{x_min};
  $self->{true_x_max} = $self->{x_max};

  $self->{true_y_min} = $self->{y_min}[1];
  $self->{true_y_max} = $self->{y_max}[1];

	$self->{x_tick_number} = 13 unless defined $self->{x_tick_number};
	$self->{y_tick_number} = 10 unless defined $self->{y_tick_number};

	$self->{x_precision} = $x_pre unless defined $self->{x_precision};

  return $self;

}	
 
sub setup_coords
{
	my $s = shift;

	# Do some sanity checks
	$s->{two_axes} = 0 if $s->{_data}->num_sets != 2 || $s->{two_axes} < 0;
	$s->{two_axes} = 1 if $s->{two_axes} > 1;

	delete $s->{y_label2} unless $s->{two_axes};

	# Set some heights for text
	$s->{tfh}  = 0 unless $s->{title};
	$s->{xlfh} = 0 unless $s->{x_label};

	# Make sure the y1 axis has a label if there is one set for y in
	# general
	$s->{y1_label} = $s->{y_label} if !$s->{y1_label} && $s->{y_label};

	# Set axis tick text heights and widths to 0 if they don't need to
	# be plotted.
	$s->{xafh} = 0, $s->{xafw} = 0 unless $s->{x_plot_values}; 
	$s->{yafh} = 0, $s->{yafw} = 0 unless $s->{y_plot_values};

	# Calculate minima and maxima for the axes
	$s->set_max_min() or return;

	# Create the labels for the axes, and calculate the max length
	$s->create_y_labels();
	$s->create_x_labels(); # CONTRIB Scott Prahl

	# Calculate the boundaries of the chart
	$s->_setup_boundaries() or return;

	# get the zero axis level
	(undef, $s->{zeropoint}) = $s->val_to_pixel(0, 0, 1);

	# More sanity checks
	$s->{x_label_skip} = 1 		if $s->{x_label_skip}  < 1;
	$s->{y_label_skip} = 1 		if $s->{y_label_skip}  < 1;
	$s->{y_tick_number} = 1		if $s->{y_tick_number} < 1;

	return $s;
}

#
# Ticks and values for x axes
#
sub draw_x_ticks_number
{

	my $self = shift;

	for (my $i = 0; $i < $self->{x_tick_number}; $i++) 
	{

    my $x_val = sprintf "%0.$self->{x_precision}f", $i * ($self->{x_max} - $self->{x_min}) / ($self->{x_tick_number} - 1) + $self->{x_min};

		my ($x, $y) = $self->val_to_pixel($x_val, 0, 1);

    if (defined $self->{x_number_format})
    {
      $x_val = ref $self->{x_number_format} eq 'CODE' ?
        &{$self->{x_number_format}}($x_val) :
        sprintf($self->{x_number_format}, $x_val);
    } 
    
		$y = $self->{bottom} unless $self->{zero_axis_only};

		# CONTRIB  Damon Brodie for x_tick_offset
		next if (!$self->{x_all_ticks} and 
				($i - $self->{x_tick_offset}) % $self->{x_label_skip} and 
				$i != $self->{_data}->num_points - 1 
			);

		if ($self->{x_ticks})
		{
			if ($self->{x_long_ticks})
			{
				$self->{graph}->line($x, $self->{bottom}, $x, $self->{top},
					$self->{fgci});
			}
			else
			{
				$self->{graph}->line($x, $y, $x, $y - $self->{x_tick_length},
					$self->{fgci});
			}
		}

		# CONTRIB Damon Brodie for x_tick_offset
		next if 
			($i - $self->{x_tick_offset}) % ($self->{x_label_skip}) and 
			$i != $self->{_data}->num_points - 1;

		$self->{gdta_x_axis}->set_text($x_val);

		my $yt = $y + $self->{axis_space};

		if ($self->{x_labels_vertical})
		{
			$self->{gdta_x_axis}->set_align('center', 'right');
			$self->{gdta_x_axis}->draw($x, $yt, PI/2);
		}
		else
		{
			$self->{gdta_x_axis}->set_align('top', 'center');
			$self->{gdta_x_axis}->draw($x, $yt);
		}
	}

	return $self;
}


sub draw_data_set
{
	my $self = shift;
	my $ds = shift;

	my @values = $self->{_data}->y_values($ds) or
		return $self->_set_error("Impossible illegal data set: $ds",
			$self->{_data}->error);

	# Pick a colour
	my $dsci = $self->set_clr($self->pick_data_clr($ds));

  my $xl = undef;
  my $yl = undef;

	for (my $i = 0; $i < @values; $i++)
	{
		next unless defined $values[$i];
		my ($xp, $yp) = $self->val_to_pixel(
			$self->{_data}->get_x($i), $values[$i], $ds);
		$self->draw_line($xl,$yl,$xp,$yp,1,$dsci) 
      if (defined $xl && defined $yl);

    $xl = $xp;
    $yl = $yp;

	}

	return $ds;
}

sub draw_line # ($xs, $ys, $xe, $ye, $type, $colour_index)
{
	my $self = shift;
	my ($xs, $ys, $xe, $ye, $type, $clr) = @_;

	my $lw = $self->{line_width};
	my $lts = $self->{line_type_scale};

	my $style = gdStyled;
	my @pattern = ();

	LINE: {

		($type == 2) && do {
			# dashed

			for (1 .. $lts) { push @pattern, $clr }
			for (1 .. $lts) { push @pattern, gdTransparent }

			$self->{graph}->setStyle(@pattern);

			last LINE;
		};

		($type == 3) && do {
			# dotted,

			for (1 .. 2) { push @pattern, $clr }
			for (1 .. 2) { push @pattern, gdTransparent }

			$self->{graph}->setStyle(@pattern);

			last LINE;
		};

		($type == 4) && do {
			# dashed and dotted

			for (1 .. $lts) { push @pattern, $clr }
			for (1 .. 2) 	{ push @pattern, gdTransparent }
			for (1 .. 2) 	{ push @pattern, $clr }
			for (1 .. 2) 	{ push @pattern, gdTransparent }

			$self->{graph}->setStyle(@pattern);

			last LINE;
		};

		# default: solid
		$style = $clr;
	}
	# Tried the line_width thing with setBrush, ugly results
	# TODO: This loop probably should be around the datasets 
	# for nicer results
	my $i;
	for $i (1..$lw)
	{
		my $yslw = $ys + int($lw/2) - $i;
		my $yelw = $ye + int($lw/2) - $i;

		# Need the setstyle to reset 
		$self->{graph}->setStyle(@pattern) if (@pattern);
		$self->{graph}->line( $xs, $yslw, $xe, $yelw, $style );
	}
}


#
# Convert value coordinates to pixel coordinates on the canvas.
#
sub val_to_pixel	# ($x, $y, $i) in real coords ($Dataspace), 
{						# return [x, y] in pixel coords
	my $self = shift;
	my ($x, $y, $i) = @_;

	my $x_min = $self->{x_min};
	my $x_max = $self->{x_max};

	my $x_step = abs(($self->{right} - $self->{left})/($x_max - $x_min));

	my $ret_x = $self->{left} + ($x - $x_min) * $x_step;

	my $y_min = ($self->{two_axes} && $i == 2) ? 
		$self->{y_min}[2] : $self->{y_min}[1];

	my $y_max = ($self->{two_axes} && $i == 2) ? 
		$self->{y_max}[2] : $self->{y_max}[1];

	my $y_step = abs(($self->{bottom} - $self->{top})/($y_max - $y_min));

	my $ret_y = $self->{bottom} - ($y - $y_min) * $y_step;

	return(_round($ret_x), _round($ret_y));
}


"Just another true value";

=head1 NAME

XYlines - XY plotting module for GD::Graph.

=head1 SYNOPSIS

use GD::Graph::xylines;

=head1 DESCRIPTION

B<xylines> is a I<perl5> module that uses GD::Graph, GD, 
to create and display PNG output for XY graphs with lines.

=head1 USAGE

See GD::Graph documentation for usage for all graphs.

=head1 METHODS AND FUNCTIONS

See GD::Graph documentation for methods for all GD::Graph graphs.

=head1 OPTIONS

=head2 Options for all graphs

See GD::Graph documentation for options for all graphs.

=head2 Options for graphs with axes

See GD::Graph documentation for options for graphs with axes.

=head1 CHANGE LOG

=head2 GDGraph-XY-0.92

B<x_number_format>

Added x_number_format functionality that mimics y_number_format
at the request of Ramon Acedo Rodriguez E<lt>rar@same-si.com<gt>

=head2 GDGraph-XY-0.91

B<Pass -w>

Thanks to some contributions by Andrew Crabb, ahc@sol.jhoc1.jhmi.edu,
the modules now pass the -w. Yes, they should have done this in the
first place, but I forgot. 

=head1 AUTHOR

Written by:  Martien Verbruggen E<lt>mgjv@comdyn.com.auE<gt>
Modified by: George 'Gaffer' Fitch E<lt>gaf3@gaf3.com<gt>

=head2 Copyright

GIFgraph: Copyright (c) 1995-1999 Martien Verbruggen.
Chart::PNGgraph: Copyright (c) 1999 Steve Bonds.
GD::Graph: Copyright (c) 1999 Martien Verbruggen.

All rights reserved. This package is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
