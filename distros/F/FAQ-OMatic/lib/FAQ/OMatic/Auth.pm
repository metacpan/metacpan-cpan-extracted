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
### The FaqAuth module provides identification, authentication,
### and authorization services for the Faq-O-Matic.
###
### Custom authentication schemes should
### be implemented by using the hooks in this module. (For
### now there are no hooks, but in theory there should be one
### replaceable function.) You'd rather not modify this file,
### so you can be drop-in compatible with future faqomatic
### releases.
###

package FAQ::OMatic::Auth;

use FAQ::OMatic;
use FAQ::OMatic::Item;
use FAQ::OMatic::AuthLocal;
use FAQ::OMatic::Groups;
use FAQ::OMatic::I18N;
use FAQ::OMatic::Entropy;
use Digest::MD5 qw(md5_hex);

# a global constant (accessible outside using my namespace)
use vars qw($cookieExtra);	# constant, visible to maintenance.pm

my $trustedID = undef;
						# Perm values only:
						# '7','9' -- returned by perm routines to indicate
						#		authQuality must be 5, and user must be the
						#		moderator of the item.
						# '6' -- a perm that indicates a group membership
						#		requirement. (actually "6 group_name".)
						# $authQuality's and Perm* values:
						# '5' -- user has provided proof that ID is correct
						# '3' -- user has merely claimed this ID
						# '1' -- no ID is offered

$cookieExtra = 600;		# 10 extra minutes to submit forms after filling
						# them out so you don't have to worry about
						# losing your text.

sub getID {
	my $params = FAQ::OMatic::getParams();	# get cached params

	my $trustedID = FAQ::OMatic::getLocal('trustedID');
	my $authQuality = FAQ::OMatic::getLocal('authQuality');
	if (not defined $trustedID) {
		if (defined $params->{'auth'}) {
			# use a user-overridable auth function
			($trustedID,$authQuality) = authenticate($params);
		} elsif (defined $params->{'id'}) {
			# id without authorization
			$trustedID = $params->{'id'};
			$authQuality = 3;
		} else {
			# no authorization offered
			$trustedID = 'anonymous';
			$authQuality = 1;
		}
	}

	FAQ::OMatic::setLocal('trustedID', $trustedID);
	FAQ::OMatic::setLocal('authQuality', $authQuality);
	return ($trustedID,$authQuality);
}

# result is 'false' if user CAN edit the part, else an error message
sub checkPerm {
	my $item = shift;
	my $operation = shift;

	my ($id,$aq) = getID();

	my $whocan = getInheritedProperty($item, $operation);

	# if just some low quality of authentication is required, prove
	# user has provided it:
	$whocan =~ m/^(\d+)/;
	my $whocanNum = $1 || 7;
		# THANKS to Mikel Smith <granola@maserith.com>
		# for pointing out that this code was generating warning messages
	if ($whocanNum <= 5 and $whocanNum <= $aq) {
		# users' ID dominates required ID
		return 0;
	}

	# prove user belongs to required group:
	if ($whocanNum == 6
		and FAQ::OMatic::Groups::checkMembership($whocan, $id)) {
		# user belongs to the specified group
		return 0;
	}

	# prove user has at least moderator priveleges
	if ((($whocanNum==7) and ($aq==5))
		and (($id eq getInheritedProperty($item, 'Moderator'))
			 or ($id eq $FAQ::OMatic::Config::adminAuth)
			 or ('anybody' eq getInheritedProperty($item, 'Moderator'))
			)
		) {
		# user has proven authentication, and is the moderator of the item
		return 0;
	}

	return $whocan;
}

sub getInheritedProperty {
	my $item = shift;
	my $property = shift;
	my $depth = shift || 0;

	if (isPropertyGlobal($property)) {
		# save a recursive walk up the tree -- this property
		# is defined at the top.
		# THANKS to John Goerzen <jgoerzen@complete.org> for
		# finding a dumb bug here.
		$item = new FAQ::OMatic::Item('1');
	}
	if (not ref $item) {
		# get property from top item if no item specified
		$item = new FAQ::OMatic::Item('1');
	}

	if (defined($item) and defined $item->{$property}) {
		return wantarray()
			? ($item->{$property}, $item)
			: $item->{$property};
	}

	if (not defined($item)
		or ($item eq '')
		or ($item->getParent() eq $item)
		or ($depth > 80)) {

		# no-one defines it, all the way up the chain
		return wantarray()
			? (getDefaultProperty($property), undef)
			: getDefaultProperty($property);
	} else {
		return getInheritedProperty($item->getParent(), $property, $depth+1);
	}
}

# fields: [ default value, isGlobal ]
my %defaultProperties = (
	'Moderator' => 			[ 'nobody', 0 ],
	'MailModerator' => 		[ 0, 0 ],
       	'Notifier' =>			[ 'nobody', 0 ],
	'MailNotifier' =>		[ 0, 0 ],
	'PermEditPart' =>		[ 5, 0 ],		# users with proven authentication
	'PermAddPart' =>		[ 5, 0 ],
	'PermAddItem' =>		[ 5, 0 ],
#	'PermEditItem' =>		[ 5, 0 ],		# (deprecated)
	'PermEditTitle' =>		[ 5, 0 ],		# moderator
	'PermEditDirectory' =>	[ 7, 0 ],
	'PermModOptions' =>		[ 7, 0 ],
	'PermUseHTML' =>		[ 7, 0 ],
	'PermNewBag' =>			[ 7, 1 ],
	'PermReplaceBag' =>		[ 7, 1 ],
	'PermInstall' =>		[ 7, 1 ],
	'PermEditGroups' =>		[ 7, 1 ],
	'RelaxChildPerms' =>	[ 'norelax', 0],
);

sub getDefaultProperty {
	my $property = shift;

	my $result = $defaultProperties{$property};
	if (not defined $result) {
		$result = 7;
		FAQ::OMatic::gripe('panic',
			"Property $property expected but not defined");	# tell author
	}
	return $result->[0];
}

sub isPropertyGlobal {
	my $property = shift;

	my $result = $defaultProperties{$property};
	return $result->[1] || 0;
}

# ensurePerm()
# Checks permissions, returns '' if okay, else returns a redirect to
# authenticate.
# In list context, returns the same value followed by a quality
# value, so if you require two ensurePerms, you return the redirect
# with the higher qualityf value (so the user gets all the authentication
# done at once). See submitMove.
sub ensurePerm {
	my @p = @_;

	my (
		$item,
		$operation,
		$restart,			# which program to run to restart operation
							# after user presents ID
		$cgi,
		$extraTime,			# allow slightly stale cookies, so that a
							# cookie isn't likely to time out between
							# clicking "edit" and "submit", which annoys.
		$xreason,			# an extra reason, needed to distinguish
							# two cases (modOptions) in editItem.
		$failexit			# redirect and exit on failure
	) = FAQ::OMatic::rearrange(
		['item','operation','restart','cgi','extraTime','xreason',
			'failexit'],
		@p);
	$item ||= '';

	my $result = '';

	my $cookieActual = $FAQ::OMatic::Config::cookieLife || 3600;
	$cookieActual += $cookieExtra if ($extraTime);
	FAQ::OMatic::setLocal('cookieActual', $cookieActual);

	my $authFailed = checkPerm($item,$operation);

	if ($authFailed) {
		my $url = FAQ::OMatic::makeAref('authenticate',
			{'_restart' => $restart, '_reason'=>$authFailed,
			 '_xreason'=>($xreason||'')}, 'url', 'saveTransients');
		$result = FAQ::OMatic::redirect($cgi, $url, 'asString');
		if ($failexit||'') {
			FAQ::OMatic::redirect($cgi, $result);
		}
	}

	return wantarray	? ($result, $authFailed)
						: $result;
}

sub newCookie {
	my $id = shift;

	# Use an existing cookie if available. (why is this good? Just
	# to keep the cookies file slimmer?)
	my ($cookie,$cid,$ctime);
	($cookie,$cid,$ctime) = findCookie($id,'id');
	return $cookie if (defined $cookie);

	$cookie = "ck".FAQ::OMatic::Entropy::gatherRandomString();

	my $cookiesFile = "$FAQ::OMatic::Config::metaDir/cookies";
	open COOKIEFILE, ">>$cookiesFile";
	print COOKIEFILE "$cookie $id ".time()."\n";
	close COOKIEFILE;
	if (not chmod(0600, "$cookiesFile")) {
		FAQ::OMatic::gripe('problem', "chmod failed on $cookiesFile");
	}

	return $cookie;
}

sub findCookie {
	my $match = shift;
	my $by = shift;

	my ($cookie,$cid,$ctime);
	if (not open COOKIEFILE, "<$FAQ::OMatic::Config::metaDir/cookies") {
		return undef;
	}
	while (defined($_=<COOKIEFILE>)) {
		chomp;
		($cookie,$cid,$ctime) = split(' ');

		# ignore dead cookies
		my $cookieActual = FAQ::OMatic::getLocal('cookieActual')
				|| $FAQ::OMatic::Config::cookieLife
				|| 3600;
		next if ((time() - $ctime) > $cookieActual);

		if (($by eq 'id') and ($cid eq $match)) {
			close COOKIEFILE;
			return ($cookie,$cid,$ctime);
		}
		if (($by eq 'cookie') and ($cookie eq $match)) {
			close COOKIEFILE;
			return ($cookie,$cid,$ctime);
		}
	}
	close COOKIEFILE;
	return undef;
}

# these functions manipulate a file that maps IDs to
# (ID,password,...) tuples. (... = future expansion)
# Right now it's a flat file, but maybe someday it should be a
# dbm file if anyone ever has zillions of authorized posters.

# given an ($id,$password,...) array, writes it into idfile
sub writeIDfile {
	my ($id,$password,@rest) = @_;

	my $lockf = FAQ::OMatic::lockFile("idfile");
	FAQ::OMatic::gripe('error', "idfile is locked.") if (not $lockf);

	if (not open(IDFILE, "<$FAQ::OMatic::Config::metaDir/idfile")) {
		FAQ::OMatic::unlockFile($lockf);
		FAQ::OMatic::gripe('abort', "FAQ::OMatic::Auth::writeIDfile: Couldn't "
				."read $FAQ::OMatic::Config::metaDir/idfile because $!");
		return;
	}

	# read id mappings in
	my %idmap;
	my ($idf,$passf,@restf);
	while (defined($_=<IDFILE>)) {
		chomp;
		($idf,$passf,@restf) = split(' ');
		$idmap{$idf} = $_;
	}
	close IDFILE;

	# change the mapping for id
	$idmap{$id} = join(' ', $id, $password, @rest);
	
	# write id mappings.
	if (not open(IDFILE, ">$FAQ::OMatic::Config::metaDir/idfile-new")) {
		FAQ::OMatic::unlockFile($lockf);
		FAQ::OMatic::gripe('abort', "FAQ::OMatic::Auth::writeIDfile: Couldn't "
				."write $FAQ::OMatic::Config::metaDir/idfile-new because $!");
		return;
	}

	foreach $idf (sort keys %idmap) {
		print IDFILE $idmap{$idf}."\n";
	}
	close IDFILE;

	unlink("$FAQ::OMatic::Config::metaDir/idfile") or
		FAQ::OMatic::gripe('abort', "FAQ::OMatic::Auth::writeIDfile: Couldn't "
				."unlink $FAQ::OMatic::Config::metaDir/idfile because $!");
	rename("$FAQ::OMatic::Config::metaDir/idfile-new", "$FAQ::OMatic::Config::metaDir/idfile") or
		FAQ::OMatic::gripe('abort', "FAQ::OMatic::Auth::writeIDfile: Couldn't "
				."rename $FAQ::OMatic::Config::metaDir/idfile-new to idfile because $!");
	chmod 0600, "$FAQ::OMatic::Config::metaDir/idfile" or
		FAQ::OMatic::gripe('problem', "FAQ::OMatic::Auth::writeIDfile: Couldn't "
				."chmod $FAQ::OMatic::Config::metaDir/idfile because $!");
	
	FAQ::OMatic::unlockFile($lockf);
}

# given an id, returns an array starting ($id,$password,...)
sub readIDfile {
	my $id = shift || '';	# key to lookup on
	my $dontHideVersion = shift || '';
						# keep regular lookups from seeing version number
						# record. (smacks of a hack, but this is Perl!)

	return undef if (($id eq 'version') and (not $dontHideVersion));

	my $lockf = FAQ::OMatic::lockFile("idfile");
	FAQ::OMatic::gripe('error', "idfile is locked.") if (not $lockf);

	if (not open(IDFILE, "<$FAQ::OMatic::Config::metaDir/idfile")) {
		FAQ::OMatic::unlockFile($lockf);
		FAQ::OMatic::gripe('abort', "FAQ::OMatic::Auth::readIDfile: Couldn't "
				."read $FAQ::OMatic::Config::metaDir/idfile because $!");
		return undef;
	}

	my ($idf,$passf,@restf);
	while (defined($_=<IDFILE>)) {
		chomp;
		($idf,$passf,@restf) = split(' ');
		last if ($idf eq $id);
	}
	close IDFILE;

	FAQ::OMatic::unlockFile($lockf);

	if (defined($idf) and ($idf eq $id)) {
		return ($idf,$passf,@restf);
	}

	return undef;
}

sub checkCryptPass {
	my ($cleartext, $crypted) = @_;
	if ($crypted =~ m/md5\((\S+),(\S+)\)/) {
		# if this record was encoded with the new md5 encoding, then
		# it'll contain a big salt and then the result:
		my $salt = $1;
		my $cryptedResult = $2;
		my $attemptedCrypt = md5_hex($salt, $cleartext);
		return ($attemptedCrypt eq $cryptedResult);
	} else {
		# compatibility mode: use crypt()
		# We no longer generate passwords with crypt, but we
		# allow checking against crypt()ed passwords to avoid
		# annoying users with a password-reset demand.
		#my $salt = substr($crypted, 0, 2);
		# specific fix from Evan Torrie <torrie@pi.pair.com>: most crypt()s
		# don't care of there's excess salt, and those with MD5 crypts use
		# more than the first two bytes as salt.
		my $salt = $crypted;
		return (crypt($cleartext, $salt) eq $crypted);
	}
}

sub cryptPass {
	my $pass = shift;
	my $salt = FAQ::OMatic::Entropy::gatherRandomString();
	return "md5(".$salt.",".md5_hex($salt.$pass).")";
}

sub authenticate {
	my $params = shift;

	my $auth = $params->{'auth'};

	# if there's a cookie...
	if ($auth =~ m/^ck/) {
		my ($cookie,$cid,$ctime) = findCookie($auth,'cookie');
		# and it's good, then return the implied id
		return ($cid,5) if (defined $cid);
		# if it's bad, fall through and inherit anonymous auth
	}

	# if we authenticate...
	if (($params->{'auth'}||'') eq 'pass' or
		((($params->{'_none_id'}||'') eq '')
			and (($params->{'_pass_id'}||'') ne ''))) {
		my $id = $params->{'_pass_id'};
		my $pass = $params->{'_pass_pass'};
		if (FAQ::OMatic::AuthLocal::checkPassword($id, $pass)) {
			# set up a cookie to use for a shortcut later,
			# and return the authentication pair
			$params->{'auth'} = newCookie($id);
			return ($id,5);
		} else {
			# let authenticate know to report the bad password
			$params->{'badPass'} = 1;
			# remove the password from the parameters, since
			# we don't want it ending up in a later GET request
			# (and then in server logs). (It got here by a POST
			# from the password form.)
			$params->{'_pass_id'} = '';
			$params->{'_pass_pass'} = '';
			# fall through to inherit some crummier Authentication Quality
		}
	}

	if (($params->{'auth'} eq 'none')
		and (defined $params->{'_none_id'})) {
		# move id where we can pass it around
		$params->{'id'} = $params->{'_none_id'};
	}

	# default authentication: whatever id we can come up with,
	# but quality is at most 3
	my $id = $params->{'id'} || 'anonymous';
	my $aq = $params->{'id'} ? 3 : 1;
	return ($id, $aq);
}

sub authError {
	my $reason = shift;
	my $file = shift;

	my %staticErrors = (
		9 => gettext("the administrator of this Faq-O-Matic"),
		5 => gettext("someone who has proven their identification"),
		3 => gettext("someone who has offered identification"),
		1 => gettext("anybody") );

	return $staticErrors{$reason} if ($staticErrors{$reason});

	if ($reason eq '7') {
		my $modname = '';
		if (defined($file)
			&& ($file ne '')) {
			# THANKS "Alan J. Flavell" <flavell@a5.ph.gla.ac.uk>
			# for fixing a "Use of uninitialized value" here.
			my $item = new FAQ::OMatic::Item($file);
			$modname = " (".getInheritedProperty($item, 'Moderator').")";
		}
		return gettext("the moderator of the item").$modname;
	}

	if ($reason =~ m/^6/) {
		return gettexta("%0 group members",FAQ::OMatic::Groups::groupCodeToName($reason));
	}

	return "I don't know who";
}

1;

