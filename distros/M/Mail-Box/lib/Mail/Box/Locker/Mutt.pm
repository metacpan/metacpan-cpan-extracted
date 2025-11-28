# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::Mutt;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

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

sub exe() { $_[0]->{MBLM_exe} }


sub unlock()
{	my $self = shift;
	$self->hasLock or return $self;

	unless(system $self->exe, '-u', $self->filename)
	{	my $folder = $self->folder;
		$self->log(WARNING => "Couldn't remove mutt-unlock $folder: $!");
	}

	$self->SUPER::unlock;
	$self;
}

#--------------------

sub lock()
{	my $self     = shift;
	my $folder   = $self->folder;

	$self->hasLock
		and $self->log(WARNING => "Folder $folder already mutt-locked"), return 1;

	my $filename = $self->filename;
	my $lockfn   = $self->lockfile;

	my $timeout  = $self->timeout;
	my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;
	my $expire   = $self->expires / 86400;  # in days for -A
	my $exe      = $self->exe;

	while(1)
	{
		system $exe, '-p', '-r', 1, $filename
			or return $self->SUPER::lock;

		WIFEXITED($?) && WEXITSTATUS($?)==3
			or $self->log(ERROR => "Will never get a mutt-lock: $!"), return 0;

		if(-e $lockfn && -A $lockfn > $expire)
		{	system $exe, '-f', '-u', $filename
				and $self->log(WARNING => "Removed expired mutt-lock $lockfn"), redo;

			$self->log(ERROR => "Failed to remove expired mutt-lock $lockfn: $!");
			last;
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
