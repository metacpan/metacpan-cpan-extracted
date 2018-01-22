#! /usr/bin/perl

use strict;
use warnings;
use Digest::SHA();
use MIME::Base64();
use Test::More tests => 152;
use Firefox::Marionette();

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
}
my $version_string = `"$binary" -version`;
diag("Version is $version_string");
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
ok($firefox = Firefox::Marionette->new(debug => 1), "Firefox has started in Marionette mode");
my $capabilities = $firefox->capabilities();
diag("Browser version is " . $capabilities->browser_version());
diag("Operating System is " . $capabilities->platform_name() . q[ ] . $capabilities->platform_version());
diag("Profile Directory is " . $capabilities->moz_profile());
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
ok($old->state() =~ /^\w+$/, "Window has a state of " . $old->state());
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
ok(not($firefox->script('window.open("https://duckduckgo.com", "duckduckgo");')), "Opening new window to duckduckgo.com via 'window.open' script");
ok($firefox->close_current_window_handle(), "Closed new tab/window");
ok($firefox->quit(), "Firefox has closed");

ok($firefox = Firefox::Marionette->new(capabilities => Firefox::Marionette::Capabilities->new(moz_headless => 1, accept_insecure_certs => 1, page_load_strategy => 'eager', moz_webdriver_click => 1, moz_accessibility_checks => 1)), "Firefox has started in Marionette mode with definable capabilities set to known values");
$capabilities = $firefox->capabilities();
ok((ref $capabilities) eq 'Firefox::Marionette::Capabilities', "\$firefox->capabilities() returns a Firefox::Marionette::Capabilities object");
ok($capabilities->page_load_strategy() eq 'eager', "\$capabilities->page_load_strategy() is 'eager'");
ok($capabilities->accept_insecure_certs() == 1, "\$capabilities->accept_insecure_certs() is set to true");
ok($capabilities->moz_webdriver_click() == 1, "\$capabilities->moz_webdriver_click() is set to true");
ok($capabilities->moz_accessibility_checks() == 1, "\$capabilities->moz_accessibility_checks() is set to true");
ok($capabilities->moz_headless() == 1, "\$capabilities->moz_headless() is set to true");
ok($firefox->quit(), "Firefox has closed");

ok($firefox = Firefox::Marionette->new(capabilities => Firefox::Marionette::Capabilities->new(moz_headless => 0, accept_insecure_certs => 0, page_load_strategy => 'none', moz_webdriver_click => 0, moz_accessibility_checks => 0)), "Firefox has started in Marionette mode with definable capabilities set to different values");
$capabilities = $firefox->capabilities();
ok((ref $capabilities) eq 'Firefox::Marionette::Capabilities', "\$firefox->capabilities() returns a Firefox::Marionette::Capabilities object");
ok($capabilities->page_load_strategy() eq 'none', "\$capabilities->page_load_strategy() is 'none'");
ok($capabilities->accept_insecure_certs() == 0, "\$capabilities->accept_insecure_certs() is set to false");
ok($capabilities->moz_webdriver_click() == 0, "\$capabilities->moz_webdriver_click() is set to false");
ok($capabilities->moz_accessibility_checks() == 0, "\$capabilities->moz_accessibility_checks() is set to false");
ok(not($capabilities->moz_headless()), "\$capabilities->moz_headless() is set to false");
ok($firefox->quit(), "Firefox has closed");

ok($profile = Firefox::Marionette::Profile->new(), "Firefox::Marionette::Profile->new() correctly returns a new profile");
ok(((defined $profile->get_value('marionette.port')) && ($profile->get_value('marionette.port') == 0)), "\$profile->get_value('marionette.port') correctly returns 0");
ok($profile->set_value('browser.link.open_newwindow', 2), "\$profile->set_value('browser.link.open_newwindow', 2) to force new windows to appear");
ok($firefox = Firefox::Marionette->new(debug => 1, profile => $profile), "Firefox has started in Marionette mode without defined capabilities, but with a defined profile and debug turned on");
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
ok($firefox->find_element('//frame[@name="target1"]')->switch_to_shadow_root(), "Switched to target1 shadow root");
ok($firefox->find_element('//frame[@name="target1"]')->switch_to_frame(), "Switched to target1 frame");
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
SKIP: {
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm 10;
	if ((exists $ENV{XAUTHORITY}) && (defined $ENV{XAUTHORITY}) && ($ENV{XAUTHORITY} =~ /xvfb/smxi)) {
		skip("Unable to change firefox screen size when xvfb is running", 3);	
	} elsif ($firefox->xvfb()) {
		skip("Unable to change firefox screen size when xvfb is running", 3);	
	}
	ok($firefox->full_screen(), "\$firefox->full_screen()");
	if ($capabilities->moz_headless()) {
		skip("Unable to minimise/maximise firefox screen size when operating in headless mode", 2);	
	}
	ok($firefox->minimise(), "\$firefox->minimise()");
	ok($firefox->maximise(), "\$firefox->maximise()");
}
alarm 0;
ok($firefox->context('chrome') eq 'content', "Initial context of the browser is 'content'");
ok($firefox->context('content') eq 'chrome', "Changed context of the browser is 'chrome'");
ok($firefox->page_source() =~ /lucky/smx, "metacpan.org contains the phrase 'lucky' in page source");
ok($firefox->refresh(), "\$firefox->refresh()");
my $element = $firefox->active_element();
ok($element, "\$firefox->active_element() returns an element");
ok(not(defined $firefox->active_frame()), "\$firefox->active_frame() is undefined for " . $firefox->uri());
ok($firefox->find_element('//input[@id="search-input"]')->send_keys('Test::More'), "Sent 'Test::More' to the 'search-input' field directly to the element");
my $autofocus;
ok($autofocus = $firefox->find_element('//input[@id="search-input"]')->attribute('autofocus'), "The value of the autofocus attribute is '$autofocus'");
my $css_rule;
ok($css_rule = $firefox->find_element('//input[@id="search-input"]')->css('display'), "The value of the css rule 'display' is '$css_rule'");
my $result;
ok($result = $firefox->find_element('//input[@id="search-input"]')->is_enabled() =~ /^[01]$/, "is_enabled returns 0 or 1:$result");
ok($result = $firefox->find_element('//input[@id="search-input"]')->is_displayed() =~ /^[01]$/, "is_displayed returns 0 or 1:$result");
ok($result = $firefox->find_element('//input[@id="search-input"]')->is_selected() =~ /^[01]$/, "is_selected returns 0 or 1:$result");
ok($firefox->find_element('//input[@id="search-input"]')->clear(), "Clearing the element directly");
foreach my $element ($firefox->find_elements('//input[@id="search-input"]')) {
	ok($firefox->send_keys($element, 'Test::More'), "Sent 'Test::More' to the 'search-input' field via the browser");
	last;
}
my $text = $firefox->find_element('//button[@name="lucky"]')->text();
ok($text, "Read '$text' directly from 'Lucky' button");
my $tag_name = $firefox->find_element('//button[@name="lucky"]')->tag_name();
ok($tag_name, "'Lucky' button has a tag name of '$tag_name'");
$rect = $firefox->find_element('//button[@name="lucky"]')->rect();
ok($rect->pos_x() =~ /^\d+([.]\d+)?$/, "'Lucky' button has a X position of " . $rect->pos_x());
ok($rect->pos_y() =~ /^\d+([.]\d+)?$/, "'Lucky' button has a Y position of " . $rect->pos_y());
ok($rect->width() =~ /^\d+([.]\d+)?$/, "'Lucky' button has a width of " . $rect->width());
ok($rect->height() =~ /^\d+([.]\d+)?$/, "'Lucky' button has a height of " . $rect->height());
ok(((scalar $firefox->cookies()) > 0), "\$firefox->cookies() shows cookies on " . $firefox->uri());
ok($firefox->delete_cookies() && ((scalar $firefox->cookies()) == 0), "\$firefox->delete_cookies() clears all cookies");
$capabilities = $firefox->capabilities();
diag("Debug to aid in replicating 'X_GetImage: BadMatch' type crashes");
diag("Mozilla PID is " . $capabilities->moz_process_id());
if ($firefox->xvfb()) {
	diag("Internal xvfb PID is " . $firefox->xvfb());
}
TODO: {
	my $buffer;
	eval {
		my $handle = $firefox->selfie();
		$handle->read($buffer, 20);
	};
	my $x_failed;
	if ($@ =~ /X_GetImage: BadMatch/) {
		$x_failed = 1;
		eval {
			$firefox->quit();
		};
		$firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
	}
	local $TODO = $x_failed ? "X-windows sometimes fails with weird errors on screenshots" : undef;
	ok($buffer =~ /^\x89\x50\x4E\x47\x0D\x0A\x1A\x0A/smx, "\$firefox->selfie() returns a PNG file");
}
TODO: {
	my $buffer;
	eval {
		my $handle = $firefox->find_element('//button[@name="lucky"]')->selfie();
		$handle->read($buffer, 20);
	};
	my $x_failed;
	if ($@ =~ /X_GetImage: BadMatch/) {
		$x_failed = 1;
		eval {
			$firefox->quit();
		};
		$firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
	}
	local $TODO = $x_failed ? "X-windows sometimes fails with weird errors on screenshots" : undef;
	ok($buffer =~ /^\x89\x50\x4E\x47\x0D\x0A\x1A\x0A/smx, "\$firefox->find_element('//button[\@name=\"lucky\"]')->selfie() returns a PNG file");
}
TODO: {
	my $actual_digest;
	eval {
		$actual_digest = $firefox->selfie(hash => 1, highlights => [ $firefox->find_element('//button[@name="lucky"]') ]);
	};
	my $x_failed;
	if ($@ =~ /X_GetImage: BadMatch/) {
		$x_failed = 1;
		eval {
			$firefox->quit();
		};
		$firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
	}
	local $TODO = $x_failed ? "X-windows sometimes fails with weird errors on screenshots" : undef;
	ok($actual_digest =~ /^[a-f0-9]+$/smx, "\$firefox->selfie(hash => 1, highlights => [ \$firefox->find_element('//button[\@name=\"lucky\"]') ]) returns a hex encoded SHA256 digest");
	my $handle;
	eval {
		$handle = $firefox->selfie(highlights => [ $firefox->find_element('//button[@name="lucky"]') ]);
	};
	if ($@ =~ /X_GetImage: BadMatch/) {
		$x_failed = 1;
		eval {
			$firefox->quit();
		};
		$firefox = Firefox::Marionette->new()->go('https://metacpan.org/');
	}
	local $TODO = $x_failed ? "X-windows sometimes fails with weird errors on screenshots" : undef;
	my $buffer;
	if (defined $handle) {
		$handle->read($buffer, 20);
	}
	ok($buffer =~ /^\x89\x50\x4E\x47\x0D\x0A\x1A\x0A/smx, "\$firefox->selfie(highlights => [ \$firefox->find_element('//button[\@name=\"lucky\"]') ]) returns a PNG file");
	if (defined $handle) {
		$handle->seek(0,0) or die "Failed to seek:$!";
		$handle->read($buffer, 1_000_000) or die "Failed to read:$!";
	}
	my $correct_digest = Digest::SHA::sha256_hex(MIME::Base64::encode_base64($buffer, q[]));
	local $TODO = $x_failed ? "X-windows sometimes fails with weird errors on screenshots" : "Digests can sometimes change for all platforms";
	ok($actual_digest eq $correct_digest, "\$firefox->selfie(hash => 1, highlights => [ \$firefox->find_element('//button[\@name=\"lucky\"]') ]) returns the correct hex encoded SHA256 hash of the base64 encoded image");
}
my $clicked;
while ($firefox->uri() eq 'https://metacpan.org/') {
	ELEMENT: foreach my $element ($firefox->find_elements('//a[@href="https://fastapi.metacpan.org"]')) {
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
ok($cookies[0]->expiry() =~ /^\d+$/, "The first cookie name has an integer expiry date of '" . $cookies[0]->expiry() . "'");
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
foreach my $element ($firefox->find_elements('//button[@name="lucky"]')) {
	ok($firefox->click($element), "Clicked the \"I'm Feeling Lucky\" button");
}
my $alert_text = 'testing alert';
$firefox->script(qq[alert('$alert_text')]);
ok($firefox->alert_text() eq $alert_text, "\$firefox->alert_text() correctly detects alert text");
ok($firefox->dismiss_alert(), "\$firefox->dismiss_alert() dismisses alert box");
ok($firefox->async_script(qq[prompt("Please enter your name", "Roland Grelewicz");]), "Started async script containing a prompt");
TODO: {
	local $TODO = ($^O eq 'MSWin32') ? "\$firefox->send_alert_text() not perfect in Win32 yet" : undef;
	eval {
		$result = $firefox->send_alert_text("John Cole");
	};
	ok($result, "\$firefox->send_alert_text() sends alert text");
}
TODO: {
	local $TODO = ($^O eq 'MSWin32') ? "\$firefox->accept_dialog() not perfect in Win32 yet" : undef;
	eval {
		$firefox->accept_dialog();
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
ok($capabilities->browser_version() =~ /^\d+[.]\d+[.]\d+$/, "\$capabilities->browser_version() is a major.minor.patch version number:" . $capabilities->browser_version());
ok($capabilities->platform_version() =~ /\d+/, "\$capabilities->platform_version() contains a number:" . $capabilities->platform_version());
ok($capabilities->moz_profile() =~ /firefox_marionette/, "\$capabilities->moz_profile() contains 'firefox_marionette':" . $capabilities->moz_profile());
ok($capabilities->moz_webdriver_click() =~ /^(1|0)$/, "\$capabilities->moz_webdriver_click() is a boolean:" . $capabilities->moz_webdriver_click());
ok($capabilities->platform_name() =~ /\w+/, "\$capabilities->platform_version() contains alpha characters:" . $capabilities->platform_name());
TODO: {
	local $TODO = "\$firefox->dismiss_alert() not perfect yet";
	eval {
		$firefox->dismiss_alert();
	};
	ok($@, "Dismiss non-existant alert caused an exception to be thrown");
}
ok($firefox->accept_connections(0), "Refusing future connections");
ok($firefox->quit(), "Quit is ok");
	
