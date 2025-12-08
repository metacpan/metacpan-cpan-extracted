# This code is part of Perl distribution Mail-Message version 3.020.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::MailInternet;{
our $VERSION = '3.020';
}

use base 'Mail::Message::Convert';

use strict;
use warnings;

use Mail::Internet ();
use Mail::Header   ();
use Carp;

use Mail::Message                 ();
use Mail::Message::Head::Complete ();
use Mail::Message::Body::Lines    ();

#--------------------

sub export($@)
{	my ($thing, $message) = (shift, shift);

	$message->isa('Mail::Message')
		or croak "Export message must be a Mail::Message, but is a ".(ref $message).".";

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
		or croak "Converting from Mail::Internet but got a ".(ref $mi).'.';

	my $head = Mail::Message::Head::Complete->new;
	my $body = Mail::Message::Body::Lines->new(data => [ @{$mi->body} ]);

	my $mi_head = $mi->head;

	# The tags of Mail::Header are unordered, but we prefer some ordering.
	my %tags = map {lc $_ => ucfirst $_} $mi_head->tags;
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
