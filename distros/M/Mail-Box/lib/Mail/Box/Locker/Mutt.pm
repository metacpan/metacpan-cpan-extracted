# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::Mutt;{
our $VERSION = '4.01';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x fault warning/ ];

use POSIX      qw/sys_wait_h/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBLM_exe} = $args->{exe} || 'mutt_dotlock';
	$self;
}

sub name()     { 'MUTT' }
sub lockfile() { $_[0]->filename . '.lock' }

#--------------------

sub exe()      { $_[0]->{MBLM_exe} }

#--------------------

sub unlock()
{	my $self = shift;
	$self->hasLock or return $self;

	system $self->exe, '-u', $self->filename
		and warning __x"couldn't remove mutt-unlock {folder}", folder => $self->folder;

	$self->SUPER::unlock;
	$self;
}


sub lock()
{	my $self     = shift;
	my $filename = $self->filename;

	$self->hasLock
		and warning(__x"folder {name} already mutt-locked with {file}.", name => $self->folder, file => $filename), return 1;

	my $lockfn   = $self->lockfile;

	my $timeout  = $self->timeout;
	my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;
	my $expire   = $self->expires / 86400;  # in days for -A
	my $exe      = $self->exe;

	while(1)
	{
		system $exe, '-p', '-r', 1, $filename
			or return $self->SUPER::lock;   # success

		WIFEXITED($?) && WEXITSTATUS($?)==3
			or fault __x"folder {name} will never get a mutt-lock with {file}", name => $self->folder, file => $filename;

		if(-e $lockfn && -A $lockfn > $expire)
		{	system $exe, '-f', '-u', $filename
				and warning(__x"removed expired mutt-lock file {file}.", file => $lockfn), redo;

			fault __x"failed to remove expired mutt-lock {file}", file => $lockfn;
		}

		--$end or last;
		sleep 1;
	}

	0;
}

sub isLocked()
{	my $self     = shift;
	system $self->exe, '-t', $self->filename;
	WIFEXITED($?) && WEXITSTATUS($?)==3;
}

1;
