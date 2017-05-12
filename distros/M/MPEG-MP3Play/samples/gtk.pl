use strict;
use MPEG::MP3Play qw(:msg :state);

$| = 1;

BEGIN {
	eval "use Gtk";
	if ( $@ ) {
		print "Sorry, no GTK module installed!\n";
		exit;
	}
}

my $mp3;
my $window;
my $pbar;
my $input_tag;

main: {
	# check if test.mp3 exists

	if ( not -f "test.mp3" ) {
		print "Please copy a mp3 file called 'test.mp3' to this directory.\n";
		print "You should hear it if you run 'runsample gtk.pl' again.\n";
	}
	
	# we need to create the MPEG::MP3Player instance *before* intializing
	# Gtk to prevent from Gdk broken pipe related error messages on
	# program exit
	
	$mp3 = new MPEG::MP3Play;
	$mp3->print_xaudio_implementation;
	
	# *now* initialize Gtk and create simple window with
	# progress bar

	init Gtk;
	create_window();
	
	# start playing the file and connect the Xaudio
	# message queue to Gdk input

	play ();
	
	# Gtk event loop (handles the Xaudio messages too)

	Gtk->main;
}

sub play {
	my $input_fd = $mp3->get_command_read_pipe;
	$input_tag = Gtk::Gdk->input_add ($input_fd, 'read', \&mp3_message_handler);
	
	$mp3->open ("test.mp3");
	$mp3->play;

	return $mp3;
}

sub mp3_message_handler {
	my $msg;
	while ( $msg = $mp3->get_message ) {

		my $code = $msg->{code};

		if ( $code == &XA_MSG_NOTIFY_INPUT_POSITION ) {
			my $percent = $msg->{position_offset}/$msg->{position_range};
			$pbar->update($percent);
		} elsif ( $code == &XA_MSG_NOTIFY_PLAYER_STATE ) {
			cleanup_and_exit() if $msg->{state} == &XA_PLAYER_STATE_EOF;
		}
	}
}

sub create_window {
	my($button,$vbox,$label);
	
	$window = new Gtk::Dialog;
	signal_connect $window "destroy" => \&cleanup_and_exit, \$window;
	signal_connect $window "delete_event" => \&cleanup_and_exit, \$window;
	$window->set_title("MPEG::MP3Play Gtk+ Test");
	$window->border_width(0);
		
	$vbox = new Gtk::VBox(0,5);
	$vbox->border_width(10);
	$window->vbox->pack_start($vbox,1,1,0);
	$vbox->show;
		
	$label = new Gtk::Label "progress...";
	$label->set_alignment(0.0,0.5);
	$vbox->pack_start($label,0,1,0);
	$label->show;
		
	$pbar = new Gtk::ProgressBar;
	$pbar->set_usize(200,20);
	$vbox->pack_start($pbar,1,1,0);
	$pbar->show;
		
	$button = new Gtk::Button "close";
	$button->signal_connect("clicked", sub { destroy $window });
	$button->can_default(1);
	$window->action_area->pack_start($button,1,1,0);
	$button->grab_default;
	$button->show;
	
	$window->show;
	
	return ($window, $pbar);
}

sub cleanup_and_exit {
	Gtk::Gdk->input_remove ($input_tag);
	exit;
}	
