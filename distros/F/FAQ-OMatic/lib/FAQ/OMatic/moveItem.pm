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

package FAQ::OMatic::moveItem;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::HelpMod;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);
	
	my $rt = FAQ::OMatic::pageHeader($params, ['help', 'faq']);
	
	my $item = new FAQ::OMatic::Item($params->{'file'});
	if ($item->isBroken()) {
		FAQ::OMatic::gripe('error', gettexta("The file (%0) doesn't exist.", $params->{'file'}));
	}

	FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
		'-operation'=>'PermEditDirectory',
		'-restart'=>'moveItem',
		'-cgi'=>$cgi,
		'-failexit'=>1);

	my $anyPermProblems = 0;	# so we can make a note later
	my $authFailed;
	my %itemSet = ();
	my $clickable;

	my ($filei, $itemi);
	foreach $filei (FAQ::OMatic::getAllItemNames()) {
		next if ($item->isEmptyStub());

		# I can't be my own parent
		next if ($filei eq $item->{'filename'});

		# No point in moving to our current parent
		next if ($filei eq $item->{'Parent'});

		# take a peek at the potential target
		$itemi = new FAQ::OMatic::Item($filei);

		# Can't move to a descendent, or we'd break the tree apart.
		next if ($itemi->hasParent($params->{'file'}));

		# Don't show items with no other kids already unless asked
		next if ((not $params->{'showBarrenItems'})
				and (not defined $itemi->{'directoryHint'})
				and (not $itemi->{'filename'} eq 'trash'));

		$authFailed = FAQ::OMatic::Auth::checkPerm($itemi,'PermAddItem');
			# need only the weaker PermAddItem for destination category
		if ($authFailed) {
			$anyPermProblems = 1;
			$clickable = 0;
			next;
		} else {
			$clickable = 1;
		}

		my ($titles, $filenames) = $itemi->getParentChain();
		my $fullname = join(":", reverse @{$titles});
		my $display = '';
		if ($clickable) {
			$display .= 
				FAQ::OMatic::makeAref('submitMove', {'_newParent'=>$filei});
		}
		$display .= $fullname;
		$display .= "</a>" if ($clickable);
		$display .= "<br>\n";
		if ($fullname =~ m/^Trash/) {
			# sort trash items at end.
			$itemSet{'9'.$fullname} = $display;
		} else {
			$itemSet{'0'.$fullname} = $display;
		}
	}

	if (scalar %itemSet) {
		$rt .= gettexta("Make <b>%0</b> belong to which other item?", $item->getTitle())
			."<p>\n";
		$rt .= join("\n", map {$itemSet{$_}} (sort keys (%itemSet)));
	} elsif (not $params->{'showBarrenItems'}) {
		$rt .= gettext("No item that already has sub-items can become the parent of")." <b>".$item->getTitle()."</b>.\n";
	} else {
		$rt .= gettext("No item can become the parent of")." <b>"
			.$item->getTitle()."</b>.\n";
	}
	if ($anyPermProblems) {
		$rt.= "<p>".gettext("Some destinations are not available (not clickable) because you do not have permission to edit them as currently authorized.")."\n";
		$rt.=FAQ::OMatic::makeAref('authenticate',
			{'_restart'=>FAQ::OMatic::commandName(), '_reason'=>$authFailed});
		$rt.=gettext("Click here</a> to provide better authentication.")."\n";
	}

	$rt .= "<p>";
	if ($params->{'showBarrenItems'}) {
		$rt .= FAQ::OMatic::button(FAQ::OMatic::makeAref('moveItem',
			{'showBarrenItems'=>''}), gettext("Hide answers, show only categories"))."\n";
	} else {
		$rt .= FAQ::OMatic::button(FAQ::OMatic::makeAref('moveItem',
			{'showBarrenItems'=>'1'}), gettext("Show both categories and answers"))."\n";
	}
	$rt.="<br>\n";
#	$rt .= FAQ::OMatic::button(FAQ::OMatic::makeAref('faq', {}),
#			"Cancel and return to FAQ")."\n";

	$rt .= FAQ::OMatic::HelpMod::helpFor($params, 'moveItem');

	print $rt;

	print FAQ::OMatic::pageFooter($params, ['help', 'faq']);
}

1;


