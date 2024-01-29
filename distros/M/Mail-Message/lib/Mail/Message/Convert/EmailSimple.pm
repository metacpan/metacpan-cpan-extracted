# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.


package Mail::Message::Convert::EmailSimple;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message::Convert';

use strict;
use warnings;

use Mail::Internet;
use Mail::Header;
use Mail::Message;
use Mail::Message::Head::Complete;
use Mail::Message::Body::Lines;

use Email::Simple;
use Carp;


sub export($@)
{   my ($thing, $message) = (shift, shift);

    croak "Export message must be a Mail::Message, but is a ".ref($message)."."
        unless $message->isa('Mail::Message');

    Email::Simple->new($message->string);
}


sub from($@)
{   my ($thing, $email) = (shift, shift);

    croak "Converting from Email::Simple but got a ".ref($email).'.'
        unless $email->isa('Email::Simple');

    my $message = Mail::Message->read($email->as_string);
}

1;
