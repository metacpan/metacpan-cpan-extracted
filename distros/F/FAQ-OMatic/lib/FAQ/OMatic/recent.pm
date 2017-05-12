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

package FAQ::OMatic::recent;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::SearchMod;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	# Get the names of the recent files
	my $matchset = FAQ::OMatic::SearchMod::getRecentSet($params);

	# Filter out those in the trash
	# THANKS: dschulte@facstaff.wisc.edu for the suggestion
	my @finalset = ();
	my $file;
	foreach $file (@{$matchset}) {
		my $item = new FAQ::OMatic::Item($file);
		if (not $item->hasParent('trash')) {
			push @finalset, $item;
		}
	}

	# reasonable text for 'n' days
	my $textDays = FAQ::OMatic::SearchMod::textDays($params->{'_duration'});
	
	my $rt = FAQ::OMatic::pageHeader($params);
	if (scalar(@{$matchset})==0) {
		$rt.=gettexta("No items were modified in the last %0.", $textDays)
			."\n<br>\n";
	} else {
		$rt.=gettexta("Items modified in the last %0:", $textDays)
			."\n<p>\n";

		my $item;
		my $itemboxes = [];
		foreach $item (sort byModDate @finalset) {
			push @$itemboxes, {
				'item'=>$item,
				'rows'=>[
					{ 'type'=>'wide', 'text'=>
						FAQ::OMatic::makeAref("faq",
							{ 'file'	=>	$item->{'filename'} })
							.$item->getTitle()."</a>",
						'id'=>'recent-title' },
						# TODO -- include first part or an excerpt from it?
					{ 'type'=>'wide',
						'text'=>FAQ::OMatic::Item::compactDate(
							$item->{'LastModifiedSecs'}),
						'id'=>'recent-date' }
				] };
		}
		$rt.=FAQ::OMatic::Appearance::itemRender($params, $itemboxes);
	}
	
	$rt .= FAQ::OMatic::pageFooter($params, ['search', 'faq']);

	print $rt;

	FAQ::OMatic::SearchMod::closeWordDB();
}

sub byModDate {
	my $lmsa = $a->{'LastModifiedSecs'} || -1;
	my $lmsb = $b->{'LastModifiedSecs'} || -1;
	return $lmsb <=> $lmsa;
}

1;
