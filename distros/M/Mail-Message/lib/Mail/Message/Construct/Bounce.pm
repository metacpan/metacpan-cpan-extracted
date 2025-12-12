# This code is part of Perl distribution Mail-Message version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message;{
our $VERSION = '4.00';
}


use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error trace/ ];

use Mail::Message::Head::Complete ();
use Mail::Message::Field          ();

#--------------------

sub bounce(@)
{	my $self   = shift;
	my $bounce = $self->clone;
	my $head   = $bounce->head;

	if(@_==1 && ref $_[0] && $_[0]->isa('Mail::Message::Head::ResentGroup' ))
	{	$head->addResentGroup(shift);
		return $bounce;
	}

	my @rgs    = $head->resentGroups;
	my $rg     = $rgs[0];

	if(defined $rg)
	{	$rg->delete;     # Remove group to re-add it later: otherwise
		while(@_)        #   field order in header would be disturbed.
		{	my $field = shift;
			ref $field ? $rg->set($field) : $rg->set($field, shift);
		}
	}
	elsif(@_)
	{	$rg = Mail::Message::Head::ResentGroup->new(@_);
	}
	else
	{	error __x"method bounce requires To, Cc, or Bcc.";
	}

	$rg->set(Date => Mail::Message::Field->toDate) unless defined $rg->date;

	unless(defined $rg->messageId)
	{	my $msgid = $head->createMessageId;
		$rg->set('Message-ID' => "<$msgid>");
	}

	$head->addResentGroup($rg);

	# Flag action to original message
	$self->label(passed => 1);    # used by some maildir clients

	$bounce;
}

1;
