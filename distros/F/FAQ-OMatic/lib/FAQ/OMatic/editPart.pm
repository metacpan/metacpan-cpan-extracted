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

package FAQ::OMatic::editPart;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::I18N;
use FAQ::OMatic::HelpMod;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $rt='';

	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);

	$rt .= FAQ::OMatic::pageHeader($params, ['help', 'faq']);
	
	my $item = new FAQ::OMatic::Item($params->{'file'});
	if ($item->isBroken()) {
		FAQ::OMatic::gripe('error', "The file (".$params->{'file'}
			.") doesn't exist.");
	}

	# check sequence number to prevent later confusion -- the user's
	# insert or change request came from an out-of-date page.
	$item->checkSequence($params);

	my $insertpart = $params->{'_insertpart'};

	my $partnum = $params->{'partnum'};
	if ($partnum =~ m/afterLast/) {
		# it's possible to come from a mirror, who might be enough
		# out of date that naming a specific part number would cause
		# the [Append to This Answer] link to sometimes cause people to
		# unintentionally insert text before existing text.
		# The pattern match lets us send something like '9999afterLast',
		# which will cause older versions (which a newer mirror may
		# point to) to generate a nice error message, instead of
		# letting the user edit the wrong part.
		$partnum = scalar(@{$item->{'Parts'}}) - 1;
	}
	my $part = undef;
	$partnum = FAQ::OMatic::stripInt($partnum);
	if ($partnum >= 0) {
		$part = $item->getPart($partnum);
		if (not $part) {
			FAQ::OMatic::gripe('error', "Part number $partnum in "
				.$params->{'file'}." doesn't exist.");
		}
	} else {
		$partnum = -1;
	}
	if (($partnum < 0) and (not $insertpart)) {
		FAQ::OMatic::gripe('error', "Part number \"$partnum\" in \""
			.$params->{'file'}."\" doesn't exist.");
	}

	# for inserts, create the part in our in-memory copy of the item
	# just like it would be created in submitItem, so that the
	# form-generator below can't tell the difference.

	# duplicates are exactly the same as inserts, but you copy an existing
	# part, rather than start with an empty one.
	if ($insertpart) {
		my $newpart;
		if ($cgi->param('_duplicate')) {
			# duplicate part -- the one above the insert, I guess.
			$newpart = $item->getPart($partnum)->clone();
		} else {
			# new part
			$newpart = new FAQ::OMatic::Part();
		}
		# squeeze the new part into the item's part list.
		splice @{$item->{'Parts'}}, $partnum+1, 0, $newpart;
		# inheret properties from parent part
		if ($part) {
			if ($part->{'Type'} ne 'directory') {
				$newpart->{'Type'} = $part->{'Type'};
			}
			$newpart->{'HideAttributions'} = $part->{'HideAttributions'};
		}
		$part = $newpart;
	}

	if ($part->{'Text'} =~ m/^\s*$/s) {
		# if the part starts out empty, we're as good as adding, not
		# editing existing content.
		# We let the item author add any new parts he wants.
		FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
			'-operation'=>'PermAddPart',
			'-restart'=>FAQ::OMatic::commandName(),
			'-cgi'=>$cgi,
			'-failexit'=>1);
	} else {
		FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
			'-operation'=>'PermEditPart',
			'-restart'=>FAQ::OMatic::commandName(),
			'-cgi'=>$cgi,
			'-failexit'=>1);

		if ($part->{'Type'} eq 'html') {
			# discourage unauthorized users from editing HTML parts which
			# they won't later be able to submit.
			FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
				'-operation'=>'PermUseHTML',
				'-restart'=>FAQ::OMatic::commandName(),
				'-cgi'=>$cgi,
				'-xreason'=>'useHTML',
				'-failexit'=>1);
		}
	}
	
	if ($params->{'_insertpart'}) {
		my $insertHint = $params->{'_insert'} || '';
		if ($insertHint eq 'answer') {
			$rt .= gettexta("Enter the answer to <b>%0</b>", $item->getTitle())."\n";
		} elsif ($insertHint eq 'category') {
			$rt .= gettexta("Enter a description for <b>%0</b>", $item->getTitle())."\n";
		} elsif ($params->{'_duplicate'}) {
			$rt .= gettexta("Edit duplicated text for <b>%0</b>", $item->getTitle())."\n";
		} else {
			$rt .= gettexta("Enter new text for <b>%0</b>", $item->getTitle())."\n";
		}
	} else {
		# little white lie -- user sees 1-based indices, but parts
		# are stored 0-based. Is this bad?
		$rt .= gettexta("Editing the %0 text part in <b>%1</b>.", 
				FAQ::OMatic::cardinal($partnum+1), $item->getTitle())
			."\n";
	}
	$rt .= $part->displayPartEditor($item, $partnum, $params);

	$rt .= FAQ::OMatic::HelpMod::helpFor($params, 'editPart', "<br>\n");
	$rt .= FAQ::OMatic::HelpMod::helpFor($params, 'makingLinks', "<br>\n");
	$rt .= FAQ::OMatic::HelpMod::helpFor($params, 'seeAlso', "<br>\n");

	# TODO: this will probably be unnecessary once there is a help system.
	if (FAQ::OMatic::getParam($params, 'editCmds') eq 'hide') {
		$rt .=
		    "<p>" .
		    gettexta("If you later need to edit or delete this text, use the [Appearance] page to turn on the expert editing commands.") .
		    "\n";
	}

	$rt .= FAQ::OMatic::pageFooter($params, ['help','faq']);

	print $rt;
}

1;



