#==========================================================================
# Module: GD::Graph::axestype3d
#
# Copyright (C) 1999,2001 Wadsack-Allen. All Rights Reserved.
#
# Based on axestype.pm,v 1.21 2000/04/15 08:59:36 mgjv
#          Copyright (c) 1995-1998 Martien Verbruggen
#
#--------------------------------------------------------------------------
# Date		Modification				                                 Author
# -------------------------------------------------------------------------
# 1999SEP18 Created 3D axestype base class (this                         JW
#           module) changes noted in comments.
# 1999OCT15 Fixed to include all GIFgraph functions                      JW
#           necessary for PNG support.
# 2000JAN19 Converted to GD::Graph sublcass                              JW
# 2000FEB21 Fixed bug in y-labels' height                                JW
# 2000APR18 Updated for compatibility with GD::Graph 1.30                JW
# 2000AUG21 Added 3d shading                                             JW
# 2000SEP04 Allowed box_clr without box axis                             JW
# 06Dec2001 Fixed bug in rendering of x tick when x_tick_number is set   JW
#==========================================================================
# TODO
#		* Modify to use true 3-d extrusions at any theta and phi
#==========================================================================
package GD::Graph::axestype3d;

use strict;
 
use GD::Graph;
use GD::Graph::axestype;
use GD::Graph::utils qw(:all);
use GD::Graph::colour qw(:colours);
use Carp;

@GD::Graph::axestype3d::ISA = qw(GD::Graph::axestype);
$GD::Graph::axestype3d::VERSION = '0.63';

# Commented inheritance from GD::Graph::axestype unless otherwise noted.

use constant PI => 4 * atan2(1,1);

my %Defaults = (
	depth_3d           => 20,
	'3d_shading'       => 1,

	# the rest are inherited
);

# Inherit _has_default 


# Can't inherit initialise, because %Defaults is referenced file-
# specific, not class specific.
sub initialise
{
	my $self = shift;

	my $rc = $self->SUPER::initialise();

	while( my($key, $val) = each %Defaults ) { 
		$self->{$key} = $val 
	} # end while

	return $rc;
} # end initialise

# PUBLIC
# Inherit plot
# Inherit set
# Inherit setup_text
# Inherit set_x_label_font
# Inherit set_y_label_font
# Inherit set_x_axis_font
# Inherit set_y_axis_font
# Inherit set_legend
# Inherit set_legend_font



# ----------------------------------------------------------
# Sub: init_graph
#
# Args: (None)
#
# Description: 
# Override GD::Graph::init_graph to add 3d shading colors, 
# if requested
#
# [From GD::Graph]
# Initialise the graph output canvas, setting colours (and 
# getting back index numbers for them) setting the graph to 
# transparent, and interlaced, putting a logo (if defined) 
# on there.
# ----------------------------------------------------------
# Date      Modification                              Author
# ----------------------------------------------------------
# 20Aug2000 Added to support 3d graph extensions          JW
# ----------------------------------------------------------
sub init_graph {
	my $self = shift;

	# Sets up the canvas and color palette
	$self->SUPER::init_graph( @_ );	

	# Now create highlights and showdows for each color
	# in the palette
	if( $self->{'3d_shading'} ) {
		$self->{'3d_highlights'} = [];
		$self->{'3d_shadows'} = [];
		$self->{'3d_highlights'}[$self->{bgci}] = $self->set_clr( $self->_brighten( _rgb($self->{bgclr}) ) );
		$self->{'3d_shadows'}[$self->{bgci}]    = $self->set_clr( $self->_darken( _rgb($self->{bgclr}) ) );

		$self->{'3d_highlights'}[$self->{fgci}] = $self->set_clr( $self->_brighten( _rgb($self->{fgclr}) ) );
		$self->{'3d_shadows'}[$self->{fgci}]    = $self->set_clr( $self->_darken( _rgb($self->{fgclr}) ) );

		$self->{'3d_highlights'}[$self->{tci}] = $self->set_clr( $self->_brighten( _rgb($self->{textclr}) ) );
		$self->{'3d_shadows'}[$self->{tci}]    = $self->set_clr( $self->_darken( _rgb($self->{textclr}) ) );

		$self->{'3d_highlights'}[$self->{lci}] = $self->set_clr( $self->_brighten( _rgb($self->{labelclr}) ) );
		$self->{'3d_shadows'}[$self->{lci}]    = $self->set_clr( $self->_darken( _rgb($self->{labelclr}) ) );

		$self->{'3d_highlights'}[$self->{alci}] = $self->set_clr( $self->_brighten( _rgb($self->{axislabelclr}) ) );
		$self->{'3d_shadows'}[$self->{alci}]    = $self->set_clr( $self->_darken( _rgb($self->{axislabelclr}) ) );

		$self->{'3d_highlights'}[$self->{acci}] = $self->set_clr( $self->_brighten( _rgb($self->{accentclr}) ) );
		$self->{'3d_shadows'}[$self->{acci}]    = $self->set_clr( $self->_darken( _rgb($self->{accentclr}) ) );

		$self->{'3d_highlights'}[$self->{valuesci}] = $self->set_clr( $self->_brighten( _rgb($self->{valuesclr}) ) );
		$self->{'3d_shadows'}[$self->{valuesci}]    = $self->set_clr( $self->_darken( _rgb($self->{valuesclr}) ) );

		$self->{'3d_highlights'}[$self->{legendci}] = $self->set_clr( $self->_brighten( _rgb($self->{legendclr}) ) );
		$self->{'3d_shadows'}[$self->{legendci}]    = $self->set_clr( $self->_darken( _rgb($self->{legendclr}) ) );

		if( $self->{boxclr} ) {
			$self->{'3d_highlights'}[$self->{boxci}] = $self->set_clr( $self->_brighten( _rgb($self->{boxclr}) ) );
			$self->{'3d_shadows'}[$self->{boxci}]    = $self->set_clr( $self->_darken( _rgb($self->{boxclr}) ) );
		} # end if
	} # end if

	return $self;
} # end init_graph


# PRIVATE

# ----------------------------------------------------------
# Sub: _brighten
#
# Args: $r, $g, $b
#	$r, $g, $b	The Red, Green, and Blue components of a color
#
# Description: Brightens the color by adding white
# ----------------------------------------------------------
# Date      Modification                              Author
# ----------------------------------------------------------
# 21AUG2000 Created to build 3d highlights table          JW
# ----------------------------------------------------------
sub _brighten {
	my $self = shift;
	my( $r, $g, $b ) = @_;
	my $p = ($r + $g + $b) / 70;
	$p = 3 if $p < 3;
	my $f = _max( $r / $p, _max( $g / $p, $b / $p ) );
	$r = _min( 255, int( $r + $f ) );
	$g = _min( 255, int( $g + $f ) );
	$b = _min( 255, int( $b + $f ) );
	return( $r, $g, $b );
} # end _brighten

# ----------------------------------------------------------
# Sub: _darken
#
# Args: $r, $g, $b
#	$r, $g, $b	The Red, Green, and Blue components of a color
#
# Description: Darkens the color by adding black
# ----------------------------------------------------------
# Date      Modification                              Author
# ----------------------------------------------------------
# 21AUG2000 Created to build 3d shadows table          JW
# ----------------------------------------------------------
sub _darken {
	my $self = shift;
	my( $r, $g, $b ) = @_;
	my $p = ($r + $g + $b) / 70;
	$p = 3 if $p < 3;
	my $f = _max( $r / $p, _max( $g / $p, $b / $p) );
	$r = _max( 0, int( $r - $f ) );
	$g = _max( 0, int( $g - $f ) );
	$b = _max( 0, int( $b - $f ) );
	return( $r, $g, $b );
} # end _darken


# inherit check_data from GD::Graph

# [JAW] Setup boundaries as parent, the adjust for 3d extrusion
sub _setup_boundaries
{
	my $self = shift;

	$self->SUPER::_setup_boundaries();

	# adjust for top of 3-d extrusion
	$self->{top} += $self->{depth_3d};

	return $self->_set_error('Vertical size too small')
		if $self->{bottom} <= $self->{top};
	
	# adjust for right of 3-d extrusion
	$self->{right} -= $self->{depth_3d};

	return $self->_set_error('Horizontal size too small')	
		if $self->{right} <= $self->{left};

	return $self;
} # end _setup_boundaries

# [JAW] Determine 3d-extrusion depth, then call parent
sub setup_coords
{
	my $self = shift;

	# Calculate the 3d-depth of the graph
	# Note this sets a minimum depth of ~20 pixels
#	if (!defined $self->{x_tick_number}) {
		my $depth = _max( $self->{bar_depth}, $self->{line_depth} );
		if( $self->{overwrite} == 1 ) {
			$depth *= $self->{_data}->num_sets();
		} # end if
	   $self->{depth_3d} = _max( $depth, $self->{depth_3d} );
#	} # end if

	$self->SUPER::setup_coords();

	return $self;
} # end setup_coords

# Inherit create_y_labels
# Inherit get_x_axis_label_height
# Inherit create_x_labels
# inherit open_graph from GD::Graph
# Inherit draw_text

# [JAW] Draws entire bounding cube for 3-d extrusion
sub draw_axes
{
	my $s = shift;
	my $g = $s->{graph};

	my ($l, $r, $b, $t) = 
		( $s->{left}, $s->{right}, $s->{bottom}, $s->{top} );
	my $depth = $s->{depth_3d};

	if ( $s->{box_axis} ) {
		# -- Draw a bounding box
		if( $s->{boxci} ) {
			# -- Fill the box with color
			# Back box
			$g->filledRectangle($l+$depth+1, $t-$depth+1, $r+$depth-1, $b-$depth-1, $s->{boxci});

			# Left side
			my $poly = new GD::Polygon;
			$poly->addPt( $l, $t );
			$poly->addPt( $l + $depth, $t - $depth );
			$poly->addPt( $l + $depth, $b - $depth );
			$poly->addPt( $l, $b );
			if( $s->{'3d_shading'} ) {
				$g->filledPolygon( $poly, $s->{'3d_shadows'}[$s->{boxci}] );
			} else {
				$g->filledPolygon( $poly, $s->{boxci} );
			} # end if

			# Bottom
			$poly = new GD::Polygon;
			$poly->addPt( $l, $b );
			$poly->addPt( $l + $depth, $b - $depth );
			$poly->addPt( $r + $depth, $b - $depth );
			$poly->addPt( $r, $b );
			if( $s->{'3d_shading'} ) {
				$g->filledPolygon( $poly, $s->{'3d_highlights'}[$s->{boxci}] );
			} else {
				$g->filledPolygon( $poly, $s->{boxci} );
			} # end if
		} # end if

		# -- Draw the box frame
		
		# Back box
		$g->rectangle($l+$depth, $t-$depth, $r+$depth, $b-$depth, $s->{fgci});
		
		# Connecting frame
		$g->line($l, $t, $l + $depth, $t - $depth, $s->{fgci});
		$g->line($r, $t, $r + $depth, $t - $depth, $s->{fgci});
		$g->line($l, $b, $l + $depth, $b - $depth, $s->{fgci});
		$g->line($r, $b, $r + $depth, $b - $depth, $s->{fgci});

		# Front box
		$g->rectangle($l, $t, $r, $b, $s->{fgci});

	} else {
		if( $s->{boxci} ) {
			# -- Fill the background box with color
			# Back box
			$g->filledRectangle($l+$depth+1, $t-$depth+1, $r+$depth-1, $b-$depth-1, $s->{boxci});

			# Left side
			my $poly = new GD::Polygon;
			$poly->addPt( $l, $t );
			$poly->addPt( $l + $depth, $t - $depth );
			$poly->addPt( $l + $depth, $b - $depth );
			$poly->addPt( $l, $b );
			if( $s->{'3d_shading'} ) {
				$g->filledPolygon( $poly, $s->{'3d_shadows'}[$s->{boxci}] );
			} else {
				$g->filledPolygon( $poly, $s->{boxci} );
			} # end if

			# Bottom
			$poly = new GD::Polygon;
			$poly->addPt( $l, $b );
			$poly->addPt( $l + $depth, $b - $depth );
			$poly->addPt( $r + $depth, $b - $depth );
			$poly->addPt( $r, $b );
			if( $s->{'3d_shading'} ) {
				$g->filledPolygon( $poly, $s->{'3d_highlights'}[$s->{boxci}] );
			} else {
				$g->filledPolygon( $poly, $s->{boxci} );
			} # end if
		} # end if
		# -- Draw the frame only for back & sides
		
		# Back box
		$g->rectangle($l + $depth, $t - $depth, $r + $depth, $b - $depth, $s->{fgci});

		# Y axis
		my $poly = new GD::Polygon;
		$poly->addPt( $l, $t );
		$poly->addPt( $l, $b );
		$poly->addPt( $l + $depth, $b - $depth );
		$poly->addPt( $l + $depth, $t - $depth );
		$g->polygon( $poly, $s->{fgci} );
		
		# X axis
		if( !$s->{zero_axis_only} ) {
			$poly = new GD::Polygon;
			$poly->addPt( $l, $b );
			$poly->addPt( $r, $b );
			$poly->addPt( $r + $depth, $b - $depth );
			$poly->addPt( $l + $depth, $b - $depth );
			$g->polygon( $poly, $s->{fgci} );
		} # end if
		
		# Second Y axis
		if( $s->{two_axes} ){
			$poly = new GD::Polygon;
			$poly->addPt( $r, $b );
			$poly->addPt( $r, $t );
			$poly->addPt( $r + $depth, $t - $depth );
			$poly->addPt( $r + $depth, $b - $depth );
			$g->polygon( $poly, $s->{fgci} );
		} # end if
	} # end if

	# Zero axis
	if ($s->{zero_axis} or $s->{zero_axis_only})	{
		my ($x, $y) = $s->val_to_pixel(0, 0, 1);
		my $poly = new GD::Polygon;
		$poly->addPt( $l, $y );
		$poly->addPt( $r, $y );
		$poly->addPt( $r + $depth, $y - $depth );
		$poly->addPt( $l + $depth, $y - $depth);
		$g->polygon( $poly, $s->{fgci} );
	} # end if
	
} # end draw_axes

# [JAW] Draws ticks and values for y axes in 3d extrusion
# Modified from MVERB source
sub draw_y_ticks
{
	my $self = shift;

	for my $t (0 .. $self->{y_tick_number}) 
	{
		for my $a (1 .. ($self->{two_axes} + 1)) 
		{
			my $value = $self->{y_values}[$a][$t];
			my $label = $self->{y_labels}[$a][$t];
			
			my ($x, $y) = $self->val_to_pixel(0, $value, $a);
			$x = ($a == 1) ? $self->{left} : $self->{right};

			# CONTRIB Jeremy Wadsack
			# Draw on the back of the extrusion
			$x += $self->{depth_3d};
			$y -= $self->{depth_3d};

			if ($self->{y_long_ticks}) 
			{
				$self->{graph}->line( 
					$x, $y, 
					$x + $self->{right} - $self->{left}, $y, 
					$self->{fgci} 
				) unless ($a-1);
				# CONTRIB Jeremy Wadsack
				# Draw conector ticks
				$self->{graph}->line( $x - $self->{depth_3d}, 
				                      $y + $self->{depth_3d},
				                      $x, 
				                      $y, 
				                      $self->{fgci} 
				) unless ($a-1);
			} 
			else 
			{
				$self->{graph}->line( 
					$x, $y, 
					$x + (3 - 2 * $a) * $self->{y_tick_length}, $y, 
					$self->{fgci} 
				);
				# CONTRIB Jeremy Wadsack
				# Draw conector ticks
				$self->{graph}->line( $x - $self->{depth_3d}, 
				                      $y + $self->{depth_3d},
				                      $x - $self->{depth_3d} + (3 - 2 * $a) * $self->{y_tick_length}, 
				                      $y + $self->{depth_3d} - (3 - 2 * $a) * $self->{y_tick_length},
				                      $self->{fgci} 
				);
			}

			next 
				if $t % ($self->{y_label_skip}) || ! $self->{y_plot_values};

			$self->{gdta_y_axis}->set_text($label);
			$self->{gdta_y_axis}->set_align('center', 
				$a == 1 ? 'right' : 'left');
			$x -= (3 - 2 * $a) * $self->{axis_space};
			
			# CONTRIB Jeremy Wadsack
			# Subtract 3-d extrusion width from left axis label
			# (it was added for ticks)
			$x -= (2 - $a) * $self->{depth_3d};

			# CONTRIB Jeremy Wadsack
			# Add 3-d extrusion height to label
			# (it was subtracted for ticks)
			$y += $self->{depth_3d};

			$self->{gdta_y_axis}->draw($x, $y);
			
		} # end foreach
	} # end foreach

	return $self;

} # end draw_y_ticks

# [JAW] Darws ticks and values for x axes wih 3d extrusion
# Modified from MVERB source
sub draw_x_ticks
{
	my $self = shift;

	for (my $i = 0; $i < $self->{_data}->num_points; $i++) 
	{
		my ($x, $y) = $self->val_to_pixel($i + 1, 0, 1);

		$y = $self->{bottom} unless $self->{zero_axis_only};

		# CONTRIB  Damon Brodie for x_tick_offset
		next if (!$self->{x_all_ticks} and 
				($i - $self->{x_tick_offset}) % $self->{x_label_skip} and 
				$i != $self->{_data}->num_points - 1 
			);

		# CONTRIB Jeremy Wadsack
		# Draw on the back of the extrusion
		$x += $self->{depth_3d};
		$y -= $self->{depth_3d};

		if ($self->{x_ticks})
		{
			if ($self->{x_long_ticks})
			{
				# CONTRIB Jeremy Wadsack
				# Move up by 3d depth
				$self->{graph}->line( $x, 
				                      $self->{bottom} - $self->{depth_3d}, 
				                      $x, 
				                      $self->{top} - $self->{depth_3d},
				                      $self->{fgci});
				# CONTRIB Jeremy Wadsack
				# Draw conector ticks
				$self->{graph}->line( $x - $self->{depth_3d}, 
				                      $y + $self->{depth_3d},
				                      $x, 
				                      $y, 
				                      $self->{fgci} 
				);
			}
			else
			{
				$self->{graph}->line( $x, $y, $x, $y - $self->{x_tick_length}, $self->{fgci} );
				# CONTRIB Jeremy Wadsack
				# Draw conector ticks
				$self->{graph}->line( $x - $self->{depth_3d}, 
				                      $y + $self->{depth_3d},
				                      $x - $self->{depth_3d} + $self->{x_tick_length}, 
				                      $y + $self->{depth_3d} - $self->{x_tick_length},
				                      $self->{fgci} 
				);
			}
		}

		# CONTRIB Damon Brodie for x_tick_offset
		next if 
			($i - $self->{x_tick_offset}) % ($self->{x_label_skip}) and 
			$i != $self->{_data}->num_points - 1;

		$self->{gdta_x_axis}->set_text($self->{_data}->get_x($i));

		# CONTRIB Jeremy Wadsack
		# Subtract 3-d extrusion width from left label
		# Add 3-d extrusion height to left label
		# (they were changed for ticks)
		$x -= $self->{depth_3d};
		$y += $self->{depth_3d};

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
		
	} # end for

	return $self;

} # end draw_x_ticks


# CONTRIB Scott Prahl
# Assume x array contains equally spaced x-values
# and generate an appropriate axis
#
####
# 'True' numerical X axis addition 
# From: Gary Deschaines
#
# These modification to draw_x_ticks_number pass x-tick values to the
# val_to_pixel subroutine instead of x-tick indices when ture[sic] numerical
# x-axis mode is detected.  Also, x_tick_offset and x_label_skip are
# processed differently when true numerical x-axis mode is detected to
# allow labeled major x-tick marks and un-labeled minor x-tick marks.
#
# For example:
#
#      x_tick_number =>  14,
#      x_ticks       =>   1,
#      x_long_ticks  =>   1,
#      x_tick_length =>  -4,
#      x_min_value   => 100,
#      x_max_value   => 800,
#      x_tick_offset =>   2,
#      x_label_skip  =>   2,
#
#
#      ~         ~    ~    ~    ~    ~    ~    ~    ~    ~    ~    ~         ~
#      |         |    |    |    |    |    |    |    |    |    |    |         |
#   1 -|         |    |    |    |    |    |    |    |    |    |    |         |
#      |         |    |    |    |    |    |    |    |    |    |    |         |
#   0 _|_________|____|____|____|____|____|____|____|____|____|____|_________|
#                |    |    |    |    |    |    |    |    |    |    |
#               200       300       400       500       600       700
####
# [JAW] Added commented items for 3d rendering
# Based on MVERB source
sub draw_x_ticks_number
{
	my $self = shift;

	for my $i (0 .. $self->{x_tick_number})
	{
		my ($value, $x, $y);

 		if (defined($self->{x_min_value}) && defined($self->{x_max_value}))
 		{
			next if ($i - $self->{x_tick_offset}) < 0;
 			next if ($i + $self->{x_tick_offset}) > $self->{x_tick_number};
 			$value = $self->{x_values}[$i];
 			($x, $y) = $self->val_to_pixel($value, 0, 1);
 		}
 		else
 		{
			$value = ($self->{_data}->num_points - 1)
						* ($self->{x_values}[$i] - $self->{true_x_min})
						/ ($self->{true_x_max} - $self->{true_x_min});
 			($x, $y) = $self->val_to_pixel($value + 1, 0, 1);
 		}

		$y = $self->{bottom} unless $self->{zero_axis_only};

		# Draw on the back of the extrusion
		$x += $self->{depth_3d};
		$y -= $self->{depth_3d};

		if ($self->{x_ticks})
		{
			if ($self->{x_long_ticks})
			{
				# XXX This mod needs to be done everywhere ticks are
				# drawn
				if ( $self->{x_tick_length} >= 0 ) 
				{
					# Move up by 3d depth
					$self->{graph}->line( $x,
					                      $self->{bottom} - $self->{depth_3d}, 
												 $x, 
												 $self->{top} - $self->{depth_3d}, 
												 $self->{fgci});
				} 
				else 
				{
					$self->{graph}->line(
						$x, $self->{bottom} - $self->{x_tick_length}, 
						$x, $self->{top}, $self->{fgci});
				}
				# CONTRIB Jeremy Wadsack
				# Draw conector ticks
				$self->{graph}->line( $x - $self->{depth_3d}, 
				                      $y + $self->{depth_3d},
				                      $x, 
				                      $y, 
				                      $self->{fgci} 
				);
			}
			else
			{
				$self->{graph}->line($x, $y, 
					$x, $y - $self->{x_tick_length}, $self->{fgci} );
				# CONTRIB Jeremy Wadsack
				# Draw conector ticks
				$self->{graph}->line( $x - $self->{depth_3d}, 
				                      $y + $self->{depth_3d},
				                      $x, - $self->{depth_3d} + $self->{tick_length}, 
				                      $y, + $self->{depth_3d} - $self->{tick_length},
				                      $self->{fgci} 
				);
			} # end if -- x_long_ticks
		} # end if -- x_ticks

		# If we have to skip labels, we'll do it here.
		# Make sure to always draw the last one.
		next if $i % $self->{x_label_skip} && $i != $self->{x_tick_number};

		$self->{gdta_x_axis}->set_text($self->{x_labels}[$i]);

		# CONTRIB Jeremy Wadsack
		# Subtract 3-d extrusion width from left label
		# Add 3-d extrusion height to left label
		# (they were changed for ticks)
		$x -= $self->{depth_3d};
		$y += $self->{depth_3d};

		if ($self->{x_labels_vertical})
		{
			$self->{gdta_x_axis}->set_align('center', 'right');
			my $yt = $y + $self->{text_space}/2;
			$self->{gdta_x_axis}->draw($x, $yt, PI/2);
		}
		else
		{
			$self->{gdta_x_axis}->set_align('top', 'center');
			my $yt = $y + $self->{text_space}/2;
			$self->{gdta_x_axis}->draw($x, $yt);
		} # end if
	} # end for

	return $self;
	
} # end draw_x_tick_number

# Inherit draw_ticks
# Inherit draw_data
# Inherit draw_data_set
# Inherit set_max_min
# Inherit get_max_y
# Inherit get_min_y
# Inherit get_max_min_y_all
# Inherit _get_bottom
# Inherit val_to_pixel
# Inherit setup_legend


# [JW] Override draw_legend and reverse the drawing order
# if cumulate is enabled so legend matches data on chart
sub draw_legend
{
	my $self = shift;

	return unless defined $self->{legend};

	my $xl = $self->{lg_xs} + $self->{legend_spacing};
	my $y  = $self->{lg_ys} + $self->{legend_spacing} - 1;

	# If there's a frame, offset by the size and margin
	$xl += $self->{legend_frame_margin} + $self->{legend_frame_size} if $self->{legend_frame_size};
	$y += $self->{legend_frame_margin} + $self->{legend_frame_size} if $self->{legend_frame_size};

	my $i = 0;
	my $row = 1;
	my $x = $xl;	# start position of current element
	my @legends = @{$self->{legend}};
	my $i_step = 1;
	
	# If we are working in cumulate mode, then reverse the drawing order
	if( $self->{cumulate} ) {
		@legends = reverse @legends;
		$i = scalar(@legends);
		$i = $self->{_data}->num_sets if $self->{_data}->num_sets < $i;
		$i++;
		$i_step = -1;
	} # end if
	
	foreach my $legend (@legends)
	{
		$i += $i_step;

		# Legend for Pie goes over first set, and all points
		# Works in either direction
		last if $i > $self->{_data}->num_sets;
		last if $i < 1;

		my $xe = $x;	# position within an element

		next unless defined($legend) && $legend ne "";

		$self->draw_legend_marker($i, $xe, $y);

		$xe += $self->{legend_marker_width} + $self->{legend_spacing};
		my $ys = int($y + $self->{lg_el_height}/2 - $self->{lgfh}/2);

		$self->{gdta_legend}->set_text($legend);
		$self->{gdta_legend}->draw($xe, $ys);

		$x += $self->{lg_el_width};

		if (++$row > $self->{lg_cols})
		{
			$row = 1;
			$y += $self->{lg_el_height};
			$x = $xl;
		}
	}
	
	# If there's a frame, draw it now
	if( $self->{legend_frame_size} ) {
		$x = $self->{lg_xs} + $self->{legend_spacing};
		$y = $self->{lg_ys} + $self->{legend_spacing} - 1;
		
		for $i ( 0 .. $self->{legend_frame_size} - 1 ) {
			$self->{graph}->rectangle(
				$x + $i,
				$y + $i, 
				$x + $self->{lg_x_size} + 2 * $self->{legend_frame_margin} - $i - 1,
				$y + $self->{lg_y_size} + 2 * $self->{legend_frame_margin} - $i - 1,
				$self->{acci},
			);
		} # end for
	} # end if
	
}



# Inherit draw_legend_marker

1;
