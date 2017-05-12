# $Id: urn.pm,v 1.3 2007-06-20 12:55:32 mike Exp $

package Keystone::Resolver::plugins::ID::urn;

use strict;
use warnings;


# See "info.pm" for comments.  Like that ID namespace, this one merely
# delegates to sub-namespaces.

sub data {
    my $class = shift();
    my($openurl, $address) = @_;

    # Urn URIs are of the form
    #	urn:<namespace>:<subaddress>
    # where namespaces include "isbn", etc.

    my($namespace, $subaddress) = ($address =~ /(.*?):(.*)/);
    return (undef, undef, undef,
	    "URN doesn't have a namespace: '$address'")
	if !defined $namespace;

    # OCLC's WorldCat COinS provides URN identifiers of the form
    # "urn:ISBN:9780394588162", with an upper-case "ISBN".  I'm not
    # sure whether that's allowed, but in any case we canonicalise it
    # down into lowercase.
    $namespace = lc($namespace);

    # Another oddity of WorldCat OpenURLs: they provide IDs with empty
    # values, such as "urn:ISSN:".  We protect the individual plugins
    # from such nonsense.
    return (undef, undef, undef, "empty URN '$address'", 1)
	if $subaddress eq "";

    eval {
	require "Keystone/Resolver/plugins/ID/urn/$namespace.pm";
    }; if ($@) {
	$openurl->warn("can't load ID URN plugin '$namespace': $@");
	return (undef, undef, undef,
		"URN namespace '$namespace' not supported ($address)");
    }

    return "Keystone::Resolver::plugins::ID::urn::$namespace"->data($openurl,
								$subaddress);
}


1;
