# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Field::URIs;{
our $VERSION = '4.03';
}

use parent 'Mail::Message::Field::Structured';

use warnings;
use strict;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

use URI           ();
use Scalar::Util  qw/blessed/;

#--------------------

#--------------------

sub init($)
{	my ($self, $args) = @_;

	my ($body, @body);
	if($body = delete $args->{body})
	{	@body = ref $body eq 'ARRAY' ? @$body : ($body);
		@body or return ();
	}

	$self->{MMFU_uris} = [];

	if(@body > 1 || blessed $body[0])
	{	$self->addURI($_) for @body;
	}
	elsif(defined $body)
	{	$body = "<$body>\n" unless index($body, '<') >= 0;
		$args->{body} = $body;
	}

	$self->SUPER::init($args);
}

sub parse($)
{	my ($self, $string) = @_;
	my @raw = $string =~ m/\<([^>]+)\>/g;  # simply ignore all but <>
	$self->addURI($_) for @raw;
	$self;
}

sub produceBody()
{	my @uris = sort map $_->as_string, $_[0]->URIs;
	local $" = '>, <';
	@uris ? "<@uris>" : undef;
}

#--------------------

sub addURI(@)
{	my $self  = shift;
	my $uri   = blessed $_[0] ? shift : URI->new(@_);
	push @{$self->{MMFU_uris}}, $uri->canonical if defined $uri;
	delete $self->{MMFF_body};
	$uri;
}


sub URIs() { @{ $_[0]->{MMFU_uris}} }


sub addAttribute($;@)
{	my $self = shift;
	error __x"no attributes for URI fields.";
}

#--------------------

1;
