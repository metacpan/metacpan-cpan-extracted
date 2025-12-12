# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::DotLock;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error fault warning/ ];

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
		  :    error __x"Dotlock requires a lock file name.";

		$self->filename($filename);
	}

	$self->SUPER::folder($folder);
}

#--------------------

sub unlock()
{	my $self = shift;
	$self->hasLock
		or return $self;

	my $lock = $self->filename;

	unlink $lock
		or warning __x"couldn't remove lockfile {file}: {rc}", file => $lock, rc => $!;

	$self->SUPER::unlock;
	$self;
}


sub _try_lock($)
{	my ($self, $lockfile) = @_;
	return if -e $lockfile;

	my $flags = $^O eq 'MSWin32' ?  O_CREAT|O_EXCL|O_WRONLY :  O_CREAT|O_EXCL|O_WRONLY|O_NONBLOCK;
	my $lock;
	sysopen $lock, $lockfile, $flags, 0600
		and $lock->close, return 1;

	$! == EEXIST
		or fault __x"lockfile {file} can never be created", file => $lockfile;

	1;
}

sub lock()
{	my $self   = shift;

	my $lockfile = $self->filename;
	$self->hasLock
		and warning(__x"folder already locked with file {file}.", file => $lockfile), return 1;

	my $timeout  = $self->timeout;
	my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;
	my $expire   = $self->expires/86400;  # in days for -A

	while(1)
	{
		return $self->SUPER::lock
			if $self->_try_lock($lockfile);

		if(-e $lockfile && -A $lockfile > $expire)
		{	unlink $lockfile
				or fault __x"failed to remove expired lockfile {file}", file => $lockfile;

			warning __x"removed expired lockfile {file}.", file => $lockfile;
			redo;
		}

		--$end or last;
		sleep 1;
	}

	return 0;
}

sub isLocked() { -e shift->filename }

1;
