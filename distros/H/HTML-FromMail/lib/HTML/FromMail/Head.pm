# This code is part of Perl distribution HTML-FromMail version 3.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail::Head;{
our $VERSION = '3.01';
}

use base 'HTML::FromMail::Page';

use strict;
use warnings;

use HTML::FromMail::Field  ();

#--------------------

sub init($)
{	my ($self, $args) = @_;
	$args->{topic} ||= 'head';
	$self->SUPER::init($args);
}

#-----------

#-----------


sub fields($$)
{	my ($thing, $realhead, $args) = @_;
	my $head = $realhead->clone;   # we are probably going to remove lines

	my $lg = $args->{remove_list_group};
	$head->removeListGroup    if $lg || !defined $lg;

	my $sg = $args->{remove_spam_groups};
	$head->removeSpamGroups   if $sg || !defined $sg;

	my $rg = $args->{remove_resent_groups};
	$head->removeResentGroups if $rg || !defined $rg;

	my @fields;
	if(my $select = $args->{select})
	{	my @select = split /\|/, $select;
		@fields    = map $head->grepNames($_), @select;
	}
	elsif(my $ignore = $args->{ignore})
	{	my @ignore = split /\|/, $ignore;
		local $"   = ")|(?:";
		my $skip   = qr/^(?:@ignore)/i;
		@fields    = grep $_->name !~ $skip, $head->orderedFields;
	}
	else
	{	@fields    = $head->orderedFields;
	}

	map $_->study, @fields;
}

1;
