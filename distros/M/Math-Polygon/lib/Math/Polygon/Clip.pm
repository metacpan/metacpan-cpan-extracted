# This code is part of Perl distribution Math-Polygon version 2.00.
# The POD got stripped from this file by OODoc version 3.03.
# For contributors see file ChangeLog.

# This software is copyright (c) 2004-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Math::Polygon::Clip;{
our $VERSION = '2.00';
}

use parent 'Exporter';

use strict;
use warnings;

our @EXPORT = qw/
	polygon_line_clip
	polygon_fill_clip1
/;

use Log::Report  'math-polygon';
use List::Util    qw/min max/;

use Math::Polygon::Calc;

sub _inside($$);
sub _cross($$$);
sub _cross_inside($$$);
sub _cross_x($$$);
sub _cross_y($$$);
sub _remove_doubles(@);

#--------------------

sub polygon_fill_clip1($@)
{	my $bbox = shift;
	my ($xmin, $ymin, $xmax, $ymax) = @$bbox;
	@_ or return ();  # empty list of points

	# Collect all crosspoints with axes, plus the original points
	my $next   = shift;
	my @poly   = $next;
	while(@_)
	{	$next  = shift;
		push @poly, _cross($bbox, $poly[-1], $next), $next;
	}

	# crop them to the borders: outside is projected on the sides
	my @cropped;
	foreach (@poly)
	{	my ($x,$y) = @$_;
		$x = $xmin if $x < $xmin;
		$x = $xmax if $x > $xmax;
		$y = $ymin if $y < $ymin;
		$y = $ymax if $y > $ymax;
		push @cropped, [$x, $y];
	}

	polygon_beautify +{despike => 1}, @cropped;
}


sub polygon_line_clip($@)
{	my $bbox = shift;
	my ($xmin, $ymin, $xmax, $ymax) = @$bbox;

	my @frags;
	my $from   = shift;
	my $fromin = _inside $bbox, $from;
	push @frags, [ $from ] if $fromin;

	while(@_)
	{	my $next   = shift;
		my $nextin = _inside $bbox, $next;

		if($fromin && $nextin)       # stay within
		{	push @{$frags[-1]}, $next;
		}
		elsif($fromin && !$nextin)   # leaving
		{	push @{$frags[-1]}, _cross_inside $bbox, $from, $next;
		}
		elsif($nextin)               # entering
		{	my @cross = _cross_inside $bbox, $from, $next;
			push @frags, [ @cross, $next ];
		}
		else                         # pass thru bbox?
		{	my @cross = _cross_inside $bbox, $from, $next;
			push @frags, \@cross if @cross;
		}

		($from, $fromin) = ($next, $nextin);
	}

	# Glue last to first?
	if(   @frags >= 2
		&& $frags[0][0][0] == $frags[-1][-1][0]  # X
		&& $frags[0][0][1] == $frags[-1][-1][1]  # Y
	)
	{	my $last = pop @frags;
		pop @$last;
		unshift @{$frags[0]}, @$last;
	}

	@frags;
}

#
### Some helper functions
#

sub _inside($$)
{	my ($bbox, $point) = @_;

		$bbox->[0] <= $point->[0]+0.00001
	&& $point->[0] <=  $bbox->[2]+0.00001  # X
	&&  $bbox->[1] <= $point->[1]+0.00001
	&& $point->[1] <=  $bbox->[3]+0.00001; # Y
}

sub _sector($$)  # left-top 678,345,012 right-bottom
{	my ($bbox, $point) = @_;
	my $xsector = $point->[0] < $bbox->[0] ? 0
				: $point->[0] < $bbox->[2] ? 1
				:                            2;
	my $ysector = $point->[1] < $bbox->[1] ? 0
				: $point->[1] < $bbox->[3] ? 1
				:                            2;
	$ysector * 3 + $xsector;
}

sub _cross($$$)
{	my ($bbox, $from, $to) = @_;
	my ($xmin, $ymin, $xmax, $ymax) = @$bbox;

	my @cross = (
		_cross_x($xmin, $from, $to),
		_cross_x($xmax, $from, $to),
		_cross_y($ymin, $from, $to),
		_cross_y($ymax, $from, $to),
	);

	# order the results
	$from->[0] < $to->[0] ? sort({$a->[0] <=> $b->[0]} @cross)
	: $from->[0] > $to->[0] ? sort({$b->[0] <=> $a->[0]} @cross)
	: $from->[1] < $to->[1] ? sort({$a->[1] <=> $b->[1]} @cross)
	:                         sort({$b->[1] <=> $a->[1]} @cross);
}

sub _cross_inside($$$)
{	my ($bbox, $from, $to) = @_;
	grep _inside($bbox, $_), _cross($bbox, $from, $to);
}

sub _remove_doubles(@)
{	my $this = shift or return ();
	my @ret  = $this;
	while(@_)
	{	my $this = shift;
		next if $this->[0]==$ret[-1][0] && $this->[1]==$ret[-1][1];
		push @ret, $this;
	}
	@ret;
}

sub _cross_x($$$)
{	my ($x, $from, $to) = @_;
	my ($fx, $fy) = @$from;
	my ($tx, $ty) = @$to;
	return () unless $fx < $x && $x < $tx || $tx < $x && $x < $fx;
	my $y = $fy + ($x - $fx)/($tx - $fx) * ($ty - $fy);
	(($fy <= $y && $y <= $ty) || ($ty <= $y && $y <= $fy)) ? [$x,$y] : ();
}

sub _cross_y($$$)
{	my ($y, $from, $to) = @_;
	my ($fx, $fy) = @$from;
	my ($tx, $ty) = @$to;
	return () unless $fy < $y && $y < $ty || $ty < $y && $y < $fy;
	my $x = $fx + ($y - $fy)/($ty - $fy) * ($tx - $fx);
	(($fx <= $x && $x <= $tx) || ($tx <= $x && $x <= $fx)) ? [$x,$y] : ();
}



1;
