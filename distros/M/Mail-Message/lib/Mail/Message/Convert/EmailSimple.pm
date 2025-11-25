# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::EmailSimple;{
our $VERSION = '3.019';
}

use base 'Mail::Message::Convert';

use strict;
use warnings;

use Mail::Internet  ();
use Mail::Header    ();
use Email::Simple   ();
use Carp;

use Mail::Message                 ();
use Mail::Message::Head::Complete ();
use Mail::Message::Body::Lines    ();

#--------------------

sub export($@)
{	my ($thing, $message) = (shift, shift);

	$message->isa('Mail::Message')
		or croak "Export message must be a Mail::Message, but is a ".ref($message).".";

	Email::Simple->new($message->string);
}


sub from($@)
{	my ($thing, $email) = (shift, shift);

	$email->isa('Email::Simple')
		or croak "Converting from Email::Simple but got a ".ref($email).'.';

	Mail::Message->read($email->as_string);
}

1;
