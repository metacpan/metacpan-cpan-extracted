# Copyrights 2001-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Field::Unstructured;
use vars '$VERSION';
$VERSION = '3.015';

use base 'Mail::Message::Field::Full';

use strict;
use warnings;


sub init($)
{   my ($self, $args) = @_;

    if($args->{body} && ($args->{encoding} || $args->{charset}))
    {   $args->{body} = $self->encode($args->{body}, %$args);
    }
    $self->SUPER::init($args) or return;

    $self->log(WARNING =>"Attributes are not supported for unstructured fields")
        if defined $args->{attributes};

    $self->log(WARNING => "No extras for unstructured fields")
        if defined $args->{extra};

    $self;
}


1;
