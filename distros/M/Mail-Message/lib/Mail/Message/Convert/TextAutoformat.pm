# Copyrights 2001-2020 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Message::Convert::TextAutoformat;
use vars '$VERSION';
$VERSION = '3.009';

use base 'Mail::Message::Convert';

use strict;
use warnings;

use Mail::Message::Body::String;
use Text::Autoformat;


sub init($)
{   my ($self, $args)  = @_;

    $self->SUPER::init($args);

    $self->{MMCA_options} = $args->{autoformat} || { all => 1 };
    $self;
}

#------------------------------------------


sub autoformatBody($)
{   my ($self, $body) = @_;

    ref($body)->new
       ( based_on => $body
       , data     => autoformat($body->string, $self->{MMCA_options})
       );
}

#------------------------------------------

1;
