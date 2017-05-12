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
### FAQ::OMatic::Groups manages group membership, so you can control postings
### more finely than {moderator-only or anyone-with-an-email-address}.
###

package FAQ::OMatic::Groups;

use FAQ::OMatic;
use FAQ::OMatic::I18N;

sub readGroups {
	# groups are cached per CGI invocation so we don't have to read
	# the groups file from the filesystem multiple times.
	# We store the cache in the s/getLocal() mechanism so that it
	# doesn't persist across invocations on a mod_perl child.
	my $groupCache = FAQ::OMatic::getLocal('groupCache');
	return $groupCache if (defined $groupCache);

	if (not open GROUPS, "$FAQ::OMatic::Config::metaDir/groups") {
		$groupCache = {};
	} else {
		while (defined($_=<GROUPS>)) {
			chomp;
			my ($groupName, $member) = split('\s', $_, 2);
			$groupCache->{$groupName}{$member} = 1;
		}
		close GROUPS;
	}

	# Make sure the one special group ('Administrators') always appears,
	# even if it has no members. By deleting, we avoid disturbing any
	# loaded hash, but ensures Perl creates a hash for this group.
	delete $groupCache->{'Administrators'}{''};

	FAQ::OMatic::setLocal('groupCache', $groupCache);
	return $groupCache;
}

sub writeGroups {
	my $groups = shift;
	my $groupCache = readGroups();
	$groupCache = $groups if (defined $groups);	# allow caller to overwrite

	if (not open GROUPS, ">$FAQ::OMatic::Config::metaDir/groups") {
		FAQ::OMatic::gripe('abort',
			"Can't write to $FAQ::OMatic::Config::metaDir/groups: $!.");
	}
	my ($groupName, $member);
	foreach $groupName (sort keys %{$groupCache}) {
		foreach $member (sort keys %{$groupCache->{$groupName}}) {
			print GROUPS "$groupName $member\n";
		}
	}
	close GROUPS;
}

sub getGroupNameList {
	my $groupCache = readGroups();
	return sort keys %{$groupCache};
}

sub groupCodeToName {
	my $code = shift;
	$code =~ s/^6 //;
	return $code;	# boy, that was easy.
}

sub groupNameToCode {
	my $code = shift;
	return "6 ".$code;
}

sub getGroupCodeList {
	readGroups();
	return map {groupNameToCode($_)} getGroupNameList();
}

sub checkMembership {
	my $code = shift;
	my $id = shift;

	my $groupCache = readGroups();
	return 1 if ($id eq $FAQ::OMatic::Config::adminAuth);

	readGroups();

	# By checking for the existence of the group first, we avoid
	# "creating" that group in the in-core cache as a side effect of
	# looking in its hash for $id.
	return 0 if (not $groupCache->{groupCodeToName($code)});

	# check for a direct user match:
	return 1 if ($groupCache->{groupCodeToName($code)}{$id});

	# check if any domains match a suffix of user's id:
	my @members = keys %{$groupCache->{groupCodeToName($code)}};
	my @domains = grep {not FAQ::OMatic::validEmail($_)} @members;
	my $domain;
	foreach $domain (@domains) {
		return 1 if ($id =~ m/$domain$/);
	}

	return 0;
}

sub displayHTML {
	my $group = shift;
	my $html = '';

	my $groupCache = readGroups();

	if (not $group) {
		$html.=gettext("Select a group to edit:")."<dl>\n";
		my ($groupName,$member);
		foreach $groupName (getGroupNameList()) {
			$html.="<dt>"
				.FAQ::OMatic::makeAref('editGroups', {'group'=>$groupName})
				."$groupName</a>\n";
			if ($groupName eq 'Administrators') {
				$html.="<dd><i>"
					.gettext("(Members of this group are allowed to access these group definition pages.)")
					."</i>\n";
			}
			my $limit=4;
			foreach $member
				(sort {sortEmail($a,$b)} keys %{$groupCache->{$groupName}}) {

				$html.="<dd>$member\n";
				if (--$limit <= 0) {
					$html.="<dd>...\n";
					last;
				}
			}
		}
		$html.="</dl>\n";
		$html.=FAQ::OMatic::makeAref('editGroups', {'group'=>''}, 'GET')
			."<input type=text size=30 name=\"group\">\n"
			."<input type=submit name=\"_junk\" value=\""
			.gettext("Add Group")
			."\">\n"
			."</form>\n";
	} else {
		validGroupName($group);
		$html.="<p>".FAQ::OMatic::button(
			FAQ::OMatic::makeAref('editGroups', {'group'=>''}),
			gettext("Up To List Of Groups"));

		$html.="<table>\n"
			."<tr><td></td><td><b>$group</b></td></tr>\n";
		my $member;
		foreach $member
			(sort {sortEmail($a,$b)} keys %{$groupCache->{$group}}) {

			$html.="<tr><td align=right>\n"
				.FAQ::OMatic::button(
					FAQ::OMatic::makeAref('submitGroup',
						{'_action'=>'remove', '_member'=>$member}),
					gettext("Remove Member"))
				."</td><td>"
				."$member\n"
				."</td></tr>\n";
		}
		$html.="<form><tr><td align=right valign=bottom>"
				.FAQ::OMatic::makeAref('submitGroup',
					{'_action'=>'add'}, 'GET')
				."<input type=submit name=\"_junk\" value=\""
				.gettext("Add Member")
				."\">\n"
				."</td><td valign=bottom>\n"
				."<input type=text size=50 name=\"_member\">\n"
				."</td></tr></form>\n";
		$html.="</table>\n";
	}

	$html.="<p>".FAQ::OMatic::button(
			FAQ::OMatic::makeAref('faq', {'group'=>''}),
			gettext("Go to the Faq-O-Matic"));
	$html.=" ".FAQ::OMatic::button(
			FAQ::OMatic::makeAref('install', {'group'=>''}),
			gettext("Go To Install/Configuration Page"));
	$html.="\n";

	return $html;
}

sub addMember {
	my $group = shift;
	my $member = shift;

	my $groupCache = readGroups();
	$groupCache->{$group}{$member} = 1;
	writeGroups();
}

sub removeMember {
	my $group = shift;
	my $member = shift;

	my $groupCache = readGroups();
	delete $groupCache->{$group}{$member};
	writeGroups();
}

sub validGroupName {
	my $group = shift;

	if (not $group =~ m/^[\w.-]+$/) {
		FAQ::OMatic::gripe('error',
			"Group names may only contain alphanumerics, "
			."periods, and hyphens.");
	}
}

sub sortEmail {
	my $a = shift;
	my $b = shift;
	my ($auser,$adomain,$buser,$bdomain);

	if ($a =~ m'@') {
		($auser,$adomain) = split('@', $a);
	} else {
		($auser,$adomain) = ('', $a);
	}
	if ($b =~ m'@') {
		($buser,$bdomain) = split('@', $b);
	} else {
		($buser,$bdomain) = ('', $b);
	}
	
	return ($adomain cmp $bdomain) || ($auser cmp $buser);
}

1;
