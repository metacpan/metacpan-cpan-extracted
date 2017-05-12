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

package FAQ::OMatic::submitCatToAns;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $removed = 0;
	
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);

	my $item = new FAQ::OMatic::Item($params->{'file'});
	if ($item->isBroken()) {
		FAQ::OMatic::gripe('error', gettexta("The file (%0) doesn't exist.", $params->{'file'}));
	}
	
	$item->checkSequence($params);
	$item->incrementSequence();

	FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
		'-operation'=>'PermEditDirectory',
		'-restart'=>FAQ::OMatic::commandName(),
		'-cgi'=>$cgi,
		'-failexit'=>1);

	# users would rarely see these messages; they'd have to forge the URL.
	if (not $item->isCategory()) {
		FAQ::OMatic::gripe('error', "This isn't a category.");
	}

	if (scalar($item->getChildren())>0) {
		FAQ::OMatic::gripe('error', "This category still has children. "
			."Move them to another category before trying to convert this "
			."category into an answer.");
	}

	if ($params->{'_removePart'}) {
		# just delete the entire part outright
		my $partnum = $item->{'directoryHint'};
		if (not defined $partnum) {
			FAQ::OMatic::gripe('abort',
				"spooky: directoryHint not defined in category "
				.$item->{'filename'});
		}
		splice @{$item->{'Parts'}}, $partnum, 1;
		delete $item->{'directoryHint'};
	} else {
		# the directory part has no faqomatic: links, so it won't hurt to
		# turn it into a regular text part.
		my $part = $item->getDirPart();
		$part->setProperty('Type', '');
		$part->touch();
		delete $item->{'directoryHint'};
		# makes sure later code (such as that that rewrites the cache)
		# thinks this is an answer now, not a category.
	}

	# parent and any see-also linkers have changed, since their icons will
	# be wrong. This is just like changing the title, although it doesn't
	# affect siblings, but who cares; we'll just use
	# the usual dependency-update routine.)
	# TODO: maybe siblings should have icons! So should the parent chain!
	$item->setProperty('titleChanged', 1);

	$item->saveToFile();

	$item->notifyModerator($cgi, "made a category into an answer.");

	my $url = FAQ::OMatic::makeAref('-command'=>'faq',
				'-params'=>$params,
				'-changedParams'=>{'checkSequenceNumber'=>''},
				'-refType'=>'url');
		# eliminate things that were in our input form that weren't
		# automatically transient (_ prefix)
	FAQ::OMatic::redirect($cgi, $url);
}

1;
