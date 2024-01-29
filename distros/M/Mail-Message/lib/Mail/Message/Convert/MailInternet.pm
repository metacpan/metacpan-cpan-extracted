# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Convert::MailInternet;
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

use Carp;


sub export($@)
{   my ($thing, $message) = (shift, shift);

    croak "Export message must be a Mail::Message, but is a ".ref($message)."."
        unless $message->isa('Mail::Message');

    my $mi_head = Mail::Header->new;

    my $head    = $message->head;
    foreach my $field ($head->orderedFields)
    {   $mi_head->add($field->Name, scalar $field->foldedBody);
    }

    Mail::Internet->new
     ( Header => $mi_head
     , Body   => [ $message->body->lines ]
     , @_
     );
}

#------------------------------------------


my @pref_order = qw/From To Cc Subject Date In-Reply-To References
    Content-Type/;

sub from($@)
{   my ($thing, $mi) = (shift, shift);

    croak "Converting from Mail::Internet but got a ".ref($mi).'.'
        unless $mi->isa('Mail::Internet');

    my $head = Mail::Message::Head::Complete->new;
    my $body = Mail::Message::Body::Lines->new(data => [ @{$mi->body} ]);

    my $mi_head = $mi->head;

    # The tags of Mail::Header are unordered, but we prefer some ordering.
    my %tags = map {lc $_ => ucfirst $_} $mi_head->tags;
    my @tags;
    foreach (@pref_order)
    {   push @tags, $_ if delete $tags{lc $_};
    }
    push @tags, sort values %tags;
    
    foreach my $name (@tags)
    {   $head->add($name, $_)
            foreach $mi_head->get($name);
    }

    Mail::Message->new(head => $head, body => $body, @_);
}

#------------------------------------------

1;
