# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::EmailSimple;{
our $VERSION = '4.03';
}

use parent 'Mail::Message::Convert';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

use Mail::Internet  ();
use Mail::Header    ();
use Email::Simple   ();

use Mail::Message                 ();
use Mail::Message::Head::Complete ();
use Mail::Message::Body::Lines    ();

#--------------------

sub export($@)
{	my ($thing, $message) = @_;

	$message->isa('Mail::Message')
		or error __x"export message must be a Mail::Message, but is a {class}.", class => ref $message;

	Email::Simple->new($message->string);
}


sub from($@)
{	my ($thing, $email) = (shift, shift);

	$email->isa('Email::Simple')
		or error __x"converting from Email::Simple but got a {class}.", class => ref $email;

	Mail::Message->read($email->as_string);
}

1;
