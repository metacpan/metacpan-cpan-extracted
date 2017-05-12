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

package FAQ::OMatic::stats;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Log;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $rt = '';
	
	my $params = FAQ::OMatic::getParams($cgi);

	$params->{'duration'} = '' if (not defined($params->{'duration'}));

	my $simpleHTML = $params->{'simpleHTML'};

	# make sure today is summarized in a .smry file
	FAQ::OMatic::Log::summarizeDay(FAQ::OMatic::Log::numericToday());
	
	# check history now that today is summarized (so there's at least 1 .smry)
	if ($params->{'duration'} eq 'history') {
		# tickle the earliestLogHint file so all 8 graph CGIs
		# don't try to do so simultaneously.
		FAQ::OMatic::Log::earliestSmry();
	}

	# get today's stats for the text part of the display
	my $today = $params->{'today'} || '';
	$today =~ m/([\d-]*)/;	# sanitize user input before treating it as a path
	$today = $1;
	if (not -e "$FAQ::OMatic::Config::metaDir/$today.smry") {
		$today = FAQ::OMatic::Log::numericToday();
	}
	my $todayItem = new FAQ::OMatic::Item("$today.smry", $FAQ::OMatic::Config::metaDir);

	# The list of properties and corresponding titles
	my @props = ('Hits', 'CumHits');
	my @titles = (gettext("Hits Per Day"),
				  gettext("Cumulative Hits"));

	if ($FAQ::OMatic::Config::statUniqueHosts) {
		push @props, ('UniqueHosts', 'CumUniqueHosts');
		push @titles, (gettext("New Hosts Per Day"),
					   gettext("Total Hosts"));
	}

	push @props, ('HitsPerHost', 'CumOperation-search');
	push @titles, (gettext("Hits Per Host"),
				   gettext("Cumulative Searches"));

	push @props, ('Operation-submitPart',	'CumOperation-submitPart');
	push @titles, (gettext("Submissions Per Day"),
				   gettext("Cumulative Submissions"));

	$rt.= FAQ::OMatic::pageHeader($params);
	$rt.= gettext("Please be patient ... the image files are generated dynamically, and can take from 20 to 50 seconds to create.\n");
	$rt.="<table>" if (!$simpleHTML);
	
	my $i;
	for ($i=0; $i<@props; $i++) {
		my $url = FAQ::OMatic::makeAref('statgraph',
			{'property'=>$props[$i],
			 'title'=>$titles[$i],
			 'duration'=>$params->{'duration'},
			 'resolution'=>$params->{'resolution'},
			 'today'=>$params->{'today'}}, 'url');

		if ($i & 0x01) {
			# before the second graph of a pair
			$rt .= $simpleHTML ?
				"" :
				"<td align=center>\n";
		} else {
			# before a pair
			$rt .= $simpleHTML ?
				"" :
				"<tr><td align=center>\n";
		}

		$rt .= "<img src=\"$url\" "
		."width=$FAQ::OMatic::Appearance::graphWidth "
		."height=$FAQ::OMatic::Appearance::graphHeight>";
		my $value = niceValue($todayItem->{$props[$i]});
		$rt .= "<br>".$titles[$i].": ".$value."\n";

		if ($i & 0x01) {
			# after a pair
			$rt .= $simpleHTML ?
				"<p>" :
				"</td></tr>\n";
		} else {
			# after the first graph of a pair
			$rt .= $simpleHTML ?
				"<p>" :
				"</td>\n";
		}
	}
	$rt.="</table>" if (!$simpleHTML);

	$rt.=FAQ::OMatic::button(FAQ::OMatic::makeAref('faq',
		{'duration'=>'','resolution'=>'','today'=>''}),
							 gettext("Return to the FAQ"));

	# let the user change the view
	$rt.=" "
		. gettext("Change View Duration")
		. ": ";
	$rt.=FAQ::OMatic::button(FAQ::OMatic::makeAref('stats',
		{'duration'=>'30'}), gettext("One Month"));
	$rt.=FAQ::OMatic::button(FAQ::OMatic::makeAref('stats',
		{'duration'=>'60'}), gettext("Two Months"));
	$rt.=FAQ::OMatic::button(FAQ::OMatic::makeAref('stats',
		{'duration'=>'90'}), gettext("Three Months"));
	$rt.=FAQ::OMatic::button(FAQ::OMatic::makeAref('stats',
		{'duration'=>'history'}), gettext("History"));

	$rt .= FAQ::OMatic::pageFooter($params);
	print $rt;
}

sub niceValue {
	my $value = shift || '';

	$value = 0 if ($value eq '');

	if (not $value =~ m/\./) {
		# for big numbers
		$value =~ s/(?!^|,)(\d\d\d)$/,$1/;	# add commas for readability
		$value =~ s/(?!^|,)(\d\d\d),/,$1,/;	# of big numbers. This'll keep you
		$value =~ s/(?!^|,)(\d\d\d),/,$1,/;	# til your trillionth hit. :v)
	} else {
		# for little numbers
		$value = sprintf "%.2f", $value;
	}
	return $value;
}

1;
