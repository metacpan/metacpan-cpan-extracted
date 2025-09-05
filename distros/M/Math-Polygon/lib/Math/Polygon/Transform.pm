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

package Math::Polygon::Transform;{
our $VERSION = '2.00';
}

use parent 'Exporter';

use strict;
use warnings;

use Log::Report  'math-polygon';
use Math::Trig   qw/deg2rad pi rad2deg/;
use POSIX        qw/floor/;

our @EXPORT = qw/
	polygon_resize
	polygon_move
	polygon_rotate
	polygon_grid
	polygon_mirror
	polygon_simplify
/;

#--------------------

sub polygon_resize(@)
{	my $args;
	if(ref $_[0] eq 'HASH') { $args = shift }
	else
	{	while(@_ && !ref $_[0])
		{	my $key       = shift;
			$args->{$key} = shift;
		}
	}

	my $sx = $args->{xscale} || $args->{scale} || 1.0;
	my $sy = $args->{yscale} || $args->{scale} || 1.0;
	return @_ if $sx==1.0 && $sy==1.0;

	my ($cx, $cy)   = defined $args->{center} ? @{$args->{center}} : (0,0);

	    $cx || $cy
	  ? map +[ $cx + ($_->[0]-$cx)*$sx,  $cy + ($_->[1]-$cy) * $sy ], @_
	  : map +[ $_->[0]*$sx, $_->[1]*$sy ], @_;
}


sub polygon_move(@)
{	my $args;
	if(ref $_[0] eq 'HASH') { $args = shift }
	else
	{	while(@_ && !ref $_[0])
		{	my $key       = shift;
			$args->{$key} = shift;
		}
	}

	my ($dx, $dy) = ($args->{dx}||0, $args->{dy}||0);
	return @_ if $dx==0 && $dy==0;

	map +[ $_->[0] +$dx, $_->[1] +$dy ], @_;
}


sub polygon_rotate(@)
{	my $args;
	if(ref $_[0] eq 'HASH') { $args = shift }
	else
	{	while(@_ && !ref $_[0])
		{	my $key       = shift;
			$args->{$key} = shift;
		}
	}

	my $angle
	  = exists $args->{radians} ? $args->{radians}
	  : exists $args->{degrees} ? deg2rad($args->{degrees})
	  :                           0;

	$angle
		or return @_;

	my $sina = sin($angle);
	my $cosa = cos($angle);

	my ($cx, $cy) = defined $args->{center} ? @{$args->{center}} : (0,0);
	$cx || $cy or return map +[
		 $cosa * $_->[0] + $sina * $_->[1],
		-$sina * $_->[0] + $cosa * $_->[1],
	], @_;

	map +[
		$cx +  $cosa * ($_->[0]-$cx) + $sina * ($_->[1]-$cy),
		$cy + -$sina * ($_->[0]-$cx) + $cosa * ($_->[1]-$cy),
	], @_;
}


sub polygon_grid(@)
{	my $args;
	if(ref $_[0] eq 'HASH') { $args = shift }
	else
	{	while(@_ && !ref $_[0])
		{	my $key       = shift;
			$args->{$key} = shift;
		}
	}

	my $raster = exists $args->{raster} ? $args->{raster} : 1;
	return @_ if $raster == 0;

	# use fast "int" for gridsize 1
	return map +[ floor($_->[0] + 0.5), floor($_->[1] + 0.5) ], @_
		if $raster > 0.99999 && $raster < 1.00001;

	map +[ $raster * floor($_->[0]/$raster + 0.5), $raster * floor($_->[1]/$raster + 0.5) ], @_;
}


sub polygon_mirror(@)
{	my $args;
	if(ref $_[0] eq 'HASH') { $args = shift }
	else
	{	while(@_ && !ref $_[0])
		{	my $key       = shift;
			$args->{$key} = shift;
		}
	}

	if(defined $args->{x})
	{	my $x2 = 2* $args->{x};
		return map +[ $x2 - $_->[0], $_->[1] ], @_;
	}

	if(defined $args->{y})
	{	my $y2 = 2* $args->{y};
		return map +[ $_->[0], $y2 - $_->[1] ], @_;
	}

	# Mirror in line

	my ($rc, $b);
	if(exists $args->{rc} )
	{	$rc = $args->{rc};
		$b  = $args->{b} || 0;
	}
	elsif(my $through = $args->{line})
	{	my ($p0, $p1) = @$through;
		if($p0->[0]==$p1->[0])
		{	$b = $p0->[0];      # vertical mirror
		}
		else
		{	$rc = ($p1->[1] - $p0->[1]) / ($p1->[0] - $p0->[0]);
			$b  = $p0->[1] - $p0->[0] * $rc;
		}
	}
	else
	{	error __"you need to specify 'x', 'y', 'rc', or 'line'";
	}

	unless(defined $rc)    # vertical
	{	my $x2 = 2* $b;
		return map +[ $x2 - $_->[0], $_->[1] ], @_;
	}

	# mirror is y=x*rc+b, y=-x/rc+c through mirrored point
	my $yf = 2/($rc*$rc +1);
	my $xf = $yf * $rc;

	map { my $c = $_->[1] + $_->[0]/$rc;
		+[ $xf*($c-$b) - $_->[0], $yf*($b-$c) + 2*$c - $_->[1] ]
	} @_;
}


sub _angle($$$)
{	my ($p0, $p1, $p2) = @_;
	my $a0 = atan2($p0->[1] - $p1->[1], $p0->[0] - $p1->[0]);
	my $a1 = atan2($p2->[1] - $p1->[1], $p2->[0] - $p1->[0]);
	my $a  = abs($a0 - $a1);
	$a = 2*pi - $a    if $a > pi;
	$a;
}

sub polygon_simplify(@)
{	my $args;
	if(ref $_[0] eq 'HASH') { $args = shift }
	else
	{	while(@_ && !ref $_[0])
		{	my $key       = shift;
			$args->{$key} = shift;
		}
	}

	@_ or return ();

	my $is_ring     = $_[0][0]==$_[-1][0] && $_[0][1]==$_[-1][1];
	my $same        = $args->{same} || 0.0001;
	my $slope       = $args->{slope};
	my $changes     = 1;

	while($changes && @_)
	{	$changes    = 0;
		my @new;

		my $p       = shift;
		while(@_)
		{	my ($x, $y)   = @$p;

			my ($nx, $ny) = @{$_[0]};
			my $d01 = sqrt(($nx-$x)*($nx-$x) + ($ny-$y)*($ny-$y));
			if($d01 < $same)
			{	$changes++;

				# point within threshold: middle, unless we are at the
				# start of the polygo description: that one has a slight
				# preference, to avoid an endless loop.
				push @new, !@new ? [ ($x,$y) ] : [ ($x+$nx)/2, ($y+$ny)/2 ];
				shift;            # remove next
				$p       = shift; # 2nd as new current
				next;
			}

			unless(@_ >= 2 && defined $slope)
			{	push @new, $p;     # keep this
				$p       = shift;  # check next
				next;
			}

			my ($sx,$sy) = @{$_[1]};
			my $d12 = sqrt(($sx-$nx)*($sx-$nx) + ($sy-$ny)*($sy-$ny));
			my $d02 = sqrt(($sx-$x) *($sx-$x)  + ($sy-$y) *($sy-$y) );

			if($d01 + $d12 <= $d02 + $slope)
			{	# three points nearly on a line, remove middle
				$changes++;
				push @new, $p, $_[1];
				shift; shift;
				$p         = shift;  # jump over next
				next;
			}

			if(@_ > 2 && abs($d01-$d12-$d02) < $slope)
			{	# check possibly a Z shape
				my ($tx,$ty) = @{$_[2]};
				my $d03 = sqrt(($tx-$x) *($tx-$x)  + ($ty-$y) *($ty-$y));
				my $d13 = sqrt(($tx-$nx)*($tx-$nx) + ($ty-$ny)*($ty-$ny));

				if($d01 - $d13 <= $d03 + $slope)
				{	$changes++;
					push @new, $p, $_[2];  # accept 1st and 4th
					splice @_, 0, 3;       # jump over handled three!
					$p = shift;
					next;
				}
			}

			push @new, $p;   # nothing for this one.
			$p = shift;
		}
		push @new, $p if defined $p;

		unshift @new, $new[-1]    # be sure to keep ring closed
			if $is_ring && ($new[0][0]!=$new[-1][0] || $new[0][1]!=$new[-1][1]);

		@_ = @new;
	}

	exists $args->{max_points}
		or return @_;

	#
	# Reduce the number of points to $max
	#

	# Collect all angles
	my $max_angles = $args->{max_points};
	my @angles;

	if($is_ring)
	{	return @_ if @_ <= $max_angles;
		pop @_;
		push @angles, [0, _angle($_[-1], $_[0], $_[1])], [$#_, _angle($_[-2], $_[-1], $_[0])];
	}
	else
	{	return @_ if @_ <= $max_angles;
		$max_angles -= 2;
	}

	foreach (my $i=1; $i<@_-1; $i++)
	{	push @angles, [$i, _angle($_[$i-1], $_[$i], $_[$i+1]) ];
	}

	# Strip widest angles
	@angles = sort { $b->[1] <=> $a->[1] } @angles;
	while(@angles > $max_angles)
	{	my $point = shift @angles;
		$_[$point->[0]] = undef;
	}

	# Return left-over points
	@_ = grep defined, @_;
	push @_, $_[0] if $is_ring;
	@_;
}

1;
