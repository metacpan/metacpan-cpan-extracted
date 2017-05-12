##############################################################################
# The Faq-O-Matic is Copyright 1997 by Jon Howell, all rights reserved.      #
#                                                                            #
# This program is free software; you can redistribute it and/or              #
# modify it under the terms of the GNU General Public License                #
# as published by the Free Software Foundation; either version 2             #
# of the License, or (at your option) any later version.                     #
#                                                                            #
# This program is distributed in the hope that it will be useful,            #
# but WITHOUT ANY WARRANTY; without even the implied warranty of             #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
# GNU General Public License for more details.                               #
#                                                                            #
# You should have received a copy of the GNU General Public License          #
# along with this program; if not, write to the Free Software                #
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.#
#                                                                            #
# Jon Howell can be contacted at:                                            #
# 6211 Sudikoff Lab, Dartmouth College                                       #
# Hanover, NH  03755-3510                                                    #
# jonh@cs.dartmouth.edu                                                      #
#                                                                            #
# An electronic copy of the GPL is available at:                             #
# http://www.gnu.org/copyleft/gpl.html                                       #
#                                                                            #
##############################################################################

# This entire file is THANKS Doug Schremp <doug_schremp@yahoo.com>.
# Purpose: "...I have added an XML/RDF
# recent search function. I use this to publish recent
# changes to the internal Slash based site as a
# slashbox. I would like to submit this code for
# possible inclusion in the base FAQ-O-Matic
# distribution. 
# 
# The code is based on recent.pm with changes to
# produce XML/RDF instead of HTML."
#
# jonh: So presumably Doug just synthesizes URLs directly to extract this
# XML data; there's no interface to grab it.

use strict;

package FAQ::OMatic::recentrdf;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::SearchMod;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	# Get the names of the recent files
	my $matchset = FAQ::OMatic::SearchMod::getRecentSet($params);

	# Filter out those in the trash
	# THANKS: dschulte@facstaff.wisc.edu for the suggestion
	my @finalset = ();
	my $file;
	foreach $file (@{$matchset}) {
		my $item = new FAQ::OMatic::Item($file);
		if (not $item->hasParent('trash')) {
			push @finalset, $item;
		}
	    }

	
	print $cgi->header('-type'=>"text/xml");
	print <<EOL;
<?xml version="1.0"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">
<channel>
EOL

        my $topitem=new FAQ::OMatic::Item('1');
	my $title=$topitem->getTitle('undefokay');
	my $topUrl=FAQ::OMatic::getCacheUrl({'file'  => $topitem->{'filename'}} ,{'file'  => $topitem->{'filename'}} );
	print ("<title>",$title,"</title>\n");
	print ("<link>",$topUrl ,"</link>\n");
	print ("<description>",$title,"Recent Updates </description>\n");
	print ("</channel>\n");
	
	my $item;                         
	my $test;
	
	foreach $item (sort byModDate @finalset)
	{
	    print "<item>\n";
	    $test=$item->getTitle();
	    print ("<title>$test</title>\n");
	    $test=FAQ::OMatic::getCacheUrl({'file'  => $item->{'filename'}} ,{'file'  => $item->{'filename'}} );
	    print ("<link>$test</link>\n");
	    print ("</item>\n");
	}
	print ("</rdf:RDF>\n");    
	
    	
	FAQ::OMatic::SearchMod::closeWordDB();
}

sub byModDate {
	my $lmsa = $a->{'LastModifiedSecs'} || -1;
	my $lmsb = $b->{'LastModifiedSecs'} || -1;
	return $lmsb <=> $lmsa;
}

1;
