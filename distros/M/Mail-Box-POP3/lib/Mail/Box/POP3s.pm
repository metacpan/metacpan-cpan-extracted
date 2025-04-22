# Copyrights 2001-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution Mail-Box-POP3.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::POP3s;{
our $VERSION = '3.007';
}

use base 'Mail::Box::POP3';

use strict;
use warnings;


sub init($)
{   my ($self, $args) = @_;
    $args->{server_port} ||= 995;
    $self->SUPER::init($args);
    $self;
}

sub type() {'pop3s'}

#-------------------------------------------


sub popClient(%)
{   my $self = shift;
    $self->SUPER::popClient(@_, use_ssl => 1);
}

1;
