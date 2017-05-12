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

package FAQ::OMatic::submitModOptions;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic::I18N;
use FAQ::OMatic;
use FAQ::OMatic::Auth;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);

	my $item = new FAQ::OMatic::Item($params->{'file'});
	if ($item->isBroken()) {
		FAQ::OMatic::gripe('error', gettexta("The file (%0) doesn't exist.", $params->{'file'}));
	}

	FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
		'-operation'=>'PermModOptions',
		'-restart'=>'editModOptions',
		'-cgi'=>$cgi,
		'-failexit'=>1);
	
	# verify that an evil cache hasn't truncated a POST
	if ($params->{'_zzverify'} ne 'zz') {
		FAQ::OMatic::gripe('error',
			"Your browser or WWW cache has truncated your POST.");
	}

	$item->checkSequence($params);
	$item->incrementSequence();

	# set each defined permission from $params
	my $pi = FAQ::OMatic::Item::permissionsInfo();
	my @permSet = map { $pi->{$_}->{'name'} } sort keys %{$pi};
	push @permSet, 'Moderator', 'MailModerator', 'Notifier', 'MailNotifier', 'RelaxChildPerms';
	my $perm;
	foreach $perm (@permSet) {
		if (defined $params->{"_$perm"}) {
			$item->setProperty($perm, $params->{"_$perm"});
		}
	}

	$item->saveToFile();

	$item->notifyModerator($cgi, 'edited the moderator options');

	my $url = FAQ::OMatic::makeAref(
		'-command'=>'faq',
		'-params'=>$params,
		'-changedParams'=>{'checkSequenceNumber'=>''},
		'-refType'=>'url');

	FAQ::OMatic::redirect($cgi, $url);
}

1;
