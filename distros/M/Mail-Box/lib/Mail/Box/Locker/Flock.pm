# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::Flock;{
our $VERSION = '4.01';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error fault warning/ ];

use Fcntl         qw/:DEFAULT :flock/;
use Errno         qw/EAGAIN/;

#--------------------

sub name() {'FLOCK'}

sub _try_lock($)
{	my ($self, $file) = @_;
	flock $file, LOCK_EX|LOCK_NB;
}

sub _unlock($)
{	my ($self, $file) = @_;
	flock $file, LOCK_UN;
	$self;
}

#--------------------

# 'r+' is require under Solaris and AIX, other OSes are satisfied with 'r'.
my $lockfile_access_mode = ($^O eq 'solaris' || $^O eq 'aix') ? '+<:raw' : '<:raw';

sub lock()
{	my $self   = shift;
	my $folder = $self->folder;

	! $self->hasLock
		or warning(__x"folder {name} already flocked.", name => $folder), return 1;

	my $filename = $self->filename;
	open my $fh, $lockfile_access_mode, $filename
		or fault __x"unable to open flock file {file} for {folder}", file => $filename, folder => $folder;

	my $timeout = $self->timeout;
	my $end     = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;

	while(1)
	{	if($self->_try_lock($fh))
		{	$self->{MBLF_filehandle} = $fh;
			return $self->SUPER::lock;
		}

		$! == EAGAIN
			or fault __x"will never get a flock on {file} for {folder}", file => $filename, folder => $folder;

		--$end or last;
		sleep 1;
	}

	return 0;
}


sub isLocked()
{	my $self     = shift;
	my $filename = $self->filename;

	open my($fh), $lockfile_access_mode, $filename
		or fault __x"unable to check lock file {file} for {folder}", file => $filename, folder => $self->folder;

	$self->_try_lock($fh) or return 0;
	$self->_unlock($fh);
	$fh->close;

	$self->SUPER::unlock;
	1;
}

sub unlock()
{	my $self = shift;

	$self->_unlock(delete $self->{MBLF_filehandle})
		if $self->hasLock;

	$self->SUPER::unlock;
	$self;
}

1;
