# This code is part of Perl distribution Log-Report-Optional version 1.08.
# The POD got stripped from this file by OODoc version 3.04.
# For contributors see file ChangeLog.

# This software is copyright (c) 2013-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Log::Report::Minimal::Domain;{
our $VERSION = '1.08';
}


use warnings;
use strict;

use String::Print        'oo';

#--------------------

sub new(@)  { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($)
{	my ($self, $args) = @_;
	$self->{LRMD_name} = $args->{name} or Log::Report::panic();
	$self;
}

#--------------------

sub name() { $_[0]->{LRMD_name} }
sub isConfigured() { $_[0]->{LRMD_where} }



sub configure(%)
{	my ($self, %args) = @_;

	my $here = $args{where} || [caller];
	if(my $s = $self->{LRMD_where})
	{	my $domain = $self->name;
		die "only one package can contain configuration; for $domain already in $s->[0] in file $s->[1] line $s->[2].  Now also found at $here->[1] line $here->[2]\n";
	}
	my $where = $self->{LRMD_where} = $here;

	# documented in the super-class, the more useful man-page
	my $format = $args{formatter} || 'PRINTI';
	$format    = {} if $format eq 'PRINTI';

	if(ref $format eq 'HASH')
	{	my $class  = delete $format->{class}  || 'String::Print';
		my $method = delete $format->{method} || 'sprinti';
		my $sp     = $class->new(%$format);
		$self->{LRMD_format} = sub { $sp->$method(@_) };
	}
	elsif(ref $format eq 'CODE')
	{	$self->{LRMD_format} = $format;
	}
	else
	{	error __x"illegal formatter `{name}' at {fn} line {line}", name => $format, fn => $where->[1], line => $where->[2];
	}

	$self;
}

#--------------------

sub interpolate(@)
{	my ($self, $msgid, $args) = @_;
	$args->{_expand} or return $msgid;

	my $f = $self->{LRMD_format} || $self->configure->{LRMD_format};
	$f->($msgid, $args);
}

1;
