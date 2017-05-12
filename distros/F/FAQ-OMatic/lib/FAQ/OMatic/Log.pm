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

##
## FaqLog.pm -- access logging facilities
##

package FAQ::OMatic::Log;

use FAQ::OMatic;
use Time::Local;

# given 'YYYY-MM-DD' and a number of days, return a 'YYYY-MM-DD' that far
# away.
sub adddays {
	my $date = shift;		# YYYY-MM-DD
	my $daydiff = shift;	# int
	my ($year,$mo,$day) = split('-',$date);
	my (@localt) = (0,0,9,$day,$mo-1,$year-1900);
		# I use 9:00 AM because 24 hours before midnight 1997-04-07 is
		# 11 pm 1997-04-05, which is not what I meant. Darn DST. Watch
		# out for that.

	my $unixtime = Time::Local::timelocal(@localt);
	my ($sec2,$min2,$hr2,$day2,$mo2,$yr2,$wday2,$yday2,$isdst2) =
		localtime($unixtime+3600*24*$daydiff);
	return sprintf("%04d-%02d-%02d",
				$yr2+1900, $mo2+1, $day2);
}

# man, why doesn't anybody ever include this or max or min in their
# dumb libraries?
sub round {
	my $arg = shift;
	return ($arg < 0) ? int($arg-0.5) : int($arg+0.5);
}

# give the difference in days between two given days in 'YYYY-MM-DD' form
sub subTwoDays {
	my $day1 = shift;	# YYYY-MM-DD
	my $day2 = shift;	# YYYY-MM-DD

	my ($y,$m,$d) = split('-', $day1);
	my @localt = (0,0,9,$d,$m-1,$y-1900);
	my $unixt1 = Time::Local::timelocal(@localt);

	my ($y2,$m2,$d2) = split('-', $day2);
	my @localt2 = (0,0,9,$d2,$m2-1,$y2-1900);
	my $unixt2 = Time::Local::timelocal(@localt2);

	return round(($unixt1 - $unixt2)/86400);
}

# return today in 'YYYY-MM-DD' form
sub numericToday {
	my ($sec,$min,$hr,$day,$mo,$yr,$wday,$yday,$isdst) = localtime(time());
	return sprintf("%04d-%02d-%02d",
				$yr+1900, $mo+1, $day);
}

# return today in 'YYYY-MM-DD-HH-MM' form
sub numericDate {
	my ($sec,$min,$hr,$day,$mo,$yr,$wday,$yday,$isdst) = localtime(time());
	return sprintf("%04d-%02d-%02d-%02d-%02d-%02d",
				$yr+1900, $mo+1, $day, $hr, $min, $sec);
}

sub logEvent {
	my $params = shift;

	my $date = numericDate();
	my $host = $ENV{'REMOTE_HOST'} || 'unknown-host';
	$host = '-' if ($host eq '');
	my $prog = FAQ::OMatic::commandName();
	my $args = $params->{'file'} || '';
	my $browser = $ENV{'HTTP_USER_AGENT'} || 'unknown-agent';
	$browser =~ s/\s//g;

	$args .= "/".$params->{'partnum'}
		if (defined $params->{'partnum'});

	my $logfile = $FAQ::OMatic::Config::metaDir."/".numericToday().".rawlog";
	if (not open LOG, ">>$logfile") {
		FAQ::OMatic::gripe('problem',
			"FAQ::OMatic::Log::logEvent: The access logging system is "
			."not working. open failed ($!)");
		return;
	}
	print LOG "$date $host $prog $args $browser\n";
	close LOG;
}

sub summarizeDay {
	my $date = shift;
	$date = numericToday() if (not $date);	# summarize today
	my $prevdate = adddays($date, -1);
	my %uniquehosts;

	$date =~ m/([\d-]*)/;		# untaint $date
	$date = $1;

	#$ENV{'IFS'} = '';
	#$ENV{'PATH'} = '';
	# First, copy the unique hosts database from the previous day to today
	if ($FAQ::OMatic::Config::statUniqueHosts) {
		my $dbfile;
		foreach $dbfile (FAQ::OMatic::safeGlob($FAQ::OMatic::Config::metaDir,
					"^$prevdate.uhdb")) {
			my $newname = $dbfile;
			$newname =~ s#/$prevdate#/$date#;
			my @msrc = FAQ::OMatic::mySystem("cp $dbfile $newname");
			if (scalar(@msrc)) {
				FAQ::OMatic::gripe('note',
				"FAQ::OMatic::Log::summarizeDay: cp $dbfile $newname failed: "
					.join(', ', @msrc));
				# assume yesterday is just plain broken, and start fresh
				my $file;
				foreach $file (FAQ::OMatic::safeGlob(
								$FAQ::OMatic::Config::metaDir,
								"^$date.uhdb")) {
					unlink $file;
				}

				# touch the dbm files so we'll see them later
				if (not dbmopen(%uniquehosts,
						"$FAQ::OMatic::Config::metaDir/$date.uhdb", 0600)) {
					FAQ::OMatic::gripe('abort',
		"FAQ::OMatic::Log::summarizeDay: Can't create $FAQ::OMatic::Config::metaDir/$date.uhdb");
				}
				dbmclose %uniquehosts;
				last;
			}
		}
	}

	# now open $date's dbfile and insert the new hosts as we compute the
	# other statistics for the day.
	if ($FAQ::OMatic::Config::statUniqueHosts) {
		if (not dbmopen(%uniquehosts,
				"$FAQ::OMatic::Config::metaDir/$date.uhdb", 0400)) {
			FAQ::OMatic::gripe('abort',
				"FAQ::OMatic::Log::summarizeDay: Couldn't open "
				."dbm file $FAQ::OMatic::Config::metaDir/$date.uhdb. ($!)");
		}
	}

	# recycle nice hashed property mechanism of FAQ::OMatic::Items for summaries
	my $oldItem = new FAQ::OMatic::Item("$prevdate.smry", $FAQ::OMatic::Config::metaDir);
	my $item = new FAQ::OMatic::Item();
	$item->setProperty('Title', 'Faq-O-Matic Access Summary');

	# treat missing logs as very uninteresting days
	if (open LOG, "$FAQ::OMatic::Config::metaDir/$date.rawlog") {
		while (defined($_=<LOG>)) {
			chomp;
			my ($date,$host,$op,$arg) = split(' ');
			$host = '' if (not defined $host);
			#$op =~ s/\.pl$//;	# '.pl' suffix is ugly, 'pl' is worse
			$op =~ s/\W//g;		# prevent bogus property keys
			if ($FAQ::OMatic::Config::statUniqueHosts) {
				# TODO: still not sure how to keep this from producing
				# bogus warnings.
				$uniquehosts{$host} = 1;
			}
			$item->{"Operation-$op"}++;
			$item->{'Hits'}++;
		}
		close LOG;
	}

	# store unique hosts stats
	if ($FAQ::OMatic::Config::statUniqueHosts) {
		my $oldCum = $oldItem->{'CumUniqueHosts'} || 0;
		$item->{'CumUniqueHosts'} = scalar(keys %uniquehosts);
		$item->{'UniqueHosts'} = $item->{'CumUniqueHosts'} - $oldCum;
	}

	# compute cumulative stats for Operations and Hits
	my %opnames=('Hits'=>1);
	my $key;
	foreach $key (keys %{$oldItem}) {
		$opnames{$key}=1 if ($key =~ m/^Oper/);
		$key =~ s/^Cum//;
		$opnames{$key}=1 if ($key =~ m/^Oper/);
	}
	foreach $key (keys %{$item}) {
		$opnames{$key}=1 if ($key =~ m/^Oper/);
	}
	foreach $key (keys %opnames) {
		my $newv = $item->{$key} || 0;
		my $oldc = $oldItem->{"Cum$key"} || 0;
		$item->{"Cum$key"} = $newv + $oldc;
		$item->{$key} = 0 if (not defined $item->{$key});
	}

	# compute derived stats
	if (($item->{'CumUniqueHosts'}||0) != 0) {
		$item->{'HitsPerHost'} = $item->{'CumHits'} / $item->{'CumUniqueHosts'};
	} else {
		$item->{'HitsPerHost'} = 0;
	}

	$date =~ m/^([\d-]*)$/;
	$date = $1;
	$item->saveToFile("$date.smry", $FAQ::OMatic::Config::metaDir);
	if ($FAQ::OMatic::Config::statUniqueHosts) {
		dbmclose(%uniquehosts);
		#dbmclose %uniquehosts
	}
}

# return the 'YYYY-MM-DD' of the earliest .smry file in metaDir.
sub earliestSmry {
	my $direntry;
	my $earliest;
	undef $earliest;

	# check for a hint
	if (open(HINT, "<$FAQ::OMatic::Config::metaDir/earliestLogHint")) {
		$earliest = <HINT>;
		chomp $earliest;
		close HINT;
	}

	# make sure the hint is valid
	if ((not defined $earliest) or
		(not -f "$FAQ::OMatic::Config::metaDir/$earliest.smry")) {

		# rediscover the earliest .smry
		$earliest = 'Z';	# should sort before anything
		opendir META, $FAQ::OMatic::Config::metaDir;
		while (defined($direntry = readdir META)) {
			next if (not $direntry =~ m/\.smry$/);
			$direntry =~ s/\.smry$//;
			$earliest = $direntry if ($direntry lt $earliest);
		}
		closedir META;
		return (undef) if ($earliest eq 'Z');

		# write out the hint
		if (open(HINT, ">$FAQ::OMatic::Config::metaDir/earliestLogHint")) {
			print HINT "$earliest\n";
			close HINT;
		}
	}

	return $earliest;
}

sub rebuildAllSummaries {
	# TODO:
	# notice we start at earliestSmry -- not the earliest rawlog. If
	# we weren't lame, we'd figure out the earliest rawlog and work from
	# there.
	my $earliest = earliestSmry();
	my $today = numericToday();
	my $dayi;

	for ($dayi=$earliest; $dayi lt $today; $dayi = adddays($dayi, 1)) {
		summarizeDay($dayi);

		my $twoDaysAgo = adddays($dayi, -2);
		# delete those uhdbs
	}
}

1;
