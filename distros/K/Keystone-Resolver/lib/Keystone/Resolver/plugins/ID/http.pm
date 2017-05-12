# $Id: http.pm,v 1.2 2007-01-26 13:53:47 mike Exp $

package Keystone::Resolver::plugins::ID::http;

use strict;
use warnings;


sub data {
    my $class = shift();
    my($openurl, $http) = @_;

    # I guess an HTTP ID is just a page that contains useful
    # information on the referent.  The simple thing in this case is
    # probably also the correct thing: just return the ID itself as a
    # result.

    return ("http:$http", "http");
}


1;
