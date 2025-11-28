# This code is part of Perl distribution Mail-Box version 3.012.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::File::Message;{
our $VERSION = '3.012';
}

use parent 'Mail::Box::Message';

use strict;
use warnings;

use List::Util   qw/sum/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->fromLine($args->{from_line})
		if exists $args->{from_line};

	$self;
}
#--------------------

sub fromLine(;$)
{	my $self = shift;
	$self->{MBMM_from_line} = shift if @_;
	$self->{MBMM_from_line} ||= $self->head->createFromLine;
}

#--------------------

sub coerce($)
{	my ($self, $message) = @_;
	return $message if $message->isa(__PACKAGE__);
	$self->SUPER::coerce($message)->labelsToStatus;
}


sub write(;$)
{	my $self  = shift;
	my $out   = shift || select;

	my $escaped = $self->escapedBody;
	$out->print($self->fromLine);

	my $size  = sum 0, map length, @$escaped;

	my $head  = $self->head;
	$head->set('Content-Length' => $size);
	$head->set('Lines' => scalar @$escaped);
	$head->print($out);

	$out->print($_) for @$escaped;
	$out->print("\n");
	$self;
}

sub clone()
{	my $self  = shift;
	my $clone = $self->SUPER::clone;
	$clone->{MBMM_from_line} = $self->fromLine;
	$clone;
}


sub escapedBody()
{	my @lines = shift->body->lines;
	s/^(\>*From )/>$1/ for @lines;
	\@lines;
}

#--------------------

sub readFromParser($)
{	my ($self, $parser) = @_;
	my ($start, $fromline)  = $parser->readSeparator;
	$fromline or return;

	$self->{MBMM_from_line} = $fromline;
	$self->{MBMM_begin}     = $start;

	$self->SUPER::readFromParser($parser) or return;
	$self;
}

sub loadHead() { $_[0]->head }


sub loadBody()
{	my $self     = shift;
	my $body     = $self->body;
	$body->isDelayed or return $body;

	my ($begin, $end) = $body->fileLocation;
	my $parser   = $self->folder->parser;
	$parser->filePosition($begin);

	my $newbody  = $self->readBody($parser, $self->head)
		or $self->log(ERROR => 'Unable to read delayed body.'), return;

	$self->log(PROGRESS => 'Loaded delayed body.');
	$self->storeBody($newbody->contentInfoFrom($self->head));
	$newbody;
}


sub fileLocation()
{	my $self = shift;

	wantarray
	  ? ($self->{MBMM_begin}, ($self->body->fileLocation)[1])
	  : $self->{MBMM_begin};
}


sub moveLocation($)
{	my ($self, $dist) = @_;
	$self->{MBMM_begin} -= $dist;

	$self->head->moveLocation($dist);
	$self->body->moveLocation($dist);
	$self;
}

1;
