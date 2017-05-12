# $Id: authorsearch.pm,v 1.2 2007-01-26 13:53:49 mike Exp $

package Keystone::Resolver::plugins::ServiceType::authorsearch;

use strict;
use warnings;


sub handle {
    my $class = shift();
    my($openURL, $service) = @_;

    return $openURL->_makeURI($service->url_recipe());
}


1;
