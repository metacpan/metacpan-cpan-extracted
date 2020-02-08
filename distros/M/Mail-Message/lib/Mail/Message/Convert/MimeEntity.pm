# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Convert::MimeEntity;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Convert';

use strict;
use warnings;

use MIME::Entity;
use MIME::Parser;
use Mail::Message;


sub export($$;$)
{   my ($self, $message, $parser) = @_;
    return () unless defined $message;

    $self->log(ERROR =>
       "Export message must be a Mail::Message, but is a ".ref($message)."."),
           return
              unless $message->isa('Mail::Message');

    $parser ||= MIME::Parser->new;
    $parser->parse($message->file);
}


sub from($)
{   my ($self, $mime_ent) = @_;
    return () unless defined $mime_ent;

    $self->log(ERROR =>
       'Converting from MIME::Entity but got a '.ref($mime_ent).'.'), return
            unless $mime_ent->isa('MIME::Entity');

    Mail::Message->read($mime_ent->as_string);
}

1;
