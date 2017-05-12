#!/usr/bin/perl

=doc

gtk+ 2.x provides a nice enhancement to the Dialog API, allowing you to use
the idea of responses instead of just connecting to buttons, and making
modal dialogs very easy.  There are two ways to use the Gtk2::Dialog --
by calling $dialog->run() for modal dialogs, or by connecting to the response
signal and handling things yourself, usually for modeless dialogs.

=cut

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 '-init';



### begin run type dialog
# if you want to pop up a simple dialog to get or provide some information this
# is probably the way you want to go. 

my $dialog = Gtk2::Dialog->new ('Run Dialog Demo', undef, 'modal',
	'gtk-ok' => 'ok',  # response ids may be one of the built-in enums...
	'_Reset' => 2,     # or any positive integer.
);

# put an hbox with a label and entry into the dialog's vbox area.
my $hbox = Gtk2::HBox->new (FALSE, 6);
$hbox->pack_start (Gtk2::Label->new ('Test:'), TRUE, TRUE, 0);
my $entry = Gtk2::Entry->new;
$hbox->pack_start ($entry, TRUE, TRUE, 0);
$hbox->show_all;

# the dialog provides a vbox for the area at the top, where your
# own widgets go.
$dialog->vbox->pack_start ($hbox, TRUE, TRUE, 0);

# Set which response is the default:
$dialog->set_default_response ('ok');

# A very common usability enhancement is to allow hitting Enter in the
# entry to activate the default response.  This turns that on:
$entry->set_activates_default (TRUE);

# run the dialog.  this will show for you.
my $response = $dialog->run;
# when a button is clicked the dialog will go away and the response (clicked 
# button) will be returned from the call to run

print "The user clicked: $response\n";
print 'The text entry was: '.$entry->get_text."\n";




### begin callback type dialog
# we'll reuse the same dialog, but use it differently. this time only the ok
# button will exit the dialog, the reset button will empty the text entry. this
# type of dialog is useful in cases where persistence is desired.

# change the dialog's title
$dialog->set (title => 'Callback Dialog Demo');

# connect a signal to the dialog's response signal.
$dialog->signal_connect (response => sub {
		# get our params
		shift; # we don't need the dialog
		$response = shift;	# the clicked button

		print "The user clicked: $response\n";
		print 'The text entry was: '.$entry->get_text."\n";
		if ($response eq 'ok')
		{
			# the user clicked ok
			Gtk2->main_quit;
		}
		elsif ($response eq 'delete-event')
		{
			# Because we didn't connect anything to delete-event
			# directly, the default handler will still destroy
			# the window.  By the time we get here, the window
			# will be gone already, and the only thing for it in
			# this example is to quit.
			Gtk2->main_quit;
		}
		else # if ($response == 2)
		{
			# the user clicked reset
			$entry->set_text ('');
		}
	});

# show the dialog
$dialog->show;
# and enter a main loop so that it will become interactive, the main loop will
# be quit by the callback attached to response.
Gtk2->main;
