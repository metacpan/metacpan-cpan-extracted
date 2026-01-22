# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message;{
our $VERSION = '4.02';
}


use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error info trace/ ];

use Mail::Message::Body::Multipart ();
use Mail::Message::Body::Nested    ();

use Scalar::Util   qw/blessed/;

#--------------------

# tests in t/57forw1f.t

sub forward(@)
{	my $self    = shift;
	my %args    = @_;

	return $self->forwardNo(@_)
		if exists $args{body};

	my $include = $args{include} || 'INLINE';
	return $self->forwardInline(@_)      if $include eq 'INLINE';

	my $preamble = $args{preamble};
	push @_, preamble => Mail::Message::Body->new(data => $preamble)
		if defined $preamble && ! ref $preamble;

	return $self->forwardAttach(@_)      if $include eq 'ATTACH';
	return $self->forwardEncapsulate(@_) if $include eq 'ENCAPSULATE';

	error __x"cannot include forward source as {kind UNKNOWN}.", kind => $include;
	undef;
}


sub forwardNo(@)
{	my ($self, %args) = @_;
	my $body = $args{body} or error __x"method forwardNo requires a body.";
	my $to   = $args{To}   or error __x"method forwardNo requires a To.";

	#
	# Collect header info
	#

	my $mainhead = $self->toplevel->head;

	# Where it comes from
	my $from = $args{From};
	unless(defined $from)
	{	my @from = $self->to;
		$from    = \@from if @from;
	}

	# Create a subject
	my $srcsub  = $args{Subject};
	my $subject
	  = ! defined $srcsub ? $self->forwardSubject($self->subject)
	  : ref $srcsub       ? $srcsub->($self->subject)
	  :                     $srcsub;

	# Create a nice message-id
	my $msgid   = $args{'Message-ID'} || $mainhead->createMessageId;
	$msgid      = "<$msgid>" if $msgid && $msgid !~ /^\s*\<.*\>\s*$/;

	# Thread information
	my $origid  = '<'.$self->messageId.'>';
	my $refs    = $mainhead->get('references');

	my $forward = Mail::Message->buildFromBody(
		$body,
		From        => ($from || '(undisclosed)'),
		To          => $to,
		Subject     => $subject,
		References  => ($refs ? "$refs $origid" : $origid),
	);

	my $newhead = $forward->head;
	$newhead->set(Cc   => $args{Cc}  ) if $args{Cc};
	$newhead->set(Bcc  => $args{Bcc} ) if $args{Bcc};
	$newhead->set(Date => $args{Date}) if $args{Date};

	# Ready

	$self->label(passed => 1);
	trace "Forward created from $origid";
	$forward;
}


sub forwardInline(@)
{	my ($self, %args) = @_;

	my $body     = $self->body;

	while(1)    # simplify
	{	if($body->isMultipart && $body->parts==1) {	$body = $body->part(0)->body }
		elsif($body->isNested) { $body = $body->nested->body }
		else                   { last }
	}

	# Prelude must be a real body, otherwise concatenate will not work
	my $prelude = exists $args{prelude} ? $args{prelude} : $self->forwardPrelude;

	$prelude    = Mail::Message::Body->new(data => $prelude)
		if defined $prelude && ! blessed $prelude;

	# Postlude
	my $postlude = exists $args{postlude} ? $args{postlude} : $self->forwardPostlude;

	# Binary bodies cannot be inlined, therefore they will be rewritten
	# into a forwardAttach... preamble must replace prelude and postlude.

	if($body->isMultipart || $body->isBinary)
	{	$args{preamble} ||= $prelude->concatenate(
			$prelude,
			($args{is_attached} || "[The forwarded message is attached]\n"),
			$postlude,
		);
		return $self->forwardAttach(%args);
	}

	$body     = $body->decoded;
	if((!exists $args{strip_signature} || $args{strip_signature}) && !$body->isNested)
	{	$body = $body->stripSignature(pattern => $args{strip_signature}, max_lines => $args{max_signature});
	}

	if(defined(my $quote = $args{quote}))
	{	my $quoting = ref $quote ? $quote : sub { $quote . $_ };
		$body = $body->foreachLine($quoting);
	}

	#
	# Create the message.
	#

	my $signature = $args{signature};
	$signature = $signature->body
		if defined $signature && $signature->isa('Mail::Message');

	my $composed  = $body->concatenate(
		$prelude, $body, $postlude,
		(defined $signature ? "-- \n" : undef), $signature
	);

	$self->forwardNo(%args, body => $composed);
}


sub forwardAttach(@)
{	my ($self, %args) = @_;

	my $body  = $self->body;
	if($body->isMultipart)
	{	$body = $body->stripSignature(pattern => $args{strip_signature}, max_lines => $args{max_signature})
			if !exists $args{strip_signature} || $args{strip_signature};
		$body = $body->part(0)->body if $body->parts == 1;
	}

	my $preamble = $args{preamble}
		or error __x"method forwardAttach requires a preamble.";

	my @parts = ($preamble, $body);
	push @parts, $args{signature} if defined $args{signature};
	my $multi = Mail::Message::Body::Multipart->new(parts => \@parts);

	$self->forwardNo(%args, body => $multi);
}


sub forwardEncapsulate(@)
{	my ($self, %args) = @_;

	my $preamble = $args{preamble}
		or error __x"method forwardEncapsulate requires a preamble.";

	my $nested   = Mail::Message::Body::Nested->new(nested => $self->clone);
	my @parts    = ($preamble, $nested);
	push @parts, $args{signature} if defined $args{signature};

	my $multi    = Mail::Message::Body::Multipart->new(parts => \@parts);
	$self->forwardNo(%args, body => $multi);
}


# tests in t/57forw0s.t

sub forwardSubject($)
{	my ($self, $subject) = @_;
	defined $subject && length $subject ? "Forw: $subject" : "Forwarded";
}


sub forwardPrelude()
{	my $head  = shift->head;

	my @lines = "---- BEGIN forwarded message\n";
	my $from  = $head->get('from');
	my $to    = $head->get('to');
	my $cc    = $head->get('cc');
	my $date  = $head->get('date');

	push @lines, $from->string if defined $from;
	push @lines,   $to->string if defined $to;
	push @lines,   $cc->string if defined $cc;
	push @lines, $date->string if defined $date;
	push @lines, "\n";

	\@lines;
}


sub forwardPostlude()
{	my $self = shift;
	[ "---- END forwarded message\n" ];
}

#--------------------

1;
