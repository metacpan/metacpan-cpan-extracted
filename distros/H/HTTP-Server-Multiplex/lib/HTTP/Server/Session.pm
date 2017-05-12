# Copyrights 2008 by Mark Overmeer.
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 1.05.
use warnings;
use strict;

package HTTP::Server::Session;
use vars '$VERSION';
$VERSION = '0.11';


use Log::Report 'httpd-multiplex', syntax => 'SHORT';


sub new(@)
{   my $class   = shift;
    my $args    = @_==1 ? shift : {@_};
    (bless {}, $class)->init($args);
}

sub init($)
{   my ($self, $args) = @_;
    $self;
}

#-----------------

1;
