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
## FAQ::OMatic.pm
##
## This module contains routines common to the various faqomatic cgi-bins.
## It also loads FaqConfig.pm, which also defines variables in the
## FAQ::OMatic:: namespace.
##

# THANKS to Andrew W. Nosenko <awn@bcs.zp.ua> for several patches
# for locale, russian translation, and bug fixes. Thanks also to
# Andrew for patiently waiting, what, EIGHT MONTHS until I finally
# got them plugged into the CVS tree. :v)

package FAQ::OMatic;

use Fcntl;	# for lockFile. Not portable, but then neither is lockFile().

use FAQ::OMatic::Item;
use FAQ::OMatic::Log;
use FAQ::OMatic::Appearance;
use FAQ::OMatic::Bags;
use FAQ::OMatic::I18N;

use vars	# these are mod_perl-safe
	# effectively constants
	qw($VERSION $USE_MOD_PERL),
	# variables that get reset on every invocation
	qw($theParams $theLocals);

$VERSION = '2.719';

# can't figure out how to get file-scoped variables in mod_perl, so
# we ensure that they're all file scoped by reseting them in dispatch.
sub reset {
	$theParams = {};
	$theLocals = {};
}

sub getLocal {
	my $localname = shift;
	return $theLocals->{$localname};
}

sub setLocal {
	my $localname = shift;
	my $localvalue = shift;
	$theLocals->{$localname} = $localvalue;
}

sub pageHeader {
	my $params = shift || $theParams;
	my $showLinks = shift;
	my $suppressType = shift;

	return FAQ::OMatic::Appearance::cPageHeader($params,
		$showLinks, $suppressType);
}

sub pageFooter {
	my $params = shift;				# arg passed to Apperance::cPageFooter
	my $showLinks = shift || [];	# arg passed to Apperance::cPageFooter
	my $isCached = shift || '';		# don't put gripes in the cached copies

	my $page = '';
	my $userGripes = getLocal('userGripes') || '';
	if (not $isCached and $userGripes ne '') {
		$page.="<hr><h3>".gettext("Warnings:")."</h3>\n".$userGripes."<hr>\n";
	}
	push @{$showLinks}, 'faqomatic-home';
	$page.=FAQ::OMatic::Appearance::cPageFooter($params, $showLinks);
	return $page;
}

# the name of the entire FAQ
sub fomTitle {
	my $topitem = new FAQ::OMatic::Item('1');
	my $title = $topitem->getTitle('undefokay');
	if (not $title) {
		if (FAQ::OMatic::Versions::getVersion('Items')) {
			# (don't gripe if FAQ not installed yet)
			FAQ::OMatic::gripe('note',
				gettext("Your Faq-O-Matic would have a title if it had an item 1, which it will when you've run the installer.")
			);
		}
		$title = gettext("Untitled Faq-O-Matic");
	}
	return $title;
}

# a description of the page we're on right now
sub pageDesc {
	my $params = shift;
	my $cmd = commandName($params);
	my $rt;

	$cmd = 'insertItem'
		if (($cmd eq 'editItem') and ($params->{'_insert'}));
	$cmd = 'insertPart'
		if (($cmd eq 'editPart') and ($params->{'_insertpart'}));

	my $file = $params->{'file'} || '1';
	my $item = new FAQ::OMatic::Item($params->{'file'}||'1');
	my $title = $item->getTitle();
	my $whatAmI = gettext($item->whatAmI());

	my $pageDescs = {
		'authenticate' => gettext_noop("Log In"),
		'changePass' => gettext_noop("Change Password"),
		'editItem' => gettext_noop("Edit Title of %0 %1"),
		'insertItem' => gettext_noop("New %0"),	# special case -- varies editItem
		'editPart' => gettext_noop("Edit Part in %0 %1"),
		'insertPart' => gettext_noop("Insert Part in %0 %1"),
		'moveItem' => gettext_noop("Move %0 %1"),
		'search' => gettext_noop("Search"),
		'stats' => gettext_noop("Access Statistics"),
		'submitPass' => gettext_noop("Validate"),
		'editModOptions' => gettext_noop("%0 Permissions for %1"),
		'editBag' => gettext_noop("Upload bag for %0 %1")
	};

	my $pd = $pageDescs->{$cmd} || '';
	if ($cmd eq 'faq') {
		$rt = $file eq "1" ? "" : $title;
	} elsif ($pd) {
		$rt = gettexta($pd, $whatAmI, $title);
	} else {
		$rt = "$cmd page";
	}

	return $rt ? ": $rt" : "";
}

sub keyValue {
	my ($line) = shift;
	my ($key,$value) = ($line =~ m/([A-Za-z0-9\-]*): (.*)$/);
	return ($key,$value);
}

# returns the name of the currently executing command module (was CGI)
sub commandName {
	my $params = shift || $theParams;
	return ($params->{'cmd'} || 'faq');
}

sub shortdate {
	my (@date) = localtime(time());
	return sprintf("%02d/%02d/%02d %02d:%02d:%02d",
		$date[5], $date[4], $date[3], $date[2], $date[1], $date[0]);
}

# TODO we now have two stacktrace-collectors. Clean this up.
sub collectStackBacktrace {
	my @stack_backtrace;
	my $i = 0;
	my ($package, $filename, $line, $subroutine);
	my @a;
	for ($i=0; ; ++$i)
	{
		@a = caller($i);
		last if (!@a);
		($package, $filename, $line)= @a;
		(undef, undef, undef, $subroutine) = caller($i+1);
		if (!defined($subroutine))
		{
			$subroutine = '';
		}
		push(@stack_backtrace,
			 { 'package' => $package,
			   'filename' => $filename,
			   'line' => $line,
			   'subroutine' => $subroutine });
	}
	return @stack_backtrace;
}

#
#	sub gripe($severity, $msg, $is_show_stack_backtrace)
#
#	Parameters:
#	$severity	Severity of message
#		interesting severity values:
#		'note'     appends msg to log
#		'debug'    appends to log, tells user
#		'error'    appends to log, tells user, aborts CGI
#		'problem'  mails msg to $faqAdmin, appends to log, tells user
#		'abort'    mails msg to $faqAdmin, appends to log, tells
#		           user, aborts CGI
#		'panic'    mails trouble to $faqAdmin, $faqAuthor, appends to
#		           log, tells user, and aborts the CGI
#	$msg		Message itself
#	$options->{'stack'}
#				Is showing of stack backtrace needed? Boolean.
#	$options->{'noentify'}
#				Boolean. Gripe contains no user text, so it's not vulnerable
#				to CSS, and we want the user to see some real HTML tags.
#
sub gripe {
	my $severity = shift || 'problem';
	my $msg = shift || '[gripe with no msg: '.join(':',caller()).']';
	my $options = shift || {};

	my $is_show_stack_backtrace = $options->{'stack'} || '';
	my $noentify = $options->{'noentify'} || '';

	my @stack_backtrace;
	my $mailguys = '';
	my $id = $FAQ::OMatic::Auth::trustedID || $theParams->{'id'} || '(noID)';

	# mail someone
	if ($severity eq 'panic') {
		# mail admin & author
		$mailguys = $FAQ::OMatic::Config::adminEmail." ".$FAQ::OMatic::Config::authorEmail;
	} elsif ($severity eq 'problem' or $severity eq 'abort') {
		# mail admin
		$mailguys = $FAQ::OMatic::Config::adminEmail;
	}

	if ($is_show_stack_backtrace) {
		@stack_backtrace = collectStackBacktrace();
	}

	if ($mailguys ne '') {
		my $message = "The \"".fomTitle()."\" Faq-O-Matic (v. $VERSION)\n";
		$message.="maintained by $FAQ::OMatic::Config::adminEmail\n";
		$message.="had a $severity situation.\n\n";
		$message.="The command was: \"".commandName()."\"\n";
		$message.="The message is: \"$msg\".\n";

		# TODO there are three backtrace-formatters in this function.
		# factor them out into one named, parameterized function.
		if ($is_show_stack_backtrace)
		{
			$message.="The stack backtrace:\n";
			if (@stack_backtrace)
			{
				my $i;
				for ($i=0; $i < @stack_backtrace; ++$i)
				{
					$message .= sprintf("\t%u: %s at %s line %u\n",
										$i+1,
										$stack_backtrace[$i]->{'subroutine'},
										$stack_backtrace[$i]->{'filename'},
										$stack_backtrace[$i]->{'line'});
				}
			}
			else
			{
				$message .= "\t(unavailable)\n";
			}
		}

		$message.="The process number is: $$\n";
		$message.="The user had given this ID: <$id>\n";
		$message.="The browser was: <".($ENV{'HTTP_USER_AGENT'}||'undefined')
			.">\n";
		sendEmail($mailguys,
				"Faq-O-Matic $severity Mail",
				$message);
	}

	# tell user
	if ($severity ne 'note') {
		my $userGripes = getLocal('userGripes');
		# since we're submitting the msg to a web browser,
		# and the messages often include things like
		# "this input was weird: <user-input-here>", we
		# need to sanitize the text (with entify) to avoid
		# a cross-site scripting attack.
		my $safeMsg = $noentify ? $msg : entify($msg);
		$userGripes .= "<li>$safeMsg\n";
 
 		if ($is_show_stack_backtrace)
 		{
 			$userGripes .= "<p>The stack backtrace:\n";
 			if (@stack_backtrace)
 			{
 				my $i;
 				$userGripes .= "<ol>\n";
 				for ($i = 0; $i < @stack_backtrace; ++$i)
 				{
 					$userGripes .=
 						sprintf("\t<li>%s at %s line %u</li>\n",
 								$stack_backtrace[$i]->{'subroutine'},
 								$stack_backtrace[$i]->{'filename'},
 								$stack_backtrace[$i]->{'line'});
 				}
 				$userGripes .= "</ol>\n"
 			}
 			else
 			{
 				$userGripes .= "\t(unavailable)\n";
 			}
 		}
 
		setLocal('userGripes', $userGripes);
	}

	# log to file
	open ERRORFILE, ">>$FAQ::OMatic::Config::metaDir/errors";
	print ERRORFILE FAQ::OMatic::Log::numericDate()
		." $FAQ::OMatic::VERSION $severity "
		.commandName()
		." $$ <$id> $msg";

	if ($is_show_stack_backtrace)
	{
		print(ERRORFILE '[Stack backtrace: ');
		if (@stack_backtrace)
		{
			my $i;
			for ($i=0; $i < @stack_backtrace; ++$i)
			{
				if ($i != 0)
				{
					print(ERRORFILE '; ');
				}
				printf(ERRORFILE
					   "[%u] %s at %s line %u",
					   $i+1,
					   $stack_backtrace[$i]->{'subroutine'},
					   $stack_backtrace[$i]->{'filename'},
					   $stack_backtrace[$i]->{'line'});
			}
		}
		else
		{
			print("(unavailable)");
		}
		print(ERRORFILE ']');
	}
	print(ERRORFILE "\n");

	close ERRORFILE;

	# abort
	if ($severity eq 'error' or $severity eq 'panic' or $severity eq 'abort') {
		if (getParam($theParams, 'isapi')) {
			# client expects easy-to-parse data
			my $userGripes = getLocal('userGripes') || '';
			my $cgi = FAQ::OMatic::dispatch::cgi();
			print FAQ::OMatic::header($cgi, '-type'=>'text/plain')
				."isapi=1\n"
				."errors=".CGI::escape($userGripes)."\n";
		} else {
			print FAQ::OMatic::pageHeader();
			print FAQ::OMatic::pageFooter();
		}
		myExit(0);
	}
}

sub lockFile {
	my $filename = shift;
	my $lockname = $filename;
	$lockname =~ s#/#-#gs;
	$lockname =~ m#^(.*)$#;
	$lockname = "$FAQ::OMatic::Config::metaDir/$1.lck";
#	if (-e $lockname) {
#		sleep 10;
#		if (-e $lockname) {
#			gripe 'problem', "Lockfile $lockname for $filename has "
#				."been there 10 seconds. Failing.";
#			return 0;
#		}
#	}
#	open (LOCK, ">$lockname") or
#		gripe('abort', "Can't create lockfile $lockname ($!)");
#	print LOCK $$;
#	close LOCK;
#	return $lockname;

	# THANKS to A.Flavell@physics.gla.ac.uk for working on finding
	# how broken my old locking code was.
	my $retries = 0;
	while (1) {
		if (++$retries >= 10) {
			gripe('abort', "waited too long to get lock... ($!, $lockname)");
		}
		if (sysopen(LOCK, $lockname, O_CREAT|O_WRONLY, 0444)) {
			# success!
			print LOCK $$;
			close LOCK;
			return $lockname;
		}
		# can't get the lockfile -- wait a little and retry
		sleep (2);
	}
}

sub unlockFile {
	my $lockname = shift;
	if (-e $lockname) {
		unlink $lockname;
		return 1;
	}
	gripe 'abort', "$lockname didn't exist -- uh oh, is the locking system broken?";
	return 0;
}

# turns faqomatic:file references into HTML links with pleasant titles.
sub faqomaticReference {
	my $params = $_[0];
	if (($params->{'render'}||'') eq 'text') {
		return faqomaticReferenceText(@_);
	} else {
		return faqomaticReferenceRich(@_);
	}
}

sub faqomaticReferenceRich {
	my $params = shift;
	my $filename = shift;
	my $which = shift || '-small';
		# '-small' (children) or '-also' (see-also links)

	my $item = new FAQ::OMatic::Item($filename);
	my $title = FAQ::OMatic::ImageRef::getImageRefCA($which,
					'border=0', $item->isCategory(), $params)
				.$item->getTitle();

	return (makeAref('-command'=>'faq',
					'-refType'=>'url',
					'-params'=>$params,
					'-changedParams'=>{"file"=>$filename}),
			$title);
}

sub faqomaticReferenceText {
	my $params = shift;
	my $filename = shift;

	my $item = new FAQ::OMatic::Item($filename);
	return ('',$item->getTitle());
}

sub baginlineReference {
	my $params = shift;
	my $filename = shift;

	if (not -f $FAQ::OMatic::Config::bagsDir.$filename) {
		return "[no bag '$filename' on server]";
	}

	my $sw = FAQ::OMatic::Bags::getBagProperty($filename, 'SizeWidth', '');
	$sw = " width=$sw" if ($sw ne '');
	my $sh = FAQ::OMatic::Bags::getBagProperty($filename, 'SizeHeight', '');
	$sh = " height=$sh" if ($sh ne '');

	# should point directly to bags dir
	# TODO: deal with this correctly when handling all the variations on
	# TODO: urls.
	my $bagUrl = makeBagRef($filename, $params);
	return "<img src=\"$bagUrl\"$sw$sh alt=\"($filename)\">";
}

sub baglinkReference {
	my $params = shift;
	my $filename = shift;

	if (not -f $FAQ::OMatic::Config::bagsDir.$filename) {
		return ('',"[no bag '$filename' on server]");
	}

	my $bagDesc = new FAQ::OMatic::Item($filename.".desc",
		$FAQ::OMatic::Config::bagsDir);
	my $size = $bagDesc->{'SizeBytes'} || '';
	if ($size ne '') {
		$size = " ".describeSize($size);
	}

	# should point directly to bags dir
	# TODO: deal with this correctly when handling all the variations on
	# TODO: urls.
	my $bagUrl = makeBagRef($filename, $params);
	return ($bagUrl,
		FAQ::OMatic::ImageRef::getImageRef('baglink', 'border=0', $params)
		.$filename
		.$size);
}

# The web server passes this information in on every call, but
# it sometimes comes in broken (broken clients, or users typing
# in abbreviated host names which won't work if used as part of a URL
# that's later clicked on by a distant user). So we now let the admin
# configure these fields; but compute them dynamically until the admin
# cements the right ones in place.
sub serverBase {
	if (defined($FAQ::OMatic::Config::serverBase)
		&& $FAQ::OMatic::Config::serverBase ne '') {
		return $FAQ::OMatic::Config::serverBase;
	}
	return (hostAndPath())[0];
}

sub cgiURL {
	if (defined($FAQ::OMatic::Config::cgiURL)
		&& $FAQ::OMatic::Config::cgiURL ne '') {
		return $FAQ::OMatic::Config::cgiURL;
	}
	return (hostAndPath())[1];
}

# compute serverBase and cgiURL dynamically
# (old code -- the cache isn't nearly as necessary now. :v)
sub hostAndPath {
	if (defined getLocal('hapCache')) {
		return @{getLocal('hapCache')};
	}

	my $cgi = FAQ::OMatic::dispatch::cgi();
	my $cgiUrl = $cgi->url();
	my ($urlRoot,$urlPath) = $cgiUrl =~ m#^(https?://[^/]+)(/.*)$#;
	if (not defined $urlRoot or not defined $urlPath) {
		if (not $cgi->protocol() =~ m/^http/i) {
			FAQ::OMatic::gripe('error', "The server protocol ("
				.$cgi->protocol()
				.") seems wrong. The author has seen this happen when "
				."broken browsers don't escape a space in the GET URL. "
				."(KDE Konqueror 1.0 is known broken; upgrade to "
				."Konquerer 1.1.) "
				."\n\n<p>\nThe URL (as CGI.pm saw it) was:\n"
				.$ENV{'QUERY_STRING'}
				."\n\n<br>The REQUEST_URI was:\n"
				.$ENV{'REQUEST_URI'}
				."\n\n<br>The SERVER_PROTOCOL was:\n"
				.$ENV{'SERVER_PROTOCOL'}
				."\n\n<br>The browser was:\n"
				.$ENV{'HTTP_USER_AGENT'}."\n"
				."\n\n<p>If you are confused, please ask "
				."$FAQ::OMatic::Config::adminEmail.\n"
			);
			# This seems to happen when you search on two words,
			# then get an <a href> with a %20 in the _highlightWords
			# field. Turns out KDE's integrated Konquerer browser
			# version 1.0 has this problem; version 1.1 fixes it.
		}
		FAQ::OMatic::gripe('problem', "Can't parse my own URL: $cgiUrl");
	}
	my @hap = ($urlRoot, $urlPath);
	setLocal('hapCache', \@hap);
	return @hap;
}

sub relativeReference {
	my $params = shift;
	my $url = shift;

	if ($url =~ m#^/#) {
		return FAQ::OMatic::serverBase().$url;
	}

	# Else url is relative to current directory.
	# Deal with ..'s. We would leave this to the browser, but we
	# want to return an URL that works everywhere, not just from the
	# CGI. (So it works from a cached file or a mirrored file.)
	my @urlPath = split('/', FAQ::OMatic::cgiURL());
	shift @urlPath;							# shift off first element ('')
	pop @urlPath;							# pop off last element (CGI name)
	while (($url =~ m#^../(.*)$#) and (scalar(@urlPath)>0)) {
		$url = $1;		# strip ../ component...
		pop @urlPath;	# ...and in exchange, explicitly remove path element
	}
	push @urlPath, $url;
	return FAQ::OMatic::serverBase().'/'.join("/",@urlPath);
}

# THANKS: to steevATtiredDOTcom for suggesting the ability to mangle
# or disable attributions to reduce the potential for spam address harvesting.
sub mailtoReference {
	my $params = shift||{};
	my $addr = shift || '';
	my $wantarray = shift || '';

	my $isText = getParam($params, 'render') eq 'text';

	$addr =~ s/^mailto://;	# strip off mailto prefix if it's there
	$addr = entify($addr);
	my $how = $FAQ::OMatic::Config::antiSpam || 'off';

	if ($how eq 'cheesy') {
		$addr =~ s#\@#AT#g;
		$addr =~ s#\.#DOT#g;
	} elsif ($how eq 'nameonly') {
		# THANKS: to "Alan J. Flavell" <flavell@a5.ph.gla.ac.uk> for
		# sending a patch to implement 'nameonly' address munging
		$addr =~ s#\@.*##;
	} elsif ($how eq 'hide') {
		$addr = 'address-suppressed';
	}
	# THANKS to Peter Lawler <sixbynine@ozemail.com.au> for suggesting
	# that we provide the FAQ-O-Matic's title as the subject line of
	# mailto: links.
	my $subject = "subject=".CGI::escape(fomTitle());
	if ($isText) {
		return $addr;
	}
	my $target = '';
	if ($how eq 'off') {
		$target = "mailto:${addr}?${subject}";
	}
	if ($wantarray) {
		# when urlReference calls this func, it wants the link label split
		# from the link target. If $target is empty, it does the right thing
		# by not creating an <A> tag.
		return ($target, $addr);
	} else {
		if ($target ne '') {
			return "<a href=\"$target\">$addr</a>";
		} else {
			return $addr;
		}
	}
}

# turns link-looking things into actual HTML links, but also turns
# <, > and & into entities to prevent them getting interpreted as HTML.
sub insertLinks {
	my $params = shift;
	my $arg = shift;
	my $ishtml = shift || 0;
	my $isdirectory = shift || 0;

	if (not $ishtml) {
		# look for <>-delimited URLs; THANKS to Hal Wine for pointing out
		# <http://www.w3.org/Addressing/URL/5.1_Wrappers.html>, which
		# proposes this as a 'standard' way of embedding URLs in non-marked-up
		# text for automatic readers:
		my @pieces = split(/<([^\s<>]+)>/, $arg);
			# the result of the previous split() operation is an odd-length
			# array; odd-numbered indices contain <things> that matched
			# the angle-bracket regex; even numbered things contain the
			# rest of the text.
		my $rt = '';
		my $i;
		for ($i=0; $i<scalar(@pieces); $i++) {
			if ($i&1) {		# odd index -- a <url>-looking thingamadoo
				$rt .= urlReference($params,$isdirectory,$pieces[$i]);
			} else {		# even index -- some body text
				my $tmp = entify($pieces[$i]);
					# entifying first is bad, because it entifies URLs,
					# which is wrong. But this is only to preserve the
					# old behavior; if you want it right, use the new <>
					# syntax and turn off fuzzy matching.
					# THANKS: to jon * <jon@clearink.com> for reporting
					# an instance of entified URLs.
				# TODO: make fuzzyMatch disable-able.
				$tmp = fuzzyMatch($params,$ishtml,$isdirectory,$tmp);
				$rt .= $tmp;
			}
		}
		$arg = $rt;
	} else {
		# HTML code gets far less mangling. It's not entified, and
		# only my made-up URLs get translated into real ones; other
		# urls are left untouched.
		$arg = fuzzyMatch($params,$ishtml,$isdirectory,$arg);
	}
	return $arg;
}

sub urlReference {
	# take an URL from the middle of some text, and wrap it with some <A></A>
	# tags to make it a link. How to do that depends on the type of
	# URL.
	my $params = shift;
	my $isdirectory = shift;
	my $arg = shift;	#URL to wrap

	my $sa = $isdirectory ? '-small' : '-also';
	
	# unless we can do better, both the label and the target of the URL
	# will be whatever we got passed (whatever matched in the text body)
	my $target = $arg||'';
	my $label = $arg||'';

	my ($prefix,$rest) = ($arg =~ m/^([^:]+):(.*)$/);
	if (not defined $prefix) {
		# match didn't work; this is some sort of link we don't understand.
	} elsif ($prefix eq 'http' or $prefix eq 'https') {
		# it's an http-ish URL.
		# It could be absolute (starts with // and includes hostname),
		#	in which case we should leave it untouched.
		# It could be server-relative (starts with /)
		#	in which case we insert our hostname in case this URL makes it
		#	a long way away.
		# It could be path-relative,
		#	in which case we have to adjust it against our known path
		#	to become absolute (again in case the URL makes it away from here).
		if ($rest =~ m#^//#) {
			$target = $arg;
		} else {
			$target = relativeReference($params, $rest);
		}
	} elsif ($prefix eq 'ftp'
		or $prefix eq 'gopher'
		or $prefix eq 'telnet'
		or $prefix eq 'news') {
		$target = $arg;
	} elsif ($prefix eq 'mailto') {
		($target,$label) = mailtoReference($params, $rest, 'wantarray');
	} elsif ($prefix eq 'faqomatic') {
		# a local reference defined in terms of a FAQ item #,
		# not a web server path (so that it's meaningful on other mirrors
		# of this FAQ, for example)
		($target,$label) = faqomaticReference($params,$rest,$sa);
	} elsif ($prefix eq 'baginline') {
		$target = '';
		$label = baginlineReference($params,$rest);
	} elsif ($prefix eq 'baglink') {
		($target,$label) = baglinkReference($params,$rest);
	}

	# A tough choice: should the readable text of the link be what the
	# user originally typed (to convey the meaning of a relative link,
	# for example), or should it be absolute, so that a printed copy of
	# the FAQ is worth something? I have been choosing the latter, so I'll
	# stick with it.
	# I escape() the target here because (a) it's HTML spec, and (b) then
	# it doesn't have any characters that get 'entified' which (rightfully)
	# some browsers pass back verbatim to the webserver and everything
	# breaks. (jon@clearink.com reported an instance of this, but I didn't
	# track it down until now.)
	# hthielen@users.sourceforge.net sent the following patch to prevent
	# us from linkifying anything without a ':'. This heuristic allows
	# usage examples: cat <infile> > <outfile>, which would otherwise
	# become link because the contents have no whitespace.
	# Arrgh. Vile escaping. :v)
	my $result;
	if (defined $prefix) {
	    if ($target ne '') {
			$result = "<a href=\"$target\">$label</a>";
	    } else {
			# this is for e.g. "baginline:" references
			$result = $label;
	    }
	} else {
		# just return the original text including the already
		# removed "<" and ">" signs
		$result = "&lt;" . $label . "&gt;";
	}
	return $result;
}

sub fuzzyMatch {
	# In 2.707 and older FOMs, any text in the body of a text part that
	# looked remotely like a URL got linkified. The rules for finding
	# such links (and more importantly, figuring out where they end) were
	# clumsy and unreliable, so the new prefered method is to put what
	# you want to get linked in <angle_brackets>. This fuzzy matching
	# code is retained for admins of older FAQs who don't want their
	# older-style "magically recognized" links to lose their magic.
	my $params = shift;
	my $ishtml = shift;
	my $isdir = shift;
	my $arg = shift;	# text to fuzzy-match for URLS

  if (not $ishtml) {
    $arg =~ s#(https?:[^\s"]*[^\s.,)\?!])#urlReference($params,$isdir,$1)#sge;
    $arg =~ s#(ftp://[^\s"]*[^\s.,)\?!])#urlReference($params,$isdir,$1)#sge;
    $arg =~ s#(gopher://[^\s"]*[^\s.,)\?!])#urlReference($params,$isdir,$1)#sge;
    $arg =~ s#(telnet://[^\s"]*[^\s.,)\?!])#urlReference($params,$isdir,$1)#sge;
    $arg =~ s#(mailto:\S+@\S*[^\s.,)\?!])#urlReference($params,$isdir,$1)#sge;
	$arg =~ s#(news:[^\s"]*[^\s.,)\?!])#urlReference($params,$isdir,$1)#sge;
	# THANKS: njl25@cam.ac.uk for pointing out the absence of the news: regex
  }

	# These get parsed even in HTML text. They're "value added." :v)
	$arg =~ s#<?(faqomatic:\S*[^\s.,)\?!>])>?#urlReference($params,$isdir,$1)#sge;
	$arg =~ s#<?(baginline:\S*[^\s.,)\?!>])>?#urlReference($params,$isdir,$1)#sge;
	$arg =~   s#<?(baglink:\S*[^\s.,)\?!>])>?#urlReference($params,$isdir,$1)#sge;

	return $arg;
}

# no entifying; only faqomatic: and mailto: links are massaged.
sub insertLinksText {
	my $params = shift;
	my $arg = shift;
	my $ishtml = shift || 0;
	my $isdirectory = shift || 0;

	$arg =~ s#faqomatic:(\S*[^\s.,)\?!])#"(*) ".faqomaticReferenceText($params,$1)#sge;
	# TODO: baginlines could map to the stored "alt" tag, if we start
	# storing one. :v)
	$arg =~ s#(mailto:\S+@\S*[^\s.,)\?!])#"(*) ".mailtoReference($params,$1)#sge;

	return $arg;
}

sub entify {
	my $arg = shift;
	$arg =~ s/&/&amp;/sg;
	$arg =~ s/</&lt;/sg;
	$arg =~ s/>/&gt;/sg;
	$arg =~ s/"/&quot;/sg;
	return $arg;
}

# returns ref to %theParams
sub getParams {
	if (not defined $_[0]) {
		return $theParams;
	}

	my $cgi = shift;
	my $dontLog = shift;	# so statgraph requests don't count as hits
	my $i;

	foreach $i ($cgi->param()) {
		$theParams->{$i} = $cgi->param($i);
	}

	# Log this access
	FAQ::OMatic::Log::logEvent($theParams) if (not $dontLog);

	# set up DIEs to panic and WARNs to note in log.
	# grep log for "Perl" to see if this is happening.
	# We only do this in getParams so that command-line utils
	# don't get confused.
	$SIG{__WARN__} = sub { gripe('note', "Perl warning: ".$_[0]); };
	# so it turns out SIGs are the wrong way to catch die()s. Evals
	# are the right way.
	# $SIG{__DIE__} = sub { gripe('panic', "Perl died: ".$_[0]); };

	return $theParams;
}

# if a param is equal to the default interpretation, we can just
# delete the param. This keeps urls short, and helps us identify
# when the user can be sent over to the cache for faster service.
# Plus, it lets admins configure site defaults that override the
# shipped defaults.

sub defaultParams {
	# This is a local, not a constant, so that mod_perl admins aren't
	# confused when they rewrite the *Default admin parameters (this
	# way they don't get stuck in the mod_perl cache).
	my $defaultParams = getLocal('defaultParams');
	if (not defined $defaultParams) {
		$defaultParams = {
			'cmd' => 'faq',
			'render' =>
				$FAQ::OMatic::Config::renderDefault || 'tables',
			'editCmds' =>
				$FAQ::OMatic::Config::editCmdsDefault || 'hide',
			'showModerator' =>
				$FAQ::OMatic::Config::showModeratorDefault || 'hide',
			'showLastModified' =>
				$FAQ::OMatic::Config::showLastModifiedDefault || 'hide',
			'showAttributions' =>
				$FAQ::OMatic::Config::showAttributionsDefault || 'default',
			'textCmds' =>
				$FAQ::OMatic::Config::textCmdsDefault || 'hide',
		};
		setLocal('defaultParams', $defaultParams);
	}
	return $defaultParams;
}

sub getParam {
	my $params = shift;
	my $key = shift;
	if (not ref $params) { FAQ::OMatic::gripe('debug', stackTrace('html')); };
	return $params->{$key} if defined($params->{$key});
	return defaultParams()->{$key} if defined(defaultParams()->{$key});
	return '';
}

sub makeAref {
	my $command = 'faq';
	my $changedParams = {};
	my $refType = '';
	my $saveTransients = '';
	my $blastAll = '';
	my $params = $theParams;	# default to global params (not preferred, tho)
	my $target = '';			# <a TARGET=""> tag
	my $thisDocIs = '';			# prevent conversion to a cache URL
	my $urlBase = '';			# use included params, but specified urlBase
	my $multipart = '';			# tell browser to reply with a multipart POST

	if ($_[0] =~ m/^\-/) {
		# named-parameter style
		while (scalar(@_)>=2) {
			my ($argName, $argVal) = splice(@_,0,2);
			if ($argName =~ m/\-command$/i) {
				$command = $argVal;
			} elsif ($argName =~ m/\-changedParams$/i) {
				$changedParams = $argVal;
			} elsif ($argName =~ m/\-refType$/i) {
				$refType = $argVal;
			} elsif ($argName =~ m/\-saveTransients$/i) {
				$saveTransients = $argVal;
			} elsif ($argName =~ m/\-blastAll$/i) {
				$blastAll = $argVal;
			} elsif ($argName =~ m/\-params$/i) {
				$params = $argVal;
			} elsif ($argName =~ m/\-target$/i) {
				$target = $argVal;
			} elsif ($argName =~ m/\-thisDocIs$/i) {
				$thisDocIs = $argVal;
			} elsif ($argName =~ m/\-urlBase$/i) {
				$urlBase = $argVal;
			} elsif ($argName =~ m/\-multipart$/i) {
				$multipart = $argVal;
			}
		}
		if (scalar(@_)) {
			gripe('problem', "Odd number of args to makeAref()");
		}
	} else {
		$command = shift;
		$changedParams = shift || {};
								# hash ref to new params
		$refType = shift || '';
								# '' => <a href="...">
								# 'POST' => <form method='POST' ...
								# 'GET' => <form method='GET' ...
								# 'url' => just the GET url
		$saveTransients = shift || '';
								# true => don't zap the _params, since
								# they're only passing through an interposing
								# script (authentication script, for example)
		$blastAll = shift || '';
								# true => zap all params, then use
								# changedParams as only new ones.
		$params = shift if (defined($_[0]));
								# given params instead of using icky global
								# ones.
	}

	my %newParams;
	if ($blastAll) {
		%newParams = ();			# blast all existing params
	} else {
		%newParams = %{$params};
	}

	# parameters with a _ prefix are defined to be "transient" -- they
	# never make it into a new Aref. That way we can introduce new
	# transient parameters, and they automatically get deleted here.
	if (not $saveTransients) {
		my $i;
		foreach $i (keys %newParams) {
			delete $newParams{$i} if ($i =~ m/^_/);
		}
	}

	# change the requested parameters
	my $i;
	foreach $i (keys %{ $changedParams }) {
		if (not defined($changedParams->{$i})
			or ($changedParams->{$i} eq '')) {
			delete $newParams{$i};
		} else {
			$newParams{$i} = $changedParams->{$i};
		}
	}
	$newParams{'cmd'} = $command;

	# delete keys where values are equal to defaults
	foreach $i (sort keys %newParams) {
		if (defined(defaultParams()->{$i})
			and ($newParams{$i} eq defaultParams()->{$i})) {
			delete $newParams{$i};
		}
	}

	# So why ever bother generating local references when
	# pointing at the CGI? (That's how faqomatic <= 2.605 worked.)
	# Generating absolute ones means
	# the same links work in the cache, or when the cache file
	# is copied for use elsewhere. It also means that pointing
	# at a mirror version of the CGI should be a minor tweak.
	# Answer: (V2.610) people like
	# THANKS: Mark Nagel
	# need server-relative references, because
	# absolute references won't work -- at their site, servers are
	# accessed through a ssh forwarder. (Why not just use https?)

	my $cgiName;
	if ($urlBase ne '') {
		$cgiName = $urlBase;
	} elsif (not $thisDocIs and
		($FAQ::OMatic::Config::useServerRelativeRefs || 0)) {
		# return a server-relative path (starts with /)
		#$cgiName = FAQ::OMatic::dispatch::cgi()->script_name();
		$cgiName = FAQ::OMatic::cgiURL();
	} else {
		# return an absolute URL (including protocol and server name)
		#$cgiName = FAQ::OMatic::dispatch::cgi()->url();
		$cgiName = FAQ::OMatic::serverBase().FAQ::OMatic::cgiURL();
	}

	# collect args in $rt in appropriate form -- hidden fields for
	# forms, or key=value pairs for URLs.
	my $rt = "";
	foreach $i (sort keys %newParams) {
		my $value = $newParams{$i};
		if (not defined($value)) { $value = ''; }

		if ($refType eq 'POST' or $refType eq 'GET') {
			# GET or POST form. stash args in hidden fields.
			$rt .= "<input type=hidden name=\"$i\" value=\""
				.entify($value)."\">\n";
			# wow, when that entify (analogous to the CGI::escape in the
			# regular GET case below) was missing, it made for awfully
			# subtle bugs! If one of the old params has a " in it (such as
			# would happen if leaving the define-config page and being asked
			# to stop off at the login page), it didn't get escaped, so the
			# browser quietly truncated the value, which made us save a bogus
			# value into the config file. Ouch!
		} else {
			# regular GET, not <form> GET. URL-style key=val&key=val
			$rt.="&".CGI::escape($i)."=".CGI::escape($value);
		}
	}
	if (($refType eq 'POST') or ($refType eq 'GET')) {
		my $encoding = '';
		if ($refType eq 'POST') {
			if ($multipart) {
				# THANKS: charlie buckheit <buckheit@olg.com> for discovering
				# THANKS: this bug, which only shows up in MSIE.
				$encoding = " ENCTYPE=\"multipart/form-data\""
						  	." ENCODING";
			}
		}
		return "<form action=\"".$cgiName."\" "
				."method=\"$refType\""
				."$encoding>\n$rt";
	}

	$rt =~ s/^\&/\?/;	# turn initial & into ?
	my $url = $cgiName.$rt;

	# see if url can be converted to point to local cache instead of CGI.
	if (not $thisDocIs) {
		# $thisDocIs indicates that this URL is going to appear to the
		# user in the "This document is:" line. So it should be a
		# fully-qualified URL, and it should not point to the cache.
		# Otherwise, see if the reference can be resolved in the cache to
		# save one or more future CGI accesses.
		$url = getCacheUrl(\%newParams, $params) || $url;
	}

	if ($refType eq 'url') {
		return $url;
	} else {
		my $targetTag = $target ? " target=\"$target\"" : '';
		return "<a href=\"$url\"$targetTag>";
	}
}

# This function examines $params and if they refer to a page that's
# statically cached, returns a ready-to-eat URL to that page.
# Otherwise it returns ''.
sub getCacheUrl {
	my $paramsForUrl = shift;
	my $paramsForMe = shift;

	# Sometimes we can do *better* than the cache -- a link
	# can point inside this very document! That's true when
	# the document is the result of a "show this entire category."
	# We require the linkee to be a child of the root of this display
	# (i.e., the linked item must appear on this page :v), and the
	# desired URL must have cmd=='' (i.e., looking at the FAQ, not
	# editing it or otherwise). Any other params I think should be
	# appearance-related, and therefore would be the same as the top
	# item being displayed.
	if ($paramsForMe->{'_recurseRoot'}
		and not defined($paramsForUrl->{'cmd'})) {
		my $linkFile = $paramsForUrl->{'file'} || '1';
		my $linkItem = new FAQ::OMatic::Item($linkFile);
		my $topFile = $paramsForMe->{'_recurseRoot'};

		if ($linkItem->hasParent($paramsForMe->{'_recurseRoot'})) {
			return "#file_".$linkFile;
		}
	}

	if ($FAQ::OMatic::Config::cacheDir
		and (not grep {not m/^file$/} keys(%{$paramsForUrl}))
		) {
		if ($paramsForMe->{'_fromCache'}) {
			# We have a link from the cache to the cache.
			# If we let it be relative, then the cache files
			# can be picked up and taken elsewhere, and they still
			# work, even without a webserver!
			return $paramsForUrl->{'file'}
				.".html";
		} else {
			# pointer into the cache from elsewhere (the CGI) -- use a full URL
			# to get them to our cache.

			# clean up the 'file' input so CSS attack can't play games with the
			# resulting URL by faking the file value.
			return FAQ::OMatic::serverBase()
				.$FAQ::OMatic::Config::cacheURL
				.cleanFile($paramsForUrl->{'file'})
				.".html";
		}
	}
	return '';
}

# ensure that a file spec is "clean". Let's say the items
# can only be named things alphanumerics and .-_.
sub cleanFile {
	my $file = shift || '';
	if ($file =~ m/[^a-zA-Z0-9\.\-\_]/s) {
		return '1';
	}
	return $file;
}

sub makeBagRef {
	# Not nearly as tricky as makeAref; this only returns a URL.

	my $bagName = shift;
	my $params = shift;

	if ($params->{'_fromCache'}) {
		# from cache to bags -- can use a local reference; this
		# will allow us to transplant the cache and bags directories
		# from this server to a CD or otherwise portable hierarchy.
		#
		# Notice that we rely here on bags/ and cache/ being in the
		# same parent directory. The presence of separate $bagsURL and
		# $cacheURL configuration items might seem to imply that they're
		# independent paths, but they're not. (So that the previous
		# comment about a 'portable hierarchy' is true.)
		return "../bags/$bagName";
	} elsif (not defined($FAQ::OMatic::Config::bagsURL)) {
		# put a bad URL in the link to make it obviously fail
		return "x:";
	} else {
		return FAQ::OMatic::serverBase()
			.$FAQ::OMatic::Config::bagsURL
			.$bagName;
	}
}

# takes an a href and a button label, and makes a button.
sub button {
	my $ahref = shift;
	my $label = shift;
	my $image = shift || '';
	my $params = shift || {};	# needed to get correct image refs from cache

	#$label =~ s/ /\&nbsp;/g;
	if ($FAQ::OMatic::Config::showEditIcons
		and ($image ne '')) {
		if (($FAQ::OMatic::Config::showEditIcons||'') eq 'icons-only') {
			$label = '';
		} elsif ($label ne '') {
			$label = "<br>$label";
		}
		return "$ahref"
			.FAQ::OMatic::ImageRef::getImageRef($image, 'border=0', $params)
			."$label</a>\n";
	} else {
		return "[$ahref$label</a>]";
	}
}

sub getAllItemNames {
	my $dir = shift || $FAQ::OMatic::Config::itemDir;

	my @allfiles;

	opendir DATADIR, $dir or
		FAQ::OMatic::gripe('problem', "Can't open data directory $dir.");
	while (defined($_ = readdir DATADIR)) {
		next if (m/^\./);
		next if (not -f $dir."/".$_);
			# not sure what the above test is good for. Avoid subdirectories?
		push @allfiles, $_;
	}
	close DATADIR;
	return @allfiles;
}

sub lotsOfApostrophes {
	my $word = shift;
	$word =~ s/(.)/$1'*/go;
	return $word;
}


# Using of locale pragma for entire file can have taint-check fails as
# result.  But search-hits highlighting should be locale dependent.
# Because of this, locale pragma is used for highlightWords() function
# only.
use locale;

sub highlightWords {
	my $text = shift;
	my $params = shift;
	
	my @hw;
	if ($params->{'_highlightWords'}) {
		@hw = split(' ', $params->{'_highlightWords'});
	} elsif ($params->{'_searchArray'}) {
		@hw = @{ $params->{'_searchArray'} };
	}
	if (@hw) {
		my $rt = '';
		@hw = map { lotsOfApostrophes($_) } @hw;

		# we'll use this to split the text into not-matches and
		# "delimiters" (matches). Split returns a list item for every
		# pair of parens, so we need to know how many parens we
		# ended up with. Then we can reassemble the text my taking
		# the zeroth item, which didn't match at all, the first item,
		# which matched the first set of parens (the anti-HTML-bashing
		# set), the fourth item which actually matched the word, then
		# continue with the zero+$numparens+1 item, which is the next
		# "split-ee."
		# see Camel ed. 2 p. 221
		my $matchstr = '((^|>)([^<]*[^\w<&])?)(('.join(')|(',@hw).'))';
		my $numparens = scalar(@hw)+4;
		my @pieces = split(/$matchstr/i, $text);

		# reassemble the split pieces according to the description above
		my $i;
		$rt = '';
		for ($i=0; $i<@pieces; $i+=$numparens+1) {
			$rt .= $pieces[$i+0];
			$rt .= $pieces[$i+1] if ($i+1<@pieces);
			$rt .= $FAQ::OMatic::Appearance::highlightStart
					.$pieces[$i+4]
					.$FAQ::OMatic::Appearance::highlightEnd if ($i+4 < @pieces);
		}
		$text = $rt;
	}
	return $text;
}

# Turn off locale pragma.  See comment about `use locale' near to begin
# of highlightWords() function for reason of this.
no locale;

sub unallocatedItemName {
	my $filename= shift || 1;

	# Things under 'trash' should get allocated in the numerical space.
	# I'm not sure when an item would get created under the trash,
	# but I've seen it happen, and they got called 'trasi'
	# and 'trasj' ... :v)
	# (I've done it deliberately with API.pm to test emptyTrash, though.)
	if ($filename eq 'trash') {
		$filename = 1;
	}

	# If the user is looking for a numeric filename (i.e. supplied no
	# argument), use hint to skip forward to biggest existing file number.
	my $useHint = ($filename =~ m/^\d*$/);
	if ($useHint and
		open HINT, "<$FAQ::OMatic::Config::metaDir/biggestFileHint") {
		$filename = int(<HINT>);
		$filename = 1 if ($filename<1);
		close HINT;
		if (not -e "$FAQ::OMatic::Config::itemDir/$filename") {
			# make sure the hint's valid; else rewind to get earliest empty
			# file
			$filename = 1;
		}
	}
	while (-e "$FAQ::OMatic::Config::itemDir/$filename") {
		$filename++;
	}
	if ($useHint and
		open HINT, ">$FAQ::OMatic::Config::metaDir/biggestFileHint") {
		print HINT "$filename\n";
		close HINT;
	}
	return $filename;
}

sub notACGI {
	return if (not defined $ENV{'QUERY_STRING'});

	print "Content-type: text/plain\n\n";
	print "This script (".commandName().") may not be run as a CGI.\n";
	myExit(0);
}

sub binpath {
	my $binpath = $0;
	$binpath =~ s#[^/]*$##;
	$binpath = "." if (not $binpath);
	return $binpath;
}

sub validEmail {
	# returns true (and the untainted address)
	# if the argument looks like an email address
	my $arg = shift;
	my $cnt = ($arg =~ /^([\w\-.+]+\@[\w\-.+]+)$/);
	return ($cnt == 1) ? $1 : undef;
}

# sends email; returns true if there was a problem.
sub sendEmail {
	my $to = shift;		# array ref or scalar
	my $subj = shift;
	my $mesg = shift;

        my $encode_lang = FAQ::OMatic::I18N::language();
        if($encode_lang eq "ja_JP.EUC") {
            require Jcode; import Jcode;
            require NKF;   import NKF;
            $subj = jcode($subj)->mime_encode;
            $mesg = nkf('-j',$mesg);
        } elsif ($encode_lang ne "en") {
            require MIME::Words; import MIME::Words qw(:all);
            $subj = encode_mimeword($subj,"B");
        }

	return if (not $FAQ::OMatic::Config::mailCommand);

	# untaint $to address
	if (ref $to) {
		$to = join(" ", map {validEmail($_)||''} @{$to});
	} else {
		$to = validEmail($to)||'';
	}
	return 'problem' if ($to =~ m/^\s*$/);
		# found no valid email addresses

	# THANKS Jason R <jasonr@austin.rr.com>.
	# need $PATH to be untainted.
	my $pathSave = $ENV{'PATH'};
	$ENV{'PATH'} = '/bin';

	# X-URL is used to help user to know which FAQ has sent this mail. 
	# THANKS suggested by Akiko Takano <takano@iij.ad.jp>
	# TODO in the case of moderator mail, we probably want this
	# URL to indicate the correct file name, rather than the top of the
	# FAQ. Make it an optional argument to this sub?
	my $xurl = FAQ::OMatic::makeAref('-command'=>'faq',
				'-params'=>{},
				'-thisDocIs'=>1,
				'-refType'=>'url');

	if ($FAQ::OMatic::Config::mailCommand =~ m/sendmail/) {
		my $to2 = $to;
		$to2 =~ s/ /, /g;
		if (not open (MAILX, "|$FAQ::OMatic::Config::mailCommand $to 2>&1 "
							.">>$FAQ::OMatic::Config::metaDir/errors")) {
			return 'problem';
		}


		print MAILX "X-URL: $xurl\n";

		print MAILX "To: $to2\n";
		print MAILX "Subject: $subj\n";
		print MAILX "From: $FAQ::OMatic::Config::adminEmail\n";
		print MAILX "\n";
		print MAILX $mesg;
		close MAILX;
	} else {
		if (not open (MAILX, "|$FAQ::OMatic::Config::mailCommand -s '$subj' $to")) {
			return 'problem';
		}
		# TODO non-sendmail mailers won't get X-URL in the header.
		print MAILX "X-URL: $xurl\n\n";
		print MAILX $mesg;
		close MAILX;
	}
	$ENV{'PATH'} = $pathSave;	# not sure if it's crucial to hang onto this
	return 0;	# no problem
}

# this is a taint-safe glob. It's not as "flexible" as the real glob,
# but safer and probably anything flexible would be not as portable, since
# it would depend on csh idiosyncracies.
sub safeGlob {
	my $dir = shift;
	my $match = shift;		# perl regexp

	return () if (not opendir(GLOBDIR, $dir));

	my @firstlist = map { m/^(.*)$/; $1 } readdir(GLOBDIR);
		# untaint data -- we can hopefully trust the operating system
		# to provide a valid list of files!
	my @filelist = map { "$dir/$_" } (grep { m/$match/ } @firstlist);
	closedir GLOBDIR;

	return @filelist;
}

# for debugging -T
sub isTainted {
	my $x;
	not eval {
		$x = join("",@_), kill 0;
		1;
	};
}

# the crummy "require 'flush.pl';" is not acting reliably for me.
# this is the same routine [made strict], but copied into this package. Grr.
sub flush {
	my $old = select(shift);
    $| = 1;
	print "";
	$| = 0;
	select($old);
}

sub canonDir {
	# canonicalize a directory path:
	# make sure dir ends with one /, and has no // sequences in it
	my $dir = shift;
	$dir =~ s#$#/#;		# add an extra / on end
	$dir =~ s#//#/#g;	# strip any //'s, including the one we possibly
						# put on the end.
	return $dir;
}

sub concatDir {
	my $dir1 = shift;
	my $dir2 = shift;

	return canonDir(canonDir($dir1).canonDir($dir2));
}

sub cardinal_en {
	my $num = shift;
	my %numsuffix=('0'=>'th', '1'=>'st', '2'=>'nd', '3'=>'rd', '4'=>'th',
				   '5'=>'th', '6'=>'th', '7'=>'th', '8'=>'th', '9'=>'th');
	my $suffix = ($num>=11 and $num<=19) ? 'th' : $numsuffix{substr($num,-1,1)};
	return $num."<sup>".$suffix."</sup>";
}

sub cardinal {
        my $num = shift;
        return $num.".";
}

sub describeSize {
	my $num = shift;

	if ($num > 524288) {
		return sprintf("(%3.1f M)", $num/1048576);	# megabytess
	} elsif ($num > 512) {
		return sprintf("(%3.1f K)", $num/1024);		# kilobytes
	} else {
		return "($num bytes)";
	}
}

# This is a variation on system().
# If it succeeds, you get an empty list ().
# If it fails (nonzero result code), you get a list containing the
# exit() value, the signal that stopped the process, the $! translation
# of the exit() value, and all of the text the child sent to stdout and
# stderr.
sub mySystem {
	my $cmd = shift;
	my $alwaysWantReply = shift || 0;

	my $count = 0;
	my $pid;

	# flush now, lest data in a buffer get flushed on close() in every stinking
	# child process.
	flush(\*STDOUT);
	flush(\*STDERR);

	pipe READPIPE, WRITEPIPE or die "getting pipes";
	# "bulletproof fork" from camel book, 2ed, page 167
	FORK: {
		$count++;
		if ($pid = fork()) {
			# parent here; child in $pid
			close WRITEPIPE;
			# (drop out of conditional to parent code below to wait for child)
		} elsif (defined $pid) {
			# child here

			# set real uid = effective uid,
			#     real gid = effective gid.
			# this keeps RCS from choking in suid situations.
			# RCS has really weird rules about how it uses real and effective
			# uids which probably make a lot of sense when multiple users
			# are competing for the same RCS store.
			$< = $>;
			$( = $);

			close READPIPE;		# close our fd to the other end of the pipe
			close STDOUT;		# redirect stderr, stdout into the pipe
			open STDOUT, ">&WRITEPIPE";
			close STDERR;
			open STDERR, ">&WRITEPIPE";
			close STDIN;		# don't let child dangle on stdin
			$ENV{'PATH'} = '/bin';	# THANKS Jason R <jasonr@austin.rr.com>.
			exec $cmd;
			die "mySystem($cmd) failed: $!\n";
			CORE::exit(-1);		# be sure child exits; don't go back
								# and try to be a web server again (in the
								# mod_perl case).
			# TODO: the preceding die will probably result in myExit()
			# getting called, and hence mod_perl continuing to run. Hmmph.
		} elsif (($count < 5) && $! =~ /No more process/) {
			# EAGAIN, supposedly recoverable fork error
			sleep(5);
			redo FORK;
		} else {
			die "Can't fork: $! (tried $count times)\n";
		}
	}

	my @stdout = <READPIPE>;	# read child output in its entirety
	close READPIPE;
	# THANKS nobody/anonymous (at sourceforge) submitted this bug fix
	# (#508199); s/he said:
	#     "The current code generates a failure code if waitpid
	#     finds no child process to wait
	#     for ($? == -1) but this is reported as a failure of the
	#     mySystem call. The following
	#     patch changes the pickup of the $statusword value to
	#     look at the pipe close event
	#     instead."
	my $statusword = $?;

	my $stdout = join('', @stdout);
	my $wrc = waitpid($pid, 0);		# just in case

	my $signal = $statusword & 0x0ff;
	my $exitstatus = ($statusword >> 8) & 0x0ff;
	if ($exitstatus == 0 and not $alwaysWantReply) {
		return ();
	} else {
		return ($exitstatus,$signal,$!,$stdout,\@stdout,"pid=$pid","wrc=$wrc");
	}
}

# TODO we now have two stacktrace-collectors. Clean this up.
sub stackTrace {
	my $html = shift;
	my $linesep = ($html)
		? '<br>'
		: '';

	my $rt = '';
	my $i=0;
	while (my ($pack, $file, $line) = caller($i++)) {
		$rt .= "$pack $file ${line}${linesep}\n";
	}
	return $rt;
}

sub mirrorsCantEdit {
	my $cgi = shift;
	my $params = shift;

	if ($FAQ::OMatic::Config::mirrorURL) {
		# whoah -- we're a mirror site, and the user wants to
		# edit! Send them to the original site.
		my $url = makeAref('-command' => commandName(),
			'-urlBase'=>$FAQ::OMatic::Config::mirrorURL,
			'-refType'=>'url');
		FAQ::OMatic::redirect($cgi, $url);
	}
}

sub authorList {
	my $params = shift;
	my $listRef = shift;
	my $render = getParam($params, 'render');

	my $rt = '';
	if ($render ne 'text') {
		$rt .= "<i>";
	} else {
		$rt .= "[";
	}
	$rt .= join(", ", map { FAQ::OMatic::mailtoReference($params, $_) }
			@{$listRef});
	if ($render ne 'text') {
		$rt .= "</i><br>";
	} else {
		$rt .= "]";
	}
	$rt .= "\n";
	return $rt;
}

# inspired by mod_perl docs: dynamically detect mod_perl and adjust
# exit() strategy.
BEGIN {
	# Auto-detect if we are running under mod_perl or CGI.
	$USE_MOD_PERL = ( (exists $ENV{'GATEWAY_INTERFACE'}
			and $ENV{'GATEWAY_INTERFACE'} =~ /CGI-Perl/)
		or exists $ENV{'MOD_PERL'} ) ? 1 : 0;
}

sub myExit {
	# "Select the correct exit way"
	my $arg = shift;
	if ($USE_MOD_PERL) {
		# Apache::exit(-2) will cause the server to exit gracefully,
		# once logging happens and protocol, etc (-2 == Apache::Constants::DONE)
		# in any case, I don't think we want it.
		Apache::exit(0);
	} else {
		CORE::exit($arg);
	}
}

sub nonce {
	# return a string that's "pretty unique". We do this by returning
	# the time concatenated with the process ID. That's unlikely to repeat.
	# It would require a single process (say a mod_perl apache child proc
	# serving two requests) calling this function twice in a second.
	# TODO: that's not really that unreasonable. It would be better if we
	# could add some other source of uniqueness here.
	return time().'p'.$$;
}

sub stripnph {
	my $hdr = shift;

	# strip off the HTTP/1.0 header line, because we're not
	# really an nph script
	$hdr =~ s#^HTTP/[^\n]*\n##s;
	return $hdr;
}

sub header {
	my $cgi = shift;
	my $charset = gettext("http-charset");
	my $hdr = stripnph($cgi->header((@_,'-charset'=>$charset), '-nph'=>1));
	return $hdr;
}

sub redirect {
	my $cgi = shift;
	my $url = shift || die 'no argument to redirect';
	my $asString = shift || '';

	# pretend to be nph to work around what I think is a bug in CGI.pm
	# wherein if we're not nph, it sends the header immediately rather
	# than returning it.
	my $rd = stripnph($cgi->redirect('-url'=>$url, '-nph'=>1));
		# -nph is true to prevent mod_perl version of CGI from attempting
		# to squirt out the header itself. (CGI.pm 2.49)

	if ($asString) {
		return $rd;
	} else {
		print $rd;
		flush('STDOUT');
		myExit(0);
	}
}

sub rearrange {
	# inspired by CGI.pm
	my ($order, @p) = @_;

	if (defined $p[0]
		and substr($p[0],0,1) eq '-') {
		my %posh = ();
		my @outary = ();
		for (my $i=0; $i<@{$order}; $i++) {
			$posh{$order->[$i]} = $i;
		}
		while (@p) {
			my $k = shift @p;
			my $v = shift @p;
			if (not defined $v) {
				die "key $k with no value";
			}
			$k =~ s/^\-//;
			if (exists $posh{$k}) {
				$outary[$posh{$k}] = $v;
			} else {
				gripe('abort', "unexpected key ($k) received in rearrange");
			}
		}
		return @outary;
	} else {
		return @p;
	}
}

sub quoteText {
	my $text = shift;
	my $prefix = shift;

	# not sure why s/^/> /mg gives a "Substitution loop" error from some Perls.
	# this is a workaround.

	return join('', map { $prefix.$_."\n" } split(/\n/, $text));
}

sub untaintFilename {
	# strips out most chars but 'A-Za-z0-9_-.' A little overly restrictive,
	# but good for when you want to read a file but don't want
	# user sneaking in '../', metachars, shell IFS, or anything
	# sneaky like that.
	my $name = shift;
	if ($name =~ m/^([A-Za-z0-9\_\-\.]+)$/) {
		return $1;
	} else {
		return '';
	}
}

sub cat {
	my $filename = untaintFilename(shift());	# must be in metaDir

	if ($filename eq '') {
		return "['$filename' has funny characters]";
	}

	open (CATFILE, "<$FAQ::OMatic::Config::metaDir/$filename")
		or return "[can't open '$filename': $!]";
	my @lines = <CATFILE>;
	close CATFILE;

	return join('', @lines);
}

# returns true to enable original DBM-based search database code.
# (in false mode, search is linear scans of files. Slow, but robust.)
sub usedbm {
	return $FAQ::OMatic::Config::useDBMSearch || '';
}

sub checkLoadAverage {
	if (1) {
		# this cobbled feature has no install-page hook; turn it off for now.
		return;
	}
	my $uptime = `uptime`;
	$uptime =~ m/load average: ([\d\.]+)/;
	my $load = $1;
	if ($load > 4) {
		FAQ::OMatic::gripe('abort',
			"I'm too busy for that now. (I'm kind of a crummy PC.)");
	}
}

# Return the integer prefix to this string, or 0.
# Used to fix "argument isn't numeric" warnings.
sub stripInt {
	my $str = shift;
	if (not defined $str) {
		return 0;
	}
	if (not $str =~ m/^([\d\-]+)/) {
		return 0;
	}
	return $1;
}

'true';
