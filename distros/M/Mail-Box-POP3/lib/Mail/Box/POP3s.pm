# Copyrights 2001-2017 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.

package Mail::Box::POP3s;
use vars '$VERSION';
$VERSION = '3.001';

use base 'Mail::Box::POP3';

use strict;
use warnings;


sub init($)
{   my ($self, $args) = @_;
    $args->{server_port} ||= 995;
    $args->{message_type} = 'Mail::Box::POP3::Message';
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
