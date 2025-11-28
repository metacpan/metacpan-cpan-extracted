# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::FcntlLock;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

use File::FcntlLock  ();
use Fcntl            qw/F_WRLCK F_SETLK F_UNLCK/;
use Errno            qw/EAGAIN/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{file} = $args->{posix_file} if $args->{posix_file};
	$self->SUPER::init($args);
}

sub name() { 'FcntlLock' }

#--------------------

sub _try_lock($)
{	my ($self, $file) = @_;
	my $fl = File::FcntlLock->new;
	$fl->l_type(F_WRLCK);
	$? = $fl->lock($file, F_SETLK);
	$?==0;
}

sub _unlock($)
{	my ($self, $file) = @_;
	my $fl = File::FcntlLock->new;
	$fl->l_type(F_UNLCK);
	$fl->lock($file, F_SETLK);
	$self;
}


sub lock()
{	my $self   = shift;

	if($self->hasLock)
	{	my $folder = $self->folder;
		$self->log(WARNING => "Folder $folder already lockf'd");
		return 1;
	}

	my $file = $self->filename;
	open my $fh, '+<:raw', $file;
	unless(defined $fh)
	{	my $folder = $self->folder;
		$self->log(ERROR => "Unable to open FcntlLock lock file $file for $folder: $!");
		return 0;
	}

	my $timeout = $self->timeout;
	my $end     = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;

	while(1)
	{	if($self->_try_lock($fh))
		{	$self->SUPER::lock;
			$self->{MBLF_filehandle} = $fh;
			return 1;
		}

		unless($!==EAGAIN)
		{	my $folder = $self->folder;
			$self->log(ERROR => "Will never get a FcntlLock lock on $file for $folder: $!");
			last;
		}

		--$end or last;
		sleep 1;
	}

	return 0;
}


sub isLocked()
{	my $self = shift;
	my $file = $self->filename;
	open my $fh, '<:raw', $file;
	unless($fh)
	{	my $folder = $self->folder;
		$self->log(ERROR => "Unable to check lock file $file for $folder: $!");
		return 0;
	}

	$self->_try_lock($fh)==0 or return 0;
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
