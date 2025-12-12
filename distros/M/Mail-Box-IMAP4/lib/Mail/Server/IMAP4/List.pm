# This code is part of Perl distribution Mail-Box-IMAP4 version 4.000.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Server::IMAP4::List;{
our $VERSION = '4.000';
}


use strict;
use warnings;

use Log::Report 'mail-box-imap4';

#--------------------

sub new($)
{	my ($class, %args) = @_;
	(bless {}, $class)->init(\%args);
}

sub init($)
{	my ($self, $args) = @_;
	my $user = $self->{MSIL_user} = $args->{user};
	$self->{MSIL_folders} = $args->{folders};
	$self->{MSIL_inbox}   = $args->{inbox};
	$self->{MSIL_delim}   = exists $args->{delimiter} ? $args->{delimiter} : '/';
	$self;
}

#--------------------

sub delimiter(;$)
{	my $delim = shift->{MSIL_delim};
	ref $delim ? $delim->(shift) : $delim;
}


sub user() { $_[0]->{MSIL_user} }


sub folders()
{	my $self = shift;
	$self->{MSIL_folders} || $self->user->topfolder;
}


sub inbox()
{	my $self = shift;
	$self->{MSIL_inbox} || $self->user->inbox;
}

#--------------------

sub list($$)
{	my ($self, $base, $pattern) = @_;

	return [ '(\Noselect)', $self->delimiter($base), '' ]
		if $pattern eq '';

	my $delim  = $self->delimiter($base);
	my @path   = split $delim, $base;
	my $folder = $self->folders;

	while(@path && defined $folder)
	{	$folder = $folder->folder(shift @path);
	}
	defined $folder or return ();

	my @pattern = split $delim, $pattern;
	return $self->_list($folder, $delim, @pattern);
}

sub _list($$@)
{	my ($self, $folder, $delim) = (shift, shift, shift);

	if(!@_)
	{	my @flags;
		push @flags, '\Noselect'
			if $folder->onlySubfolders || $folder->deleted;

		push @flags, '\Noinferiors' unless $folder->inferiors;
		my $marked = $folder->marked;
		push @flags, ($marked ? '\Marked' : '\Unmarked')
			if defined $marked;

		local $" = ' ';

		# This is not always correct... should compose the name from the
		# parts... but in nearly all cases, the following is sufficient.
		my $name = $folder->fullname;
		for($name)
		{	s/^=//;
			s![/\\]!$delim!g;
		}
		return [ "(@flags)", $delim, $name ];
	}

	my $pat = shift;
	if($pat eq '%')
	{	my $subs = $folder->subfolders
			or return $self->_list($folder, $delim);
		return map $self->_list($_, $delim, @_), $subs->sorted;
	}

	if($pat eq '*')
	{	my @own = $self->_list($folder, $delim, @_);
		my $subs = $folder->subfolders or return @own;
		return @own, map $self->_list($_, $delim, '*', @_), $subs->sorted;
	}

	$folder = $folder->find(subfolders => $pat) or return ();
	$self->_list($folder, $delim, @_);
}

#--------------------

1;
