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

package Math::Polygon::Surface;{
our $VERSION = '2.00';
}


use strict;
use warnings;

use Log::Report   'math-polygon';
use Scalar::Util  qw/blessed/;

use Math::Polygon ();

#--------------------

sub new(@)
{	my $thing = shift;
	my $class = ref $thing || $thing;
	my (@poly, %options);

	while(@_)
	{	if(!ref $_[0]) { my $k = shift; $options{$k} = shift }
		elsif(ref $_[0] eq 'ARRAY')        { push @poly, shift }
		elsif(blessed $_[0] && $_[0]->isa('Math::Polygon')) { push @poly, shift }
		else { panic "illegal argument $_[0]" }
	}

	$options{_poly} = \@poly if @poly;
	(bless {}, $class)->init(\%options);
}

sub init($$)
{	my ($self, $args)  = @_;
	my ($outer, @inner);

	if($args->{_poly})
	{	($outer, @inner) = @{$args->{_poly}};
	}
	else
	{	$outer = $args->{outer} or error __"surface requires outer polygon";
		@inner = @{$args->{inner}} if defined $args->{inner};
	}

	foreach ($outer, @inner)
	{	next unless ref $_ eq 'ARRAY';
		$_ = Math::Polygon->new(points => $_);
	}

	$self->{MS_outer} = $outer;
	$self->{MS_inner} = \@inner;
	$self;
}

#--------------------

sub outer() { $_[0]->{MS_outer} }


sub inner() { @{$_[0]->{MS_inner}} }

#--------------------

sub bbox() { $_[0]->outer->bbox }


sub area()
{	my $self = shift;
	my $area = $self->outer->area;
	$area   -= $_->area for $self->inner;
	$area;
}


sub perimeter()
{	my $self = shift;
	my $per  = $self->outer->perimeter;
	$per    += $_->perimeter for $self->inner;
	$per;
}

#--------------------

sub lineClip($$$$)
{	my ($self, @bbox) = @_;
	map { $_->lineClip(@bbox) } $self->outer, $self->inner;
}


sub fillClip1($$$$)
{	my ($self, @bbox) = @_;
	my $outer = $self->outer->fillClip1(@bbox);
	return () unless defined $outer;

	$self->new(
		outer => $outer,
		inner => [ map {$_->fillClip1(@bbox)} $self->inner ],
	);
}


sub string()
{	my $self = shift;
	  "["
	. join( "]\n-[",
			$self->outer->string,
			map $_->string, $self->inner)
	. "]";
}

1;
