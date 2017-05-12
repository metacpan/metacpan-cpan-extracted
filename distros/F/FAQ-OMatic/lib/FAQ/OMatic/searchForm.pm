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

use strict;

package FAQ::OMatic::searchForm;

use CGI;
use FAQ::OMatic;
use FAQ::OMatic::I18N;
use FAQ::OMatic::HelpMod;
use FAQ::OMatic::SearchMod;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	my $page = '';

	$page.=FAQ::OMatic::pageHeader($params, ['help', 'faq']);

	my $useTable = not $params->{'simple'};

	my $labelColor = $FAQ::OMatic::Config::regularPartColor || '#ffff0f';
	my $labelColorCmd = "bgcolor=\"$labelColor\"";
	$page.="<table width=\"100%\">\n" if $useTable;
	$page.="<tr><td $labelColorCmd>\n" if $useTable;
	$page.=gettext("search for keywords");
	$page.="</td></tr>\n" if $useTable;
	$page.="<tr><td valign=top>\n" if $useTable;
	$page .= FAQ::OMatic::makeAref('search', {}, 'GET');
	$page .= "<input type=\"submit\" name=\"_submit\" "
		."value=\"".gettext("Search for")."\">\n";
	$page .= "<input type=\"text\" name=\"_search\"> ".gettext("matching")."\n";
	$page .= "<select name=\"_minMatches\">\n";
	$page .= "<option value=\"\">".gettext("all")."\n";
	$page .= "<option value=\"1\">".gettext("any")."\n";
	$page .= "<option value=\"2\">".gettext("two")."\n";
	$page .= "<option value=\"3\">".gettext("three")."\n";
	$page .= "<option value=\"4\">".gettext("four")."\n";
	$page .= "<option value=\"5\">".gettext("five")."\n";
	$page .= "</select>\n";
	$page .= gettext("words").".\n";
	$page .= "</form>\n";
	$page.="</td></tr>\n" if $useTable;
	$page.="</table>\n" if $useTable;

	## Recent documents
	$page.="<table width=\"100%\">\n" if $useTable;
	$page.="<tr><td $labelColorCmd>\n" if $useTable;
	$page.=gettext("search for recent changes");
	$page.="</td></tr>\n" if $useTable;
	$page.="<tr><td valign=top>\n" if $useTable;
	$page .= FAQ::OMatic::makeAref('recent',
			{'showLastModified'=>'show'}, 'GET');
	$page .= "<input type=\"submit\" name=\"_submit\" "
		."value=\"".gettext("Show documents")."\">\n";
	$page .= " ".gettext("modified in the last")." \n";
	$page .= "<select name=\"_duration\">\n";
	my $recentMap = FAQ::OMatic::SearchMod::getRecentMap();
	foreach my $numDays (sort {$a <=> $b} keys %$recentMap) {
		# default to "week"
		my $selected = ($numDays == 7) ? " SELECTED" : "";
		$page .= "<option value=\"${numDays}\"${selected}>"
			.gettext($recentMap->{$numDays}).".\n";
	}
	$page .= "</select>\n";
	$page .= "</form>\n";
	$page.="</td></tr></table>\n" if $useTable;

#	$page.=FAQ::OMatic::button(
#		FAQ::OMatic::makeAref('-command'=>''),
#		'Return to the FAQ')."<br>\n";

	$page.=FAQ::OMatic::HelpMod::helpFor($params,
		'Search Tips', "<br>");

	$page.= FAQ::OMatic::pageFooter($params, ['help','faq']);

	print $page;
}

1;
