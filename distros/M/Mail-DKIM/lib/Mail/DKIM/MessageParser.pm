#!/usr/bin/perl

# Copyright 2005 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>

# Copyright (c) 2004 Anthony D. Urso. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use warnings;

package Mail::DKIM::MessageParser;
use Carp;

sub new_object
{
	my $class = shift;
	return $class->TIEHANDLE(@_);
}

sub new_handle
{
	my $class = shift;
	local *TMP;
	tie *TMP, $class, @_;
	return *TMP;
}

sub TIEHANDLE
{
	my $class = shift;
	my %args = @_;
	my $self = bless \%args, $class;
	$self->init;
	return $self;
}

sub init
{
	my $self = shift;

	my $buf = '';
	$self->{buf_ref} = \$buf;
	$self->{in_header} = 1;
}

sub PRINT
{
	my $self = shift;
	my $buf_ref = $self->{buf_ref};
	$$buf_ref .= @_ == 1 ? $_[0] : join("", @_)  if @_;

	if ($self->{in_header}) {
		local $1;  # avoid polluting a global $1
		while ($$buf_ref ne '')
		{
			if (substr($$buf_ref,0,2) eq "\015\012")
			{
				substr($$buf_ref, 0, 2) = '';
				$self->finish_header();
				$self->{in_header} = 0;
				last;
			}
			if ($$buf_ref !~ /^(.+?\015\012)[^\ \t]/s)
			{
				last;
			}
			my $header = $1;
			$self->add_header($header);
			substr($$buf_ref, 0, length($header)) = '';
		}
	}

	if (!$self->{in_header}) {
		my $j = rindex($$buf_ref,"\015\012");
		if ($j >= 0)
		{
			# avoid copying a large buffer: the unterminated
			# last line is typically short compared to the rest

			my $carry = substr($$buf_ref, $j+2);
			substr($$buf_ref, $j+2) = '';  # shrink to last CRLF
			$self->add_body($$buf_ref);    # must end on CRLF
			$$buf_ref = $carry;  # restore unterminated last line
		}
	}
	return 1;
}

sub CLOSE
{
	my $self = shift;
	my $buf_ref = $self->{buf_ref};

	if ($self->{in_header})
	{
		if ($$buf_ref ne '')
		{
			# A line of header text ending CRLF would not have been
			# processed yet since before we couldn't tell if it was
			# the complete header. Now that we're in CLOSE, we can
			# finish the header...
			$$buf_ref =~ s/\015\012\z//s;
			$self->add_header("$$buf_ref\015\012");
		}
		$self->finish_header;
		$self->{in_header} = 0;
	}
	else
	{
		if ($$buf_ref ne '')
		{
			$self->add_body($$buf_ref);
		}
	}
	$$buf_ref = '';
	$self->finish_body;
	return 1;
}

sub add_header
{
	die "add_header not implemented";
}

sub finish_header
{
	die "finish_header not implemented";
}

sub add_body
{
	die "add_body not implemented";
}

sub finish_body
{
	# do nothing by default
}

sub reset
{
	carp "reset not implemented";
}

1;
