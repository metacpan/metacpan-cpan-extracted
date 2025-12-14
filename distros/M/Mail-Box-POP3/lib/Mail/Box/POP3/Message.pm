# This code is part of Perl distribution Mail-Box-POP3 version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::POP3::Message;{
our $VERSION = '4.01';
}

use parent 'Mail::Box::Net::Message';

use strict;
use warnings;

use Log::Report  'mail-box-pop3';

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{body_type} ||= 'Mail::Message::Body::Lines';
	$self->SUPER::init($args);
}


sub size($)
{	my $self = shift;
	$self->isDelayed
	  ? $self->folder->popClient->messageSize($self->unique)
	  : $self->SUPER::size;
}

sub label(@)
{	my $self = shift;
	$self->loadHead;              # be sure the labels are read
	return $self->SUPER::label(@_) if @_==1;

	# POP3 can only set 'deleted' in the source folder.  Don't forget
	my $olddel = $self->label('deleted') ? 1 : 0;
	my $ret    = $self->SUPER::label(@_);
	my $newdel = $self->label('deleted') ? 1 : 0;

	$self->folder->popClient->deleted($newdel, $self->unique)
		if $newdel != $olddel;

	$ret;
}

sub labels(@)
{	my $self = shift;
	$self->loadHead;              # be sure the labels are read
	$self->SUPER::labels(@_);
}

#--------------------

sub loadHead()
{	my $self     = shift;
	my $head     = $self->head;
	$head->isDelayed or return $head;

	$head        = $self->folder->getHead($self);
	$self->head($head);

	$self->statusToLabels;  # not supported by al POP3 servers
	$head;
}

sub loadBody()
{	my $self     = shift;

	my $body     = $self->body;
	$body->isDelayed or return $body;

	(my $head, $body) = $self->folder->getHeadAndBody($self);
	$self->head($head) if $head->isDelayed;
	$self->storeBody($body);
}

1;
