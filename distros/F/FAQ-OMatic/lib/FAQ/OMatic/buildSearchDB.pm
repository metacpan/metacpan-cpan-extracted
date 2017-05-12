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

package FAQ::OMatic::buildSearchDB;

use FAQ::OMatic::Item;
use FAQ::OMatic;

sub build {
	my $words = {};

	# Notice we don't bother doing this recursively -- faqs
	# can be in a state where not everybody shares a common root.
	# (This does search the trash, however, which is not necessarily
	# what you want.)
	# Mental note: If I switch back to recursive search from a common
	# root, I should remember to turn the recursion back on in
	# FAQ::OMatic::Item::extractWords.
	my @allItems = FAQ::OMatic::getAllItemNames();
	my $filename;
	my $item;
	localhprint("beginning scan");
	foreach $filename (@allItems) {
		localhprint("scanning $filename");
		$item = new FAQ::OMatic::Item($filename);
		if ($item->isEmptyStub()) {
			# pass over it.
		} elsif ($item->isBroken()) {
			FAQ::OMatic::gripe('debug', 'item/'.$filename.' is broken.');
		} else {
			$item->extractWords($words);
		}
	}

	my @wordlist = sort keys %{$words};

	## Build the files in temporaries, so searching still works during the
	## re-extraction. In fact, a running search process will continue to
	## use the old ones (and not get confused when we mv in the new ones)
	## because of Unix' cool file semantics.

	my %wordsdb;
	my $searchFileName = 'search.'.FAQ::OMatic::nonce();
	my $searchFilePath = $FAQ::OMatic::Config::metaDir.'/'.$searchFileName;
	my $usedbm = FAQ::OMatic::usedbm();
	if ($usedbm) {
		dbmopen (%wordsdb, $searchFilePath, 0600);
		# perl sure is touchy about its octal literals
	} else {
		open OFFSETFILE, ">${searchFilePath}.offset"
			|| die "${searchFilePath}.offset $!";
	}
	open(INDEXFILE, ">${searchFilePath}.index")
		|| die "${searchFilePath}.index $!";
	open(WORDSFILE, ">${searchFilePath}.words")
		|| die "${searchFilePath}.words $!";

	localhprint("squirting words into ${searchFilePath}");
	foreach my $i (@wordlist) {
		## Write down in the hash the file pointer where we can find
		## this entry:
		if ($usedbm) {
			$wordsdb{$i} = (tell INDEXFILE)." ".(tell WORDSFILE);
		} else {
			# a very slow replacement for a direct-access database. Pfft.
			print OFFSETFILE "${i} ".(tell INDEXFILE)." ".(tell WORDSFILE)."\n";
		}
		## Then dump out all the items with this word in them:
		my @list = sort keys %{ $words->{$i} };
		foreach my $j (@list) {
			print INDEXFILE "$j\n";
		}
		## And append the word to the words file
		print WORDSFILE "$i\n";
		## terminate the list
		print INDEXFILE "END\n";
	}
	localhprint("squirting complete");

	if ($usedbm) {
		dbmclose %wordsdb;
	} else {
		close OFFSETFILE;
	}
	close INDEXFILE;
	close WORDSFILE;

	## make sure the files are readable
	# Using wildcards lets us remain ignorant of dbm's extension(s), which
	# vary machine to machine.
	my @searchfiles = FAQ::OMatic::safeGlob($FAQ::OMatic::Config::metaDir,
						"^${searchFileName}");

	foreach my $i (@searchfiles) {
		chmod 0644, $i;
	}

	# move temp files into place as the official search database
	foreach my $from (@searchfiles) {
		$from =~ m#${searchFileName}([^/]*)$#;
		my $suffix = $1;
		if (not defined $suffix) {
			die "Could not find suffix: $from !~ $searchFileName";
		}
		my $to = "${FAQ::OMatic::Config::metaDir}/search${suffix}";
		rename($from,$to) ||
			FAQ::OMatic::gripe('debug', "rename($from,$to) failed");
	}

	# create a freshSearchDBHint to let me know I don't need to do
	# this again any time soon.
	open SEARCHHINT, ">$FAQ::OMatic::Config::metaDir/freshSearchDBHint";
	close SEARCHHINT;
}

sub localhprint {
	my $msg = shift;
	FAQ::OMatic::maintenance::hprint("${msg}<br>\n");
	FAQ::OMatic::maintenance::hflush();
}

1;
