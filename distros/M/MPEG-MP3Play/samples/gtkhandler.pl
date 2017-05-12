use strict;
use MPEG::MP3Play qw(:msg :state);

$| = 1;

BEGIN {
	eval "use Gtk";
	if ( $@ ) {
		print "Sorry, no GTK module installed!\n";
		exit;
	}
	print "\nThe warning message 'Subroutine msg_notify_player_state redefined'\n";
	print "is intended. Please refer to the documentation to find out more\n";
	print "about this.\n\n";
}

main: {
	# check if test.mp3 exists

	if ( not -f "test.mp3" ) {
		print "Please copy a mp3 file called 'test.mp3' to this directory.\n";
		print "You should hear it if you run 'runsample gtk.pl' again.\n";
	}
	
	# we need to create the MPEG::MP3Player instance *before* intializing
	# Gtk to prevent from Gdk broken pipe related error messages on
	# program exit

	my $mp3 = new MPEG::MP3Play;
	$mp3->print_xaudio_implementation;
	
	# create simple window with progress bar

	init Gtk;
	my $pbar = create_window($mp3);
	
	# play the file triggering the progress bar,
	# connect Xaudio message queue to Gdk input

	play ($mp3, $pbar);
	
	# Gtk event loop (handles the Xaudio messages too)

	Gtk->main;
}

sub play {
	my ($mp3, $pbar) = @_;

	$mp3->open ("test.mp3");
	$mp3->play;

	my $input_fd = $mp3->get_command_read_pipe;

	my $input_tag = Gtk::Gdk->input_add (
		$input_fd,
		'read',
		sub { $mp3->process_messages_nowait }
	);

	$mp3->set_user_data ({
		input_tag => $input_tag,
		pbar => $pbar
	});
}

sub create_window {
	my ($mp3) = @_;

	my($pbar,$window,$button,$vbox,$label);
	
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
	
	return $pbar;
}

sub cleanup_and_exit {
	my ($input_tag) = @_;
	Gtk::Gdk->input_remove ($input_tag);
	exit;
}	

# message handlers

package MPEG::MP3Play;

sub msg_notify_input_position {
	my ($mp3, $msg) = @_;
	
	my $data = $mp3->get_user_data;

	my $percent = $msg->{position_offset}/$msg->{position_range};
	$data->{pbar}->update($percent);
}

sub msg_notify_player_state {
	my ($mp3, $msg) = @_;
	
	my $data = $mp3->get_user_data;

	main::cleanup_and_exit($data->{input_tag})
		if $msg->{state} == &XA_PLAYER_STATE_EOF;
}
