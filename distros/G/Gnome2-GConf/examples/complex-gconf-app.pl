#!/usr/bin/perl

# This is a reworked version of basic-gconf-app.pl that uses GConfChangeSet for
# storing the preferences with an 'explicit-apply' dialog. (ebassi)

use strict;
use warnings;

use constant TRUE	=> 1;
use constant FALSE	=> 0;

use constant FOO_KEY  => '/apps/basic-gconf-app/foo';
use constant BAR_KEY  => '/apps/basic-gconf-app/bar';
use constant BAZ_KEY  => '/apps/basic-gconf-app/baz';
use constant BLAH_KEY => '/apps/basic-gconf-app/blah';

use Gtk2;
use Gnome2::GConf;

Gtk2->init;

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

$client->remove_dir ("/apps/basic-gconf-app");

0;

sub create_main_window
{
	my $client = shift;
	
	my $w = Gtk2::Window->new('toplevel');
	$w->set_title('complex-gconf-app Main Window');
	
	my $vbox = Gtk2::VBox->new(FALSE, 5);
	$vbox->set_border_width(5);

	$w->add($vbox);

	my $config;
	
	# Create labels that we can "configure"
	$config = create_configurable_widget ($client, FOO_KEY);
	$vbox->pack_start($config, TRUE, TRUE, 0);

	$config = create_configurable_widget ($client, BAR_KEY);
	$vbox->pack_start($config, TRUE, TRUE, 0);

	$config = create_configurable_widget ($client, BAZ_KEY);
	$vbox->pack_start($config, TRUE, TRUE, 0);

	$config = create_configurable_widget ($client, BLAH_KEY);
	$vbox->pack_start($config, TRUE, TRUE, 0);

	$w->signal_connect(delete_event => sub { $_[0]->destroy });
	$w->signal_connect(destroy => sub { Gtk2->main_quit });
	$w->{client} = $client;

	my $prefs = Gtk2::Button->new("Prefs");
	$vbox->pack_end($prefs, FALSE, FALSE, 0);
	$prefs->signal_connect(clicked => sub {
			my $button = shift;
			my $main_window = shift;

			my $prefs_dialog = $main_window->{prefs};
			if (not $prefs_dialog)
			{
				my $client = $main_window->{client};
				$prefs_dialog = create_prefs_dialog ($main_window, $client);
				$main_window->{prefs} = $prefs_dialog;
				
				$prefs_dialog->signal_connect(
						destroy => \&prefs_dialog_destroyed,
						$main_window);

				$prefs_dialog->show_all;
			}
			else
			{	
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
	$label->set_text($s) if $s;

	my $notify_id = $client->notify_add($config_key, sub {
			# Notification callback for our label widgets that
			# monitor the current value of a gconf key. i.e.
			# we are conceptually "configuring" the label widgets
			my ($client, $cnxn_id, $entry, $label) = @_;
			return unless $entry;
			
			# Note that value can be undef (unset) or it can have
			# the wrong type! Need to check that to survive
			# gconftool --break-key
			unless ($entry->{value})
			{
				$label->set_text('');
			}
			elsif ($entry->{value}->{type} eq 'string')
			{
				$label->set_text($entry->{value}->{value});
			}
			else
			{
				$label->set_text('!type error!');
			}
		}, $label);
	
	# Note that notify_id will be 0 if there was an error,
    # so we handle that in our destroy callback.	
	$label->{notify_id} = $notify_id;
	$label->{client} = $client;
	$label->signal_connect(destroy => sub {
			# Remove the notification callback when the widget monitoring
			# notifications is destroyed
			my $client = $_[0]->{client};
			my $notify_id = $_[0]->{notify_id};

			$client->notify_remove($notify_id) if $notify_id;
		});
	
	return $frame;
}

# Preferences dialog code. NOTE that the prefs dialog knows NOTHING
# about the existence of the main window; it is purely a way to fool
# with the GConf database. It never does something like change
# the main window directly; it ONLY changes GConf keys via
# GConfClient. This is _important_, because people may configure
# your app without using your preferences dialog.
#
# This is an explicit-apply prefs dialog that uses GConfChangeSets. This kind
# of dialog is disencouraged inside the GNOME Human Interface Guidelines,
# since it's anti-intuitive; nevertheless, sometimes it is the only
# acceptable solution (e.g.: when preferences might take more than a short
# period of time to apply). (ebassi)

sub prefs_dialog_destroyed
{
	my $dialog = shift;
	my $main_window = shift;

	$main_window->{prefs} = undef;
}

sub on_prefs_response
{
	use Data::Dumper;
	my $dialog = shift;
	my $response = shift;
	my $client = shift;

	my $changeset = $dialog->{changeset};
	
	# see the state of the change set before committing it
	#print Dumper($changeset);

	if ('apply' eq $response)
	{
		# apply changeset but remain open.  we should disable the 'apply'
		# button until a change is made, but this is left as an exercise
		# to the reader.
		$client->commit_change_set($changeset, FALSE);
	}
	elsif ('ok' eq $response)
	{
		# apply changeset and close. 
		$client->commit_change_set($changeset, FALSE);
		$dialog->destroy;
	}
	else
	{
		$dialog->destroy;
	}
}

# this sub will handle the changes inside the preferences.  It's important to
# note that every change is made inside the changeset; the client is not used
# inside this callback.
sub config_entry_commit
{
	my $entry = shift;

	my $changeset = $entry->{changeset};	
	my $key = $entry->{key};
	my $text = $entry->get_chars(0, -1);
	
	# Unset if the string is zero-length, otherwise set
	if ($text)
	{
		# change the value inside the changeset
		$changeset->{$key} = { type => 'string', value => $text };
	}
	else
	{
		# unset the key inside the changeset
		$changeset->{$key} = { type => 'string', value => undef };
	}
	
	# since we also connect the "focus_out_event" to this callback, this return
	# is needed. (ebassi)
	FALSE;
}

sub create_config_entry
{
	my $prefs_dialog = shift;
	my $changeset	 = shift;
	my $config_key   = shift;
	my $has_focus    = shift || FALSE;

	my $hbox  = Gtk2::HBox->new(FALSE, 5);
	my $label = Gtk2::Label->new($config_key);
	my $entry = Gtk2::Entry->new;

	$hbox->pack_start($label, FALSE, FALSE, 0);
	$hbox->pack_end($entry, FALSE, FALSE, 0);

	# get the key's value from the changeset.  it's important to note that a
	# changeset is a collection of gconfvalues, so we must access the 'value'
	# field of that data structure.
	my $s = $changeset->{$config_key}->{'value'};
	$entry->set_text($s) if $s;

	$entry->{changeset} = $changeset;
	$entry->{key} = $config_key;
	
	# Commit changes if the user focuses out, or hits enter; we don't
    # do this on "changed" since it'd probably be a bit too slow to
    # round-trip to the server on every "changed" signal.
	$entry->signal_connect(activate        => \&config_entry_commit);
	$entry->signal_connect(focus_out_event => \&config_entry_commit);
	
	# Set the entry insensitive if the key it edits isn't writable.
    # Technically, we should update this sensitivity if the key gets
    # a change notify, but that's probably overkill.
	$entry->set_sensitive($client->key_is_writable($config_key));

	$entry->grab_focus if $has_focus;
	
	return $hbox;
}


sub create_prefs_dialog
{
	use Data::Dumper;
	
	my $parent = shift;
	my $client = shift;

	my $dialog = Gtk2::Dialog->new("basic-gconf-app Preferences",
								   $parent,
								   [ qw/destroy-with-parent/ ],
								   'gtk-cancel', 'cancel',
								   'gtk-apply', 'apply',
								   'gtk-ok', 'ok');
	
	# commit on button press
	$dialog->signal_connect(response => \&on_prefs_response, $client);
	$dialog->set_default_response('ok');
	
	# resizing doesn't grow the entries anyhow
	$dialog->set_resizable(FALSE);

	my $vbox = Gtk2::VBox->new(FALSE, 5);
	$vbox->set_border_width(5);

	$dialog->vbox->pack_start($vbox, FALSE, FALSE, 0);
	
	# create the changeset from the current key state; the changeset will be
	# our "interface" to the gconf client, and we will operate any change in
	# the key state on it.
	my $cs = $client->change_set_from_current(
			FOO_KEY,
			BAR_KEY,
			BAZ_KEY,
			BLAH_KEY
		);
	# see the state of the changeset
	#print Dumper($cs);
	
	my $entry;
	$entry = create_config_entry ($dialog, $cs, FOO_KEY, TRUE);
	$vbox->pack_start($entry, FALSE, FALSE, 0);

	$entry = create_config_entry ($dialog, $cs, BAR_KEY);
	$vbox->pack_start($entry, FALSE, FALSE, 0);

	$entry = create_config_entry ($dialog, $cs, BAZ_KEY);
	$vbox->pack_start($entry, FALSE, FALSE, 0);

	$entry = create_config_entry ($dialog, $cs, BLAH_KEY);
	$vbox->pack_start($entry, FALSE, FALSE, 0);

	$dialog->{changeset} = $cs; # hold a reference
	
	return $dialog;
}
