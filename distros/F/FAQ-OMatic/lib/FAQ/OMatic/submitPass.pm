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

package FAQ::OMatic::submitPass;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::I18N;


sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	
	my $params = FAQ::OMatic::getParams($cgi);

	if ($params->{'_fromChangePass'} or $params->{'_badSecret'}) {
		# this is the user coming from changePass; send the secret
		# in email, and put up a page explaining what to do.
		my $id = $params->{'_id'} || '';
		if (not FAQ::OMatic::validEmail($id)) {
			FAQ::OMatic::gripe('error', gettext("An email address must look like 'name\@some.domain'.")
				."\n"
				.gettexta("If yours (%0) does and I keep rejecting it, please mail the administrator of this FAQ at %1 and tell him or her what's happening.",
					 $id, $FAQ::OMatic::Config::adminEmail));
		}
		my $pass = $params->{'_pass'} || '';
			# THANKS to Mark Shaw <mshaw@dal.asp.ti.com> for catching this
			# potential uninitialized value error.
		if (not ($pass =~ m/^\S*$/)) {
			FAQ::OMatic::gripe('error', gettext("Your password may not contain spaces or carriage returns."));
		}

		# put the secret in the IDfile, but don't put in the new
		# Only create a secret if user is coming straight from changePass.
		# Don't create ANOTHER secret if this is just the user
		# looping back around after entering a bad secret.
		if ($params->{'_fromChangePass'}) {
			my $secret = FAQ::OMatic::Entropy::gatherRandomString();
			my $restart = $params->{'_restart'} ||
				FAQ::OMatic::makeAref('faq', {}, 'url', 0, 'blastAll');
			# keep passwords out of the GET request fired up
			# when restarting after an authentication.
			# THANKS to
			# Cream-puff Casper Milquetoast <doughnut@doughnut.net>
			# for reporting this issue.
			my $saveurl = FAQ::OMatic::makeAref($restart,
				{'auth'=>'','pass'=>'','id'=>'',
				 '_id'=>'', '_pass'=>''},
				'url', 'saveTransients');

			# password yet, or we'll have circumvented the whole secret
			# thing.
			my ($idf,$passf,$secretf,$saveurlf,$oldwaitpassf,@rest)=FAQ::OMatic::Auth::readIDfile($id);
			if ((not defined $passf)
				or (not defined $idf)
				or ($idf ne $id)) {
				$passf = '__INVALID__';
			}
			my $cryptwaitpass = FAQ::OMatic::Auth::cryptPass($pass);
				# we'll store the crypted version to install later
	
			FAQ::OMatic::Auth::writeIDfile($id,$passf,$secret,$saveurl,$cryptwaitpass,@rest);
	
			# mail the user the secret url
			my $secreturl = FAQ::OMatic::makeAref('submitPass',
								{	'_id'=>$id,
									'_secret'=>$secret	},
								'url', 0, 'blastAll');
			my $subj = gettext("Your Faq-O-Matic authentication secret");
                        my $mesg = gettext("To validate your Faq-O-Matic password, you may either enter this secret into the Validation form:")."\n\n";   
			$mesg .= gettext("Secret:")." ".$secret."\n\n";
                        $mesg .= gettext("Or access the following URL. Be careful when you copy and paste the URL that the line-break doesn't cut the URL short.");
                        $mesg .= "\n\n$secreturl\n\n".gettext("Thank you for using Faq-O-Matic.")."\n\n";
			$mesg .= gettexta("(Note: if you did not sign up to use the Faq-O-Matic, someone else has attempted to log in using your name. Do not access the URL above; it will validate the password that user has supplied. Instead, send mail to %0 and I will look into the matter.)", $FAQ::OMatic::Config::adminEmail );

			if (FAQ::OMatic::sendEmail($id, $subj, $mesg)) {
				FAQ::OMatic::gripe('error',
					gettexta("I couldn't mail the authentication secret to \"%0\" and I'm not sure why.", $id));
			}
		}

		# now tell the user what's going on
		my $rt = '';

		$rt .= FAQ::OMatic::pageHeader($params);

		if ($params->{'_badSecret'}) {
			$rt .= gettext("The secret you entered is not correct.")."\n";
			$rt .=
			gettext("Did you copy and paste the secret or the URL completely?")
				."\n<p>\n";
		}
		else {
			$rt .= gettexta("I sent email to you at \"%0\". It should arrive soon, containing a URL.",
							$id)
				."\n<p>\n";
		}
		$rt.= gettext("Either open the URL directly, or paste the secret into the form below and click Validate.")
			."\n<p>\n"
			.gettext("Thank you for taking the time to sign up.")
			."\n";

		$rt.= FAQ::OMatic::makeAref('submitPass',
					{	'_id'=>$id,
						'_pass'=>$pass },
					'POST', 0, 'blastAll');
		#$rt.="<form action=\"submitPass\" method=POST>\n";
		$rt.= gettext("Secret:")." \n";
		$rt.= "<input type=text name=\"_secret\" value=\"\" size=36>\n";
		$rt.= "<p><input type=submit name=\"_submit\" value=\"".gettext("Validate")."\">\n";
		$rt.= "</form>\n";

		$rt .= FAQ::OMatic::pageFooter($params);
		print $rt;
	} else {
		# this is the user presenting his secret received via email
		my $id = $params->{'_id'};
		my $secret = $params->{'_secret'};
		my ($idf,$passf,$secretf,$saveurl,$cryptwaitpassf,@rest)
			= FAQ::OMatic::Auth::readIDfile($id);
		if (not defined($idf)
			or not ($idf eq $id)
			or not ($secret eq $secretf)) {
			# if we get the wrong secret, send the user back
			# around to the page with the Validate button (the top case
			# in this file) to give them another chance to enter the secret.
			my $url = FAQ::OMatic::makeAref('submitPass',
				{ '_badSecret'=>1, '_id'=>$id }, 'url');
			FAQ::OMatic::redirect($cgi, $url);
		}

		# no secret necessary anymore
		FAQ::OMatic::Auth::writeIDfile($idf, $cryptwaitpassf);
		# generate a cookie. We know it's you by your secret, but
		# we don't have your (uncrypted) password to let you go through the
		# normal password check. So we'll just create a cookie right now.
		my $newauth = "&auth=".FAQ::OMatic::Auth::newCookie($idf);
		FAQ::OMatic::redirect($cgi, $saveurl.$newauth);
	}
}

1;





