# $Id: Elsevier.pm,v 1.2 2007-01-26 13:53:48 mike Exp $

package Keystone::Resolver::plugins::Service::Elsevier;

use strict;
use warnings;
use Keystone::ContentURL::Elsevier;


### Should these parameters be held in the database?
my $_handle = new Keystone::ContentURL::Elsevier("KEYSTONE", 1,
				       ".0iVzmAd)cPGS)nHoL(lE1uw)4xEy9z+");


sub uri {
    my $class = shift();
    my($openurl) = @_;

    ### We might be able to extract this from an rft_id
    my $pii = undef;

    my(@metadata) = map { $openurl->rft($_) } qw(issn volume issue
						 spage epage auinit1
						 aulast date);

    $metadata[5] ||= $openurl->rft("auinit");
    return $_handle->url($pii, @metadata);
}


1;
