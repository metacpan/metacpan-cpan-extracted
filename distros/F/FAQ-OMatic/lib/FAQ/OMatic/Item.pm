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
### A FAQ::OMatic::Item is a data structure that contains an entire item
### from the FAQ. (One file.)
###

package FAQ::OMatic::Item;

use FAQ::OMatic::Part;
use FAQ::OMatic;
use FAQ::OMatic::Auth;
use FAQ::OMatic::Appearance;
use FAQ::OMatic::Groups;
use FAQ::OMatic::Words;
use FAQ::OMatic::HelpMod;
use FAQ::OMatic::Versions;
use FAQ::OMatic::Set;
use FAQ::OMatic::I18N;

BEGIN {
#   This code use Japanese environment only.
#   see http://chasen.aist-nara.ac.jp/index.html.en
#
    if (FAQ::OMatic::I18N::language() eq 'ja_JP.EUC') {
	require NKF; import NKF;
    }
}

my @monthMap;			# a constant array, no cache problem for mod_perl

sub new {
	my ($class) = shift;
	my ($arg) = shift;	# what file the item data lives in
	my ($dir) = shift;	# what dir we should look in for the item data
						# (default $FAQ::OMatic::Config::itemDir)
	my $item = {};
	bless $item;

	# if we have the item loaded already, use the in-core copy!
	my $itemCache = FAQ::OMatic::getLocal('itemCache');
	if ($arg and (defined $itemCache->{$arg})) {
		return $itemCache->{$arg};
	}

	$item->{'class'} = $class;
	$item->{'Parts'} = [];

	if ($arg) {
		$item->loadFromFile($arg,$dir);
		if ($item->{'filename'}) {
			$itemCache->{$item->{'filename'}} = $item;
			FAQ::OMatic::setLocal('itemCache', $itemCache);
		}
	} else {
		$item->setProperty('Title', gettext("New Item"));
	}

	# ensure every item has a sequence number.
	# sequence numbers are used to:
	# 1. detect conflicting edits. We discard the later submission;
	# no attempt is made to prevent simultaneous edits in the first place.
	# The assumption is that simultaneous edits are uncommon, and stale
	# locks would probably be less convenient than occasional conflicts.
	# 2. incremental transfers for mirrored faqs
	$item->{'SequenceNumber'} = 0 if (not defined($item->{'SequenceNumber'}));

	return $item;
}

# used for emptying trash.
sub destroyItem {
	my $self = shift;
	my $deferUpdate = shift || '';
	# only works for things in Config::itemDir

	my $filename = $self->{'filename'};

	# remove item from internal cache so we don't try to re-save it out.
	my $itemCache = FAQ::OMatic::getLocal('itemCache');
	delete $itemCache->{$filename};

	# detach the item from its parent
	my $parent = $self->getParent();
	$parent->removeSubItem($filename, $deferUpdate);

	# TODO note that we don't do anything about symlinks (faqomatic: refs)
	# to this missing item; they'll become "missing or broken item". We
	# should probably handle that issue during the "Move to trash" operation,
	# since you don't really want symlinks into the trash, anyway.
	# TODO note that the file simply disappears, so if we lose the
	# biggestFileHint, we might accidentally reallocate this file number.
	# That's not horrible, but perhaps worth avoiding.
	# TODO I don't delete the RCS file, because disk space is free.
	# I'm emptying the trash just to reduce the amount of cruft that piles
	# up in user-visible space! If someone really cares, they could delete
	# the RCS file, too. (On the other hand, one might worry about
	# disk space for bag deletion.)
	destroyItemRaw($self->{'filename'});
}

sub destroyItemRaw {
	my $filename = shift;

	# zero file on disk
	# we leave a stub there so that new files won't be created with the
	# same file name. That keeps links by filename from changing their
	# destination.
	my $dir = $FAQ::OMatic::Config::itemDir || '';
#my $inode = `ls -i $dir/$filename`;
	my $rc = open(FILE, ">$dir/$filename");
	close FILE;
	if (not $rc or ((-s "$dir/$filename") != 0)) {
		FAQ::OMatic::gripe('problem', "Bummer: failed to zero $filename\n");
		return 0;
	}
	# TODO need to commit to RCS, get & release Item lock.
	return 1;
}

sub loadFromFile {
	my $self = shift;
	my $filename = shift;
	my $dir = shift || '';		# optional -- almost always itemDir

	# untaint user input (so they can't express
	# a file of ../../../../../../etc/passwd)
	if (not $filename =~ m/^([\w\-.]*)$/) {
		# if taint check fails, just return a bad item, rather
		# than implying that there really is an item with the funny name
		# supplied.
		
		delete $self->{'Title'};
		return;
	} else {
		$filename = $1;
	}

	if (not $dir) {
		$dir = $FAQ::OMatic::Config::itemDir || '';
	}

	if (not -f "$dir/$filename") {
		if ($dir eq ($FAQ::OMatic::Config::itemDir||'x')
			and FAQ::OMatic::Versions::getVersion('Items')) {
			# admin only cares much if an item turns up missing,
			# and then only if he's actually gotten the FAQ installed.
			FAQ::OMatic::gripe('note',
				"FAQ::OMatic::Item::loadFromFile: $filename isn't a regular "
				."file (-f test failed).");
		}
		delete $self->{'Title'};
		return;
	}

	if ((-s "$dir/$filename") == 0) {
		delete $self->{'Title'};
		$self->{'EmptyStub'} = 'true';
		return;
	}

	if (not open(FILE, "$dir/$filename")) {
		FAQ::OMatic::gripe('note',
			"FAQ::OMatic::Item::loadFromFile couldn't open $filename.");
		delete $self->{'Title'};
		return;
	}

	# take note of which file we came from
	$self->{'filename'} = $filename;

	$self->loadFromFileHandle(\*FILE, $filename);

	close(FILE);

	return $self;
}

sub loadFromFileHandle {
	my $self = shift;
	my $fh = shift;
	my $debugFilename = shift;

	return loadFromCodeClosure($self,
		sub {
			return <$fh>;	# read one line
		},
		$debugFilename);
}

sub loadFromString {
	my $self = shift;
	my $string = shift;
	my $debugFilename = shift;

	my @lines = split("\n", $string);
	splice(@lines, scalar(@lines)-1);	# hack off last empty string

	return loadFromCodeClosure($self,
		sub {
			# read one line
			my $line = shift(@lines);
			$line .= "\n" if (defined $line);
			return $line;
		},
		$debugFilename);
}

sub loadFromCodeClosure {
	my $self = shift;
	my $closure = shift;	# a sub that returns one line of the file
	my $debugFilename = shift || 'an item read from a filehandle';

	# process item headers
	# THANKS to "John R. Jackson" <jrj@gandalf.cc.purdue.edu> for
	# grepping for unprotected while constructs.
	while (defined($_ = &{$closure})) {
		chomp;
		my ($key,$value) = FAQ::OMatic::keyValue($_);
		if ($key eq 'Part') {
			my $newPart = new FAQ::OMatic::Part;
			$newPart->loadFromCodeClosure($closure, $self->{'filename'}, $self,
					scalar @{$self->{'Parts'}});	# partnum
			push @{$self->{'Parts'}}, $newPart;
		} elsif ($key eq 'LastModified') {
			# LEGACY: Transparently update older items with LastModified keys
			# to use new LastModifiedSecs key.
			my $secs = compactDateToSecs($value);	# turn back into seconds
			$self->{'LastModifiedSecs'} = $secs;
		} elsif ($key eq 'PermEditItem') {
			# Replace this old permission descriptor with the new ones
			$self->{'PermEditTitle'} = $value;
			$self->{'PermEditDirectory'} = $value;
			$self->{'PermAddItem'} = $value;
		} elsif ($key =~ m/-Set$/) {
			if (not defined($self->{$key})) {
				$self->{$key} = new FAQ::OMatic::Set;
			}
			$self->{$key}->insert($value);
		} elsif ($key ne '') {
			$self->setProperty($key, $value);
		} else {
			FAQ::OMatic::gripe('problem',
				"FAQ::OMatic::Item::loadFromCodeClosure was confused by this "
				."header in $debugFilename: \"$_\"");
			# this marks the item "broken" so that the save routine will
			# refuse to save this corrupted file out and lose more data.
			delete $self->{'Title'};
			return;
		}
	}

	# We just loaded this item from a file; the title hasn't really
	# changed. So we unset that property (that was set when we read
	# the 'Title:' header), so that we can detect when an item's title
	# actually does change.
	$self->setProperty('titleChanged', '');

	return $self;
}

sub numParts {
	my $self = shift;
	return scalar @{$self->{'Parts'}};
}

sub getPart {
	my $self = shift;
	my $num = shift;

	return $self->{'Parts'}->[FAQ::OMatic::stripInt($num)];
}

@monthMap =( 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
				'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' );

# a human-readable date/time format. Currently used for the
# last-modified field.
sub compactDate {
	my ($forsecs) = shift;	# optional; default is now
	$forsecs = time() if (not $forsecs);
	my ($sec,$min,$hr,$day,$mo,$yr,$wday,$yday,$isdst) = localtime($forsecs);

	my $df = $FAQ::OMatic::Config::dateFormat||'';
	my $time;
	if ($df eq '24') {
		# THANKS: to Jan Ornstedt for suggesting 24-hour "European" dates
		$time = sprintf("%02d:%02d%s", $hr, $min);
	} else {
		my $ampm = "am";
		if ($hr >= 12) {
			$hr -= 12;
			$ampm = "pm";
		}
		$hr = 12 if ($hr == 0);
		$time = sprintf("%2d:%02d%s", $hr, $min, $ampm);
	}

	return sprintf("%04d-%03s-%02d %s",
			$yr+1900, $monthMap[$mo], $day, $time);
}

# undo the previous transformation
# TODO: this is only used (I think) for updating LastModified: fields
# TODO: to LastModifiedSecs: fields. It could eventually be discarded.
sub compactDateToSecs {
	my $cd = shift;
	my ($yr,$mo,$dy,$hr,$mn,$ampm) =
		($cd =~ m/(\d+)-([a-z]+)-(\d+) +(\d+):(\d+)([ap])m/i);
	if (not defined $ampm) {
		return -1;		# can't parse string
	}
	my $month_i;
	for ($month_i=0; $month_i<12; $month_i++) {
		if ($mo eq $monthMap[$month_i]) {
			$mo = $month_i;		# notice months run 0..11
			last;
		}
	}
	if ($month_i == 12) {
		return -1;				# can't parse month
	}
	$hr = 0 if ($hr == 12);		# noon/midnight
	$hr += 12 if ($ampm eq 'p');	# am/pm
	$yr -= 1900;	 			# year is biased in struct

	require Time::Local;
	# LastModified: keys were represented in local time, not GMT.
	return Time::Local::timelocal(0, $mn, $hr, $dy, $mo, $yr);
}

sub saveToFile {
	my $self = shift;
	my $filename = shift || '';
	my $dir = shift || '';			# optional -- almost always itemDir
	my $lastModified = shift || '';	# optional -- normally today.
									# 'noChange' is allowed; used when
									# regenerating files (mod date hasn't
									# really changed.).
	my $updateAllDependencies = shift || '';	# optional. specified
						# by maintenance when regenerating all dependencies.
	my $noRecomputeDependencies = shift || '';	# optional, used by
						# mirrorClient to prevent trying to follow
						# forward references.

# TODO: I don't think maintenance.pm really needs to actually write the
# TODO: item files when regenerating dependencies/HTML cache files.
# TODO: If not, that part of saveToFile should be factored out, so we're
# TODO: not really writing out item/ files.

	$dir = $FAQ::OMatic::Config::itemDir if (not $dir);

	$filename =~ m/([\w\-.]*)/;	# Untaint filename
	$filename = $1;

	if (not $filename) {
		$filename = $self->{'filename'};
	} else {
		# change of filename (from a new, anonymous item)
		$self->{'filename'} = $filename;
	}

	if ($self->isBroken()) {
		FAQ::OMatic::gripe('error',
			"Tried to save a broken item to ".(defined($filename)?$filename:"<undef-filename>")."<p>".FAQ::OMatic::stackTrace());
	}

	if ($dir eq $FAQ::OMatic::Config::itemDir
		and not $noRecomputeDependencies) {
		# compute new IDependOn-Set -- the items whose titles we depend
		# on.
		# copy old list first, so we have something to compare new list to
		$self->{'oldIDependOn-Set'} =
			$self->getSet('IDependOn-Set')->clone();
		my $newSet = new FAQ::OMatic::Set;
		# I depend on any item I link to, which includes any explicit
		# (faqomatic:...) links in the text, ...
		my $parti;
		for ($parti=0; $parti<$self->numParts(); $parti++) {
			my $part = $self->getPart($parti);
			$newSet->insert($part->getLinks());
		}
		# ...and any implicit links to my ancestors or to siblings
		my ($parentTitles,$parentNames) = $self->getParentChain();
		$newSet->insert(@{$parentNames});
		$newSet->insert(grep {defined($_)} $self->getSiblings());
		# ...and any bags.
		$newSet->insert(map { "bags.".$_ } $self->getBags());

		$self->{'IDependOn-Set'} = $newSet;
	}

	# note last modified date in item itself
	if ($lastModified ne 'noChange') {
		# Time now stored in file in Unix-style seconds.
		# (but as an ASCII integer, which isn't 31-bit limited,
		# so I'm sure you'll be pleased to note that we're
		# Y2.038K-compliant. :v)
		$lastModified = time() if ($lastModified eq '');
		$self->{'LastModifiedSecs'} = $lastModified;
		# $self->{'LastModified'} = compactDate($lastModified);
	}

	my $lock = FAQ::OMatic::lockFile("$filename");
	return if not $lock;

	if (not open(FILE, ">$dir/$filename")) {
		FAQ::OMatic::gripe('problem',
			"saveToFile: Couldn't write to $dir/$filename because $!");
		FAQ::OMatic::unlockFile($lock);
		return;
	}
	my $key;
	foreach $key (sort keys %{$self}) {
		if (($key =~ m/^[a-z]/) or ($key eq 'Parts')) {
			next;
			# some keys don't get explicitly written out.
			# These include lowercase keys (e.g. class, filename),
			# and the Parts key, which we write explicitly later.
		} elsif ($key =~ m/-Set$/) {
			my $a;
			foreach $a ($self->getSet($key)->getList()) {
			        if (FAQ::OMatic::I18N::language() eq 'ja_JP.EUC') {
				# Japanese only
			                $a = nkf('-e', $a);
				}
				print FILE "$key: $a\n";
			}
		} else {
			my $value = $self->{$key};
			$value =~ s/[\n\r]/ /g;	# don't allow CRs in a single-line field,
									# that would corrupt the file format.
                        if (FAQ::OMatic::I18N::language() eq 'ja_JP.EUC') {
			# Japanese only
			        $value = nkf('-e', $value);
			}
			print FILE "$key: $value\n";
		}
	}
	# now save the parts out
	my $partCount = 0;
	my $part;
	foreach $part (@{$self->{'Parts'}}) {
		print FILE "Part: $partCount\n";
		print FILE $part->displayAsFile();
		print FILE "EndPart: $partCount\n";
		++$partCount;
	}

	close FILE;
	FAQ::OMatic::unlockFile($lock);

	# For item files (not .smry files, which also use the FAQ::OMatic::Item
	# mechanism for storage), do these things:
	# 1. Perform RCS ci so we can always get the files back in the face
	#    of net-creeps.
	# 2. Clear the search hint so we know to regenerate the search index
	# 3. Rewrite the static cached HTML copy
	# 
	# We now ci and co in separate steps so that we can specify the '-ko'
	# flag to co (which ci doesn't accept); the '-ko' flag keeps co
	# from performing RCS keyword substitution on the item text. This
	# is important in general to avoid modifying users' data,
	# but crucial in the (dollar)Log(dollar)
	# case, where the number of lines in an item file change, and
	# the structure of the file is corrupted. (Oh, to use XML!)
	#
	# THANKS to others for pointing out the -k fix, and
	# THANKS Somnath Mitra <somnath@cisco.com> for sending a patch
	# upon which this fix is based.
	if ($dir eq $FAQ::OMatic::Config::itemDir) {
		## Tell RCS who we are
		$ENV{"USER"} = $FAQ::OMatic::Config::RCSuser;
	   	$ENV{"LOGNAME"} = $FAQ::OMatic::Config::RCSuser;
		my $itemPath = "$dir/$filename";
		my $rcsFilePath = $FAQ::OMatic::Config::metaDir
			."/RCS/$filename,v";
		my $cmd = "$FAQ::OMatic::Config::RCSci "
			."$FAQ::OMatic::Config::RCSciArgs $itemPath $rcsFilePath "
			."&& "	# && => only exit with success if both operations succeed
			."$FAQ::OMatic::Config::RCSco "
			."$FAQ::OMatic::Config::RCScoArgs $rcsFilePath $itemPath";
		#FAQ::OMatic::gripe('debug', $cmd);
		my @result = FAQ::OMatic::mySystem($cmd);
		if (scalar(@result)) {
			FAQ::OMatic::gripe('problem',
				"RCS \"$cmd\" failed: (".join(", ", @result).")");
		}
	}
	# RCS has a habit of making item files read-only by the user -- fix that
	# (umask might also be uptight)
	if (not chmod(0644, "$dir/$filename")) {
		FAQ::OMatic::gripe('problem', "chmod($dir/$filename) failed: $!");
	}

	# if $lastModified was specified, correct filesystem mtime
	# (If not specified, the fs mtime is already set to 'now',
	# which is correct.)
	if ($lastModified) {
		utime(time(),$self->{'LastModifiedSecs'},"$dir/$filename");
	}

	# As I was saying, ...
	# 2. Clear the search hint so we know to regenerate the search index
	# 3. Rewrite the static cached HTML copy
	if ($dir eq $FAQ::OMatic::Config::itemDir) {
		unlink("$FAQ::OMatic::Config::metaDir/freshSearchDBHint");

		$self->writeCacheCopy();
		if ($self->{'titleChanged'}) {
			# this item's title has changed:
			# update the cache for any items that refer to this one (and
			# thus have this one's title in their cached HTML)
			my $dependent;
			foreach $dependent (getDependencies($self->{'filename'})) {
				my $dependentItem = new FAQ::OMatic::Item($dependent);
				$dependentItem->writeCacheCopy();
			}
		}

		# rewrite .dep files (items that contain HeDependsMe-Sets)
		my $oidos = $self->getSet('oldIDependOn-Set');
		my $nidos = $self->getSet('IDependOn-Set');
		my @removeList = ($oidos->subtract($nidos))->getList();
		my @addList;
		if ($updateAllDependencies) {
			@addList = $nidos->getList();
		} else {
			@addList = ($nidos->subtract($oidos))->getList();
		}
		my $itemName;
		foreach $itemName (@removeList) {
			adjustDependencies('remove', $itemName, $self->{'filename'});
		}
		foreach $itemName (@addList) {
			adjustDependencies('insert', $itemName, $self->{'filename'});
		}
	}
}

sub getDependencies {
	my $filename = shift;
	my $depItem = loadDepItem($filename);
	return $depItem->getSet('HeDependsOnMe-Set')->getList();
}

sub loadDepItem {
	my $itemName = shift;

	my $depFile = "$itemName.dep";
	my $depItem = new FAQ::OMatic::Item($depFile,
			$FAQ::OMatic::Config::cacheDir);
	$depItem->setProperty('Title', 'Dependency List');
			# in case $depItem was new
	return $depItem;
}

sub adjustDependencies {
	my $what = shift;		# 'insert' or 'remove'
	my $itemName = shift;
	my $targetName = shift;

	my $depItem = loadDepItem($itemName);
	my $hdos = $depItem->getSet('HeDependsOnMe-Set');
	if ($what eq 'insert') {
		$hdos->insert($targetName);
	} else {
		$hdos->remove($targetName);
	}
	$depItem->setProperty('HeDependsOnMe-Set', $hdos);
			# in case $hdos was new
	my $depFile = "$itemName.dep";
	$depItem->saveToFile($depFile,
			$FAQ::OMatic::Config::cacheDir);
}

# For explicit faqomatic: links, the dependency mechanism is automatic:
# the link can't change without the item itself changing, so when the
# item gets written out, the cache and dependencies for it are up-to-date.
#
# For parent links, the dependency mechanism still works -- if a parent
# moves or changes its name (or this item moves, which is an operation on
# its parent), the old parent had to get written, and this item knew it
# was dependent on that parent, so this item gets rewritten, too, and has
# its dependencies updated, at which point it detects any new parent.
#
# But for sibling links, this item has no way of discovering (via
# dependencies) when those links change. Whenever a category changes its
# directory part list, it has also changed the sibling links for some
# of its children. In any case like that, it's the parent's responsibility
# to rewrite all of its children, so their dependencies and caches
# can be recomputed.
sub updateAllChildren {
	my $self = shift;

	my $filei;
	foreach $filei ($self->getChildren()) {
		#FAQ::OMatic::gripe('debug', "Updating child $filei of ".$self->{'filename'});
		my $itemi = new FAQ::OMatic::Item($filei);
		if (not $itemi->isBroken()) {
	#		$itemi->writeCacheCopy();
	# jonh: only writing the cache copy isn't enough -- if $itemi's set of
	# siblings has changed, then its IDependOns have changed, too. Those
	# are stored in the item file itself.
			$itemi->saveToFile('', '', 'noChange');
				# The contents of the item itself haven't changed.
				# The 'noChange' prevents us from updating the LastModifiedSecs
				# property, so that this item doesn't show up in 'recent'
				# searches even though it hasn't actually changed.
		}
	}
}

sub getChildren {
	my $self = shift;

	my $dirPart = $self->getDirPart();
	if (defined($dirPart)) {
		return $dirPart->getChildren();
	}
	return ();
}

sub getBags {
	my $self = shift;

	# remove duplicates but keep order using a Set
	my $bagset = new FAQ::OMatic::Set('keepOrdered');
	my $i;
	for ($i=0; $i<$self->numParts(); $i++) {
		$bagset->insert($self->getPart($i)->getBags());
	}

	return $bagset->getList();
}

# Currently meaningful -Sets that can be in an Item:
# HeDependsOnMe-Set: list of items that depend on this item's Title property
# IDependOn-Set: list of items whose titles this item depends upon.
#	it's useful so we can revoke our membership in that item's
#	HeDependsOnMe-Set when we no longer refer to it.

sub getSet {
	my $self = shift;
	my $setName = shift;

	return $self->{$setName} || new FAQ::OMatic::Set;
}

sub writeCacheCopy {
	my $self = shift;

	my $filename = $self->{'filename'};

	if (defined($FAQ::OMatic::Config::cacheDir)
		&& (-w $FAQ::OMatic::Config::cacheDir)) {
		my $staticFilename =
			"$FAQ::OMatic::Config::cacheDir/$filename.html";
		my $params = {'file'=>$self->{'filename'},
					'_fromCache'=>1};
			# this link is coming from inside the cache, so we
			# can use relative links. That's nice if we later
			# wrap up the cache and mail it somewhere.
		my $staticHtml = $self->getWholePage($params, 1);
		if (not open(CACHEFILE, ">$staticFilename")) {
			FAQ::OMatic::gripe('problem',
				"Can't write $staticFilename: $!");
		} else {
			print CACHEFILE $staticHtml;
			close CACHEFILE;
			if (not chmod(0644, $staticFilename)) {
				FAQ::OMatic::gripe('problem',
					"chmod($staticFilename) failed: $!");
			}
		}
	}
}

sub getWholePage {
	my $self = shift;
	my $params = shift;
	my $isCached = shift || '';

	return FAQ::OMatic::pageHeader($params,
			FAQ::OMatic::Appearance::allLinks(), 'suppressType')
		.$self->displayHTML($params)
		.basicURL($params)
		.FAQ::OMatic::pageFooter($params,
			FAQ::OMatic::Appearance::allLinks(), $isCached);
}

sub display {
	my $self = shift;
	my @keys;
	my $rt = "";	# return text

	my $key;
	foreach $key (sort keys %$self) {
		if ($key eq 'Parts') {
			$rt .= "<li>".gettext("Parts")."\n";
			my $part;
			foreach $part (@{$self->{$key}}) {
				$rt .=  $part->display();
			}
		} else {
			$rt .= "<li>$key => $self->{$key}<br>\n";
		}
	}
	return $rt;
}

sub getTitle {
	my $self = shift;
	my $undefokay = shift;	# return undef instead of '(missing or broken...'
	my $title = $self->{'Title'};
	if ($title) {
    	$title =~ s/&/&amp;/sg;
    	$title =~ s/</&lt;/sg;
    	$title =~ s/>/&gt;/sg;
    	$title =~ s/"/&quot;/sg;
	} else {
		undef $title;
		$title = gettext("(missing or broken file)") if (not $undefokay);
	}

	return $title;
}

sub isBroken {
	my $self = shift;
	return (not defined($self->{'Title'}));
}

sub isEmptyStub {
	my $self = shift;
	return $self->{'EmptyStub'} || '';
}

sub getParent {
	my $self = shift;

	return new FAQ::OMatic::Item($self->{'Parent'});
}

# returns two lists, the filenames and titles of this item's parent items.
# The list is slightly falsified in that if the topmost ancestor isn't
# '1' (such as 'trash' and 'help000'), we insert '1' as an ancestor.
# That way 'trash' and 'help000's displayed parent chains include links
# to the top of the FAQ, but are not moveable (since they still have no
# real parent, which is how moveItem.pm can tell.)
sub getParentChain {
	my $self = shift;
	my @titles = ();
	my @filenames = ();
	my ($nextfile, $nextitem, $thisfile);

	$nextitem = $self;
	$nextfile = $self->{'filename'};
	do {
		push @titles, $nextitem->getTitle();
		push @filenames, $nextitem->{'filename'};
		$thisfile = $nextfile;
		$nextfile = $nextitem->{'Parent'};
		$nextitem = $nextitem->getParent();
	} while ((defined $nextitem) and (defined $nextfile)
		and ($nextfile ne $thisfile));

	if (($nextfile||'') ne '1') {
		# insert '1' as extra 'bogus' parent
		my $item1 = new FAQ::OMatic::Item('1');
		push @titles, $item1->getTitle();
		push @filenames, $item1->{'filename'};	# I can guess what this is :v)
	}

	# Massage undefined data; this happens when writing the HTML cache for
	# a mirrored item that has a forward reference to another item that
	# hasn't been mirrored yet. Once the new item arrives, dependencies
	# will cause us to rewrite the HTML file correctly.
	# TODO: a regression test should 'grep undefinedFilename item/*' to
	# see if any of these stay in the item or cache directories after a
	# mirror is complete.
	@titles = map { $_ || 'undefinedTitle' } @titles;
	@filenames = map { $_ || 'undefinedFilename' } @filenames;
	return (\@titles, \@filenames);
}

# same structure as above, but only used to check for a particular parent
sub hasParent {
	my $self = shift;
	my $parentFile = shift;

	my ($nextfile, $nextitem, $thisfile);

	$nextitem = $self;
	$nextfile = $self->{'filename'};
	do {
		return 1 if (defined($nextfile) && ($nextfile eq $parentFile));

		$thisfile = $nextfile;
		$nextfile = $nextitem->{'Parent'};
		$nextitem = $nextitem->getParent();
	} while ((defined $nextitem) and (defined $nextfile)
		and ($nextfile ne $thisfile));
	
	return 0;
}

# okay, I guess this displays the neighbors, too...
sub displaySiblings {
	my $self = shift;
	my $params = shift;
	my $rt = '';		# return text
	my $useTable = FAQ::OMatic::getParam($params, 'render') eq 'tables';

	my ($prevs,$nexts) = $self->getSiblings();
	if ($prevs) {
		my $prevItem = new FAQ::OMatic::Item($prevs);
		my $prevTitle = $prevItem->getTitle();
		if ($useTable) {
			$rt.="<tr><td valign=top align=right>\n";
		} else {
			$rt.="<br>\n";
		}
		$rt.=gettext("Previous").": ";
		$rt.="</td><td valign=top align=left>\n" if $useTable;
		$rt.=FAQ::OMatic::makeAref('-command'=>'faq',
							'-params'=>$params,
							'-changedParams'=>{"file"=>$prevs})
			.FAQ::OMatic::ImageRef::getImageRefCA('-small',
				'border=0', $prevItem->isCategory(), $params)
			."$prevTitle</a>\n";
		$rt.="</td></tr>\n" if $useTable;
	}
	if ($nexts) {
		my $nextItem = new FAQ::OMatic::Item($nexts);
		my $nextTitle = $nextItem->getTitle();
		if ($useTable) {
			$rt.="<tr><td valign=top align=right>\n";
		} else {
			$rt.="<br>\n";
		}
		$rt.=gettext("Next").": ";
		$rt.="</td><td valign=top align=left>\n" if $useTable;
		$rt.=FAQ::OMatic::makeAref('-command'=>'faq',
							'-params'=>$params,
							'-changedParams'=>{"file"=>$nexts})
			.FAQ::OMatic::ImageRef::getImageRefCA('-small',
				'border=0', $nextItem->isCategory(), $params)
			."$nextTitle</a>\n";
		$rt.="</td></tr>\n" if $useTable;
	}
	return $rt;
}

# sub hasParent {
# 	my $self = shift;
# 	my $parentQuery = shift;
# 	my ($titles,$filenames) = $self->getParentChain();
# 
# 	my $i;
# 	foreach $i (@{$filenames}) {
# 		my $item = new FAQ::OMatic::Item($i);
# 		return 'true' if ($item->{'filename'} eq $parentQuery);
# 	}
# 
# 	return '';
# }

sub displayCoreHTML {
	my $self = shift;
	my $params = shift;	# ref to hash of display params
	my $whatAmI = $self->whatAmI();
	my $render = FAQ::OMatic::getParam($params, 'render');

	# we'll pass this to makeAref to get file param right in links
	my @fixfn =('file'=>$self->{'filename'});
	my $title = $self->getTitle();

	# accumulate the title, the parts, and the editing sections into
	# a list @rowboxes, so that when we construct the <table>, we know in
	# advance how many rows it has.
	my @rowboxes = ();

	# create the title
	{
		my $titlebox = '';
		if ($render ne 'text') {
			$titlebox .= "<a name=\"file_"
				.$self->{'filename'}."\"> </a>\n";	# link for internal refs
		}
	
		# prefix item title with a path back to the root, so that user
		# can find his way back up. (This replaces the old "Up to:" line.)
		my ($titles,$filenames) = $self->getParentChain();
		my ($thisTitle) = shift @{$titles};
		my ($thisFilename) = shift @{$filenames};
#		my (@parentTitles) = reverse @{$titles};
		my (@parentFilenames) = reverse @{$filenames};
		$titlebox.=
			join(" : ",
				map {
					my ($target,$label) =
						FAQ::OMatic::faqomaticReference($params, "$_");
					"<a href=\"$target\">$label</a>";
				} @parentFilenames
			);
		if (@parentFilenames) {
			$titlebox.=" :\n";
			if ($render ne 'text'
				and not ($FAQ::OMatic::Config::nolanTitles || '')) {
				$titlebox.="<br>";
			}
		}
		# THANKS: to Jim Adler <jima@sr.hp.com> who suggested this graphical
		# improvement: larger type to make the titles stand out.
		if ($render eq 'text') {
			$titlebox.=$thisTitle;
		} else {
			if ($FAQ::OMatic::Config::nolanTitles || '') {
				# John Nolan <jnolan@cdnow.com> likes it better this way:
				$titlebox.= FAQ::OMatic::ImageRef::getImageRefCA('-small',
					'border=0', $self->isCategory(), $params);
				$titlebox.="<b>$thisTitle</b>";
			} else {
				$titlebox.="<font size=\"+1\"><b>$thisTitle</b></font>";
			}
			$titlebox.="</a>"; # close <a name=...
		}
		push @rowboxes, { 'type'=>'wide', 'text'=>$titlebox,
			'id'=>'title' };
	}

	if (FAQ::OMatic::getParam($params, 'showModerator') eq 'show') {
		my $mod = FAQ::OMatic::Auth::getInheritedProperty($self, 'Moderator');
		my $brt = '';

		# highlight the "Moderator: ". 
		# THANKS submitted by Akiko Takano <takano@iij.ad.jp>
		if (FAQ::OMatic::getParam($params, 'render') ne 'text') {
			$brt .= "<font color=$FAQ::OMatic::Config::highlightColor>";
			$brt .= gettext("Moderator").": ".FAQ::OMatic::mailtoReference($params, $mod);
			$brt .= " <i>"
				.gettext("(inherited from parent)")."</i>" if (not $self->{'Moderator'});
			$brt .= "</font>\n";
		} else {
			$brt .= "Moderator: ".FAQ::OMatic::mailtoReference($params, $mod);
		}

		push @rowboxes, { 'type'=>'wide', 'text'=>$brt,
			'id'=>'showModerator' };
	}

	## Edit commands:
	my $aoc = $self->isCategory ? 'cat' : 'ans';

	if (FAQ::OMatic::getParam($params, 'editCmds') ne 'hide') {
		my $editrow = [];
		my ($text_edit_title, $text_edit_perm, $text_move, $text_trash);
		if ($self->isCategory())
		{
			$text_edit_title = gettext("Category Title and Options");
			$text_edit_perm = gettext("Edit Category Permissions");
			$text_move = gettext("Move Category");
			$text_trash = gettext("Trash Category");
		}
		elsif ($self->isAnswer())
		{
			$text_edit_title = gettext("Answer Title and Options");
			$text_edit_perm = gettext("Edit Answer Permissions");
			$text_move = gettext("Move Answer");
			$text_trash = gettext("Trash Answer");
		}
		else
		{
			# fixup for unexpected cases
			my $s = gettext($whatAmI);
			$text_edit_title = gettexta("%0 Title and Options", $s);
			$text_edit_perm = gettexta("Edit %0 Permissions", $s);
			$text_edit_perm = gettexta("Edit %0 Permissions", $s);
			$text_move = gettexta("Move %0", $s);
			$text_trash = gettexta("Trash %0", $s);
		}

		push @$editrow, {'text'=>FAQ::OMatic::button(
			FAQ::OMatic::makeAref('-command'=>'editItem',
					'-params'=>$params,
					'-changedParams'=>{@fixfn}),
			$text_edit_title,
			"$aoc-title", $params),
				'size'=>'edit'};
			# TODO: just edit title. Options is only part order; need
			# a new interface for that.

		push @$editrow, {'text'=>FAQ::OMatic::button(
			FAQ::OMatic::makeAref('-command'=>'editModOptions',
					'-params'=>$params,
					'-changedParams'=>{@fixfn}),
			$text_edit_perm,
			"$aoc-opts", $params),
				'size'=>'edit'};

		push @rowboxes, { 'type'=>'multirow', 'cells'=>$editrow,
			'id'=>'title, perms', 'isEdit'=>'true' };
		$editrow = [];

		# These don't make sense if we're in a special-case item file, such
		# as 'trash'. We'll assume here that items whose file names end in
		# a digit are 'incrementable' and can thus have children.
		# TODO: default system should ship with help000 having moderator-only
		# TODO: permissions to discourage the public from modifying the
		# TODO: help system. This will matter more when the help system
		# TODO: is implemented. :v)
		# THANKS: to Doug Becker <becker@foxvalley.net> for
		# accidentally making a 'trasi' item (perl incrsemented 'trash' :v)
		# and discovering this problem.
		if ($self->ordinaryItem()) {
			# Duplicate it
			my $dupTitle = $whatAmI eq "Answer"
						? gettext("Duplicate Answer")
						: gettext("Duplicate Category as Answer");
			push @$editrow, {'text'=>FAQ::OMatic::button(
				FAQ::OMatic::makeAref('-command'=>'addItem',
						'-params'=>$params,
						'-changedParams'=>{'_insert'=>'answer',
					 			'_duplicate'=>$self->{'filename'},
								'file'=>$self->{'Parent'}}
					),
					$dupTitle,
					"$aoc-dup-ans", $params),
						'size'=>'edit'};
	
			# Move it (if not at the top)
			if ($self->{'Parent'} ne $self->{'filename'}) {
				push @$editrow, {'text'=>FAQ::OMatic::button(
						FAQ::OMatic::makeAref('-command'=>'moveItem',
							'-params'=>$params,
							'-changedParams'=>{@fixfn}),
						$text_move),
							'size'=>'edit'};
	
				# Trash it (same rules as for moving)
				push @$editrow, {'text'=>FAQ::OMatic::button(
						FAQ::OMatic::makeAref('-command'=>'submitMove',
							'-params'=>$params,
							'-changedParams'=>{@fixfn,
								'_newParent'=>'trash'}),
						$text_trash),
							'size'=>'edit'};
			}
	
			# Convert category to answer / answer to category
			# THANKS: to Steve Herber for suggesting pulling this out of
			# THANKS: editPart and putting it here as a distinct command
			# THANKS: for clarity.
			if ($self->isCategory()
					and scalar($self->getChildren())==0) {
				push @$editrow, {'text'=>FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'submitCatToAns',
							'-params'=>$params,
							'-changedParams'=>{
							  'checkSequenceNumber'=>$self->{'SequenceNumber'},
							  @fixfn}),
						gettext("Convert to Answer"),
						'cat-to-ans', $params),
							'size'=>'edit'};
			} elsif (not $self->isCategory()) {
				push @$editrow, {'text'=>FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'submitAnsToCat',
							'-params'=>$params,
							'-changedParams'=>{
							  'checkSequenceNumber'=>$self->{'SequenceNumber'},
							  @fixfn}),
						gettext("Convert to Category"),
						"$aoc-to-cat", $params),
							'size'=>'edit'};
			}
	
			# Create new children
			if ($self->isCategory()) {
				# suggestion of adding cat title to reduce confusion is from
				# THANKS: pauljohn@ukans.edu
				if (length($title) > 15) {
					$title = substrFOM($title, 12)."...";
				}
				push @$editrow, {'text'=>FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'addItem',
							'-params'=>$params,
							'-changedParams'=>{'_insert'=>'answer', @fixfn}),
						gettexta("New Answer in \"%0\"", $title),
						'cat-new-ans', $params),
							'size'=>'edit'};
				push @$editrow, {'text'=>FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'addItem',
							'-params'=>$params,
							'-changedParams'=>{'_insert'=>'category', @fixfn}),
						gettexta("New Subcategory of \"%0\"", $title),
						'cat-new-cat', $params),
							'size'=>'edit'};
			}
		}

		push @rowboxes, { 'type'=>'multirow', 'cells'=>$editrow,
			'id'=>'dup, trash, etc', 'isEdit'=>'true' };
		$editrow = [];

		# Allow user to insert a part before any other
		if ($self->ordinaryItem()) {	# as opposed to trash, help, ...
			push @$editrow, {'text'=>''};	# empty cell --
				# this is a *hack* so that this 'multirow' lines up the
				# same as the afterbody's of the 'three'-type parts generated
				# by Part.pm. But it may confuse some future itemRender
				# routine.
			push @$editrow, {'text'=>
				FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'editPart',
						'-params'=>$params,
						'-changedParams'=>{'partnum'=>'-1',
							'_insertpart'=>'1',
							'checkSequenceNumber'=>$self->{'SequenceNumber'},
							@fixfn}
						),
					gettext("Insert Text Here"),
					"$aoc-ins-part", $params),
						'size'=>'edit'};
			push @$editrow, {'text'=>
				FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'editPart',
						'-params'=>$params,
						'-changedParams'=>{'partnum'=>'-1',
							'_insertpart'=>'1',
							'_upload'=>'1',
							'checkSequenceNumber'=>$self->{'SequenceNumber'},
							@fixfn}
						),
					gettext("Insert Uploaded Text Here"),
					"$aoc-ins-part", $params),
						'size'=>'edit'};
			push @rowboxes, { 'type'=>'multirow', 'cells'=>$editrow,
				'id'=>'insert before other parts', 'isEdit'=>'true' };
		}
	}

	my $partnum = 0;
	my $authorSet = new FAQ::OMatic::Set('keepordered');
			# for AttributionsTogether
	my $part;
	foreach $part (@{$self->{'Parts'}}) {
		if ($render eq 'text') {
			push @rowboxes, $part->displayText($self, $partnum, $params);
		} else {
			push @rowboxes, $part->displayHTML($self, $partnum, $params);
		}
		$authorSet->insert($part->{'Author-Set'}->getList());
		++$partnum;
	}

	if ((not $FAQ::OMatic::Config::hideEasyEdits)
		and ($render ne 'text')) {
		if ($self->isCategory()) {
			# Categories: offer a way to insert a new answer
			# TODO: does this link belong just below the directory
			# part, rather than at the bottom?
			my $title = $self->getTitle();
			push @rowboxes, { 'type'=>'wide',
				'text'=>FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'addItem',
							'-params'=>$params,
							'-changedParams'=>{'_insert'=>'answer', @fixfn}),
					gettexta("New Answer in \"%0\"", $title),
					'cat-new-ans', $params),
				'size'=>'edit',
				'id'=>'easy edit insert answer'};
		} else {
			# answers: offer a way to append an item
			my $partnum = scalar(@{$self->{'Parts'}})-1;
			push @rowboxes, { 'type'=>'wide',
				'text'=>FAQ::OMatic::button(
					FAQ::OMatic::makeAref('-command'=>'editPart',
						'-params'=>$params,
						'-changedParams'=>{'partnum'=>'9999afterLast',
							'_insertpart'=>'1',
							'checkSequenceNumber'=>$self->{'SequenceNumber'},
							@fixfn}
						),
					gettext("Append to This Answer"),
					"$aoc-ins-part", $params),
				'size'=>'edit',
				'id'=>'easy edit append to answer'};
		}
	}

	# AttributionsTogether displays all attributions for any part in
	# this item together at the bottom of the item to reduce clutter.
	my $attributionsTogether = $self->{'AttributionsTogether'} || '';
	my $showAttributions = FAQ::OMatic::getParam($params, 'showAttributions');
	if ($attributionsTogether and 
		($showAttributions eq 'default')) {
		my @authors = $authorSet->getList();
		my $brt = FAQ::OMatic::authorList($params, \@authors);
		push @rowboxes, { 'type'=>'wide', 'text'=>$brt,
			'id'=>'attributionsTogether' };
	}

	# THANKS: Config::showLastModifiedAlways feature was requested by
	# THANKS: parker@austx.tandem.com
	# (but it's now handled as a standard default parameter.)
	my $showLastModified =
		FAQ::OMatic::getParam($params, 'showLastModified') eq 'show';
	my $lastModified = $self->{'LastModifiedSecs'};
	if ($lastModified and $showLastModified) {
		my $brt = '';
		$brt .= "<i>".compactDate($self->{'LastModifiedSecs'})."</i>\n";
		push @rowboxes, { 'type'=>'wide', 'text'=>$brt,
			'id'=>'lastModified' };
	}

	my @items = { 'item'=>$self,
				  'rows'=>\@rowboxes };

	## recurse on children
	if ($params->{'recurse'} or $params->{'_recurse'}) {
		my $filei;
		my $itemi;
		foreach $filei ($self->getChildren()) {
			$itemi = new FAQ::OMatic::Item($filei);
			#$rt .= $itemi->displayCoreHTML($params);
			push @items, @{$itemi->displayCoreHTML($params)};
		}
	}

	#return $rt;
	return \@items;
}

sub ordinaryItem {
	my $self = shift;
	return ($self->{'filename'} =~ m/\d$/);
}

sub displayHTML {
	my $self = shift;
	my $params = shift;	# ref to hash of display params
	my $rt = "";

	# signal to aref generator that some internal links are
	# possible. (only signal this when recursing to save effort otherwise)
	if ($params->{'recurse'} or $params->{'_recurse'}) {
		$params->{'_recurseRoot'} = $self->{'filename'};
		# A limit jonh puts on his machines:
		# FAQ::OMatic::checkLoadAverage();
	}

	my $itemboxes = $self->displayCoreHTML($params);
	$rt = FAQ::OMatic::Appearance::itemRender($params, $itemboxes);

	# turn #internal links off after the items are displayed.
	# Otherwise they mess up the bottom link bar.
	# (is there a general way to solve that problem?)
	delete $params->{'_recurseRoot'};

	# Sibling links
	if ((FAQ::OMatic::getParam($params, 'render') ne 'text')
		and not ($FAQ::OMatic::Config::hideSiblings || '')) {
		my $useTable = FAQ::OMatic::getParam($params, 'render') eq 'tables';
		$rt.="\n";
		$rt.="<table>" if $useTable;
		$rt.="<!-- Sibling links -->\n";
		$rt.= $self->displaySiblings($params);
		$rt.="</table>\n" if $useTable;
		$rt.="<p>\n" if not $useTable;
	}

	$rt.=FAQ::OMatic::HelpMod::helpFor($params,
		'How can I contribute to this FAQ?', "<br>");

	return $rt;
}

sub basicURL {
	my $params = shift;

	return '' if ($params->{'file'} =~ m/^help/);
	
	my %killParams = %{$params};
	delete $killParams{'file'};
	delete $killParams{'recurse'} if ($params->{'recurse'});
	my $i; foreach $i (keys %killParams) { $killParams{$i} = ''; }

	# TODO: We have always had the "This document is:"
	# TODO: refer to the CGI. I liked that because it let me fiddle
	# TODO: with the cache layout (after all, it changed in 2.604.)
	# TODO: But others have asked to totally hide the presence of the CGI,
	# TODO: in which case we should *only* display cache URLs here.
	# TODO: Or leave this line out altogether.

	my $url = FAQ::OMatic::makeAref('-command'=>'faq',
				'-params' => $params,
				'-changedParams'=>\%killParams,
				'-thisDocIs'=>1,
				'-refType'=>'url');

	if (FAQ::OMatic::getParam($params, 'render') ne 'text') {
		return gettext("This document is:") . " <a href=\"$url\">$url</a><br>\n";
	} else {
		return gettext("This document is at:") . " $url\n";
	}
}

sub permissionBox {
	my $self = shift;
	my $perm = shift;

	my @permNum = (7);
	push @permNum, FAQ::OMatic::Groups::getGroupCodeList();
	push @permNum, (5, 3);

	my @permDesc = map { nameForPerm($_); } @permNum;

	push @permNum, ('');
	push @permDesc, gettext('Inherit');

	return popup($perm, \@permNum, \@permDesc, $self->{$perm}||'');
}

sub popup {
	my $name = shift;
	my $values = shift;			# ary ref
	my $descary = shift;		# ary ref; 1:1 with $values
	my $curvalue = shift;		# one of @{$values}

	$curvalue = '' if (not defined $curvalue);

	my $rt = '';
	$rt.="<select name=\"_$name\">\n";
	for (my $i=0; $i<@{$values}; $i++) {
		$rt .= "<option value=\"".$values->[$i]."\"";
		$rt .= " SELECTED" if ($values->[$i] eq $curvalue);
		$rt .= ">".$descary->[$i]."\n";
	}
	$rt.="</select>\n";
	return $rt;
}

sub nameForPerm {
	# this is a lot like Auth::authError, but with more concise descriptions
	my $perm = shift;

	if ($perm =~ m/^6 (.*)$/) {
		return gettexta("Group %0", "$1");
	}

	my %map = (
		'3' => gettext("Users giving their names"),
		'5' => gettext("Authenticated users"),
		'7' => gettext("Moderator"),
	);

	return $map{$perm};
}

sub displayItemEditor {
	my $self = shift;
	my $params = shift;
	my $cgi = shift;
	my $rt = ""; 	# return text

	my $insertHint = $params->{'_insert'} || '';
	if ($insertHint eq 'category') {
		$rt .= gettext("New Category")."\n";
	} elsif ($insertHint eq "answer") {
		$rt .= gettext("New Answer")."\n";
	} else {
		if ($self->isCategory())
		{
			$rt .= gettexta("Editing Category <b>%0</b>", $self->getTitle());
		}
		elsif ($self->isAnswer())
		{
			$rt = gettexta("Editing Answer <b>%0</b>", $self->getTitle());
		}
		else
		{
			# fixup for unexpected cases.
			$rt .= gettexta("Editing %0 <b>%1</b>",
							gettext($self->whatAmI()),
							$self->getTitle());
		}
		$rt .= "\n";
	}
	$rt .= FAQ::OMatic::makeAref('-command'=>'submitItem',
			'-params'=>$params,
			'-changedParams'=>{'_insert'=>$params->{'_insert'}},
			'-refType'=>'POST');

	# SequenceNumber protects the database from race conditions --
	# if person A gets this form,
	# then person B gets this form,
	# then person A returns the form (incrementing the sequence number),
	# then person B returns the form, the sequence number won't match,
	# so B will be turned back, so he can't mistakenly overwrite A's changes.
	# (it doesn't help for race conditions involving two simultaneously-
	# running CGIs, only with the simultaneity of two people typing into
	# browser forms at once.
	# TODO: Lock files are supposed to help with two CGIs, but their
	# TODO: implementation isn't right. They only protect during the
	# TODO: actual write (which keeps the item files consistent). But
	# TODO: data can get lost in a race, since two CGIs can still
	# TODO: run in the classic A:read-B:read-A:modify,write-B:modify,write
	# TODO: race condition.
	$rt .= "<input type=hidden name=\"checkSequenceNumber\" value=\""
			.$self->{'SequenceNumber'}."\">\n";

	# Title
	$rt .= "<br>".gettext("Title:")."<br><input type=text name=\"_Title\" value=\""
			.$self->getTitle()."\" size=60>\n";

	# Reorder parts
	if ($self->numParts() > 1) {
		$rt .= gettext("<p>New Order for Text Parts:");
		$rt .= "<br><input type=text name=\"_partOrder\" value=\"";
		my $i;
		for ($i=0; $i<$self->numParts(); $i++) {
			$rt .= "$i ";
		}
		$rt .= "\" size=60>\n";
	}

	# AttributionsTogether
	$rt .= "<p><input type=checkbox name=\"_AttributionsTogether\"";
	$rt .= " CHECKED" if $self->{'AttributionsTogether'};
	$rt .= "> ".gettext("Show attributions from all parts together at bottom")."\n";

# TODO: delete this block. superseded by submitAnsToCat
#	if ((not defined $self->{'directoryHint'})
#		and (not $params->{'_insert'})) {
#		# we hide this on initial inserts, because it serves to confuse, and
#		# they can always come back here.
#		$rt .= "<p><input type=checkbox name=\"_addDirectory\">"
#			." Add a directory part to turn this answer item into "
#			."a category item.\n";
#	}

	# Submit
	$rt .="<br><input type=submit name=\"_submit\" value=\"".gettext("Submit Changes")."\">\n";
	$rt .= "<input type=reset name=\"_reset\" value=\"".gettext("Revert")."\">\n";
	$rt .= "<input type=hidden name=\"_zzverify\" value=\"zz\">\n";
		# this lets the submit script check that the whole POST was
		# received.
	$rt .= "</form>\n";
#	$rt .= FAQ::OMatic::button(
#			FAQ::OMatic::makeAref('-command'=>'faq',
#				'-params'=>$params,
#				'-changedParams'=>{'checkSequenceNumber'=>''}),
#			"Cancel and return to the FAQ");

	$rt .= FAQ::OMatic::HelpMod::helpFor($params, 'editItem', "<br>\n");

	return $rt;
}

sub permissionsInfo {
	my $permissionsInfo = {

	'01' => { 'name'=>'PermAddPart', 'desc'=>
			gettext("Who can add a new text part to this item:") },
	'02' => { 'name'=>'PermAddItem', 'desc'=>
			gettext("Who can add a new answer or category to this category:") },
	'03' => { 'name'=>'PermEditPart', 'desc'=>
			gettext("Who can edit or remove existing text parts from this item:") },
	'04' => { 'name'=>'PermEditDirectory', 'desc'=>
			gettext("Who can move answers or subcategories from this category; or turn this category into an answer or vice versa:") },
	'05' => { 'name'=>'PermEditTitle', 'desc'=>
			gettext("Who can edit the title and options of this answer or category:") },
	'06' => { 'name'=>'PermUseHTML', 'desc'=>
			gettext("Who can use untranslated HTML when editing the text of this answer or category:") },
	'07' => { 'name'=>'PermModOptions', 'desc'=>
			gettext("Who can change these moderator options and permissions:") },
	'09' => { 'name'=>'PermNewBag', 'global'=>1, 'desc'=>
			gettext("Who can create new bags:") },
	'10' => { 'name'=>'PermReplaceBag', 'global'=>1, 'desc'=>
			gettext("Who can replace existing bags:") },
	'11' => { 'name'=>'PermInstall', 'global'=>1, 'desc'=>
			gettext("Who can access the installation/configuration page (use caution!):") },
	'12' => { 'name'=>'PermEditGroups', 'global'=>1, 'desc'=>
			gettext("Who can use the group membership pages:") },
	};
		# TODO: The global permissions should probably appear
		# TODO: on a different page. As-is, the administrator must
		# TODO: give away control over these permissions to give
		# TODO: away moderatorship of the root item.
	return $permissionsInfo;
}

sub displayModOptionsEditor {
	my $self = shift;
	my $params = shift;
	my $cgi = shift;
	my $rt = ""; 	# return text

	if ($self->isCategory())
	{
		$rt .= gettext("Moderator options for category");
	}
	elsif ($self->isAnswer())
	{
		$rt .= gettext("Moderator options for answer");
	}
	else
	{
		# fixup for unexpected cases.
		$rt .= gettext("Moderator options for")." "
				.gettext($self->whatAmI());
	}
	$rt .= " <b>".$self->getTitle()."</b>:\n"
			."<p>\n";

	$rt .= FAQ::OMatic::makeAref('-command'=>'submitModOptions',
			'-params'=>$params,
			'-changedParams'=>{'_insert'=>$params->{'_insert'}},
			'-refType'=>'POST');

	$rt .= "<input type=hidden name=\"checkSequenceNumber\" value=\""
			.$self->{'SequenceNumber'}."\">\n";

	# Moderator
	# THANKS to John Nolan for suggesting a better permissions layout.
	$rt .= "<table border=1>\n";
	$rt .=	"<tr>\n"
			."  <th>".gettext("Name & Description")."</th>\n"
			."  <th>".gettext("Setting")."</th>\n"
			."  <th>".gettext("Setting if Inherited")."</th>\n"
			."</tr>\n";

	# Moderator
#	$rt .= "<tr><td colspan=3 align=center><b>".gettext("Moderator")."</b>"
#			."</td></tr>\n";
	my $inherited = $self->getInheritance($params, 'Moderator', '<br>',
		sub {shift;});
	$rt .= "<tr><td colspan=2 align=left><b>".gettext("Moderator")."</b>\n"
			."<br>".gettext("(will inherit if empty)")."\n";
	$rt .= "<br>"
			."<input type=text name=\"_Moderator\" value=\""
			.($self->{'Moderator'}||'')."\" size=60></td>\n";
	$rt .= "<td>$inherited"
			."</td></tr>\n";

	# ModeratorMail
	$rt .= "<tr>"
			."<td><b>MailModerator</b>"
			."<br>".gettext("Send mail to the moderator when someone other than the moderator edits this item:")."</td>\n";
	$rt .= "<td>\n";
	$rt .= popup('MailModerator', [1, 0, ''], [gettext('Yes'), gettext('No'), gettext('Inherit')],
			$self->{'MailModerator'});
	$inherited =
		$self->getInheritance($params, 'MailModerator', '<br>',
			sub {(gettext("No"), gettext("Yes"))[shift()] || gettext("undefined")});
	$rt .= "<td>$inherited</td>\n";
	$rt .= "</tr>\n";


	# Notifier
	# THANKS to John Nolan for suggesting a better permissions layout.
#	$rt .= "<table border=1>\n";
#	$rt .=	"<tr>\n"
#			."  <th>".gettext("Name & Description")."</th>\n"
#			."  <th>".gettext("Setting")."</th>\n"
#			."  <th>".gettext("Setting if Inherited")."</th>\n"
#			."</tr>\n";

	# Notifer
#	$rt .= "<tr><td colspan=3 align=center><b>".gettext("Moderator")."</b>"
#			."</td></tr>\n";
	$inherited = $self->getInheritance($params, 'Notifier', '<br>',
		sub {shift;});
	$rt .= "<tr><td colspan=2 align=left><b>".gettext("Notifier")."</b>\n"
			."<br>".gettext("Send mail to the Notifier when item is created or modified")."\n"
			."<br>".gettext("(will inherit if empty)")."\n";
	$rt .= "<br>"
			."<input type=text name=\"_Notifier\" value=\""
			.($self->{'Notifier'}||'')."\" size=60></td>\n";
	$rt .= "<td>$inherited"
			."</td></tr>\n";

	# NotifierMail
	$rt .= "<tr>"
			."<td><b>MailNotifier</b>"
			."<br>".gettext("Send mail to the Notifier when someone other than the moderator edits this item:")."</td>\n";
	$rt .= "<td>\n";
	$rt .= popup('MailNotifier', [1, 0, ''], [gettext('Yes'), gettext('No'), gettext('Inherit')],
			$self->{'MailNotifier'});
	$inherited =
		$self->getInheritance($params, 'MailNotifier', '<br>',
			sub {(gettext("No"), gettext("Yes"))[shift()] || gettext("undefined")});
	$rt .= "<td>$inherited</td>\n";
	$rt .= "</tr>\n";

	# Permission info
	$rt .= "<tr><th colspan=3>".gettext("Permissions")."</th></tr>\n";

	my $permissionsInfo = permissionsInfo();
	foreach my $key (sort keys %{$permissionsInfo}) {
		my $ph = $permissionsInfo->{$key};	# permission descriptor hash
		next if ($ph->{'global'} and $self->{'filename'} ne '1');
			# only display global permissions for item 1, where they are set
		my $pname = $ph->{'name'};
		my $inherited =
			$self->getInheritance($params, $pname, '<br>', \&nameForPerm);
		$rt.="<tr><!-- $pname -->\n";
		$rt.="  <td><b>$pname</b>"
			."<br>".$ph->{'desc'}."</td>\n";	# Perm description column
		$rt.="  <td>".$self->permissionBox($ph->{'name'})."</td>\n";
												# popup choice column
		$rt.="  <td>$inherited</td>\n";			# inherited value column
		$rt.="</tr>\n";
	}

	# RelaxChildPerms
	$rt .= "<tr>"
			."<td><b>"."RelaxChildPerms"."</b>"
			."<br>".gettext("Relax: New answers and subcategories will be moderated ")
				.gettext("by the creator of the item, allowing that person full ")
				.gettext("freedom to edit that new item.")
			."<br>".gettext("Don't Relax: new items will be moderated by ")
			.gettext("the moderator of this item.")
			."</td>\n";
	$rt .= "<td>\n";
	$rt .= popup('RelaxChildPerms',
			['relax', 'norelax', ''],
			[gettext("Relax"), gettext("Don\'t Relax"), gettext("Inherit")],
			$self->{'RelaxChildPerms'});
	$inherited =
		$self->getInheritance($params, 'RelaxChildPerms', '<br>',
			sub {{'relax'=>gettext("Relax"), 'norelax'=>gettext("Don\'t Relax")}->{shift()}
				|| gettext("undefined")});
	$rt .= "<td>$inherited</td>\n";
	$rt .= "</tr>\n";

	$rt .= "</table>\n";

	$rt .="<p><input type=submit name=\"_submit\" value=\"".gettext("Submit Changes")."\">\n";
	$rt .= "<input type=reset name=\"_reset\" value=\"".gettext("Revert")."\">\n";
	$rt .= "<input type=hidden name=\"_zzverify\" value=\"zz\">\n";
		# this lets the submit script check that the whole POST was
		# received.
	$rt .= "</form>\n";

	$rt .= FAQ::OMatic::HelpMod::helpFor($params, 'editModOptions', "<br>\n");

	return $rt;
}

sub getInheritance {
	my $self = shift;
	my $params = shift;
	my $pname = shift;
	my $separator = shift;
	my $namecode = shift;

	my $val;
	my $whered;
	if ($self->getParent() eq $self) {
		$val = FAQ::OMatic::Auth::getDefaultProperty($pname);
		$whered = gettext("(system default)");
	} else {
		my ($pset,$where) = FAQ::OMatic::Auth::getInheritedProperty(
			$self->getParent(), $pname);
		if (defined $where) {
			$val = $pset;
			$whered = "(".gettext("defined in")." \""
				.FAQ::OMatic::makeAref('-command'=>'editModOptions',
					'-params'=>$params,
					'-changedParams'=>{'file'=>$where->{'filename'}})
				.$where->getTitle()
				."</a>\")";
		} else {
			$val = $pset;
			$whered = gettext("(system default)");
		}
	}
	return ("<i>".&{$namecode}($val)."</i>".$separator.$whered);
}

sub setProperty {
	my $self = shift;
	my $property = shift;
	my $value = shift;

	if (defined($value) and ($value ne '')) {
		$self->{$property} = $value;
		if ($property eq 'Title') {
			# keep track if title changes after file is loaded;
			# used to update items whose cached representations
			# depend on this item's title (because those items have
			# embedded faqomatic: references to this one).
			$self->{'titleChanged'} = 1;
		}
	} else {
		delete $self->{$property};
	}
}

sub getProperty {
	my $self = shift;
	my $property = shift;

	return $self->{$property};
}

sub getDirPart {
	my $self = shift;

	if (defined $self->{'directoryHint'}) {
		return $self->{'Parts'}->[$self->{'directoryHint'}];
	} else {
		return undef;
	}
}

sub makeDirectory {
	# This sub guarantees that this item contains a directory part,
	# creating an empty one if there wasn't already one.
	# It returns the dirpart.
	my $self = shift;

	return $self->getDirPart() if $self->getDirPart();

	my $dirPart = new FAQ::OMatic::Part();
	# should set author for $newPart to user doing this action
	$dirPart->{'Type'} = 'directory';
	$dirPart->{'Text'} = '';
	$dirPart->{'HideAttributions'} = 1;	# directories prefer to have
										# attributions hidden.
	$self->{'directoryHint'} = scalar @{$self->{'Parts'}};
	push @{$self->{'Parts'}}, $dirPart;

	return $dirPart;
}

sub addSubItem {
	my $self = shift;
	my $subfilename = shift;
	my $deferUpdate = shift || '';

	my $dirPart;

	my $subitem = new FAQ::OMatic::Item($subfilename);
	if ($subitem->isBroken()) {
		FAQ::OMatic::gripe('problem', gettexta("File %0 seems broken.", $subfilename));
	}

	$self->makeDirectory()->mergeDirectory($subfilename);

	# all the children in the list may now have different siblings,
	# which means we need to recompute their dependencies and
	# regenerate their cached html.
	if (!$deferUpdate) {
		$self->updateAllChildren();
	}

	$self->incrementSequence();
}

sub removeSubItem {
	my $self = shift;
	my $subfilename = shift; # if omitted, this just removes an empty
							 # directory part.
	my $deferUpdate = shift || '';

	my $dirPart = $self->getDirPart();
	if (not defined $dirPart) {
		FAQ::OMatic::gripe('panic', "FAQ::OMatic::Item::removeSubItem(): I ("
			.$self->{'filename'}
			.") don't have a directoryHint! How did that happen?");
	}
	if ($subfilename) {
		$dirPart->unmergeDirectory($subfilename);

		# all the children in the list may now have different siblings,
		# which means we need to recompute their dependencies and
		# regenerate their cached html.
		if (!$deferUpdate) {
			$self->updateAllChildren();
		}
	}

# I'm not sure why I thought automatically converting categories to answers
# when their directories become empty was a good idea. When the trash is
# emptied, it becomes an answer. If you empty a category, and expect
# to refill it with moves, you won't see your category in the (default)
# move target list anymore. That would be confusing. Hmmm.
#	if ($dirPart->{'Text'} =~ m/^\s*$/s) {
#		splice @{$self->{'Parts'}}, $self->{'directoryHint'}, 1;
#		delete $self->{'directoryHint'};
#	}

	$self->incrementSequence();
}

sub extractWordsFromString {
	my $string = shift;
	my $filename = shift;
	my $words = shift;

	my @wordlist = FAQ::OMatic::Words::getWords( $string );

	# Associate words with this file in index
	my $i;
	foreach $i (@wordlist) {
		# do it for every prefix, too
		my $prefix;
		foreach $prefix ( FAQ::OMatic::Words::getPrefixes( $i ) ) {
			$words->{$prefix}{$filename} = 1;
		}
	}
}

sub extractWords {
	my $self = shift;
	my $words = shift;

	extractWordsFromString($self->getTitle(), $self->{'filename'}, $words);

	my $part;
	foreach $part (@{$self->{'Parts'}}) {
		extractWordsFromString($part->{'Text'}, $self->{'filename'}, $words);
	}
	
	# recurse (turned off -- see buildSearchDB)
	# my $dirPart = $self->getDirPart();
	# if (defined $dirPart) {
	# 	my $filei;
	# 	my $itemi;
	# 	foreach $filei ($dirPart->getChildren()) {
	# 		$itemi = new FAQ::OMatic::Item($filei);
	# 		$itemi->extractWords($words);
	# 	}
	# }
}

sub rightEnd {
    my $string = shift;
    my $amount = shift;
    my $encode_lang = FAQ::OMatic::I18N::language();
#EUC-JP case
    return rightEndMB($string,$amount) if($encode_lang eq "ja_JP.EUC");
#normal case
    return rightEndSB($string,$amount);
}

sub rightEndSB {
    my $string = shift;
    my $amount = shift;
    if ($amount >= length($string)) {
	return $string;
    } else {
	return substr($string,length($string)-$amount,$amount);
    }
}

sub rightEndMB {
	my $string = shift;
	my $amount = shift;
	my ($n, $c, $r, $mb, $width, $result);
	$width = length($string) - $amount;
	if ($amount >= length($string)) {
		return $string;
	} else {
            while (length($string)) {
               last unless ($mb = $string =~ s/^([\200-\377].)+//) ||
		 $string =~s/[\0-\177]+//;
	       $n = $width;
	       $n -= $width % 2 if $mb;
	       ($c,$r) = unpack("a$n a*", $&);
	       $width -= length($c);
	       $result .= $c;
	       last if length($r)
	   }
	    return ($r.$string);
	}
}

sub displaySearchContext {
	my $self = shift;
	my $params = shift;
	my $rows = [];
	my $text = "";
	my @contexts = ();
	my @pieces=();
	my @parts=();
	my @hw;
	my $wordmatch;
	my $i;
	my $count;

	my @highlightWordsFlag = ();
	if (not ($FAQ::OMatic::Config::disableSearchHighlight || '')) {
		@highlightWordsFlag = (
			'_highlightWords'	=>	join(' ', @{$params->{'_searchArray'}})
		);
	}
	# start with a title that's a link
	push @$rows, { 'type'=>'wide', 'text'=>
		FAQ::OMatic::makeAref('-command'=>'faq',
			'-params'=>$params,
			'-changedParams'=>
			{	'file'				=>	$self->{'filename'},
				@highlightWordsFlag
				#'_highlightWords'	=>	join(' ', @{$params->{'_searchArray'}})
			})
			.FAQ::OMatic::highlightWords($self->getTitle(),$params)."</a>",
		'id'=>'displaySearchContext-title' };

	# add some context
	# get all of my parts' text
	$text = join(" ",
		map { $_->{'Text'} } @{$self->{'Parts'}});

	# contstruct the wordmatch regular expression that matches any
	# of the search words, with apostrophes interspersed.
	@hw = @{ $params->{'_searchArray'} };
	@hw = map { FAQ::OMatic::lotsOfApostrophes($_) } @hw;
	$wordmatch = '(\W'.join(')|(',@hw).')';

	$text = ' '.$text;	# ensure we match at beginning of text (because of \s)

	@pieces = split(/$wordmatch/is, $text);	# break into pieces
		# THANKS to John Goerzen <jgoerzen@complete.org>
		# and THANKS to Colin Watson <cjwatson@debian.org>
		# for reporting the fix on the previous line for a Perl 5.8 warning
		# that turns into an error.
	# save only the defined parts, so it alternates between match and nonmatch
	foreach $i (@pieces) {
		if (defined $i) {
			push @parts, $i;
		}
	}

	# now all even @parts are non-match, all odd are matches
	# whenever an even part is shorter than 20 characters, merge
	# it and its neighbors.
	for ($i=2; ($i<scalar(@parts)-1); $i+=2) {
		if (length($parts[$i]) < 20) {
			splice(@parts, $i-1, 3, $parts[$i-1].$parts[$i].$parts[$i+1]);
			$i = $i - 2;
		}
	}

	for ($i=1, $count=0; $i<scalar @parts and $count<4; $i+=2, $count++) {
		my $ls = ($i-1 >= 0) ? $parts[$i-1] : '';
		my $rs = ($i+1 < scalar(@parts)) ? $parts[$i+1] : '';
		my $ltrunc = (($i>1) or length($ls)>40);
		my $rtrunc = (($i<scalar(@parts)-2) or length($rs)>40);
		push @contexts,
			FAQ::OMatic::entify(
				($ltrunc ? '...' : '')
				.rightEnd($ls,40)
				.' '
				.$parts[$i]
				.substrFOM($rs,40)
				.($rtrunc ? '...' : ''));
	}
	my $context = join("\n<br>", @contexts);

	# highlight the matching words
	push @$rows, { 'type'=>'wide',
		'text'=>FAQ::OMatic::highlightWords($context,$params),
		'id'=>'displaySearchContext-text' };

	return { 'item'=>$self, 'rows'=>$rows };
}

sub notifyModerator {
	my $self = shift;
	my $cgi = shift;
	my $didWhat = shift;
	my $changedPart = shift;

	my $mail = FAQ::OMatic::Auth::getInheritedProperty($self, 'MailModerator')
				|| '';
	return if ($mail ne '1');	# didn't want mail anyway

	my $moderator = FAQ::OMatic::Auth::getInheritedProperty($self, 'Moderator');
	return if (not $moderator =~ m/\@/);	# some non-address

	my $msg = '';
	my ($id,$aq) = FAQ::OMatic::Auth::getID();

	if ($id eq $moderator
		and $didWhat =~ m/moderator options/) {
		return;
		# moderator doesn't need to get mail about his own edits
		# THANKS to Bernhard Scholz <scholz@peanuts.org> for the suggestion
	}

	$msg .= "[This is a message about the Faq-O-Matic items you moderate.]\n\n";
	$msg .= "Who:      $id\n";
	$msg .= "Item:     ".$self->getTitle()."\n";
	$msg .= "File:     ".$self->{'filename'}."\n";
	my $url = FAQ::OMatic::makeAref('-command'=>'faq',
			# sleazy hack that will bite me later -- go ahead and use
			# global params, because that's always "okay" here.
			#'-params'=>$params,
			'-changedParams'=>{'file'=>$self->{'filename'}},
			'-reftype'=>'url',
			'-blastAll'=>1);
	$msg .= "URL:      ".$url."\n";
	$msg .= "What:     ".$didWhat."\n";

	if (defined $changedPart) {
		$msg .= "New text:\n";
		$msg .= FAQ::OMatic::quoteText($self->getPart($changedPart)->{'Text'},
			'> ');
	}

	$msg .= "\nAs always, thanks for your help maintaining the FAQ.\n";

	# make sure $moderator isn't a trick string
	$moderator = FAQ::OMatic::validEmail($moderator);
	if (defined($moderator)) {
		# send the mail to the moderator
		# pageHeader is added to tell which FAQ has sent the mail.  
		# THANKS suggested by Akiko Takano <takano@iij.ad.jp>
		FAQ::OMatic::sendEmail($moderator, 
			"[" . FAQ::OMatic::fomTitle() . "] Faq-O-Matic Moderator Mail",
			$msg);
	} else {
		FAQ::OMatic::gripe('problem',
			"Moderator address is suspect ($moderator)");
	}
}

sub notifyNotifier {
	my $self = shift;
	my $cgi = shift;
	my $didWhat = shift;
	my $changedPart = shift;

	my $mail = FAQ::OMatic::Auth::getInheritedProperty($self, 'MailNotifier')
				|| '';
	return if ($mail ne '1');	# didn't want mail anyway

	my $moderator = FAQ::OMatic::Auth::getInheritedProperty($self, 'Notifier');
	return if (not $moderator =~ m/\@/);	# some non-address

	my $msg = '';
	my ($id,$aq) = FAQ::OMatic::Auth::getID();

	if ($id eq $moderator
		and $didWhat =~ m/moderator options/) {
		return;
		# moderator doesn't need to get mail about his own edits
		# THANKS to Bernhard Scholz <scholz@peanuts.org> for the suggestion
	}

	$msg .= "[This is a notification about the Faq-O-Matic items you have subscribed to.]\n\n";
	$msg .= "Who:      $id\n";
	$msg .= "Item:     ".$self->getTitle()."\n";
	$msg .= "File:     ".$self->{'filename'}."\n";
	my $url = FAQ::OMatic::makeAref('-command'=>'faq',
			# sleazy hack that will bite me later -- go ahead and use
			# global params, because that's always "okay" here.
			#'-params'=>$params,
			'-changedParams'=>{'file'=>$self->{'filename'}},
			'-reftype'=>'url',
			'-blastAll'=>1);
	$msg .= "URL:      ".$url."\n";
	$msg .= "What:     ".$didWhat."\n";

	if (defined $changedPart) {
		$msg .= "New text:\n";
		$msg .= FAQ::OMatic::quoteText($self->getPart($changedPart)->{'Text'},
			'> ');
	}

	$msg .= "\nAs always, thanks for your help maintaining the FAQ.\n";

	# make sure $moderator isn't a trick string
	$moderator = FAQ::OMatic::validEmail($moderator);
	if (defined($moderator)) {
		# send the mail to the moderator
		# pageHeader is added to tell which FAQ has sent the mail.  
		# THANKS suggested by Akiko Takano <takano@iij.ad.jp>
		FAQ::OMatic::sendEmail($moderator, 
			"[" . FAQ::OMatic::fomTitle() . "] " . $self->getTitle().":".$didWhat,
			$msg);
	} else {
		FAQ::OMatic::gripe('problem',
			"Moderator address is suspect ($moderator)");
	}
}

# item in the parent's list
sub getSiblings {
	my $self = shift;
	my ($prev, $next);

	my $parent = $self->getParent();
	return (undef,undef) if (not $parent);
	my @siblings = $parent->getChildren();
	my $i;
	for ($i=0; $i<@siblings; $i++) {
		if ($siblings[$i] eq $self->{'filename'}) {
			$prev = ($i>0) ? $siblings[$i-1] : undef;
			$next = ($i<@siblings-1) ? $siblings[$i+1] : undef;
			return ($prev,$next);
		}
	}
	return (undef,undef);
}

sub isCategory {
	my $self = shift;
	return (defined $self->{'directoryHint'}) ? 1 : 0;
}

# added for convenient reasons
sub isAnswer {
	my $self = shift;
	return !($self->isCategory());
}

sub whatAmI {
	# do not translate here; translate just before output.
	# (There is code that tests for string equality based on the
	# output of this function. Maybe that's stupid.)
	my $self = shift;

	return gettext_noop("Category")	if ($self->isCategory());
	return gettext_noop("Answer")	if ($self->isAnswer());

	# unreachable
	gripe('problem',
		  'Internal error #20010805-1843: unreachable code is reached',
		  1);
	return "(Unexpected item type)";
}

sub updateDirectoryHint {
	my $self = shift;

	my $i;
	for ($i=0; $i<$self->numParts(); $i++) {
		if ($self->getPart($i)->{'Type'} eq 'directory') {
			$self->{'directoryHint'} = $i;
			return;
		}
	}
	delete $self->{'directoryHint'};
}

sub clone {
	# return a deep-copy of myself
	my $self = shift;

	my $newitem = new FAQ::OMatic::Item();

	# copy all of prototype's attributes
	my $key;
	foreach $key (keys %{$self}) {
		next if ($key eq 'Parts');
		if ($key =~ m/-Set$/) {
			$newitem->{$key} = $self->{$key}->clone();
		} elsif (ref $self->{$key}) {
			# guarantee this is a deep copy -- if we missed
			# a ref, complain.
			FAQ::OMatic::gripe('error', "clone: prototype has key '$key' "
				."that is a reference (".$self->{$key}.").");
		}
		$newitem->{$key} = $self->{$key};
	}

	# copy all the parts...
	my $i;
	for ($i=0; $i<$self->numParts(); $i++) {
		push(@{$newitem->{'Parts'}}, $self->getPart($i)->clone());
	}

	$newitem->updateDirectoryHint();

	return $newitem;
}

sub checkSequence {
	my $self = shift;
	my $params = shift;

	my $checkSequenceNumber =
		defined($params->{'checkSequenceNumber'})
		? $params->{'checkSequenceNumber'}
		: -1;
	if ($checkSequenceNumber ne $self->{'SequenceNumber'}) {
		my $button = FAQ::OMatic::button(
			FAQ::OMatic::makeAref('-command'=>'faq',
				'-params'=>$params,
				'-changedParams'=>{'partnum'=>'', 'checkSequenceNumber'=>''}
			),
			gettext("Return to the FAQ"));
		FAQ::OMatic::gripe('error',
			gettext("Either someone has changed the answer or category you were editing since you received the editing form, or you submitted the same form twice.")
			."\n<p>"
			.gettexta("Please %0 and start again to make sure no changes are lost. Sorry for the inconvenience.",
					  $button)
			."<p>"
			.gettexta("(Sequence number in form: %0; in item: %1)",
				  $checkSequenceNumber, $self->{'SequenceNumber'}),
				{'noentify'=>1}
			);
	}
}

sub incrementSequence {
	my $self = shift;

	$self->setProperty('SequenceNumber', $self->{'SequenceNumber'}+1);
}

sub substrFOM {
    my $string = shift;
    my $width = shift;
    my $result = shift;
    my $encode_lang = FAQ::OMatic::I18N::language();
#EUC-JP case
    return substrMB($string,$width,$result) if($encode_lang eq "ja_JP.EUC");
#normal case
    return substr($string,$width,$result);

}

sub substrMB {
        my $string = shift;
        my $width = shift;
        my $result = shift;
        my ($n, $c, $r, $mb);
        while (length($string)){
           last unless ($mb = $string =~ s/^([\200-\377].)+//)
            || $string =~ s/[\0-\177]+//;
                $n = $width;
                $n -= $width % 2 if $mb;
                ($c,$r) = unpack("a$n a*", $&);
                $width -= length($c);
                $result .= $c;
                last if length($r);
       }
        return $result;
} # end of sub substrJ..
1;
