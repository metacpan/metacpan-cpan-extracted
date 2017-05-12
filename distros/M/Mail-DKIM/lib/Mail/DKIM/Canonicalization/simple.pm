#!/usr/bin/perl

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::Canonicalization::simple;
use base "Mail::DKIM::Canonicalization::DkimCommon";
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

	#
	# draft-allman-dkim-base-01.txt, section 3.4.1:
	#   the "simple" header field canonicalization algorithm does not
	#   change the header field in any way
	#

	return $line;
}

sub canonicalize_body
{
	my $self = shift;
	my ($multiline) = @_;

	#
	# draft-allman-dkim-base-01.txt, section 3.4.3:
	#   the "simple" body canonicalization algorithm ignores all
	#   empty lines at the end of the message body
	#

	#
	# (i.e. do not emit empty lines until a following nonempty line
	# is found)
	#
	my $empty_lines = $self->{canonicalize_body_empty_lines};

	if ( $multiline =~ s/^((?:\015\012)+)// )
	{	# count & strip leading empty lines
		$empty_lines += length($1)/2;
	}

	if (length($multiline) > 0)
	{
		$self->{canonicalize_body_started} = 1;
		if ($empty_lines > 0)
		{	# re-insert leading white if any nonempty lines exist
			$multiline = ("\015\012" x $empty_lines) . $multiline;
			$empty_lines = 0;
		}
	}

	while ($multiline =~ /\015\012\015\012\z/)
	{	# count & strip trailing empty lines
		chop $multiline; chop $multiline;
		$empty_lines++;
	}

	$self->{canonicalize_body_empty_lines} = $empty_lines;
	return $multiline;
}

sub finish_body
{
	my $self = shift;
	$self->{canonicalize_body_started}
		or $self->output("\015\012");
	$self->SUPER::finish_body;
}

1;
