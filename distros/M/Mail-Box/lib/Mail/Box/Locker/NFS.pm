# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Locker::NFS;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Locker';

use strict;
use warnings;

use Sys::Hostname;
use Carp;
use Fcntl  qw/O_CREAT O_WRONLY/;

#--------------------

sub name() { 'NFS' }

#--------------------

# METHOD nfs
# This hack is copied from the Mail::Folder packages, as written
# by Kevin Jones.  Cited from his code:
#    Whhheeeee!!!!!
#    In NFS, the O_CREAT|O_EXCL isn't guaranteed to be atomic.
#    So we create a temp file that is probably unique in space
#    and time ($folder.lock.$time.$pid.$host).
#    Then we use link to create the real lock file. Since link
#    is atomic across nfs, this works.
#    It loses if it's on a filesystem that doesn't do long filenames.

my $hostname = hostname;

sub _tmpfilename()
{	my $self = shift;
	$self->{MBLN_tmp} ||= $self->filename . $$;
}

sub _construct_tmpfile()
{	my $self    = shift;
	my $tmpfile = $self->_tmpfilename;

	sysopen my $fh, $tmpfile, O_CREAT|O_WRONLY, 0600
		or return undef;

	$fh->close;
	$tmpfile;
}

sub _try_lock($$)
{	my ($self, $tmpfile, $lockfile) = @_;

	link $tmpfile, $lockfile
		or return undef;

	my $linkcount = (stat $tmpfile)[3];

	unlink $tmpfile;
	$linkcount == 2;
}

sub _unlock($$)
{	my ($self, $tmpfile, $lockfile) = @_;

	unlink $lockfile
		or warn "Couldn't remove lockfile $lockfile: $!\n";

	unlink $tmpfile;
	$self;
}


sub lock()
{	my $self     = shift;
	my $folder   = $self->folder;

	$self->hasLock
		and $self->log(WARNING => "Folder $folder already locked over nfs"), return 1;

	my $lockfile = $self->filename;
	my $tmpfile  = $self->_construct_tmpfile or return;
	my $timeout  = $self->timeout;
	my $end      = $timeout eq 'NOTIMEOUT' ? -1 : $timeout;
	my $expires  = $self->expires / 86400;  # in days for -A

	if(-e $lockfile && -A $lockfile > $expires)
	{	unlink $lockfile
			or $self->log(ERROR => "Unable to remove expired lockfile $lockfile: $!"), return 0;

		$self->log(WARNING => "Removed expired lockfile $lockfile.");
	}

	while(1)
	{	return $self->SUPER::lock
			if $self->_try_lock($tmpfile, $lockfile);

		--$end or last;
		sleep 1;
	}

	return 0;
}

sub isLocked()
{	my $self     = shift;
	my $tmpfile  = $self->_construct_tmpfile or return 0;
	my $lockfile = $self->filename;

	my $fh = $self->_try_lock($tmpfile, $lockfile) or return 0;
	close $fh;

	$self->_unlock($tmpfile, $lockfile);
	$self->SUPER::unlock;

	1;
}

sub unlock($)
{	my $self   = shift;
	$self->hasLock or return $self;

	$self->_unlock($self->_tmpfilename, $self->filename);
	$self->SUPER::unlock;
	$self;
}

1;
