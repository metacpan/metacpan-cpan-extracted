# This code is part of Perl distribution HTML-FromMail version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail::Message;{
our $VERSION = '4.00';
}

use base 'HTML::FromMail::Page';

use strict;
use warnings;

use Log::Report 'html-frommail';

use HTML::FromMail::Head  ();
use HTML::FromMail::Field ();
use HTML::FromMail::Default::Previewers ();
use HTML::FromMail::Default::HTMLifiers ();

use File::Basename   qw/basename/;

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{topic} ||= 'message';
	$self->SUPER::init($args);

	$self->{HFM_dispose}  = $args->{disposition};
	my $settings = $self->settings;

	# Collect previewers
	my @prevs = @HTML::FromMail::Default::Previewers::previewers;
	if(my $prevs = $settings->{previewers})
	{	unshift @prevs, @$prevs;
	}
	$self->{HFM_previewers} = \@prevs;

	# Collect htmlifiers
	my @html = @HTML::FromMail::Default::HTMLifiers::htmlifiers;
	if(my $html = $settings->{htmlifiers})
	{	unshift @html, @$html;
	}
	$self->{HFM_htmlifiers} = \@html;

	# We will use header and field formatters
	$self->{HFM_field} = HTML::FromMail::Field->new(settings => $settings);
	$self->{HFM_head}  = HTML::FromMail::Head ->new(settings => $settings);

	$self;
}

#-----------

sub fields() { $_[0]->{HFM_field} }


sub header() { $_[0]->{HFM_head} }

#-----------


my $attach_id = 0;

sub createAttachment($$$)
{	my ($self, $message, $part, $args) = @_;
	my $outdir   = $args->{outdir} or panic;
	my $decoded  = $part->decoded;

	my $filename = $part->label('filename');
	unless(defined $filename)
	{	$filename = $decoded->dispositionFilename($outdir);
		$part->label(filename => $filename);
	}

	$decoded->write(filename => $filename);

	 +(	url      => basename($filename),
		size     => (-s $filename),
		type     => $decoded->type->body,

		filename => $filename,    # absolute
		decoded  => $decoded,
	  );
}


sub htmlField($$)
{	my ($self, $message, $args) = @_;

	my $name  = $args->{name};
	unless(defined $name)
	{	warning __x"no field name specified in {template}.", template => $args->{input};
		$name = "NONE";
	}

	my $current = $self->lookup('part_object', $args);

	my $head;
	for($args->{from} || 'PART')
	{	my $source = ($_ eq 'PART' ? $current : $_ eq 'PARENT' ? $current->container : undef) || $message;
		$head      = $source->head;
	}

	my @fields  = $self->fields->fromHead($head, $name, $args);

	$args->{formatter}->onFinalToken($args)
		or return [ map +{ field_object => $_ }, @fields ];

	my $f       = $self->fields;
	join "<br />\n", map $f->htmlBody($_, $args), @fields;
}


sub htmlSubject($$)
{	my ($self, $message, $args) = @_;
	my %args = (%$args, name => 'subject', from => 'NESSAGE');
	$self->htmlField($message, \%args);
}


sub htmlName($$)
{	my ($self, $message, $args) = @_;

	my $field = $self->lookup('field_object', $args)
		or error __x"use of 'name' outside field container.";  #XXX better message?

	$self->fields->htmlName($field, $args);
}


sub htmlBody($$)
{	my ($self, $message, $args) = @_;

	my $field = $self->lookup('field_object', $args)
		or error __x"use of 'body' outside field container";

	$self->fields->htmlBody($field, $args);
}


sub htmlAddresses($$)
{	my ($self, $message, $args) = @_;

	my $field = $self->lookup('field_object', $args)
		or error __x"use of 'addresses' outside field container";

	$self->fields->htmlAddresses($field, $args);
}


sub htmlHead($$)
{	my ($self, $message, $args) = @_;

	my $current = $self->lookup('part_object', $args) || $message;
	my $head    = $current->head or return;
	my @fields  = $self->header->fields($head, $args);

	$args->{formatter}->onFinalToken($args)
		or return [ map +{ field_object => $_ }, @fields ];

	local $" = '';
	"<pre>@{ [ map $_->string, @fields ] }</pre>\n";
}


sub htmlMessage($$)
{	my ($self, $message, $args) = @_;
	+{ message_text => $args->{formatter}->containerText($args) };
}


sub htmlMultipart($$)
{	my ($self, $message, $args) = @_;
	my $current = $self->lookup('part_object', $args) || $message;
	$current->isMultipart or return '';

	my $body = $current->body;    # un-decoded info is more useful
	+{ type => $body->mimeType->type, size => $body->size };
}


sub htmlNested($$)
{	my ($self, $message, $args) = @_;
	my $current = $self->lookup('part_object', $args) || $message;
	$current->isNested or return '';

	my $partnr  = $self->lookup('part_number', $args);
	$partnr    .= '.' if length $partnr;

	[ +{ part_number => $partnr . '1', part_object => $current->body->nested } ];
}


sub htmlifier($)
{	my ($self, $type) = @_;
	my $pairs = $self->{HFM_htmlifiers};
	for(my $i=0; $i < @$pairs; $i+=2)
	{	return $pairs->[$i+1] if $type eq $pairs->[0];
	}
	undef;
}


sub previewer($)
{	my ($self, $type) = @_;
	my $pairs = $self->{HFM_previewers};
	for(my $i=0; $i < @$pairs; $i+=2)
	{	return $pairs->[$i+1] if $type eq $pairs->[$i] || $type->mediaType eq $pairs->[$i];
	}
	undef;
}


sub disposition($$$)
{	my ($self, $message, $part, $args) = @_;
	return '' if $part->isMultipart || $part->isNested;

	my $cd   = $part->head->get('Content-Disposition');

	my $sugg = defined $cd ? lc($cd->body) : '';
	$sugg    = 'attach' if $sugg =~ m/^\s*attach/;

	my $body = $part->body;
	my $type = $body->mimeType;

	if($sugg eq 'inline')
	{	$sugg = $self->htmlifier($type) ? 'inline' : $self->previewer($type) ? 'preview' :  'attach';
	}
	elsif($sugg eq 'attach')
	{	$sugg = 'preview' if $self->previewer($type);
	}
	elsif($self->htmlifier($type)) { $sugg = 'inline' }
	elsif($self->previewer($type)) { $sugg = 'preview' }
	else                           { $sugg = 'attach'  }

	# User may have a different opinion.
	my $disp = $self->settings->{disposition} or return $sugg;
	$disp->($message, $part, $sugg, $args)
}


sub htmlInline($$)
{	my ($self, $message, $args) = @_;

	my $current = $self->lookup('part_object', $args) || $message;
	my $dispose = $self->disposition($message, $current, $args);
	$dispose eq 'inline' or return '';

	my @attach  = $self->createAttachment($message, $current, $args);
	my $inliner = $self->htmlifier($current->body->mimeType);
	my $inline  = $inliner->($self, $message, $current, $args);

	+{ %$inline, @attach };
}


sub htmlAttach($$)
{	my ($self, $message, $args) = @_;

	my $current = $self->lookup('part_object', $args) || $message;
	my $dispose = $self->disposition($message, $current, $args);
	$dispose eq 'attach' or return '';

	my %attach  = $self->createAttachment($message, $current, $args);
	\%attach;
}


sub htmlPreview($$)
{	my ($self, $message, $args) = @_;

	my $current   = $self->lookup('part_object', $args) || $message;
	my $dispose   = $self->disposition($message, $current, $args);
	$dispose eq 'preview' or return '';

	my %attach    = $self->createAttachment($message, $current, $args);
	my $previewer = $self->previewer($current->body->mimeType);
	$previewer->($self, $message, $current, \%attach, $args);
}


sub htmlForeachPart($$)
{	my ($self, $message, $args) = @_;
	my $part     = $self->lookup('part_object', $args) || $message;

	$part or error __x"foreachPart not used within part.";
	$part->isMultipart or error __x"foreachPart outside multipart.";

	my $parentnr = $self->lookup('part_number',$args) || '';
	$parentnr   .= '.' if length $parentnr;

	my @parts   = $part->parts;
	my @part_data;

	for(my $partnr = 0; $partnr < @parts; $partnr++)
	{	push @part_data, +{
			part_number => $parentnr . ($partnr+1),
			part_object => $parts[$partnr],
		};
	}

	\@part_data;
}


sub htmlRawText($$)
{	my ($self, $message, $args) = @_;
	my $part = $self->lookup('part_object', $args) || $message;
	$self->plain2html($part->decoded->string);
}


sub htmlPart($$)
{	my ($self, $message, $args) = @_;
	my $format  = $args->{formatter};
	my $msg     = $format->lookup('message_text', $args);

	defined $msg or error __x"part outside a 'message' block.";
	$format->processText($msg, $args);
}

#--------------------

1;
