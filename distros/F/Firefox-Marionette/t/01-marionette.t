#! /usr/bin/perl

use strict;
use warnings;
use Digest::SHA();
use MIME::Base64();
use Test::More tests => 174;
use Cwd();
use Firefox::Marionette();
use Config;

sub start_firefox {
	my ($require_visible, %parameters) = @_;
        my $firefox;
	eval {
		$firefox = Firefox::Marionette->new(%parameters);
	};
	my $exception = $@;
	chomp $exception;
	my $skip_message;
	if ($exception) {
		my ($package, $file, $line) = caller;
		my $source = $package eq 'main' ? $file : $package;
		diag("Exception in $source at line $line during new:$exception");
	}
	if ($exception =~ /^(Firefox exited with a 11|Firefox killed by a SEGV signal \(11\))/) {
		diag("Caught a SEGV type exception.  Running any appliable memory checks");
		if ($^O eq 'linux') {
			diag("grep -r Mem /proc/meminfo");
			diag(`grep -r Mem /proc/meminfo`);
			diag("ulimit -a | grep -i mem");
			diag(`ulimit -a | grep -i mem`);
		} elsif ($^O =~ /bsd/i) {
			diag("sysctl hw | egrep 'hw.(phys|user|real)'");
			diag(`sysctl hw | egrep 'hw.(phys|user|real)'`);
			diag("ulimit -a | grep -i mem");
			diag(`ulimit -a | grep -i mem`);
		}
		sleep 5 + int rand 5; # magic number.  No science behind it. Trying to give time to allow OS/firefox to recover (5-9 seconds)
		$firefox = undef;
		eval {
			$firefox = Firefox::Marionette->new(%parameters);
		};
		if ($firefox) {
		} else {
			diag("Caught a second exception:$@");
			$skip_message = "Skip tests that depended on firefox starting successfully:$@";
		}
	} elsif ($exception) {
		if (($^O eq 'MSWin32') || ($^O eq 'cygwin') || ($^O eq 'darwin')) {
			diag("Failed to start in $^O:$exception");
		} else {
			`Xvfb -help 2>/dev/null | grep displayfd`;
			if ($? == 1) {
				`dbus-launch 2>/dev/null >/dev/null`;
				if ($? == 0) {
					if ($^O eq 'freebsd') {
						my $mount = `mount`;
						if ($mount =~ /fdescfs/) {
							diag("Failed to start with fdescfs mounted and a working Xvfb and D-Bus:$exception");
						} else {
							$skip_message = "Unable to launch a visible firefox in $^O without fdescfs mounted:$exception";
						}
					} else {
						diag("Failed to start with a working Xvfb and D-Bus:$exception");
					}
				} else {
					$skip_message = "Unable to launch a visible firefox in $^O with an incorrectly setup D-Bus:$exception";
				}
			} elsif ($require_visible) {
				$skip_message = "Unable to launch a visible firefox in $^O without Xvfb:$exception";
			}
		}
	}
	return ($skip_message, $firefox);
}

umask 0;
my $binary = 'firefox';
if ( $^O eq 'MSWin32' ) {
    my $program_files_key;
    foreach my $possible ( 'ProgramFiles(x86)', 'ProgramFiles' ) {
        if ( $ENV{$possible} ) {
            $program_files_key = $possible;
            last;
        }
    }
    $binary = File::Spec->catfile(
        $ENV{$program_files_key},
        'Mozilla Firefox',
        'firefox.exe'
    );
}
elsif ( $^O eq 'darwin' ) {
    $binary = '/Applications/Firefox.app/Contents/MacOS/firefox';
} elsif ($^O eq 'cygwin') {
	if (-e "$ENV{PROGRAMFILES} (x86)") {
		$binary = "$ENV{PROGRAMFILES} (x86)/Mozilla Firefox/firefox.exe";
	} else {
		$binary = "$ENV{PROGRAMFILES}/Mozilla Firefox/firefox.exe";
	}
}
my $version_string = `"$binary" -version`;
diag("Version is $version_string");
if ($^O eq 'MSWin32') {
} elsif ($^O eq 'darwin') {
} else {
	if (exists $ENV{XAUTHORITY}) {
		diag("XAUTHORITY is $ENV{XAUTHORITY}");
	}
	if (exists $ENV{DISPLAY}) {
		diag("DISPLAY is $ENV{DISPLAY}");
	}
	`dbus-launch >/dev/null`;
	if ($? == 0) {
		diag("D-Bus is working");
	} else {
		diag("D-Bus appears to be broken.  'dbus-launch' was unable to successfully complete:$?");
	}
	if ($^O eq 'freebsd') {
		`pkg -v >/dev/null 2>/dev/null`;
		if ($? == 0) {
			diag("pkg -v is " . `pkg -v`);
			diag("xorg-vfbserver version is " . `pkg info xorg-vfbserver | perl -nle 'print "\$1" if (/Version\\s+:\\s+(\\S+)\\s*/);'`);
			diag("xkeyboard-config version is " . `pkg info xkeyboard-config | perl -nle 'print "\$1" if (/Version\\s+:\\s+(\\S+)\\s*/);'`);
			diag("xkbcomp version is " . `pkg info xkbcomp | perl -nle 'print "\$1" if (/Version\\s+:\\s+(\\S+)\\s*/);'`);
			diag("xauth version is " . `pkg info xauth | perl -nle 'print "\$1" if (/Version\\s+:\\s+(\\S+)\\s*/);'`);
			diag("xorg-fonts version is " . `pkg info xorg-fonts | perl -nle 'print "\$1" if (/Version\\s+:\\s+(\\S+)\\s*/);'`);
		} else {
			diag("pkg does not seem to be supported in $^O");
		}
		print "mount | grep fdescfs\n";
		my $result = `mount | grep fdescfs`;
		if ($result =~ /fdescfs/) {
			diag("fdescfs has been mounted.  /dev/fd/ should work correctly for xvfb/xauth");
		} else {
			diag("It looks like 'sudo mount -t fdescfs fdesc /dev/fd' needs to be executed")
		}
	} elsif ($^O eq 'linux') {
		`dpkg --help >/dev/null 2>/dev/null`;
		if ($? == 0) {	
			diag("DPKG version is " . `dpkg -s Xvfb | perl -nle 'print if s/^Version:[ ]//smx'`);
		} else {
			`rpm --help >/dev/null 2>/dev/null`;
			if (($? == 0) && (-f '/usr/bin/Xvfb')) {
				diag("RPM version is " . `rpm -qf /usr/bin/Xvfb`);
			}
		}
	}
}
if ($^O eq 'linux') {
	diag("grep -r Mem /proc/meminfo");
	diag(`grep -r Mem /proc/meminfo`);
	diag("ulimit -a | grep -i mem");
	diag(`ulimit -a | grep -i mem`);
} elsif ($^O =~ /bsd/i) {
	diag("sysctl hw | egrep 'hw.(phys|user|real)'");
	diag(`sysctl hw | egrep 'hw.(phys|user|real)'`);
	diag("ulimit -a | grep -i mem");
	diag(`ulimit -a | grep -i mem`);
}
my $count = 0;
foreach my $name (Firefox::Marionette::Profile->names()) {
	my $profile = Firefox::Marionette::Profile->existing($name);
	$count += 1;
}
ok(1, "Read $count existing profiles");
diag("This firefox installation has $count existing profiles");
my $profile;
eval {
	$profile = Firefox::Marionette::Profile->existing();
};
ok(1, "Read existing profile if any");
my $firefox;
eval {
	$firefox = Firefox::Marionette->new(firefox_binary => '/firefox/is/not/here');
};
chomp $@;
ok((($@) and (not($firefox))), "Firefox::Marionette->new() threw an exception when launched with an incorrect path to a binary:$@");
eval {
	$firefox = Firefox::Marionette->new(firefox_binary => $^X);
};
chomp $@;
ok((($@) and (not($firefox))), "Firefox::Marionette->new() threw an exception when launched with a path to a non firefox binary:$@");
my $skip_message;
my $at_least_one_success;
my ($major_version, $minor_version, $patch_version); 
SKIP: {
	($skip_message, $firefox) = start_firefox(0, debug => 1);
	if (!$skip_message) {
		$at_least_one_success = 1;
	}
	if ($skip_message) {
		skip($skip_message, 28);
	}
	ok($firefox, "Firefox has started in Marionette mode");
	my $capabilities = $firefox->capabilities();
	diag("Browser version is " . $capabilities->browser_version());
	($major_version, $minor_version, $patch_version) = split /[.]/smx, $capabilities->browser_version(); 
	diag("Operating System is " . $capabilities->platform_name() . q[ ] . $capabilities->platform_version());
	diag("Profile Directory is " . $capabilities->moz_profile());
	diag("Mozilla PID is " . $capabilities->moz_process_id());
	if ($firefox->xvfb()) {
		diag("Internal xvfb PID is " . $firefox->xvfb());
	}
	ok($firefox->application_type(), "\$firefox->application_type() returns " . $firefox->application_type());
	ok($firefox->marionette_protocol(), "\$firefox->marionette_protocol() returns " . $firefox->marionette_protocol());
	ok($firefox->window_type() eq 'navigator:browser', "\$firefox->window_type() returns 'navigator:browser':" . $firefox->window_type());
	my $new_x = 3;
	my $new_y = 9;
	my $new_height = 452;
	my $new_width = 326;
	my $new = Firefox::Marionette::Window::Rect->new( pos_x => $new_x, pos_y => $new_y, height => $new_height, width => $new_width );
	my $old = $firefox->window_rect($new);
	ok($old->pos_x() =~ /^\-?\d+([.]\d+)?$/, "Window has a X position of " . $old->pos_x());
	ok($old->pos_y() =~ /^\-?\d+([.]\d+)?$/, "Window has a Y position of " . $old->pos_y());
	ok($old->width() =~ /^\d+([.]\d+)?$/, "Window has a width of " . $old->width());
	ok($old->height() =~ /^\d+([.]\d+)?$/, "Window has a height of " . $old->height());
	TODO: {
		local $TODO = $major_version < 57 ? $capabilities->browser_version() . " probably does not have support for \$firefox->window_rect()->wstate()" : q[];
		ok(defined $old->wstate() && $old->wstate() =~ /^\w+$/, "Window has a state of " . ($old->wstate() || q[]));
	}
	my $rect = $firefox->window_rect();
	ok($rect->pos_x() =~ /^[-]?\d+([.]\d+)?$/, "Window has a X position of " . $rect->pos_x());
	ok($rect->pos_y() =~ /^[-]?\d+([.]\d+)?$/, "Window has a Y position of " . $rect->pos_y());
	ok($rect->width() =~ /^\d+([.]\d+)?$/, "Window has a width of " . $rect->width());
	ok($rect->height() =~ /^\d+([.]\d+)?$/, "Window has a height of " . $rect->height());
	my $page_timeout = 45_043;
	my $script_timeout = 48_021;
	my $implicit_timeout = 41_001;
	$new = Firefox::Marionette::Timeouts->new(page_load => $page_timeout, script => $script_timeout, implicit => $implicit_timeout);
	my $timeouts = $firefox->timeouts($new);
	ok((ref $timeouts) eq 'Firefox::Marionette::Timeouts', "\$firefox->timeouts() returns a Firefox::Marionette::Timeouts object");
	ok($timeouts->page_load() =~ /^\d+$/, "\$timeouts->page_load() is an integer");
	ok($timeouts->script() =~ /^\d+$/, "\$timeouts->script() is an integer");
	ok($timeouts->implicit() =~ /^\d+$/, "\$timeouts->implicit() is an integer");
	$timeouts = $firefox->timeouts($new);
	ok($timeouts->page_load() == $page_timeout, "\$timeouts->page_load() is $page_timeout");
	ok($timeouts->script() == $script_timeout, "\$timeouts->script() is $script_timeout");
	ok($timeouts->implicit() == $implicit_timeout, "\$timeouts->implicit() is $implicit_timeout");
	ok(!defined $firefox->child_error(), "Firefox does not have a value for child_error");
	ok(not($firefox->script('window.open("https://duckduckgo.com", "duckduckgo");')), "Opening new window to duckduckgo.com via 'window.open' script");
	ok($firefox->alive(), "Firefox is still alive");
	ok($firefox->close_current_window_handle(), "Closed new tab/window");
	ok($firefox->delete_session()->new_session(), "\$firefox->delete_session()->new_session() has cleared the old session and created a new session");
	my $child_error = $firefox->quit();
	if ($child_error != 0) {
		diag("Firefox exited with a \$? of $child_error");
	}
	ok($child_error =~ /^\d+$/, "Firefox has closed with an integer exit status of " . $child_error);
	ok($firefox->child_error() == $child_error, "Firefox returns $child_error for the child error, matching the return value of quit():$child_error:" . $firefox->child_error());
	ok(!$firefox->alive(), "Firefox is not still alive");
}

SKIP: {
	($skip_message, $firefox) = start_firefox(0, debug => 1, capabilities => Firefox::Marionette::Capabilities->new(moz_headless => 1, accept_insecure_certs => 1, page_load_strategy => 'eager', moz_webdriver_click => 1, moz_accessibility_checks => 1));
	if (!$skip_message) {
		$at_least_one_success = 1;
	}
	if ($skip_message) {
		skip($skip_message, 8);
	}
	ok($firefox, "Firefox has started in Marionette mode with definable capabilities set to known values");
	my $capabilities = $firefox->capabilities();
	ok((ref $capabilities) eq 'Firefox::Marionette::Capabilities', "\$firefox->capabilities() returns a Firefox::Marionette::Capabilities object");
	ok($capabilities->page_load_strategy() eq 'eager', "\$capabilities->page_load_strategy() is 'eager'");
	ok($capabilities->accept_insecure_certs() == 1, "\$capabilities->accept_insecure_certs() is set to true");
	TODO: {
		local $TODO = $major_version < 57 ? $capabilities->browser_version() . " probably does not have support for \$capabilities->moz_webdriver_click()" : q[];
		ok($capabilities->moz_webdriver_click() == 1, "\$capabilities->moz_webdriver_click() is set to true");
	}
	ok($capabilities->moz_accessibility_checks() == 1, "\$capabilities->moz_accessibility_checks() is set to true");
	ok($capabilities->moz_headless() == 1, "\$capabilities->moz_headless() is set to true");
	ok($firefox->quit() == 0, "Firefox has closed with an exit status of 0:" . $firefox->child_error());
}

ok($profile = Firefox::Marionette::Profile->new(), "Firefox::Marionette::Profile->new() correctly returns a new profile");
ok(((defined $profile->get_value('marionette.port')) && ($profile->get_value('marionette.port') == 0)), "\$profile->get_value('marionette.port') correctly returns 0");
ok($profile->set_value('browser.link.open_newwindow', 2), "\$profile->set_value('browser.link.open_newwindow', 2) to force new windows to appear");
SKIP: {
	($skip_message, $firefox) = start_firefox(0, debug => 0, profile => $profile);
	if (!$skip_message) {
		$at_least_one_success = 1;
	}
	if ($skip_message) {
		skip($skip_message, 107);
	}
	ok($firefox, "Firefox has started in Marionette mode without defined capabilities, but with a defined profile and debug turned off");
	ok($firefox->go(URI->new("https://www.w3.org/WAI/UA/TS/html401/cp0101/0101-FRAME-TEST.html")), "https://www.w3.org/WAI/UA/TS/html401/cp0101/0101-FRAME-TEST.html has been loaded");
	ok($firefox->window_handle() =~ /^\d+$/, "\$firefox->window_handle() is an integer:" . $firefox->window_handle());
	ok($firefox->chrome_window_handle() =~ /^\d+$/, "\$firefox->chrome_window_handle() is an integer:" . $firefox->chrome_window_handle());
	ok($firefox->chrome_window_handle() == $firefox->current_chrome_window_handle(), "\$firefox->chrome_window_handle() is equal to \$firefox->current_chrome_window_handle()");
	ok(scalar $firefox->chrome_window_handles() == 1, "There is one window/tab open at the moment");
	ok(scalar $firefox->window_handles() == 1, "There is one actual window open at the moment");
	my ($original_chrome_window_handle) = $firefox->chrome_window_handles();
	foreach my $handle ($firefox->chrome_window_handles()) {
		ok($handle =~ /^\d+$/, "\$firefox->chrome_window_handles() returns a list of integers:" . $handle);
	}
	my ($original_window_handle) = $firefox->window_handles();
	foreach my $handle ($firefox->window_handles()) {
		ok($handle =~ /^\d+$/, "\$firefox->window_handles() returns a list of integers:" . $handle);
	}
	ok(not($firefox->script('window.open("https://duckduckgo.com", "duckduckgo");')), "Opening new window to duckduckgo.com via 'window.open' script");
	ok(scalar $firefox->chrome_window_handles() == 2, "There are two windows/tabs open at the moment");
	ok(scalar $firefox->window_handles() == 2, "There are two actual windows open at the moment");
	my $new_chrome_window_handle;
	foreach my $handle ($firefox->chrome_window_handles()) {
		ok($handle =~ /^\d+$/, "\$firefox->chrome_window_handles() returns a list of integers:" . $handle);
		if ($handle != $original_chrome_window_handle) {
			$new_chrome_window_handle = $handle;
		}
	}
	ok($new_chrome_window_handle, "New chrome window handle $new_chrome_window_handle detected");
	my $new_window_handle;
	foreach my $handle ($firefox->window_handles()) {
		ok($handle =~ /^\d+$/, "\$firefox->window_handles() returns a list of integers:" . $handle);
		if ($handle != $original_window_handle) {
			$new_window_handle = $handle;
		}
	}
	ok($new_window_handle, "New window handle $new_window_handle detected");
	TODO: {
		my $screen_orientation = q[];
		eval {
			$screen_orientation = $firefox->screen_orientation();
			ok($screen_orientation, "\$firefox->screen_orientation() is " . $screen_orientation);
		} or do {
			if ($@ =~ /Only supported in Fennec/) {
				local $TODO = "Only supported in Fennec";
				ok($screen_orientation, "\$firefox->screen_orientation() is " . $screen_orientation);
			} else {
				ok($screen_orientation, "\$firefox->screen_orientation() is " . $screen_orientation);
			}
		};
	}
	ok($firefox->switch_to_window($original_window_handle), "\$firefox->switch_to_window() used to move back to the original window");
	TODO: {
		my $element;
		eval {
			$element = $firefox->find('//frame[@name="target1"]')->switch_to_shadow_root();
		};
		local $TODO = "Switch to shadow root can be broken";
		ok($element, "Switched to target1 shadow root");
	}
	ok($firefox->find('//frame[@name="target1"]')->switch_to_frame(), "Switched to target1 frame");
	ok($firefox->active_frame()->isa('Firefox::Marionette::Element'), "\$firefox->active_frame() returns a Firefox::Marionette::Element object");
	ok($firefox->switch_to_parent_frame(), "Switched to parent frame");
	foreach my $handle ($firefox->close_current_chrome_window_handle()) {
		ok($handle == $new_chrome_window_handle, "Closed original window, which means the remaining chrome window handle should be $new_chrome_window_handle:" . $handle);
	}
	ok($firefox->switch_to_window($new_window_handle), "\$firefox->switch_to_window() used to move to the new window");
	ok($firefox->go("https://metacpan.org/"), "metacpan.org has been loaded in the new window");
	my $uri = $firefox->uri();
	ok($uri eq 'https://metacpan.org/', "\$firefox->uri() is equal to https://metacpan.org/:$uri");
	ok($firefox->title() =~ /Search/, "metacpan.org has a title containing Search");
	ok($firefox->context('chrome') eq 'content', "Initial context of the browser is 'content'");
	ok($firefox->context('content') eq 'chrome', "Changed context of the browser is 'chrome'");
	ok($firefox->page_source() =~ /lucky/smx, "metacpan.org contains the phrase 'lucky' in page source");
	ok($firefox->html() =~ /lucky/smx, "metacpan.org contains the phrase 'lucky' in html");
	ok($firefox->refresh(), "\$firefox->refresh()");
	my $element = $firefox->active_element();
	ok($element, "\$firefox->active_element() returns an element");
	ok(not(defined $firefox->active_frame()), "\$firefox->active_frame() is undefined for " . $firefox->uri());
	ok($firefox->find('//input[@id="search-input"]')->type('Test::More'), "Sent 'Test::More' to the 'search-input' field directly to the element");
	my $autofocus;
	ok($autofocus = $firefox->find_element('//input[@id="search-input"]')->attribute('autofocus'), "The value of the autofocus attribute is '$autofocus'");
	ok($autofocus = $firefox->find('//input[@id="search-input"]')->property('autofocus'), "The value of the autofocus property is '$autofocus'");
	my $css_rule;
	ok($css_rule = $firefox->find('//input[@id="search-input"]')->css('display'), "The value of the css rule 'display' is '$css_rule'");
	my $result;
	ok($result = $firefox->find('//input[@id="search-input"]')->is_enabled() =~ /^[01]$/, "is_enabled returns 0 or 1:$result");
	ok($result = $firefox->find('//input[@id="search-input"]')->is_displayed() =~ /^[01]$/, "is_displayed returns 0 or 1:$result");
	ok($result = $firefox->find('//input[@id="search-input"]')->is_selected() =~ /^[01]$/, "is_selected returns 0 or 1:$result");
	ok($firefox->find('//input[@id="search-input"]')->clear(), "Clearing the element directly");
	ok($firefox->find('//input[@id="search-input"]')->send_keys('Test::More'), "Sent 'Test::More' to the 'search-input' field directly to the element");
	ok($firefox->find('//input[@id="search-input"]')->clear(), "Clearing the element directly");
	foreach my $element ($firefox->find_elements('//input[@id="search-input"]')) {
		ok($firefox->send_keys($element, 'Test::More'), "Sent 'Test::More' to the 'search-input' field via the browser");
		ok($firefox->clear($element), "Clearing the element via the browser");
		ok($firefox->type($element, 'Test::More'), "Sent 'Test::More' to the 'search-input' field via the browser");
		last;
	}
	my $text = $firefox->find('//button[@name="lucky"]')->text();
	ok($text, "Read '$text' directly from 'Lucky' button");
	my $tag_name = $firefox->find('//button[@name="lucky"]')->tag_name();
	ok($tag_name, "'Lucky' button has a tag name of '$tag_name'");
	my $rect = $firefox->find('//button[@name="lucky"]')->rect();
	ok($rect->pos_x() =~ /^\d+([.]\d+)?$/, "'Lucky' button has a X position of " . $rect->pos_x());
	ok($rect->pos_y() =~ /^\d+([.]\d+)?$/, "'Lucky' button has a Y position of " . $rect->pos_y());
	ok($rect->width() =~ /^\d+([.]\d+)?$/, "'Lucky' button has a width of " . $rect->width());
	ok($rect->height() =~ /^\d+([.]\d+)?$/, "'Lucky' button has a height of " . $rect->height());
	ok(((scalar $firefox->cookies()) > 0), "\$firefox->cookies() shows cookies on " . $firefox->uri());
	ok($firefox->delete_cookies() && ((scalar $firefox->cookies()) == 0), "\$firefox->delete_cookies() clears all cookies");
	my $capabilities = $firefox->capabilities();
	my $buffer = undef;
	my $handle = $firefox->selfie();
	$handle->read($buffer, 20);
	ok($buffer =~ /^\x89\x50\x4E\x47\x0D\x0A\x1A\x0A/smx, "\$firefox->selfie() returns a PNG file");
	$buffer = undef;
	$handle = $firefox->find('//button[@name="lucky"]')->selfie();
	$handle->read($buffer, 20);
	ok($buffer =~ /^\x89\x50\x4E\x47\x0D\x0A\x1A\x0A/smx, "\$firefox->find('//button[\@name=\"lucky\"]')->selfie() returns a PNG file");
	my $actual_digest = $firefox->selfie(hash => 1, highlights => [ $firefox->find('//button[@name="lucky"]') ]);
	ok($actual_digest =~ /^[a-f0-9]+$/smx, "\$firefox->selfie(hash => 1, highlights => [ \$firefox->find('//button[\@name=\"lucky\"]') ]) returns a hex encoded SHA256 digest");
	$handle = $firefox->selfie(highlights => [ $firefox->find('//button[@name="lucky"]') ]);
	$buffer = undef;
	$handle->read($buffer, 20);
	ok($buffer =~ /^\x89\x50\x4E\x47\x0D\x0A\x1A\x0A/smx, "\$firefox->selfie(highlights => [ \$firefox->find('//button[\@name=\"lucky\"]') ]) returns a PNG file");
	$handle->seek(0,0) or die "Failed to seek:$!";
	$handle->read($buffer, 1_000_000) or die "Failed to read:$!";
	my $correct_digest = Digest::SHA::sha256_hex(MIME::Base64::encode_base64($buffer, q[]));
	TODO: {
		local $TODO = "Digests can sometimes change for all platforms";
		ok($actual_digest eq $correct_digest, "\$firefox->selfie(hash => 1, highlights => [ \$firefox->find('//button[\@name=\"lucky\"]') ]) returns the correct hex encoded SHA256 hash of the base64 encoded image");
	}
	my $clicked;
	while ($firefox->uri() eq 'https://metacpan.org/') {
		ELEMENT: foreach my $element ($firefox->list('//a[@href="https://fastapi.metacpan.org"]')) {
			$clicked = 1;
			$firefox->click($element);
			last ELEMENT;
		}
	}
	ok($clicked, "Clicked the API link");
	ok($firefox->uri()->host() eq 'github.com', "\$firefox->uri()->host() is equal to github.com:" . $firefox->uri());
	my @cookies = $firefox->cookies();
	ok($cookies[0]->name() =~ /\w/, "The first cookie name is '" . $cookies[0]->name() . "'");
	ok($cookies[0]->value() =~ /\w/, "The first cookie value is '" . $cookies[0]->value() . "'");
	TODO: {
		local $TODO = ($major_version < 56) ? "\$cookies[0]->expiry() does not function for Firefox versions less than 56" : q[];
		ok(defined $cookies[0]->expiry() && $cookies[0]->expiry() =~ /^\d+$/, "The first cookie name has an integer expiry date of '" . ($cookies[0]->expiry() || q[]) . "'");
	}
	ok($cookies[0]->http_only() =~ /^[01]$/, "The first cookie httpOnly flag is a boolean set to '" . $cookies[0]->http_only() . "'");
	ok($cookies[0]->secure() =~ /^[01]$/, "The first cookie secure flag is a boolean set to '" . $cookies[0]->secure() . "'");
	ok($cookies[0]->path() =~ /\S/, "The first cookie path is a string set to '" . $cookies[0]->path() . "'");
	ok($cookies[0]->domain() =~ /^[\w\-.]+$/, "The first cookie domain is a domain set to '" . $cookies[0]->domain() . "'");
	my $original_number_of_cookies = scalar @cookies;
	ok(($original_number_of_cookies > 1) && ((ref $cookies[0]) eq 'Firefox::Marionette::Cookie'), "\$firefox->cookies() returns more than 1 cookie on " . $firefox->uri());
	ok($firefox->delete_cookie($cookies[0]->name()), "\$firefox->delete_cookie('" . $cookies[0]->name() . "') deletes the specified cookie name");
	ok(not(grep { $_->name() eq $cookies[0]->name() } $firefox->cookies()), "List of cookies no longer includes " . $cookies[0]->name());
	ok($firefox->back(), "\$firefox->back() goes back one page");
	ok($firefox->uri()->host() eq 'metacpan.org', "\$firefox->uri()->host() is equal to metacpan.org:" . $firefox->uri());
	ok($firefox->forward(), "\$firefox->forward() goes forward one page");
	ok($firefox->uri()->host() eq 'github.com', "\$firefox->uri()->host() is equal to github.com:" . $firefox->uri());
	ok($firefox->back(), "\$firefox->back() goes back one page");
	ok($firefox->uri()->host() eq 'metacpan.org', "\$firefox->uri()->host() is equal to metacpan.org:" . $firefox->uri());
	ok($firefox->script('return window.find("lucky");'), "metacpan.org contains the phrase 'lucky' in a 'window.find' javascript command");
	my $cookie = Firefox::Marionette::Cookie->new(name => 'BonusCookie', value => 'who really cares about privacy', expiry => time + 500000);
	ok($firefox->add_cookie($cookie), "\$firefox->add_cookie() adds a Firefox::Marionette::Cookie without a domain");
	foreach my $element ($firefox->list('//button[@name="lucky"]')) {
		ok($firefox->click($element), "Clicked the \"I'm Feeling Lucky\" button");
	}
	my $alert_text = 'testing alert';
	$firefox->script(qq[alert('$alert_text')]);
	ok($firefox->alert_text() eq $alert_text, "\$firefox->alert_text() correctly detects alert text");
	ok($firefox->dismiss_alert(), "\$firefox->dismiss_alert() dismisses alert box");
	$capabilities = $firefox->capabilities();
	my $version = $capabilities->browser_version();
	my ($major_version, $minor_version, $patch_version) = split /[.]/, $version;
	ok($firefox->async_script(qq[prompt("Please enter your name", "John Cole");]), "Started async script containing a prompt");
	TODO: {
		local $TODO = "\$firefox->async_script() not perfect in Firefox yet";
		my $result;
		eval {
			$result = $firefox->send_alert_text("Roland Grelewicz");
		};
		ok($result, "\$firefox->send_alert_text() sends alert text");
		$result = undef;
		eval {
			$result = $firefox->accept_dialog();
		};
		ok($result, "\$firefox->accept_dialog() accepts the dialog box");
	}
	ok($firefox->current_chrome_window_handle() =~ /^\d+$/, "Returned the current chrome window handle as an integer");
	$capabilities = $firefox->capabilities();
	ok((ref $capabilities) eq 'Firefox::Marionette::Capabilities', "\$firefox->capabilities() returns a Firefox::Marionette::Capabilities object");
	ok($capabilities->page_load_strategy() =~ /^\w+$/, "\$capabilities->page_load_strategy() is a string:" . $capabilities->page_load_strategy());
	ok($capabilities->moz_headless() =~ /^(1|0)$/, "\$capabilities->moz_headless() is a boolean:" . $capabilities->moz_headless());
	ok($capabilities->accept_insecure_certs() =~ /^(1|0)$/, "\$capabilities->accept_insecure_certs() is a boolean:" . $capabilities->accept_insecure_certs());
	ok($capabilities->moz_process_id() =~ /^\d+$/, "\$capabilities->moz_process_id() is an integer:" . $capabilities->moz_process_id());
	ok($capabilities->browser_name() =~ /^\w+$/, "\$capabilities->browser_name() is a string:" . $capabilities->browser_name());
	ok($capabilities->rotatable() =~ /^(1|0)$/, "\$capabilities->rotatable() is a boolean:" . $capabilities->rotatable());
	ok($capabilities->moz_accessibility_checks() =~ /^(1|0)$/, "\$capabilities->moz_accessibility_checks() is a boolean:" . $capabilities->moz_accessibility_checks());
	ok((ref $capabilities->timeouts()) eq 'Firefox::Marionette::Timeouts', "\$capabilities->timeouts() returns a Firefox::Marionette::Timeouts object");
	ok($capabilities->timeouts()->page_load() =~ /^\d+$/, "\$capabilities->timeouts->page_load() is an integer:" . $capabilities->timeouts()->page_load());
	ok($capabilities->timeouts()->script() =~ /^\d+$/, "\$capabilities->timeouts->script() is an integer:" . $capabilities->timeouts()->script());
	ok($capabilities->timeouts()->implicit() =~ /^\d+$/, "\$capabilities->timeouts->implicit() is an integer:" . $capabilities->timeouts()->implicit());
	ok($capabilities->browser_version() =~ /^\d+[.]\d+([.]\d+)?$/, "\$capabilities->browser_version() is a major.minor.patch version number:" . $capabilities->browser_version());
	ok($capabilities->platform_version() =~ /\d+/, "\$capabilities->platform_version() contains a number:" . $capabilities->platform_version());
	ok($capabilities->moz_profile() =~ /firefox_marionette/, "\$capabilities->moz_profile() contains 'firefox_marionette':" . $capabilities->moz_profile());
	TODO: {
		local $TODO = $major_version < 57 ? $capabilities->browser_version() . " probably does not have support for \$capabilities->moz_webdriver_click()" : q[];
		ok($capabilities->moz_webdriver_click() =~ /^(1|0)$/, "\$capabilities->moz_webdriver_click() is a boolean:" . $capabilities->moz_webdriver_click());
	}
	ok($capabilities->platform_name() =~ /\w+/, "\$capabilities->platform_version() contains alpha characters:" . $capabilities->platform_name());
	TODO: {
		local $TODO = "\$firefox->dismiss_alert() not perfect yet";
		eval {
			$firefox->dismiss_alert();
		};
		ok($@, "Dismiss non-existant alert caused an exception to be thrown");
	}
	my $install_id;
	my $install_path = Cwd::abs_path("t/addons/test.xpi");
	if ($^O eq 'cygwin') {
		my $drive = $ENV{SYSTEMDRIVE};
		$install_path = "${drive}/cygwin64$install_path";
		$install_path =~ s/\//\\/smxg;
	} elsif ($^O eq 'MSWin32') {
		$install_path =~ s/\//\\/smxg;
	}
	diag("Installing extension from $install_path");
	ok($install_id = $firefox->install($install_path, 1), "Successfully installed an extension:$install_id");
	ok($firefox->uninstall($install_id), "Successfully uninstalled an extension");
	ok($firefox->accept_connections(0), "Refusing future connections");
	ok($firefox->quit() == 0, "Firefox has closed with an exit status of 0:" . $firefox->child_error());
}

SKIP: {
	($skip_message, $firefox) = start_firefox(0, visible => 0);
	if (!$skip_message) {
		$at_least_one_success = 1;
	}
	if ($skip_message) {
		skip($skip_message, 4);
	}
	ok($firefox, "Firefox has started in Marionette mode with visible set to 0");
	my $capabilities = $firefox->capabilities();
	ok((ref $capabilities) eq 'Firefox::Marionette::Capabilities', "\$firefox->capabilities() returns a Firefox::Marionette::Capabilities object");
	ok($capabilities->moz_headless(), "\$capabilities->moz_headless() is set to true");
	ok($firefox->quit() == 0, "Firefox has closed with an exit status of 0:" . $firefox->child_error());
}

SKIP: {
	($skip_message, $firefox) = start_firefox(1, debug => 1, capabilities => Firefox::Marionette::Capabilities->new(moz_headless => 0, accept_insecure_certs => 0, page_load_strategy => 'none', moz_webdriver_click => 0, moz_accessibility_checks => 0));
	if (!$skip_message) {
		$at_least_one_success = 1;
	}
	if ($skip_message) {
		skip($skip_message, 8);
	}
	ok($firefox, "Firefox has started in Marionette mode with definable capabilities set to different values");
	my $capabilities = $firefox->capabilities();
	ok((ref $capabilities) eq 'Firefox::Marionette::Capabilities', "\$firefox->capabilities() returns a Firefox::Marionette::Capabilities object");
	ok($capabilities->page_load_strategy() eq 'none', "\$capabilities->page_load_strategy() is 'none'");
	ok($capabilities->accept_insecure_certs() == 0, "\$capabilities->accept_insecure_certs() is set to false");
	TODO: {
		local $TODO = $major_version < 57 ? $capabilities->browser_version() . " probably does not have support for \$capabilities->moz_webdriver_click()" : q[];
		ok($capabilities->moz_webdriver_click() == 0, "\$capabilities->moz_webdriver_click() is set to false");
	}
	ok($capabilities->moz_accessibility_checks() == 0, "\$capabilities->moz_accessibility_checks() is set to false");
	ok(not($capabilities->moz_headless()), "\$capabilities->moz_headless() is set to false");
	ok($firefox->quit() == 0, "Firefox has closed with an exit status of 0:" . $firefox->child_error());
}
SKIP: {
	($skip_message, $firefox) = start_firefox(1, visible => 1);
	if (!$skip_message) {
		$at_least_one_success = 1;
	}
	if ($skip_message) {
		skip($skip_message, 7);
	}
	ok($firefox, "Firefox has started in Marionette mode with visible set to 1");
	my $capabilities = $firefox->capabilities();
	ok((ref $capabilities) eq 'Firefox::Marionette::Capabilities', "\$firefox->capabilities() returns a Firefox::Marionette::Capabilities object");
	ok(!$capabilities->moz_headless(), "\$capabilities->moz_headless() is set to false");
	SKIP: {
		if ((exists $ENV{XAUTHORITY}) && (defined $ENV{XAUTHORITY}) && ($ENV{XAUTHORITY} =~ /xvfb/smxi)) {
			skip("Unable to change firefox screen size when xvfb is running", 3);	
		} elsif ($firefox->xvfb()) {
			skip("Unable to change firefox screen size when xvfb is running", 3);	
		}
		local $TODO = "Not entirely stable in firefox";
		my $full_screen;
		local $SIG{ALRM} = sub { die "alarm during full screen\n" };
		alarm 15;
		eval {
			$full_screen = $firefox->full_screen();
		} or do {
			diag("Crashed during \$firefox->full_screen:$@");
		};
		alarm 0;
		ok($full_screen, "\$firefox->full_screen()");
		my $minimise;
		local $SIG{ALRM} = sub { die "alarm during minimise\n" };
		alarm 15;
		eval {
			$minimise = $firefox->minimise();
		} or do {
			diag("Crashed during \$firefox->minimise:$@");
		};
		alarm 0;
		ok($minimise, "\$firefox->minimise()");
		my $maximise;
		local $SIG{ALRM} = sub { die "alarm during maximise\n" };
		alarm 15;
		eval {
			$maximise = $firefox->maximise();
		} or do {
			diag("Crashed during \$firefox->maximise:$@");
		};
		alarm 0;
		ok($maximise, "\$firefox->maximise()");
	}
	if ($^O eq 'MSWin32') {
		ok($firefox->quit() == 0, "Firefox has closed with an exit status of 0:" . $firefox->child_error());
	} else {
		my @sig_nums  = split q[ ], $Config{sig_num};
		my @sig_names = split q[ ], $Config{sig_name};
		my %signals_by_name;
		my $idx = 0;
		foreach my $sig_name (@sig_names) {
			$signals_by_name{$sig_name} = $sig_nums[$idx];
			$idx += 1;
		}
		while($firefox->alive()) {
			diag("Killing PID " . $capabilities->moz_process_id() . " with a signal " . $signals_by_name{TERM});
			kill $signals_by_name{TERM}, $capabilities->moz_process_id();
			sleep 1;
		}
		ok($firefox->quit() == $signals_by_name{TERM}, "Firefox has been killed by a signal with value of $signals_by_name{TERM}:" . $firefox->child_error() . ":" . $firefox->error_message());
		diag("Error Message was " . $firefox->error_message());
	}
}
ok($at_least_one_success, "At least one firefox start worked");

