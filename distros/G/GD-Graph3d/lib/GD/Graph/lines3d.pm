#==========================================================================
# Module: GD::Graph::lines3d
#
# Copyright (C) 1999,2001 Wadsack-Allen. All Rights Reserved.
#
# Based on GD::Graph::lines.pm,v 1.10 2000/04/15 mgjv
#          Copyright (c) 1995-1998 Martien Verbruggen
#
#--------------------------------------------------------------------------
# Date		Modification				                                 Author
# -------------------------------------------------------------------------
# 1999SEP18 Created 3D line chart class (this module)                   JAW
# 1999SEP19 Finished overwrite 1 style                                  JAW
# 1999SEP19 Polygon'd linewidth rendering                               JAW
# 2000SEP19 Converted to a GD::Graph class                              JAW
# 2000APR18 Modified for compatibility with GD::Graph 1.30              JAW
# 2000APR24 Fixed a lot of rendering bugs                               JAW
# 2000AUG19 Changed render code so lines have consitent width           JAW
# 2000AUG21 Added 3d shading                                            JAW
# 2000AUG24 Fixed shading top/botttom vs. postive/negative slope        JAW
# 2000SEP04 For single point "lines" made a short segment               JAW
# 2000OCT09 Fixed bug in rendering of legend                            JAW
#==========================================================================
# TODO
#		** The new mitred corners don't work well at data anomlies. Like
#		   the set (0,0,1,0,0,0,1,0,1) Looks really wrong!
#		* Write a draw_data_set that draws the line so they appear to pass 
#		  through one another. This means drawing a border edge at each 
#		  intersection of the data lines so the points of pass-through show.
#		  Probably want to draw all filled polygons, then run through the data 
#		  again finding intersections of line segments and drawing those edges.
#==========================================================================
package GD::Graph::lines3d;

use strict;
 
use GD;
use GD::Graph::axestype3d;
use Data::Dumper;

@GD::Graph::lines3d::ISA = qw( GD::Graph::axestype3d );
$GD::Graph::lines3d::VERSION = '0.63';

my $PI = 4 * atan2(1, 1);

my %Defaults = (
	# The depth of the line in their extrusion

	line_depth		=> 10,
);

sub initialise()
{
	my $self = shift;

	my $rc = $self->SUPER::initialise();

	while( my($key, $val) = each %Defaults ) { 
		$self->{$key} = $val 

		# *** [JAW]
		# Should we reset the depth_3d param based on the 
		# line_depth, numsets and overwrite parameters, here?
		#
	} # end while

	return $rc;
	
} # end initialize

sub set
{
	my $s = shift;
	my %args = @_;

	$s->{_set_error} = 0;

	for (keys %args) 
	{ 
		/^line_depth$/ and do 
		{
			$s->{line_depth} = $args{$_};
			delete $args{$_};
			next;
		};
	}

	return $s->SUPER::set(%args);
} # end set

# PRIVATE

# [JAW] Changed to draw_data intead of 
# draw_data_set to allow better control 
# of multiple set rendering
sub draw_data
{
	my $self = shift;
	my $d = $self->{_data};
	my $g = $self->{graph};

	$self->draw_data_overwrite( $g, $d );

	# redraw the 'zero' axis, front and right
	if( $self->{zero_axis} ) {
		$g->line( 
			$self->{left}, $self->{zeropoint}, 
			$self->{right}, $self->{zeropoint}, 
			$self->{fgci} );
		$g->line( 
			$self->{right}, $self->{zeropoint}, 
			$self->{right} + $self->{depth_3d}, $self->{zeropoint} - $self->{depth_3d}, 
			$self->{fgci} );
	} # end if
	
	# redraw the box face
	if ( $self->{box_axis} ) {
		# Axes box
		$g->rectangle($self->{left}, $self->{top}, $self->{right}, $self->{bottom}, $self->{fgci});
		$g->line($self->{right}, $self->{top}, $self->{right} + $self->{depth_3d}, $self->{top} - $self->{depth_3d}, $self->{fgci});
		$g->line($self->{right}, $self->{bottom}, $self->{right} + $self->{depth_3d}, $self->{bottom} - $self->{depth_3d}, $self->{fgci});
	} # end if

	return $self;
	
} # end draw_data

# Copied from MVERB source
sub pick_line_type
{
	my $self = shift;
	my $num = shift;

	ref $self->{line_types} ?
		$self->{line_types}[ $num % (1 + $#{$self->{line_types}}) - 1 ] :
		$num % 4 ? $num % 4 : 4
}

# ----------------------------------------------------------
# Sub: draw_data_overwrite
#
# Args: $gd
#	$gd	The GD object to draw on
#
# Description: Draws each line segment for each set. Runs 
# over sets, then points so that the appearance is better.
# ----------------------------------------------------------
# Date      Modification                              Author
# ----------------------------------------------------------
# 19SEP1999 Added this for overwrite support.             JW
# 20AUG2000 Changed structure to use points 'objects'     JW
# ----------------------------------------------------------
sub draw_data_overwrite {
	my $self = shift;
	my $g = shift;
	my @points_cache;

	my $i;
	for $i (0 .. $self->{_data}->num_points()) 
	{
		my $j;
		for $j (1 .. $self->{_data}->num_sets()) 
		{
			my @values = $self->{_data}->y_values($j) or
				return $self->_set_error( "Impossible illegal data set: $j", $self->{_data}->error );

			if( $self->{_data}->num_points() == 1 && $i == 1 ) {
				# Copy the first point to the "second" 
				$values[$i] = $values[0];
			} # end if

			next unless defined $values[$i];

			# calculate offset of this line
			# *** Should offset be the max of line_depth 
			#     and depth_3d/numsets? [JAW]
			#
			my $offset = $self->{line_depth} * ($self->{_data}->num_sets() - $j);

			# Get the coordinates of the previous point, if this is the first 
			# point make a point object and start over (i.e. next;)
			unless( $i ) {
				my( $xb, $yb );
				if (defined($self->{x_min_value}) && defined($self->{x_max_value})) {
					($xb, $yb) = $self->val_to_pixel( $self->{_data}->get_x($i), $values[$i], $j );
				} else {
					($xb, $yb) = $self->val_to_pixel( $i + 1, $values[$i], $j );
				} # end if
				$xb += $offset;
				$yb -= $offset;
				$points_cache[$i][$j] = { coords => [$xb, $yb] };
				next;
			} # end unless

			# Pick a data colour, calc shading colors too, if requested
			my( @rgb ) = $self->pick_data_clr( $j );
			my $dsci = $self->set_clr( @rgb );
			if( $self->{'3d_shading'} ) {
				$self->{'3d_highlights'}[$dsci] = $self->set_clr( $self->_brighten( @rgb ) );
				$self->{'3d_shadows'}[$dsci]    = $self->set_clr( $self->_darken( @rgb ) );
			} # end if

			# Get the type
			my $type = $self->pick_line_type($j);
			
			# Get the coordinates of the this point
			unless( ref $points_cache[$i][$j] ) {
				my( $xe, $ye );
				if( defined($self->{x_min_value}) && defined($self->{x_max_value}) ) {
					( $xe, $ye ) = $self->val_to_pixel( $self->{_data}->get_x($i), $values[$i], $j );
				} else {
					( $xe, $ye ) = $self->val_to_pixel($i + 1, $values[$i], $j);
				} # end if
				$xe += $offset;
				$ye -= $offset;
				$points_cache[$i][$j] = { coords => [$xe, $ye] };
			} # end if
			
			# Find the coordinates of the next point
			if( defined $values[$i + 1] ) {
				my( $xe, $ye );
				if( defined($self->{x_min_value}) && defined($self->{x_max_value}) ) {
					( $xe, $ye ) = $self->val_to_pixel( $self->{_data}->get_x($i + 1), $values[$i + 1], $j );
				} else {
					( $xe, $ye ) = $self->val_to_pixel($i + 2, $values[$i + 1], $j);
				} # end if
				$xe += $offset;
				$ye -= $offset;
				$points_cache[$i + 1][$j] = { coords => [$xe, $ye] };
			} # end if

			if( $self->{_data}->num_points() == 1 && $i == 1 ) {
				# Nudge the x coords back- and forwards
				my $n = int(($self->{right} - $self->{left}) / 30);
				$n = 2 if $n < 2;
				$points_cache[$i][$j]{coords}[0] = $points_cache[$i - 1][$j]{coords}[0] + $n;
				$points_cache[$i - 1][$j]{coords}[0] -= $n;
			} # end if
			
			# Draw the line segment
			$self->draw_line( $points_cache[$i - 1][$j], 
			                  $points_cache[$i][$j], 
			                  $points_cache[$i + 1][$j], 
			                  $type, 
			                  $dsci );
			
			# Draw the end cap if last segment
			if( $i >= $self->{_data}->num_points() - 1 ) {
				my $poly = new GD::Polygon;
				$poly->addPt( $points_cache[$i][$j]{face}[0], $points_cache[$i][$j]{face}[1] );
				$poly->addPt( $points_cache[$i][$j]{face}[2], $points_cache[$i][$j]{face}[3] );
				$poly->addPt( $points_cache[$i][$j]{face}[2] + $self->{line_depth}, $points_cache[$i][$j]{face}[3] - $self->{line_depth} );
				$poly->addPt( $points_cache[$i][$j]{face}[0] + $self->{line_depth}, $points_cache[$i][$j]{face}[1] - $self->{line_depth} );
				if( $self->{'3d_shading'} ) {
					$g->filledPolygon( $poly, $self->{'3d_shadows'}[$dsci] );
				} else {
					$g->filledPolygon( $poly, $dsci );
				} # end if
				$g->polygon( $poly, $self->{fgci} );
			} # end if

		} # end for -- $self->{_data}->num_sets()
	} # end for -- $self->{_data}->num_points()

} # end sub draw_data_overwrite

# ----------------------------------------------------------
# Sub: draw_line
#
# Args: $prev, $this, $next, $type, $clr
#	$prev       A hash ref for the prev point's object
#	$this       A hash ref for this point's object
#	$next       A hash ref for the next point's object
#	$type       A predefined line type (2..4) = (dashed, dotted, dashed & dotted)
#	$clr        The color (colour) index to use for the fill
#
# Point "Object" has these properties:
#	coords      A 2 element array of the coordinates for the line 
#	            (this should be filled in before calling)
#	face        An 4 element array of end points for the face 
#	            polygon. This will be populated by this method.
#
# Description: Draws a line segment in 3d extrusion that 
# connects the prev point the the this point. The next point
# is used to calculate the mitre at the joint.
# ----------------------------------------------------------
# Date      Modification                              Author
# ----------------------------------------------------------
# 18SEP1999 Modified MVERB source to work on data 
#           point, not data set for better rendering     JAW
# 19SEP1999 Ploygon'd line rendering for better effect   JAW
# 19AUG2000 Made line width perpendicular                JAW
# 19AUG2000 Changed parameters to use %line_seg hash/obj JAW
# 20AUG2000 Mitred joints of line segments               JAW
# ----------------------------------------------------------
sub draw_line
{
	my $self = shift;
	my( $prev, $this, $next, $type, $clr ) = @_;
	my $xs = $prev->{coords}[0];
	my $ys = $prev->{coords}[1];
	my $xe = $this->{coords}[0];
	my $ye = $this->{coords}[1];

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

	# [JAW] Removed the dataset loop for better results.

	# Need the setstyle to reset 
	$self->{graph}->setStyle(@pattern) if (@pattern);

	#
	# Find the x and y offsets for the edge of the front face 
	# Do this by adjusting them perpendicularly from the line
	# half the line width in front and in back. 
	#
	my( $lwyoff, $lwxoff );
	if( $xe == $xs ) {
		$lwxoff = $lw / 2;
		$lwyoff = 0;
	} elsif( $ye == $ys ) {
		$lwxoff = 0;
		$lwyoff = $lw / 2;
	} else {
		my $ln = sqrt( ($ys-$ye)**2 + ($xe-$xs)**2 );
		$lwyoff = ($xe-$xs) / $ln  * $lw / 2;
		$lwxoff = ($ys-$ye) / $ln * $lw / 2;
	} # end if

	# For first line, figure beginning point
	unless( defined $prev->{face}[0] ) {
		$prev->{face} = [];
		$prev->{face}[0] = $xs - $lwxoff;
		$prev->{face}[1] = $ys - $lwyoff;
		$prev->{face}[2] = $xs + $lwxoff;
		$prev->{face}[3] = $ys + $lwyoff;
	} # end unless
	
	# Calc and store this point's face coords
	unless( defined $this->{face}[0] ) {
		$this->{face} = [];
		$this->{face}[0] = $xe - $lwxoff;
		$this->{face}[1] = $ye - $lwyoff;
		$this->{face}[2] = $xe + $lwxoff;
		$this->{face}[3] = $ye + $lwyoff;
	} # end if
	
	# Now find next point and nudge these coords to mitre
	if( ref $next->{coords} eq 'ARRAY' ) {
		my( $lwyo2, $lwxo2 );
		my( $x2, $y2 ) = @{$next->{coords}};
		if( $x2 == $xe ) {
			$lwxo2 = $lw / 2;
			$lwyo2 = 0;
		} elsif( $y2 == $ye ) {
			$lwxo2 = 0;
			$lwyo2 = $lw / 2;
		} else {
			my $ln2 = sqrt( ($ye-$y2)**2 + ($x2-$xe)**2 );
			$lwyo2 = ($x2-$xe) / $ln2  * $lw / 2;
			$lwxo2 = ($ye-$y2) / $ln2 * $lw / 2;
		} # end if
		$next->{face} = [];
		$next->{face}[0] = $x2 - $lwxo2;
		$next->{face}[1] = $y2 - $lwyo2;
		$next->{face}[2] = $x2 + $lwxo2;
		$next->{face}[3] = $y2 + $lwyo2;
	
		# Now get the intersecting coordinates
		my $mt = ($ye - $ys)/($xe - $xs);
		my $mn = ($y2 - $ye)/($x2 - $xe);
		my $bt = $this->{face}[1] - $this->{face}[0] * $mt;
		my $bn = $next->{face}[1] - $next->{face}[0] * $mn;
		if( $mt != $mn ) {
			$this->{face}[0] = ($bn - $bt) / ($mt - $mn);
		} # end if
		$this->{face}[1] = $mt * $this->{face}[0] + $bt;
		$bt = $this->{face}[3] - $this->{face}[2] * $mt;
		$bn = $next->{face}[3] - $next->{face}[2] * $mn;
		if( $mt != $mn ) {
			$this->{face}[2] = ($bn - $bt) / ($mt - $mn);
		} # end if
		$this->{face}[3] = $mt * $this->{face}[2] + $bt;
	} # end if


	# Make the top/bottom polygon
	my $poly = new GD::Polygon;
	if( ($ys-$ye)/($xe-$xs) > 1 ) {
		$poly->addPt( $prev->{face}[2], $prev->{face}[3] );
		$poly->addPt( $this->{face}[2], $this->{face}[3] );
		$poly->addPt( $this->{face}[2] + $self->{line_depth}, $this->{face}[3] - $self->{line_depth} );
		$poly->addPt( $prev->{face}[2] + $self->{line_depth}, $prev->{face}[3] - $self->{line_depth} );
		if( $self->{'3d_shading'} &&  $style == $clr ) {
			if( ($ys-$ye)/($xe-$xs) > 0 ) {
				$self->{graph}->filledPolygon( $poly, $self->{'3d_shadows'}[$clr] );
			} else {
				$self->{graph}->filledPolygon( $poly, $self->{'3d_highlights'}[$clr] );
			} # end if
		} else {
			$self->{graph}->filledPolygon( $poly, $style );
		} # end if
	} else {
		$poly->addPt( $prev->{face}[0], $prev->{face}[1] );
		$poly->addPt( $this->{face}[0], $this->{face}[1] );
		$poly->addPt( $this->{face}[0] + $self->{line_depth}, $this->{face}[1] - $self->{line_depth} );
		$poly->addPt( $prev->{face}[0] + $self->{line_depth}, $prev->{face}[1] - $self->{line_depth} );
		if( $self->{'3d_shading'} &&  $style == $clr ) {
			if( ($ys-$ye)/($xe-$xs) < 0 ) {
				$self->{graph}->filledPolygon( $poly, $self->{'3d_shadows'}[$clr] );
			} else {
				$self->{graph}->filledPolygon( $poly, $self->{'3d_highlights'}[$clr] );
			} # end if
		} else {
			$self->{graph}->filledPolygon( $poly, $style );
		} # end if
	} # end if
	$self->{graph}->polygon( $poly, $self->{fgci} );

	# *** This paints dashed and dotted patterns on the faces of
	#     the polygons. They don't look very good though. Would it
	#     be better to extrude the style as well as the lines?
	#     Otherwise could also be improved by using gdTiled instead of 
	#     gdStyled and making the tile a transform of the line style
	#     for each face. [JAW]

	# Make the face polygon
	$poly = new GD::Polygon;
	$poly->addPt( $prev->{face}[0], $prev->{face}[1] );
	$poly->addPt( $this->{face}[0], $this->{face}[1] );
	$poly->addPt( $this->{face}[2], $this->{face}[3] );
	$poly->addPt( $prev->{face}[2], $prev->{face}[3] );

	$self->{graph}->filledPolygon( $poly, $style );
	$self->{graph}->polygon( $poly, $self->{fgci} );

} # end draw line

# ----------------------------------------------------------
# Sub: draw_legend_marker
#
# Args: $dsn, $x, $y
#	$dsn	The dataset number to draw the marker for
#	$x  	The x position of the marker
#	$y  	The y position of the marker
#
# Description: Draws the legend marker for the specified 
# dataset number at the given coordinates
# ----------------------------------------------------------
# Date      Modification                              Author
# ----------------------------------------------------------
# 2000OCT06 Fixed rendering bugs                          JW
# ----------------------------------------------------------
sub draw_legend_marker
{
	my $self = shift;
	my ($n, $x, $y) = @_;

	my $ci = $self->set_clr($self->pick_data_clr($n));
	my $type = $self->pick_line_type($n);

	$y += int($self->{lg_el_height}/2);

	#  Joe Smith <jms@tardis.Tymnet.COM>
	local($self->{line_width}) = 2;    # Make these show up better

	$self->draw_line(
		{ coords => [$x, $y] }, 
		{ coords => [$x + $self->{legend_marker_width}, $y] }, 
		undef, 
		$type,
		$ci
	);

} # end draw_legend_marker

1;
