#!/usr/bin/perl

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::Canonicalization::nowsp;
use base "Mail::DKIM::Canonicalization::DkimCommon";
use Carp;

sub canonicalize_header
{
	my $self = shift;
	croak "wrong number of parameters" unless (@_ == 1);
	my ($line) = @_;

	# remove all whitespace
	$line =~ s/[ \t\015\012]//g;

	if ($line =~ /^([^:]+):(.*)$/)
	{
		# lowercase field name
		$line = lc($1) . ":$2";
	}

	return $line;
}

sub canonicalize_body
{
	my $self = shift;
	my ($multiline) = @_;

	$multiline =~ s/[ \t\015\012]//g;
	return $multiline;
}

sub finish_body
{
	my $self = shift;
	$self->SUPER::finish_body;
}

1;
