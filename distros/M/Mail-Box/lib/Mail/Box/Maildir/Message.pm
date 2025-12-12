# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Maildir::Message;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Dir::Message';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x fault info trace/ ];

use File::Copy              qw/move/;
use File::Spec::Functions   qw/catfile/;

#--------------------

sub filename(;$)
{	my $self    = shift;
	my $oldname = $self->SUPER::filename;
	@_ or return $oldname;

	my $newname = shift;
	! defined $oldname || $oldname ne $newname
		or return $newname;

	my ($id, $semantics, $flags) =
		$newname =~ m!(.*?)(?:\:([12])\,([A-Za-z]*))! ? ($1, $2, $3) : ($newname, '', '');

	my %flags;
	$flags{$_}++ for split //, $flags;

	$self->SUPER::label(
		draft   => (delete $flags{D} || 0),
		flagged => (delete $flags{F} || 0),
		replied => (delete $flags{R} || 0),
		seen    => (delete $flags{S} || 0),
		deleted => (delete $flags{T} || 0),

		passed  => (delete $flags{P} || 0),    # uncommon
		unknown => join('', sort keys %flags) # application specific
	);

	! defined $oldname || move $oldname, $newname
		or fault __x"cannot rename file {from} to {to}", from => $oldname, to => $newname;

	$self->SUPER::filename($newname);
}

#--------------------


sub guessTimestamp()
{	my $self = shift;
	my $timestamp   = $self->SUPER::guessTimestamp;
	return $timestamp if defined $timestamp;

	$self->filename =~ m/^(\d+)/ ? $1 : undef;
}

#--------------------

sub label(@)
{	my $self   = shift;
	@_ or return $self->SUPER::label;

	my $labels = $self->SUPER::label(@_);
	$self->labelsToFilename;
	$labels;
}


sub labelsToFilename()
{	my $self   = shift;
	my $labels = $self->labels;
	my $old    = $self->filename;

	my ($folderdir, $set, $oldname, $oldflags) = $old =~ m!(.*)/(new|cur|tmp)/(.+?)(\:2,[^:]*)?$!;

	my $newflags    # alphabeticly ordered!
	  = ($labels->{draft}   ? 'D' : '')
	  . ($labels->{flagged} ? 'F' : '')
	  . ($labels->{passed}  ? 'P' : '')
	  . ($labels->{replied} ? 'R' : '')
	  . ($labels->{seen}    ? 'S' : '')
	  . ($labels->{deleted} ? 'T' : '')
	  . ($labels->{unknown} || '');

	my $newset = $labels->{accepted} ? 'cur' : 'new';
	if($set ne $newset)
	{	my $folder = $self->folder;
		$folder->modified(1) if defined $folder;
	}

	my $flags = $newset ne 'new' || $newflags ne '' ? ":2,$newflags" : $oldflags ? ':2,' : '';
	my $new   = catfile $folderdir, $newset, $oldname.$flags;

	if($new ne $old)
	{	move $old, $new
			or fault __x"cannot rename file {from} to {to}", from => $old, to => $new;

		trace "Moved $old to $new.";
		$self->SUPER::filename($new);
	}

	$new;
}

#--------------------

sub accept(;$)
{	my $self   = shift;
	my $accept = @_ ? shift : 1;
	$self->label(accepted => $accept);
}

#--------------------

1;
