# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Manage::User;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Manager';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error panic trace warning/ ];

use Mail::Box::Collection     ();

#--------------------

sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::init($args);

	my $identity = $self->{MBMU_id} = $args->{identity}
		or error __x"user manager requires an identity.";

	my $top     = $args->{folder_id_type}  // 'Mail::Box::Identity';
	my $coltype = $args->{collection_type} // 'Mail::Box::Collection';

	unless(blessed $top)
	{	my $name = $args->{topfolder_name};
		$name  //= '=';   # MailBox's abbrev to top

		$top     = $top->new(
			name        => $name,
			manager     => $self,
			location    => scalar($self->folderdir),
			folder_type => $self->defaultFolderType,
			collection_type => $coltype,
		);
	}

	$self->{MBMU_top}   = $top;
	$self->{MBMU_delim} = $args->{delimiter} || '/';
	$self->{MBMU_inbox} = $args->{inbox};
	$self;
}

#--------------------

sub identity()  { $_[0]->{MBMU_id} }
sub delimiter() { $_[0]->{MBMU_delim} }
sub topfolder() { $_[0]->{MBMU_top} }


sub inbox(;$)
{	my $self = shift;
	@_ ? ($self->{MBMU_inbox} = shift) : $self->{MBMU_inbox};
}

#--------------------

# A lot of work still has to be done here: all moves etc must inform
# the "existence" administration as well.

#--------------------

sub folder($)
{	my ($self, $name) = @_;
	my $top  = $self->topFolder or return ();
	my @path = split $self->delimiter, $name;
	(shift @path) eq $top->name or return ();

	$top->folder(@path);
}


sub folderCollection($)
{	my ($self, $name) = @_;
	my $top  = $self->topFolder or return ();

	my @path = split $self->delimiter, $name;
	shift @path eq $top->name
		or error __x"folder {name} not under top.", name => $name;

	my $base = pop @path;
	($top->folder(@path), $base);
}


# This feature is thoroughly tested in the Mail::Box::Netzwert distribution

sub create($@)
{	my ($self, $name, %args) = @_;
	my ($dir, $base) = $self->folderCollection($name);

	unless(defined $dir)
	{	$args{create_supers}
			or error __x"cannot create folder {name}: higher levels missing.", name => $name;

		my $delim = $self->delimiter;
		my $upper = $name =~ s!$delim$base!!r or panic "$name - $base";
		$dir = $self->create($upper, %args, deleted => 1);
	}

	my $id = $dir->folder($base);
	if(!defined $id)
	{	my $idopt = $args{id_options} || [];
		$id  = $dir->addSubfolder($base, @$idopt, deleted => $args{deleted});
	}
	elsif($args{deleted})
	{	$id->deleted(1);
		return $id;
	}
	elsif($id->deleted)
	{	# Revive! Raise the death!
		$id->deleted(0);
	}
	else
	{	# Bumped into existing folder
		error __x"folder {name} already exists.", name => $name;
	}

	$self->defaultFolderType->create($id->location, %args)
		if ! exists $args{create_real} || $args{create_real};

	$id;
}


sub delete($)
{	my ($self, $name) = @_;
	my $folder = $self->folder($name) or return ();
	$folder->remove;
	$self->SUPER::delete($name);
}


sub rename($$@)
{	my ($self, $oldname, $newname, %args) = @_;

	my $old     = $self->folder($oldname)
		or error __x"source folder for rename does not exist: {from} to {to}.", from => $oldname, to => $newname;

	my ($newdir, $base) = $self->folderCollection($newname);
	unless(defined $newdir)
	{	$args{create_supers}
			or error __x"cannot rename folder {from} to {to}: higher levels are missing.", from => $oldname, to => $newname;

		my $delim = $self->delimiter;
		my $upper = $newname =~ s!$delim$base!!r or panic "$newname - $base";
		$newdir   = $self->create($upper, %args, deleted => 1);
	}

	my $oldlocation = $old->location;
	my $new         = $old->rename($newdir, $base);

	my $newlocation = $new->location;
	$oldlocation eq $newlocation
		or panic "Physical folder relocation not yet implemented";  #XXX
		# this needs a $old->rename(xx,yy) which isn't implemented yet

	trace "renamed folder $oldname to $newname";
	$new;
}

1;
