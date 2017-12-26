# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

use strict;
use warnings;

package Mail::Message::Convert::MimeEntity;
use vars '$VERSION';
$VERSION = '3.005';

use base 'Mail::Message::Convert';

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
