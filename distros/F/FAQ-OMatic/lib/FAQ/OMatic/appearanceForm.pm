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

package FAQ::OMatic::appearanceForm;

use CGI;
use FAQ::OMatic;
use FAQ::OMatic::I18N;
use FAQ::OMatic::HelpMod;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	my $page = '';

	$page.=FAQ::OMatic::pageHeader($params, ['help', 'faq']);
	
	$page.="<h3>".gettext("Appearance Options")."</h3>";

# Data structure key:
#		['parameterName',			# as resolved by $params->{'parameterName'}
#			['value-names', ...],	# one per table column
#			['value', ...],			# as will appear in value="" field
#			'description'],			# text description of parameter

	my $boxes = [
#		['recurse',
#			['', gettext("Show"), gettext("Hide")],
#			['', '1', ''],
#			gettext("all categories and answers below current category")],
		['editCmds',
			[gettext("Show"), gettext("Compact"), gettext("Hide")],
			['show', 'compact', 'hide'],
			gettext("expert editing commands")],
		['showModerator',
			['', gettext("Show"), gettext("Hide")],
			['', 'show', 'hide'],
			gettext("name of moderator who organizes current category")],
		['showLastModified',
			['', gettext("Show"), gettext("Hide")],
			['', 'show', 'hide'],
			gettext("last modified date")],
# showLastModifiedAlways is now obsolete; that default will be handled
# in the (new) standard way using OMatic::getParam().
#		($FAQ::OMatic::Config::showLastModifiedAlways||0)
#			? ['',
#				['', '', ''],
#				['', '', ''],
#				'<i>last modified date always shown</i>']
#			: ['showLastModified',
#				['', 'Show', 'Hide'],
#				['', '1', ''],
#				'last modified date']
#			,
		['showAttributions',
			[gettext("Show"), gettext("Default"), gettext("Hide")],
			['all', 'default', 'hide'],
			gettext("attributions")],
		['render',
			['', gettext("Simple"), gettext("Fancy")],
			['', 'simple', 'tables'],
			'HTML'],
		['textCmds',
			['', gettext("Show"), gettext("Hide")],
			['', 'show', 'hide'],
			gettext("commands for generating text output")]
	];

	$page.=FAQ::OMatic::makeAref("faq",
			# kill all params that have a form entry
			{ map {$_->[0] => ''} @{$boxes} },
			'GET')
		."<table>\n";
	my ($setup, $choice);
	foreach $setup (@{$boxes}) {
		$page.="<tr>";
		foreach $choice (0, 1, 2) {
			$page.="<td>";
			if ($setup->[1][$choice]) {
				$page.="<input type=radio name=\""
					.$setup->[0]
					."\" value=\""
					.$setup->[2][$choice]
					."\"";
				my $existing = FAQ::OMatic::getParam($params, $setup->[0]);
				if ($existing eq $setup->[2][$choice]) {
					$page.=" checked\n";
				}
				$page.="> "
					.$setup->[1][$choice];
			}
			$page.="</td>\n";
		}
		$page.= "<td>".$setup->[3]."</td>\n";
		$page.="</tr>";
	}
	$page.="<tr><td></td><td></td><td></td><td align=left>"
		."<input type=submit name=\"_fromAppearance\" value=\"".gettext("Accept")."\">"
		."</td></tr>\n";
	$page.="</table></form>\n";

	$page.=FAQ::OMatic::HelpMod::helpFor($params, 'Appearance Options', "\n");

	$page.= FAQ::OMatic::pageFooter($params, ['help', 'faq']);

	print $page;
}

1;
