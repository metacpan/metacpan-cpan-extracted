# Copyrights 2011-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package IOMux::Handler::Service;
use vars '$VERSION';
$VERSION = '1.00';

use base 'IOMux::Handler';

use Log::Report       'iomux';


sub muxInit($)
{   my ($self, $mux) = @_;
    $self->SUPER::muxInit($mux);
    $self->fdset(1, 1, 0, 0);  # 'read' new connections
}

sub muxRemove()
{   my $self = shift;
    $self->SUPER::muxRemove;
    $self->fdset(0, 1, 0, 0);
}

#----------

sub muxConnection($) {shift}

1;
