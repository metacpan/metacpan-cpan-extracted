# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Net::Message;{
our $VERSION = '4.00';
}

use parent 'Mail::Box::Message';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error trace/ ];

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);
	$self->unique($args->{unique});
	$self;
}

#--------------------

sub unique(;$)
{	my $self = shift;
	@_ ? $self->{MBNM_unique} = shift : $self->{MBNM_unique};
}

#--------------------

sub loadHead()
{	my $self     = shift;
	my $head     = $self->head;
	$head->isDelayed or return $head;

	my $folder   = $self->folder;

	$folder->lazyPermitted(1);
	$self->readFromParser($self->parser);
	$folder->lazyPermitted(0);

	trace "Loaded delayed head for message ". $self->messageId;
	$self->head;
}


sub loadBody()
{	my $self     = shift;
	my $msgid    = $self->messageId;

	my $body     = $self->body;
	$body->isDelayed or return;

	my $head     = $self->head;
	my $parser   = $self->parser;

	if($head->isDelayed)
	{	$head = $self->readHead($parser)
			or error __x"unable to read delayed head for {msgid}.", msgid => $msgid;

		trace "Loaded delayed head for $msgid.";
		$self->head($head);
	}
	else
	{	my ($begin, $end) = $body->fileLocation;
		$parser->filePosition($begin);
	}

	my $newbody  = $self->readBody($parser, $head)
		or error __x"unable to read delayed body for {msgid}.", msgid => $msgid;

	trace "Loaded delayed body for $msgid.";
	$self->storeBody($newbody->contentInfoFrom($head));
}

1;
