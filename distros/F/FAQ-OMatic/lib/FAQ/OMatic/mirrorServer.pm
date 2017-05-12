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

package FAQ::OMatic::mirrorServer;

use CGI;
use FAQ::OMatic;
use FAQ::OMatic::Item;
use FAQ::OMatic::install;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	my $rt = "Content-type: text/plain\n\n";
	$rt .= "# FAQ-O-Matic mirror master\n";
	$rt .= "# This file describes the configuration, items, and bags of a\n"
		."# FAQ-O-Matic, so it can be mirrored at another site.\n";

	# mirror format version number -- sent so client (mirror) can make
	# sure he understands the structure of the following data.
	$rt .= "version 1.0\n";
	$rt .= "itemURL $FAQ::OMatic::Config::itemURL\n";
	$rt .= "bagsURL $FAQ::OMatic::Config::bagsURL\n";

	# send mirrorable config params
	my $configInfo = FAQ::OMatic::install::configInfo();
	my $map = FAQ::OMatic::install::readConfig();
	my $key;
	foreach $key (sort keys %{$configInfo}) {
		my $ch = $configInfo->{$key};
		next if (not $ch->{'-mirror'});
		my $value = $map->{'$'.$key} || "''";	# undefined => ''
		$rt.='config $'."$key = $value\n";
	}

	# send item catalog
	my $file;
	my @allItems = sort numerically FAQ::OMatic::getAllItemNames();
	foreach $file (@allItems) {
		my $item = new FAQ::OMatic::Item($file);
		my $lms = $item->{'LastModifiedSecs'} || time();
		my $whatIsIt = $item->whatAmI();
		$rt.="item $file $lms $whatIsIt\n";
	}

	# send bags catalog
	my @bagList = grep { not m/\.desc$/ }
		FAQ::OMatic::getAllItemNames($FAQ::OMatic::Config::bagsDir);
	my $bagName;
	foreach $bagName (sort @bagList) {
		my $item = new FAQ::OMatic::Item($bagName.".desc",
							$FAQ::OMatic::Config::bagsDir);
		my $lms = $item->{'LastModifiedSecs'} || time();
		$rt.="bag $bagName $lms\n";
	}

	print $rt;
}

# sort numeric things numerically, but don't fail (sort lexically) otherwise.
sub numerically {
	my $compare = FAQ::OMatic::stripInt($a) <=> FAQ::OMatic::stripInt($b);
	if ($compare == 0) {
		$compare = $a cmp $b;
	}
	return $compare;
}

1;
