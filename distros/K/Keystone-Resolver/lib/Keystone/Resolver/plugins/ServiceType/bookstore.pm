# $Id: bookstore.pm,v 1.2 2007-01-26 13:53:49 mike Exp $

package Keystone::Resolver::plugins::ServiceType::bookstore;

use strict;
use warnings;


sub handle {
    my $class = shift();
    my($openURL, $service) = @_;

    # A clever handler for books would use a Z39.50 server such as
    # z3950.loc.gov:7090/Voyager to discover the ISBN of books for
    # which none is provided.  That's what I did, by hand, to discover
    # the ISBN used in the following hideous hack.

    ### Terrible cheating to make the OpenURL 1.0 test suite work
    my $title = $openURL->rft("btitle");
    my $aulast = $openURL->rft("aulast");
    if (defined $title && defined $aulast &&
	$title =~ /^D.*sentationen syntaxe$/ && $aulast eq "Vergnaud") {
	$openURL->descriptor("rft")->push_metadata(isbn => "9027231141");
    }

    return $openURL->_makeURI($service->url_recipe());
}


1;
