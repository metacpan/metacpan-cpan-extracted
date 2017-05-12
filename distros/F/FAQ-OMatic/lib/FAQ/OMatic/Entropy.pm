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
### Entropy looks around for some entropy for better password/nonce
### generation. Uses /dev/random if you've got it.
###

package FAQ::OMatic::Entropy;

use Digest::MD5 qw(md5_hex);

# generate a temporary password
# THANKS to Matej Vela <vela@debian.org> for pointing out that my crappy
# first cut ( crypt(rand(time)) ) was very easily attackable with an offline
# attack: so if your fom file becomes world-readable and your config
# goes away, an attacker could easily compute the attack offline, then
# log in and control the config page: that's a lot of power. He can
# specify executables to run there. Yikes!
# Just for kicks, a google search for "temporaryCryptedPassword" found
# four publically-readable passwords. They weren't vulnerable because the
# sites config files are set up correctly ... for now! Scary.
#
# So, to be a little safer, let's use a less-attackable hash (which will
# require admins to install Digest::MD5), and collect entropy wherever
# we can find it.
# (Perhaps we could fancy-up crypt to give more like 112 bits of hash
# quality by tweaking it to essentially do 3DES, but I doubt it, and I
# don't want my crypto sloppiness to expose your machine to attack.)
# 
sub gatherRandomString {
	my $entropy = '';
	$entropy .= $$;
	$entropy .= time();
	# if you've got real random bits, let's take 128 of them.
	# Too bad there's not a standard way to fetch real entropy on all platforms
	if (-r "/dev/random") {
		my $buf;
		open (RANDFH, "/dev/random");
		sysread(RANDFH, $buf, 16);
		close (RANDFH);
		$entropy .= $buf;
	}
	# grab some more sources for those poor slobs who don't have /dev/random
	$entropy .= `uptime`;
	$entropy .= `uname -a`;

	# hash it all up into a secret password
	return md5_hex($entropy);
}

1;
