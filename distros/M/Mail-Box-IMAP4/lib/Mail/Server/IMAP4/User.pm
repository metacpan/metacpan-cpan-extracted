# This code is part of Perl distribution Mail-Box-IMAP4 version 3.010.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Server::IMAP4::User;{
our $VERSION = '3.010';
}

use base 'Mail::Box::Manage::User';

use strict;
use warnings;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return ();
	$self->{MSNU_indexfile} = $args->{indexfile} // ($self->folderdir . '/index');
	$self;
}

#--------------------

sub indexFilename() { $_[0]->{MSNU_indexfile} };

#--------------------

sub folderInfo($)
{	my $index = $_[0]->index or return ();
	$index->folder(shift);
}


sub delete($)
{	my ($self, $name) = @_;
	my $index = $self->index->startModify or return 0;

	unless($self->_delete($index, $name))
	{	$self->cancelModification($index);
		return 0;
	}

	$index->write;
}

sub _delete($$)
{	my ($self, $index, $name) = @_;

	# First clean all subfolders recursively
	foreach my $subf ($index->subfolders($name))
	{	$self->_delete($index, $subf) or return 0;
	}

	# Already disappeared?  Shouldn't happen, but ok
	my $info  = $index->folder($name)
		or return 1;

	# Bluntly clean-out the directory
	if(my $dir = $info->{Directory})
	{	# Bluntly try to remove, but error is not set
		if(remove(\1, $dir) != 0 && -d $dir)
		{	$self->log(error => "Unable to remove folder $dir");
			return 0;
		}
	}

	# Remove (sub)folder from index
	$index->folder($name, undef);
	1;
}


sub create($@)
{	my ($self, $name) = (shift, shift);
	my $index   = $self->index->startModify or return undef;

	if(my $info = $index->folder($name))
	{	$self->log(WARNING => "Folder $name already exists, creation skipped");
		return $info;
	}

	my $uniq    = $index->createUnique;

	# Create the directory
	# Also in this case, we bluntly try to create it, and when it doesn't
	# work, we check whether we did too much. This may safe an NFS stat.

	my $dir     = $self->home . '/F' . $uniq;
	unless(mkdir $dir, 0750)
	{	my $rc = "$!";
		unless(-d $dir)   # replaces $!
		{	$self->log(ERROR => "Cannot create folder directory $dir: $rc");
			return undef;
		}
	}

	# Write folder name in directory, for recovery purposes.
	my $namefile = "$dir/name";
	my $namefh;
	unless(open $namefh, '>:encoding(utf-8)', $namefile)
	{	$self->log(ERROR => "Cannot write name for folder in $namefile: $!");
		return undef;
	}

	$namefh->print("$name\n");

	unless($namefh->close)
	{	$self->log(ERROR => "Failed writing folder name to $namefile: $!");
		return undef;
	}

	# Add folder to the index

	my $facts = $self->folder(
		$name,
		Folder    => $name,
		Directory => $dir,
		Messages  => 0,
		Size      => 0,
	);

	$self->write && $facts;
}

#--------------------

1;
