# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::DKIM;{
our $VERSION = '3.020';
}

use base 'Mail::Message::Field::Structured';

use warnings;
use strict;

use URI      ();

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$self->{MMFD_tags} = +{ v => 1, a => 'rsa-sha256' };

	$self->SUPER::init($args);
	$self;
}

sub parse($)
{	my ($self, $string) = @_;
	my $tags = $self->{MMFD_tags};

	foreach (split /\;/, $string)
	{	m/^\s*([a-z][a-z0-9_]*)\s*\=\s*([\s\x21-\x7E]+?)\s*$/is or next;
		# tag-values stay unparsed (for now)
		$self->addTag($1, $2);
	}

	(undef, $string) = $self->consumeComment($string);
	$self;
}

sub produceBody()
{	my $self = shift;
}

#--------------------


sub addAttribute($;@)
{	my $self = shift;
	$self->log(ERROR => 'No attributes for DKIM headers.');
	$self;
}


sub addTag($$)
{	my ($self, $name) = (shift, lc shift);
	$self->{MMFD_tags}{$name} = join ' ', @_;
	$self;
}


sub tag($) { $_[0]->{MMFD_tags}{lc $_[1]} }


#--------------------

sub tagAlgorithm() { $_[0]->tag('a') }
sub tagSignData()  { $_[0]->tag('b') }
sub tagSignature() { $_[0]->tag('bh') }
sub tagC14N()      { $_[0]->tag('c') }
sub tagDomain()    { $_[0]->tag('d') }
sub tagSignedHeaders() { $_[0]->tag('h') }
sub tagAgentID()   { $_[0]->tag('i') }
sub tagBodyLength(){ $_[0]->tag('l') }
sub tagQueryMethods()  { $_[0]->tag('q') }
sub tagSelector()  { $_[0]->tag('s') }
sub tagTimestamp() { $_[0]->tag('t') }
sub tagExpires()   { $_[0]->tag('x') }
sub tagVersion()   { $_[0]->tag('v') }
sub tagExtract()   { $_[0]->tag('z') }

#--------------------

1;
