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

package FAQ::OMatic::submitPart;

use CGI;
use FAQ::OMatic::Item;
use FAQ::OMatic::I18N;
use FAQ::OMatic;
use FAQ::OMatic::Auth;

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $removed = 0;
	
	my $params = FAQ::OMatic::getParams($cgi);

	FAQ::OMatic::mirrorsCantEdit($cgi, $params);

	my $item = new FAQ::OMatic::Item($params->{'file'});
	if ($item->isBroken()) {
		FAQ::OMatic::gripe('error', gettexta("The file (%0) doesn't exist.", $params->{'file'}));
	}
	
	my $insertpart = $params->{'_insertpart'} || $params->{'s_insertpart'};
		# have to check the s_ case, because we don't extract the s_-encoded
		# parameters until later. (Any reason not to do them here?)

	if (not $insertpart) {
		# if inserting a part, we don't have to check -- inserts can
		# come out of order and it's not too bad.
		$item->checkSequence($params);
	}
	$item->incrementSequence();

	my $partnum = $params->{'partnum'};
	my $part;
	if ($partnum >= 0) {
		$part = $item->getPart($partnum);
		if (not $part) {
			FAQ::OMatic::gripe('error', "Part number \"$partnum\" in \""
				.$params->{'file'}."\" doesn't exist.");
		}
	} else {
		$partnum = -1;
	}
	if (($partnum < 0) and (not $insertpart)) {
		FAQ::OMatic::gripe('error', "Part number \"$partnum\" in \""
			.$params->{'file'}."\" doesn't exist.");
	}

	# if we're inserting a part, create a new one to hold the data
	# and stuff it into the item. (Don't worry about the permissions
	# check being later -- we're only modifying the in-memory copy;
	# we haven't written the item out yet.)
	if ($insertpart) {
		$part = new FAQ::OMatic::Part();
		splice @{$item->{'Parts'}}, $partnum+1, 0, $part;
		$item->updateDirectoryHint();
	}

	# verify that an evil cache hasn't truncated a POST
	if ((($params->{'_zzverify'}||'') ne 'zz')
		and (not $params->{'s_textInFile'})) {
		FAQ::OMatic::gripe('error',
			"Your browser or WWW cache has truncated your POST.");
	}

	# select source of data: file or textarea
	if (($params->{'_inputType'}||'') eq 'file') {
		# THANKS: John Nolan's fix applies here, too.
		my $formFileHandle = $cgi->param('_newTextFile');
		$params->{'_newText'} = '';		# scrap <textarea> text and load file
		my $sizesum = 0;
		# if the nextline gives you an error, update your CGI.pm.
		while (defined(my $line = <$formFileHandle>)) {
			$sizesum += length($line);
			if ($sizesum > 64*1024) {
				FAQ::OMatic::gripe('error',
					"Your file was greater than 64K long.");
			}
			$line =~ s/[^ -~\t\r\n\x80-\xff]//gs;	# limit to printable characters
			$params->{'_newText'} .= $line;
		}
	}

	# verify permissions
	my $authFailed = '';
	my $perm;
	if ($insertpart or ($part->{'Text'} =~ m/^\s*$/s)) {
		# if the part is currently empty, the user is doing no more than
		# an add. But we always send users back to editPart, since the
		# only way to get this far and fail is by cheating, so a weird
		# error message ain't my fault. :v)
		$perm = 'PermAddPart';
	} else {
		$perm = 'PermEditPart';
	}
	$authFailed = FAQ::OMatic::Auth::checkPerm($item, $perm);

	if ((!$authFailed) && ($part->{'Type'} eq 'HTML')) {
	    $authFailed = FAQ::OMatic::Auth::checkPerm($item, 'PermUseHTML');
	}

	my @rcvFields = ('_HideAttributions', '_Type', '_insertpart');
	my $fn;
	if ($authFailed) {
		# There was a permission problem. Write the user's data to
		# a file, and send them to the authentication page.
		# That way, they can come right back here and submit without
		# having to type their data again, which would bite.
		if ($params->{'s_textInFile'}) {
			# hey, already been here once -- just let the (now "permanent")
			# arguments pass through to authenticate again.
		} else {
			# write the _newText out to a file, instead of passing through
			# as a variable, since we don't trust browsers not to abuse it.
			# And it could make a very big URL.
			for ($fn = FAQ::OMatic::nonce();
				-f "$FAQ::OMatic::Config::metaDir/submitTmp.$fn";
				$fn++) {}	# skip until we find an unused filename
			if (not open(TMPF, ">$FAQ::OMatic::Config::metaDir/submitTmp.$fn")) {
				# shoot -- this trick isn't working! Just send the
				# user through the usual channels, and they'll have to retype.
				FAQ::OMatic::Auth::ensurePerm('-item'=>$item,
					'-operation'=>$perm,
					'-restart'=>'editPart',
					'-cgi'=>$cgi,
					'-failexit'=>1);
			}
			print TMPF $params->{'_newText'};
			close TMPF;
			$params->{'s_textInFile'} = $fn;

			# turn input _transient params into s_notSoTransient args, so
			# they make the round-trip through authenticate. We'll delete
			# them from the params list when we finally succeed.
			my $i;
			foreach $i (@rcvFields) {
				$params->{"s$i"} = $params->{$i};
			}
		}
		# attach all the _params
		my $url = FAQ::OMatic::makeAref('authenticate',
			{'_restart'=>FAQ::OMatic::commandName(), '_reason'=>$authFailed},
			'url');
		FAQ::OMatic::redirect($cgi, $url);
	}

	# check for args coming from an authentication detour, and convert
	# back to the ones we expect
	if ($params->{'s_textInFile'}) {
		$params->{'s_textInFile'} =~ m#([^/]*)#gs;
		$fn = "$FAQ::OMatic::Config::metaDir/submitTmp.".$1;
		if (not open(TMPF, $fn)) {
			# shoot, the save-file has disappeared ... send the user
			# back to editPart, poor slob.
			killS_Params($params);
			my $url = FAQ::OMatic::makeAref('editPart', {},
				'url');
			FAQ::OMatic::redirect($cgi, $url);
		}
		my @lines = <TMPF>;
		close TMPF;
		unlink $fn;
		$params->{'_newText'} = join('', @lines);
		my $i;
		foreach $i (@rcvFields) {
			$params->{$i} = $params->{"s$i"};
		}
		killS_Params($params);	# get rid of these vestigial params
	}

	# Finally, input the arguments we originally expected into the part.
	$part->setProperty('HideAttributions',
		defined $params->{'_HideAttributions'} ? 1 : '');
	# remove extra title info from faqomatic: link
	$params->{'_newText'} =~ s/faqomatic\[[^\[\]]*\]:/faqomatic:/sg;
	if ($part->{'Type'} eq 'directory') {
		if ($params->{'_Type'} ne 'directory') {
			FAQ::OMatic::gripe('error', "Can't change Type from directory.");
		}
		# verify that new and old directory text contain identical set of
		# faqomatic: links
		my @oldLinks = sort($part->getLinks());
		my @newLinks = sort(
			FAQ::OMatic::Part::getLinksFromText($params->{'_newText'}));
			# Perl sucks sometimes. If you leave the parens of the sort()
			# in the previous statement, the secret magical Perl bit
			# 'wantarray' does not get set, and so the return value from
			# getLinks...() gets all globbed into a single scalar, glued
			# together with spaces. Aaaargh! I hate how Perl second-guesses me.

		my $error = 0;
		if (scalar @oldLinks != scalar @newLinks) {
			$error = 1;
		} else {
			my $i;
			for ($i=0; $i<scalar(@oldLinks); $i++) {
				if ($oldLinks[$i] ne $newLinks[$i]) {
					$error = 1;
				}
			}
		}
		if ($error) {
			FAQ::OMatic::gripe('error', "When editing a directory, you "
				."may not alter the set of faqomatic:<i>item</i> links in "
				."directory."
				."<p>".join('',(map {"<br>old: $_\n"} @oldLinks))
				."<p>".join('',(map {"<br>new: $_\n"} @newLinks))
				);
		}

		# the new directory passes the test
		$part->setText($params->{'_newText'});

		# all the children in the list may now have different siblings,
		# which means we need to recompute their dependencies and
		# regenerate their cached html.
		$item->updateAllChildren();
	} else {
		if ($params->{'_Type'} eq 'directory') {
			FAQ::OMatic::gripe('error', "Can't force Type to directory.");
		}
		$part->setText($params->{'_newText'});
		$part->setProperty('Type', $params->{'_Type'} || '');
	}
	$part->touch();	# update modification date

	# in any case, the user has co-authored the document
	my ($id,$aq) = FAQ::OMatic::Auth::getID();
	$part->addAuthor($id) if ($id);
	$item->saveToFile();

	# partnum may be invalid now, if removeSubItem() happened
	if ($removed) {
		$item->notifyModerator($cgi, "removed the directory, making an "
			."answer item from a category item.");
	} elsif ($insertpart) {
		$item->notifyModerator($cgi, 'inserted a part', $partnum+1);
		$item->notifyNotifier($cgi, 'inserted a part', $partnum+1);
	} else {
		$item->notifyModerator($cgi, 'edited a part', $partnum);
		$item->notifyNotifier($cgi, 'edited a part', $partnum);
	}

	if (FAQ::OMatic::getParam($params, 'isapi')) {
		# caller is a program; doesn't want a redirect to an HTML file!
		# provide textual results
		print FAQ::OMatic::header($cgi, '-type'=>'text/plain')
			."isapi=1\n"
			."file=".$item->{'filename'}."\n"
			."checkSequenceNumber=".$item->{'SequenceNumber'}."\n";
		FAQ::OMatic::myExit(0);
	}

	my $url = FAQ::OMatic::makeAref('-command'=>'faq',
				'-params'=>$params,
				'-changedParams'=>{'partnum'=>'', 'checkSequenceNumber'=>''},
				'-refType'=>'url');
		# eliminate things that were in our input form that weren't
		# automatically transient (_ prefix)
	FAQ::OMatic::redirect($cgi, $url);
}

# when auth fails between editPart and submitPart, we call through
# the authenticate script. To keep params from getting lost along the
# way, we convert them from "_param" transient form to "s_param" form,
# which survives makeAref(). This sub kills off those s_* guys once we're
# done with 'em.
sub killS_Params {
	my $params = shift;
	foreach my $i (keys %{$params}) {
		next if (not $i =~ m/^s_/);
		delete $params->{$i};
	}
}

1;
