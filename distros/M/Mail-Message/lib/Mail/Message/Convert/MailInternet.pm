# This code is part of Perl distribution Mail-Message version 4.02.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::MailInternet;{
our $VERSION = '4.02';
}

use parent 'Mail::Message::Convert';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

use Mail::Internet ();
use Mail::Header   ();

use Mail::Message                 ();
use Mail::Message::Head::Complete ();
use Mail::Message::Body::Lines    ();

#--------------------

sub export($@)
{	my ($thing, $message) = (shift, shift);

	$message->isa('Mail::Message')
		or error __x"export message must be a Mail::Message object, but is {what UNKNOWN}.", what => $message;

	my $mi_head = Mail::Header->new;
	foreach my $field ($message->head->orderedFields)
	{	$mi_head->add($field->Name, scalar $field->foldedBody);
	}

	Mail::Internet->new(Header => $mi_head, Body => [ $message->body->lines ], @_);
}


my @pref_order = qw/From To Cc Subject Date In-Reply-To References Content-Type/;

sub from($@)
{	my ($thing, $mi) = (shift, shift);

	$mi->isa('Mail::Internet')
		or error __x"converting from Mail::Internet but got {what UNKNOWN}.", what => $mi;

	my $head = Mail::Message::Head::Complete->new;
	my $body = Mail::Message::Body::Lines->new(data => [ @{$mi->body} ]);

	my $mi_head = $mi->head;

	# The tags of Mail::Header are unordered, but we prefer some ordering.
	my %tags = map +(lc $_ => ucfirst $_), $mi_head->tags;
	my @tags;
	foreach (@pref_order)
	{	push @tags, $_ if delete $tags{lc $_};
	}
	push @tags, sort values %tags;

	foreach my $name (@tags)
	{	$head->add($name, $_) for $mi_head->get($name);
	}

	Mail::Message->new(head => $head, body => $body, @_);
}

1;
