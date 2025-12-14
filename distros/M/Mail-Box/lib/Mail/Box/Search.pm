# This code is part of Perl distribution Mail-Box version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Search;{
our $VERSION = '4.01';
}

use parent 'Mail::Reporter';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw/__x error/ ];

#--------------------

sub init($)
{	my ($self, $args) = @_;

	$self->SUPER::init($args);

	my $in = $args->{in} || 'BODY';
	@$self{ qw/MBS_check_head MBS_check_body/ }
	  = $in eq 'BODY'    ? (0,1)
	  : $in eq 'HEAD'    ? (1,0)
	  : $in eq 'MESSAGE' ? (1,1)
	  :    error __x"search in BODY, HEAD or MESSAGE, not {what UNKNOWN}.", what => $in;

	! $self->{MBS_check_head} || $self->can('inHead') or error __x"cannot search in header.";
	! $self->{MBS_check_body} || $self->can('inBody') or error __x"cannot search in body.";

	my $deliver             = $args->{deliver};
	$self->{MBS_deliver}
	  = ref $deliver eq 'CODE' ? sub { $deliver->($self, $_[0]) }
	  : !defined $deliver      ? undef
	  : $deliver eq 'DELETE'   ? sub { $_[0]->{part}->toplevel->label(deleted => 1) }
	  :    error __x"don't know how to deliver results in {what UNKNOWN}.", what => $deliver;

	my $logic               = $args->{logical}  || 'REPLACE';
	$self->{MBS_negative}   = $logic =~ s/\s*NOT\s*$//;
	$self->{MBS_logical}    = $logic;

	$self->{MBS_label}      = $args->{label};
	$self->{MBS_binaries}   = $args->{binaries} || 0;
	$self->{MBS_limit}      = $args->{limit}    || 0;
	$self->{MBS_decode}     = $args->{decode}   || 1;
	$self->{MBS_no_deleted} = not $args->{deleted};
	$self->{MBS_delayed}    = exists $args->{delayed} ? $args->{delayed} : 1;
	$self->{MBS_multiparts} = exists $args->{multiparts} ? $args->{multiparts} : 1;

	$self;
}

#--------------------

sub deliver()      { $_[0]->{MBS_deliver} }
sub doMultiparts() { $_[0]->{MBS_multiparts} }
sub parseDelayed() { $_[0]->{MBS_delayed} }
sub skipDeleted()  { $_[0]->{MBS_no_deleted} }

#--------------------

sub search(@)
{	my ($self, $object) = @_;

	my $label         = $self->{MBS_label};
	my $limit         = $self->{MBS_limit};

	my @messages
	  = ref $object eq 'ARRAY'        ? @$object
	  : $object->isa('Mail::Box')     ? $object->messages
	  : $object->isa('Mail::Message') ? ($object)
	  : $object->isa('Mail::Box::Thread::Node') ? $object->threadMessages
	  :   error __x"expect messages to search, not {what UNKNOWN}.", what => $object;

	my $take = 0;
	   if($limit < 0) { $take = -$limit; @messages = reverse @messages }
	elsif($limit > 0) { $take = $limit }
	elsif(!defined $label && !wantarray && !$self->deliver) {$take = 1 }

	my $logic         = $self->{MBS_logical};
	my @selected;
	my $count = 0;

	foreach my $message (@messages)
	{	next if $self->skipDeleted && $message->isDeleted;
		next unless $self->parseDelayed || !$message->isDelayed;

		my $set = defined $label ? $message->label($label) : 0;

		my $selected
		  =  $set && $logic eq 'OR'  ? 1
		  : !$set && $logic eq 'AND' ? 0
		  : $self->{MBS_negative}    ? ! $self->searchPart($message)
		  :    $self->searchPart($message);

		$message->label($label => $selected) if defined $label;
		if($selected)
		{	push @selected, $message;
			$count++;
			last if $take && $count == $take;
		}
	}

	$limit < 0 ? reverse @selected : @selected;
}



sub searchPart($)
{	my ($self, $part) = @_;

	my $matched = 0;
	$matched  = $self->inHead($part, $part->head)
	if $self->{MBS_check_head};

	return $matched unless $self->{MBS_check_body};
	return $matched if $matched && !$self->deliver;

	my $body  = $part->body;
	my @bodies;

	# Handle multipart parts.

	if($body->isMultipart)
	{	$self->doMultiparts or return $matched;

		@bodies = ($body->preamble, $body->epilogue);

		foreach my $piece (grep defined, $body->parts)
		{	next if $piece->isDelayed && ! $self->parseDelayed;

			$matched += $self->searchPart($piece);
			return $matched if $matched && !$self->deliver;
		}
	}
	elsif($body->isNested)
	{	$self->doMultiparts or return $matched;
		$matched += $self->searchPart($body->nested);
	}
	else
	{	@bodies = ($body);
	}

	# Handle normal bodies.

	foreach (grep defined, @bodies)
	{	next if !$self->{MBS_binaries} && $_->isBinary;
		my $body   = $self->{MBS_decode} ? $_->decoded : $_;
		my $inbody = $self->inBody($part, $body);
		$matched  += $inbody;
	}

	$matched;
}


sub inHead(@) { $_[0]->notImplemented }


sub inBody(@) { $_[0]->notImplemented }

#--------------------

sub printMatch($) { $_[0]->notImplemented }

1;
