# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Message;{
our $VERSION = '3.012';
}

use parent 'Mail::Message';

use strict;
use warnings;

use Scalar::Util  qw/weaken/;

use Mail::Box::Message::Destructed  ();

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBM_body_type} = $args->{body_type};
	$self->{MBM_folder}    = $args->{folder};
	weaken($self->{MBM_folder});

	$self;
}

sub head(;$)
{	my $self  = shift;
	@_ or return $self->SUPER::head;

	my $new   = shift;
	my $old   = $self->head;
	$self->SUPER::head($new);

	defined $new || defined $old
		or return undef;

	my $folder = $self->folder
		or return $new;

	if(!defined $new && defined $old && !$old->isDelayed)
	{	$folder->messageId($self->messageId, undef);
		$folder->toBeUnthreaded($self);
	}
	elsif(defined $new && !$new->isDelayed)
	{	$folder->messageId($self->messageId, $self);
		$folder->toBeThreaded($self);
	}

	$new || $old;
}

#--------------------

sub folder(;$)
{	my $self = shift;
	if(@_)
	{	$self->{MBM_folder} = shift;
		weaken($self->{MBM_folder});
		$self->modified(1);
	}
	$self->{MBM_folder};
}


sub seqnr(;$) {	my $self = shift; @_ ? $self->{MBM_seqnr} = shift : $self->{MBM_seqnr} }

#--------------------

sub copyTo($@)
{	my ($self, $folder) = (shift, shift);
	$folder->addMessage($self->clone(@_));
}


sub moveTo($@)
{	my ($self, $folder, %args) = @_;

	exists $args{share} || exists $args{shallow_body}
		or $args{share} = 1;

	my $added = $self->copyTo($folder, %args);
	$self->label(deleted => 1);
	$added;
}

#--------------------

sub readBody($$;$)
{	my ($self, $parser, $head, $getbodytype) = @_;

	unless($getbodytype)
	{	my $folder   = $self->folder;
		$getbodytype = sub { $folder->determineBodyType(@_) } if defined $folder;
	}

	$self->SUPER::readBody($parser, $head, $getbodytype);
}


sub diskDelete() { $_[0] }

sub forceLoad() {   # compatibility
	my $self = shift;
	$self->loadBody(@_);
	$self;
}

#--------------------

sub destruct() { Mail::Box::Message::Destructed->coerce(shift) }

1;
