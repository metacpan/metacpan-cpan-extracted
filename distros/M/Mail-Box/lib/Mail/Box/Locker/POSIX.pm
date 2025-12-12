# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::POSIX;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error fault warning/ ];

use Fcntl   qw/F_WRLCK F_UNLCK F_SETLK/;
use Errno   qw/EAGAIN/;

# fcntl() should not be used without XS: the below is sensitive
# for changes in the structure.  However, at the moment it seems
# there are only two options: either SysV-style or BSD-style

my $pack_pattern = $^O =~ /bsd|darwin/i ? '@20 s @256' : 's @256';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{file} = $args->{posix_file} if $args->{posix_file};
	$self->SUPER::init($args);
}

sub name() { 'POSIX' }

#--------------------

sub _try_lock($)
{	my ($self, $file) = @_;
	my $p = pack $pack_pattern, F_WRLCK;
	$? = fcntl($file, F_SETLK, $p) || ($!+0);
	$?==0;
}

sub _unlock($)
{	my ($self, $file) = @_;
	my $p = pack $pack_pattern, F_UNLCK;
	fcntl $file, F_SETLK, $p;
	$self;
}


sub lock()
{	my $self   = shift;

	$self->hasLock
		and warning(__x"folder {name} already lockf'd.", name => $self->folder), return 1;

	my $file     = $self->filename;

	open my $fh, '+<:raw', $file
		or fault __x"unable to open POSIX lock file {file} for {folder}", file => $file, $self->folder;

	my $timeout  = $self->timeout;
	my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;

	while(1)
	{	if($self->_try_lock($fh))
		{	$self->{MBLF_filehandle} = $fh;
			return $self->SUPER::lock;
		}

		$!==EAGAIN
			or fault __x"will never get a POSIX lock on {file} for {folder}", file => $file, folder => $self->folder;

		--$end or last;
		sleep 1;
	}

	return 0;
}


sub isLocked()
{	my $self = shift;
	my $file = $self->filename;

	open my $fh, '<:raw', $file
		or fault __x"unable to check lock file {file} for {folder}", file => $file, folder => $self->folder;

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
