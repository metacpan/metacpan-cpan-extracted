# This code is part of Perl distribution Mail-Box-IMAP4 version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Server::IMAP4::User;{
our $VERSION = '4.01';
}

use parent 'Mail::Box::Manage::User';

use strict;
use warnings;

use Log::Report 'mail-box-imap4', import => [ qw/__x fault warning/ ];

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
		{	fault __x"Unable to remove folder {name}", name => $dir;
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
	{	warning __x"folder {name} already exists, creation skipped.", name => $name;
		return $info;
	}

	my $uniq    = $index->createUnique;

	# Create the directory
	# Also in this case, we bluntly try to create it, and when it doesn't
	# work, we check whether we did too much. This may safe an NFS stat.

	my $dir     = $self->home . '/F' . $uniq;
	-d $dir or mkdir $dir, 0750
		or fault __x"cannot create folder directory {dir}", dir => $dir;

	# Write folder name in directory, for recovery purposes.
	my $namefile = "$dir/name";
	my $namefh;
	open $namefh, '>:encoding(utf-8)', $namefile
		or fault __x"cannot write name for folder in {file}", file => $namefile;

	$namefh->print("$name\n");

	$namefh->close
		or fault __x"failed writing folder name to {file}", file => $namefile;

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
