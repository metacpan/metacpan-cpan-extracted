# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::MimeEntity;{
our $VERSION = '4.03';
}

use parent 'Mail::Message::Convert';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error/ ];

use MIME::Entity   ();
use MIME::Parser   ();

use Mail::Message  ();

#--------------------

sub export($$;$)
{	my ($self, $message, $parser) = @_;
	defined $message or return ();

	$message->isa('Mail::Message')
		or error __x"export message must be a Mail::Message object, but is {what UNKNOWN}.", what => $message;

	$parser ||= MIME::Parser->new;
	$parser->parse($message->file);
}


sub from($)
{	my ($self, $mime_ent) = @_;
	defined $mime_ent or return ();

	$mime_ent->isa('MIME::Entity')
		or error __x"converting from MIME::Entity but got a {class}.", class => ref $mime_ent;

	Mail::Message->read($mime_ent->as_string);
}

1;
