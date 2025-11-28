# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Net::Message;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Message';

use strict;
use warnings;

use Carp;

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

	my $parser   = $self->parser or return;
	$self->readFromParser($parser);

	$folder->lazyPermitted(0);

	$self->log(PROGRESS => 'Loaded delayed head.');
	$self->head;
}


sub loadBody()
{	my $self     = shift;

	my $body     = $self->body;
	$body->isDelayed or return;

	my $head     = $self->head;
	my $parser   = $self->parser or return;

	if($head->isDelayed)
	{	$head = $self->readHead($parser)
			or $self->log(ERROR => 'Unable to read delayed head.'), return;

		$self->log(PROGRESS => 'Loaded delayed head.');
		$self->head($head);
	}
	else
	{	my ($begin, $end) = $body->fileLocation;
		$parser->filePosition($begin);
	}

	my $newbody  = $self->readBody($parser, $head)
		or $self->log(ERROR => 'Unable to read delayed body.'), return;

	$self->log(PROGRESS => 'Loaded delayed body.');
	$self->storeBody($newbody->contentInfoFrom($head));
}

1;
