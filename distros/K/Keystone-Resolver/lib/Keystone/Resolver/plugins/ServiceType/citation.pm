# $Id: citation.pm,v 1.2 2007-01-26 13:53:49 mike Exp $

package Keystone::Resolver::plugins::ServiceType::citation;

use strict;
use warnings;


sub handle {
    my $class = shift();
    my($openURL, $service) = @_;

    my $style = $service->tag();
    eval {
	require "Keystone/Resolver/plugins/Citation/$style.pm";
    }; if ($@) {
	$openURL->warn("can't load citation-style plugin '$style': $@");
	return (undef, "citation style '$style' not defined");
    }

    my($citation, $mimeType) =
	"Keystone::Resolver::plugins::Citation::$style"->citation($openURL);

    return ($citation, undef, undef, $mimeType);
}


1;
