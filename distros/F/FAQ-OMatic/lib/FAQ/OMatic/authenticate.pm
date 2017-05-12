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

package FAQ::OMatic::authenticate;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::HelpMod;
use FAQ::OMatic::I18N;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $params = FAQ::OMatic::getParams($cgi);

	my $rt = FAQ::OMatic::pageHeader($params, ['help', 'faq']);

	my $what = $params->{'_restart'};
	my $whoIsAllowed = FAQ::OMatic::Auth::authError($params->{'_reason'},
		$params->{'file'});

	# Give them the option of setting up a new password
	# Creating a login is the same thing
	my $newPassButton .= FAQ::OMatic::button(
			FAQ::OMatic::makeAref('changePass',
				{'_pass_pass' => '',
			 	'_pass_id' => '' }, '', 'saveTransients'),
			gettext("Set a New Password"));
	my $newLoginButton .= FAQ::OMatic::button(
			FAQ::OMatic::makeAref('changePass',
				{'_pass_pass' => '',
			 	'_pass_id' => '' }, '', 'saveTransients'),
			gettext("Create a New Login"));

	if ($params->{'badPass'}) {
		$rt.=gettext("That password is invalid. If you've forgotten your old password, you can")." $newPassButton.\n";

		delete $params->{'badPass'};
		# We had to use a nontransient param because the func that sets
		# the badPass flag (FAQ::OMatic::AuthLocal::authenticate()) doesn't directly
		# generate a URL, and of course stuffing a transient param
		# into the param list won't make it to the URL.
		#
		# You're probably worried the param could live on too long (I was).
		# Say you fill in the authentication dialog with a bad password.
		# You get a badPass param, but say the script checking your
		# authentication decides to accept the 'anonymous' $aq==1
		# authentication that results. But wait -- the reason you were
		# asked to authenticate in the first place was that your previous
		# auth wasn't good enough for that script. And aq=1 is certainly
		# no better.
	} else {
		if ($what eq 'addItem') {
			$rt.=gettexta("New items can only be added by %0.",$whoIsAllowed);
		} elsif ($what eq 'addPart') {
			$rt.=gettexta("New text parts can only be added by %0.",$whoIsAllowed);
		} elsif ($what eq 'delPart') {
			$rt.=gettexta("Text parts can only be removed by %0.",$whoIsAllowed);
		} elsif ($what eq 'editPart' or $what eq 'submitPart') {
			my $xreason = $params->{'_xreason'} || '';
			if ($xreason eq 'useHTML') {
				$rt.=gettexta("This part contains raw HTML. To avoid pages with invalid HTML, the moderator has specified that only %0 can edit HTML parts. If you are %0 you may authenticate yourself with this form.",$whoIsAllowed);
			} elsif ($params->{'_insertpart'}) {
				$rt.=gettexta("Text parts can only be added by %0.",$whoIsAllowed);
			} else {
				$rt.=gettexta("Text parts can only be edited by %0.",$whoIsAllowed);
			}
		} elsif ($what eq 'editItem' or $what eq 'submitItem') {
			$rt.=gettexta("The title and options for this item can only be edited by %0.",$whoIsAllowed);
		} elsif ($what eq 'editModOptions' or $what eq 'submitModOptions') {
			$rt.=gettexta("The moderator options can only be edited by %0.",$whoIsAllowed);
		} elsif ($what eq 'moveItem' or $what eq 'submitMove') {
			if ($whoIsAllowed =~ m/moderator/) {
				$rt.=gettext("This item can only be moved by someone who can edit both the source and destination parent items.");
			} else {
				$rt.=gettexta("This item can only be moved by %0.",$whoIsAllowed);
			}
		} elsif ($what eq 'selectBag'
			or $what eq 'editBag'
			or $what eq 'submitBag') {
			my $xreason = $params->{'_xreason'} || '';
			if ($xreason eq 'replace') {
				$rt.=gettexta("Existing bags can only be replaced by %0.",$whoIsAllowed);
			} else {
				$rt.=gettexta("Bags can only be posted by %0.",$whoIsAllowed);
			}
		} elsif ($what eq 'install') {
			$rt.=gettexta("The FAQ-O-Matic can only be configured by %0.",$whoIsAllowed);
		} else {
			$rt.=gettexta("The operation you attempted (%0) can only be done by %1.",$what,$whoIsAllowed);
		}
	
		$rt .= "<ul><li>".gettext("If you have never established a password to use with FAQ-O-Matic, you can")." $newLoginButton.\n";
		$rt .= "<li>".gettext("If you have forgotten your password, you can")." $newPassButton.\n";
		$rt .= "<li>".gettext("If you have already logged in earlier today, it may be that the token I use to identify you has expired. Please log in again.")."\n";
		$rt .= "</ul>\n";
	}

	$rt .= FAQ::OMatic::makeAref($params->{'_restart'},
			{ 'id' => '', 'auth' => '',
				'_pass_id'=>'',		# since we saveTransients, our own
				'_pass_pass'=>'',	# transients must be explicitly killed
				'_none_id'=>'' },
			'POST', 'saveTransients');

	my $reason = FAQ::OMatic::stripInt($params->{'_reason'});
	if ($reason <= 3) {
		$rt .= "<p>"
			.gettext("Please offer one of the following forms of identification:")."\n";
	
		$rt .= "<p><input type=radio name=\"auth\" value=\"none\" checked>\n";
		$rt .= " ".gettext("No authentication, but my email address is:")."\n";
		$rt .= "<br>".gettext("Email:")
			." <input type=text name=\"_none_id\" value=\"\" size=60>\n";
	}

	$rt .= "<p><input type=radio name=\"auth\" value=\"pass\"";
	$rt .= " checked" if ($reason > 3);
	$rt .= ">\n";
	$rt .= " ".gettext("Authenticated login:")."\n";
	$rt .= "<br>Email: <input type=text name=\"_pass_id\" value=\"\" size=60>\n";
	$rt .= "<br>".gettext("Password:")." <input type=password name=\"_pass_pass\" value=\"\" size=10>\n";

	$rt .= "<p><input type=submit name=\"_submit\" value=\"".gettext("Log In")."\">\n";
	$rt .= "</form>\n";

	# Give them the option of leaving whatever authentication they
	# used to have intact, and giving up on "better" auth.
#	$rt .= FAQ::OMatic::button(FAQ::OMatic::makeAref(
#				'-command'=>'faq',
#				'-params'=>$params,
#				'-changedParams'=>{'partnum'=>'',
#					'checkSequenceNumber'=>''}
#				),
#			"Cancel and Return to FAQ");

	$rt.=FAQ::OMatic::HelpMod::helpFor($params, 'authenticate');

	$rt .= FAQ::OMatic::pageFooter($params, ['help', 'faq']);

	print $rt;
}

1;


