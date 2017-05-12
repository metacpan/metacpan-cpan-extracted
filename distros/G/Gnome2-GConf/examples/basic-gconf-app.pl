#!/usr/bin/perl

# This program demonstrates how to use GConf.  The key thing is that
# the main window and the prefs dialog have NO KNOWLEDGE of one
# another as far as configuration values are concerned; they don't
# even have to be in the same process. That is, the GConfClient acts
# as the data "model" for configuration information; the main
# application is a "view" of the model; and the prefs dialog is a
# "controller."
#
# You can tell if your application has done this correctly by
# using "gconftool" instead of your preferences dialog to set
# preferences. For example:
# 
# gconftool --type=string --set /apps/basic-gconf-app/foo "My string"
# 
# If that doesn't work every bit as well as setting the value
# via the prefs dialog, then you aren't doing things right. ;-)
#
#
# If you really want to be mean to your app, make it survive
# this:
# 
# gconftool --break-key /apps/basic-gconf-app/foo
# 
# Remember, the GConf database is just like an external file or
# the network - it may have bogus values in it. GConf admin
# tools will let people put in whatever they can think of.
# 
# GConf does guarantee that string values will be valid UTF-8, for
# convenience.
# 

# Throughout, this program is letting GConfClient use its default
# error handlers rather than checking for errors or attaching custom
# handlers to the "unreturned_error" signal. Thus the last arg to
# GConfClient functions is None.
#

# Special mention of an idiom often used in GTK+ apps that does
# not work right with GConf but may appear to at first:
#
# i_am_changing_value = gtk.TRUE
# change_value (value)
# i_am_changing_value = gtk.FALSE
# 
# This breaks for several reasons: notification of changes
# may be asynchronous, you may get notifications that are not
# caused by change_value () while change_value () is running,
# since GConf will enter the main loop, and also if you need
# this code to work you are probably going to have issues
# when someone other than yourself sets the value.
# 
# A robust solution in this case is often to compare the old
# and new values to see if they've really changed, thus avoiding
# whatever loop you were trying to avoid.
#

# The code is a direct mapping (with some perlisms) of the C
# code; where the code diverge, I placed a comment. (ebassi)

use strict;
use warnings;

use Glib qw/TRUE FALSE/;
use Gtk2 '-init';
use Gnome2::GConf;

our $client = Gnome2::GConf::Client->get_default;

# Tell GConfClient that we're interested in the given directory.
# This means GConfClient will receive notification of changes
# to this directory, and cache keys under this directory.
# So _don't_ add "/" or something silly like that or you'll end
# up with a copy of the whole GConf database. ;-)
#
# We use 'preload_none' to avoid loading all config keys on
# startup. If your app pretty much reads all config keys
# on startup, then preloading the cache may make sense.

$client->add_dir ("/apps/basic-gconf-app", 'preload-none');

our $main_window = create_main_window ($client);
$main_window->show_all;

Gtk2->main;

# Remove any notification on the directory
$client->remove_dir ("/apps/basic-gconf-app");

0;

sub create_main_window
{
	my $client = shift;
	
	my $w = Gtk2::Window->new('toplevel');
	$w->set_title('basic-gconf-app Main Window');
	
	my $vbox = Gtk2::VBox->new(FALSE, 12);
	$vbox->set_border_width(12);

	$w->add($vbox);

	my $config;
	
	# Create labels that we can "configure"
	$config = create_configurable_widget ($client, "/apps/basic-gconf-app/foo");
	$vbox->pack_start($config, TRUE, TRUE, 0);

	$config = create_configurable_widget ($client, "/apps/basic-gconf-app/bar");
	$vbox->pack_start($config, TRUE, TRUE, 0);

	$config = create_configurable_widget ($client, "/apps/basic-gconf-app/baz");
	$vbox->pack_start($config, TRUE, TRUE, 0);

	$config = create_configurable_widget ($client, "/apps/basic-gconf-app/blah");
	$vbox->pack_start($config, TRUE, TRUE, 0);

	$w->signal_connect(destroy => sub { Gtk2->main_quit });
	$w->{client} = $client;

	my $prefs = Gtk2::Button->new("Prefs");
	$vbox->pack_end($prefs, FALSE, FALSE, 0);
	$prefs->signal_connect(clicked => sub {
			my $button = shift;
			my $main_window = shift;

			my $prefs_dialog = $main_window->{prefs};
			if (not $prefs_dialog) {
				my $client = $main_window->{client};
				$prefs_dialog = create_prefs_dialog ($main_window, $client);
				$main_window->{prefs} = $prefs_dialog;
				
				$prefs_dialog->signal_connect(
						destroy => \&prefs_dialog_destroyed,
						$main_window);

				$prefs_dialog->show_all;
			} else {	
				# show existing dialog
				$prefs_dialog->present;
			}
		}, $w);
		
	return $w;
}

# Create a GtkLabel inside a frame, that we can "configure"
# (the label displays the value of the config key).
sub create_configurable_widget
{
	my $client = shift;
	my $config_key = shift;

	my $frame = Gtk2::Frame->new($config_key);
	my $label = Gtk2::Label->new;
	$frame->add($label);

	my $s = $client->get_string($config_key);
	$label->set_text("Value: $s") if $s;

	my $notify_id = $client->notify_add($config_key, sub {
			# Notification callback for our label widgets that
			# monitor the current value of a gconf key. i.e.
			# we are conceptually "configuring" the label widgets
			my ($client, $cnxn_id, $entry, $label) = @_;
			return unless $entry;

			# Note that value can be undef (unset) or it can have
			# the wrong type! Need to check that to survive
			# gconftool --break-key
			unless ($entry->{value}) {
				$label->set_text('');
			} elsif ($entry->{value}->{type} eq 'string') {
				warn(sprintf("got: %s\n", $entry->{value}));

				$label->set_text("Value: " . $entry->{value}->{value});
			} else {
				$label->set_text('!type error!');
			}
		}, $label);
	
	# Note that notify_id will be 0 if there was an error,
	# so we handle that in our destroy callback.	
	$label->{notify_id} = $notify_id;
	$label->{client} = $client;
	$label->signal_connect(destroy => sub {
			# Remove the notification callback when the widget
			# monitoring notifications is destroyed
			my $client = $_[0]->{client};
			my $notify_id = $_[0]->{notify_id};

			$client->notify_remove($notify_id) if $notify_id;
		});
	
	return $frame;
}

#
# Preferences dialog code. NOTE that the prefs dialog knows NOTHING
# about the existence of the main window; it is purely a way to fool
# with the GConf database. It never does something like change
# the main window directly; it ONLY changes GConf keys via
# GConfClient. This is _important_, because people may configure
# your app without using your preferences dialog.
#
# This is an instant-apply prefs dialog. For a complicated
# apply/revert/cancel dialog as in GNOME 1, see the
# complex-gconf-app.c example. But don't actually copy that example
# in GNOME 2, thanks. ;-) complex-gconf-app.c does show how
# to use GConfChangeSet.
#

sub prefs_dialog_destroyed
{
	my $dialog = shift;
	my $main_window = shift;

	$main_window->{prefs} = undef;
}

sub config_entry_commit
{
	my $entry = shift;

	my $client = $entry->{client};
	my $key    = $entry->{key};
	
	my $text = $entry->get_chars(0, -1);
	
	# Unset if the string is zero-length, otherwise set
	if ($text) {
		# show how to use the generic 'set' method, instead of
		# get_string. (ebassi)
		$client->set($key, {
			type => 'string',
			value => $text
		});
	} else {
		$client->unset($key);
	}
	
	# since we connect the "focus_out_event" to this callback,
	# this return is needed. (ebassi)
	return FALSE;
}

sub create_config_entry
{
	my $prefs_dialog = shift;
	my $client       = shift;
	my $config_key   = shift;
	my $has_focus    = shift || FALSE;

	my $hbox  = Gtk2::HBox->new(FALSE, 6);
	my $label = Gtk2::Label->new("$config_key =");
	my $entry = Gtk2::Entry->new;

	$hbox->pack_start($label, FALSE, FALSE, 0);
	$hbox->pack_end($entry, FALSE, FALSE, 0);

	# this will print an error via default error handler
	# if the key isn't set to a string
	my $s = $client->get_string($config_key);
	$entry->set_text($s) if $s;

	$entry->{client} = $client;
	$entry->{key} = $config_key;
	
	# Commit changes if the user focuses out, or hits enter; we
	# don't do this on "changed" since it'd probably be a bit too
	# slow to round-trip to the server on every "changed" signal.
	$entry->signal_connect(activate        => \&config_entry_commit);
	$entry->signal_connect(focus_out_event => \&config_entry_commit);
	
	# Set the entry insensitive if the key it edits isn't writable.
	# Technically, we should update this sensitivity if the key
	# gets a change notify, but that's probably overkill.
	$entry->set_sensitive($client->key_is_writable($config_key));

	$entry->grab_focus if $has_focus;
	
	return $hbox;
}


sub create_prefs_dialog
{
	my $parent = shift;
	my $client = shift;

	my $dialog = Gtk2::Dialog->new("basic-gconf-app Preferences",
				       $parent,
				       [ qw/destroy-with-parent/ ],
				       'gtk-close', 'accept');
				       
	# destroy dialog on button press
	$dialog->signal_connect(response => sub { $_[0]->destroy });
	$dialog->set_default_response('accept');
	
	# resizing doesn't grow the entries anyhow
	$dialog->set_resizable(FALSE);

	my $vbox = Gtk2::VBox->new(FALSE, 12);
	$vbox->set_border_width(12);

	$dialog->vbox->pack_start($vbox, FALSE, FALSE, 0);

	my $entry;
	$entry = create_config_entry ($dialog, $client, "/apps/basic-gconf-app/foo", TRUE);
	$vbox->pack_start($entry, FALSE, FALSE, 0);

	$entry = create_config_entry ($dialog, $client, "/apps/basic-gconf-app/bar");
	$vbox->pack_start($entry, FALSE, FALSE, 0);

	$entry = create_config_entry ($dialog, $client, "/apps/basic-gconf-app/baz");
	$vbox->pack_start($entry, FALSE, FALSE, 0);

	$entry = create_config_entry ($dialog, $client, "/apps/basic-gconf-app/blah");
	$vbox->pack_start($entry, FALSE, FALSE, 0);
		
	return $dialog;
}
