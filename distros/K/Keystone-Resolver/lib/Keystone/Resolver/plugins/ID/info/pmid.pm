# $Id: pmid.pm,v 1.2 2007-01-26 13:53:48 mike Exp $

package Keystone::Resolver::plugins::ID::info::pmid;

use strict;
use warnings;


sub data {
    my $class = shift();
    my($openurl, $pmid) = @_;

    # There's a PubMed search interface at
    #	http://www.ncbi.nlm.nih.gov/entrez/query.fcgi
    # but it would be a pain to write a scaper, plus invoking one
    # would radically slow down the resolver.  So let's not.

    return (undef, undef, undef, "Resolution of PubMed IDs is unsupported", 1);
}


1;

