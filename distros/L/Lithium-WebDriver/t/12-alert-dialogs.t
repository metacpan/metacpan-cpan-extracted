#!/usr/bin/perl

use strict;
use warnings;

use Test::Builder::Tester;
use t::common;

my $site = start_depends;

# Connect to the test site and click click on the popup button in the footer
# this will manually click on buttons and ensure visibility and invisibility
# It does not create generic functions to handle "popups"
my $DRIVER = Lithium::WebDriver->new(%{driver_conf(site => $site)});
$DRIVER->connect;

$DRIVER->maximize;

# set up variables to enable easier cross-browser testing;
my $ok = "ok";
my $nok = "not ok";
my $confirm_alert = "OK!";
my $cancel_alert = "Cancel!";
if (is_phantom) {
	note "Testing under phantomjs, ensuring oks are now not oks, as phantom doesn't support modals";
	$ok = $nok;
	$confirm_alert = $cancel_alert;
}

### NOTE: None of these test blocks can be converted to subtests, as that will interfere
###       with Test::Builder::Tester's testing of the tests.

{
	# Use default message on confirm_alert
	$DRIVER->open(url => "/");
	is($DRIVER->text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	$DRIVER->click(selector => "button.popup.confirm");
	test_out "$ok 1 - Confirming alertbox";
	ok($DRIVER->confirm, "Confirming alertbox");
	test_test name => "Default test name for confirm_alert comes through",
		skip_err => 1;
	is($DRIVER->text("p#ok_cancel"), $confirm_alert, "Confirm state shown after confirming");

	# Now with custom message for confirm_alert
	$DRIVER->open(url => "/");
	is($DRIVER->text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	$DRIVER->click(selector => "button.popup.confirm");
	test_out "$ok 1 - I can confirm";
	ok($DRIVER->confirm, "I can confirm");
	test_test name => "Test name for confirm_alert is correctly overridden",
		skip_err => 1;
	is($DRIVER->text("p#ok_cancel"), $confirm_alert, "Confirm state shown after confirming");

	# Make sure confirming with lack of alert dialog works
	$DRIVER->open(url => "/");
	is($DRIVER->text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	test_out "$nok 1 - There is no alert to confirm";
	test_fail(+1);
	ok($DRIVER->confirm, "There is no alert to confirm");
	test_test name => "Properly failed the confirm_alert test if no alert available",
		skip_err => 1;
	is($DRIVER->text("p#ok_cancel"), "", "No alert confirm/cancel state after testing");
}

{
	# Use default message on cancel_alert
	$DRIVER->open(url => "/");
	is($DRIVER->text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	$DRIVER->click(selector => "button.popup.confirm");
	test_out "$ok 1 - Canceling alertbox";
	ok($DRIVER->cancel, "Canceling alertbox");
	test_test name => "Default test name for cancel_alert comes through",
		skip_err => 1;
	is($DRIVER->text("p#ok_cancel"), $cancel_alert, "Cancel state shown after canceling");

	# Now with custom message for cancel_alert
	$DRIVER->open(url => "/");
	is($DRIVER->text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	$DRIVER->click(selector => "button.popup.confirm");
	test_out "$ok 1 - I can cancel";
	ok($DRIVER->cancel, "I can cancel");
	test_test name => "Test name for cancel_alert is correctly overridden",
		skip_err => 1;
	is($DRIVER->text("p#ok_cancel"), $cancel_alert, "Cancel state shown after canceling");

	# Make sure confirming with lack of alert dialog works
	$DRIVER->open(url => "/");
	is($DRIVER->text("p#ok_cancel"), "", "No alert confirm/cancel state at initialization");
	test_out "$nok 1 - There is no alert to cancel";
	test_fail +1;
	ok($DRIVER->confirm, "There is no alert to cancel");
	test_test name => "Properly failed the cancel_alert test if no alert available",
		skip_err => 1;
	is($DRIVER->text("p#ok_cancel"), "", "No alert confirm/cancel state after testing");
}

{
	# Default message for alert_text
	my $expect = is_phantom() ? undef : "I am an alert box!";
	$DRIVER->open(url => "/");
	$DRIVER->click(selector => "button.popup");
	test_out "$ok 1 - Retrieving alert text";
	my $txt = $DRIVER->alert_text();
	ok($DRIVER->alert_text, "Retrieving alert text");
	test_test name => "Default Test Name for alert_text comes through",
		skip_err => 1;
	is $txt, $expect, "Alert text returns correct content";

	# now with custom message for alert_text
	test_out "$ok 1 - Custom alert msg";
	ok($DRIVER->alert_text("Custom alert msg"), "Custom alert msg");
	test_test name => "Test Name for alert_text is correctly overridden",
		skip_err => 1;
	test_out "$ok 1 - Confirm popup";
	ok($DRIVER->confirm, "Confirm popup");
	test_test name => "Closing alert",
		skip_err =>1;

	# Make sure alert_text fails on lack of alert dialog
	$DRIVER->open(url => "/");
	test_out "$nok 1 - Retrieving alert text";
	test_fail +1;
	ok($DRIVER->alert_text, "Retrieving alert text");
	test_test name => "Properly failed the alert_text call if no alert available",
		skip_err => 1;
}

{
	# Default message for type_alert
	my $expect = is_phantom() ? "" : "Hello first_name! How are you today?";
	$DRIVER->open(url => "/");
	is $DRIVER->text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	$DRIVER->click(selector => "button.popup.input");
	test_out "$ok 1 - Setting alert text", "$ok 2 - Confirming alertbox";
	ok($DRIVER->alert_text("first_name"), "Setting alert text");
	ok($DRIVER->confirm, "Confirming alertbox");
	test_test name => "Default Test Name for type_alert comes through",
		skip_err => 1;
	is $DRIVER->text('p#popup_input'), $expect,
		"type_alert input was handled correctly";

	# Custom message for type_alert
	$expect = is_phantom() ? "" : "Hello second_name! How are you today?";
	$DRIVER->open(url => "/");
	is $DRIVER->text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	$DRIVER->click(selector => "button.popup.input");
	test_out "$ok 1 - Cutom type message", "$ok 2 - Confirming alertbox";
	ok($DRIVER->alert_text("second_name"), "Cutom type message");
	ok($DRIVER->confirm, "Confirming alertbox");
	test_test name => "Test Name for type_alert is correctly overridden",
		skip_err => 1;
	is $DRIVER->text('p#popup_input'), $expect,
		"type_alert input was handled correctly with custom message";

	# pass undef into type_alert
	$expect = is_phantom() ? "" : "Hello ! How are you today?";
	$DRIVER->open(url => "/");
	is $DRIVER->text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	$DRIVER->click(selector => "button.popup.input");
	test_out "$ok 1 - Setting alert text", "$ok 2 - Confirming alertbox";
	ok($DRIVER->alert_text(""), "Setting alert text");
	ok($DRIVER->confirm, "Confirming alertbox");
	test_test name => "type_alert handles undef input",
		skip_err => 1;
	is $DRIVER->text('p#popup_input'), $expect,
		"type_alert with undef input sets properly";

	# pass empty string into type_alert
	$DRIVER->open(url => "/");
	is $DRIVER->text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	$DRIVER->click(selector => "button.popup.input");
	test_out "$ok 1 - Setting alert text", "$ok 2 - Confirming alertbox";
	ok($DRIVER->alert_text(""), "Setting alert text");
	ok($DRIVER->confirm, "Confirming alertbox");
	test_test name => "type_alert handles empty string input",
		skip_err => 1;
	is $DRIVER->text('p#popup_input'), $expect,
		"type_alert with empty string sets properly";

	$DRIVER->open(url => "/");
	is $DRIVER->text('p#popup_input'), "",
		"type_alert feedback text is empty on test initialization";
	test_out "$nok 1 - Setting alert text";
	test_fail +1;
	ok($DRIVER->alert_text("fail"), "Setting alert text");
	test_test name => "type_alert properly failed when no alert dialog was present",
		skip_err => 1;
	is $DRIVER->text('p#popup_input'), "",
		"type_alert feedback text is empty after testing";
}

$DRIVER->disconnect;
stop_depends;
done_testing;
