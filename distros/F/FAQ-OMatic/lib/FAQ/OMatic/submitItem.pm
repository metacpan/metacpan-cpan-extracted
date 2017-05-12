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

package FAQ::OMatic::submitItem;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::I18N;


sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);

	my $item = new FAQ::OMatic::Item($params->{'file'});
	if ($item->isBroken()) {
		FAQ::OMatic::gripe('error', gettexta("The file (%0) doesn't exist.", $params->{'file'}));
	}

	FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
		'-operation'=>'PermEditTitle',
		'-restart'=>'editItem',
		'-cgi'=>$cgi,
		'-extraTime'=>1,
		'-failexit'=>1);
	
	# verify that an evil cache hasn't truncated a POST
	if ($params->{'_zzverify'} ne 'zz') {
		FAQ::OMatic::gripe('error',
			gettext("Your browser or WWW cache has truncated your POST."));
	}

	$item->checkSequence($params);
	$item->incrementSequence();

	my $titleMessage = '';
	if (FAQ::OMatic::getParam($params, '_Title') ne '') {
		my $oldTitle = $item->getProperty('Title');
		my $newTitle = FAQ::OMatic::getParam($params, '_Title');
		if ($oldTitle ne $newTitle) {
			$titleMessage = " ".gettexta("Changed the item title, was \"%0\"", $oldTitle);
		}
		$item->setProperty('Title', $newTitle); 
	}
	if (defined $params->{'_partOrder'}) {
		# get the user's new ordering for the parts
		#my @newOrder = ($params->{'_partOrder'} =~
		#					m/([^\s,]+)/sg);
		# for some reason the previous construct doesn't extract more
		# than one item from the list on some Perls.
		# THANKS to Matthew Enger <menger@dhs.org>
		# for reporting the problem.
		my @newOrder = split(/[\s,]+/, $params->{'_partOrder'} || '');

		# verify that there are as many items in the new order as the old:
		if (scalar @newOrder != $item->numParts()) {
			FAQ::OMatic::gripe('error', gettexta("Your part order list (%0) ", join(", ", @newOrder))
				.gettexta("doesn't have the same number of parts (%0) as the original item.", $item->numParts()));
		}

		# verify now that every number 0 .. numParts()-1 appears exactly
		# once in the new list.
		my %newOrderHash = map { ($_,1) } @newOrder;
		my $i;
		for ($i=0; $i<$item->numParts(); $i++) {
			if (not $newOrderHash{$i}) {
				FAQ::OMatic::gripe('error', gettexta("Your part order list (%0) ", join(", ", @newOrder))
					.gettexta("doesn't say what to do with part %0.", $i));
			}
		}

		# now we trust the @newOrder array.
		my $newPartOrder = [];	# new anonymous array
		foreach $i (@newOrder) {
			push @{$newPartOrder}, $item->getPart($i);
		}

		# install the new anonymous array
		$item->{'Parts'} = $newPartOrder;
	}

	$item->setProperty('AttributionsTogether',
		defined $params->{'_AttributionsTogether'} ? 1 : '');

	$item->saveToFile();

	$item->notifyModerator($cgi, 'edited the item configuration.'
		.$titleMessage);

	if (FAQ::OMatic::getParam($params, 'isapi')) {
		# caller is a program; doesn't want a redirect to an HTML file!
		# provide textual results
		print FAQ::OMatic::header($cgi, '-type'=>'text/plain')
			."isapi=1\n"
			."file=".$item->{'filename'}."\n"
			."checkSequenceNumber=".$item->{'SequenceNumber'}."\n";
		FAQ::OMatic::myExit(0);
	}

	my $url;
	if ($params->{'_insert'}) {
		$url = FAQ::OMatic::makeAref(
			'-command'=>'editPart',
			'-params'=>$params,
			'-changedParams'=>{'_insertpart'=>1,
				'partnum'=>'-1',
				'checkSequenceNumber'=>$item->{'SequenceNumber'},
				'_insert'=>$params->{'_insert'}},
			'-refType'=>'url');
	} else {
		$url = FAQ::OMatic::makeAref(
			'-command'=>'faq',
			'-params'=>$params,
			'-changedParams'=>{'checkSequenceNumber'=>''},
			'-refType'=>'url');
	}

	FAQ::OMatic::redirect($cgi, $url);
}

1;





