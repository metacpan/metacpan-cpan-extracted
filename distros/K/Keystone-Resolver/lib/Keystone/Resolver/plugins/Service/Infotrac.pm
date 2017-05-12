# $Id: Infotrac.pm,v 1.5 2007-05-25 08:31:34 mike Exp $

package Keystone::Resolver::plugins::Service::Infotrac;

use strict;
use warnings;
use URI::Escape qw(uri_escape_utf8);


# See ../../doc/providers/Infomarks Dynamic Creation for OpenURL.doc
# The example InfoMarc (that is, Gale URL) in that document is:
#	http://www.infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc3%5FEAIM%5F0%5F%5Fsu+%22ace+inhibitors%22?sw_aep=gale
#
# However, the documentation seems to be wrong in several respects.
# The following InfoTrac URLs are known empirically to work.  The
# first URL in this list is a working example sent by Deryck Velasquez
# at Gale <Deryck.Velasquez@thomson.com>.  I made the others by
# changing one aspect at a time to bring it as close as possible to
# what the specification suggests without breaking it.
#
# Original as supplied by Deryck Velasquez:
#	http://infotrac.galegroup.com/itw/infomark/0/1/1/purl=rc11_ITOF_0_sn_0034-4125_AND_vo_39_AND_sp_373_&dyn=sig!49?sw_aep=cusqa_ingenta
# Change the "sw_aep" from "cusqa_ingenta" to our own "indexdata":
#	http://infotrac.galegroup.com/itw/infomark/0/1/1/purl=rc11_ITOF_0_sn_0034-4125_AND_vo_39_AND_sp_373_&dyn=sig!49?sw_aep=indexdata
# Remove the "&dyn=sig!49" component, which is not documented:
#	http://infotrac.galegroup.com/itw/infomark/0/1/1/purl=rc11_ITOF_0_sn_0034-4125_AND_vo_39_AND_sp_373_?sw_aep=indexdata
# Change the "_0_" after the resource name into "__" as documented:
#	http://infotrac.galegroup.com/itw/infomark/0/1/1/purl=rc11_ITOF__sn_0034-4125_AND_vo_39_AND_sp_373_?sw_aep=indexdata
# Change "0/1/1" to "1/1/1" as specified:
#	http://infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11_ITOF__sn_0034-4125_AND_vo_39_AND_sp_373_?sw_aep=indexdata
# Use hostname "www..." as documented:
#	http://www.infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11_ITOF__sn_0034-4125_AND_vo_39_AND_sp_373_?sw_aep=indexdata
# Replace some "_" occurrences by "%5F" as documented:
#	http://www.infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11%5FITOF%5F%5Fsn_0034-4125_AND_vo_39_AND_sp_373_?sw_aep=indexdata
# Remove extraneous underscore from the end of the query:
#	http://www.infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11%5FITOF%5F%5Fsn_0034-4125_AND_vo_39_AND_sp_373?sw_aep=indexdata
# Provide parameters for the usual Bergelson _Science_ article:
#	http://www.infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11%5FITOF%5F%5Fjn_Science_AND_vo_275_AND_sp_1320?sw_aep=indexdata
# Re-order query terms alphabetically by fieldname:
#	http://www.infotrac.galegroup.com/itw/infomark/1/1/1/purl=rc11%5FITOF%5F%5Fjn_Science_AND_sp_1320_AND_vo_275?sw_aep=indexdata
# And the last of these is what we actually generate.

my %fields = (
#	      au => "aulast",	### au is really of the form "Taylor, Mike"
#	      ti => "atitle",
	      # No OpenURL field for "su" (subject)
	      # No OpenURL field for "ab" (abstract)
	      # No OpenURL field for "ke" (keyword)
# we prefer JN to IS since Gale doesn't seem to know the ISSN of
# _Science_ magazine, where the usual test-case article lives.
# Astonishingly, if both are provided, InfoTrac says, "The search
# expression is missing a search term".  By experimentation, this
# seems to be InfoTrac's response whenver it's given a search in which
# one of the ANDed terms has no hits.
	      jn => "jtitle",
#	      is => "issn",
	      vo => "volume",
	      iu => "issue",
	      sp => "spage",
#	      da => "date",	# da may be more complex, e.g. "May 3 2001"
	      # No OpenURL fields for "cn" (critic name)
	      );

sub uri {
    my $class = shift();
    my($openurl) = @_;

    my($issn, $volume, $issue, $spage)
	= map { $openurl->rft($_) } qw(issn volume issue spage);

    my $resource = "ITOF";	# This is what we are subscribed to
    my $location = "indexdata";	# As specified in email from Gale
    my $query = "";
    foreach my $key (sort keys %fields) {
	my $val = $openurl->rft($fields{$key});
	if (defined $val) {
	    ### For some reason, "_" as a separator works but the
	    # documented "+" doesn't.
	    ### Does the InfoTrac gateway expect us to encode UTF8 or Latin1?
	    $query .= "_AND_" if $query ne "";
	    $query .= "${key}_" . uri_escape_utf8($val) . "";
	}
    }

    ### For some reason, "rc11" works but the documented "rc3" doesn't
    return "http://www.infotrac.galegroup.com/itw/infomark/1/1/1/" .
	"purl=rc11%5F$resource%5F%5F$query?sw_aep=$location";
}


1;
