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

package FAQ::OMatic::submitAnsToCat;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::I18N;
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

	if ($item->isCategory()) {
		# users would rarely see this message; they'd have to forge the URL.
		FAQ::OMatic::gripe('error', "This is an answer, not a category.");
	}

	$item->makeDirectory()->
		setText(gettext("Subcategories:")."\n\n\n".gettext("Answers in this category:")."\n");

	# parent and any see-also linkers have changed, since their icons will
	# be wrong. This is just like changing the title, although it doesn't
	# affect siblings, but who cares; we'll just use
	# the usual dependency-update routine.)
	$item->setProperty('titleChanged', 1);

	# in any case, the user has co-authored the document
	# TODO: does this make sense for just changing the status of a part?
	my ($id,$aq) = FAQ::OMatic::Auth::getID();
	$item->getDirPart()->addAuthor($id) if ($id);
	$item->saveToFile();

	$item->notifyModerator($cgi, "made an answer into a category.");

	my $url = FAQ::OMatic::makeAref('-command'=>'faq',
				'-params'=>$params,
				'-changedParams'=>{'checkSequenceNumber'=>''},
				'-refType'=>'url');
		# eliminate things that were in our input form that weren't
		# automatically transient (_ prefix)
	FAQ::OMatic::redirect($cgi, $url);
}

1;
