# $Id: doi.pm,v 1.2 2007-01-26 13:53:48 mike Exp $

package Keystone::Resolver::plugins::ID::info::doi;

use strict;
use warnings;


sub data {
    my $class = shift();
    my($openurl, $doi) = @_;

    # The obvious DOI resolver to use is the one at
    #	http://dx.doi.org/
    # which can be invoked using a simple GET, like this:
    #	http://dx.doi.org/10.1126/science.275.5304.1320
    # The problem is that this doesn't resolve to a metadata set, but
    # directly to a URL for the full text ... which may or may not be
    # what we want.

    my $req = "http://dx.doi.org/$doi";
    my ($uri, $errmsg) = $openurl->co()->fetch($req, "DOI", 1);
    if (!defined $uri && $errmsg =~ /200 OK$/) {
	# This is ugly, but that's how it goes when you screen-scrape.
	# The only reason the DOI resolver would give us a page of
	# HTML would be to report an error, so we know there's
	# something wrong with the DOI.
	$errmsg = "invalid DOI ($doi)";
    }

    return ($uri, "info:doi", undef, $errmsg, 1);
}


1;
