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

package FAQ::OMatic::ColorPicker;

sub findRGB {
	my $horizFrac = shift;	# fraction of distance along horizontal of image
	my $vertFrac = shift;

	my $f16 = 1/6;
	my $f26 = 2/6;
	my $f36 = 3/6;
	my $f46 = 4/6;
	my $f56 = 5/6;
	my $f66 = 1;

	my ($hue, $red, $green, $blue);

	$hue = $horizFrac;
	if ($hue<$f16) {
		$red = 1;
		$green = $hue*6;
		$blue = 0;
	} elsif ($hue<$f26) {
		$red = ($f26-$hue)*6;
		$green = 1;
		$blue = 0;
	} elsif ($hue<$f36) {
		$red = 0;
		$green = 1;
		$blue = 1-($f36-$hue)*6;
	} elsif ($hue<$f46) {
		$red = 0;
		$green = ($f46-$hue)*6;
		$blue = 1;
	} elsif ($hue<$f56) {
		$red = 1-($f56-$hue)*6;
		$green = 0;
		$blue = 1;
	} else {	# $hue<$f66
		$red = 1;
		$green = 0;
		$blue = ($f66-$hue)*6;
	}
	if ($vertFrac<0.5) {	# blend toward white
		my $trans = 2*$vertFrac;	# at middle, $trans = 1
		$red	= $trans*$red	+ (1-$trans)*1;
		$green	= $trans*$green	+ (1-$trans)*1;
		$blue	= $trans*$blue	+ (1-$trans)*1;
	} else {
		my $trans = 2*(1-$vertFrac);	# at middle, $trans = 1
		$red	= $trans*$red	+ 0;
		$green	= $trans*$green	+ 0;
		$blue	= $trans*$blue	+ 0;
	}

	return ($red,$green,$blue);
}

1;
