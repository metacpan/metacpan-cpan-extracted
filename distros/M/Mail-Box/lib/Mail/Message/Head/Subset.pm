# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Head::Subset;{
our $VERSION = '4.00';
}

use parent 'Mail::Message::Head';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw// ];

use Object::Realize::Later
	becomes        => 'Mail::Message::Head::Complete',
	realize        => 'load',
	believe_caller => 1;

use Date::Parse       qw/str2time/;

#--------------------

sub count($)
{	my ($self, $name) = @_;
	my @values = $self->get($name)
		or return $self->load->count($name);
	scalar @values;
}


sub get($;$)
{	my $self = shift;

	if(wantarray)
	{	my @values = $self->SUPER::get(@_);
		return @values if @values;
	}
	else
	{	my $value  = $self->SUPER::get(@_);
		return $value  if defined $value;
	}

	$self->load->get(@_);
}


#--------------------

sub guessBodySize()
{	my $self = shift;

	my $cl = $self->SUPER::get('Content-Length');
	return $1 if defined $cl && $cl =~ m/(\d+)/;

	my $lines = $self->SUPER::get('Lines');   # 40 chars per lines
	defined $lines && $lines =~ m/(\d+)/ ? $1 * 40 : undef
}

# Be careful not to trigger loading: this is not the thoroughness
# we want from this method.

sub guessTimestamp()
{	my $self = shift;
	return $self->{MMHS_timestamp} if $self->{MMHS_timestamp};

	my $stamp;
	if(my $date = $self->SUPER::get('date'))
	{	$stamp = str2time($date, 'GMT');
	}

	unless($stamp)
	{	foreach my $time ($self->SUPER::get('received'))
		{	$stamp = str2time($time, 'GMT');
			last if $stamp;
		}
	}

	$self->{MMHS_timestamp} = $stamp;
}

#--------------------

sub load() { $_[0] = $_[0]->message->loadHead }

1;
