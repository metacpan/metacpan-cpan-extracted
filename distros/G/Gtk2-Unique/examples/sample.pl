#!/usr/bin/perl

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Gtk2::Unique;
use Encode;
use Data::Dumper;

my $COMMAND_WRITE = 1;


exit main();


sub main {
	die "Usage: message\n" unless @ARGV;
	my ($text) = @ARGV;
	# If we want to pass UTF-8 text in the command line arguments
	$text = decode('UTF-8', $text);
	
	# As soon as we create the UniqueApp instance we either have the name we
	# requested ("org.mydomain.MyApplication", in the example) or we don't because
	# there already is an application using the same name.
	my $app = Gtk2::UniqueApp->new(
		"org.example.Sample", undef,
		write => $COMMAND_WRITE,
	);


	# If there already is an instance running, this will return TRUE; there's no
	# race condition because the check is already performed at construction time.
	if ($app->is_running) {
		my $response = $app->send_message_by_name(write => data => $text);
		return 0;
	}


	# Create the single application instance and wait for other requests
	my $window = create_application($app, $text);
	Gtk2->main();
	
	return 0;
}


#
# Called when the application needs to be created. This happens when there's no
# other instance running.
#
sub create_application {
	my ($app, $text) = @_;

	# Standard window and windgets
	my $window = Gtk2::Window->new();
	$window->set_title("Unique - Example");
	$window->set_size_request(480, 240);
	my $textview = Gtk2::TextView->new();
	my $scroll = Gtk2::ScrolledWindow->new();
	my $buffer = $textview->get_buffer;

	$buffer->insert($buffer->get_end_iter, "$text\n");

	# Widget packing
	$scroll->add($textview);
	$window->add($scroll);
	$window->show_all();

	# Widget signals
	$window->signal_connect(delete_event => sub {
		Gtk2->main_quit();
		return TRUE;
	});

	# Listen for new commands
	$app->watch_window($window);
	$app->signal_connect('message-received' => sub {
		my ($app, $command, $message, $time) = @_;
		
		my $text = Dumper($message->get);
		$buffer->insert($buffer->get_end_iter, "$text\n");
		
		# Must return a "Gtk2::UniqueResponse"
		return 'ok';
	});

	return $window;
}
