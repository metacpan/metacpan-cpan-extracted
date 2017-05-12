# Copyrights 2011 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.07.
use warnings;
use strict;

package IOMux::HTTP::Server;
use vars '$VERSION';
$VERSION = '0.11';

use base 'IOMux::Service::TCP';

use IOMux::HTTP::Service;

use Log::Report 'iomux-http';


sub init($)
{   my ($self, $args) = @_;
    $args->{conn_type} ||= 'IOMux::HTTP::Service';

    my $handler = $args->{handler}
        or error __x"HTTP server {name} requires a handler for new incoming"
             , name => $self->name;
    push @{$args->{conn_opts}}, handler => $handler;

    $self->SUPER::init($args);
    $self;
}

1;
