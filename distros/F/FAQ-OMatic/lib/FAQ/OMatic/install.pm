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
### install.pm
###
### This module allows the administrator to install and configure a
### Faq-O-Matic.
###

my $VERSION = undef;	# mod_perl really won't care about this file-scoped 'my'
# This is NOT really the version number. See FAQ/OMatic.pm.
# THANKS: "Andreas J. Koenig" <andreas.koenig@anima.de> says that I need
# THANKS: a dummy VERSION string to fix a weird interaction among MakeMaker,
# THANKS: CPAN, and FAQ-O-Matic encountered by
# THANKS: "Larry W. Virden" <lvirden@cas.org>.

package FAQ::OMatic::install;

use Config;
use CGI;
use Digest::MD5 qw(md5_hex);
use FAQ::OMatic;
use FAQ::OMatic::Item;
use FAQ::OMatic::Part;
use FAQ::OMatic::Versions;
use FAQ::OMatic::I18N;
use FAQ::OMatic::ColorPicker;
use FAQ::OMatic::maintenance;

use vars qw($params $configInfo);	# file-scoped, mod_perl-safe

sub main {
	$params = {};

	if ($FAQ::OMatic::Config::secureInstall) {
		require FAQ::OMatic::Auth;
		# make params available to FAQ::OMatic::Auth::getId
		$params = FAQ::OMatic::getParams(cgi(), 'dontlog');
		my ($id,$aq) = FAQ::OMatic::Auth::getID();
		# THANKS to Joerg Schneider <joergs@mail.deuba.com> for
		# sending in this patch that lets the admin set the permissions
		# for who (else) can get to the install page.
		if (($id ne $FAQ::OMatic::Config::adminAuth) or ($aq<5)) {
			FAQ::OMatic::Auth::ensurePerm('-item'=>'',
				'-operation'=>'PermInstall',
				'-restart'=>FAQ::OMatic::commandName(),
				'-cgi'=>cgi(),
				'-failexit'=>1);
		}
	} elsif (defined($main::temporaryCryptedPassword)) {
		# secureInstall isn't set -- the temporary password must be
		# present.
		my $tcp = $main::temporaryCryptedPassword;
		my $temppass = cgi()->param('temppass') || '';
		my $crtemppass = md5_hex($temppass);
		if ($crtemppass ne $tcp) {
			tempPassPage();
			FAQ::OMatic::myExit(0);
		}
		# else temp pass matched -- accept it.
	}

	if ((cgi()->param('step')||'') eq 'makeSecure') {
		makeSecureStep();	# don't print text/html header
	} else {
		print FAQ::OMatic::header(cgi(), '-type'=>"text/html");
		print cgi()->start_html('-title'=>gettext("Faq-O-Matic Installer"),
								'-bgcolor'=>"#ffffff");
	
		doStep(cgi()->param('step'));

		print cgi()->end_html();
	}
}

sub doStep {
	my $step = shift || '';

	my %knownSteps = map {$_=>$_} qw(
		default			askMeta			configMeta		initConfig
		mainMenu		
		configItem		askConfig
		firstItem		initMetaFiles					setConfig
		maintenance		makeSecure
		colorSampler	askColor		setColor
		copyItems		configVersion
		);

	if ($knownSteps{$step}) {
		# look up subroutine dynamically.
		$step = $knownSteps{$step};		# untaint input
		my $expr = $step."Step()";
		eval($expr);
		if ($@) {
			displayMessage(gettexta("%0 failed: ", $step).$@
				.FAQ::OMatic::stackTrace('html'), 'default');
		}
	} elsif ($step eq '') {
		doStep('default');
	} else {
		displayMessage(gettexta("Unknown step: \"%0\".", $step), 'default');
	}
}

sub defaultStep {
	if ((-f FAQ::OMatic::dispatch::meta()."/config")
		and (FAQ::OMatic::dispatch::meta()
			ne ($FAQ::OMatic::Config::metaDir||''))) {
		# CGI stub points at a valid config file, but config hasn't
		# been updated. This happens if admin moves meta dir and
		# fixes the stub.
		displayMessage(gettexta("Updating config to reflect new meta location <b>%0</b>.",
				FAQ::OMatic::dispatch::meta()));
  		my $map = readConfig();
		$map->{'$metaDir'} = "'".FAQ::OMatic::dispatch::meta()."'";
  		writeConfig($map);
  		rereadConfig();
  		doStep('mainMenu');
		FAQ::OMatic::myExit(0);
	}

	my $meta = $FAQ::OMatic::Config::metaDir || './';
	if (-f "$meta/config") {
		# There's a config file in the directory pointed to by the
		# CGI stub. We're can run the main menu and do everything else
		# from there now.
		doStep('mainMenu');
	} else {
		# Can't see a config file. Offer to create it for admin.
		displayMessage(gettexta("(Can't find <b>config</b> in '%0' -- assuming this is a new installation.)", $meta));
		doStep('askMeta');
	}
}

sub askMetaStep {
	my $rt = '';
	use Cwd;

	# THANKS Jason R <jasonr@austin.rr.com>. On his platform (HPUX?),
	# the Cwd module depends on an untainted $PATH.
	my $pathSave = $ENV{'PATH'};
	$ENV{'PATH'} = '/bin';
	my $stubMeta = cwd();
	$ENV{'PATH'} = $pathSave;

	if (FAQ::OMatic::dispatch::meta() =~ m#^/#) {
		$stubMeta = "";			# stub meta is an absolute path
	} else {
		$stubMeta =~s#/$##;		# stub meta is relative to cwd
		$stubMeta .= "/";
	}
	$stubMeta.="<b>".FAQ::OMatic::dispatch::meta()."</b>";

	$rt.="<a href=\"".installUrl('configMeta')."\">".gettexta("Click here</a> to create %0.", $stubMeta)."<p>\n";

	$rt.=gettext("If you want to change the CGI stub to point to another directory, edit the script and then");
	$rt.="\n<a href=\""
		.installUrl('default')
		."\">".gettext("click here to use the new location")."</a>.<p>\n";

	$rt.=gettexta("FAQ-O-Matic stores files in two main directories.<p>The <b>meta/</b> directory path is encoded in your CGI stub (%0). It contains:", $0);
        $rt.=gettext("<ul><li>the <b>config</b> file that tells FAQ-O-Matic where everything else lives. That's why the CGI stub needs to know where meta/ is, so it can figure out the rest of its configuration. <li>the <b>idfile</b> file that lists user identities. Therefore, meta/ should not be accessible via the web server. <li>the <b>RCS/</b> subdirectory that tracks revisions to FAQ items. <li>various hint files that are used as FAQ-O-Matic runs. These can be regenerated automatically.</ul>");
        $rt.=gettext("<p>The <b>serve/</b> directory contains three subdirectories <b>item/</b>, <b>cache/</b>, and <b>bags/</b>. These directories are created and populated by the FAQ-O-Matic CGI, but should be directly accessible via the web server (without invoking the CGI).");
        $rt.=gettext("<ul><li>serve/item/ contains only FAQ-O-Matic formatted source files, which encode both user-entered text and the hierarchical structure of the answers and categories in the FAQ. These files are only accessed through the web server (rather than the CGI) when another FAQ-O-Matic is mirroring this one. <li>serve/cache/ contains a cache of automatically-generated HTML versions of FAQ answers and categories. When possible, the CGI directs users to the cache to reduce load on the server. (CGI hits are far more expensive than regular file loads.) <li>serve/bags/ contains image files and other ``bags of bits.'' Bit-bags can be linked to or inlined into FAQ items (in the case of images). </ul>");

	displayMessage($rt);
}

sub configMetaStep {
	my $rt.='';

	my $meta = FAQ::OMatic::dispatch::meta();
	if (not -d "$meta/.") {
		# try mkdir
		if (not mkdir(stripSlash($meta), 0700)) {
			displayMessage(gettexta("I couldn't create <b>%0</b>: %1" , $meta, $!));
			doStep('askMeta');
			return;
		}
		displayMessage(gettexta("Created <b>%0</b>.", $meta));
	}
	if (not -w "$meta/.") {
		displayMessage(gettexta("I don't have write permission to <b>%0</b>.", $meta));
		doStep('askMeta');
		return;
	}
	my $rcsDir = FAQ::OMatic::concatDir($meta, "/RCS/");
	if (not -d $rcsDir) {
		# try mkdir
		if (not mkdir(stripSlash($rcsDir), 0700)) {
			displayMessage(gettexta("I couldn't create <b>%0</b>: %1", $rcsDir, $!));
			doStep('askMeta');
			return;
		}
		displayMessage(gettexta("Created <b>%0</b>.", $rcsDir));
	}
	if (not -w "$rcsDir.") {
		displayMessage(gettexta("I don't have write permission to <b>%0</b>.", $rcsDir));
		doStep('askMeta');
		return;
	}

	doStep('initConfig');
}

sub initConfigStep {
	if (not -f FAQ::OMatic::dispatch::meta()."/config") {
		my $metaDfl = FAQ::OMatic::dispatch::meta();
		$metaDfl .= "/" if (not $metaDfl =~ m#/$#);
		my $mailDfl = which("sendmail") || which("mailx");
	
		if ($mailDfl=~m/mailx/) {
			# `` changed to mySystem() call to avoid -T error on some
			# machines.
			# THANKS Thomas Hiller <hiller@tu-harburg.de>
			my @lrc = FAQ::OMatic::mySystem('/bin/uname -s', 'always');
			if ((defined $lrc[3]) and ($lrc[3] =~ m/Linux/i)) {
				# linux mailx doesn't work like we'd hope. Let's go for
				# /bin/mail (which takes -s on linux), and if that fails,
				# leave it blank and hold out hope that the admin will supply
				# a path to sendmail.
				$mailDfl = which("mail");
			}
		}
	
		my $map = getPotentialConfig();

		# THANKS: to Jim Adler <jima@sr.hp.com> for this fix that
		# keeps HP-UX's RCS happy. (I'd recommend just installing
		# GNU RCS, but this will be convenient for some.)
		my $ciDfl = $map->{'$RCSci'};
		if ($Config{osname} eq 'hpux' and
			($ciDfl eq '/usr/bin/ci' or $ciDfl eq '/bin/ci')) {
			#TODO don't know if this handles '-k' correctly.
			$map->{'$RCSciArgs'} = "'-l -mnull'";
		}

		$map->{'$metaDir'} = "'".$metaDfl."'";
		$map->{'$mailCommand'} = "'".$mailDfl."'";
	
		writeConfig($map);
		displayMessage(gettext("Created new config file."));
	}

	doStep('initMetaFiles');
}

sub initMetaFilesStep {
	if (not open(IDFILE, ">>".FAQ::OMatic::dispatch::meta()."/idfile")) {
		displayMessage(gettexta("I couldn't create <b>%0</b>: %1",
				FAQ::OMatic::dispatch::meta()."/idfile", $!),
			'askMeta');
		return;
	}
	close IDFILE;
	displayMessage(gettext("The idfile exists."));

	doStep('default');
}

sub which {
	my $prog = shift;
	foreach my $path (split(':', $ENV{'PATH'})) {
		if (-x "$path/$prog") {
			return "$path/$prog";
		}
	}
	return '';
}

sub rereadConfig {
	# reread config if available, so that we immediately reflect
	# any changes.
	if (-f FAQ::OMatic::dispatch::meta()."/config") {
		open IN, FAQ::OMatic::dispatch::meta()."/config";
		my @cfg = <IN>;
		close IN;
		my $cfg = join('', @cfg);

		$cfg =~ m/^(.*)$/s;	 # untaint (since data is from a file)
		$cfg = $1;

		{
			no strict 'vars';
				# config file is not written in 'strict' form (vars are
				# not declared/imported).
			local $SIG{'__WARN__'} = sub { die $_[0] };
				# ensure we can see any warnings that come from the eval
			eval($cfg);
			die $@ if ($@);
		}
	}
}

sub mainMenuStep {
	my $rt='';

	rereadConfig();

	my $maintenanceSecret = $FAQ::OMatic::Config::maintenanceSecret || '';
	my $mirror = ($FAQ::OMatic::Config::mirrorURL||'') ne '';

	my $par = "";	# "<p>" for more space between items

	$rt.="<h3>".gettext("Configuration Main Menu (install module)")."</h3>\n";
	$rt.=gettexta("Perform these tasks in order to prepare your FAQ-O-Matic version %0:",
			$FAQ::OMatic::VERSION)
		."\n<ol>";
	$rt.="$par<li><a href=\"".installUrl('askConfig')."\">"
			.checkBoxFor('askConfig')
			.gettext("Define configuration parameters")."</a>\n";
	if (not $FAQ::OMatic::Config::secureInstall) {
		if ($FAQ::OMatic::Config::mailCommand and $FAQ::OMatic::Config::adminAuth) {
			$rt.="$par<li><a href=\"".installUrl('makeSecure')."\">"
				.checkBoxFor('makeSecure')
				.gettext("Set your password and turn on installer security")
				."</a>\n";
		} else {
			$rt.="$par<li>"
				.checkBoxFor('makeSecure')
				.gettext("Set your password and turn on installer security")
				.gettext("(Need to configure \$mailCommand and \$adminAuth)")
				."\n";
		}
	} else {
		$rt.="$par<li>"
			.checkBoxFor('makeSecure')
			.gettext("(Installer security is on)")
			."\n";
	}
	$rt.="$par<li><a href=\"".installUrl('configItem')."\">"
			.checkBoxFor('configItem')
			.gettext("Create item, cache, and bags directories in serve dir")
			."</a>\n";

	if (not $mirror) {
		if (defined($FAQ::OMatic::Config::itemDir_Old)) {
			$rt.="$par<li>"
				."<a href=\"".installUrl('copyItems')."\">"
				.checkBoxFor('copyItems')
				.gettexta("Copy old items</a> from <tt>%0</tt> to <tt>%1</tt>.",
					$FAQ::OMatic::Config::itemDir_Old,
					$FAQ::OMatic::Config::itemDir)
				."\n";
			$rt.="$par<li>"
				."<a href=\"".installUrl('firstItem')."\">"
				.checkBoxFor('firstItem')
				.gettext("Install any new items that come with the system")
				."</a>\n"
		} else {
			$rt.="$par<li><a href=\"".installUrl('firstItem')."\">"
				.checkBoxFor('firstItem')
				.gettext("Create system default items")
				."</a>\n";
		}

		$rt.="$par<li>"
			.checkBoxFor('rebuildCache')
			."<a href=\"".installUrl('', 'url', 'maintenance')
			."&secret=$maintenanceSecret&tasks=rebuildCache\">"
			.gettext("Rebuild the cache and dependency files")
			."</a>\n";
	
		$rt.="$par<li>"
			.checkBoxFor('systemBags')
			."<a href=\"".installUrl('', 'url', 'maintenance')
			."&secret=$maintenanceSecret&tasks=bagAllImages\">"
			.gettext("Install system images and icons")
			."</a>\n";
	} else {
		# mirror sites should update now
		$rt.="$par<li>"
			.checkBoxFor('nothing')
			."<a href=\"".installUrl('', 'url', 'maintenance')
			."&secret=$maintenanceSecret&tasks=mirrorClient\">"
			.gettext("Update mirror from master now. (this can be slow!)")
			."</a>\n";
	}

	$rt.="$par<li><a href=\"".installUrl('maintenance')."\">"
			.checkBoxFor('maintenance')
			.gettext("Set up the maintenance cron job")
			."</a>\n";
	if ($maintenanceSecret) {
		$rt.="$par<li><a href=\"".installUrl('', 'url', 'maintenance')
				."&secret=$maintenanceSecret\">"
				.checkBoxFor('manualMaintenance')
				.gettext("Run maintenance script manually now")
				.".</a>\n";
	} else {
			$rt.="$par<li>"
				.checkBoxFor('manualMaintenance')
				.gettext("Run maintenance script manually now")
				." "
				.gettext("(Need to set up the maintenance cron job first)")
				.".\n";
	}
	my $lm = FAQ::OMatic::maintenance::readMaintenanceHint();
	my $lmstr = $lm
		? FAQ::OMatic::Item::compactDate($lm)
		: "never";
	$rt.="<br>".checkBoxFor('nothing')
		.gettext("Maintenance last run at:")
		." $lmstr\n";

	$rt.="$par<li><a href=\"".installUrl('configVersion')."\">"
		.checkBoxFor('configVersion')
		.gettexta("Mark the config file as upgraded to Version %0",
		          $FAQ::OMatic::VERSION)
                ."</a>\n";

	$rt.="$par<li><a href=\"".installUrl('colorSampler')."\">"
			.checkBoxFor('customColors')
			.gettext("Select custom colors for your Faq-O-Matic</a> (optional)")
			.".\n";
	$rt.="$par<li><a href=\"".installUrl('', 'url', 'editGroups')."\">"
			.checkBoxFor('customGroups')
			.gettext("Define groups</a> (optional)")
			.".\n";

	# THANKS: to John Goerzen for discovering the CGI.pm/bags bug
	$rt.="$par<li>"
			.checkBoxFor('CGIversion')
			.gettext("Upgrade to CGI.pm version 2.49 or newer.")
			.($CGI::VERSION >= 2.49
				? ''
				: " ".gettext("(optional; older versions have bugs that affect bags)")."\n"
			)
			." "
			.gettexta("You are using version %0 now.", $CGI::VERSION)
			."\n";

	$rt.="$par<li>".checkBoxFor('nothing')
			."<a href=\"".installUrl('mainMenu')."\">"
			.gettext("Bookmark this link to be able to return to this menu.")
			."</a>\n";
	if ($FAQ::OMatic::Config::secureInstall) {
		$rt.="$par<li>".checkBoxFor('nothing')
				."<a href=\"".installUrl('', 'url', 'faq')."\">"
				.gettext("Go to the Faq-O-Matic")
				."</a>\n";
	} else {
		$rt.="$par<li>".checkBoxFor('nothing')
			.gettext("Go to the Faq-O-Matic")
			." "
			.gettext("(need to turn on installer security)");
	}
	$rt.="</ol>\n";
	$rt.="<ul><u>".gettext("Other available tasks:")."</u>\n";
	$rt.="$par<li>"
			.checkBoxFor('nothing')
			."<a href=\"".installUrl('','url','stats')."\">"
			.gettext("See access statistics")
			."</a>\n";
	$rt.="$par<li>"
			.checkBoxFor('nothing')
			."<a href=\"".installUrl('','url','selectBag')."\">"
			.gettext("Examine all bags")
			."</a>\n";
	$rt.="$par<li>"
		.checkBoxFor('nothing')
		."<a href=\"".installUrl('', 'url', 'maintenance')
		."&secret=$maintenanceSecret&tasks=expireBags\">"
		.gettext("Check for unreferenced bags (not linked by any FAQ item)")
		."</a>\n";
	$rt.="$par<li>"
		.checkBoxFor('nothing')
		."<a href=\"".installUrl('', 'url', 'maintenance')
		."&secret=$maintenanceSecret&tasks=emptyTrash\">"
		.gettext("Empty old trash now")
		."</a>\n";
	$rt.="$par<li>"
		.checkBoxFor('nothing')
		."<a href=\"".installUrl('', 'url', 'maintenance')
		."&secret=$maintenanceSecret&tasks=fsck\">"
		.gettext("fsck (check and repair tree structure) now")
		."</a>\n";
	$rt.="$par<li>"
		.checkBoxFor('nothing')
		."<a href=\"".installUrl('', 'url', 'maintenance')
		."&secret=$maintenanceSecret&tasks=buildSearchDB&force=true\">"
		.gettext("rebuild search database now")
		."</a>\n";
	# rebuildCache shows up again at the end, because it doesn't show
	# up in the numbered list if this is a mirror site.
	$rt.="$par<li>"
		.checkBoxFor('nothing')
		."<a href=\"".installUrl('', 'url', 'maintenance')
		."&secret=$maintenanceSecret&tasks=rebuildCache\">"
		.gettext("Rebuild the cache and dependency files now")
		."</a>\n";
	
	$rt.="</ul>\n";

	$rt.=gettexta("The Faq-O-Matic modules are version %0.", $FAQ::OMatic::VERSION)
		."\n";

	displayMessage($rt);
}

sub isDone {
	my $thing = shift;

	return 1 if (($thing eq 'askConfig')
		&& (($FAQ::OMatic::Config::adminAuth||'') ne '')
		&& not undefinedConfigsExist());
	return 1 if (($thing eq 'configItem')
		&& (($FAQ::OMatic::Config::itemDir||'') ne '')
		&& (-d "$FAQ::OMatic::Config::itemDir/.")
		&& (($FAQ::OMatic::Config::cacheDir||'') ne '')
		&& (-d "$FAQ::OMatic::Config::cacheDir/.")
		&& (($FAQ::OMatic::Config::bagsDir||'') ne '')
		&& (-d "$FAQ::OMatic::Config::bagsDir/."));
	return 1 if (($thing eq 'firstItem')
		&& FAQ::OMatic::Versions::getVersion('Items') eq $FAQ::OMatic::VERSION);
		# The above test ensures that the "create initial items" routine
		# has been run once by this version of the faq. That way as new
		# default initial items are supplied, upgraders don't get a checkbox
		# until they're installed.
	return 1
		if (($thing eq 'maintenance')
					&& ($FAQ::OMatic::Config::maintenanceSecret));
	return 1 if (($thing eq 'makeSecure') && ($FAQ::OMatic::Config::secureInstall));
	return 1 if (($thing eq 'manualMaintenance')
					&& (-f "$FAQ::OMatic::Config::metaDir/lastMaintenance")
					&& (FAQ::OMatic::Versions::getVersion('MaintenanceInvoked')
						eq $FAQ::OMatic::VERSION));
	return 1 if (($thing eq 'customColors')
					&& FAQ::OMatic::Versions::getVersion('CustomColors'));
	return 1 if (($thing eq 'rebuildCache')
					&& (FAQ::OMatic::Versions::getVersion('CacheRebuild')
						eq $FAQ::OMatic::VERSION));
	return 1 if (($thing eq 'customGroups')
					&& FAQ::OMatic::Versions::getVersion('CustomGroups'));
	return 1 if (($thing eq 'systemBags')
					&& (FAQ::OMatic::Versions::getVersion('SystemBags')
						eq $FAQ::OMatic::VERSION));
	return 1 if (($thing eq 'CGIversion')
					&& ($CGI::VERSION >= 2.49));
	return 1 if (($thing eq 'copyItems')
					&& (-f "$FAQ::OMatic::Config::itemDir/1"));
	return 1 if (($thing eq 'configVersion')
					&& ($FAQ::OMatic::Config::version
						eq $FAQ::OMatic::VERSION));

	return 0;
}

sub checkBoxFor {
	my $thing = shift;
	my $done = isDone($thing);

	my $rt = "<img border=0 src=\"";
	if ($thing eq 'nothing') {
		$rt.=installUrl('', 'url', 'img', 'space');
	} elsif ($done) {
		$rt.=installUrl('', 'url', 'img', 'checked');
	} else {
		$rt.=installUrl('', 'url', 'img', 'unchecked');
	}
	$rt.="\"> ";
	return $rt;
}

# sub askItemStep {
# 	my $rt = '';
# 
# 	my $dflItem = stripQuotes(readConfig()->{'$itemDir'});
# 
# 	$rt.="Faq-O-Matic needs a writable directory in which to store\n";
# 	$rt.="FAQ item data. Frequently, this is just a subdirectory of\n";
# 	$rt.="the <b>meta/</b> directory. If you have an existing Faq-O-Matic 2\n";
# 	$rt.="installation, you can enter the path to its <b>item/</b> here,\n";
# 	$rt.="and this installation will use those existing items.\n";
# 	$rt.=installUrl('configItem', 'GET');
# 	$rt.="<input type=text size=60 name=item value=\"$dflItem\">\n";
# 	$rt.="<input type=submit name=junk value=\"Define\">\n";
# 	$rt.="</form>\n";
# 	displayMessage($rt);
# }

sub configItemStep {
	my $rt.='';

	# create item, cache, and bags directories.
	createDir('$item',	'/item/');
	createDir('$cache', '/cache/');
	createDir('$bags',	'/bags/');

	doStep('mainMenu');
}

sub createDir {
	my $dirSymbol = shift;
	my $dirSuffix = shift;

	my $dirPath =
		FAQ::OMatic::concatDir($FAQ::OMatic::Config::serveDir, $dirSuffix);
	my $dirUrl =
		FAQ::OMatic::concatDir($FAQ::OMatic::Config::serveURL, $dirSuffix);

	if (not -d $dirPath) {
		if (not mkdir(stripSlash($dirPath), 0700)) {
			dirFail(gettexta("I couldn't create <b>%0</b>: %1", $dirPath, $!));
			return;
		}
		displayMessage(gettexta("Created <b>%0</b>.", $dirPath));
	}
	if (not -w "$dirPath/.") {
		dirFail(gettexta("I don't have write permission to <b>%0</b>.", $dirPath));
		return;
	}
	if (not chmod 0755, $dirPath) {
		dirFail(gettexta("I wasn't able to change the permissions on <b>%0</b> to 755 (readable/searchable by all).",
						 $dirPath));
		return;
	}

	my $map = readConfig();
	if (defined $map->{$dirSymbol."Dir"}
		and ($map->{$dirSymbol."Dir"} ne "''")) {
		# copy the prior definition. Used so we know where the old
		# $itemDir was after we've created the new one.
		$map->{$dirSymbol."Dir_Old"} = $map->{$dirSymbol."Dir"};
	}
	$map->{$dirSymbol."Dir"} = "'".$dirPath."'";
	$map->{$dirSymbol."URL"} = "'".$dirUrl."'";
	writeConfig($map);
	displayMessage(gettext("updated config file:")." $dirSymbol"."Dir = <b>$dirPath</b>"
		."<br>".gettext("updated config file:")." $dirSymbol"."URL = <b>$dirUrl</b>");
}

sub dirFail {
	my $message = shift;

	displayMessage($message
		."<p>".gettexta("Redefine configuration parameters to ensure that <b>%0</b> is valid.", $FAQ::OMatic::Config::serveDir));
	doStep('mainMenu');
}

# lets me succinctly define configInfo entries
sub ci {
	my $key = shift;
	my $mymap = {};
	my $property;
	while (defined($property = shift(@_))) {
		if (not $property=~m/^-/) {
			FAQ::OMatic::gripe('error',
				gettexta("Jon made a mistake here; key=%0, property=%1.", $key, $property))
		}
		my $val = 1;
		if (scalar(@_) and not $_[0]=~m/^-/) {
			$val = shift(@_);	# shift an argument on, if possible
		}
		$mymap->{$property} = $val;
	}
	return ($key,$mymap);
}

$configInfo = undef;
sub configInfo {
	# init the array inside a sub so that it doesn't get initted unless
	# needed -- some of the defaults call things like which(), which goes
	# out and frobs the filesystem, which is pretty heavyweight.
	if (not defined $configInfo) {
		$configInfo = {
#	config var => [ 'sortOrder|hide', 'description',
#					['unquoted values'], free-input-okay, is-a-command ]
# -desc=>'...'	-- description of variable
# -choices=>[]	-- list of potential choices
# -free			-- provide a free-form input field
# -hide			-- hide variable from define page
# -sort=key		-- variable sorts in this order on define page
# -cmd			-- variable is a Unix command string
# -mirror		-- variable should be mirrored from server

	ci('sep_a', '-sort'=>'a--sep', '-separator', '-desc'=>
		gettext("<b>Mandatory:</b> System information")),
	ci('adminAuth',	'-sort'=>'a-a1', '-free',
		'-default'=>"''", '-desc'=>
		gettext("Identity of local FAQ-O-Matic administrator (an email address)")),
	ci('mailCommand',	'-sort'=>'a-m1', '-free', '-cmd', '-desc' =>
		gettext("A command FAQ-O-Matic can use to send mail. It must either be sendmail, or it must understand the -s (Subject) switch.")),
	ci('crontabCommand','-sort'=>'a-m4', '-free', '-cmd', '-desc' =>
		gettext("The command FAQ-O-Matic can use to install a cron job."),
		'-default'=>"'".which('crontab')."'"),
	ci('RCSci',		'-sort'=>'a-r1', '-free', '-cmd',
		'-default'=>"'".which('ci')."'", '-desc'=>
		gettext("Path to the <b>ci</b> command from the RCS package.")),
	ci('RCSco',		'-sort'=>'a-r2', '-free', '-cmd',
		'-default'=>"'".which('co')."'", '-desc'=>
		gettext("Path to the <b>co</b> command from the RCS package.")),

	ci('sep_c', '-sort'=>'c--sep', '-separator', '-desc'=>
		gettext("<b>Mandatory:</b> Server directory configuration")),
	ci('serverBase', '-sort'=>'c-a1', '-free', '-desc'=>
		gettext("Protocol, host, and port parts of the URL to your site. This will be used to construct link URLs. Omit the trailing '/'; for example: <tt>http://www.dartmouth.edu</tt>"),
		'-default'=>"'".FAQ::OMatic::serverBase()."'" ),
	ci('cgiURL', '-sort'=>'c-a2', '-free', '-desc'=>
		gettext("The path part of the URL used to access this CGI script, beginning with '/' and omitting any parameters after the '?'. For example: <tt>/cgi-bin/cgiwrap/jonh/faq.pl</tt>"),
		'-default'=>"'".FAQ::OMatic::cgiURL()."'" ),
	ci('serveDir', '-sort'=>'c-c1', '-free', '-desc'=>
		gettext("Filesystem directory where FAQ-O-Matic will keep item files, image and other bit-bag files, and a cache of generated HTML files. This directory must be accessible directly via the http server. It might be something like /home/faqomatic/public_html/fom-serve/"),'-default'=>"''"),
	ci('serveURL', '-sort'=>'c-c2', '-free', '-desc'=>
		gettext("The path prefix of the URL needed to access files in <b>\$serveDir</b>. It should be relative to the root of the server (omit http://hostname:port, but include a leading '/'). It should also end with a '/'.") , '-default'=>"''" ),

	ci('sep_e', '-sort'=>'e--sep', '-separator', '-desc'=>
		gettext("<i>Optional:</i> Miscellaneous configurations")),
	ci('language',		'-sort'=>'k-m00',
		'-choices'=>[ "'en'", "'de_iso8859_1'", "'fr'", "'ru'",
					  "'uk'", "'fi'", "'ja_JP.EUC'" , "'hu'"],
		'-desc'=>
		gettext("Select the display language."),
		'-default'=>gettext("'en'")),
	ci('dateFormat',	'-sort'=>'k-m01',
		'-choices'=>[ "''", "'24'"],
		'-desc'=>
		gettext("Show dates in 24-hour time or am/pm format."),
		'-default'=>"''"),
	ci('mirrorURL',		'-sort'=>'k-m1', '-free', '-choices'=>[ "''"],
		'-default'=>"''", '-desc'=>
		gettext("If this parameter is set, this FAQ will become a mirror of the one at the given URL. The URL should be the base name of the CGI script of the master FAQ-O-Matic.")),
	ci('pageHeader',	'-sort'=>'m-p1', '-free', '-mirror', '-desc'=>
		gettext("An HTML fragment inserted at the top of each page. You might use this to place a corporate logo.")
		." "
		.gettext("If this field begins with <tt>file=</tt>, the text will come from the named file in the meta directory; otherwise, this field is included verbatim.")),
	# THANKS to Vicki Brown <vlb@cfcl.com> for demanding a configurable
	# tableWidth tag. It's a workaround for Netscape's buggy page layout;
	# it doesn't even help with align=right images.
	ci('tableWidth',	'-sort'=>'m-p15',
		'-choices'=>[ "'width=\"100%\"'" ],
		'-default'=>"'width=\"100%\"'",
		'-free', '-mirror', '-desc'=>
		gettext("The <tt>width=</tt> tag in a table. If your <b>\$pageHeader</b> has <tt>align=left</tt>, you will want to make this empty.")),
	ci('pageFooter',	'-sort'=>'m-p2', '-free', '-mirror',
		'-default' => "'This FAQ administered by ...'", '-desc'=>
		gettext("An HTML fragment appended to the bottom of each page. You might use this to identify the webmaster for this site.")
		." "
		.gettext("If this field begins with <tt>file=</tt>, the text will come from the named file in the meta directory; otherwise, this field is included verbatim.")),
	ci('adminEmail','-sort'=>'n-e2', '-free', '-choices'=>[ '$adminAuth' ],
		'-default' => "\$adminAuth",
		'-desc'=> gettext("Where FAQ-O-Matic should send email when it wants to alert the administrator (usually same as \$adminAuth)")),
	ci('maintSendErrors',	'-sort'=>'n-m2', '-choices'=>[ "'true'", "''" ],
		'-desc'=> gettext("If true, FAQ-O-Matic will mail the log file to the administrator whenever it is truncated."),
		'-default'=>"'true'"),
	ci('RCSuser',	'-sort'=>'r-r3', '-free', '-choices'=>['getpwuid($>)'],
		'-desc'=> gettext("User to use for RCS ci command (default is process UID)"),
		'-default'=>'getpwuid($>)'),
	ci('useServerRelativeRefs', '-sort'=>'r-s1',
		'-choices'=>[ "'true'", "''" ], '-default'=>"''", '-desc'=>
		gettext("Links from cache to CGI are relative to the server root, rather than absolute URLs including hostname:")),
	ci('antiSpam', '-sort'=>'r-s7', '-mirror',
		'-choices'=>[ "'off'", "'cheesy'", "'nameonly'", "'hide'" ],
		'-default'=>"'off'", '-desc'=>
		gettext("mailto: links can be rewritten such as jonhATdartmouthDOTedu (cheesy), jonh (nameonly), or e-mail addresses suppressed entirely (hide).")),
	ci('cookieLife', '-sort'=>'r-s8', '-free',
		'-choices'=>[ "'3600'" ],
		'-default'=>"'3600'",
		'-desc'=> gettext("Number of seconds that authentication cookies remain valid. These cookies are stored in URLs, and so can be retrieved from a browser history file. Hence they should usually time-out fairly quickly.")),
	ci('trashTime', '-sort'=>'r-s9', '-free',
		'-choices'=>[ "'14'" ],
		'-default'=>"'14'",
		'-desc'=> gettext("Number of days that trash sits in the trash category before maintenance cleans it up. '0' lets it stay forever.")),

	ci('sep_t', '-sort'=>'t--sep', '-separator', '-desc'=>
			gettext("<i>Optional:</i> These options set the default [Appearance] modes.")),

	ci('renderDefault', '-sort'=>'t-t1', '-mirror',
		'-choices'=>[ "'tables'", "'simple'", "'text'" ],
		'-default'=> "'tables'", '-desc'=>
		      gettext("Page rendering scheme. Do not choose 'text' as the default.")),

	ci('editCmdsDefault', '-sort'=>'t-t2', '-mirror',
		'-choices'=>[ "'show'", "'compact'", "'hide'" ],
		'-default'=>"'hide'", '-desc'=>
			gettext("expert editing commands")),

	ci('showModeratorDefault', '-sort'=>'t-t3', '-mirror',
		'-choices'=>[ "'show'", "'hide'" ],
		'-default'=>"'hide'", '-desc'=>
			gettext("name of moderator who organizes current category")),

	ci('showLastModifiedDefault', '-sort'=>'t-t4', '-mirror',
		'-choices'=>[ "'show'", "'hide'" ],
		'-default'=>"'hide'", '-desc'=>
			gettext("last modified date")),

	ci('showAttributionsDefault', '-sort'=>'t-t5', '-mirror',
		'-choices'=>[ "'all'", "'default'", "'hide'" ],
		'-default'=>"'default'", '-desc'=>
			gettext("attributions")),

	ci('textCmdsDefault', '-sort'=>'t-t6', '-mirror',
		'-choices'=>[ "'show'", "'hide'" ],
		'-default'=>"'hide'", '-desc'=>
			gettext("commands for generating text output")),

	ci('sep_u', '-sort'=>'v--sep', '-separator', '-desc'=>
			gettext("<i>Optional:</i> These options fine-tune the appearance of editing features.")),
	ci('showEditOnFaq', '-sort'=>'v-s3', '-mirror',
		'-choices'=>[ "'show'", "'compact'", "''" ], '-default'=>"''", '-desc'=>
	                gettext("The old [Show Edit Commands] button appears in the navigation bar.")),

	ci('navigationBlockAtTop', '-sort'=>'v-s35', '-mirror',
		'-choices'=>[ "'true'", "''" ], '-default'=>"''", '-desc'=>
			gettext("Navigation links appear at top of page as well as at the bottom.")),

	ci('hideEasyEdits', '-sort'=>'v-s4', '-mirror',
		'-choices'=>[ "'true'", "''" ], '-default'=>"''", '-desc'=>
		gettext("Hide [Append to This Answer] and [Add New Answer in ...] buttons.")),

	ci('showEditIcons', '-sort'=>'v-s6', '-mirror',
		'-choices'=>[ "'icons-and-label'", "'icons-only'", "''" ],
		'-default'=>"''", '-desc'=>
		gettext("Editing commands appear with neat-o icons rather than [In Brackets].")),

	ci('sep_z', '-sort'=>'z--sep', '-separator', '-desc'=>
			gettext("<i>Optional:</i> Other configurations that you should probably ignore if present.")),

	ci('nolanTitles', '-mirror', '-choices'=>[ "'true'", "''" ],
			'-default'=>"''", '-desc'=>
			gettext("Draw Item titles John Nolan's way.")),

	ci('hideSiblings', '-mirror', '-choices'=>[ "'true'", "''" ],
			'-default'=>"''", '-desc'=>
			gettext("Hide sibling (Previous, Next) links")),

	ci('useDBMSearch', '-choices'=>[ "'true'", "''" ],
			'-default'=>"''", '-desc'=>
			gettext("Use DBM-based search databases. Faster on machines with non-broken DBM.")),
	ci('disableSearchHighlight', '-choices'=>[ "'true'", "''" ],
			'-default'=>"''", '-desc'=>
			gettext("Links from search results page point into cache (do not highlight search terms)")),
			# THANKS anti-feature suggested by
			# THANKS "Dameon D. Welch-Abernathy" <dwelch@phoneboy.com>

	ci('RCSciArgs',	'-sort'=>'a-r1-args', '-free', '-desc'=>
		gettext("Arguments to make ci quietly log changes and not mash RCS tags (use default with GNU RCS)"),
		'-default'=>"'-mnull -t-null'"),
	ci('RCScoArgs',	'-sort'=>'a-r2-args', '-free', '-desc'=>
		gettext("Arguments to make co not mash RCS tags (use default with GNU RCS)"),
		'-default'=>"'-ko -l'"),
	ci('RCSargs',	'-hide', '-free', '-desc'=>
		gettext('deprecated; subsumed by RCSciArgs and RCScoArgs.')),
	ci('authorEmail', '-hide', '-default'=>"''"),
	ci('backgroundColor', '-hide', '-mirror', '-default'=>"'#ffffff'"),
	ci('bagsDir', '-hide'),
	ci('bagsURL', '-hide'),
	ci('cacheDir', '-hide'),
	ci('cacheURL', '-hide'),
	ci('directoryPartColor', '-hide', '-mirror', '-default'=>"'#80d080'"),
	ci('highlightColor', '-hide', '-mirror', '-default'=>"'#d00050'"),
	ci('itemBarColor', '-hide', '-mirror', '-default'=>"'#606060'"),
	ci('itemDir', '-hide'),
	ci('itemURL', '-hide'),
	ci('linkColor', '-hide', '-mirror', '-default'=>"'#3030c0'"),
	ci('maintenanceSecret', '-hide'),
	ci('metaDir', '-hide',),
	ci('regularPartColor', '-hide', '-mirror', '-default'=>"'#d0d0d0'"),
	ci('secureInstall', '-hide'),
	ci('statUniqueHosts', '-hide',
		'-default'=>"''"),
	ci('textColor', '-hide', '-mirror', '-default'=>"'#000000'"),
	ci('version', '-hide', '-default'=>"'$FAQ::OMatic::VERSION'"),
	ci('vlinkColor', '-hide', '-mirror', '-default'=>"'#3030c0'"),

        ci('bagsDir_Old', '-hide', '-desc'=>'(internal use)'),
	ci('cacheDir_Old', '-hide', '-desc'=>'(internal use)'),
	ci('compactEditCmds', '-hide', '-desc'=>'(obsolete)'),
	ci('showLastModifiedAlways', '-hide',
		'-choices'=>[ ], '-desc'=>
		'(obsolete) Items always display their last-modified dates.')
                   }
	}
	return $configInfo;
}
# THANKS: John Goerzen and someone else (sorry I forgot who since I
# THANKS: fixed it!) pointed out that the serveURL (then the cacheURL) needs
# THANKS: a leading slash to avoid picking up a prefix like cgi-bin/.

sub getPotentialConfig {
	# gets the current config, plus empty strings for any expected but
	# nonexistant keys (probably because the modules have been upgraded to
	# a new version)
	my $map = readConfig('ignoreErrors');

	# Provide defaults for any new options not present in config file
	my $ckey;
	foreach $ckey (sort keys %{configInfo()}) {
		next if defined($map->{'$'.$ckey});
		next if configInfo()->{$ckey}->{'-separator'};
		$map->{'$'.$ckey} =
			configInfo()->{$ckey}->{'-default'} || "''";
	}

	return $map;
}

sub undefinedConfigsExist {
	my $map = readConfig();
	my $ckey;
	foreach $ckey (sort keys %{configInfo()}) {
		if (not defined($map->{'$'.$ckey})
			and not configInfo()->{$ckey}->{'-separator'}) {
			FAQ::OMatic::gripe('debug', "not defined: $ckey");
			return 1;
		}
	}
	return 0;
}

sub askConfigStep {
	my $rt = '';
	my ($left, $right);

	$rt.="<table>\n";
	$rt.=installUrl('setConfig', 'POST'); # long pageHeader can exceed limit of web server

	# Read current configuration
	my $map = getPotentialConfig();

	my $widgets = {};	# collect widgets here for sorting later
	# want to list any widget that either in the existing $map, or
	# in the list of possible configs (configInfo()); but of course
	# any given widget should appear only once (hence the hash).
	my %keylist = map {$_=>$_}
						((keys %{$map}),
						(map {'$'.$_} keys %{configInfo()}));
	foreach $left (sort keys %keylist) {
		$right = $map->{$left} || '';
		my $aleft = $left;
		$aleft =~ s/^\$//;
		my $isLegacy = not $right=~m/^'/;	# if value isn't a free input
		my $aright = stripQuotes($right);
		my ($sort,$desc,$choices,$free,$cmd,$separator,$mirror,$default);
		my $ch = configInfo()->{$aleft} || {'-free'=>1};
		if (defined $ch) {
			$sort		= $ch->{'-sort'} || 'zzzz';
			$desc		= $ch->{'-desc'} || '(no description)';
			$choices	= $ch->{'-choices'} || [];
			$free		= $ch->{'-free'} || 0;
			$cmd		= $ch->{'-cmd'} || 0;
			$separator	= $ch->{'-separator'} || 0;
			$mirror		= $ch->{'-mirror'} || 0;
			$default	= $ch->{'-default'} || '';
			$sort 		= 'hide' if ($ch->{'-hide'});
			$desc.="<br>".gettext("This is a command, so only letters, hyphens, and slashes are allowed.") if ($cmd);
		}
		if ($separator) {
			$widgets->{$sort} =
			"<tr><td colspan=2>\n<hr>$desc<hr>\n</td></tr>\n";
		} elsif ($sort eq 'hide') {
			# don't show hidden widgets
		} elsif ((($FAQ::OMatic::Config::mirrorURL||'') ne '') and $mirror) {
			# don't show mirrorable widgets if this is a mirror site --
			# they'll get automatically defined at mirroring time.
		} else {
			my $wd = '';
			$wd.="<tr><td align=right valign=top><b>$left</b></td>"
				."<td align=left valign=top>\n";
			$wd.="$desc<br>\n";
			my $selected = 0;		# don't show $right in free field if
									# it was available by a select button
			if (scalar(@{$choices})) {
				foreach my $choice (@{$choices}) {
					my $defaultText = ($choice eq $default)
						? ' <i>(default)</i>'
						: '';
					my $echoice = FAQ::OMatic::entify($choice);
					$wd.="<input type=radio name=\"$left-select\" "
						.($right eq $choice ? ' checked' : '')
						." value=\"$echoice\"> $choice$defaultText<br>\n";
					$selected = 1 if ($right eq $choice);
				}
				if ($selected == 0 and $isLegacy) {
					# there is an unquoted value that's no longer
					# a given choice, but can't go in the free field
					# (because otherwise it'll pick up quotes.)
					$wd.="<input type=radio name=\"$left-select\" "
						."checked value=\""
						.FAQ::OMatic::entify($right)
						."\"> $right "
						."<i><font color=red>This is no longer a "
						."recommended selection.</font></i><br>\n";
					$selected = 1;
				}
				if ($free) {
					$wd.="<input type=radio name=\"$left-select\" "
						.($selected ? '' : ' checked')
						." value=\"free\">\n";
				}
			} else {
				$wd.="<input type=hidden name=$left-select value=\"free\">\n";
			}
			if ($free) {
				$wd.="<input type=text size=40 name=\"$left-free\" "
					."value=\""
					.($selected ? '' : FAQ::OMatic::entify($aright))
					."\">\n";
			}
			$wd.="</td></tr>\n";
			$widgets->{$sort} .= $wd;
		}
	}

	$rt.=gettext("If this is your first time installing a FAQ-O-Matic, I recommend only filling in the sections marked <b>Mandatory</b>.");
	# now display the widgets in sorted order
	$rt.= join('', map {$widgets->{$_}} sort(keys %{$widgets}));
	$rt.="<tr><td></td><td>"
		."<input type=submit name=junk value=\"".gettext("Define")."\"></td></tr>\n";
	$rt.="</form>\n";
	$rt.="</table>\n";

	displayMessage($rt);
}

sub setConfigStep {
	my $warnings = '';
	my $notices = '';	#nonproblems
	my ($left, $right);
	my $map = getPotentialConfig();

	foreach $left (sort keys %{$map}) {
		$right = $map->{$left};
		my $selected = cgi()->param($left."-select") || '';
		if ($selected eq 'free') {
			$map->{$left} = "'".cgi()->param($left."-free")."'";
		} elsif ($selected ne '') {
			$map->{$left} = $selected;
		}
		$map->{$left} =~ s/\n//gs;	# don't let weirdo newlines through
		my $aleft = $left;
		$aleft =~ s/^\$//;
		if (configInfo()->{$aleft}->{'-cmd'}) {	# it represents a command...
			$map->{$left} =~ s#[^\w/'-]##gs;	# be very restrictive
		}
		my ($warn,$howbad) = checkConfig($left, \$map->{$left});
		if ($howbad eq 'ok') {
			$notices .= "<li>$warn";
		} elsif ($warn) {
			$warnings .= "<li>$warn";
		}
	}
	writeConfig($map);
	FAQ::OMatic::I18N::reload();	# future displays should be in new language
		# TODO except in practice the next configuration screen
		# stays in the old language.
	if ($notices) {
		$notices = "<ul>$notices</ul>\n";
	}
	if ($warnings) {
		$warnings = "<p><b>".gettext("Warnings:")." <ul>$warnings</ul>"
				.gettexta("You should <a href=\"%0\">go back</a> and fix these configurations.", installUrl('askConfig'))
				 ."</b>";
	}
	displayMessage(gettext("Rewrote configuration file.")
		."\n$notices\n$warnings");
	doStep('mainMenu');
}

sub checkConfig {
	my $left = shift;
	my $rightref = shift;
	my $right = ${$rightref};
	my $eright = FAQ::OMatic::entify($right);
	my $aright = stripQuotes($right);

	if ($aright =~ m/'/) {
		$$rightref = configInfo()->{$left}->{'-default'} || "''";
		return (gettexta("%0 (%1) has an internal apostrophe, which will certainly make Perl choke on the config file.", $left, $eright), 'fix');
	}
	if ($left eq '$adminAuth') {
		if (not FAQ::OMatic::validEmail($aright)) {
			return (gettexta("%0 (%1) doesn't look like a fully-qualified email address.", $left, $eright),
				'fix');
		}
	}
	if ($left eq '$adminEmail' and $right ne '$adminAuth') {
		if (not FAQ::OMatic::validEmail($aright)) {
			return (gettexta("%0 (%1) doesn't look like a fully-qualified email address.", $left, $eright),
				'fix');
		}
	}
	if ($left eq '$mailCommand') {
		if (not -x $aright) {
			return (gettexta("%0 (%1) isn't executable.", $left, $eright), 'fix');
		}
	}
	if ($left eq '$RCSci') {
		if (not -x $aright) {
			return (gettexta("%0 (%1) isn't executable.", $left, $eright), 'fix');
		}
	}
	if ($left eq '$serveDir') {
		if ($aright eq '') {
			return ("$left undefined. You must define a directory readable "
				."by the web server from which to serve data. If you are "
				."upgrading, I recommend creating a new directory in the "
				."appropriate place in your filesystem, and copying in "
				."your old items later. The installer checklist will tell you "
				."when to do the copy.",
				'fix');
		}
		$aright = FAQ::OMatic::canonDir($aright);
		if (not -d $aright) {
			my $dirname = stripSlash($aright);
			if (scalar($dirname =~ m#^([/\w\.\-_]+)$#)==0) {
				FAQ::OMatic::gripe('error', gettexta("%0 has funny characters.", $dirname));
			}
			$dirname = $1;
			if (not mkdir($dirname, 0755)) {
				return ("$left ($eright) can't be created.", 'fix');
			} else {
				chmod(0755,$dirname);
				return ("$left: Created directory $eright.", 'ok');
			}
		}
	}
	if ($left eq '$cookieLife') {
		if ($aright < 1) {
			$$rightref = "'3600'";
			return ("$left was nonpositive; I set it to '3600' (one hour).",
				'ok');
			# simply disallow unreasonable numbers. I can't imagine a
			# scenario where someone would want a 0 cookieLife (uttering
			# those words, of course, will cause such a scenario to
			# spring into existence), and this will save a lot of grief
			# for most people upgrading.
		}
	}
	return ('','');
}

sub firstItemStep {
	if (not -f "$FAQ::OMatic::Config::itemDir/1") {
		my $item = new FAQ::OMatic::Item();
		$item->setProperty('Title', gettext("Untitled Faq-O-Matic"));
		$item->setProperty('Parent', '1');
		$item->setProperty('Moderator', $FAQ::OMatic::Config::adminAuth);

		# tell the user how to name his FAQ
		my $helpPart = new FAQ::OMatic::Part();
		$helpPart->{'Text'} = gettext("To name your FAQ-O-Matic, use the [Appearance] page to show the expert editing commands, then click [Edit Category Title and Options].");
		push @{$item->{'Parts'}}, $helpPart;

		# prevent user from feeling dumb because he can't find
		# the [New Answer] button by making the initial item as a
		# category (giving it a directory).
		$item->makeDirectory()->
			setText(gettext("Subcategories:")."\n\n\n".gettext("Answers in this category:")."\n");

		$item->saveToFile('1');
		displayMessage(gettexta("Created category \"%0\".", 'Top (file=1)'));
	} else {
		displayMessage(gettexta("<b>%0</b> already contains a file '%1'.",
			$FAQ::OMatic::Config::itemDir, '1'));
	}
	if (not -f "$FAQ::OMatic::Config::itemDir/trash") {
		my $item = new FAQ::OMatic::Item();
		$item->setProperty('Title', 'Trash');
		$item->setProperty('Parent', 'trash');
		$item->setProperty('Moderator', $FAQ::OMatic::Config::adminAuth);
		$item->makeDirectory();
		$item->saveToFile('trash');
		displayMessage(gettexta("Created category \"%0\".", 'trash'));
	} else {
		displayMessage(gettexta("<b>%0</b> already contains a file '%1'.",
			$FAQ::OMatic::Config::itemDir, 'trash'));
	}
	if (not -f "$FAQ::OMatic::Config::itemDir/help000") {
		my $item = new FAQ::OMatic::Item();
		$item->setProperty('Title', 'Help');
		$item->setProperty('Parent', 'help000');
		$item->setProperty('Moderator', $FAQ::OMatic::Config::adminAuth);
		$item->makeDirectory();
		$item->saveToFile('help000');
		displayMessage(gettexta("Created category \"%0\".", 'help'));
	} else {
		displayMessage(gettexta("<b>%0</b> already contains a file '%1'.",
			$FAQ::OMatic::Config::itemDir, 'help000'));
	}

	# The reason for an Items version field is to ensure that
	# all of the items that come with a default FOM of a given
	# version are now installed. Old items are not replaced...
	FAQ::OMatic::Versions::setVersion('Items');

	# set itemDir_Old to current itemDir, since that's now the
	# working directory. That way if it ever moves again (oh man
	# I hope not), we'll know where to copy from. Ugh.
	my $map = readConfig();
	delete $map->{'$itemDir_Old'};
	writeConfig($map);

	doStep('mainMenu');
}

sub copyItemsStep {
	my $oldDir = $FAQ::OMatic::Config::itemDir_Old;
	my $newDir = $FAQ::OMatic::Config::itemDir;
	
	my @oldList = FAQ::OMatic::getAllItemNames($oldDir);
	my $file;
	foreach $file (@oldList) {
		my $item = new FAQ::OMatic::Item($file, $oldDir);
		$item->saveToFile('', $newDir, 'noChange');
	}
	my @newList = FAQ::OMatic::getAllItemNames($newDir);

	if (scalar(@oldList) ne scalar(@newList)) {
		displayMessage("I'm vaguely concerned that $oldDir contained "
			.scalar(@oldList)." items, but (after copying) $newDir has "
			.scalar(@newList)." items. I don't plan on doing anything "
			."about this, though. How about you check? :v)");
	} else {
		displayMessage(
			gettexta("Copied %0 items from <tt>%1</tt> to <tt>%2</tt>.",
				scalar(@newList), $oldDir, $newDir));
	}
	doStep('mainMenu');
}

sub maintenanceStep {
	require FAQ::OMatic::Entropy;
	my $rt = '';
	my $secret = FAQ::OMatic::Entropy::gatherRandomString();

	# The parameters we'll be passing to the maintenance module
	# via the CGI dispatch mechanism:
	my $host = cgi()->virtual_host();
	my $port = cgi()->server_port();
	my $path = cgi()->script_name();
	my $req = $path."?cmd=maintenance&secret=$secret";

	# Figure out a suitable -I include path in case we're picking up FAQ-O-Matic
	# modules relative to . (current working dir)
	my $idir;
	my $incBase='';
	my $incOption='';
	foreach $idir (@INC) {
		if (-d "$idir/FAQ/OMatic") {
			$incBase = $idir;
			last;
		}
	}

	if (not $incBase) {
		displayMessage("I can't figure out where the Faq-O-Matic modules live, "
			."so the cron job may not work.");
	}

	# No way to know if path is a Perl default or if it was supplied
	# with the #! (shebang) line of the CGI, so we always include it just
	# to be sure the cron job will work.
	if (not $incBase =~ m#^/#) {	# convert relative INC to absolute
		my $cwd = getcwd();
		$cwd =~ s#/$##;
		$incOption = "use lib \"$cwd/$incBase\"";
	} else {
		$incOption = "use lib \"$incBase\"";
	}

	# THANKS: John Goerzen pointed out that I wasn't putting a full path
	# THANKS: to perl in the cron job, which on some systems picks up the
	# THANKS: wrong Perl. (Perl 4, for example.)
	my $perlbin = $Config{'perlpath'};
	my $cronCmd = "$perlbin -e '$incOption; use FAQ::OMatic::maintenance; "
		."FAQ::OMatic::maintenance::cronInvoke(\"$host\", "
		."$port, \"$req\");'";
	my $cronLine = sprintf("%d * * * * %s\n", (rand(1<<16)%60), $cronCmd);

	# display what we're planning to do, so that resourceful admins
	# can still install even if our heuristics fail and we have to abort.
	displayMessage(gettext("Attempting to install cron job:")
			."\n<pre><font size=\"-1\">$cronLine</font></pre>\n");

	# Set up new maintenance secret immediately, in case the install fails
	# but a resourceful admin manually installs the displayed crontab line.
	# THANKS: "Riesland, Dan (MN10)" <Dan.Riesland@HBC.Honeywell.com> for
	# THANKS: helping to figure this problem out.
	my $map = readConfig();
	$map->{'$maintenanceSecret'} = "'$secret'";
	writeConfig($map);

	# 1999-04-04 hal@dtor.com: we have to be sure to test on triple
	#  of host, port, path to make sure we have correct entry
	#  (allow for some hand editing to have happenend, too...)
	# THANKS to hal for supplying this in patch form instead of bug report form
	my $pattern = "\Qnvoke(\"$host\",\E\\s*$port,\\s*\Q\"$path?\E";
	#displayMessage( "pattern is:<pre>$pattern</pre>" );

	my @oldTab = getCurrentCrontab();
	my @oldUnrelated = grep {not m/$pattern/} @oldTab;
	my @oldReplacing = grep {m/$pattern/} @oldTab;

	if (scalar(@oldReplacing)>1) {
		displayMessage("Wait: more than one old crontab entry looks like\n"
			."mine (matches <b>$pattern</b>). "
			."I'm not going to touch them. You'd better add\n"
			."the above line\n"
			."to some crontab yourself with <b><tt>crontab -e</tt></b>.\n",
			'default', 'abort');
	}

	open(CRONTAB, ">$FAQ::OMatic::Config::metaDir/cronfile") ||
		displayMessage("Can't write to $FAQ::OMatic::Config::metaDir/cronfile."
			." No crontab entry added.", 'default', 'abort');
	# preserve existing entries
	print CRONTAB join('', @oldUnrelated);
	# and add our new one.
	print CRONTAB $cronLine;
	close CRONTAB;
	
	my $crontabbin = $FAQ::OMatic::Config::crontabCommand || '/bin/false';
	my $cmd = "$crontabbin $FAQ::OMatic::Config::metaDir/cronfile";
	my @msrc = FAQ::OMatic::mySystem($cmd);
	if (scalar(@msrc)) {
		$rt.="'$cmd' failed: ".join('', @msrc)."\n";
	}

	if (@oldReplacing) {
		$rt.=gettext("I replaced this old crontab line, which appears to be an older one for this same FAQ:")."\n<tt><p><font size=\"-1\">\n"
			.$oldReplacing[0]
			."</font></tt>\n";
	}

	# perform a simple test to verify our cron line got installed
	my @newTab = getCurrentCrontab();
	if (scalar(grep {m/$pattern/} @newTab) != 1
		or scalar(grep {m/$secret/} @newTab) != 1) {
		displayMessage(gettext("I thought I installed a new cron job, but it didn't appear to take.")."\n"
			."tab".join("<br>\n",@newTab)
			.gettexta("You better add %0 to some crontab yourself with <b><tt>crontab -e</tt></b>",
				"\n<pre><font size=\"-1\">$cronLine</font></pre>\n")."\n",
			'default', 'abort');
	}

	FAQ::OMatic::Versions::setVersion('MaintenanceCronJob');
	$rt.="<p>".gettext("Cron job installed. The maintenance script should run hourly.")."\n";
	displayMessage($rt);
	doStep('default');
}

sub getCurrentCrontab {
	my $crontabbin = $FAQ::OMatic::Config::crontabCommand || '/bin/false';

	my $cmd = "$crontabbin -l";
	my @systemrc = FAQ::OMatic::mySystem($cmd, 'alwaysWantReply');
	my @oldTab;
	if ($systemrc[0]==1) {
		if ($systemrc[3]=~m/open.*crontab/i
			or $systemrc[3]=~m/no crontab for /i) {
			# looks like the "error" you get if you don't have a crontab.
			# THANKS: to Hal Wine <hal@dtor.com> for supplying the
			# second pattern to match vixie-cron's error message
			@oldTab = ();
			$systemrc[0] = 0;
		}
	}
	if ($systemrc[0] != 0) {
		displayMessage("crontab -l failed: "
			.join(',', @systemrc),
			'default', 'abort');
	} else {
		@oldTab = @{$systemrc[4]};
	}

	if ((scalar(@oldTab)==1) and (not $oldTab[0] =~ m/^\s*[0-9*#]/)) {
		# crontab returned one line, and it doesn't look like a
		# cron comment or command line. It's probably the error
		# message you get if you don't already have a crontab.
		# (Unfortunately, the text of the message varies across versions.)
		@oldTab = ();
	}

	return @oldTab;
}

sub makeSecureStep {
	my $map = readConfig();
	$map->{'$secureInstall'} = "'true'";
	writeConfig($map);

	# send admin straight through to changePass, since he can't
	# have a password yet
	my $url = FAQ::OMatic::makeAref('changePass',
			{'_restart'=>'install', '_admin'=>1}, 'url');
	FAQ::OMatic::redirect(cgi(), $url);
}

sub colorSamplerStep {
	my $rt = '';
	my $button = "*";

	$rt.=gettexta("Use the <u>%0</u> links to change the color of a feature.", $button);

	# an outer table provides the background (page) color
	$rt.="\n<table bgcolor=$FAQ::OMatic::Config::backgroundColor width=\"100%\">\n";
	$rt.="<tr><td>\n";

	$rt.="<table width=\"100%\">\n";
	$rt.="<tr><td rowspan=5 bgcolor=".$FAQ::OMatic::Config::itemBarColor
		." width=20 valign=bottom>\n";
	$rt.="<a href=\""
		.installUrl('askColor', 'url')."&whichColor=\$itemBarColor\">"
		."$button</a>\n";
	$rt.="</td>\n";
	$rt.="<td bgcolor=$FAQ::OMatic::Config::backgroundColor>\n";
	$rt.="<b><font color=$FAQ::OMatic::Config::textColor>".gettext("An Item Title")."</font></b>\n";
	$rt.="</td></tr>\n";

	$rt.="<tr><td bgcolor=$FAQ::OMatic::Config::regularPartColor>\n";
	$rt.="<a href=\""
		.installUrl('askColor', 'url')."&whichColor=\$regularPartColor\">"
		."$button</a><p>\n";
	$rt.="<font color=$FAQ::OMatic::Config::textColor>"
		.gettext("A regular part is how most of your content will appear. The text colors should be most pleasantly readable on this background.")
		."</font>\n";
	$rt.="<br><font color=$FAQ::OMatic::Config::linkColor>".gettext("A new link")."</font>\n";
	$rt.="<br><font color=$FAQ::OMatic::Config::vlinkColor>".gettext("A visited link")."</font>\n";
	$rt.="<br><font color=$FAQ::OMatic::Config::highlightColor><b>"
		.gettext("A search hit")."</b></font>\n";
	$rt.="</td></tr>\n";

	$rt.="<tr><td bgcolor=$FAQ::OMatic::Config::directoryPartColor>\n";
	$rt.="<a href=\""
		.installUrl('askColor', 'url')."&whichColor=\$directoryPartColor\">"
		."$button</a><p>\n";
	$rt.="<font color=$FAQ::OMatic::Config::textColor>"
		.gettext("A directory part should stand out")."</font>\n";
	$rt.="<br><font color=$FAQ::OMatic::Config::linkColor>".gettext("A new link")."</font>\n";
	$rt.="<br><font color=$FAQ::OMatic::Config::vlinkColor>".gettext("A visited link")."</font>\n";
	$rt.="<br><font color=$FAQ::OMatic::Config::highlightColor><b>"
		.gettext("A search hit")."</b></font>\n";
	$rt.="</td></tr>\n";

	$rt.="<tr><td bgcolor=$FAQ::OMatic::Config::regularPartColor>\n";
	$rt.="&nbsp;<p>\n";
	$rt.="</td></tr>\n";

	$rt.="<tr><td bgcolor=$FAQ::OMatic::Config::regularPartColor>\n";
	$rt.="&nbsp;<p>\n";
	$rt.="</td></tr>\n";

	$rt.="<tr><td colspan=2 bgcolor=$FAQ::OMatic::Config::backgroundColor>\n";
	$rt.="<a href=\""
		.installUrl('askColor', 'url')."&whichColor=\$backgroundColor\">"
		."$button</a>\n";
	#$rt.="<font color=$FAQ::OMatic::Config::textColor>Page background color</font>";
	$rt.="<p>\n";
	$rt.="<a href=\""
		.installUrl('askColor', 'url')."&whichColor=\$textColor\">"
		."$button</a>\n";
	$rt.="<font color=$FAQ::OMatic::Config::textColor>".gettext("Regular text")."</font><br>\n";
	$rt.="<a href=\""
		.installUrl('askColor', 'url')."&whichColor=\$linkColor\">"
		."$button</a>\n";
	$rt.="<font color=$FAQ::OMatic::Config::linkColor>".gettext("A new link")."</font><br>\n";
	$rt.="<a href=\""
		.installUrl('askColor', 'url')."&whichColor=\$vlinkColor\">"
		."$button</a>\n";
	$rt.="<font color=$FAQ::OMatic::Config::vlinkColor>".gettext("A visited link")."</font><br>\n";
	$rt.="<a href=\""
		.installUrl('askColor', 'url')."&whichColor=\$highlightColor\">"
		."$button</a>\n";
	$rt.="<font color=$FAQ::OMatic::Config::highlightColor><b>"
		.gettext("A search hit")."</b></font>\n";
	$rt.="</td></tr>\n";

	$rt.="</table>\n";

	$rt.="</td></tr></table>\n";
	displayMessage($rt, 'mainMenu');
}

sub askColorStep {
	my $rt = '';
	my $which = $params->{'whichColor'};
	$rt.=gettexta("Select a color for %0:", $which)
		."<p>\n";
	$rt.="<a href=\""
		.installUrl('setColor', 'url')
		."&whichColor=$which&color=\"><img src=\""
		.installUrl('', 'url', 'img', 'picker')
		."\" border=1 ismap width=256 height=128></a>\n";

	my $map = readConfig();
	my $oldval = stripQuotes($map->{$which});
	$rt.="<p>".installUrl('setColor', 'GET');
	$rt.=gettext("Or enter an HTML color specification manually:")."<br>\n";
	$rt.="<input type=hidden name=\"whichColor\" value=\"$which\">\n"
		."<input type=text name=\"color\" value=\"$oldval\">\n"
		."<input type=submit name=\"_junk\" value=\"".gettext("Select")."\">\n"
		."</form>\n";

	displayMessage($rt);
}

sub setColorStep {
	my $which = $params->{'whichColor'};
	if (not $which =~ m/Color$/) {
		displayMessage(gettext("Unrecognized config parameter")." ($which).", 'default');
		return;
	}
	my $color = $params->{'color'}||'';
	my $colorSpec;
	if ($color =~ m/,/) {
		my ($c,$r) = ($color =~ m/\?(\d+),(\d+)/);
		if (not defined $c or not defined $r) {
			displayMessage("color parameter ($color) not received", 'default');
			return;
		}
		my ($red,$green,$blue) = FAQ::OMatic::ColorPicker::findRGB($c/255, $r/127);
		$colorSpec = sprintf("'#%02x%02x%02x'",
			$red*255, $green*255, $blue*255);
	} else {
		$colorSpec = "'$color'";
	}

	# update config file
	my $map = readConfig();
	$map->{$which} = $colorSpec;
	writeConfig($map);

	FAQ::OMatic::Versions::setVersion('CustomColors');

	rereadConfig();

	doStep('colorSampler');
}

sub configVersionStep {
	my $map = readConfig();
	$map->{'$version'} = "'$FAQ::OMatic::VERSION'";
	writeConfig($map);
	
	doStep('mainMenu');
}

sub displayMessage {
	my $msg = shift;
	my $whereNext = shift;
	my $abort = shift;

	my $rt = '';
	$rt .= "\n$msg<p>\n";

	if ($whereNext) {
		my $url = installUrl($whereNext);
		$rt .= "[<a href=\"$url\">".gettexta("Proceed to step '%0'", $whereNext)."</a>]\n";
	}
	print $rt;

	if ($abort) {
		FAQ::OMatic::myExit(0);
	}
}

sub cgi {
	# file-scoped $cgi was a bad idea -- if this file gets called
	# from another, install::cgi may never get initialized.
	# So here we provide a shortcut to $cgi that is reliable.
	return $FAQ::OMatic::dispatch::cgi;
}

sub installUrl {
	# can't necessarily use makeAref yet, because we're not configured.
	my $step = shift;
	my $reftype = shift || 'url';	# 'url', 'GET' and 'POST' supported
	my $cmd = shift || 'install';	# for images, need to specify cmd
	my $name = shift || '';			# for images, need to specify name
	my $temppass = shift;

	if (not defined $temppass) {
		$temppass = cgi()->param('temppass') || '';
	}

	my $imarg = ($name) ? ("&name=$name") : '';

	if ($FAQ::OMatic::Config::secureInstall) {
		# What a hack. When coming from an invocation of install.pm,
		# this saves the cookie; when called in from outside (such
		# as from maintenance::mirrorClient), we can't figure
		# out where to get ahold of $params, so we just discard
		# the auth cookie. Not like they were going to use it anyway.
		my $authCookie = defined($params) ? $params->{'auth'} : '';
		return FAQ::OMatic::makeAref($cmd,
			{'step'=>$step,
			'name'=>$name,
			'auth'=>$authCookie	# preserve only the cookie
			},
			$reftype, 0, 'blastAll');
	}

	my $url = FAQ::OMatic::serverBase().FAQ::OMatic::cgiURL();
	if ($reftype eq 'GET' || $reftype eq 'POST') {
		my $rt = '';
		$rt .= "<form action=\"$url\" method=\"${reftype}\">\n"
			."<input type=hidden name=cmd value=install>\n"
			."<input type=hidden name=step value=$step>\n";
		if ($temppass ne '') {
			$rt .= "<input type=hidden name=temppass value=\"$temppass\">\n";
		}
		return $rt;
	} else {
		my $tpa = ($temppass ne '') ? "&temppass=$temppass" : '';
		return "$url?cmd=${cmd}${tpa}&step=${step}${imarg}";
	}
}

sub readConfig {
	my $ignoreErrors = shift || '';

	if (not open(CONFIG, "<".FAQ::OMatic::dispatch::meta()."/config")) {
		if ($ignoreErrors) {
			return {};
		}
		displayMessage("Can't read config file \""
			.FAQ::OMatic::dispatch::meta()
			."/config\" because: $!", 'default');
		return;
	}

	my $map = {};
	while (defined($_=<CONFIG>)) {
		chomp;
		next if (not m/=/);
		my ($left,$right) = m/(\S+)\s*=\s*(\S+.*);$/;
		if (defined $left and defined $right) {
			$map->{$left} = $right;
		}
	}
	close CONFIG;

	return $map;
}

sub writeConfig {
	my $map = shift;

	if (not open(CONFIG, ">".FAQ::OMatic::dispatch::meta()."/config")) {
		displayMessage("Can't write config file \""
			.FAQ::OMatic::dispatch::meta()
			."/config\" because: $!", 'default', 'abort');
	}

	print CONFIG "package FAQ::OMatic::Config;\n";
	my ($left, $right);
	foreach $left (sort keys %{$map}) {
		$right = $map->{$left};
		print CONFIG $left." = ".$right.";\n";
	}
	print CONFIG "1;\n";	# modules have to return true
	close CONFIG;

	return;
}

sub stripQuotes {
	my $arg = shift;
	$arg =~ s/^'//;
	$arg =~ s/'$//;
	return $arg;
}

# some mkdir()s don't like to create a dir if the argument path has a
# trailing slash. (John Goerzen says this is true of BSDI.) So although
# canonically store directories with trailing slashes (to prevent
# concatenating together a path and forgetting an intervening slash),
# we need to strip the slash before calling mkdir().
# THANKS: John Goerzen
sub stripSlash {
	my $arg = shift;

	$arg =~ s#/+$##;
	return $arg;
}

sub tempPassPage {
	my $rt;
	$rt = gettext("You must enter the correct temporary password to install this FAQ-O-Matic. If you don't know it, remake the CGI stub to have a new one assigned.");
	$rt .= installUrl('', 'GET', 'install', '', '');
		# last '' prevents an old, incorrect temppass from sticking around
	$rt .= gettext("Temporary password: ")."<input type=password size=36 name=temppass>\n";
	# Null submit button is a workaround for a bug in Lynx that
	# prevents you from submitting a page with only a password field.
	# THANKS Boyd Lynn Gerber <gerberb@zenez.com> for complaining about this
	$rt .= "<input type=submit name=Submit value=Submit>\n";
	$rt .= "</form>\n";

	print FAQ::OMatic::header(cgi(), '-type'=>"text/html");
	print $rt;
	FAQ::OMatic::myExit(0);
}

1;






