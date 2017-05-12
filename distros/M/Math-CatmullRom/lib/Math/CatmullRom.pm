###########################################################################
#
# Math::CatmullRom
#
# $Id: CatmullRom.pm,v 1.1.1.1 2003/08/31 16:53:16 wiggly Exp $
#
# $Author: wiggly $
#
# $Revision: 1.1.1.1 $
#
###########################################################################

package Math::CatmullRom;

use strict;

use Data::Dumper;

our $VERSION = '0.00';


###########################################################################
#
# new
#
###########################################################################
sub new
{
	my $class = shift;

	# control points
	my @p = @_;
	
	my $self = {};

	$self = bless $self, $class;

	$self->control_points( @p );

	$self->plot_all( 0 );

	return $self;
}


###########################################################################
#
# control_points
#
###########################################################################
sub control_points
{
	my $self = shift;

	my @p = @_;

	# make sure we have enough points	
	if( ( scalar( @p ) / 2 ) < 4 )
	{
		die "passed too few control points, minimum is 4 pairs.\n";
	}
	
	# make sure we have an even amount of points	
	if( scalar( @p ) % 2 )
	{
		die "passed odd number of control points.\n";
	}
	
	$self->{'p'} = \@p;

	# pre-calculate some useful values 
	$self->{'np'} = scalar( @p ) / 2;
	$self->{'nl'} = $self->{'np'} - 3;

	#print STDERR "NP : " . $self->{'np'} . "\n";
	#print STDERR "NL : " . $self->{'nl'} . "\n";
	
	return 1;
}


###########################################################################
#
# plot_all
#
###########################################################################
sub plot_all
{
	my $self = shift;

	my $all = shift
		or 1;

	$self->{'plot_all'} = $all;

	return 1;
}


###########################################################################
#
# point
#
###########################################################################
sub point
{
	my $self = shift;

	my $theta = shift;

	my @p = ();

	my ( $segment, $ps, $pf );

	#print STDERR "TH : $theta\n";

	# figure out where along the total curve we are
	$theta = $theta * $self->{'nl'};

	#print STDERR "TH : $theta\n";

	# figure out which segment we are plotting for
	$segment = int( $theta );

	# calculate theta within segment
	$theta = $theta - $segment;

	#print STDERR "TH : $theta\n";

	$ps = $segment * 2;

	$pf = ( ( $segment + 3 ) * 2 ) + 1;

	#print STDERR "PS : $ps\n";
	#print STDERR "PF : $pf\n";
	
	#print STDERR "POINTS : " . join( ',', ( @{$self->{'p'}}[ $ps .. $pf ] ) ) . "\n";

	#print STDERR "DUMP : " . Dumper( ( @{$self->{'p'}}[ $ps .. $pf ] ) ) . "\n";

	push @p, catmull_rom( $theta, ( @{$self->{'p'}}[ $ps .. $pf ] ) );

	return wantarray ? @p : \@p;
}


###########################################################################
#
# curve
#
###########################################################################
sub curve
{
	my $self = shift;
	
	my $num = shift;

	my $per_segment = shift
		or 0;

	# list of points on curve
	my @p = ();
	
	# if we want to plot per-segemnt then we multiply our number of required
	# points by the number of segments in our line	
	if( $per_segment )
	{
		$num = $num * $self->{'nl'};
	}
	
	# figure out what our theta increment is
	my $increment = 1 / $num;

	my ( $point, $theta );
	
	$theta = 0;
	
	# plot every point and push it onto our return array
	for( $point = 0; $point < $num; $point++ )
	{
		$theta = $point * $increment;
		push @p, $self->point( $theta );
	}
	push @p, $self->point( 1.0 );

	# return as an array or reference depending on context	
	return wantarray ? @p : \@p;
}


###########################################################################
#
# catmull_rom
#
###########################################################################
sub catmull_rom
{
	my ( $t, $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4 ) = @_;

	my $t2 = $t * $t;
	my $t3 = $t2 * $t;

	return (
		( 0.5
		* ( ( - $x1 + 3 * $x2 -3 * $x3 + $x4 ) * $t3
		+ ( 2 * $x1 -5 * $x2 + 4 * $x3 - $x4 ) * $t2
		+ ( -$x1 + $x3 ) * $t
		+ 2 * $x2 ) )
		,
		( 0.5
		* ( ( - $y1 + 3 * $y2 -3 * $y3 + $y4 ) * $t3
		+ ( 2 * $y1 -5 * $y2 + 4 * $y3 - $y4 ) * $t2
		+ ( -$y1 + $y3 ) * $t
		+ 2 * $y2 ) )
	);

#	return 0.5
#		* ( ( - $p1 + 3 * $p2 -3 * $p3 + $p4 ) * $t * $t * $t
#		+ ( 2 * $p1 -5 * $p2 + 4 * $p3 - $p4 ) * $t * $t
#		+ ( -$p1 + $p3 ) * $t
#		+ 2 * $p2 );
}


###########################################################################
1;

=pod

=head1 NAME

Math::CatmullRom - Calculate Catmull-Rom splines

=head1 SYNOPSIS

	use Math::CatmullRom;

	# create curve passing through list of control points
	my $curve = new Math::CatmullRom( $x1, $y1, $x2, $y2, ..., $xn, $yn );

	# or pass reference to list of control points
	my $curve = new Math::CatmullRom( [ $x1, $y1, $x2, $y2, ..., $xn, $yn ] );

	# determine (x, y) at point along curve, range 0.0 -> 1.0
	my ($x, $y) = $curve->point( 0.5 );

	# returns list ref in scalar context
	my $xy = $curve->point( 0.5 );

	# return list of 20 (x, y) points along curve
	my @curve = $curve->curve( 20 );

	# returns list ref in scalar context
	my $curve = $curve->curve( 20 );

	# include start and finish points by adding false data points
	$curve->plot_all;

=head1 DESCRIPTION

This module provides an algorithm to generate plots for Catmull-Rom splines.

A Catmull-Rom spline can be considered a special type of Bezier curve that
guarantees that the curve will cross every control point starting at the
second point and terminating at the penultimate one. For this reason the
minimum number of control points is 4.

To plot a curve where you have a set of points but want the curve to be
drawn through the start and finish points you can tell the module to plot
all of the points. In this case it assumes that there are two extra points,
prior to the start point with the same values as the start point and one
prior to the finish point with the same values as the finish point. This is
really just a convenience function for certain kinds of plot.

A new Catmull-Rom spline is created using the new() constructor, passing a
list of control points.

	use Math::CatmullRom;

	# create curve passing through list of control points 
	my @control = ( $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4 );
	my $spline = new Math::CatmullRom( @control );

Alternatively, a reference to a list of control points may be passed.

	# or pass reference to list of control points
	my $spline = new Math::CatmullRom( \@control );

The point( $theta ) method can be called on the object, passing a value in
the range 0.0 to 1.0 which represents the distance along the spline.  When
called in list context, the method returns the x and y coordinates of that
point on the curve.

	my ( $x, $y ) = $curve->plot( 0.75 );
	print "X : $x\nY : $y\n";

When called in a scalar context, it returns a reference to a list containing
the X and Y coordinates.

	my $point = $curve->plot( 0.75 );
	print "X : $point->[0]\nY : $point->[1]\n";

The curve( $n, $per_segment ) method can be used to return a set of points
sampled along the length of the curve (i.e. in the range 0.0 <= $theta <=
1.0).

The parameter indicates the number of sample points required. The method
returns a list of ($x1, $y1, $x2, $y2, ..., $xn, $yn) points when called in
list context, or a reference to such an array when called in scalar context.

The $per_segment parameter determines whether $n points total will be plotted
or $n points between every point, defaulting to $n points total.

	my @points = $curve->curve( 10, 1 );

	while( @points )
	{
		my ( $x, $y ) = splice( @points, 0, 2 );
		print "X : $x\nY : $y\n";
	}

	my $points = $curve->curve( 50 );

	while( @$points )
	{
		my ( $x, $y ) = splice( @$points, 0, 2 );
		print "X : $x\nY : $y\n";
	}

=head1 TODO

Test, test, test.

=head1 BUGS

None known so far. Please report any and all to Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SUPPORT / WARRANTY

This module is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 LICENSE

The Math::CatmullRom module is Copyright (c) 2003 Nigel Rantor. England. All
rights reserved.

You may distribute under the terms of either the GNU General Public License
or the Artistic License, as specified in the Perl README file.

=head1 AUTHORS

Nigel Rantor <F<wiggly@wiggly.org>>

=head1 SEE ALSO

L<Math::Bezier>.

=cut
