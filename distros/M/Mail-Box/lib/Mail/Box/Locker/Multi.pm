# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::Multi;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/trace try/ ];

use Scalar::Util     qw/blessed/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	my @use
	  = exists $args->{use} ? @{delete $args->{use}}
	  : $^O eq 'MSWin32'    ? qw/Flock/
	  :   qw/NFS FcntlLock Flock/;

	my (@lockers, @used);

	foreach my $method (@use)
	{	if(blessed $method && $method->isa('Mail::Box::Locker'))
		{	push @lockers, $method;
			push @used, ref $method =~ s/.*\:\://r;
			next;
		}

		my $locker = try { Mail::Box::Locker->new(%$args, method => $method, timeout => 1) };
		defined $locker or next;

		push @lockers, $locker;
		push @used, $method;
	}

	$self->{MBLM_lockers} = \@lockers;
	trace "Multi-locking via @used.";
	$self;
}

#--------------------

sub lockers() { @{ $_[0]->{MBLM_lockers}} }

sub name() {'MULTI'}

sub _try_lock()
{	my $self     = shift;
	my @successes;

	foreach my $locker ($self->lockers)
	{
		unless($locker->lock)
		{	$_->unlock for @successes;
			return 0;
		}
		push @successes, $locker;
	}

	1;
}

#--------------------

sub unlock()
{	my $self = shift;
	$self->hasLock or return $self;
	$_->unlock for $self->lockers;
	$self->SUPER::unlock;
	$self;
}

sub lock()
{	my $self  = shift;
	return 1 if $self->hasLock;

	my $timeout = $self->timeout;
	my $end     = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;

	while(1)
	{	return $self->SUPER::lock
			if $self->_try_lock;

		last unless --$end;
		sleep 1;
	}

	return 0;
}

sub isLocked()
{	my $self     = shift;

	# Try get a lock
	$self->_try_lock or return 0;

	# and release it immediately
	$self->unlock;
	1;
}


1;
