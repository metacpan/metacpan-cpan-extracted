# This code is part of Perl distribution HTML-FromMail version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail::Field;{
our $VERSION = '4.00';
}

use base 'HTML::FromMail::Page';

use strict;
use warnings;

use Log::Report 'html-frommail';

use Mail::Message::Field::Full ();

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{topic} ||= 'field';
	$self->SUPER::init($args);
}

#-----------

#-----------

sub fromHead($$@)
{	my ($self, $head, $name, $args) = @_;
	$head->study($name);
}


sub htmlName($$$)
{	my ($self, $field, $args) = @_;
	defined $field or return;

	my $reform = $args->{capitals} || $self->settings->{names} || 'UNCHANGED';
	$self->plain2html($reform ? $field->wellformedName : $field->Name);
}


sub htmlBody($$$)
{	my ($self, $field, $args) = @_;

	my $settings = $self->settings;
	my $wrap     = $args->{wrap} || $settings->{wrap};
	my $content  = $args->{content} || $settings->{content} || (defined $wrap && 'REFOLD') || 'DECODED';

	if($field->isa('Mail::Message::Field::Addresses'))
	{	my $how  = $args->{address} || $settings->{address} || 'MAILTO';
		$how eq 'PLAIN' or return $self->addressField($field, $how, $args)
	}

	return $self->plain2html($field->unfoldedBody)
		if $content eq 'UNFOLDED';

	$field->setWrapLength($wrap || 78)
		if $content eq 'REFOLD';

	$self->plain2html($field->foldedBody);
}


sub addressField($$$)
{	my ($self, $field, $how, $args) = @_;
	return $self->plain2html($field->foldedBody) if $how eq 'PLAIN';

	return join ",<br />", map $_->address, $field->addresses
		if $how eq 'ADDRESS';

	return join ",<br />", map {$_->phrase || $_->address} $field->addresses
		if $how eq 'PHRASE';

	if($how eq 'MAILTO')
	{	my @links;
		foreach my $address ($field->addresses)
		{	my $addr   = $address->address;
			my $phrase = $address->phrase || $addr;
			push @links, qq[<a href="mailto:$addr">$phrase</a>];
		}
		return join ",<br />", @links;
	}

	if($how eq 'LINK')
	{	my @links;
		foreach my $address ($field->addresses)
		{	my $addr   = $address->address;
			my $phrase = $address->phrase || '';
			push @links, qq[$phrase &lt;<a href="mailto:$addr">$addr</a>&gt;];
		}
		return join ",<br />", @links;
	}

	error __x"don't know address field formatting '{how}'.", how => $how;
}


sub htmlAddresses($$)
{	my ($self, $field, $args) = @_;
	$field->can('addresses') or return undef;

	my @addrs;
	foreach my $address ($field->addresses)
	{	my %addr = (
			email   => $address->address,
			address => $self->plain2html($address->string),
		);

		if(defined(my $phrase = $address->phrase))
		{	$addr{phrase} = $self->plain2html($phrase);
		}

		push @addrs, \%addr;
	}

	\@addrs;
}

#--------------------

1;
