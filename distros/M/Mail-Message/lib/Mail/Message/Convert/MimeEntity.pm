# This code is part of Perl distribution Mail-Message version 3.019.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Message::Convert::MimeEntity;{
our $VERSION = '3.019';
}

use base 'Mail::Message::Convert';

use strict;
use warnings;

use MIME::Entity   ();
use MIME::Parser   ();

use Mail::Message  ();

#--------------------

sub export($$;$)
{	my ($self, $message, $parser) = @_;
	defined $message or return ();

	$message->isa('Mail::Message')
		or $self->log(ERROR => "Export message must be a Mail::Message, but is a ".(ref $message)."."), return;

	$parser ||= MIME::Parser->new;
	$parser->parse($message->file);
}


sub from($)
{	my ($self, $mime_ent) = @_;
	defined $mime_ent or return ();

	$mime_ent->isa('MIME::Entity')
		or $self->log(ERROR => 'Converting from MIME::Entity but got a '.(ref $mime_ent).'.'), return;

	Mail::Message->read($mime_ent->as_string);
}

1;
