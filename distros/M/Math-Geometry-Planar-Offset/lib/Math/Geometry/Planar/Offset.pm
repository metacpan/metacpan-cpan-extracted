package Math::Geometry::Planar::Offset;

require 5.006;

our $VERSION = '1.05';

use strict;
use warnings;

use Carp;

our $debug     = 0;
our $precision = 7;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw(
				OffsetPolygon
                $precision
                $debug
               );

=pod

=head1 NAME

Math::Geometry::Planar::Offset - Calculate offset polygons

=head1 SYNOPSIS

  use Math::Geometry::Planar::Offset;

  my (@results) = OffsetPolygon(\@points, $distance);
  foreach my $polygon (@results) {
    # do something with @$polygon
  }

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

=head1 COPYRIGHT NOTICE

Copyright (C) 2003-2007 Eric L. Wilhelm.  All rights reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, neither Eric Wilhelm, nor anyone else, owes you anything
whatseover.  You have been warned.

Note that this includes NO GUARANTEE of MATHEMATICAL CORRECTNESS.  If
you are going to use this code in a production environment, it is YOUR
RESPONSIBILITY to verify that the methods return the correct values. 

=head1 LICENSE

You may use this software under one of the following licenses:

  (1) GNU General Public License 
    (found at http://www.gnu.org/copyleft/gpl.html) 
  (2) Artistic License 
    (found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 BUGS

There are currently some problems with concurrent edge events on outward
(and maybe inward) offsets.  Some significant changes need to be made.

=cut

=head1 METHODS

These methods are actually defined in Math::Geometry::Planar, which uses
this module.

=head2  offset_polygon

Returns reference to an array of polygons representing the original polygon
offsetted by $distance

  $polygon->offset_polygon($distance);

=cut

my $delta = 10 ** (-$precision);

my $offset_depth = 0;
my $screen_height = 600;
my $flag;
my @bisectors;

=head1 Functions

Only OffsetPolygon is exported.

=head2 pi

Returns the constant pi

=cut
sub pi {
	atan2(1,1) * 4;
}

=head2 OffsetPolygon

Make offset polygon subroutine.

Call with offset distance and ref to array of points for original
polygon polygon input must be pre-wrapped so point[n]=point[0]

Will return a list of polygons (as refs.)  The number of polygons in the
output depends on the shape of your input polygon.  It may split into
several pieces during the offset.

  my (@results) = OffsetPolygon(\@points, $distance);
  foreach my $polygon (@results) {
    # do something with @$polygon
  }

=cut
sub OffsetPolygon {
	my ($points, $offset, $canvas) = @_;
	my %intersects;
	my ($count,$n,$n2);
	my ($time, $time_static);
	# my $key1,$key2;
	my @angles;
	my @directions;
	my @phi;
	my @bis_dir;
	my @bis_end;
	my @bis_scale;
	my @result1;
	my @result2;
	my @outlist;
	my ($cut1,$cut2,$cut);
	$#outlist = 0;
	my @newpoints;
	my @newpoints1;

	# set limit on number of recursions
	# does perl have its own limit to the number of scopes generated?
	if($offset_depth > 100){
		print "reached recursion depth_limit\n";
		return();
	}
	#ew: $offset_depth would have had to be reset by calling script 
	# (now is incremented and decremented on each side of recursive call)
	my $npoints = @{$points};
	$debug && print "points: ", $npoints, "\n";
	$debug && print "number of points $npoints\n";
	# print "points: @{$points->[0]}\n";
	# exit;
	# my $bis_length = 15;
	# All polygons should be counter-clockwise !!!
	_find_direction($points,\@angles,\@directions);
	$debug and print "starting recurse: ",$offset_depth -1,"\n";
	$debug and print "offset:  $offset\n";
	# ew removed junk related to null points
	# bail out if not at least a triangle
	if($npoints < 3) {
		carp("Need at least 3 non-colinear points to offset");
		return;
	}
	# Now to make the bisectors
	for($n = 0;$n < $npoints; $n++) {
		$phi[$n] = ((pi) - $angles[$n]) / 2;
		$bis_scale[$n] = abs(1 / sin($phi[$n]));
		$bis_dir[$n] = $directions[$n] + $phi[$n];
		$bis_end[$n][0] = $points->[$n][0] + $offset * $bis_scale[$n] * cos($bis_dir[$n]);  # X-coordinate
		$bis_end[$n][1] = $points->[$n][1] + $offset * $bis_scale[$n] * sin($bis_dir[$n]);  # Y-coordinate
	}

	# Draw bisectors
	if ($canvas) {
		# first delete existing bisectors
		for($n = 0; $n<@bisectors;$n++) {
			$canvas ->delete($bisectors[$n]);
		}
		@bisectors = ();
		# then draw the bisector points from the vertices.
		for($n = 0; $n < $npoints; $n++) {
			my $x1 = $points->[$n][0];
			my $y1 = $screen_height - $points->[$n][1];
			my $x2 = $bis_end[$n][0];
			my $y2 = $screen_height-$bis_end[$n][1];
			$bisectors[$n] = $canvas->create('line', $x1,$y1,$x2,$y2, '-fill' => 'blue','-arrow'=>'last');
		}
	}
	
	# Need to find whether a bisector first intersects a bisector,
	# or a bisector first intersects a "ghost" edge.  Also, must know
	# which one and at what time:
	my ($Ax1,$Ay1,$Ax2,$Ay2,$Bx1,$By1,$Bx2,$By2);
	my ($delAx,$delAy,$delBx,$delBy,$Am,$Ab,$Bm,$Bb);
	my ($x_int,$y_int);
	my ($first_join,$first_split,$split_seg);
	my $first_event = "";
	my $first_time = abs($offset)+1;
	my $time_dir = $offset / abs($offset);  # +1 or -1 to give direction
	my $new_offset;
	my $join_time = $first_time;
	my $split_time = $first_time;
	
	# first find intersections of adjacent bisectors (if any)
	for($n = 0;$n <$npoints;$n++) {
		$Ax1 = $points->[$n][0];
		$Ay1 = $points->[$n][1];
		$Ax2 = $bis_end[$n][0];
		$Ay2 = $bis_end[$n][1];
		$delAx = $Ax2 - $Ax1;
		$delAy = $Ay2 - $Ay1;
		# elw: what amateur wrote this!
		if($delAx)  {
			$Am = $delAy / $delAx;  $Ab = $Ay1 - $Ax1 * $Am;
		}
		else {
			$Am = "inf";
		}
		# Check against the next bisector:
		$Bx1 = $points->[$n+1-$npoints][0];
		$By1 = $points->[$n+1-$npoints][1];
		$Bx2 = $bis_end[$n+1-$npoints][0];
		$By2 = $bis_end[$n+1-$npoints][1];
		$delBx = $Bx2 - $Bx1;
		$delBy = $By2 - $By1;
		# elw: maybe you are getting closer to zen now:)
		if($delBx)  {
			$Bm = $delBy / $delBx;$Bb = $By1 - $Bx1 * $Bm;
		}
		else{
			$Bm = "inf";
		}
		if( ($Am == $Bm) || ($Am eq $Bm) ) {
			next;
		}
		# Calculate determinants to find if intersection is within the bisector segment.
		if  (! _do_cross($Ax1,$Ay1,$Ax2,$Ay2,$Bx1,$By1,$Bx2,$By2) ){
			next;
		}
		# if we have an intersection of the skeleton and only a triangle,
		# then it has collapsed to a point:
		if($npoints < 4) {
			$debug && print "collapsed\n";
			return();
		}
		if($Am eq "inf") {  # Slope of first line is infinite, so use Ax1.
			$x_int = $Ax1;    # Will always be on vertical line.
			$y_int = $Bm * $x_int + $Bb;
		}
		elsif($Bm eq "inf") {  # Slope of second line is infinite, so use Bx1.
			$x_int = $Bx1;$y_int = $Am * $x_int + $Ab;
		}
		else {
			$x_int = ($Bb - $Ab) / ($Am - $Bm);$y_int = $Am *$x_int + $Ab;
		}
		# Now, if the lines are not parallel, and the intersection
		# happens on the line segments, we are here with
		# the x and y coordinates of the intersection of the two lines.
		## $debug and printf ("intersection: %6.0f,%6.0f\n",$x_int, $y_int);

		# Let's find the time of intersect.
		# distance  formula with adjustment for speed
		$time = sqrt( ($x_int - $points->[$n][0])**2 + ($y_int - $points->[$n][1])**2 ) / $bis_scale[$n];
		if( (abs($time) < $first_time) )
			# && ( $time / abs($time)== $offset / abs($offset) ) )
			{
			# note that none of the times loaded here have a sign
			$first_time = abs($time);
			$join_time = $first_time;
			$first_join=$n;
			$first_event="join";
		}


	} # end for n (for each bisector vs next neighbor)
	# Time is smallest relevant offset distance before first join.
	# first join is address of point to be joined.
	# first event is "join" if controlling (could be over-ridden by split)
	# If this is the controlling case, create the joined polygon at that offset time
	# and make a recursive call.
	#
	#
	# Now to check for intersections of bisectors with edges
	# Have to check against all segments except adjacent ones.
	# Nothing will happen if it is a triangle.
	if($npoints > 3) {
		for($n = 0; $n < $npoints; $n++) {
			$Ax1 = $points->[$n][0];  # Get bisector endpoints
			$Ay1 = $points->[$n][1];
			$Ax2 = $bis_end[$n][0];
			$Ay2 = $bis_end[$n][1];
			$debug && print "starting at $Ax1 $Ay1\n";
			$debug && print "bisector toward $Ax2 $Ay2\n";
			# I need it to be a ray, so I am just making a really long segment here.
			$delAx = 1000* $offset* ($Ax2 - $Ax1);
			$delAy = 1000* $offset* ($Ay2 - $Ay1);
			$Ax2 = $Ax1+ $delAx;
			$Ay2 = $Ay1 + $delAy;
			if($delAx)  {$Am = $delAy / $delAx;  $Ab = $Ay1 - $Ax1 * $Am;}else{$Am = "inf";};
			# this loop has to compare to all of the polygon sides except the adjacent ones
			for($n2 = 0; $n2 < $npoints; $n2++) {
				$time = abs($offset) +1;
				# Can't split adjacent segments
				if( ($n2 == $n) || ($n2 == $n-1) || ( ($n==0)&&($n2 == $npoints-1) ) ){
					next;
				}
				$debug && print "inner loop at n2 = $n2\n";
				$Bx1 = $points->[$n2][0];  # Get edge endpoints
				$By1 = $points->[$n2][1];
				$Bx2 = $points->[$n2 + 1 - $npoints][0];
				$By2 = $points->[$n2+1-$npoints][1];
				$delBx = $Bx2 - $Bx1;
				$delBy = $By2 - $By1;
				if($delBx)  {
					$Bm = $delBy / $delBx;$Bb = $By1 - $Bx1 * $Bm;
				}
				else {
					$Bm = "inf";
				}
				if( ($Am == $Bm) || ($Am eq $Bm) ){
					next;
				}
				# Note that I am not using the dot product here (it
				# shows up below.  I need to know where the infinite ray
				# of the bisector crosses the infinite line of the
				# polygon edge (but this may cause problems as well)
				if($Am eq "inf") { 
					# Slope of first line is infinite, so use Ax1.
					$x_int = $Ax1;$y_int = $Bm * $x_int + $Bb;
				}
				elsif($Bm eq "inf") {
					# Slope of second line is infinite, so use Bx1.
					$x_int = $Bx1;$y_int = $Am * $x_int + $Ab;
				}
				else {
					$x_int = ($Bb - $Ab) / ($Am - $Bm);$y_int = $Am *$x_int + $Ab;
				}
				# now make sure that the intersection happened on the right side
				# (point the ray in the offset direction)
				my $delxto_int = $x_int - $Ax1;
				my $delyto_int = $y_int - $Ay1;
				my $next = $n2+1;
				if ($next == $npoints) {
					$next = 0;
				}
				# This method is not handling the split which happens to edges terminating
				# at a concave point.  This event is a third case because the time calculated
				# below will be smaller for the extension of the edge before the concavity than
				# for the edge after the concavity, which is the one to properly split.


				# I have suspicions about the accuracy here:
				# Original intent was to make sure that the ray was properly treated
				# now handled by using a really long segment (1000*offset) for the ray.
				# if( $bis_dir[$n] == (atan2($delyto_int,$delxto_int)))
					{
					# direction is good, calculate distance
					# note that the int_scale should be naturally signed
					# to prevent strangeness on internal offsets.
					# dvdp:
					# $int_scale = 1 / (sin( $directions[$n2] - $bis_dir[$n])) ;
					# This could lead to a devision by 0 so we calculate the reverse and check first
					my $int_scale = (sin( $directions[$n2] - $bis_dir[$n])) ;
					$debug && print "bisector scale:  $bis_scale[$n]\n";
					$debug && print "intersection scale:  1 / $int_scale\n";
					if ($int_scale) {
						$int_scale  = 1 / $int_scale;
						if($bis_scale[$n]+$int_scale) {
							$time_static = sqrt( ($x_int - $points->[$n][0])**2 + 
								($y_int - $points->[$n][1])**2 ) / ($bis_scale[$n]+$int_scale);
						}
						else {
							# intersection happens only at infinite offset time
							# die "PGON offset dying at 281 with $bis_scale[$n] and $int_scale\n";
						}
					}
					else {
							# 1 / $int_scale is arbitrary large so division reduces to 0
							$time_static = 0;
					}
					# once you have calculated the time, you need to see if the
					# intersected segment is still in that place at that time to be struck by the ray
					# Does time_dir belong here? (yes for test case A)
					$Bx1 = $points->[$n2][0] + $time_static  * $bis_scale[$n2] * cos($bis_dir[$n2]);
					$By1 = $points->[$n2][1] + $time_static  * $bis_scale[$n2] *  sin($bis_dir[$n2]);
					$Bx2 = $points->[$n2 + 1 - $npoints][0] + $time_static * $bis_scale[$next] * cos($bis_dir[$next]);
					$By2 = $points->[$n2 + 1 - $npoints][1] + $time_static * $bis_scale[$next] * sin($bis_dir[$next]);
					if(! _do_cross($Ax1,$Ay1,$Ax2,$Ay2,$Bx1,$By1,$Bx2,$By2) ) {
						next;
					}
					$time = $time_static;
					# make sure the case controls and is in the right direction.  (required for case A)
					# dvdp: replaced division by abs($time) by a multiplication to overcome
					#       potential divide by 0
					if( (abs($time)<$first_time)  and ( $time == $time_dir * abs($time) ) ) {
						# note that none of the times loaded here have a sign
						$first_time = abs($time);
						$split_time = $first_time;
						$first_split=$n;
						$split_seg = $n2;
						$first_event="split";
					}
				}
			} # end for n2
		} # end for n (each bisector verses each edge)
	} # End if not triangle
	
	# Time is the smallest relavent split time (unless join controls)
	# first_split is address of point to be split.
	# first_event is "split" if controlling (could be controlled by join)(or nothing)
	# If this is the controlling case, create the split polygons at that offset time
	# and make a recursive call.
	
	if($first_time <= abs($offset)) {
		if($debug) {
			if($first_event eq "join") {
				printf("join vertex %d at time %6.2f\n",$first_join,$first_time);
			}
			if($first_event eq "split") {
				printf(
					"split segment %d with vertex %d at time %6.2f\n",
					$split_seg,$first_split,$first_time
					);
			}
			print "\ttime:  $first_time\n";
		}
		# get a list of points for the offset polygon at first_time

		if($first_event eq "join") {
			# How are coincident events handled?
			# remove the offending point and call yourself with time adjusted.
			@newpoints = ();
			for($n = 0; $n<$npoints; $n++) {
				$newpoints[$n][0] = $points->[$n][0] + $first_time *
					$time_dir* $bis_scale[$n] * cos($bis_dir[$n]);
				$newpoints[$n][1] = $points->[$n][1] + $first_time *
					$time_dir* $bis_scale[$n] * sin($bis_dir[$n]);
			}
			# keep the one with the smaller scale.
			if($bis_scale[$first_join]<$bis_scale[$first_join+1]) {
				splice(@newpoints, $first_join + 1, 1);
			}
			else {
				splice(@newpoints, $first_join , 1);
			}
			$npoints--;
			$new_offset = $offset - $first_time * $time_dir;  # put a direction on it.
			$offset_depth++;
			@outlist = OffsetPolygon(\@newpoints,$new_offset) ;
			$offset_depth--;
			return(@outlist);
		}
		elsif ($first_event eq "split") {
			# make two polygons and call yourself with time adjusted.
			@newpoints = ();
			my @split_check;
			my @split_check1;
			for($n = 0; $n<$npoints; $n++) {
				$newpoints[$n][0] = $points->[$n][0] + $first_time *
						$time_dir * $bis_scale[$n] * cos($bis_dir[$n]);
				$newpoints[$n][1]  = $points->[$n][1] + $first_time *
						$time_dir * $bis_scale[$n] * sin($bis_dir[$n]);
				$split_check[$n] = $n;
			}
			$new_offset = $offset - $first_time * $time_dir;
			@newpoints1 = ();
			@newpoints1 = @newpoints;
				@split_check1 = ();
				@split_check1 = @split_check;
			# have first_split and split_seg, must find a way to wrap around.
			my $cut_startA;
			my $cut_startB;
			my $cutB;
			if($split_seg < $first_split) {
				$cut1 = $#newpoints - $first_split;
				$cut2 = $split_seg+1;
				$cut_startA=$first_split+1;
				$cut_startB = $split_seg+1;
				$cutB = $first_split - $split_seg -1;
			}
			else {
				$cut1 = $#newpoints - $split_seg;
				$cut2 = $first_split;
				$cut_startA = $split_seg +1;
				$cut_startB = $first_split + 1;
				$cutB = $split_seg - $first_split;
			}
			splice(@newpoints,$cut_startA,$cut1);
			splice(@newpoints,0,$cut2);
			splice(@split_check,$cut_startA,$cut1);
			splice(@split_check,0,$cut2);
			splice(@newpoints1,$cut_startB,$cutB);
			splice(@split_check1,$cut_startB,$cutB);
			my $num = @newpoints;
			my $num1 = @newpoints1;

			if($debug) {
				print "split was:\n@split_check\n@split_check1\n";
				print "first splitted:\n";
				for($n = 0; $n<$num;$n++) {
					printf ("point: %d  (%6.2f,%6.2f)\n",$n,@{$newpoints[$n]});
				}
				print "second splitted:\n";
				for($n = 0; $n < $num1;$n++) {
					printf ("point: %d  (%6.2f,%6.2f)\n",$n,@{$newpoints1[$n]});
				}
			}
			$#result1 = 0;
			shift(@result1);
			$#result2 = 0;
			shift(@result2);
			if($num>2) {
				$offset_depth++;
				@result1 = OffsetPolygon(\@newpoints,$new_offset);
				$offset_depth--;
			}
			else {
				$debug and print "too few on first\n";
			}
			if($num1>2) {
				$offset_depth++;	
				@result2 = OffsetPolygon(\@newpoints1,$new_offset);
				$offset_depth--;
			}
			else {
				$debug and print "too few on second\n";
			}
			return(@result1, @result2);  # This concatenates the list.
		} # end elsif split
	} # end if time <= offset
	else {
		# No splits or joins needed, so offset the thing.
		# Bisector endpoints should be available.
		@newpoints = ();
		for($n = 0; $n<$npoints; $n++) {
			$newpoints[$n][0] = $points->[$n][0] + $offset * $bis_scale[$n] * cos($bis_dir[$n]);
			$newpoints[$n][1] = $points->[$n][1] + $offset * $bis_scale[$n] * sin($bis_dir[$n]);
		}
		return( \@newpoints);
	}
}  # End offset polygon subroutine definition
#########################################################################
# Find  direction subroutine.
# Called with (<Polygon points>,<changes in angle>, <angles>).
# Returns total change in angle (as radians (everything is as radians)).
# Second two array refs are optional.
# Forcing counter-clockwise currently not done here, but maybe should.
sub _find_direction {
	my($coords,$del_theta,$thetas) = @_;
	my $sum_theta=0;
	my $sum_delta_theta = 0;
	@{$del_theta} = ();        # Clear arrays referenced for in-place modification.
	@{$thetas}    = ();
	my $n = 0;
	for(;;) {
		last if ($n == @{$coords});
		# dvdp: take advantage of negative indexing in Perl
		my $n2 = $n - @{$coords} + 1;
		my $n3 = $n - 1;
		my $Ax1 = ${$coords}[$n][0];   # Line leaving point
		my $Ay1 = ${$coords}[$n][1];   # this is the one belonging to the point
		my $Ax2 = ${$coords}[$n2][0];
		my $Ay2 = ${$coords}[$n2][1];
		my $delAx = $Ax2 - $Ax1;
		my $delAy = $Ay2 - $Ay1;
		my $Bx1 = ${$coords}[$n3][0];  # Line coming to point n
		my $By1 = ${$coords}[$n3][1];
		my $Bx2 = ${$coords}[$n][0];
		my $By2 = ${$coords}[$n][1];
		my $delBx = $Bx2 - $Bx1;
		my $delBy = $By2 - $By1;
		# dvdp remove coinciding points
		if ( ((abs($delAx) < $delta) && (abs($delAy) < $delta)) ||
				 ((abs($delBx) < $delta) && (abs($delBy) < $delta)) ) {
			splice @{$coords},$n,1;
			next;
		}
		my $theta_A = atan2($delAy,$delAx);    # Angle of leaving line
		my $theta_B = atan2($delBy,$delBx);    # Angle of coming line
		my $theta_AB = $theta_A - $theta_B;
		if ($theta_AB < -(pi)) {
			$theta_AB += 2 * (pi);
		}
		elsif ($theta_AB > (pi)) {
			$theta_AB -= 2 * (pi);
		}
		if( (abs($theta_AB - (pi)) < $delta) ) {
			splice @{$coords},$n,1;
			$n and $n--; # need to recalc thetas if spike removed !
			next;
		}
		${$thetas}[$n]    = $theta_A;
		${$del_theta}[$n] = $theta_AB;
		$n++
	}
}  # End _find_direction sub
#########################################################################
# Determines if a pair of line segments have an intersection.
sub _do_cross {
	my ($Ax1,$Ay1,$Ax2,$Ay2,$Bx1,$By1,$Bx2,$By2) = @_;
	# Calculate four relevant minor determinants
	my $det_123=($Ax2 - $Ax1)*($By1 - $Ay1) - ($Bx1 - $Ax1)*($Ay2 - $Ay1);
	my $det_124=($Ax2 - $Ax1)*($By2 - $Ay1) - ($Bx2 - $Ax1)*($Ay2 - $Ay1);
	my $det_341=($Bx1 - $Ax1)*($By2 - $Ay1) - ($Bx2 - $Ax1)*($By1 - $Ay1);
	my $det_342 =$det_123-$det_124+$det_341;
	if( ($det_123*$det_124 > 0) || ($det_341*$det_342 > 0) ) {
		return(0);  # segments only intersect if the above two products are both negative
	}
	else {
		return(1);
	}
}  # End _do_cross subroutine definition
########################################################################

1;
