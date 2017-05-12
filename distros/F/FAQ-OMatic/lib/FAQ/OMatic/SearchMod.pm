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

### SearchMod.pm
###
### Support for search functions
###

package FAQ::OMatic::SearchMod;

use FAQ::OMatic::Item;
use FAQ::OMatic::I18N;
use FAQ::OMatic::Words;
use FAQ::OMatic;

sub openWordDB {
	return if (defined FAQ::OMatic::getLocal('wordDB'));
	my $wordDBtoken;
	if (FAQ::OMatic::usedbm()) {
		my %wordDB;
		if (not dbmopen (%wordDB, "$FAQ::OMatic::Config::metaDir/search", 0400)) {
			FAQ::OMatic::gripe('abort', "Can't open dbm search database. "
				."Have you run buildSearchDB? (Should I?)");
		}
		$wordDBtoken = \%wordDB;
	} else {
		if (not open(OFFSETFILE, "<$FAQ::OMatic::Config::metaDir/search.offset")) {
			FAQ::OMatic::gripe('abort', "Can't open search.offset. "
				."Have you run buildSearchDB? (Should I?)");
		}
		$wordDBtoken = "files_are_open_yahoo!";
	}
	if (not open(WORDSFILE, "<$FAQ::OMatic::Config::metaDir/search.words")) {
		FAQ::OMatic::gripe('abort', "Can't open search.words. "
			."Have you run buildSearchDB? (Should I?)");
	}
	if (not open(INDEXFILE, "<$FAQ::OMatic::Config::metaDir/search.index")) {
		FAQ::OMatic::gripe('abort', "Can't open search.index. "
			."Have you run buildSearchDB? (Should I?)");
	}
	FAQ::OMatic::setLocal('wordDB', $wordDBtoken);
}

sub closeWordDB {
	my $wordDB = FAQ::OMatic::getLocal('wordDB');
	if (FAQ::OMatic::usedbm()) {
		dbmclose %{$wordDB};
		undef %{$wordDB};
	} else {
		close OFFSETFILE;
	}
	close WORDSFILE;
	close INDEXFILE;
}

# linear scan of .offset file, looking for $word. Pretty slow,
# unless your dbm implementation is somehow very slow and broken,
# as on sourceforge.
sub scanOffsets {
	my $word = shift;
	seek (OFFSETFILE, 0, 0);
	my $line;
	# THANKS to Gary.Frost@ubsw.com for reporting the "Value of
	# <HANDLE> construct can be "0"" error that occurs on his version
	# of perl; fixed here and elsewhere.
	while (defined($line = <OFFSETFILE>)) {
		chomp $line;
		my ($fileWord, $pair) = split(' ', $line, 2);
		if ($fileWord eq $word) {
			#FAQ::OMatic::gripe('debug', "found pair: $line");
			return $pair;
		}
	}
	return undef;
}

sub getIndices {
	my $word = shift;
	my $pair;
	if (FAQ::OMatic::usedbm()) {
		my $wordDB = FAQ::OMatic::getLocal('wordDB');
		$pair = $wordDB->{$word};
	} else {
		$pair = scanOffsets($word);
	}

	# returns indexseek,wordseek pair
	# THANKS to Vicki Brown <vlb@cfcl.com> and jon * <jon@clearink.com>
	# for reporting unitialized value errors in this code.
	return defined($pair)
		? split(' ', $pair)
		: (undef,undef);
}

sub getWordClass {
	my $word = shift;
	my @wordclass = ();

	openWordDB();
	
	my ($indexseek, $wordseek) = getIndices($word);
	#FAQ::OMatic::gripe('debug', "got seeks $indexseek and $wordseek for $word");

	if (defined $indexseek) {
		#grab all words in wordsfile with $word as a prefix
		seek WORDSFILE, $wordseek, 0;
		while (defined($_ = <WORDSFILE>)) {
			chomp;
			if (m/^$word/) {
				push @wordclass, $_;
			} else {
				last;
			}
		}
	}

	return \@wordclass;
}

sub getMatchesForClass {
	my $classref = shift;	# array ref for a class of "identical" words
	my %files;

	my $word;
	foreach $word (@{$classref}) {
		my ($indexseek,$wordseek) = getIndices($word);
		next if (not defined $indexseek);
		seek INDEXFILE, $indexseek, 0;
		while (defined($_ = <INDEXFILE>)) {
			chomp;
			last if (m/^END$/);
			$files{$_}=1;
		}
	}

	my @matches = sort keys %files;
	return \@matches;
}

sub getMatchesForSet {
	my $params = shift;
	my $setref = $params->{'_searchArray'};
							# array ref for complete set of user words to search

	$params->{'_minMatches'} = 'all' if ($params->{'_minMatches'} eq '');
	my $minhits = $params->{'_minMatches'};
							# we return only files with at least this many hits
	if ($minhits eq 'all') {	# convert symbolic hits to a number
		$minhits = scalar(@{$setref});
	}
	$params->{'_actualMatches'} = $minhits;

	my %accumulator=();
	my @hitfiles=();

	my ($word, $file);
	foreach $word (@{$setref}) {
		my $classref = getWordClass($word);
		my $matches = getMatchesForClass($classref);
		foreach $file (@{$matches}) {
			$accumulator{$file}++;
		}
	}

	foreach $file (sort keys %accumulator) {
		if ($accumulator{$file} >= $minhits) {
			push @hitfiles, $file;
		}
	}

	return \@hitfiles;
}

sub convertSearchParams {
	my $params = shift;
	my $pattern;
        my $encode_lang = FAQ::OMatic::I18N::language();

	# given a user-input search string, we break it into "legal" words
	# and store it in another parameter.
	
	$pattern = $params->{'_search'};
	if($encode_lang eq "ja_JP.EUC") {
	    require NKF; import NKF;
	    $pattern = nkf('-e', $pattern);
        }
	my @patternwords = FAQ::OMatic::Words::getWords( $pattern );

	$params->{'_searchArray'} = \@patternwords;
}

sub addNewFiles {
	my $wordset = shift;	#ary ref
	my $fileset = shift;	# hash ref -- where to add results
	my $words = {};

	# Get the list of files touched since last searchDB build
	if (not open HINTS, "<$FAQ::OMatic::Config::metaDir/searchHints") {
		# sorry, can't help ya
		return;
	}
	my @touchedFiles = <HINTS>;
	close HINTS;

	# index each item
	my $filename;
	my $item;
	foreach $filename (@touchedFiles) {
		chomp $filename;
		$item = new FAQ::OMatic::Item($filename);
		$item->extractWords($words);
	}

	# for every word in the wordset, add all the files it appears
	# in to the fileset passed to us.
	my $word;
	foreach $word (@{$wordset}) {
		if ($words->{$word}) {
			foreach $filename (keys %{$words->{$word}}) {
				$fileset->{$filename} = 1;
			}
		}
	}

	# notice that if there were suffixes of the user's requested words
	# in the new content that weren't in the system anywhere when the
	# searchDB was built, then those suffixes won't be in the wordset,
	# and the search will miss them. Hey, wah, this is better than
	# missing ALL the new content, okay? :v)

	# this also screws up the counts of how many matches this file
	# had (since it could contribute matches from the searchDB lookup
	# AND the newFiles lookup), so I'm going to leave it turned off
	# for now. Rats.
}

sub getRecentSet {
	my $params = shift;
	my $recentList = [];

	my $durationdays = $params->{'_duration'};
		# used directly to compare against perl's floating-point -M file test
	my $then = time() - $durationdays*24*60*60;
		# Used to compare against LastModifiedSecs field.
		# By 'days' we mean 24-hour periods, not calendar days.
		# (In the US, for example, there is a 23-hour calendar day in
		# April and a 25-hour one in the fall, what, in October? for daylight
		# savings time.)

	my $filei;
	foreach $filei (FAQ::OMatic::getAllItemNames()) {
		# use file time as a hint for which items we even need to open up.
		next if (-M "$FAQ::OMatic::Config::itemDir/$filei" >= $durationdays);
		# ...but only trust LastModifiedSecs field for final say on mod time.
		my $item = new FAQ::OMatic::Item($filei);
		my $lm = $item->{'LastModifiedSecs'} || 0;
		if ($lm > $then) {
			push @{$recentList}, $filei;
		}
	}

	return $recentList;
}

# reasonable text for 'n' days
my %dayMap = (
	0 => gettext("zero days"),
	1 => gettext("day"),
	2 => gettext("two days"),
	7 => gettext("week"),
	14 => gettext("fortnight"),
	31 => gettext("month"), # (31? a month, give or take. :v)
	92 => gettext("three months"),
	184 => gettext("six months"),
	366 => gettext("year")
);

sub getRecentMap {
	# get a copy of the day map (except for 0)
	# for use in creating the recent form
	my %recentMap = %dayMap;
	delete $recentMap{0};
	return \%recentMap;
}

sub textDays {
	my $duration = shift || 0;
	my $textDayStr = $dayMap{$duration} || $duration." ".gettext("days");
	return $textDayStr;
}

1;
