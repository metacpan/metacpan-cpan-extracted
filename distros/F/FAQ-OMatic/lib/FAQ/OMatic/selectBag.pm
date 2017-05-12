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

package FAQ::OMatic::selectBag;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $rt = '';
	
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);

	FAQ::OMatic::Auth::ensurePerm('-item'=>'',
		'-operation'=>'PermReplaceBag',
		'-restart'=>FAQ::OMatic::commandName(),
		'-cgi'=>$cgi,
		'-xreason'=>'replace',
		'-failexit'=>1);
	
	$rt = FAQ::OMatic::pageHeader($params, ['help', 'faq']);
	
	my @bagList = ();	# list to choose from
	my $file = $params->{'file'};
	if (defined $file) {
		my $item = new FAQ::OMatic::Item($file);
		if ($item->isBroken()) {
			FAQ::OMatic::gripe('error', gettexta("The file (%0) doesn't exist.", $file));
		}
		@bagList = $item->getBags();
	} else {
		# browse every bag in the system.
		@bagList = grep { not m/\.desc$/ }
			FAQ::OMatic::getAllItemNames($FAQ::OMatic::Config::bagsDir);
	}

	$rt .= "<h3>".gettext("Replace which bag?")."</h3>\n";

	# display bags in a few columns.
	my $numcols = 3;
	my $bagsInCol = int((scalar(@bagList)+$numcols-1)/$numcols);

	$rt .= "<table><tr>\n";
	my $col;
	for ($col=0; $col<3; $col++) {
		my $bagnum;
		$rt .= "  <td valign=top>\n";
		for ($bagnum=$col*$bagsInCol;
			$bagnum<($col+1)*$bagsInCol && $bagnum < scalar(@bagList);
			$bagnum++) {
			$rt .= "    <br>"
				.FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'editBag',
						'-params'=>$params,
						'-changedParams'=>{'_target'=>$bagList[$bagnum]}),
					"$bagList[$bagnum]")
				."\n";
		}
		$rt .= "  </td>\n";
	}
	$rt .= "</tr></table>\n";

	$rt .= FAQ::OMatic::pageFooter($params, ['help', 'faq']);

	print $rt;
}

1;
