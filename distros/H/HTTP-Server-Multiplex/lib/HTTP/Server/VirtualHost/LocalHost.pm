# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use warnings;
use strict;

package HTTP::Server::VirtualHost::LocalHost;
use vars '$VERSION';
$VERSION = '0.11';

use base 'HTTP::Server::VirtualHost';

use Log::Report 'httpd-multiplex', syntax => 'SHORT';


sub init($)
{   my ($self, $args) = @_;

    $args->{name} ||= 'localhost';
    $self->SUPER::init($args);
}

# probably, more code will need to be added later

1;
