# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Identity;{
our $VERSION = '4.01';
}

use parent qw/User::Identity::Item Mail::Reporter/;

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error/ ];

use Mail::Box::Collection ();

# tests in tests/52message/30collect.t

#--------------------

sub new(@)
{	my $class = shift;
	unshift @_, 'name' if @_ % 2;
	$class->Mail::Reporter::new(@_);
}

sub init($)
{	my ($self, $args) = @_;

	$self->Mail::Reporter::init($args);
	$self->User::Identity::init($args);

	$self->{MBI_location}  = delete $args->{location};
	$self->{MBI_ftype}     = delete $args->{folder_type};
	$self->{MBI_manager}   = delete $args->{manager};
	$self->{MBI_subf_type} = delete $args->{subf_type}||'Mail::Box::Collection';
	$self->{MBI_only_subs} = delete $args->{only_subs};
	$self->{MBI_marked}    = delete $args->{marked};
	$self->{MBI_deleted}   = delete $args->{deleted};
	$self->{MBI_inferiors} = exists $args->{inferiors} ? $args->{inferiors} : 1;

	$self;
}

#--------------------

sub type { "mailbox" }


sub fullname(;$)
{	my $self   = shift;
	my $delim  = @_ && defined $_[0] ? shift : '/';

	my $parent = $self->parent or return $self->name;
	$parent->parent->fullname($delim) . $delim . $self->name;
}


sub location(;$)
{	my $self = shift;
	return ($self->{MBI_location} = shift) if @_;
	return $self->{MBI_location} if defined $self->{MBI_location};

	my $parent = $self->parent
		or error __x"toplevel directory requires explicit location.";

	$self->folderType->nameOfSubFolder($self->name, $parent->parent->location)
}



sub folderType()
{	my $self = shift;
	return $self->{MBI_ftype} if defined $self->{MBI_ftype};

	my $parent = $self->parent
		or error __x"toplevel directory requires explicit folder type.";

	$parent->parent->folderType;
}



sub manager()
{	my $self = shift;
	return $self->{MBI_manager} if $self->{MBI_manager};
	my $parent = $self->parent or return undef;
	$self->parent->manager;
}



sub topfolder()
{	my $self = shift;
	my $parent = $self->parent or return $self;
	$parent->parent->topfolder;
}



sub onlySubfolders(;$)
{	my $self = shift;
	return($self->{MBI_only_subs} = shift) if @_;
	return $self->{MBI_only_subs} if exists $self->{MBI_only_subs};
	$self->parent ? 1 : ! $self->folderType->topFolderWithMessages;
}



sub marked(;$)
{	my $self = shift;
	@_ ? ($self->{MBI_marked} = shift) : $self->{MBI_marked};
}



sub inferiors(;$)
{	my $self = shift;
	@_ ? ($self->{MBI_inferiors} = shift) : $self->{MBI_inferiors};
}



sub deleted(;$)
{	my $self = shift;
	@_ ? ($self->{MBI_deleted} = shift) : $self->{MBI_deleted};
}

#--------------------

sub subfolders()
{	my $self = shift;
	my $subs = $self->collection('subfolders');
	return (wantarray ? $subs->roles : $subs)
		if defined $subs;

	my @subs;
	if(my $location = $self->location)
	{	@subs   = $self->folderType->listSubFolders(folder => $location);
	}
	else
	{	my $mgr = $self->manager;
		my $top = defined $mgr ? $mgr->folderdir : '.';
		@subs   = $self->folderType->listSubFolders(folder => $self->fullname, folderdir => $top);
	}
	@subs or return ();

	my $subf_type = $self->{MBI_subf_type} || ref($self->parent) || 'Mail::Box::Collection';

	$subs = $subf_type->new('subfolders');

	$self->addCollection($subs);
	$subs->addRole(name => $_) for @subs;
	wantarray ? $subs->roles : $subs;
}



sub subfolderNames() { map $_->name, $_[0]->subfolders }



sub folder(@)
{	my $self = shift;
	return $self unless @_ && defined $_[0];

	my $subs = $self->subfolders  or return undef;
	my $nest = $subs->find(shift) or return undef;
	$nest->folder(@_);
}


sub open(@)
{	my $self = shift;
	$self->manager->open($self->fullname, type => $self->folderType, @_);
}


sub foreach($)
{	my ($self, $code) = @_;
	$code->($self);

	my $subs = $self->subfolders or return ();
	$_->foreach($code) for $subs->sorted;
	$self;
}



sub addSubfolder(@)
{	my $self  = shift;
	my $subs  = $self->subfolders;

	if(defined $subs) { ; }
	elsif(!$self->inferiors)
	{	my $name = $self->fullname;
		error __x"it is not permitted to add subfolders to {folder}.", folder => $name;
		return undef;
	}
	else
	{	$subs = $self->{MBI_subf_type}->new('subfolders');
		$self->addCollection($subs);
	}

	$subs->addRole(@_);
}



sub remove(;$)
{	my $self = shift;

	my $parent = $self->parent
		or error __x"the toplevel folder cannot be removed this way.";

	@_ or return $parent->removeRole($self->name);

	my $name = shift;
	my $subs = $self->subfolders or return ();
	$subs->removeRole($name);
}


sub rename($;$)
{	my ($self, $folder, $newname) = @_;
	$newname //= $self->name;
	my $away   = $self->remove;
	$away->name($newname);

	$folder->addSubfolder($away);
}

1;
