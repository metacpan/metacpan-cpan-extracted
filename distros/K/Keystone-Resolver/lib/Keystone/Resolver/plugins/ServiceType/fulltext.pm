# $Id: fulltext.pm,v 1.3 2007-07-19 16:11:55 mike Exp $

package Keystone::Resolver::plugins::ServiceType::fulltext;

use strict;
use warnings;


### A nice big comment is required describing the plugin interface.

# Returns undef if the service does not have the requested journal, or
# if its coverage does not include the requested volume/issue.
#
sub handle {
    my $class = shift();
    my($openURL, $service) = @_;

    my($serial, $errmsg) = $openURL->_serial();
    if (!defined $serial) {
	# Serial not supported at all, first time of asking
	return (undef, $errmsg, 1);
    } elsif (!$serial) {
	# Serial not supported at all, but we already knew that so
	# there's no need to generate another message
	return undef;
    }

    if (!$openURL->db()->service_has_serial($service, $serial)) {
	# Journal not covered by this service: quiet failure, no error
	$openURL->log(Keystone::Resolver::LogLevel::CHITCHAT,
		   , $service->render(), " lacks ", $serial->render());
	return undef;
    }
    $openURL->log(Keystone::Resolver::LogLevel::CHITCHAT,
	       $service->render(), " has ", $serial->render());

    # If a recipe is provided, then we use it to construct the URI.
    # If not, then we take the service's tag as the name of a plugin,
    # and invoke that to do the resolution.
    my $recipe = $service->url_recipe();
    return $openURL->_makeURI($recipe)
	if $recipe;

    my $tag = $service->tag();
    eval {
	require "Keystone/Resolver/plugins/Service/$tag.pm";
    }; if ($@) {
	$openURL->warn("can't load service plugin '$tag': $@");
	return (undef, "service plug-in '$tag' not defined", 1);
    }

    return "Keystone::Resolver::plugins::Service::$tag"->uri($openURL);
}


1;
