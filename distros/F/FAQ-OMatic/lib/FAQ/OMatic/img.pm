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
### img.pm
###
### A dynamic interface to the images in ImageData.pm. It's only
### here in case there's just no way to get the images into the filesystem
### and http-serve them from there.
###

package FAQ::OMatic::img;

use FAQ::OMatic::ImageRef;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $name = $cgi->param('name') || 'unchecked';

	my $data = FAQ::OMatic::ImageRef::getImage($name);

	print FAQ::OMatic::header($cgi,
			'-type'=>"image/".FAQ::OMatic::ImageRef::getType($name),
			'-expires'=>24*30*3);	# cache those suckers for a good season
	print $data;
}

1;
