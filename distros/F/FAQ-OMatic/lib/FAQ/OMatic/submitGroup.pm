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

package FAQ::OMatic::submitGroup;

use CGI;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::Groups;
use FAQ::OMatic::Versions;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);

	my $action = $params->{'_action'};
	my $group = $params->{'group'};
	my $member = $params->{'_member'};

	FAQ::OMatic::Auth::ensurePerm(
		'-operation'=>'PermEditGroups',
		'-restart'=>FAQ::OMatic::commandName(),
		'-cgi'=>$cgi,
		'-extraTime'=>1,
		'-failexit'=>1);

	if ($action eq 'add') {
		FAQ::OMatic::Groups::validGroupName($group);

		# Things that aren't email addresses (no '@') are taken
		# to be domains to match.
		#if (not FAQ::OMatic::validEmail($member)) {
		#	FAQ::OMatic::gripe('error', "'$member' doesn't appear to "
		#		."be a valid email address.");
		#}

		# THANKS: To "Mark D. Nagel" <nagel@intelenet.net> for catching
		# this bad case.
		if (($member eq '') or ($member=~m/\s/)) {
			FAQ::OMatic::gripe('error',
				"Member field ('$member') is empty or contains whitespace.");
		}

		FAQ::OMatic::Groups::addMember($group, $member);

		FAQ::OMatic::Versions::setVersion('CustomGroups', '1');
	} elsif ($action eq 'remove') {
		FAQ::OMatic::Groups::validGroupName($group);

		FAQ::OMatic::Groups::removeMember($group, $member);
	} else {
		FAQ::OMatic::gripe('error', "Invalid action '$action'.");
	}

	my $url = FAQ::OMatic::makeAref('editGroups', {}, 'url');
	FAQ::OMatic::redirect($cgi, $url);
}

1;
