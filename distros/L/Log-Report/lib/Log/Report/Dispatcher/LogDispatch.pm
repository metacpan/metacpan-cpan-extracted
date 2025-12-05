# This code is part of Perl distribution Log-Report version 1.43.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2007-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Log::Report::Dispatcher::LogDispatch;{
our $VERSION = '1.43';
}

use base 'Log::Report::Dispatcher';

use warnings;
use strict;

use Log::Report 'log-report', syntax => 'SHORT';
use Log::Report::Util  qw/@reasons expand_reasons/;

use Log::Dispatch 2.00;

my %default_reasonToLevel = (
	TRACE   => 'debug',
	ASSERT  => 'debug',
	INFO    => 'info',
	NOTICE  => 'notice',
	WARNING => 'warning',
	MISTAKE => 'warning',
	ERROR   => 'error',
	FAULT   => 'error',
	ALERT   => 'alert',
	FAILURE => 'emergency',
	PANIC   => 'critical',
);

@reasons != keys %default_reasonToLevel
	and panic __"Not all reasons have a default translation";

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$args->{name}        = $self->name;
	$args->{min_level} ||= 'debug';

	$self->{level}  = { %default_reasonToLevel };
	if(my $to_level = delete $args->{to_level})
	{	my @to = @$to_level;
		while(@to)
		{	my ($reasons, $level) = splice @to, 0, 2;
			my @reasons = expand_reasons $reasons;

			Log::Dispatch->level_is_valid($level)
				or error __x"Log::Dispatch level '{level}' not understood", level => $level;

			$self->{level}{$_} = $level for @reasons;
		}
	}

	$self->{backend} = $self->type->new(%$args);
	$self;
}

sub close()
{	my $self = shift;
	$self->SUPER::close or return;
	delete $self->{backend};
	$self;
}

#--------------------

sub backend() { $_[0]->{backend} }

#--------------------

sub log($$$$$)
{	my $self  = shift;
	my $text  = $self->translate(@_) or return;
	my $level = $self->reasonToLevel($_[1]);

	$self->backend->log(level => $level, message => $text);
	$self;
}


sub reasonToLevel($) { $_[0]->{level}{$_[1]} }

1;
