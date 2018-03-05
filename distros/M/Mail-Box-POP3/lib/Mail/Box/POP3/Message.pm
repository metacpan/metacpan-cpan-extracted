# Copyrights 2001-2018 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Box-POP3.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::POP3::Message;
use vars '$VERSION';
$VERSION = '3.004';

use base 'Mail::Box::Net::Message';

use strict;
use warnings;


sub init($)
{   my ($self, $args) = @_;

    $args->{body_type} ||= 'Mail::Message::Body::Lines';

    $self->SUPER::init($args);
    $self;
}


sub size($)
{   my $self = shift;
    
    return $self->SUPER::size
        unless $self->isDelayed;

    $self->folder->popClient->messageSize($self->unique);
}

sub label(@)
{   my $self = shift;
    $self->loadHead;              # be sure the labels are read
    return $self->SUPER::label(@_) if @_==1;

    # POP3 can only set 'deleted' in the source folder.  Don't forget
    my $olddel = $self->label('deleted') ? 1 : 0;
    my $ret    = $self->SUPER::label(@_);
    my $newdel = $self->label('deleted') ? 1 : 0;

    $self->folder->popClient->deleted($newdel, $self->unique)
        if $newdel != $olddel;

    $ret;
}

sub labels(@)
{   my $self = shift;
    $self->loadHead;              # be sure the labels are read
    $self->SUPER::labels(@_);
}

#-------------------------------------------


sub loadHead()
{   my $self     = shift;
    my $head     = $self->head;
    return $head unless $head->isDelayed;

    $head        = $self->folder->getHead($self);
    $self->head($head);

    $self->statusToLabels;  # not supported by al POP3 servers
    $head;
}

sub loadBody()
{   my $self     = shift;

    my $body     = $self->body;
    return $body unless $body->isDelayed;

    (my $head, $body) = $self->folder->getHeadAndBody($self);
    $self->head($head) if $head->isDelayed;
    $self->storeBody($body);
}

1;
