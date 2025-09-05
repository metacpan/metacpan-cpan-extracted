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

package Math::Polygon;{
our $VERSION = '2.00';
}


use strict;
use warnings;

use Log::Report     'math-polygon';

# Include all implementations
use Math::Polygon::Calc;
use Math::Polygon::Clip;
use Math::Polygon::Transform;

#--------------------

sub new(@)
{	my $thing = shift;
	my $class = ref $thing || $thing;

	my @points;
	my %options;
	if(ref $thing)
	{	$options{clockwise} = $thing->{MP_clockwise};
	}

	while(@_)
	{	if(ref $_[0] eq 'ARRAY') { push @points, shift }
		else { my $k = shift; $options{$k} = shift }
	}
	$options{_points} = \@points;

	(bless {}, $class)->init(\%options);
}

sub init($$)
{	my ($self, $args) = @_;
	$self->{MP_points}    = $args->{points} || $args->{_points};
	$self->{MP_clockwise} = $args->{clockwise};
	$self->{MP_bbox}      = $args->{bbox};
	$self;
}

#--------------------

sub nrPoints() { scalar @{ $_[0]->{MP_points}} }


sub order() { @{ $_[0]->{MP_points}} -1 }


sub points(;$)
{	my ($self, $format) = @_;
	my $points = $self->{MP_points};
	$points    = [ polygon_format $format, @$points ] if $format;
	wantarray ? @$points : $points;
}


sub point(@)
{	my $points = shift->{MP_points};
	wantarray ? @{$points}[@_] : $points->[shift];
}

#--------------------

sub bbox()
{	my $self = shift;
	return @{$self->{MP_bbox}} if $self->{MP_bbox};

	my @bbox = polygon_bbox $self->points;
	$self->{MP_bbox} = \@bbox;
	@bbox;
}


sub area()
{	my $self = shift;
	return $self->{MP_area} if defined $self->{MP_area};
	$self->{MP_area} = polygon_area $self->points;
}


sub centroid(%)
{	my ($self, %args) = @_;
	$self->{MP_centroid} //= polygon_centroid \%args, $self->points;
}


sub isClockwise()
{	my $self = shift;
	return $self->{MP_clockwise} if defined $self->{MP_clockwise};  # undef == unknown here
	$self->{MP_clockwise} = (polygon_is_clockwise $self->points) || 0;
}


sub clockwise()
{	my $self = shift;
	return $self if $self->isClockwise;

	$self->{MP_points}    = [ reverse $self->points ];
	$self->{MP_clockwise} = 1;
	$self;
}


sub counterClockwise()
{	my $self = shift;
	$self->isClockwise or return $self;

	$self->{MP_points}    = [ reverse $self->points ];
	$self->{MP_clockwise} = 0;
	$self;
}


sub perimeter() { polygon_perimeter $_[0]->points }


sub startMinXY()
{	my $self = shift;
	$self->new(polygon_start_minxy $self->points);
}


sub beautify(@)
{	my ($self, %args) = @_;
	my @beauty = polygon_beautify \%args, $self->points;
	@beauty > 2 ? $self->new(points => \@beauty) : ();
}


sub equal($;@)
{	my $self  = shift;
	my ($other, $tolerance);
	if(@_ > 2 || ref $_[1] eq 'ARRAY') { $other = \@_ }
	else
	{	$other     = ref $_[0] eq 'ARRAY' ? shift : shift->points;
		$tolerance = shift;
	}
	polygon_equal scalar($self->points), $other, $tolerance;
}


sub same($;@)
{	my $self = shift;
	my ($other, $tolerance);
	if(@_ > 2 || ref $_[1] eq 'ARRAY') { $other = \@_ }
	else
	{	$other     = ref $_[0] eq 'ARRAY' ? shift : shift->points;
		$tolerance = shift;
	}
	polygon_same scalar($self->points), $other, $tolerance;
}


sub contains($)
{	my ($self, $point) = @_;
	polygon_contains_point($point, $self->points);
}


sub distance($)
{	my ($self, $point) = @_;
	polygon_distance($point, $self->points);
}


sub isClosed() { polygon_is_closed($_[0]->points) }

#--------------------

sub resize(@)
{	my ($self, %args) = @_;

	my $clockwise = $self->{MP_clockwise};
	if(defined $clockwise)
	{	my %args   = @_;
		my $xscale = $args{xscale} || $args{scale} || 1;
		my $yscale = $args{yscale} || $args{scale} || 1;
		$clockwise = not $clockwise if $xscale * $yscale < 0;
	}

	(ref $self)->new(
		points    => [ polygon_resize \%args, $self->points ],
		clockwise => $clockwise,
		# we could save the bbox calculation as well
	);
}


sub move(%)
{	my ($self, %args) = @_;

	(ref $self)->new(
		points    => [ polygon_move \%args, $self->points ],
		clockwise => $self->{MP_clockwise},
		bbox      => $self->{MP_bbox},
	);
}


sub rotate(%)
{	my ($self, %args) = @_;

	(ref $self)->new(
		points    => [ polygon_rotate \%args, $self->points ],
		clockwise => $self->{MP_clockwise},
		# we could save the bbox calculation as well
	);
}


sub grid(%)
{	my ($self, %args) = @_;

	(ref $self)->new(
		points    => [ polygon_grid \%args, $self->points ],
		clockwise => $self->{MP_clockwise},
		# probably we could save the bbox calculation as well
	);
}


sub mirror(@)
{	my ($self, %args) = @_;

	my $clockwise = $self->{MP_clockwise};
	$clockwise    = not $clockwise if defined $clockwise;

	(ref $self)->new(
		points    => [ polygon_mirror \%args, $self->points ],
		clockwise => $clockwise,
		# we could save the bbox calculation as well
	);
}


sub simplify(@)
{	my ($self, %args) = @_;

	(ref $self)->new(
		points    => [ polygon_simplify \%args, $self->points ],
		clockwise => $self->{MP_clockwise},
		bbox      => $self->{MP_bbox},       # protect bounds
	);
}

#--------------------

sub lineClip($$$$)
{	my ($self, @bbox) = @_;
	polygon_line_clip \@bbox, $self->points;
}


sub fillClip1($$$$)
{	my ($self, @bbox) = @_;
	my @clip = polygon_fill_clip1 \@bbox, $self->points;
	@clip ? $self->new(points => \@clip) : undef;
}

#--------------------

sub string(;$)
{	my ($self, $format) = @_;
	polygon_string $self->points($format);
}

1;
