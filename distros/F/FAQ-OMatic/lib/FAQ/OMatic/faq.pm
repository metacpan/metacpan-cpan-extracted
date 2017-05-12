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

package FAQ::OMatic::faq;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();

	my $params = FAQ::OMatic::getParams($cgi);
	# supply some default parameters where necessary
	$params->{'file'} = 1 if (not $params->{'file'});

	# strip out null params from params array
	if ($params->{'_fromAppearance'}) {
		my $key;
		foreach $key (keys %{$params}) {
			delete $params->{$key} if ($params->{$key} eq '');
		}
		delete $params->{'_fromAppearance'};
	}

	my $cacheUrl = FAQ::OMatic::getCacheUrl($params);
	if ($cacheUrl) {
		# Hey! We could just send this guy to the cached site!
		FAQ::OMatic::redirect($cgi, $cacheUrl);
		# (implicit exit)
	}

	my $render = FAQ::OMatic::getParam($params, 'render');
	my $html = '';
	if ($render eq 'text') {
		$html .= FAQ::OMatic::header($cgi, '-type'=>'text/plain');
	} else {
		$html .= FAQ::OMatic::header($cgi, '-type'=>'text/html');
	}
	
	if (FAQ::OMatic::getParam($params, 'editCmds') ne 'hide') {
		FAQ::OMatic::mirrorsCantEdit($cgi, $params);
	}

	my $item = new FAQ::OMatic::Item($params->{'file'});
	if ($item->isBroken()) {
		FAQ::OMatic::gripe('error', gettexta("The file (%0) doesn't exist.", $params->{'file'}));
	}

	if ($params->{'debug'}) {
		$html .= $item->display();
	}

	$html .= $item->getWholePage($params);

# TODO: worry about this when we turn the help system back on
# TODO- (perhaps just stuff it into getWholePage().)
#	if (not $params->{'file'} =~ m/^help/) {
#		$html .= FAQ::OMatic::pageFooter($params, 'all');
#	}

	print $html;
}

1;
