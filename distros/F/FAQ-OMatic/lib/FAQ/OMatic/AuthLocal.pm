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

package FAQ::OMatic::AuthLocal;

# To implement a local authentication scheme, return a true value
# if the id and password are valid, else return a false value.
#
# (There should be a way for you to also hide or override the
# 'set a new password' mechanism, but there isn't as of this writing,
# version 2.504.)

sub checkPassword {
	my $id = shift;
	my $pass = shift;

	my ($idf,$passf,@rest) = FAQ::OMatic::Auth::readIDfile($id);
	if ((defined $idf)
		and ($idf eq $id)
		and ($passf ne '__INVALID__')	# avoid the obvious vandal's hole...
		and FAQ::OMatic::Auth::checkCryptPass($pass, $passf)) {
		return 'true';
	}

	return undef;
}

1;
