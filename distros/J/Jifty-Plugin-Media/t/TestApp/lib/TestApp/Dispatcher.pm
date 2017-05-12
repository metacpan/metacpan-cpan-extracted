use strict;
use warnings;

package TestApp::Dispatcher;
use Jifty::Dispatcher -base;

=head1 NAME

Jifty::Plugin::Media::Dispatcher - default dispatcher for media plugin

=cut

# whitelist safe actions to avoid cross-site scripting
before '*' => run { 
    #TODO be more strict
    Jifty->api->allow('Jifty::Plugin::Media::Action::ManageFile'); 
    };

1;
