#!/usr/bin/perl

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::Canonicalization::dk_simple;
use base "Mail::DKIM::Canonicalization::DkCommon";
use Carp;

sub init
{
	my $self = shift;
	$self->SUPER::init;

	$self->{canonicalize_body_empty_lines} = 0;
}

sub canonicalize_header
{
	my $self = shift;
	croak "wrong number of parameters" unless (@_ == 1);
	my ($line) = @_;

	return $line;
}

sub canonicalize_body
{
	my $self = shift;
	my ($multiline) = @_;

	# ignore empty lines at the end of the message body
	#
	# (i.e. do not emit empty lines until a following nonempty line
	# is found)
	#
	my $empty_lines = $self->{canonicalize_body_empty_lines};

	if ( $multiline =~ s/^((?:\015\012)+)// )
	{	# count & strip leading empty lines
		$empty_lines += length($1)/2;
	}

	if ($empty_lines > 0 && length($multiline) > 0)
	{	# re-insert leading white if any nonempty lines exist
		$multiline = ("\015\012" x $empty_lines) . $multiline;
		$empty_lines = 0;
	}

	while ($multiline =~ /\015\012\015\012\z/)
	{	# count & strip trailing empty lines
		chop $multiline; chop $multiline;
		$empty_lines++;
	}

	$self->{canonicalize_body_empty_lines} = $empty_lines;
	return $multiline;
}

1;
