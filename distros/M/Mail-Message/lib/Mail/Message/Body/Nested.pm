# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Body::Nested;{
our $VERSION = '3.020';
}

use base 'Mail::Message::Body';

use strict;
use warnings;

use Mail::Message::Body::Lines ();
use Mail::Message::Part        ();
use Carp;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{mime_type} ||= 'message/rfc822';

	$self->SUPER::init($args);

	my $nested;
	if(my $raw = $args->{nested})
	{	$nested = Mail::Message::Part->coerce($raw, $self)
			or croak 'Data not convertible to a message (type is ', ref $raw,")\n";
	}

	$self->{MMBN_nested} = $nested;
	$self;
}

sub clone()
{	my $self     = shift;
	(ref $self)->new($self->logSettings, based_on => $self, nested => $self->nested->clone);
}

sub isNested() { 1 }
sub isBinary() { $_[0]->nested->body->isBinary }
sub nrLines()  { $_[0]->nested->nrLines }
sub size()     { $_[0]->nested->size }

sub string()   { my $nested = $_[0]->nested; defined $nested ? $nested->string : '' }
sub lines()    { my $nested = $_[0]->nested; defined $nested ? $nested->lines  : () }
sub file()     { my $nested = $_[0]->nested; defined $nested ? $nested->file   : undef }
sub print(;$)  { my $self = shift; $self->nested->print(shift || select) }
sub endsOnNewline() { $_[0]->nested->body->endsOnNewline }

sub partNumberOf($)
{	my ($self, $part) = @_;
	$self->message->partNumber || '1';
}


sub foreachLine($)
{	my ($self, $code) = @_;
	$self->log(ERROR => "You cannot use foreachLine on a nested");
	confess;
}

sub check() { $_[0]->forNested( sub {$_[1]->check} ) }

sub encode(@)
{	my ($self, %args) = @_;
	$self->forNested( sub {$_[1]->encode(%args)} );
}

sub encoded() { $_[0]->forNested( sub { $_[1]->encoded } ) }

sub read($$$$)
{	my ($self, $parser, $head, $bodytype) = @_;

	my $nest = Mail::Message::Part->new(container => undef);
	$nest->readFromParser($parser, $bodytype)
		or return;

	$nest->container($self);
	$self->{MMBN_nested} = $nest;
	$self;
}

sub fileLocation()
{	my $nested   = shift->nested;
	( ($nested->head->fileLocation)[0], ($nested->body->fileLocation)[1] );
}

sub moveLocation($)
{	my $self   = shift;
	my $dist   = shift or return $self;  # no move

	my $nested = $self->nested;
	$nested->head->moveLocation($dist);
	$nested->body->moveLocation($dist);
	$self;
}

#--------------------

sub nested() { $_[0]->{MMBN_nested} }


sub forNested($)
{	my ($self, $code) = @_;
	my $nested    = $self->nested;
	my $body      = $nested->body;

	my $new_body  = $code->($self, $body) or return;
	$new_body != $body or return $self;

	my $new_nested  = Mail::Message::Part->new(head => $nested->head->clone, container => undef);
	$new_nested->body($new_body);

	my $created = (ref $self)->new(based_on => $self, nested => $new_nested);
	$new_nested->container($created);

	$created;
}

sub toplevel() { my $msg = $_[0]->message; $msg ? $msg->toplevel : undef}

1;
