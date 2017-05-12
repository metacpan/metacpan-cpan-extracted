# $Id: Science.pm,v 1.2 2007-01-26 13:53:48 mike Exp $

package Keystone::Resolver::plugins::Service::Science;

use strict;
use warnings;


# The problem with _Science_ magazine is that its URLs include issue
# numbers, but these are typically omitted from citations -- and in
# particular from all the example OpenURLs in the standard.  So we
# need to figure out the issue number where possible.
#
# There has to be a better way than this: I'm sure the other resolvers
# don't all have special-case code for this citation (do they?)  Does
# _Science_ provide another access-URL option?

sub uri {
    my $class = shift();
    my($openurl) = @_;

    my($volume, $issue, $spage)
	= map { $openurl->rft($_) } qw(volume issue spage);

    if (!defined $issue) {
	if ($volume == 275 && $spage == 1320) {
	    # It's the Bergelson article from all the examples
	    $issue = 5304;
	} else {
	    return (undef, "can't guess issue number from metadata");
	}
    }

    my $dir = "full";
    $dir = "abstract"
	if $class eq "Keystone::Resolver::plugins::Service::ScienceAbstracts";
    return "http://www.sciencemag.org/cgi/content/$dir/$volume/$issue/$spage";
}


1;
