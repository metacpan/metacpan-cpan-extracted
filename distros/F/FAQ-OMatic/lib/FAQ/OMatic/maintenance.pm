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
## maintenance.pm
##
## This module should be invoked periodically by cron.
## It can be given an argument to run a specific task, or it will
## automatically determine which tasks to run.
##
## FAQ::OMatic::maintenance::main() (via the dispatch.pm CGI mechanism) will
##	make this script do its thing.
##
## FAQ::OMatic::maintenance::invoke(host, port, url) will request the url from the host.
##	Cron scripts should invoke me that way, which will cause the above
##	invocation (and make maintenance do its thing).

package FAQ::OMatic::maintenance;

use CGI;
use Socket;

use FAQ::OMatic;
use FAQ::OMatic::Log;
use FAQ::OMatic::Auth;
use FAQ::OMatic::buildSearchDB;
use FAQ::OMatic::Versions;
use FAQ::OMatic::ImageRef;
use FAQ::OMatic::Slow;
use FAQ::OMatic::I18N;

my $badKeyMessage = 'Bad maintenance key.';

sub main {
	my $cgi = FAQ::OMatic::dispatch::cgi();

	## Demand a secret key from the caller, so that we don't have
	## Joe Q. Random firing up umpteen copies of the mainenance script
	## and slowing things down. With the hints that keep it from doing
	## much very often, this probably doesn't matter, but anyway.
	if ($cgi->param('secret') ne $FAQ::OMatic::Config::maintenanceSecret) {
		print FAQ::OMatic::header($cgi, '-type'=>"text/plain");
		print "$badKeyMessage\n";
		return;
	}

	my $slow = '';
	my $tasks = $cgi->param('tasks') || '';
#	if ($tasks ne 'mirrorClient'
#		and $tasks ne 'rebuildCache') {
#		# (don't force out the header for Slow processes, which need
#		# to be able to redirect.)
#		hprint(FAQ::OMatic::header($cgi, '-type'=>'text/html'));
#		hprint("<title>FAQ-O-Matic Maintenance</title>\n");
#		hflush();
#			# just in case some other junk sneaks out on the fd
#	} else {
#		$slow = '-slow';	# tell task to run interactively
#	}

	# do everything in "slow" mode -- fork a process (so the web
	# server won't kill it), and redirect all output to a Slow file.
	my $fh = FAQ::OMatic::Slow::split();
	hSetFilehandle($fh);
	hprint("This is process ID ".$$."<p>\n");
	hflush();

	my %schedules = ('month'=>1,'week'=>1,'day'=>1,'hour'=>1);
	my @tasks = split(',', ($cgi->param('tasks')||''));
	if ((@tasks == 0) or ((@tasks == 1) and $schedules{$tasks[0]})) {
		@tasks = periodicTasks($tasks[0] || '');
	}

	my %taskUntaint = map {$_=>$_}
		( 'writeMaintenanceHint', 'trimUHDB', 'trimSubmitTmps',
		 'buildSearchDB', 'trim', 'cookies', 'errors', 'logSummary',
		 'rebuildAllSummaries', 'rebuildCache', 'expireBags', 'bagAllImages',
		 'mirrorClient', 'trimSlowOutput', 'emptyTrash', 'fsck');

		 #hprint("<pre>\n");
	foreach my $i (sort @tasks) {
		$i =~ s/\d+ //;
		if (defined $taskUntaint{$i}) {
			$i = $taskUntaint{$i};
			hprint("--- $i\n");
			hflush();
			if (not eval "$i(); return 1;") {
				FAQ::OMatic::gripe('problem',
					"*** Task $i failed\n    Error: $@\n");
				hprint("*** Task $i failed\n    Error: $@\n");
				hprint(FAQ::OMatic::stackTrace('html'));
				hflush();
			}
			hflush();
		} else {
			hprint("*** Task $i undefined\n");
			hflush();
		}
	}

	# output results
	hprint("\n</pre>\n");

	# provide a link to the install page, just for kicks
	FAQ::OMatic::getParams($cgi);
	hprint(FAQ::OMatic::button(
			FAQ::OMatic::makeAref('install', {}, ''),
			gettext("Go To Install/Configuration Page")));

	hflush();
}

sub hSetFilehandle {
	my $filehandle = shift;
	FAQ::OMatic::setLocal('maintenance-fh', $filehandle);
}

sub hprint {
	# I have no idea why I thought this should be a separate
	# function. I think because I wanted to have the output appear
	# as it was generated, but didn't want to have 'print' calls to
	# weed out if I ever changed how I did printing.
	my $html = FAQ::OMatic::getLocal('maintenance-html') || '';
	$html .= join('', @_);
	FAQ::OMatic::setLocal('maintenance-html', $html);
	# we don't flush until explicitly asked to. That way, if a routine
	# decides to Slow::split, it can get its redirect out before we
	# send out a header.
}

sub hflush {
	my $html = FAQ::OMatic::getLocal('maintenance-html') || '';
	my $filehandle = FAQ::OMatic::getLocal('maintenance-fh') || \*STDOUT;
	print $filehandle $html;
	FAQ::OMatic::flush($filehandle);
	FAQ::OMatic::setLocal('maintenance-html', '');
}

sub periodicTasks {
	my $arg = shift || '';
	my $lastMaintenance = readMaintenanceHint();

	my @thenTime = localtime($lastMaintenance);
	my @nowTime = localtime($^T);

	my $newYear =	($thenTime[5] != $nowTime[5])?1:0;
	my $newMonth =	(!defined($thenTime[4])
					or !defined($nowTime[4])
					or ($thenTime[4] != $nowTime[4])
					or $newYear
					or ($arg eq 'month'))
						?1:0;

	# a tricky case:
	my $newWeek = 	(($thenTime[6] > $nowTime[6])
						# it's now "earlier" in the week than then
					or ($lastMaintenance<($^T-(86400*7)))
					or ($arg eq 'week')) ? 1 : 0;
						# or it's at least a week later

	my $newDay =	(($thenTime[3] != $nowTime[3]) or $newMonth
					or ($arg eq 'day'))?1:0;
	my $newHour =	(($thenTime[2] != $nowTime[2]) or $newDay
					or ($arg eq 'hour'))?1:0;

	my @tasks = ();

	# The number in front of the task is the sort order
	push @tasks, (
		'10 buildSearchDB'
		) if $newHour;
	push @tasks, (
		'40 mirrorClient',	# if we're a mirror, this will do an update.
		'50 cookies',
		'60 logSummary',
		'80 trimUHDB',		# turns on a flag so trim() will trim uhdbs
		'81 trimSubmitTmps',# turns on a flag so trim() will trim submitTmps
		'82 trimSlowOutput',# turns on a flag so trim() will trim slow-outputs
		'89 trim',	 		# traverse metadir (needed for trim() to do anything)
		'90 fsck',
		'91 emptyTrash'
		) if $newDay;
	push @tasks, (
		'55 errors'
		) if $newWeek;
	push @tasks, '98 writeMaintenanceHint';

	hprint('Executing schedules:'
		.($newHour	? ' Hourly'	:'')
		.($newDay	? ' Daily'	:'')
		.($newWeek	? ' Weekly'	:'')
		."\n\n");

	my %tasks = map { ($_,1) } @tasks;
	return keys %tasks;
}

# sub runScript {
# 	my $script = shift;
# 	$html.= "    Executing $script...\n";
# 	if (system("$script")) {
# 		$html.= "   ...failed because $!\n";
# 	}
# }

sub readMaintenanceHint {
	my $lastMaintenance;
	if (open LMHINT, "$FAQ::OMatic::Config::metaDir/lastMaintenance") {
		<LMHINT> =~ m/^(\d+)/;
		$lastMaintenance = defined($1) ? int($1) : 0;
			# THANKS Michael Gerdts <gerdts@cae.wisc.edu> for the defined() test
		close LMHINT;
	} else {
		$lastMaintenance = 0;
	}
	return $lastMaintenance;
}

############################################################################
########  Task definitions  ################################################
############################################################################

sub writeMaintenanceHint {
	if (open LMHINT, ">$FAQ::OMatic::Config::metaDir/lastMaintenance") {
		print LMHINT $^T."  ".scalar localtime($^T)."\n";
		close LMHINT;
	}
	FAQ::OMatic::Versions::setVersion('MaintenanceInvoked');
}

sub trimUHDB {
	my $trimset = FAQ::OMatic::getLocal('trimset') || {};
	$trimset->{'uhdb'} = 1;
	FAQ::OMatic::setLocal('trimset', $trimset);
}

sub trimSubmitTmps {
	my $trimset = FAQ::OMatic::getLocal('trimset') || {};
	$trimset->{'submitTmp'} = 1;
	FAQ::OMatic::setLocal('trimset', $trimset);
}

sub trimSlowOutput {
	my $trimset = FAQ::OMatic::getLocal('trimset') || {};
	$trimset->{'slow'} = 1;
	FAQ::OMatic::setLocal('trimset', $trimset);
}

sub buildSearchDB {
	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $force = $cgi->param('force') || '';
		# FORCE feature requested by
		# "Dameon D. Welch-Abernathy" <dwelch@phoneboy.com>
	if ($force
		or (not -f "$FAQ::OMatic::Config::metaDir/freshSearchDBHint")
		or (-M "$FAQ::OMatic::Config::metaDir/freshSearchDBHint" > 1/24)) {
		FAQ::OMatic::buildSearchDB::build();
	} else {
		hprint("    (not needed)\n");
	}
}

sub rebuildAllSummaries {
	FAQ::OMatic::Log::rebuildAllSummaries();
}

sub trim {
	if (not opendir NEWLOGDIR, $FAQ::OMatic::Config::metaDir) {
		hprint("*** Couldn't scan $FAQ::OMatic::Config::metaDir.");
		return;
	}

	my $trimset = FAQ::OMatic::getLocal('trimset') || {};
	hprint("trimming: ".join(' ', sort keys %{$trimset})."\n");

	my $daybefore = FAQ::OMatic::Log::adddays(FAQ::OMatic::Log::numericToday(), -2);
	while (defined(my $file = readdir(NEWLOGDIR))) {
		# untaint file -- we should be able to trust the operating system
		# to provide only reasonable filenames from a readdir().
		$file =~ m/^(.*)$/;
		$file = $1;

		# uhdb's (unique host databases, part of the access log)
		if ($trimset->{'uhdb'} and ($file =~ m/^[\d-]+.uhdb./)) {
			my @dates = ($file =~ m/^([\d-]+)/);
			my $date = $dates[0];

			# Delete all uhdb files before yesterday to save
			# space.  we save the day-before's log, since
			# we need it if we summarize yesterday's log (which
			# is another task on the maintenance agenda).
			# (uhdb = Unique Host Database files. Since no
			# "new" unique hosts will be joining logs from the
			# past, having the files around doesn't help
			# anymore.)
			# Notice we do these tests based on the name of the
			# file, not the mod date, since it could have been
			# generated today by a regenerateSmrys.
			if ($date lt $daybefore) {
				hprint("removing $file\n");
				unlink "$FAQ::OMatic::Config::metaDir/$file";
			}
		}

		# submitTmp
		if ($trimset->{'submitTmp'} and ($file =~ m/^submitTmp\./)) {
			# only trim files older than a day
			if (-M "$FAQ::OMatic::Config::metaDir/$file" > 1.0) {
				hprint("removing $file\n");
				unlink "$FAQ::OMatic::Config::metaDir/$file";
			}
		}

		# slow
		if ($trimset->{'slow'} and ($file =~ m/^slow-output\./)) {
			# only trim files older than a day
			if (-M "$FAQ::OMatic::Config::metaDir/$file" > 1.0) {
				hprint("removing $file\n");
				unlink "$FAQ::OMatic::Config::metaDir/$file";
			}
		}
	}
	close NEWLOGDIR;
}

sub cookies {
	# throw away old cookies
	if (not open COOKIES, "$FAQ::OMatic::Config::metaDir/cookies") {
		hprint("no cookie file.\n");
		return;
	}
	my $cookiesNewFile = "$FAQ::OMatic::Config::metaDir/cookies.new";
	if (not open NEWCOOKIES, ">$cookiesNewFile") {
		hprint("can't create $FAQ::OMatic::Config::metaDir/cookies.new.\n");
		return;
	}
	while (defined($_=<COOKIES>)) {
		my ($cookie,$id,$time) = split(' ');
		if ($time
				+($FAQ::OMatic::Config::cookieLife||3600)
				+$FAQ::OMatic::Auth::cookieExtra
					> $^T) {
			# TODO: that 3600 default should be encoded somewhere,
			# rather than being a magic number. It also appears in Auth.pm.
			print NEWCOOKIES $_;
		}
	}
	close COOKIES;
	close NEWCOOKIES;
	if (not chmod(0600, "$cookiesNewFile")) {
		FAQ::OMatic::gripe('problem', "chmod failed on $cookiesNewFile");
	}
	unlink "$FAQ::OMatic::Config::metaDir/cookies";
	if (not rename("$FAQ::OMatic::Config::metaDir/cookies.new","$FAQ::OMatic::Config::metaDir/cookies")) {
		hprint ("Couldn't rename $FAQ::OMatic::Config::metaDir/cookies.new "
			."to $FAQ::OMatic::Config::metaDir/cookies\n"
			."because $!\n");
	}
}

sub errors {
	if (not $FAQ::OMatic::Config::maintSendErrors) {
		hprint("    Config says don't mail errors.\n");
		return;
	}

	my $size = (-s "$FAQ::OMatic::Config::metaDir/errors") || 0;
	if ($size == 0) {
		hprint("    No ($size) errors to mail.\n");
		return;
	}

	my $msg = "Errors from ".FAQ::OMatic::fomTitle()
		." (v. $FAQ::OMatic::VERSION):\n\n";
	if (not open(ERRORS, "$FAQ::OMatic::Config::metaDir/errors")) {
		hprint("   Couldn't read $FAQ::OMatic::Config::metaDir/errors "
			."because $!; not truncating\n");
	} else {
		hprint("   Sending errors...\n");
		my @errs = <ERRORS>;
		close ERRORS;
		FAQ::OMatic::sendEmail($FAQ::OMatic::Config::adminEmail,
					"Faq-O-Matic Error Log",
					$msg.join('', @errs));

		# truncate errorfile
		open ERRORS, ">$FAQ::OMatic::Config::metaDir/errors";
		close ERRORS;
	}
}

sub logSummary {
	my $yesterday = FAQ::OMatic::Log::adddays(FAQ::OMatic::Log::numericToday(), -1);

	FAQ::OMatic::Log::summarizeDay($yesterday);
}

sub cronInvoke {
	# special version to be called from cron to alert user to errors
	my @reply = invoke(@_);
	my $reply = join('', @reply);

	# if the cron job fails to run, we should print a message out,
	# so that the user knows to fix it. (most crons mail the message
	# to the user.)
	my ($proto,$code,@rest) = split(' ', $reply[0]);

	# THANKS to Andrew W. Nosenko <awn@bcs.zp.ua>
	# for this patch to ignore 'Moved Temporarily' response.
	# TODO: I'm not sure 302 guarantees that it actually worked,
	# but it's something. Why do we return the 'slow' URL to cron?
	# That seems buggy.
	if ($code != '200' && $code != '302') {
		print "Unable to invoke maintenance task; HTTP reply follows:\n\n";
		print $reply;
	}
	if ($reply =~ m/$badKeyMessage/) {
		print "$badKeyMessage\n";
		print "Admin must access the install page and\n"
			."click \"Set up the maintenance cron job.\"\n";
	}
}

sub invoke {
	my $host = shift;
	my $port = shift;
	my $url = shift;
	my $verbose = shift;

	my $proto = getprotobyname('tcp');
	socket(HTTPSOCK, PF_INET, SOCK_STREAM, $proto);
	my $httpsock = \*HTTPSOCK;	# filehandles are such a nasty legacy in Perl
	my $sin = sockaddr_in($port, inet_aton($host));
	if (not connect(HTTPSOCK, $sin)) {
		die "maintenance::invoke can't connect(): $!, $@!\n"
	}
	print $httpsock "GET $url HTTP/1.0\nHost: ${host}\n\n";
		# Thanks to Gabor Melis <gabor.melis@essnet.se> for the "Host:"
		# header, which makes virtually hosted sites work right.
	FAQ::OMatic::flush($httpsock);
		# Thanks to Miro Jurisic <meeroh@MIT.EDU> for this fix.

	my @reply = <$httpsock>;
	close $httpsock;

	if ($verbose) {
		hprint(join('', @reply));
	}
	return @reply if wantarray();
}

# We used to have a verifyCache task that rebuilt cached files if
# they were older than their item file (or the config file).
# The former condition wasn't very useful, since caches are rewritten
# whenever items are. The latter shouldn't really have happened
# automatically, because it can be verrrry slow on a big FAQ.
# And in neither case could you refresh *every* item in the cache.
# The new task simply reads and writes every item in the item/ directory,
# which ensures that its cache and dependencies are up-to-date.
# (note also the 'updateAllDependencies' flag to saveToFile().)
#
sub rebuildCache {
	my $slow = shift || '';

	return if ((not defined $FAQ::OMatic::Config::cacheDir)
				or ($FAQ::OMatic::Config::cacheDir eq ''));
	
	if ($slow) {
		my $fh = FAQ::OMatic::Slow::split();
		hSetFilehandle($fh);
		# from now on, our output goes into the slow-output file
		# to be periodically loaded by the browser.
	}

	my $itemName;
	foreach $itemName (FAQ::OMatic::getAllItemNames()) {
		hprint( "<br>Updating $itemName\n");
		my $item = new FAQ::OMatic::Item($itemName);
		if ($item->isEmptyStub()) {
			# skip stubs
			next;
		}
		if (not eval {
			$item->saveToFile('', '', 'noChange', 'updateAllDependencies');
			1;
		}) {
			FAQ::OMatic::gripe('note', "save failed for ".$itemName);
		}


		# flush stdout
		hflush();
	}

	FAQ::OMatic::Versions::setVersion('CacheRebuild');
}

sub expireBags {
	return if ((not defined $FAQ::OMatic::Config::cacheDir)
				or ($FAQ::OMatic::Config::cacheDir eq '')
				or (not defined $FAQ::OMatic::Config::bagsDir)
				or ($FAQ::OMatic::Config::bagsDir eq ''));
	
	my $anyMessages = 0;
	my @bagList = grep { not m/\.desc$/ }
		FAQ::OMatic::getAllItemNames($FAQ::OMatic::Config::bagsDir);
	my $bagName;
	foreach $bagName (@bagList) {
		#hprint("<br>Checking $bagName\n");
		my @dependents = FAQ::OMatic::Item::getDependencies("bags.".$bagName);
		if (scalar(@dependents) == 0) {
			# don't declare system-supplied bags invalid
			# THANKS: to John Goerzen for pointing this out
			my ($prefix) = ($bagName =~ m/^(.*)\.[^\.]+$/);
			# THANKS: Edwin Chiu <edwinc@s-scape.ca> for fixing an
			# uninitialized value warning coming from here.
			next if (defined($prefix)
				&& FAQ::OMatic::ImageRef::validImage($prefix));

			if (not $anyMessages) {
				hprint("The following suggestion(s) are based on "
					."dependency files.\n You might run rebuildCache first "
					."if you want to be certain that they are valid.\n\n");
			}
			$anyMessages = 1;
			my $msg = "Consider removing bag $bagName; it is not linked from "
				."any item in the FAQ.";
			hprint "<br>$msg\n";
			# TODO: in a future version, we could actually just unlink
			# TODO: the unreferenced bags. (garbage collection).
			# The comment above about rebuildCache would apply.
			# Dependencies should stay current, but I'd sure hate
			# to accidentally blast your bag.
		}
	}
}

sub bagAllImages {
	return if ((not defined $FAQ::OMatic::Config::bagsDir)
				or ($FAQ::OMatic::Config::bagsDir eq ''));

	require FAQ::OMatic::ImageRef;
	FAQ::OMatic::ImageRef::bagAllImages();

	FAQ::OMatic::Versions::setVersion('SystemBags');
}

sub mirrorClient {
	my $slow = shift || '';
	my $url = $FAQ::OMatic::Config::mirrorURL;

	if ((not defined $url)
		or ($url eq '')) {
		hprint("mirrorClient() exiting silently because this is "
			."not a mirror.\n");
		return;
	}

	if ($slow) {
		my $fh = FAQ::OMatic::Slow::split();
		hSetFilehandle($fh);
		# from now on, our output goes into the slow-output file
		# to be periodically loaded by the browser.
	}

	hprint("<p>Querying master site for item and bag modification times.<p>\n");
	hflush();

	my $limit = -1;	# Set to a small number for debugging, so you don't
					# have to wait for the whole mirror to complete.
					# Set to -1 for normal operation.

	require FAQ::OMatic::install;

	# cheesily parse the URL. This seemed better than use'ing the
	# whole URL.pm kit. I had bad luck with it once. Maybe I'm irrational.
	my ($host, $port, $path) =
		$url =~ m#http://([^/:]+)(:\d+)?/(.*)$#;
	if (defined $port) {
		$port =~ s/^://;
	} else {
		$port = 80;
	}
	$path = "/$path?cmd=mirrorServer";

	my @reply = invoke($host, $port, $path);

	# chew HTTP headers until a blank line
	while (not $reply[0] =~ m/^[\r\n]*$/) {
		shift @reply;
	}
	shift @reply;	# chew off that blank line
	@reply = grep { not m/^#/ } @reply;		# chew off comment lines
	@reply = map { chomp $_; $_ } @reply;		# chomp LFs

	# first line of remaining content must be version number
	my $version = shift @reply;
	if ($version ne 'version 1.0') {
		die "This FAQ-O-Matic version $FAQ::OMatic::VERSION only understands "
			."mirrorServer data version 1.0; received $version.";
	}

	#hprint  join("\n", @reply);

	my @itemURL = grep { m/^itemURL\s/ } @reply;
	my $itemURL = ($itemURL[0] =~ m/^itemURL\s+(.*)$/)[0];
	if (not defined $itemURL) {
		die "master didn't send itemURL line.";
	}

	my @configs = grep { m/^config\s/ } @reply;
	my $config;
	my $map = FAQ::OMatic::install::readConfig();
	hprint("configs supplied: ".scalar(@configs)."\n");
	foreach $config (@configs) {
		my ($left,$right) =
			($config =~ m/config (\$\S+) = (.+)$/);
		if (defined $left and defined $right) {
			# unless the config line is buggy, as can happen when
			# the mirrorServer FAQ is running 2.618 :v(, update our config
			$map->{$left} = $right;
			hprint("<br>$left => $right\n");
		}
	}
	FAQ::OMatic::install::writeConfig($map);
	# now make sure that config takes effect for all the cache
	# files we're about to write
	FAQ::OMatic::install::rereadConfig();
	hflush();

	my $count = 0;
	my @items = grep { m/^item\s/ } @reply;
	my $line;
	foreach $line (@items) {
		my ($file,$lms) =
			($line =~ m/item\s+(\S+)\s+(\S+)/);
		if (not defined $file || $file eq '') {
			hprint("<br>Can't parse: $line\n");
			next;
		}
		my $item = new FAQ::OMatic::Item($file);
		my $existingLms = $item->{'LastModifiedSecs'} || -1;
		if ($lms != $existingLms) {
			hprint("<br>$file ".$item->getTitle().": item needs update\n");
			mirrorItem($host, $port, $itemURL."$file", $file, '');
			$count++;	# each net access counts 1, whether or not it takes
		} else {
			# hprint "<br>Already have: $file ".$item->getTitle()."\n";
			# Benign output supressed so you can see which items you
			# don't have.
		}

		if ($limit>=0 && $count >= $limit) {
			hprint("<p>stopping because count = limit ($limit)\n");
			return;
		}
		# flush output
		hflush();
	}

	my @bagsURL = grep { m/^bagsURL\s/ } @reply;
	my $bagsURL = ($bagsURL[0] =~ m/^bagsURL\s+(.*)$/)[0];
	if (not defined $bagsURL) {
		die "master didn't send bagsURL line.";
	}

	my @bags = grep { m/^bag\s/ } @reply;
	foreach $line (@bags) {
		my ($bagword,$file,$lms) = split(/\s+/, $line);
		if (not defined($bagword)
			|| ($bagword ne 'bag')
			|| not defined($file)) {
			hprint("bad line: $line");
			#continue; LEFT OFF
		}
		if ((not defined($lms)) || ($lms eq '')) {
			# some old mirrorServer forgot to send a date --- assume the
			# file is recently modified.
			$lms = time();
		}
		$file = FAQ::OMatic::Bags::untaintBagName($file);
		if ($file eq '') {
			hprint("<br>Tainted bag name in '$line'\n");
			next;
		}

		my $descFile = $file.".desc";
		my $descItem = new FAQ::OMatic::Item($descFile,
							$FAQ::OMatic::Config::bagsDir);
		my $existingLms = $descItem->{'LastModifiedSecs'} || -1;

		if ($lms != $existingLms) {
			hprint("<br>${file}: bag needs update\n");
			# transfer bag byte-for-byte to my bags dir
			mirrorBag($host, $port, $bagsURL."$file", $file);
			# transfer the .desc file, using same item mirroring code as above
			mirrorItem($host, $port, $bagsURL.$descFile,
				$descFile, $FAQ::OMatic::Config::bagsDir);
			# update the link in any items that point to this bag
			FAQ::OMatic::Bags::updateDependents($file);
			$count += 2;
		} else {
			# hprint "<br>Already have: $file\n";
		}

		if ($limit>=0 && $count >= $limit) {
			hprint("<p>stopping because count = limit ($limit)\n");
			return;
		}
		# flush output
		hflush();
	}
}

# a close relative of previous function invoke().
sub mirrorItem {
	my $host = shift;
	my $port = shift;
	my $path = shift;
	my $itemFilename = shift;
	my $itemDir = shift;

	my $proto = getprotobyname('tcp');
	my $sin = sockaddr_in($port, inet_aton($host));

	socket(HTTPSOCK, PF_INET, SOCK_STREAM, $proto);
	my $httpsock = \*HTTPSOCK;

	if (not connect($httpsock, $sin)) {
		die "mirrorItem can't connect(): $!, $@!\n"
	}
	my $request = "GET $path HTTP/1.0\nHost: ${host}";
		# THANKS to Stefan Stidl <sti@austromail.at> for the
		# Host: header, to fix mirroring from virtual hosts
	print $httpsock "$request\n\n";
	FAQ::OMatic::flush($httpsock);
		# Thanks to Miro Jurisic <meeroh@MIT.EDU> for this fix.
	my $httpstatus = <$httpsock>;	# get initial result
	chomp $httpstatus;
	my ($statusNum) = ($httpstatus =~ m/\s(\d+)\s/);
	if ($statusNum != 200) {
		hprint("<br>Request '$request' for $itemFilename from "
			."$host:$port failed: ($statusNum) $httpstatus\n");
		close($httpsock);
		return;
	}
	while (defined($_=<$httpsock>)) {			# blow past HTTP headers
		last if ($_ =~ m/^[\r\n]*$/);
	}

	my $item = new FAQ::OMatic::Item();
	$item->{'filename'} = $itemFilename;
	$item->loadFromFileHandle($httpsock);
	close($httpsock);

	$item->{'titleChanged'} = 'true';
		# since we just mirrored this guy, the title may very well
		# have changed, so we need to be sure to rewrite dependent items.
	$item->saveToFile($itemFilename, $itemDir, 'noChange', 'updateAllDeps',
		'noRecomputeDependencies');
		# notice we're passing in a filename we got from that
		#	web server -- an insidious master might try to pass
		#	off bogus item filenames with '..'s in them. But saveToFile()
		#	has a taint-check to prevent that sort of thing.
		# 'noChange' keeps lastModified date intact, so we won't keep
		#	re-mirroring this item.
		# 'updateAllDependencies' is necessary, because otherwise
		#	saveToFile only adds those dependencies that are "new" to
		#	this item -- but we only have the item, not the .dep file,
		#	so we need to always regenerate all deps.
		# 'noRecomputeDependencies' prevents Item.pm from trying to
		#	resolve forward references to nonexistent items. For example, an
		#	item can have a parent that hasn't been reached yet in the
		#	mirroring.
	hprint("<br>$itemFilename (".$item->getTitle()."): "
		."item mirrored successfully\n");
}

sub mirrorBag {
	my $host = shift;
	my $port = shift;
	my $path = shift;
	my $bagFilename = shift;	# already untainted by caller

	my $proto = getprotobyname('tcp');
	my $sin = sockaddr_in($port, inet_aton($host));

	socket(HTTPSOCK, PF_INET, SOCK_STREAM, $proto);
	my $httpsock = \*HTTPSOCK;	# filehandles are such a nasty legacy in Perl

	if (not connect($httpsock, $sin)) {
		die "mirrorBag can't connect(): $!, $@!\n"
	}
	my $request = "GET $path HTTP/1.0\nHost: ${host}";
	print $httpsock "$request\n\n";
	FAQ::OMatic::flush($httpsock);
		# Thanks to Miro Jurisic <meeroh@MIT.EDU> for this fix.
	my $httpstatus = <$httpsock>;	# get initial result
	chomp $httpstatus;
	my ($statusNum) = ($httpstatus =~ m/\s(\d+)\s/);
	if ($statusNum != 200) {
		hprint("<br>Request '$request' for $bagFilename from "
			."$host:$port failed: ($statusNum) $httpstatus\n");
		close($httpsock);
		return;
	}
	while (defined($_=<$httpsock>)) {			# blow past HTTP headers
		last if ($_ =~ m/^[\r\n]*$/);
	}

	# input looks good at this point -- open output bag file
	if (not open(BAGFILE, ">".$FAQ::OMatic::Config::bagsDir.$bagFilename)) {
		hprint("<br>open of $bagFilename failed: $!\n");
		close $httpsock;
		return;
	}

	my $sizeBytes = 0;
	my $buf;
	while (read($httpsock, $buf, 4096)) {
		print BAGFILE $buf;
		$sizeBytes += length($buf);
		# TODO: maybe have (mirror-site-admin)-configurable length limit here
	}
	close(BAGFILE);
	close($httpsock);

	if (not chmod(0644, $FAQ::OMatic::Config::bagsDir.$bagFilename)) {
		FAQ::OMatic::gripe('problem', "chmod("
			.$FAQ::OMatic::Config::bagsDir.$bagFilename
			." failed: $!");
	}

	if ($sizeBytes == 0) {
		hprint("<br><b>Uh oh, I read no bytes for $bagFilename.</b>\n");
		return;
	}

	hprint("<br>${bagFilename}: bag mirrored successfully\n");
}

sub mtime {
	my $filename = shift;
	return (stat($filename))[9] || 0;
}

sub emptyTrash {
	my $slow = shift || '';

	if ($slow) {
		my $fh = FAQ::OMatic::Slow::split();
		hSetFilehandle($fh);
		# from now on, our output goes into the slow-output file
		# to be periodically loaded by the browser.
	}

	my $trashExpirationDays = $FAQ::OMatic::Config::trashTime || 0;
	if ($trashExpirationDays == 0) {
		hprint("\$trashTime says to never take out the trash.<br>\n");
		return;
	}

	my $trashItem = new FAQ::OMatic::Item('trash');
	if ($trashItem->isBroken()) {
		FAQ::OMatic::gripe('problem', gettext('Crud, the trash can is broken.'));
		return;
	}

	# walk the trash tree looking for old trash
	hprint("<br>At top level:\n");
	my @children = $trashItem->getChildren();
	emptyTrashVisitChildren($trashItem, \@children, 1);
	$trashItem->saveToFile();
	hprint("<p>emptyTrash: Done\n");
}

sub indent {
	my $amount = shift;
	return ("."x($amount*3))." ";
}

sub emptyTrashVisitChildren {
	my $parentItem = shift;
	my $childList = shift;
	my $indent = shift;

	hprint(indent($indent)."Visit children (".scalar(@$childList).")\n");
	foreach my $childName (@$childList) {
		#hprint(indent($indent+1)."Visit children ($childName)\n");
		my $childItem = new FAQ::OMatic::Item($childName);
		if ($childItem->isBroken()) {
			# can't see into child item. Detach, and let fsck find
			# and destroy te item file.
			hprint(indent($indent)."detaching broken child $childName\n");
			$parentItem->removeSubItem($childName, 'deferUpdate');
				# deferred update okay because caller will
				# explicitly save this guy
		} else {
			emptyTrashVisitItem($childName, $childItem, $indent);
		}
		hflush();
	}
}

sub emptyTrashVisitItem {
	my $itemName = shift;
	my $item = shift;
	my $indent = shift;

	my $trashExpirationDays = $FAQ::OMatic::Config::trashTime || 0;
	my $trashExpirationSeconds = $trashExpirationDays*24*60*60;

	my $filename = $item->{'filename'} || '[no filename]';
	my $title = $item->getTitle() || '[no title]';
	hprint(indent($indent)."Examining trash node $filename ($itemName) named $title\n");

	# Get (rid of) the children;
	# if this isn't a category, it'll just get the
	# empty list, and that's perfect.
	my @children = $item->getChildren();
	if (scalar(@children)>0) {
		emptyTrashVisitChildren($item, \@children, $indent+1);
	}

	# if there aren't any children now (either there weren't before, or
	# we actually blasted them all), then consider blasting this guy, too.
	my $blasted = 0;
	@children = $item->getChildren();
	if (scalar(@children)<=0) {
		# found a leaf
		hprint(indent($indent)."Found a leaf ".$item->getTitle()."\n");
		my $lastModified = $item->{'LastModifiedSecs'} || 0;
		my $age = time() - $lastModified;
		if ($age > $trashExpirationSeconds) {
			hprint(indent($indent)." ... and it's old. Should delete.\n");
			my $filename = $item->{'filename'};
			my $rc = $item->destroyItem('deferUpdate');
				# deferred update is okay, because we're going to
				# save this guy's parent anyway when we return from
				# the recursion (if the parent isn't blasted.)
			if ($rc) {
				hprint(indent($indent)."removed $filename; rc = $rc");
				$blasted = 1;
			} else {
				hprint(indent($indent)."couldn't remove $filename; rc = $rc");
			}
		} else {
			hprint(indent($indent).sprintf("'-but it's not old. (%d sec)\n", $age));
		}
	}
	if (!$blasted) {
		# make sure changes to directory stick.
		hprint(indent($indent).scalar(@children)." children remain. This item survives. Saving changed directory\n");
		$item->saveToFile();
	}
}

sub fsck {

	my $reportFreq = 100;

	# check for:
	# links to broken items -> replace link with text describing broken link
	# items claimed by multiple parents -> rewrite as links in n-1 parents
	# roots other than 1, trash -> connect to lost+found
	hprint("Pass 1: detect broken files\n");
	hflush();
	my $count = 0;
	foreach my $filei (FAQ::OMatic::getAllItemNames()) {
		my $item = new FAQ::OMatic::Item($filei);
#		if ($filei eq '1117') {
#			hprint("1117: broken=".($item->isBroken()?'t':'f')
#				." emptyStub=".($item->isEmptyStub()?'t':'f')
#				."\n");
#		}
		if ($item->isBroken() and not $item->isEmptyStub()) {
			# file is broken. disconnect it from parent; delete file
			fsckReport("found broken item file $filei; destroying");
			FAQ::OMatic::Item::destroyItemRaw($filei);
		}
		if (((++$count)%$reportFreq)==0) {
			hprint("checked $count items; finished $filei\n");
		}
		hflush();
	}

	my $lostAndFoundItem = undef;
	hprint("Pass 2: Detect incorrect ownership claims, disconnected subtrees\n");
	hflush();
	$count = 0;
	foreach my $filei (FAQ::OMatic::getAllItemNames()) {
		my $item = new FAQ::OMatic::Item($filei);
		if ($item->isBroken() and not $item->isEmptyStub()) {
			FAQ::OMatic::gripe('abort', "pass 1 failed; can't proceed to pass 2.");
		}
		my @children = $item->getChildren();
		my $changedChildren = 0;
		foreach my $childName (@children) {
			my $childItem = new FAQ::OMatic::Item($childName);
			if ($childItem->isBroken()) {
				fsckReport("$filei owns broken child $childName; detaching");
				$item->removeSubItem($childName, 'deferUpdate');
				$changedChildren = 1;
			} elsif ($childItem->{'Parent'} ne $filei) {
				fsckReport("$filei claims to own $childName, but ${childName}'s parent is ".$childItem->{'Parent'}."; detaching");

				$item->removeSubItem($childName, 'deferUpdate');
				$changedChildren = 1;
			}
		}
		if ($changedChildren) {
			$item->saveToFile();
		}
		hflush();
		
		my $parent = $item->getParent();
		if ($filei eq '1' || $filei eq 'trash' || $filei eq 'help000') {
			# ignore these; they're okay as roots.
		} elsif ($parent->isBroken() or ($parent == $item)) {
			fsckReport("$filei is a root, but shouldn't be");
			$lostAndFoundItem = getLostAndFoundItem($lostAndFoundItem);
			$lostAndFoundItem->addSubItem($filei);
			$item->setProperty('Parent', $lostAndFoundItem->{'filename'});
			$item->saveToFile();
			$lostAndFoundItem->saveToFile();
		}
		if (((++$count)%$reportFreq)==0) {
			hprint("checked $count items; finished $filei\n");
		}
		hflush();
	}
	hprint("fsck complete\n");
	hflush();
}

sub fsckReport {
	my $msg = shift;
	hprint("$msg\n");
	FAQ::OMatic::gripe('note', $msg);
}

sub getLostAndFoundItem {
	my $lostAndFoundItem = shift;
	if (defined($lostAndFoundItem)) {
		return $lostAndFoundItem;
	}
	my $top = new FAQ::OMatic::Item('1');
	foreach my $childName ($top->getChildren) {
		my $childItem = new FAQ::OMatic::Item($childName);
		if (($childItem->{'Title'}||'') eq 'lost+found') {
			return $childItem;
		}
	}
	# have to create one.
	$lostAndFoundItem = new FAQ::OMatic::Item();
	$lostAndFoundItem->setProperty('Parent', '1');
	$lostAndFoundItem->setProperty('Title', 'lost+found');
	$lostAndFoundItem->saveToFile(FAQ::OMatic::unallocatedItemName('1'));

	$top->addSubItem($lostAndFoundItem->{'filename'});
	$top->saveToFile();
	return $lostAndFoundItem;
}

1;
