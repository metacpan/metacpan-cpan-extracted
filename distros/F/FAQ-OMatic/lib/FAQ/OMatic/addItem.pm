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

package FAQ::OMatic::addItem;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);

	my $file = $params->{'file'} || '';
	my $item = new FAQ::OMatic::Item($file);
	if ($item->isBroken()) {
		FAQ::OMatic::gripe('error', gettexta("The file (%0) doesn't exist.", $file));
	}

	FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
		'-operation'=>'PermAddItem',
		'-restart'=>FAQ::OMatic::commandName(),
		'-cgi'=>$cgi,
		'-failexit'=>1);

	my $duplicateFrom = $cgi->param('_duplicate');
	my $newitem;
	if ($duplicateFrom) {
		# duplicate an existing item
		my $source = new FAQ::OMatic::Item($duplicateFrom);
		if ($source->isBroken()) {
			FAQ::OMatic::gripe('error', "The source of the duplicate (file=".
				$duplicateFrom.") is broken.");
		}
		$newitem = $source->clone();
		$newitem->setProperty("Title", gettext("Copy of")." ".$newitem->getTitle());
	} else {
		# create a new item in destination item file
		$newitem = new FAQ::OMatic::Item();
		# inherit parent's properties:
		$newitem->setProperty('AttributionsTogether',
			$item->{'AttributionsTogether'});
	}
	$newitem->setProperty("Parent", $item->{'filename'});
			# tell the new kid who his parent is.
	$newitem->setProperty('Moderator', '');
		# regardless of what the parent did, we inherit moderator
		# from parent rather than setting it explicitly.
			
		# THANKS to <dgatwood@mklinux.org> for the following patch:
		# BZZT.  That sucks.  Set it explicitly if relax is set.     
	if (($item->getProperty('RelaxChildPerms')||'') eq 'relax') {
		my ($id,$aq) = FAQ::OMatic::Auth::getID();
		if ($id) { 
			$newitem->setProperty('Moderator', $id);
		} else {
			print FAQ::OMatic::header($cgi, '-type'=>'text/plain');
			FAQ::OMatic::gripe('error',
				"You must be logged in to add to a category if "
				."RelaxChildPerms is set to relax.\n"
				."You should not ever see this message.  "
				."Contact your site administrator.\n");
			FAQ::OMatic::myExit(0);
		}
	}

	# if user was asking for a category, add a directory just to
	# make him feel better
	if ($params->{'_insert'} eq 'category') {
		$newitem->makeDirectory()->
			setText(gettext("Subcategories:")."\n\n\n".gettext("Answers in this category:")."\n");
	}

	# passing $file as a name ensures that new child will have the
	# same type of name as its parent. (such as a helpfile)
	$newitem->saveToFile(FAQ::OMatic::unallocatedItemName($file));

	# add that item to the (proud) parent item's catalog
	$item->addSubItem($newitem->{'filename'});
	$item->saveToFile();

	$item->notifyModerator($cgi, 'added a sub-item #'.$newitem->{'filename'});

	if (FAQ::OMatic::getParam($params, 'isapi')) {
		# caller is a program; doesn't want a redirect to an HTML file!
		# provide textual results
		print FAQ::OMatic::header($cgi, '-type'=>'text/plain')
			."isapi=1\n"
			."file=".$newitem->{'filename'}."\n"
			."checkSequenceNumber=".$newitem->{'SequenceNumber'}."\n";
		FAQ::OMatic::myExit(0);
	}

	# redirect user to the new page
	my $url;
	if ($duplicateFrom) {
		$url = FAQ::OMatic::makeAref('editItem',
			{'file'=>$newitem->{'filename'},
	 		 '_duplicate'=>$params->{'_duplicate'}},
			'url');
	} else {
		# send the user to the edit item page, to supply the title
		$url = FAQ::OMatic::makeAref('editItem',
			{'file'=>$newitem->{'filename'},
		 	 '_insert'=>$params->{'_insert'}},
			'url');
	}

	FAQ::OMatic::redirect($cgi, $url);
}

1;
