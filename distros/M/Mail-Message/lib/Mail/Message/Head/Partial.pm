# This code is part of Perl distribution Mail-Message version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Head::Partial;{
our $VERSION = '4.00';
}

use parent 'Mail::Message::Head::Complete';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw// ];

use Scalar::Util   qw/weaken/;

#--------------------

sub removeFields(@)
{	my $self  = shift;
	my $known = $self->{MMH_fields};

	foreach my $match (@_)
	{
		if(ref $match)
		     { $_ =~ $match && delete $known->{$_} for keys %$known }
		else { delete $known->{lc $match} }
	}

	$self->cleanupOrderedFields;
}


sub removeFieldsExcept(@)
{	my $self   = shift;
	my $known  = $self->{MMH_fields};
	my %remove = map +($_ => 1), keys %$known;

	foreach my $match (@_)
	{	if(ref $match)
		     { $_ =~ $match && delete $remove{$_} for keys %remove }
		else { delete $remove{lc $match} }
	}

	delete @$known{ keys %remove };
	$self->cleanupOrderedFields;
}


sub removeResentGroups()
{	my $self = shift;
	require Mail::Message::Head::ResentGroup;

	my $known = $self->{MMH_fields};
	my $found = 0;
	foreach my $name (keys %$known)
	{	Mail::Message::Head::ResentGroup->isResentGroupFieldName($name) or next;
		delete $known->{$name};
		$found++;
	}

	$self->cleanupOrderedFields;
	$self->modified(1) if $found;
	$found;
}


sub removeListGroup()
{	my $self = shift;
	require Mail::Message::Head::ListGroup;

	my $known = $self->{MMH_fields};
	my $found = 0;
	foreach my $name (keys %$known)
	{	Mail::Message::Head::ListGroup->isListGroupFieldName($name) or next;
		delete $known->{$name};
		$found++;
	}

	$self->cleanupOrderedFields if $found;
	$self->modified(1) if $found;
	$found;
}


sub removeSpamGroups()
{	my $self = shift;
	require Mail::Message::Head::SpamGroup;

	my $known = $self->{MMH_fields};
	my $found = 0;
	foreach my $name (keys %$known)
	{	Mail::Message::Head::SpamGroup->isSpamGroupFieldName($name) or next;
		delete $known->{$name};
		$found++;
	}

	$self->cleanupOrderedFields if $found;
	$self->modified(1) if $found;
	$found;
}


sub cleanupOrderedFields()
{	my $self = shift;
	my @take = grep defined, @{$self->{MMH_order}};
	weaken($_) for @take;
	$self->{MMH_order} = \@take;
	$self;
}

#--------------------

1;
