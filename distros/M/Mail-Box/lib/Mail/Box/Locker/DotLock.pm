# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::DotLock;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

use Carp;
use File::Spec::Functions qw/catfile/;
use Errno                 qw/EEXIST/;
use Fcntl                 qw/O_CREAT O_EXCL O_WRONLY O_NONBLOCK/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{file} = $args->{dotlock_file} if $args->{dotlock_file};
	$self->SUPER::init($args);
}

sub name() { 'DOTLOCK' }

#--------------------

sub folder(;$)
{	my $self = shift;
	@_ && $_[0] or return $self->SUPER::folder;

	my $folder = shift;
	unless(defined $self->filename)
	{	my $org = $folder->organization;

		my $filename
		  = $org eq 'FILE'     ? $folder->filename . '.lock'
		  : $org eq 'DIRECTORY'? catfile($folder->directory, '.lock')
		  :    croak "Need lock file name for DotLock.";

		$self->filename($filename);
	}

	$self->SUPER::folder($folder);
}

#--------------------

sub _try_lock($)
{	my ($self, $lockfile) = @_;
	return if -e $lockfile;

	my $flags = $^O eq 'MSWin32' ?  O_CREAT|O_EXCL|O_WRONLY :  O_CREAT|O_EXCL|O_WRONLY|O_NONBLOCK;
	my $lock;
	sysopen $lock, $lockfile, $flags, 0600
		and $lock->close, return 1;

	$! == EEXIST
		or $self->log(ERROR => "lockfile $lockfile can never be created: $!"), return 0;

	1;
}


sub unlock()
{	my $self = shift;
	$self->hasLock
		or return $self;

	my $lock = $self->filename;

	unlink $lock
		or $self->log(WARNING => "Couldn't remove lockfile $lock: $!");

	$self->SUPER::unlock;
	$self;
}


sub lock()
{	my $self   = shift;

	my $lockfile = $self->filename;
	$self->hasLock
		and $self->log(WARNING => "Folder already locked with file $lockfile"), return 1;

	my $timeout  = $self->timeout;
	my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;
	my $expire   = $self->expires/86400;  # in days for -A

	while(1)
	{
		return $self->SUPER::lock
			if $self->_try_lock($lockfile);

		if(-e $lockfile && -A $lockfile > $expire)
		{	unlink $lockfile
				or $self->log(ERROR => "Failed to remove expired lockfile $lockfile: $!"), last;

			$self->log(WARNING => "Removed expired lockfile $lockfile");
			redo;
		}

		last unless --$end;
		sleep 1;
	}

	return 0;
}

sub isLocked() { -e shift->filename }

1;
