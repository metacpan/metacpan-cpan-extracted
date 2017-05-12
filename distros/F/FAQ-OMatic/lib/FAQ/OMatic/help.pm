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

package FAQ::OMatic::help;

use CGI;

use FAQ::OMatic;
use FAQ::OMatic::Item;
use FAQ::OMatic::HelpMod;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	my $cmd = $params->{'_onCmd'} || '';

	my $mainUrl = FAQ::OMatic::makeAref('-command'=>$cmd,
		'-params'=>$params,
		'-changedParams'=>{'help'=>1},
		'-refType'=>'url',
		'-saveTransients'=>1);
	$helpUrl = FAQ::OMatic::HelpMod::helpURL($params, $cmd);
#	my $helpUrl = FAQ::OMatic::makeAref('-command'=>'faq',
#		'-params'=>$params,
#		'-changedParams'=>{'file'=>'help000'},
#		'-refType'=>'url');

	my $html=<<__EOF__;
<HTML>
<HEAD>
<TITLE>FAQ-O-Matic</TITLE>
</HEAD>
<FRAMESET ROWS="*,200">
	 <FRAME
	       NAME="main-content"
	       SRC="$mainUrl"
	       MARGINWIDTH=1
	       MARGINHEIGHT=1
	       SCROLLING=yes>
	 <FRAME
	        NAME="help"
	        SRC="$helpUrl"
	        MARGINWIDTH=5
	        MARGINHEIGHT=5
			SCROLLING=yes>
</FRAMESET>

<NOFRAMES>
<BODY BGCOLOR="#ffffff">
FAQ-O-Matic Context-Sensitive Help currently works only with
frames. You can navigate the help text independently by following
this link, if it were a link.
</BODY>
</NOFRAMES>
</HTML>
__EOF__

	print FAQ::OMatic::header($cgi, '-type'=>'text/html')
		.$html;
}

1;
