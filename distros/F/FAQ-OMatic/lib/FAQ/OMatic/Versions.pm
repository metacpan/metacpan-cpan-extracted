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

###
### The Versions module is used by the installer and maintenance modules
### to keep track of upgrade status.
###

package FAQ::OMatic::Versions;

use FAQ::OMatic;
use FAQ::OMatic::Item;

sub getVersion {
	my $property = shift;

	my $versionItem = new FAQ::OMatic::Item('versionFile',
		$FAQ::OMatic::Config::metaDir);
	return $versionItem->{$property} || '';
}

sub setVersion {
	my $property = shift;
	my $version = shift || $FAQ::OMatic::VERSION;

	my $versionItem = new FAQ::OMatic::Item('versionFile',
		$FAQ::OMatic::Config::metaDir);
	$versionItem->setProperty('Title', "Versions Data File");
	$versionItem->setProperty($property, $version);
	$versionItem->saveToFile('versionFile',
		$FAQ::OMatic::Config::metaDir);
}

1;
