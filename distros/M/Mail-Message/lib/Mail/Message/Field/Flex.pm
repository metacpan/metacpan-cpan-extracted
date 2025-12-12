# This code is part of Perl distribution Mail-Message version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::Flex;{
our $VERSION = '4.00';
}

use parent 'Mail::Message::Field';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

#--------------------

sub new($;$$@)
{	my $class  = shift;
	my $args
	  = @_ <= 2 || ! ref $_[-1] ? {}
	  : ref $_[-1] eq 'ARRAY'  ? { @{pop @_} }
  	  :    pop @_;

	my ($name, $body) = $class->consume(@_==1 ? (shift) : (shift, shift));
	defined $body or return ();

	# Attributes preferably stored in array to protect order.
	my $attr   = $args->{attributes};
	$attr      = [ %$attr ] if defined $attr && ref $attr eq 'HASH';
	push @$attr, @_;

	$class->SUPER::new(%$args, name => $name, body => $body, attributes => $attr);
}

sub init($)
{	my ($self, $args) = @_;

	@$self{ qw/MMFF_name MMFF_body/ } = @$args{ qw/name body/ };
	$self->comment($args->{comment}) if exists $args->{comment};

	my $attr = $args->{attributes};
	$self->attribute(shift @$attr, shift @$attr) while @$attr;

	$self;
}

sub clone()
{	my $self = shift;
	(ref $self)->new($self->Name, $self->body);
}

sub length()
{	my $self = shift;
	length($self->{MMFF_name}) + 1 + length($self->{MMFF_body});
}

sub name() { lc($_[0]->{MMFF_name}) }

sub Name() { $_[0]->{MMFF_name} }

sub folded(;$)
{	my $self = shift;

	wantarray
		or return $self->{MMFF_name}.':'.$self->{MMFF_body};

	my @lines = $self->foldedBody;
	my $first = $self->{MMFF_name}. ':'. shift @lines;
	($first, @lines);
}

sub unfoldedBody($;@)
{	my $self = shift;
	$self->{MMFF_body} = $self->fold($self->{MMFF_name}, @_) if @_;
	$self->unfold($self->{MMFF_body});
}

sub foldedBody($)
{	my ($self, $body) = @_;
	if(@_==2) { $self->{MMFF_body} = $body }
	else      { $body = $self->{MMFF_body} }

	wantarray ? (split /^/, $body) : $body;
}

1;
